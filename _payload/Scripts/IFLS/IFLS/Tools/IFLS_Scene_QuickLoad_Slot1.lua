-- IFLS_Scene_QuickLoad_Slot1.lua
-- Phase 13: Quick load Scene Slot 1

local r = reaper
local resource_path = r.GetResourcePath()
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok, scenedom = pcall(dofile, domain_path .. "IFLS_SceneDomain.lua")
if not ok or type(scenedom) ~= "table" then
  r.ShowMessageBox("Scene QuickLoad: IFLS_SceneDomain.lua konnte nicht geladen werden.", "IFLS Scene", 0)
  return
end

local ok_load, err = scenedom.load_scene(1)
if not ok_load then
  r.ShowMessageBox("Scene QuickLoad: " .. tostring(err), "IFLS Scene", 0)
else
  r.ShowMessageBox("Scene 1 geladen.", "IFLS Scene QuickLoad", 0)
end
