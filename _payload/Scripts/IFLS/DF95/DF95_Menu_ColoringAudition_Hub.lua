-- DF95_Menu_ColoringAudition_Hub.lua (V3 Hub Entrypoint)
-- Backward compatible Action: delegates to central hub definitions.
local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

local Hubs = dofile(base .. "/Scripts/DF95Framework/Menus/DF95_Hubs.lua")
Hubs.run_hub("coloring_audition")

--[[ 
LEGACY implementation preserved at:
  DF95_Menu_ColoringAudition_Hub_Legacy.lua
]]


--[[
LEGACY CONTENT (preserved for reference):
-- @description Coloring & Audition Hub
-- @version 1.1
-- @author DF95
-- Bündelt Coloring Dropdown, Audition-Loader, FXBus- und Master-Audition, GainMatch A/B.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function run_rel(rel_path)
  local path = (res .. sep .. rel_path):gsub("\\","/")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox(
      "Konnte Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 Coloring & Audition Hub", 0
    )
    return
  end
  f()
end

local function main()
  local menu =
    "DF95 – Coloring & Audition Hub||" ..
    "Coloring Dropdown (v2b)|" ..
    "Coloring – Load with Audition|" ..
    "Coloring – Load with LUFS Audition|" ..
    "FX Bus Audition|" ..
    "Master Audition|" ..
    "Coloring A/B (GainMatch)|"

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 ColorHub", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_Menu_Coloring_Dropdown_v2b.lua")
  elseif idx == 3 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Coloring_Load_Audition.lua")
  elseif idx == 4 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Coloring_Load_Audition_LUFS.lua")
  elseif idx == 5 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_FXBus_Audition_v1.lua")
  elseif idx == 6 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_Master_Audition_v1.lua")
  elseif idx == 7 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_GainMatch_AB.lua")
  end
end

main()

]]
