-- @description Sampler: Build Layered RS5k Kit From Two Folders
-- @version 1.0
-- @author DF95
-- @about
--   Baut ein RS5k-Kit mit "Layern":
--     - Nutzer wählt zwei Sample-Ordner (Layer A und Layer B)
--     - Die Dateien werden in beiden Ordnern alphabetisch sortiert
--     - Für Index i wird jeweils das i-te Sample aus Ordner A und B
--       auf DIESELBE MIDI-Note gemappt (zwei RS5k-Instanzen pro Note)
--     - Ergebnis: Zwei Samples pro Note werden gleichzeitig gespielt.
--
--   Hinweis:
--     - Es wird die kleinere Anzahl von Files in A/B verwendet.
--     - Der Zweck ist "Layering" (Stacks), nicht RoundRobin.
--     - Für RoundRobin bitte DF95_Sampler_Build_RoundRobin_Kit.lua nutzen.

local r = reaper

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sampler – Layered Kit", 0)
end

local function get_target_track()
  local sel_tr = r.GetSelectedTrack(0, 0)
  if sel_tr then return sel_tr end
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95 RS5k Layered Kit", true)
  return tr
end

local function pick_folders()
  local lastA = r.GetExtState("DF95_SAMPLER", "layer_folder_A") or ""
  local lastB = r.GetExtState("DF95_SAMPLER", "layer_folder_B") or ""
  local ok, ret = r.GetUserInputs("DF95 RS5k Layered Kit", 2,
    "Ordner A (voller Pfad):,Ordner B (voller Pfad):",
    lastA .. "," .. lastB)
  if not ok or not ret or ret == "" then return nil end
  local a, b = ret:match("^(.*),(.*)$")
  if not a or not b or a == "" or b == "" then return nil end
  a = a:gsub('[\\"<>|]', ""):gsub("[/\\]+$", "")
  b = b:gsub('[\\"<>|]', ""):gsub("[/\\]+$", "")
  r.SetExtState("DF95_SAMPLER", "layer_folder_A", a, true)
  r.SetExtState("DF95_SAMPLER", "layer_folder_B", b, true)
  return a, b
end

local function iter_audio_files_sorted(folder)
  local files = {}
  local i = 0
  while true do
    local fname = r.EnumerateFiles(folder, i)
    if not fname then break end
    local lower = fname:lower()
    if lower:match("%.wav$") or lower:match("%.wave$") or lower:match("%.aif$") or lower:match("%.aiff$")
      or lower:match("%.flac$") or lower:match("%.ogg$") then
      table.insert(files, fname)
    end
    i = i + 1
  end
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
  end
end

local function build_layered()
  local tr = get_target_track()
  if not tr then
    msg("Keine Zielspur gefunden oder anlegbar.")
    return
  end

  local folderA, folderB = pick_folders()
  if not folderA or not folderB then return end

  local filesA = iter_audio_files_sorted(folderA)
  local filesB = iter_audio_files_sorted(folderB)

  local nA = #filesA
  local nB = #filesB
  local n  = math.min(nA, nB)

  if n == 0 then
    msg("In mindestens einem der Ordner wurden keine Audio-Dateien gefunden.")
    return
  end

  r.Undo_BeginBlock()

  local base_note = 36
  local sep = package.config:sub(1,1)
  local count = 0

  for i = 1, n do
    local note = base_note + (i - 1)
    local fA = folderA .. sep .. filesA[i]
    local fB = folderB .. sep .. filesB[i]

    -- Layer A
    local fxA = r.TrackFX_AddByName(tr, "ReaSamplomatic5000 (Cockos)", false, -1)
    if fxA >= 0 then
      r.TrackFX_SetNamedConfigParm(tr, fxA, "FILE0", fA)
      set_note_range_for_rs5k(tr, fxA, note)
      local nameA = string.format("RS5k %d L1 (%s)", note, filesA[i])
      r.TrackFX_SetNamedConfigParm(tr, fxA, "renamed_name", nameA)
      count = count + 1
    end

    -- Layer B
    local fxB = r.TrackFX_AddByName(tr, "ReaSamplomatic5000 (Cockos)", false, -1)
    if fxB >= 0 then
      r.TrackFX_SetNamedConfigParm(tr, fxB, "FILE0", fB)
      set_note_range_for_rs5k(tr, fxB, note)
      local nameB = string.format("RS5k %d L2 (%s)", note, filesB[i])
      r.TrackFX_SetNamedConfigParm(tr, fxB, "renamed_name", nameB)
      count = count + 1
    end
  end

  r.Undo_EndBlock(string.format("DF95 Sampler: Layered Kit (%d Instanzen, %d Noten)", count, n), -1)
end

build_layered()
