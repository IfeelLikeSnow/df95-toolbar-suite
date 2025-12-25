-- @description Sampler: Build RS5k Kit From Folder
-- @version 1.0
-- @author DF95
-- @about
--   Baut ein einfaches RS5k-Drumkit:
--     - Nutzer gibt einen Sample-Ordner an
--     - Auf der ausgewählten Spur (oder einer neuen Spur) werden
--       pro Sample jeweils eine ReaSamplOmatic5000-Instanz erzeugt
--     - Jede Instanz reagiert auf eine eigene MIDI-Note (startend bei 36)

local r = reaper

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sampler – Build RS5k Kit", 0)
end

local function get_target_track()
  local sel_tr = r.GetSelectedTrack(0, 0)
  if sel_tr then return sel_tr end
  -- Wenn keine Spur selektiert ist: neue Spur anlegen
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95 RS5k Kit", true)
  return tr
end

local function get_global_mode_and_root()
  local gm = r.GetExtState("DF95_SAMPLER_WIZ", "global_mode") or "0"
  local root = r.GetExtState("DF95_SAMPLER_WIZ", "global_root") or ""
  gm = tonumber(gm) or 0
  return gm == 1, root
end

local function pick_folder()
  local use_global, root = get_global_mode_and_root()
  if use_global and root ~= "" then
    return root, true -- true = recursive
  end

  local last = r.GetExtState("DF95_SAMPLER", "last_folder") or ""
  local ok, input = r.GetUserInputs("DF95 RS5k Kit – Ordner", 1, "Sample-Ordner (voller Pfad):", last)
  if not ok or not input or input == "" then return nil end
  input = input:gsub('[\\"<>|]', "") -- minimal sanitizing
  local folder = input:gsub("[/\\]+$", "")
  r.SetExtState("DF95_SAMPLER", "last_folder", folder, true)
  return folder, false
end

local function iter_audio_files(folder, recursive)
  local files = {}
  local sep = package.config:sub(1,1)

  local function scan_dir(dir)
    local i = 0
    while true do
      local fname = r.EnumerateFiles(dir, i)
      if not fname then break end
      local lower = fname:lower()
      if lower:match("%.wav$") or lower:match("%.wave$") or lower:match("%.aif$") or lower:match("%.aiff$")
        or lower:match("%.flac$") or lower:match("%.ogg$") then
        table.insert(files, {dir = dir, name = fname})
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

  table.sort(files, function(a,b)
    if a.dir == b.dir then
      return a.name:lower() < b.name:lower()
    end
    return (a.dir .. "/" .. a.name):lower() < (b.dir .. "/" .. b.name):lower()
  end)

  return files
end

local function build_kit()
  local tr = get_target_track()
  if not tr then
    msg("Keine Zielspur gefunden oder anlegbar.")
    return
  end

  local folder, recursive = pick_folder()
  if not folder then return end

  local files = iter_audio_files(folder, recursive)
  if #files == 0 then
    msg("Im angegebenen Ordner (inkl. Unterordnern) wurden keine Audio-Dateien gefunden.")
    return
  end

  r.Undo_BeginBlock()

  local base_note = 36
  local inst_count = 0
  local sep = package.config:sub(1,1)

  for _, info in ipairs(files) do
    local full = info.dir .. sep .. info.name
    inst_count = inst_count + 1
    local note = base_note + (inst_count - 1)

    local fx_idx = r.TrackFX_AddByName(tr, "ReaSamplomatic5000 (Cockos)", false, -1)
    if fx_idx >= 0 then
      r.TrackFX_SetNamedConfigParm(tr, fx_idx, "FILE0", full)
      set_note_range_for_rs5k(tr, fx_idx, note)
      local inst_name = string.format("RS5k %d (%s)", note, info.name)
      r.TrackFX_SetNamedConfigParm(tr, fx_idx, "renamed_name", inst_name)
    end
  end

  r.Undo_EndBlock(string.format("DF95 Sampler: RS5k Kit aus Ordner (%d Samples)", inst_count), -1)
end


build_kit()
