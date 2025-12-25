-- @description ThemeZip Auto-Install + ThemeSync
-- @version 1.0
-- Copies DF95_BalancedStudio.ReaperThemeZip into ColorThemes and runs ThemeSync

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function script_dir()
  local info = debug.getinfo(1,'S').source:sub(2)
  return info:match("^(.*"..sep..")") or ""
end

local function copy(src,dst)
  local f=io.open(src,"rb"); if not f then return false end
  local d=f:read("*all"); f:close()
  local g=io.open(dst,"wb"); if not g then return false end
  g:write(d); g:close(); return true
end

local root = script_dir():gsub(sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."?$","")
if root == "" then r.ShowMessageBox("Quellpfad nicht ermittelt.","DF95 ThemeZip Auto-Install",0) return end

local src_zip = root .. "DF95_BalancedStudio.ReaperThemeZip"
local dst_zip = res .. sep .. "ColorThemes" .. sep .. "DF95_BalancedStudio.ReaperThemeZip"
local ok = copy(src_zip, dst_zip)
if not ok then r.ShowMessageBox("Kopieren fehlgeschlagen:\n"..src_zip,"DF95 ThemeZip Auto-Install",0) return end

r.ShowMessageBox("ThemeZip kopiert:\nOptions → Themes → Import → DF95_BalancedStudio.ReaperThemeZip\nDanach DF95_ThemeSync_Apply.lua ausführen.","DF95 ThemeZip Auto-Install",0)
