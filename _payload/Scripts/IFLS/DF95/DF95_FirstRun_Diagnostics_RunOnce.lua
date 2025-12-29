
-- @description First-Run Diagnostics (RunOnce) – Linter + Smokes + HTML
-- @version 1.0
local r = reaper
local _, done = r.GetProjExtState(0, "DF95_INSTALL", "RUNONCE_DIAG")
if done == "1" then return end

local base = reaper.GetResourcePath():gsub("\\","/")

-- Feature flag gate (V3): diagnostics can be disabled via Support/DF95_Config.json
do
  local okc, Core = pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
  if okc and type(Core) == "table" and type(Core.get_config) == "function" then
    local cfg = Core.get_config()
    if cfg and cfg.features and cfg.features.enable_diagnostics == false then
      if Core.log_info then Core.log_info("Diagnostics disabled by config: " .. (debug.getinfo(1,'S').source or '?')) end
      return
    end
  end
end
local root = (reaper.GetResourcePath().."/Scripts/IFLS/DF95/"):gsub("\\","/")
local function safe_run(file)
  local f=io.open(root..file,"rb"); if not f then return false end
  f:close(); dofile(root..file); return true
end

local ok1 = safe_run("DF95_Menu_StrictLinter.lua")
local ok2 = safe_run("DF95_Slicing_SmokeTest_v1.lua")
local ok3 = safe_run("DF95_Loudness_SWS_Analyze_Hook.lua")
local ok4 = safe_run("DF95_Diagnostics_RunAll.lua")

r.SetProjExtState(0, "DF95_INSTALL", "RUNONCE_DIAG", "1")
r.ShowMessageBox("DF95 First-Run Diagnostics:\nLinter="..tostring(ok1).." Smoke="..tostring(ok2)..
  " LoudnessHook="..tostring(ok3).." HTML="..tostring(ok4), "DF95", 0)
