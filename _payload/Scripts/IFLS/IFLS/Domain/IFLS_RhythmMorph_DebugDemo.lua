-- IFLS_RhythmMorph_DebugDemo.lua
-- Phase 91: Debug/demo script for RhythmMorpher.

local RhythmStyles  = require("IFLS_RhythmStyles")
local RhythmMorpher = require("IFLS_RhythmMorpher")

local function build_straight_pattern()
  local pattern = {
    resolution   = 16,
    length_bars  = 1,
    tracks       = {
      kick = { steps = { [1]={hit=true, vel=110}, [9]={hit=true, vel=110} } },
      snare= { steps = { [5]={hit=true, vel=115}, [13]={hit=true, vel=115} } },
      hat  = { steps = {} },
    }
  }
  for i = 1, 16, 2 do
    pattern.tracks.hat.steps[i] = {hit=true, vel=90}
  end
  return pattern
end

local function dump_pattern(p, label)
  reaper.ShowConsoleMsg("=== Pattern: "..label.." ===\n")
  local res = p.resolution
  local inst_list = {"kick","snare","hat","perc"}
  for _, inst in ipairs(inst_list) do
    local track = p.tracks[inst]
    if track and track.steps then
      local line = inst..": "
      for i = 1, res do
        if track.steps[i] and track.steps[i].hit then
          line = line .. "X"
        else
          line = line .. "."
        end
      end
      reaper.ShowConsoleMsg(line.."\n")
    end
  end
end

local p0 = build_straight_pattern()
dump_pattern(p0, "original")

local p50 = RhythmMorpher.morph(build_straight_pattern(), "IDM_Chaos", 0.5, {
  instruments = {"kick","snare","hat","perc"},
  density_bias = 0.2,
})
dump_pattern(p50, "IDM_Chaos amount=0.5")

local p100 = RhythmMorpher.morph(build_straight_pattern(), "IDM_Chaos", 1.0, {
  instruments = {"kick","snare","hat","perc"},
  density_bias = 0.4,
})
dump_pattern(p100, "IDM_Chaos amount=1.0")

reaper.ShowConsoleMsg("=== End RhythmMorph Demo ===\n")
