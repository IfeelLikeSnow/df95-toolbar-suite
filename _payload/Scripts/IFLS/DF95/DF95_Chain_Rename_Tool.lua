
-- DF95_Chain_Rename_Tool.lua
-- Hilfsscript zur Analyse und optionalen Minimal-Umbenennung von DF95-FXChains.
--
-- Standardmäßig DRY RUN (APPLY=false). Siehe Documentation/DF95_Chain_Naming_Policy.md

local r = reaper

local APPLY   = false  -- auf true setzen, um Umbenennungen wirklich zu schreiben
local VERBOSE = true

local function log(msg)
  if VERBOSE then
    r.ShowConsoleMsg(tostring(msg) .. "\n")
  end
end

local function join(a, b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then
    return a .. b
  end
  return a .. "/" .. b
end

local RESOURCE = r.GetResourcePath()
local FXROOT   = join(RESOURCE, "FXChains")
local DF95ROOT = join(FXROOT, "DF95")

local function exists_dir(path)
  local f = r.EnumerateFiles(path, 0)
  return f ~= nil
end

if not exists_dir(FXROOT) then
  r.ShowMessageBox("FXChains-Ordner nicht gefunden:\n" .. FXROOT,
                   "DF95 Chain Rename Tool", 0)
  return
end

if not exists_dir(DF95ROOT) then
  r.ShowMessageBox("DF95-Unterordner in FXChains nicht gefunden:\n" .. DF95ROOT,
                   "DF95 Chain Rename Tool", 0)
  return
end

local renames = {}

local function plan_rename(old_fullpath, new_fullpath)
  if old_fullpath == new_fullpath then return end
  renames[#renames+1] = { old = old_fullpath, new = new_fullpath }
end

local function scan_dir(base, rel)
  local abs = join(base, rel)
  local i = 0
  while true do
    local f = r.EnumerateFiles(abs, i)
    if not f then break end
    if f:lower():sub(-8) == ".rfxchain" then
      local old_full = join(abs, f)

      local stem, ext = f:match("^(.*)%.(.-)$")
      local new_name = f

      if stem and ext and ext ~= "RfxChain" then
        new_name = stem .. ".RfxChain"
      end

      local base_stem = new_name:match("^(.*)%.RfxChain$")
      local rel_dir = rel:lower()

      if rel_dir:find("mic") and not base_stem:match("^Mic_") then
        new_name = "Mic_" .. base_stem .. ".RfxChain"
      elseif rel_dir:find("coloring") and not base_stem:match("^Color_") then
        new_name = "Color_" .. base_stem .. ".RfxChain"
      elseif rel_dir:find("master") and not base_stem:match("^Master_") then
        new_name = "Master_" .. base_stem .. ".RfxChain"
      elseif rel_dir:find("fxbus") and not (base_stem:match("^FXBus_") or base_stem:match("^DF95_FXBus_")) then
        new_name = "DF95_FXBus_" .. base_stem .. ".RfxChain"
      end

      local new_full = join(abs, new_name)
      plan_rename(old_full, new_full)
    end
    i = i + 1
  end

  local j = 0
  while true do
    local sub = r.EnumerateSubdirectories(abs, j)
    if not sub then break end
    local sub_rel = rel == "" and sub or (rel .. "/" .. sub)
    scan_dir(base, sub_rel)
    j = j + 1
  end
end

r.ShowConsoleMsg("")
log("DF95 Chain Rename Tool – DRY RUN = " .. tostring(not APPLY))
log("FXChains Root: " .. FXROOT)
log("DF95 Root:     " .. DF95ROOT)
log("----------------------------------------------------")

scan_dir(DF95ROOT, "")

if #renames == 0 then
  log("Keine potenziellen Umbenennungen gefunden.")
  return
end

log("Geplante Umbenennungen (" .. #renames .. "):")
for _, rn in ipairs(renames) do
  log("  OLD: " .. rn.old)
  log("  NEW: " .. rn.new)
end

if not APPLY then
  r.ShowMessageBox("DF95 Chain Rename Tool (DRY RUN)\n\n" ..
                   "Es wurden " .. #renames .. " mögliche Umbenennungen gefunden.\n" ..
                   "Details siehe ReaScript Console.\n\n" ..
                   "Um sie auszuführen, setze APPLY = true im Script und starte es erneut.",
                   "DF95 Chain Rename Tool", 0)
  return
end

local ok_count, err_count = 0, 0
for _, rn in ipairs(renames) do
  local ok, err = os.rename(rn.old, rn.new)
  if ok then
    ok_count = ok_count + 1
  else
    err_count = err_count + 1
    log("FEHLER: " .. tostring(err) .. " | " .. rn.old .. " -> " .. rn.new)
  end
end

r.ShowMessageBox("DF95 Chain Rename Tool – Fertig\n\n" ..
                 "Erfolgreich: " .. ok_count .. "\n" ..
                 "Fehler: " .. err_count .. "\n\n" ..
                 "Details siehe ReaScript Console.",
                 "DF95 Chain Rename Tool", 0)
