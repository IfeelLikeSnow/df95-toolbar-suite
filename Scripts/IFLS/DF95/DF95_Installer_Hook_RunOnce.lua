
-- @description Installer Hook (Run Once) – Linter + Smoke
-- @version 1.0
local r = reaper
local _, done = r.GetProjExtState(0,"DF95_INSTALL","RUNONCE")
if done == "1" then return end

local root = r.GetResourcePath().."/Scripts/IFLS/DF95/"
local function run(name)
  local f = io.open(root..name, "rb"); if f then f:close(); dofile(root..name); return true end
  return false
end

local ok1 = run("DF95_Menu_StrictLinter.lua")
local ok2 = run("DF95_AutoSmokeTest_v1.lua")
local ok3 = run("DF95_Slicing_SmokeTest_v1.lua")

r.SetProjExtState(0,"DF95_INSTALL","RUNONCE","1")
r.ShowMessageBox("DF95 Installer Hook: Linter("..tostring(ok1)..") Smoke("..tostring(ok2)..") SliceSmoke("..tostring(ok3)..") – erledigt.", "DF95", 0)
