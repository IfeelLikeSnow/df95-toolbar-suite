-- @description Bias & Humanize Hub
-- @version 1.1
-- @author DF95
-- Humanize-Menü + Bias-Snapshots + Profil-Switcher + Clamp-Shortcuts in einem Hub.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function run_rel(rel_path)
  local path = (res .. sep .. rel_path):gsub("\\","/")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox(
      "Konnte Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 Bias & Humanize Hub", 0
    )
    return
  end
  f()
end

local function main()
  local menu =
    "DF95 – Bias & Humanize Hub||" ..
    "Humanize (Dropdown)|" ..
    "Bias Snapshot – Neutral|" ..
    "Bias Snapshot – IDM|" ..
    "Bias Snapshot – Glitch|" ..
    "Bias Snapshot – BoC Warm|" ..
    "Bias Profile Switcher|" ..
    "ArtistBias Tuner GUI|" ..
    "Humanize Clamp LUFS ±1.0|" ..
    "Humanize Clamp LUFS ±1.3|" ..
    "Humanize Clamp LUFS ±2.0|"

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 BiasHub", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Menu_Humanize_Dropdown.lua")
  elseif idx == 3 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_BiasSnapshot_Neutral.lua")
  elseif idx == 4 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_BiasSnapshot_IDM.lua")
  elseif idx == 5 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_BiasSnapshot_Glitch.lua")
  elseif idx == 6 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_BiasSnapshot_BoC_Warm.lua")
  elseif idx == 7 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_Bias_Profile_Switcher.lua")
  elseif idx == 8 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_ArtistBias_Tuner_GUI.lua")
  elseif idx == 9 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_SetClamp_LUFS_1_0.lua")
  elseif idx == 10 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_SetClamp_LUFS_1_3.lua")
  elseif idx == 11 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_SetClamp_LUFS_2_0.lua")
  end
end

main()
