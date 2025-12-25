-- @description DF95_V95_2_Fieldrec_OneClick_SplitEngine
-- @version 1.0
-- @author DF95
-- @about
--   OneClick-Wrapper für die V95-Fieldrec-Engine.
--   - Erkennt automatisch, ob ein Single-Mic- oder MicBundle-Szenario vorliegt.
--   - Single-Mic: ruft DF95_V95_Fieldrec_Split_And_Distribute.lua auf
--                 (Energy-basierte Segmentierung + Safety-Fades).
--   - Multi-Mic (Items auf mehreren Tracks): ruft
--                 DF95_V95_1_Fieldrec_Split_And_Distribute_MicBundle_AutoGain.lua auf
--                 (gemeinsame Segmentierung, Folder-Master pro Klasse,
--                  Child-Tracks pro Mic, AutoGain + Safety-Fades).
--
--   Hinweis:
--   - Dieses Script erwartet selektierte Audio-Items.
--   - Die aufgerufenen Scripts müssen im selben ReaScripts-Ordner liegen:
--       Scripts/IFLS/DF95/ReampSuite/

local r = reaper

------------------------------------------------------------
local function get_script_dir()
  local info = debug.getinfo(1, "S")
  local script_path = info.source:match("^@(.+)$")
  return script_path:match("^(.*[\\/])") or ""
end

local function show_msg(msg)
  r.ShowMessageBox(msg, "DF95 V95.2 OneClick SplitEngine", 0)
end

------------------------------------------------------------
local function detect_bundle_type()
  local sel_count = r.CountSelectedMediaItems(0)
  if sel_count == 0 then
    return "none", 0, {}
  end

  local tracks = {}
  local track_list = {}

  for i = 0, sel_count-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local tr = r.GetMediaItem_Track(item)
    if tr then
      local ptr_str = tostring(tr)
      if not tracks[ptr_str] then
        tracks[ptr_str] = tr
        track_list[#track_list+1] = tr
      end
    end
  end

  local num_tracks = #track_list

  if num_tracks == 0 then
    return "none", 0, {}
  elseif num_tracks == 1 then
    return "single", 1, track_list
  else
    return "bundle", num_tracks, track_list
  end
end

------------------------------------------------------------
local function run_child_script(child_name)
  local base_dir = get_script_dir()
  -- Script liegt im selben Ordner wie dieses Script
  local child_path = base_dir .. child_name
  local file = io.open(child_path, "r")
  if not file then
    show_msg("Konnte Child-Script nicht finden:
" .. child_path)
    return
  end
  file:close()
  dofile(child_path)
end

------------------------------------------------------------
local function main()
  local mode, num_tracks, _ = detect_bundle_type()
  if mode == "none" then
    show_msg("Bitte mindestens ein Audio-Item auswählen.")
    return
  end

  r.Undo_BeginBlock()

  if mode == "single" then
    -- Single-Mic-Fall: klassischer V95-Split
    run_child_script("DF95_V95_Fieldrec_Split_And_Distribute.lua")
  else
    -- Multi-Mic-Fall: MicBundle + Folder + AutoGain
    run_child_script("DF95_V95_1_Fieldrec_Split_And_Distribute_MicBundle_AutoGain.lua")
  end

  r.Undo_EndBlock("DF95 V95.2 Fieldrec OneClick SplitEngine", -1)
end

main()
