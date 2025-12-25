-- DF95_Menu_QASafety_Hub.lua (V3 Hub Entrypoint)
-- This entry script is kept for backward compatibility (Action stays the same).
-- It delegates to the central hub definitions in Scripts/DF95Framework/Menus/DF95_Hubs.lua

local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

local Hubs = dofile(base .. "/Scripts/DF95Framework/Menus/DF95_Hubs.lua")
Hubs.run_hub("qa_hub")


--[[
LEGACY CONTENT (preserved for reference):
-- @description QA & Safety Hub
-- @version 1.1
-- @author DF95
-- Safety/Loudness, Fix Chains, Snapshots, SmokeTests, Missing Plugins & META-Tools.

local r = reaper

-- V3 Feature Flags (menu flag-aware)
local __df95_base = reaper.GetResourcePath():gsub("\\","/")
local __df95_Core = dofile(__df95_base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
local __df95_cfg = (__df95_Core and __df95_Core.get_config) and __df95_Core.get_config() or {}

if __df95_cfg.features and __df95_cfg.features.enable_diagnostics == false then
  local MB = dofile(__df95_base .. "/Scripts/DF95Framework/Lib/DF95_MenuBuilder.lua")
  MB.show_disabled_menu({
    title = "DF95 Menü",
    reason = "Diagnostics deaktiviert",
    config_path = __df95_base .. "/Support/DF95_Config.json"
  })
  return
end

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function run_rel(rel_path)
  local path = (res .. sep .. rel_path):gsub("\\","/")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox(
      "Konnte Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 QA & Safety Hub", 0
    )
    return
  end
  f()
end

local function main()
  local menu =
    "DF95 – QA & Safety||" ..
    "Safety / Loudness Menu|" ..
    "Fix Chains – GainStage|" ..
    "Fix Chains – LiveMode|" ..
    "Master Snapshot (Save/Restore)|" ..
    "LiveCheck (First Run)|" ..
    "AutoSmokeTest (Chains)|" ..
    "Diagnostics RunAll|" ..
    "MissingPlugin Reporter|" ..
    "MissingPlugin AutoPatch|" ..
    "META Bulk Wizard|" ..
    "META Helper GUI|"

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 QASafety", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."QA"..sep.."DF95_Safety_Loudness_Menu.lua")
  elseif idx == 3 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Fix_Chain_GainStage.lua")
  elseif idx == 4 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Fix_Chain_LiveMode.lua")
  elseif idx == 5 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."QA"..sep.."DF95_Master_Snapshot.lua")
  elseif idx == 6 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."QA"..sep.."DF95_FirstRun_LiveCheck.lua")
  elseif idx == 7 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_AutoSmokeTest_v1.lua")
  elseif idx == 8 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Diagnostics_RunAll.lua")
  elseif idx == 9 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_MissingPlugin_Reporter.lua")
  elseif idx == 10 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_MissingPlugin_AutoPatch.lua")
  elseif idx == 11 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_META_Bulk_Wizard.lua")
  elseif idx == 12 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_META_Helper_GUI.lua")
  end
end

main()

]]
