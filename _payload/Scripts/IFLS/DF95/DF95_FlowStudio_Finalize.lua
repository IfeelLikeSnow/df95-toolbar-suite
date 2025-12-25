-- @description FlowStudio Finalize (ThemeSync + Toolbar + Icons)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function run_by_path(p)
  local cmd = r.NamedCommandLookup(("_RS %s"):format(p))
  if cmd == 0 then return false end
  r.Main_OnCommand(cmd, 0); return true
end
local base = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep
run_by_path(base.."DF95_ThemeSync_Apply.lua")
r.Main_OnCommand(40016,0) -- Customize menus/toolbars
run_by_path(base.."DF95_AutoIcon_Assign_ThemeAware.lua")
r.ShowMessageBox("DF95 Finalize:\n- ThemeSync angewendet\n- Toolbar-Fenster geöffnet\n- Icons gesetzt (theme-aware)\n\nImportiere jetzt Menus/DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet und klicke Apply.","DF95 FlowStudio",0)

reaper.ShowMessageBox("DF95 Template installiert:\nFile → Project templates → DF95_Default_Session_Template","DF95 Template",0)
