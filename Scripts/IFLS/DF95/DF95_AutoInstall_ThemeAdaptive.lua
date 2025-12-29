-- @description AutoInstall + Theme-Adaptive UX (FlowErgo Creative v1)
-- @version 1.47.1
-- @author IfeelLikeSnow
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function ensure_dir(p) return r.RecursiveCreateDirectory(p,0) ~= 0 end
local function copy(src,dst)
  local f=io.open(src,"rb"); if not f then return false,"open src" end
  local d=f:read("*all"); f:close()
  local g=io.open(dst,"wb"); if not g then return false,"open dst" end
  g:write(d); g:close(); return true
end
local function script_dir()
  local info = debug.getinfo(1,'S').source:sub(2)
  return info:match("^(.*"..sep..")") or ""
end
local src_root = script_dir():gsub(sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."?$","")
if src_root == "" then r.ShowMessageBox("Quellpfad nicht gefunden.","DF95 AutoInstall",0) return end
local dst_menus   = res .. sep .. "Menus"
local dst_scripts = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
local dst_icons   = res .. sep .. "Data" .. sep .. "toolbar_icons" .. sep .. "DF95"
ensure_dir(dst_menus); ensure_dir(dst_scripts); ensure_dir(dst_icons)
local src_toolbar = src_root .. "Menus"..sep.."DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet"
local dst_toolbar = dst_menus .. sep .. "DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet"
local ok,err = copy(src_toolbar, dst_toolbar); if not ok then r.ShowMessageBox("Toolbar-Kopie fehlgeschlagen: "..(err or "?"),"DF95 AutoInstall",0) return end
local theme_file = r.GetLastColorThemeFile and r.GetLastColorThemeFile() or ""
local theme = (theme_file:match("([^"..sep.."]+)%.ReaperTheme") or theme_file:match("([^"..sep.."]+)%.ReaperThemeZip") or "Default"):lower()
local palette = { base="#3E3E3E", spacer="#6A6A6A", setup="#2EAFC3", fx="#77B29C", color="#D9A441", master="#8273A9" }
local profile = { theme=theme, spacer="auto", icon_variant="mono", density="normal", hover="#A0A0A0" }
if theme:find("hydra") then profile.spacer="wide"; profile.density="compact" end
if theme:find("commala") then profile.spacer="narrow" end
if theme:find("imperial") or theme:find("lcs") then profile.spacer="wide" end
local jf = io.open(dst_scripts..sep.."DF95_UX_Profile.json","wb")
if jf then
  local j = string.format([[{
    "theme":"%s","spacer":"%s","icon_variant":"%s","density":"%s","hover":"%s",
    "palette":{"base":"%s","spacer":"%s","setup":"%s","fx":"%s","color":"%s","master":"%s"}
  }]], profile.theme, profile.spacer, profile.icon_variant, profile.density, profile.hover,
        palette.base, palette.spacer, palette.setup, palette.fx, palette.color, palette.master)
  jf:write(j); jf:close()
end
r.Main_OnCommand(40016,0)
r.ShowMessageBox("DF95 AutoInstall abgeschlossen. Importiere die Toolbar und Apply.","DF95 AutoInstall",0)
