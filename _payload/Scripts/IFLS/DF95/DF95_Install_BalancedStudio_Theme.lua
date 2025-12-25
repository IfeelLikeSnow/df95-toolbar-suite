-- @description DF95: Install BalancedStudio Theme to ColorThemes
-- @version 1.0
-- @author DF95
-- @about
--   Kopiert die DF95_BalancedStudio.ReaperThemeZip aus dem REAPER-ResourcePath
--   in den Unterordner "ColorThemes", so dass das Theme in REAPER direkt
--   auswählbar ist (Options > Themes).
--
--   Verwendung:
--   - Stelle sicher, dass diese Script-Datei und die Theme-Zip aus dem
--     DF95-Repo in deinem REAPER-ResourcePath liegen.
--   - Starte dieses Script einmal über die Action List.
--   - Wähle danach in REAPER unter "Options > Themes" das
--     "DF95_BalancedStudio" Theme.

local r = reaper

local function msg(s)
  r.ShowMessageBox(s, "DF95 BalancedStudio Theme Installer", 0)
end

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local src = res .. sep .. "DF95_BalancedStudio.ReaperThemeZip"
local dst_dir = res .. sep .. "ColorThemes"
local dst = dst_dir .. sep .. "DF95_BalancedStudio.ReaperThemeZip"

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

if not file_exists(src) then
  msg("Die Datei 'DF95_BalancedStudio.ReaperThemeZip' wurde im REAPER-ResourcePath nicht gefunden.\n\n" ..
      "Bitte entpacke das DF95-Repo direkt in deinen ResourcePath\n" ..
      "oder kopiere die Theme-Zip manuell dorthin und starte das Script erneut.")
  return
end

-- sicherstellen, dass ColorThemes-Ordner existiert
r.RecursiveCreateDirectory(dst_dir, 0)

-- Datei kopieren
local in_f = io.open(src, "rb")
if not in_f then
  msg("Konnte die Theme-Datei nicht öffnen:\n" .. src)
  return
end
local data = in_f:read("*all")
in_f:close()

local out_f = io.open(dst, "wb")
if not out_f then
  msg("Konnte nicht in den ColorThemes-Ordner schreiben:\n" .. dst)
  return
end
out_f:write(data)
out_f:close()

msg("DF95_BalancedStudio.ReaperThemeZip wurde nach:\n\n" ..
    dst .. "\n\nkopiert.\n\n" ..
    "Du kannst das Theme jetzt in REAPER unter\n" ..
    "'Options > Themes' auswählen.")
