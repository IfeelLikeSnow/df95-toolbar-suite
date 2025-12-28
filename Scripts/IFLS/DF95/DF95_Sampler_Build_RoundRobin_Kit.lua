-- @description Sampler: Build RoundRobin RS5k Kit From Folder
-- @version 1.0
-- @author DF95
-- @about
--   Baut ein RS5k-Drumkit mit RoundRobin-Gruppierung:
--     - Nutzer wählt einen Sample-Ordner
--     - Nutzer gibt Anzahl Variationen pro Instrument (z.B. 3 oder 4) an
--     - Pro "Instrument" wird eine Gruppe von N Samples gebildet
--       (in alphabetischer Reihenfolge)
--     - Jede Gruppe bekommt einen Basis-Note-Wert (z.B. 36, 37, 38...)
--     - Innerhalb einer Gruppe werden die Layer in den RS5k-Namen
--       als RR1, RR2, RR3 markiert
--
--   Hinweis:
--     Diese Version erzeugt nur die strukturelle RoundRobin-Gruppierung.
--     ECHTE RoundRobin-Logik (Random/Cycle) muss über ein vorgelagertes
--     MIDI-Script (z.B. JSFX, das Noten auf mehrere Noten verteilt)
--     oder weitere DF95-Module umgesetzt werden.

local r = reaper

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sampler – RoundRobin", 0)
end

local function get_target_track()
  local sel_tr = r.GetSelectedTrack(0, 0)
  if sel_tr then return sel_tr end
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95 RS5k RoundRobin Kit", true)
  return tr
end

local function get_global_mode_and_root()
  local gm = r.GetExtState("DF95_SAMPLER_WIZ", "global_mode") or "0"
  local root = r.GetExtState("DF95_SAMPLER_WIZ", "global_root") or ""
  gm = tonumber(gm) or 0
  return gm == 1, root
end

local function pick_folder_and_rr()
  local use_global, root = get_global_mode_and_root()
  local folder
  local variants

  if use_global and root ~= "" then
    folder = root
    -- Varianten trotzdem abfragen
    local ok, ret = r.GetUserInputs("DF95 RS5k RoundRobin – Varianten", 1,
      "Varianten pro Instrument (z.B. 3 oder 4):", "4")
    if not ok or not ret or ret == "" then return nil end
    variants = tonumber(ret) or 4
  else
    local last = r.GetExtState("DF95_SAMPLER", "rr_folder") or ""
    local ok, input = r.GetUserInputs("DF95 RS5k RoundRobin", 2,
      "Sample-Ordner (voller Pfad):,Varianten pro Instrument (z.B. 3 oder 4):",
      last .. ",4")
    if not ok then return nil end
    folder, n = input:match("^(.*),(.*)$")
    if not folder or folder == "" then return nil end
    folder = folder:gsub('[\\"<>|]', ""):gsub("[/\\]+$", "")
    r.SetExtState("DF95_SAMPLER", "rr_folder", folder, true)
    variants = tonumber(n) or 4
  end

  variants = math.max(1, math.floor(variants))
  return folder, variants
end

local function iter_audio_files_sorted(folder)
  local files = {}
  local sep = package.config:sub(1,1)

  local use_global, _ = get_global_mode_and_root()
  local recursive = use_global

  local function scan_dir(dir)
    local i = 0
    while true do
      local fname = r.EnumerateFiles(dir, i)
      if not fname then break end
      local lower = fname:lower()
      if lower:match("%.wav$") or lower:match("%.wave$") or lower:match("%.aif$") or lower:match("%.aiff$")
        or lower:match("%.flac$") or lower:match("%.ogg$") then
        table.insert(files, dir .. sep .. fname)
      end
      i = i + 1
    end
    if recursive then
      local j = 0
      while true do
        local sub = r.EnumerateSubdirectories(dir, j)
        if not sub then break end
        scan_dir(dir .. sep .. sub)
        j = j + 1
      end
    end
  end

  scan_dir(folder)
  table.sort(files)
  return files
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

local function set_midi_channel_for_rs5k(track, fx_idx, chan)
  -- Versucht, den "MIDI channel"-Parameter zu finden und zu setzen.
  -- Annahme: 0 = All, 1..16 = Kanäle -> normalisiert 0..1
  local num_params = r.TrackFX_GetNumParams(track, fx_idx)
  for p = 0, num_params-1 do
    local _, pname = r.TrackFX_GetParamName(track, fx_idx, p, "")
    local lname = (pname or ""):lower()
    if lname:find("channel") and not lname:find("note") then
      local val = (chan - 1) / 15.0
      if val < 0 then val = 0 end
      if val > 1 then val = 1 end
      r.TrackFX_SetParamNormalized(track, fx_idx, p, val)
    end
  end
end

  end
end

local function build_rr()
  local tr = get_target_track()
  if not tr then
    msg("Keine Zielspur gefunden oder anlegbar.")
    return
  end

  local folder, variants = pick_folder_and_rr()
  if not folder then return end

  local files = iter_audio_files_sorted(folder)
  if #files == 0 then
    msg("Im angegebenen Ordner wurden keine Audio-Dateien gefunden.")
    return
  end

  r.Undo_BeginBlock()

  local base_note = 36
  local sep = package.config:sub(1,1)
  local inst_index = 0
  local fx_created = 0

  local i = 1
  while i <= #files do
    inst_index = inst_index + 1
    local note = base_note + (inst_index - 1)
    for v = 1, variants do
      local fname = files[i]
      if not fname then break end
      local full = folder .. sep .. fname
      local fx_idx = r.TrackFX_AddByName(tr, "ReaSamplomatic5000 (Cockos)", false, -1)
      if fx_idx >= 0 then
        r.TrackFX_SetNamedConfigParm(tr, fx_idx, "FILE0", full)
        set_note_range_for_rs5k(tr, fx_idx, note)
        set_midi_channel_for_rs5k(tr, fx_idx, v)
        local inst_name = string.format("RS5k %d RR%d (%s)", note, v, fname)
        r.TrackFX_SetNamedConfigParm(tr, fx_idx, "renamed_name", inst_name)
        fx_created = fx_created + 1
      end
      i = i + 1
      if i > #files then break end
    end
  end

  r.Undo_EndBlock(string.format("DF95 Sampler: RoundRobin-Kit (%d Instanzen)", fx_created), -1)
end

build_rr()
