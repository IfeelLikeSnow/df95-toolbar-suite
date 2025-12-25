-- IFLS_OpenMasterHub.lua
-- Convenience script: opens IFLS_MasterHub_ImGui.lua

local r = reaper
local resource_path = r.GetResourcePath()
local hub_path = resource_path .. "/Scripts/IFLS/IFLS/Hubs/IFLS_MasterHub_ImGui.lua"

local ok, err = pcall(dofile, hub_path)
if not ok then
  r.ShowMessageBox("IFLS_OpenMasterHub: Konnte IFLS_MasterHub_ImGui.lua nicht laden:\n" .. tostring(err),
                   "IFLS Open Master Hub", 0)
end
