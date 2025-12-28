-- DF95 integration: if Artist Console ImGui is available, launch it directly
do
  local ok_imgui = reaper.ImGui_CreateContext ~= nil
  local sep = package.config:sub(1,1)
  local res = reaper.GetResourcePath()

  -- 1) Prefer Artist Console
  local console_path = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_ArtistConsole_ImGui.lua"):gsub("\\","/")
  local console_file = io.open(console_path, "r")
  if ok_imgui and console_file then
    console_file:close()
    local ok, err = pcall(dofile, console_path)
    if not ok then
      reaper.ShowMessageBox("Fehler beim Starten der DF95 Artist Console:\n" .. tostring(err), "DF95 Slicing & Edit Hub", 0)
    end
    return
  end

  -- 2) Fallback: Slicing Hub
  local hub_path = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_SlicingHub_ImGui.lua"):gsub("\\","/")
  local hub_file = io.open(hub_path, "r")
  if ok_imgui and hub_file then
    hub_file:close()
    local ok, err = pcall(dofile, hub_path)
    if not ok then
      reaper.ShowMessageBox("Fehler beim Starten des DF95 Slicing Hub:\n" .. tostring(err), "DF95 Slicing & Edit Hub", 0)
    end
    return
  end
end

-- @description Slicing & Edit Hub
-- @version 1.1
-- @author DF95
-- Bündelt Slicing, Rearrange, LoopBuilder, Fades & ZeroCross-Tools.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function run_rel(rel_path)
  local path = (res .. sep .. rel_path):gsub("\\","/")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox(
      "Konnte Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 Slicing & Edit Hub", 0
    )
    return
  end
  f()
end

local function main()
  local menu =
    "DF95 – Slicing & Edit||" ..
    "Slice (Direct)|" ..
    "Slicing Master Menu|" ..
    "Slicing Dropdown|" ..
    "Weighted Slice Menu|" ..
    "Rearrange / Align|" ..
    "Loop / Rhythm Builder|" ..
    "Fades & Timing Helper|" ..
    "Slicing – Toggle ZeroCross|" ..
    "Slicing – ZeroCross PostFix|"

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 SlicingHub", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Edit"..sep.."DF95_Slice_Direct.lua")
  elseif idx == 3 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95_Slicing"..sep.."DF95_Slicing_Master_Menu.lua")
  elseif idx == 4 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Menu_Slicing_Dropdown.lua")
  elseif idx == 5 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_Slice_Menu_Weighted.lua")
  elseif idx == 6 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Edit"..sep.."DF95_Rearrange_Align.lua")
  elseif idx == 7 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_LoopBuilder.lua")
  elseif idx == 8 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Edit"..sep.."DF95_Fades_Timing_Helper.lua")
  elseif idx == 9 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Slicing_Toggle_ZeroCross.lua")
  elseif idx == 10 then
    run_rel("Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Slicing_ZeroCross_PostFix.lua")
  end
end

main()
