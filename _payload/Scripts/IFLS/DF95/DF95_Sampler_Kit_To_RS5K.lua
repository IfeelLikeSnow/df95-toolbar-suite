\
-- @description DF95_Sampler_Kit_To_RS5K
-- @version 1.0
-- @author DF95
-- @about
--   Adapter: DF95_Sampler_KitSchema -> ReaSamplomatic5000-Instanzen auf einem Track.
--   Erzeugt einen neuen Track, legt fuer jeden Slot eine RS5k-Instanz an und laedt die Datei.
--
--   Hinweis:
--     - Nutzt TrackFX_SetNamedConfigParm, um die Sample-Datei zu setzen.
--     - Root-Note wird versucht ueber NOTE_START/NOTE_END zu setzen (sofern von REAPER akzeptiert).
--     - Dieses Script ist als Modul gedacht (return M).

local r = reaper

local M = {}

local function ensure_track(track_name)
  local proj = 0
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if name == track_name then
      return tr
    end
  end

  r.InsertTrackAtIndex(track_count, true)
  local tr = r.GetTrack(proj, track_count)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", track_name, true)
  return tr
end

local function add_rs5k_instance(tr)
  local fx_name = "ReaSamplomatic5000 (Cockos)"
  local fx_index = r.TrackFX_AddByName(tr, fx_name, false, -1)
  if fx_index < 0 then
    fx_name = "ReaSamplomatic5000"
    fx_index = r.TrackFX_AddByName(tr, fx_name, false, -1)
  end
  return fx_index
end

local function set_rs5k_sample(tr, fx_index, file, root_note)
  if not file or file == "" then return end
  -- Sample-Datei setzen
  r.TrackFX_SetNamedConfigParm(tr, fx_index, "FILE0", file)

  if root_note then
    local rn = tostring(root_note|0)
    -- Diese Parm-Namen sind inoffiziell; wenn REAPER sie nicht kennt, passiert einfach nichts.
    r.TrackFX_SetNamedConfigParm(tr, fx_index, "NOTE_START", rn)
    r.TrackFX_SetNamedConfigParm(tr, fx_index, "NOTE_END", rn)
  end

  -- Sampler auf One-shot / No Loop setzen, falls vorhanden (Failsafe: Param-IDs koennen sich aendern)
  -- Wir versuchen hier nur defensiv, den Loop-Typ zu beeinflussen.
  local num_params = r.TrackFX_GetNumParams(tr, fx_index)
  for i = 0, num_params-1 do
    local _, pname = r.TrackFX_GetParamName(tr, fx_index, i, "")
    if pname:lower():find("mode") or pname:lower():find("loop") then
      local _, val, _, _ = r.TrackFX_GetParam(tr, fx_index, i)
      -- z.B. Wert 0 = Normal / One-shot, je nach Version
      r.TrackFX_SetParam(tr, fx_index, i, 0.0)
    end
  end
end

-- Erzeugt einen neuen Track und baut alle Slots eines Kits als RS5k-Instanzen
-- options: { track_name }
function M.build_on_new_track(kit, options)
  if not kit or type(kit) ~= "table" or type(kit.slots) ~= "table" then
    r.ShowMessageBox("Kit ist ungueltig oder enthaelt keine Slots.", "DF95 Kit -> RS5k", 0)
    return
  end

  options = options or {}
  local track_name = options.track_name or (kit.meta and kit.meta.name) or "DF95_RS5K_KIT"

  r.Undo_BeginBlock()

  local tr = ensure_track(track_name)

  for _, slot in ipairs(kit.slots) do
    local fx_index = add_rs5k_instance(tr)
    if fx_index >= 0 then
      set_rs5k_sample(tr, fx_index, slot.file, slot.root)
    end
  end

  r.Undo_EndBlock("DF95 Kit -> RS5k (" .. track_name .. ")", -1)
end

return M
