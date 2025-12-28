-- @description Input & LUFS Hub
-- @version 1.1
-- @author DF95
-- MicFX, GainMatch, LUFS AutoTarget und SWS-LUFS-Hooks in einem Menü.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function run_rel(rel_path)
  local path = (res .. sep .. rel_path):gsub("\\","/")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox(
      "Konnte Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 Input & LUFS Hub", 0
    )
    return
  end
  f()
end

local function main()
  local menu =
    "DF95 – Input & LUFS||" ..
    "Mic FX Manager|" ..
    "GainMatch A/B|" ..
    "LUFS AutoTarget (Autopilot)|" ..
    "SWS LUFS Hook (Setup)|" ..
    "LUFS AutoGain from SWS|"

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 InputLUFS", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_MicFX_Manager.lua")
  elseif idx == 3 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_GainMatch_AB.lua")
  elseif idx == 4 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Input"..sep.."DF95_LUFS_AutoTarget.lua")
  elseif idx == 5 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_SWS_LUFS_Hook.lua")
  elseif idx == 6 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_LUFS_AutoGain_FromSWS.lua")
  end
end

main()
