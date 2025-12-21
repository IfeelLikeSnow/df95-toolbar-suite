-- IFLS_SyncTuning_AllTracks.lua
-- Phase 11: Sync IFLS_TuningDomain -> all IFLS_MIDIProcessor instances.

local r = reaper
local resource_path = r.GetResourcePath()
local tools_path    = resource_path .. "/Scripts/IFLS/IFLS/Tools/"

local ok, bridge = pcall(dofile, tools_path .. "IFLS_TuningBridge.lua")
if not ok or type(bridge) ~= "table" then
  r.ShowMessageBox("IFLS_SyncTuning_AllTracks: IFLS_TuningBridge.lua konnte nicht geladen werden.", "IFLS Tuning Sync", 0)
  return
end

local count = bridge.sync_all()
r.ShowMessageBox("TuningSync: " .. tostring(count) .. " IFLS_MIDIProcessor-Instanzen synchronisiert.", "IFLS Tuning Sync", 0)
