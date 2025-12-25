-- @description LoopBuilder2 – Euclid / StepGrid / Commit
-- @version 1.0
-- @author DF95
-- @about
--   Erweiterter LoopBuilder:
--     - Commit ausgewählter Slices auf neue DF95 Loop-Spur
--     - Euclid-Drumloop (Kick/Snare/Hat/MicroPerc) als MIDI erzeugen
--     - StepGrid-IDM-Pattern (Maschine-/Elektron-Style) erzeugen

local r = reaper

local function msg(s)
  -- r.ShowConsoleMsg(tostring(s).."\n")
end

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local RhythmEngine
do
  local path = df95_root() .. "DF95_RhythmEngine.lua"
  local ok, mod = pcall(dofile, path)
  if ok and type(mod) == "table" then
    RhythmEngine = mod
  else
    r.ShowMessageBox("DF95_RhythmEngine.lua konnte nicht geladen werden:\n"..tostring(mod), "DF95 LoopBuilder2", 0)
  end
end

----------------------------------------------------------------------
-- Classic Commit: selektierte Slices → neue DF95 Loop-Spur
----------------------------------------------------------------------

local function commit_selected_slices_to_looptrack()
  if r.CountSelectedMediaItems(0) == 0 then
    r.ShowMessageBox("Keine Items ausgewählt – zum Commit bitte Slices/Items markieren.", "DF95 LoopBuilder2", 0)
    return
  end
  r.Undo_BeginBlock()
  local tr_count = r.CountTracks(0)
  r.InsertTrackAtIndex(tr_count, true)
  local dst = r.GetTrack(0, tr_count)
  r.GetSetMediaTrackInfo_String(dst, "P_NAME", "DF95 Loop", true)

  r.Main_OnCommand(40698, 0) -- Copy Items
  r.SetOnlyTrackSelected(dst)
  r.Main_OnCommand(40058, 0) -- Paste Items

  r.Undo_EndBlock("DF95 LoopBuilder2: Commit Slices to DF95 Loop", -1)
end

----------------------------------------------------------------------
-- Euclid Drumloop
----------------------------------------------------------------------

local function generate_euclid_drumloop()
  if not RhythmEngine then return end
  r.Undo_BeginBlock()

  local tr_count = r.CountTracks(0)
  r.InsertTrackAtIndex(tr_count, true)
  local tr = r.GetTrack(0, tr_count)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95 Loop – Euclid", true)

  local cursor = r.GetCursorPosition()
  local start_time = cursor
  local beat_len = 4.0 -- 1 Takt in 4/4

  local lanes = RhythmEngine.make_euclid_idm_kit(16)
  RhythmEngine.write_drum_pattern_as_midi(tr, start_time, beat_len, lanes, 0.1)

  r.Undo_EndBlock("DF95 LoopBuilder2: Euclid DrumLoop", -1)
end

----------------------------------------------------------------------
-- StepGrid IDM
----------------------------------------------------------------------

local function generate_stepgrid_drumloop()
  if not RhythmEngine then return end
  r.Undo_BeginBlock()

  local tr_count = r.CountTracks(0)
  r.InsertTrackAtIndex(tr_count, true)
  local tr = r.GetTrack(0, tr_count)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95 Loop – StepGrid", true)

  local cursor = r.GetCursorPosition()
  local start_time = cursor
  local beat_len = 4.0

  local lanes = RhythmEngine.make_stepgrid_idm_kit(16, 0.25, 0.2, 0.6)
  RhythmEngine.write_drum_pattern_as_midi(tr, start_time, beat_len, lanes, 0.18)

  r.Undo_EndBlock("DF95 LoopBuilder2: StepGrid IDM Loop", -1)
end

----------------------------------------------------------------------
-- Kontext-Menü
----------------------------------------------------------------------

local function show_menu()
  local items = {
    "DF95 LoopBuilder2:",
    ">Commit / Slices",
    "Commit selected slices as DF95 Loop",
    "<Generate New Loops",
    "Generate Euclid DrumLoop (Kick/Snare/Hat/MicroPerc)",
    "Generate StepGrid IDM DrumLoop (Elektron/Maschine Style)",
  }
  local menu = table.concat(items, "|")
  r.gfx.init("DF95 LoopBuilder2", 0, 0)
  local mx, my = r.GetMousePosition()
  r.gfx.x, r.gfx.y = mx, my
  local idx = r.gfx.showmenu(menu)
  r.gfx.quit()
  if idx == 2 then
    commit_selected_slices_to_looptrack()
  elseif idx == 4 then
    generate_euclid_drumloop()
  elseif idx == 5 then
    generate_stepgrid_drumloop()
  end
end

local function main()
  show_menu()
end

main()
