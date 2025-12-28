-- @description Bus & Routing Hub
-- @version 1.1
-- @author DF95
-- Öffnet ein Menü für AutoBus, FX-Bus, Coloring, Master und Mic FX.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function run_rel(rel_path)
  local path = (res .. sep .. rel_path):gsub("\\","/")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox(
      "Konnte Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 Bus & Routing Hub", 0
    )
    return
  end
  f()
end

local function main()
  local menu =
    "DF95 – Bus & Routing Hub||" ..
    "Explode AutoBus|" ..
    "FX Bus Selector|" ..
    "FX Bus Seed (Randomize)|" ..
    "Coloring Bus Selector|" ..
    "Master Bus Selector|" ..
    "Mic FX Manager|"

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 BusHub", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Explode_AutoBus.lua")
  elseif idx == 3 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_FXBus_Selector.lua")
  elseif idx == 4 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_FXBus_Seed.lua")
  elseif idx == 5 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ColoringBus_Selector.lua")
  elseif idx == 6 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_MasterBus_Selector.lua")
  elseif idx == 7 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_MicFX_Manager.lua")
  end
end

main()
