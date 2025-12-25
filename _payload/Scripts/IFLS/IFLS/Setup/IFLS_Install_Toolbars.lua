-- IFLS_Install_Toolbars.lua
-- Phase 94: Toolbar Installer for IFLS
--
-- This script copies the IFLS toolbar definition files from the IFLS
-- repo into REAPER's MenuSets folder (inside the REAPER resource path).
--
-- It does NOT modify reaper-menu.ini or automatically assign toolbars
-- to slots. After running, you can:
--   * open "Customize toolbars..." in REAPER
--   * import the IFLS toolbars into any toolbar pages you like.
--
-- The script:
--   * detects the IFLS repo root from the script location
--   * looks for MenuSets/IFLS_*.Toolbar.ReaperMenu in the repo
--   * copies them into <resourcepath>/MenuSets
--   * makes simple .bak backups if files already exist.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function dirname(path)
  local sep = package.config:sub(1,1)
  return path:match("^(.*" .. sep .. ")") or path
end

local function strip_trailing_sep(path)
  local sep = package.config:sub(1,1)
  if path:sub(-1) == sep then
    return path:sub(1, -2)
  end
  return path
end

local function join(a, b)
  local sep = package.config:sub(1,1)
  a = strip_trailing_sep(a)
  if a == "" then return b end
  return a .. sep .. b
end

local function ensure_dir(path)
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(path, 0)
  end
end

local function file_exists(path)
  if r.file_exists then
    return r.file_exists(path)
  end
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function copy_file(src, dst)
  local f_in, err_in = io.open(src, "rb")
  if not f_in then
    return false, "cannot open src: " .. tostring(err_in)
  end
  local data = f_in:read("*a")
  f_in:close()

  local f_out, err_out = io.open(dst, "wb")
  if not f_out then
    return false, "cannot open dst: " .. tostring(err_out)
  end
  f_out:write(data or "")
  f_out:close()
  return true
end

-- 1) Determine repo root from this script location
local _, script_path = r.get_action_context()
local sep = package.config:sub(1,1)

script_path = strip_trailing_sep(script_path)
local script_dir = dirname(script_path)                 -- .../IFLS/Setup/
script_dir = strip_trailing_sep(script_dir)
local ifls_dir   = dirname(script_dir)                  -- .../IFLS/
ifls_dir = strip_trailing_sep(ifls_dir)
local ifls_parent= dirname(ifls_dir)                    -- .../IfeelLikeSnow/
ifls_parent = strip_trailing_sep(ifls_parent)
local scripts_dir= dirname(ifls_parent)                 -- .../Scripts/
scripts_dir = strip_trailing_sep(scripts_dir)
local repo_root  = dirname(scripts_dir)                 -- repo root
repo_root = strip_trailing_sep(repo_root)

-- Fallback: if the above fails, just go three parents up
if not repo_root or repo_root == "" then
  local p = script_dir
  for i = 1,3 do
    p = strip_trailing_sep(p)
    p = dirname(p)
  end
  repo_root = strip_trailing_sep(p)
end

local repo_menusets = join(repo_root, "MenuSets")
local resource_path = r.GetResourcePath()
local dest_menusets = join(resource_path, "MenuSets")

local toolbars = {
  "IFLS_Main.Toolbar.ReaperMenu",
  "IFLS_Beat.Toolbar.ReaperMenu",
  "IFLS_Sample.Toolbar.ReaperMenu",
  "IFLS_Debug.Toolbar.ReaperMenu",
}

local existing = {}
local copied   = {}
local errors   = {}

if not file_exists(repo_menusets) then
  r.ShowMessageBox(
    "Konnte IFLS MenuSets-Ordner nicht finden:\n\n" ..
    repo_menusets ..
    "\n\nStelle sicher, dass das IFLS-Repo korrekt installiert ist.",
    "IFLS Toolbar Installer",
    0
  )
  return
end

ensure_dir(dest_menusets)

for _, fname in ipairs(toolbars) do
  local src = join(repo_menusets, fname)
  local dst = join(dest_menusets, fname)

  if not file_exists(src) then
    table.insert(errors, "Fehlt in Repo: " .. src)
  else
    if file_exists(dst) then
      local bak = dst .. ".bak"
      local ok_bak, err_bak = copy_file(dst, bak)
      if ok_bak then
        table.insert(existing, string.format("%s (Backup: %s)", dst, bak))
      else
        table.insert(errors, "Backup fehlgeschlagen für " .. dst .. ": " .. tostring(err_bak))
      end
    end

    local ok, err = copy_file(src, dst)
    if ok then
      table.insert(copied, dst)
    else
      table.insert(errors, "Kopieren fehlgeschlagen für " .. dst .. ": " .. tostring(err))
    end
  end
end

local summary = {}
table.insert(summary, "IFLS Toolbar Installer – Ergebnis:")
table.insert(summary, "")
table.insert(summary, "Repo-MenuSets:  " .. repo_menusets)
table.insert(summary, "Ziel-MenuSets:  " .. dest_menusets)
table.insert(summary, "")

if #copied > 0 then
  table.insert(summary, "Kopiert:")
  for _, p in ipairs(copied) do
    table.insert(summary, "  - " .. p)
  end
  table.insert(summary, "")
end

if #existing > 0 then
  table.insert(summary, "Bestehende Dateien (mit .bak gesichert):")
  for _, p in ipairs(existing) do
    table.insert(summary, "  - " .. p)
  end
  table.insert(summary, "")
end

if #errors > 0 then
  table.insert(summary, "Fehler:")
  for _, e in ipairs(errors) do
    table.insert(summary, "  - " .. e)
  end
  table.insert(summary, "")
end

local summary_str = table.concat(summary, "\n")

msg(summary_str)

r.ShowMessageBox(
  summary_str ..
  "\n\nNächste Schritte:\n" ..
  "1) In REAPER: View > Toolbars > Customize Toolbars…\n" ..
  "2) Freie Toolbar wählen, Import… klicken\n" ..
  "3) Eine der IFLS_*.Toolbar.ReaperMenu-Dateien aus dem MenuSets-Ordner auswählen.\n" ..
  "4) Buttons bei Bedarf neu anordnen/andocken.\n",
  "IFLS Toolbar Installer",
  0
)
