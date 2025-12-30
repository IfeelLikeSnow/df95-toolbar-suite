-- @description DF95/IFLS OneClick Setup (Theme + Toolbars) - DEFAULT: IFLS_Main.Toolbar.ReaperMenu
-- @version 1.0.1
-- @author DF95 (packaging helper by Reaper DAW Ultimate Assistant)
-- @about
--   OneClick bootstrap for DF95/IFLS:
--   - Ensures REAPER\ResourcePath\MenuSets exists
--   - Copies DF95/IFLS *.ReaperMenuSet and *.ReaperMenu into MenuSets (so they can be loaded from Customize menus/toolbars)
--   - Installs DF95_BalancedStudio theme into ColorThemes and applies it
--   - Guides you to import IFLS_Main.Toolbar.ReaperMenu as the default toolbar/menu preset
--
--   Safe to run multiple times (overwrites destination files).

local function msg(s) reaper.ShowConsoleMsg(tostring(s) .. "\n") end

local function join(a,b)
  if not a or a=="" then return b end
  local last = a:sub(-1)
  if last == "\\" or last == "/" then return a .. b end
  return a .. "/" .. b
end

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

local function ensure_dir(path)
  reaper.RecursiveCreateDirectory(path, 0)
end

local function copy_file(src, dst)
  local f = io.open(src, "rb")
  if not f then return false, "cannot open src" end
  local data = f:read("*all")
  f:close()
  ensure_dir(dst:match("^(.*)[/\\].-$") or "")
  local o = io.open(dst, "wb")
  if not o then return false, "cannot open dst" end
  o:write(data)
  o:close()
  return true
end

local function list_files(dir, ext_lower)
  local out = {}
  local i = 0
  while true do
    local file = reaper.EnumerateFiles(dir, i)
    if not file then break end
    i = i + 1
    if not ext_lower or file:lower():sub(-#ext_lower) == ext_lower then
      out[#out+1] = join(dir, file)
    end
  end
  return out
end

local function dir_exists(dir)
  return reaper.EnumerateFiles(dir, 0) ~= nil or reaper.EnumerateSubdirectories(dir, 0) ~= nil
end

local function copy_menusets_from(src_dir, dst_dir)
  if not dir_exists(src_dir) then
    return 0, ("skip (missing dir): " .. src_dir)
  end

  local count = 0
  for _, ext in ipairs({".reapermenuset", ".reapermenu"}) do
    for _, src in ipairs(list_files(src_dir, ext)) do
      local filename = src:match("([^/\\]+)$")
      local dst = join(dst_dir, filename)
      local ok, err = copy_file(src, dst)
      if ok then
        count = count + 1
      else
        msg("  ! failed: " .. filename .. " (" .. tostring(err) .. ")")
      end
    end
  end
  return count
end

local function apply_theme(resource)
  local colorThemes = join(resource, "ColorThemes")
  ensure_dir(colorThemes)

  local candidates = {
    join(resource, "DF95_BalancedStudio.ReaperThemeZip"),
    join(resource, "Theme/DF95_BalancedStudio.ReaperThemeZip"),
    join(resource, "Theme/DF95_BalancedStudio.ReaperTheme"),
    join(resource, "DF95_BalancedStudio.ReaperTheme"),
  }

  local src = nil
  for _, p in ipairs(candidates) do
    if exists(p) then src = p break end
  end

  if not src then
    msg("[DF95][WARN] Theme not found in expected locations. Skipping theme install/apply.")
    return false
  end

  local filename = src:match("([^/\\]+)$")
  local dst = join(colorThemes, filename)

  local ok, err = copy_file(src, dst)
  if not ok then
    msg("[DF95][ERROR] Failed copying theme to ColorThemes: " .. tostring(err))
    return false
  end

  msg("[DF95] Theme installed: " .. dst)

  local ok_apply = reaper.OpenColorThemeFile(dst)
  if ok_apply then
    msg("[DF95] Theme applied.")
  else
    msg("[DF95][WARN] Theme copied but could not be applied automatically. Use Options > Themes to select it.")
  end
  return true
end

-- MAIN
reaper.ClearConsole()
msg("DF95/IFLS OneClick Setup: Theme + Toolbars (Default: IFLS_Main.Toolbar.ReaperMenu)")
local resource = reaper.GetResourcePath()
msg("ResourcePath: " .. resource)

-- Ensure MenuSets exists
local menuSetsDir = join(resource, "MenuSets")
ensure_dir(menuSetsDir)
msg("MenuSets ensured: " .. menuSetsDir)

-- Copy menu/toolbar sets from known install locations (per your index.xml)
local total = 0
for _, dir in ipairs({
  join(resource, "Menus"),
  join(resource, "Toolbars"),
  join(resource, "MenuSets"), -- in case pack already shipped some
}) do
  msg("Scanning: " .. dir)
  local c, note = copy_menusets_from(dir, menuSetsDir)
  if note then msg("  " .. note) end
  total = total + (c or 0)
end
msg(("MenuSets installed/updated: %d file(s)"):format(total))

-- Apply theme
apply_theme(resource)

-- Default target: IFLS_Main.Toolbar.ReaperMenu
local defaultFile = "IFLS_Main.Toolbar.ReaperMenu"
local defaultDst = join(menuSetsDir, defaultFile)

msg("")
msg("DEFAULT TOOLBAR PRESET:")
if exists(defaultDst) then
  msg("  Found: " .. defaultDst)
else
  msg("  [WARN] Not found in MenuSets: " .. defaultDst)
  msg("  If it exists elsewhere in your repo, ensure it's included in the Resources pack and re-run this installer.")
end

msg("")
msg("NEXT STEPS (manual import inside REAPER):")
msg("1) Open: Options > Customize menus/toolbars...")
msg("2) Click: Import...")
msg("3) Select: " .. defaultFile)
msg("4) Enable toolbars via View > Toolbars (Toolbar 1..n) as desired.")
msg("5) If icons look missing: restart REAPER once (toolbar icon cache).")
