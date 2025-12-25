-- @description DF95: Rebuild IFLS Main Toolbar MenuSet (non-empty, self-resolving)
-- @version 1.0.1
-- @author DF95
-- @about
--   Fixes "toolbar/menu empty" by generating an importable MenuSet that uses REAL command IDs
--   for scripts installed on THIS machine (no placeholders).
--
--   It registers the scripts (so they get _RS... named command IDs), then writes:
--     <ResourcePath>\MenuSets\IFLS_Main.Toolbar.ReaperMenuSet
--
--   After running:
--     Options > Customize menus/toolbars...
--     Select: Floating toolbar 1 (Toolbar 1)
--     Import... > IFLS_Main.Toolbar.ReaperMenuSet
--
--   Notes:
--     - Toolbar entries must have sequential item_0, item_1...; otherwise REAPER ignores following items.
--     - ActionCommandID-strings must begin with "_" (e.g. "_RS...").
--     - If a referenced script file does not exist, it will be skipped (but MenuSet will still be non-empty if any exist).

local function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

local sep = package.config:sub(1,1)
local function join(a,b)
  if a:sub(-1) == "\\" or a:sub(-1) == "/" then return a..b end
  return a..sep..b
end

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

-- Register script into Action List (Main section) and return named command string "_RS..."
local function ensure_named_cmd(script_path)
  if not file_exists(script_path) then return nil, "missing file" end
  -- AddRemoveReaScript: (add, sectionID, scriptfn, commit)
  -- sectionID 0 = Main
  local cmd_id = reaper.AddRemoveReaScript(true, 0, script_path, true)
  if not cmd_id or cmd_id == 0 then return nil, "AddRemoveReaScript failed" end
  local named = reaper.ReverseNamedCommandLookup(cmd_id)
  if not named or named == "" then
    -- Fallback: sometimes returns empty until restart, but usually works immediately.
    return nil, "ReverseNamedCommandLookup returned empty (try restart REAPER)"
  end
  if named:sub(1,1) ~= "_" then named = "_"..named end
  return named, nil
end

local function write_menuset(out_path, items)
  -- MenuSet format is the same INI-style as reaper-menu.ini sections.
  -- We generate the floating toolbar section with sequential item_N and matching icon_N.
  local f = assert(io.open(out_path, "wb"))
  local function w(s) f:write(s) end

  -- IMPORTANT: keep it simple ASCII/UTF-8 without BOM. Use \n (REAPER accepts it).
  w("[Floating toolbar 1 (Toolbar 1)]\n")
  w("title=IFLS Main\n")
  for i,it in ipairs(items) do
    local id = i-1
    -- icon: text button with tooltip
    w(("icon_%d=text\n"):format(id))
    -- item: ActionCommandID-string must begin with "_" (per REAPER menu/toolbar rules)
    w(("item_%d=%s %s\n"):format(id, it.cmd, it.title))
  end
  w("\n")
  f:close()
end

reaper.ClearConsole()
msg("=== IFLS Toolbar Builder (rebuild) ===")
local res = reaper.GetResourcePath()
msg("Resource path: "..res)

local scripts_root = join(res, "Scripts")

-- Candidate scripts (adjust as your project evolves)
local candidates = {
  { title="IFLS: InstallDoctor (Create Shims)", rel="IFLS/DF95/Installers/DF95_IFLS_InstallDoctor_CreateShims.lua" },
  { title="IFLS: Diagnostics",                 rel="IFLS_Diagnostics.lua" },
  -- add your main launcher here if/when you know the filename:
  -- { title="IFLS: Main", rel="IFLS/DF95/IFLS_Main.lua" },
}

local items = {}
local missing = 0
for _,c in ipairs(candidates) do
  local abs = join(scripts_root, c.rel:gsub("/", sep))
  local cmd, err = ensure_named_cmd(abs)
  if cmd then
    table.insert(items, {cmd=cmd, title=c.title})
    msg(("OK  : %s  ->  %s"):format(c.rel, cmd))
  else
    missing = missing + 1
    msg(("MISS: %s  (%s)"):format(c.rel, err or "unknown"))
  end
end

if #items == 0 then
  msg("")
  msg("ERROR: No toolbar items could be built (all candidate scripts missing/unregistered).")
  msg("Fix: Ensure these files exist under ResourcePath\\Scripts, then run again.")
  return
end

local menuset_dir = join(res, "MenuSets")
local out_path = join(menuset_dir, "IFLS_Main.Toolbar.ReaperMenuSet")

-- Ensure MenuSets dir exists (usually does)
os.execute((sep=="\\") and ('cmd /c if not exist "'..menuset_dir..'" mkdir "'..menuset_dir..'"') or ('mkdir -p "'..menuset_dir..'"'))

write_menuset(out_path, items)

msg("")
msg("Wrote MenuSet: "..out_path)
msg(("Items: %d OK, %d missing"):format(#items, missing))
msg("")
msg("NEXT:")
msg("1) Options > Customize menus/toolbars...")
msg("2) Select: Floating toolbar 1 (Toolbar 1)")
msg("3) Import... > IFLS_Main.Toolbar.ReaperMenuSet")
msg("4) If toolbar still looks empty: ensure you are viewing Floating toolbar 1, not Main toolbar.")
msg("=== Done ===")
