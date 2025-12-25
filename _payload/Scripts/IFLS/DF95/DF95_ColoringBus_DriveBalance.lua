-- @description ColoringBus Drive Balance (In+Out Match)
-- @version 1.0
-- @author DF95
-- @about
--   Erhöht oder verringert den Drive auf Coloring-Bussen,
--   indem der erste "JS: Volume Adjustment" im FX-Chain als Input-Gain
--   und der letzte "JS: Volume Adjustment" als Output-Gain behandelt wird.
--   Input wird in dB verändert, Output wird gegengleich angepasst,
--   um die subjektive Lautheit grob zu erhalten.
--
--   Funktioniert auf allen selektierten Tracks.
--   Wenn keine Tracks selektiert sind, wird der Master-Track verwendet.
--
--   Hinweis:
--   Das Script nutzt TrackFX_GetFormattedParamValue und eine kleine
--   Binärsuche, um die dB-Werte der JS-Volume-Parameter robust zu setzen,
--   ohne Annahmen über die interne Normierung.

local reaper = reaper

local function msg(s) reaper.ShowConsoleMsg(tostring(s) .. "\\n") end

----------------------------------------------------------------------
-- Hilfe-Funktionen
----------------------------------------------------------------------

local function parse_db_from_string(s)
  if not s then return nil end
  -- Ersten Float aus dem String extrahieren, z.B. "-12.34 dB"
  local num = s:match("([-+]?%d+[%.,]?%d*)")
  if not num then return nil end
  num = num:gsub(",", ".")
  local v = tonumber(num)
  return v
end

local function get_param_db(track, fx, param)
  local ok1, _, _ , _ = reaper.TrackFX_GetParam(track, fx, param)
  if not ok1 then return nil end
  local ok2, txt = reaper.TrackFX_GetFormattedParamValue(track, fx, param, "")
  if not ok2 then return nil end
  return parse_db_from_string(txt)
end

local function set_param_db(track, fx, param, target_db)
  if not track then return end
  -- Binärsuche auf dem normalisierten Bereich 0..1
  local lo, hi = 0.0, 1.0
  local best_norm = nil
  local best_diff = math.huge

  for i = 1, 24 do
    local mid = (lo + hi) / 2.0
    reaper.TrackFX_SetParamNormalized(track, fx, param, mid)
    local cur_db = get_param_db(track, fx, param)
    if not cur_db then break end
    local diff = cur_db - target_db
    if math.abs(diff) < best_diff then
      best_diff = math.abs(diff)
      best_norm = mid
    end
    if diff < 0 then
      -- aktuelle Lautstärke ist zu leise -> wir müssen höher gehen
      lo = mid
    else
      -- zu laut -> runter
      hi = mid
    end
  end

  if best_norm then
    reaper.TrackFX_SetParamNormalized(track, fx, param, best_norm)
  end
end

local function find_first_last_js_volume(track)
  local fx_count = reaper.TrackFX_GetCount(track)
  local first_idx, last_idx = nil, nil

  for i = 0, fx_count - 1 do
    local _, name = reaper.TrackFX_GetFXName(track, i, "")
    if name:find("JS: Volume Adjustment", 1, true) then
      if not first_idx then
        first_idx = i
      end
      last_idx = i
    end
  end

  return first_idx, last_idx
end

----------------------------------------------------------------------
-- User-Input: Drive in dB
----------------------------------------------------------------------

local retval, user_in = reaper.GetUserInputs(
  "DF95 ColoringBus Drive",
  1,
  "Drive (dB, positiv = mehr, negativ = weniger):",
  "3.0"
)

if not retval then return end

local drive_db = tonumber(user_in)
if not drive_db or drive_db == 0 then
  return
end

reaper.Undo_BeginBlock()

local num_sel = reaper.CountSelectedTracks(0)
if num_sel == 0 then
  -- Wenn nichts selektiert: Master
  num_sel = 1
end

for i = 0, num_sel - 1 do
  local track
  if reaper.CountSelectedTracks(0) == 0 then
    track = reaper.GetMasterTrack(0)
  else
    track = reaper.GetSelectedTrack(0, i)
  end

  if track then
    local in_fx, out_fx = find_first_last_js_volume(track)
    if in_fx ~= nil and out_fx ~= nil then
      -- Nur wenn es auch wirklich zwei Volume-Instanzen gibt
      local in_db = get_param_db(track, in_fx, 0)
      local out_db = get_param_db(track, out_fx, 0)
      if in_db and out_db then
        local new_in = in_db + drive_db
        local new_out = out_db - drive_db

        set_param_db(track, in_fx, 0, new_in)
        set_param_db(track, out_fx, 0, new_out)
      end
    end
  end
end

reaper.Undo_EndBlock("DF95 ColoringBus Drive Balance", -1)
