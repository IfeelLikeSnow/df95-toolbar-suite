
-- @description PostInstall ThemeAdaptive Hook
-- @version 1.0
-- @about Führt den ThemeAdaptive Loader einmal aus und fordert Toolbar-Refresh an.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local loader = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ThemeAdaptive_Loader.lua"
local ok, err = pcall(dofile, loader)
if not ok then
  r.ShowConsoleMsg("[DF95] ThemeAdaptive Loader Fehler: "..tostring(err).."\n")
else
  -- kurz Toolbar-Dialog öffnen/schließen erzwingt Icon-Refresh
  r.Main_OnCommand(40016,0) -- Customize menus/toolbars
end
