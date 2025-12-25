-- @description One-Click UI Master Installer (Balanced Studio)
-- @version 1.0
-- @author IfeelLikeSnow
-- Copies ThemeZip, Menus, Scripts, Icons. Runs ThemeSync and Icon Assign. Shows final import step.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function log(s) reaper.ShowConsoleMsg(tostring(s).."\n") end
local function ensure_dir(p) return r.RecursiveCreateDirectory(p,0) ~= 0 end

local function copy_file(src, dst)
  local f=io.open(src,"rb"); if not f then return false,"open src" end
  local d=f:read("*all"); f:close()
  local g=io.open(dst,"wb"); if not g then return false,"open dst" end
  g:write(d); g:close(); return true
end

local function copy_tree(src, dst)
  local okcnt, failcnt = 0,0
  for root,dirs,files in io.popen('dir "'..src..'" /b /s'):lines() do end -- noop (Windows only helper not used)
  return okcnt, failcnt
end

local function walk(dir, files)
  local p = io.popen(('cmd /c dir /b /s "%s"'):format(dir))
  if not p then return files end
  for line in p:lines() do
    local attr = r.EnumerateFiles and "" or "" -- not used; we rely on filesystem
    table.insert(files, line)
  end
  p:close(); return files
end

-- Resolve package root (folder where this script resides)
local function script_dir()
  local info = debug.getinfo(1,'S').source:sub(2)
  return info:match("^(.*"..sep..")") or ""
end

local root = script_dir():gsub(sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."?$","")
if root == "" then
  r.ShowMessageBox("Quellpfad nicht gefunden. Bitte Script direkt aus dem entpackten DF95 Master-ZIP starten.","DF95 Master Installer",0)
  return
end

-- Targets
local dst_color = res .. sep .. "ColorThemes"
local dst_menus = res .. sep .. "Menus"
local dst_icons_dark  = res .. sep .. "Data"..sep.."toolbar_icons"..sep.."DF95"..sep.."dark"
local dst_icons_light = res .. sep .. "Data"..sep.."toolbar_icons"..sep.."DF95"..sep.."light"
local dst_scripts = res .. sep .. "Scripts"..sep.."IFLS"..sep.."DF95"

ensure_dir(dst_color); ensure_dir(dst_menus); ensure_dir(dst_icons_dark); ensure_dir(dst_icons_light); ensure_dir(dst_scripts)

-- 1) Copy ThemeZip
local src_themezip = root .. "DF95_BalancedStudio.ReaperThemeZip"
local ok,err = copy_file(src_themezip, dst_color .. sep .. "DF95_BalancedStudio.ReaperThemeZip")
if not ok then r.ShowMessageBox("ThemeZip-Kopie fehlgeschlagen: "..(err or "?"),"DF95 Master Installer",0) return end

-- 2) Copy MenuSet (keep user's existing files, just add ours)
local src_menus = root .. "Menus"..sep.."DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet"
copy_file(src_menus, dst_menus .. sep .. "DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet")

-- 3) Copy Scripts (ThemeSync, ThemeZip AutoInstall, AutoIcon Assign, AutoInstall ThemeAdaptive, UX Helper)
local list_scripts = {
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ThemeSync_Apply.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ThemeZip_AutoInstall.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_AutoIcon_Assign.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_AutoIcon_Assign_ThemeAware.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_AutoInstall_ThemeAdaptive.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_UX_Helper_Spacers.lua"
}
for _,rel in ipairs(list_scripts) do
  local src = root .. rel
  local dst = res .. sep .. rel
  ensure_dir(dst:match("^(.*"..sep..")"))
  copy_file(src, dst)
end

-- 4) Copy Icons (dark/light sets if present)
local function copy_dir(srcDir, dstDir)
  local pattern = ('dir /b "%s"'):format(srcDir)
  local p = io.popen('cmd /c '..pattern)
  if p then
    for f in p:lines() do
      local s = srcDir..sep..f
      local d = dstDir..sep..f
      copy_file(s, d)
    end
    p:close()
  end
end

copy_dir(root.."Data"..sep.."toolbar_icons"..sep.."DF95"..sep.."dark",  dst_icons_dark)
copy_dir(root.."Data"..sep.."toolbar_icons"..sep.."DF95"..sep.."light", dst_icons_light)

-- 5) Run ThemeSync to write DF95_UX_Profile.json
local cmd = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ThemeSync_Apply.lua"
r.Main_OnCommand(r.NamedCommandLookup(("_RS %s"):format(cmd)), 0) -- invoke by absolute path via ReaScript alias

-- 6) Final message
r.ShowMessageBox(
  "DF95 Master UI installiert. Als nächstes:\n\n"..\
  "1) Options → Themes → Import → DF95_BalancedStudio.ReaperThemeZip (Theme wählen)\n"..\
  "2a) Options → Customize menus/toolbars → Main toolbar → Import → DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet → Apply\n"..\
  "2b) (Empfohlen) Zusätzlich/alternativ: eine freie Toolbar → Import → DF95_SuperToolbar_Main.ReaperMenuSet (inkl. BEAT / RHYTHM Hub)\n"..\
  "3) Actions → Run: DF95_AutoIcon_Assign_ThemeAware.lua (Icons automatisch setzen)\n\n"..\
  "Viel Spaß mit DF95 Balanced Studio UI + DF95 SuperToolbar!", "DF95 Master Installer", 0)


-- DF95 v1.48: install default session template (sanitized)
do
  local templDst = res..sep.."Projects"..sep.."Templates"
  ensure_dir(templDst)

  local function copyfile(src,dst)
    local f=io.open(src,"rb"); if not f then return false end
    local d=f:read("*all"); f:close()
    local g=io.open(dst,"wb"); if not g then return false end
    g:write(d); g:close(); return true
  end

  local function script_dir()
    local info = debug.getinfo(1,'S').source:sub(2)
    return info:match("^(.*"..sep..")") or ""
  end

  local root = script_dir():gsub(sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."?$","")
  local tplSrc = root.."Projects"..sep.."Templates"..sep.."DF95_Default_Session_Template.RPP"
  copyfile(tplSrc, templDst..sep.."DF95_Default_Session_Template.RPP")
end
