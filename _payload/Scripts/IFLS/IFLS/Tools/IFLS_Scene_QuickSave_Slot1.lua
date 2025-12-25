-- IFLS_Scene_QuickSave_Slot1.lua
-- Phase 13: Quick save current state into Scene Slot 1

local r = reaper
local resource_path = r.GetResourcePath()
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok, scenedom = pcall(dofile, domain_path .. "IFLS_SceneDomain.lua")
if not ok or type(scenedom) ~= "table" then
  r.ShowMessageBox("Scene QuickSave: IFLS_SceneDomain.lua konnte nicht geladen werden.", "IFLS Scene", 0)
  return
end

scenedom.save_scene(1, "Scene 1")
r.ShowMessageBox("Scene 1 gespeichert.", "IFLS Scene QuickSave", 0)
