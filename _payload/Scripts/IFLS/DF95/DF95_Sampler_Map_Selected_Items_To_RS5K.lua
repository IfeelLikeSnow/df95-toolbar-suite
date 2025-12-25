-- @description Sampler: Map Selected Items To RS5k Kit
-- @version 1.0
-- @author DF95
-- @about
--   Baut ein RS5k-Kit aus den aktuell ausgewählten Items:
--     - Eine Instanz ReaSamplOmatic5000 pro Item
--     - Jede Instanz bekommt das zugrunde liegende Sample
--     - Note-Zuweisung ab 36 aufwärts
--
--   Hinweis:
--     Diese erste Version verwendet den Quell-Sample-Pfad der Takes.
--     Falls mehrere Items denselben Source-File nutzen (z.B. Slices
--     aus einer Loop-Datei), wird aktuell der gesamte File als Sample
--     geladen, nicht nur der Item-Ausschnitt.

local r = reaper

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sampler – Map Items To RS5k", 0)
end

local function get_target_track()
  local sel_tr = r.GetSelectedTrack(0, 0)
  if sel_tr then return sel_tr end
  -- Wenn keine Spur selektiert ist: neue Spur anlegen
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95 RS5k Slices", true)
  return tr
end

local function collect_selected_items()
  local t = {}
  local cnt = r.CountSelectedMediaItems(0)
  for i = 0, cnt-1 do
    local it = r.GetSelectedMediaItem(0, i)
    if it then table.insert(t, it) end
  end
  return t
end

local function get_source_path_of_item(item)
  local take = r.GetActiveTake(item)
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  if not src then return nil end
  local buf = ""
  local retval, path = r.GetMediaSourceFileName(src, "")
  if not retval or path == "" then return nil end
  return path
end

local function set_note_range_for_rs5k(track, fx_idx, note)
  local num_params = r.TrackFX_GetNumParams(track, fx_idx)
  for p = 0, num_params-1 do
    local _, pname = r.TrackFX_GetParamName(track, fx_idx, p, "")
    local lname = (pname or ""):lower()
    if lname:find("note range start") or lname:find("note start") then
      r.TrackFX_SetParamNormalized(track, fx_idx, p, note / 127.0)
    elseif lname:find("note range end") or lname:find("note end") then
      r.TrackFX_SetParamNormalized(track, fx_idx, p, note / 127.0)
    end
  end
end

local function build_from_items()
  local items = collect_selected_items()
  if #items == 0 then
    msg("Keine Items ausgewählt.")
    return
  end

  local tr = get_target_track()
  if not tr then
    msg("Keine Zielspur gefunden oder anlegbar.")
    return
  end

  r.Undo_BeginBlock()

  local base_note = 36
  local inst_count = 0

  for _, it in ipairs(items) do
    local path = get_source_path_of_item(it)
    if path and path ~= "" then
      inst_count = inst_count + 1
      local note = base_note + (inst_count - 1)
      local fx_idx = r.TrackFX_AddByName(tr, "ReaSamplomatic5000 (Cockos)", false, -1)
      if fx_idx >= 0 then
        r.TrackFX_SetNamedConfigParm(tr, fx_idx, "FILE0", path)
        set_note_range_for_rs5k(tr, fx_idx, note)
        local inst_name = string.format("RS5k %d (%s)", note, r.GetTakeName(r.GetActiveTake(it)) or "?")
        r.TrackFX_SetNamedConfigParm(tr, fx_idx, "renamed_name", inst_name)
      end
    end
  end

  r.Undo_EndBlock(string.format("DF95 Sampler: RS5k Kit aus %d Items", inst_count), -1)
end

build_from_items()
