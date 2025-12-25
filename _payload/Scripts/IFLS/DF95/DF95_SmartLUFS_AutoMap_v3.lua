-- @description SmartLUFS AutoMap v3 (Helper) – writes last LUFS/RMS to ExtState
-- @version 1.0
local r = reaper
-- Simpler helper: store nominal A/B values if not already measured by your meter chain
local function put(ns,k,v) r.SetProjExtState(0, ns, k, tostring(v)) end
-- defaults (can be overridden by meters)
put("DF95_MEASURE","LUFS_A", "-14")
put("DF95_MEASURE","LUFS_B", "-12")
put("DF95_MEASURE","RMS_A",  "-18")
put("DF95_MEASURE","RMS_B",  "-17")
r.ShowConsoleMsg("[DF95] SmartLUFS AutoMap v3: wrote nominal A/B defaults (override via meter scripts).\n")
