-- IFLS_Diagnostics_DebugDemo.lua
-- Phase 93: Diagnostics & PerfProbe demo script.
--
-- This script:
--   * logs a few demo events
--   * profiles a fake expensive function
--   * dumps diagnostics + perf report to REAPER console

local resource = reaper.GetResourcePath()
local domain_path = resource .. "/Scripts/IFLS/IFLS/Domain/"

local function __ifls_add_path(p)
  if not package.path:find(p, 1, true) then
    package.path = package.path .. ";" .. p
  end
end
__ifls_add_path(resource .. "/Scripts/?.lua")
__ifls_add_path(resource .. "/Scripts/IFLS/IFLS/Domain/?.lua")
__ifls_add_path(resource .. "/Scripts/IFLS/IFLS/Core/?.lua")

local okDiag, Diagnostics = pcall(require, "IFLS_Diagnostics")
if not okDiag then Diagnostics = dofile(domain_path .. "IFLS_Diagnostics.lua") end
local okPerf, PerfProbe = pcall(require, "IFLS_PerfProbe")
if not okPerf then PerfProbe = dofile(domain_path .. "IFLS_PerfProbe.lua") end


reaper.ShowConsoleMsg("=== IFLS Diagnostics Demo ===\n")

Diagnostics.log("scene_load", "Loaded scene demo_glitch_intro", {
  scene_id  = "demo_glitch_intro",
  flavor    = "GlitchCore",
  artist    = "Demo Artist",
})

Diagnostics.log("rhythm_morph", "Morph pattern toward IDM_Chaos", {
  pattern_id = "pattern_01",
  style      = "IDM_Chaos",
  amount     = 0.75,
})

local function fake_work()
  local s = 0
  for i = 1, 200000 do
    s = s + math.sin(i)
  end
  return s
end

PerfProbe.begin("fake_work_block")
local result = Diagnostics.profile_block("fake_work_block", fake_work, {
  note = "demo heavy work",
})
PerfProbe.finish("fake_work_block")

Diagnostics.log("fx_chain_build", "FX chain built for kick bus", {
  chain_template = "DrumBus_Glue_Color",
  plugin_count   = 4,
})

Diagnostics.dump_to_console(50)
PerfProbe.dump_to_console()

reaper.ShowConsoleMsg("=== End Diagnostics Demo ===\n")
