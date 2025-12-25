-- @description ThemeSync – auto-adapt DF95 UX profile to active theme
-- @version 1.0
-- @author IfeelLikeSnow
-- Reads current REAPER theme and writes DF95_UX_Profile.json with Balanced Studio defaults if DF95_BalancedStudio is active.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function write_profile(dst, prof)
  local jf = io.open(dst,"wb"); if not jf then return false end
  jf:write(prof); jf:close(); return true
end

local theme_file = r.GetLastColorThemeFile and r.GetLastColorThemeFile() or ""
local theme = (theme_file:match("([^"..sep.."]+)%.ReaperTheme") or theme_file:match("([^"..sep.."]+)%.ReaperThemeZip") or "Default")

-- Target UX profile path
local dst_profile = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_UX_Profile.json"

-- Balanced Studio palette
local palette = {
  base="#3E3E3E", spacer="#6A6A6A",
  setup="#2EAFC3", fx="#77B29C", color="#D9A441", master="#8273A9"
}

-- Spacer width heuristics per common themes
local spacer = "auto"
local density = "normal"
local lower = theme:lower()
if lower:find("hydra") then spacer="wide"; density="compact" end
if lower:find("commala") then spacer="narrow" end
if lower:find("imperial") or lower:find("lcs") then spacer="wide" end

-- Build profile JSON
local json = string.format([[{
  "theme":"%s","spacer":"%s","icon_variant":"mono","density":"%s","hover":"#A0A0A0",
  "palette":{"base":"%s","spacer":"%s","setup":"%s","fx":"%s","color":"%s","master":"%s"}
}]], theme, spacer, density, palette.base, palette.spacer, palette.setup, palette.fx, palette.color, palette.master)

if write_profile(dst_profile, json) then
  r.ShowMessageBox("DF95 ThemeSync: Profil aktualisiert für Theme: "..theme, "DF95 ThemeSync", 0)
else
  r.ShowMessageBox("DF95 ThemeSync: Konnte Profil nicht schreiben:\n"..dst_profile, "DF95 ThemeSync", 0)
end
