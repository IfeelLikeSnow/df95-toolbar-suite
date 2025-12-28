-- @description Master Selector (Dropdown)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local helper = dofile(res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_Menu_Helper.lua")
local loader = dofile(res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_FXChain_Loader.lua")
local index = helper.readjson(res..sep.."Data"..sep.."DF95"..sep.."DF95_Master_Index.json")
local menu, entries, paths = helper.flat_menu_from_index(index)
r.gfx.init("DF95: Master Selector", 260, 38, 0, 400, 240)
local choice = r.gfx.showmenu(menu)
r.gfx.quit()
if choice>0 then
  local p = paths[choice]
  local fp = res..sep.."FXChains"..sep.."DF95"..sep.."Master"..sep..p.rel:gsub("/", sep)
  loader(fp, true)
end
