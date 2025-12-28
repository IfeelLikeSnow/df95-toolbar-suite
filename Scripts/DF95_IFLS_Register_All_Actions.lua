-- @description DF95/IFLS: Register all DF95/IFLS actions (first run)
-- @version 1.0.0
-- @author DF95 / IFLS
-- @about
--   One-time bootstrap: scans the repository Scripts folders and registers DF95/IFLS scripts
--   as Actions in REAPER's Action List. Safe to re-run.
--   Tip: If you only want a subset registered, edit the allowlist patterns in this script.

local function msg(s) reaper.ShowMessageBox(tostring(s), "DF95/IFLS Register Actions", 0) end

local function norm(p)
  p = p:gsub('\\','/')
  return p
end

local function join(a,b)
  if a:sub(-1) == '/' then return a .. b end
  return a .. '/' .. b
end

local function file_exists(p)
  local f = io.open(p,'rb')
  if f then f:close() return true end
  return false
end

local function read_first_kb(p, maxbytes)
  local f = io.open(p,'rb')
  if not f then return '' end
  local data = f:read(maxbytes or 2048) or ''
  f:close()
  return data
end

-- Allowlist patterns: keep Action List clean.
-- Add more prefixes if you want other namespaces to be registered automatically.
local allow_patterns = {
  "^DF95_",
  "^IFLS_",
  "^DF95IFLS_",
}

-- Folders to scan relative to REAPER resource path
local scan_roots = {
  "Scripts/DF95_ToolbarSuite",
  "Scripts/IFLS",
  "Scripts/DF95",
  "Scripts/DF95Framework",
  "Scripts",
}

-- Heuristic: only register scripts that look like runnable ReaScripts (not pure libs/templates).
-- - must be .lua
-- - file name must match allow_patterns
-- - skip files in Lib/, Templates/, Docs/
local skip_dir_patterns = {
  "/Lib/",
  "/lib/",
  "/Templates/",
  "/templates/",
  "/Docs/",
  "/docs/",
}

local function is_allowed_file(path)
  local fn = path:match("([^/]+)$") or path
  if not fn:lower():match("%.lua$") then return false end
  local base = fn:gsub("%.lua$","")
  local ok=false
  for _,p in ipairs(allow_patterns) do
    if base:match(p) then ok=true break end
  end
  if not ok then return false end
  for _,sp in ipairs(skip_dir_patterns) do
    if path:find(sp, 1, true) then return false end
  end
  -- If file has a ReaScript metaheader, it's probably intended to be runnable
  local head = read_first_kb(path, 4096)
  if head:find("@description", 1, true) then return true end
  -- Otherwise still allow, but only if it contains `reaper.` calls (cheap signal it's runnable)
  if head:find("reaper%.", 1, true) then return true end
  return false
end

local function scan_dir(dir, out)
  local i = 0
  while true do
    local file = reaper.EnumerateFiles(dir, i)
    if not file then break end
    local full = join(dir, file)
    full = norm(full)
    if is_allowed_file(full) then
      out[#out+1] = full
    end
    i = i + 1
  end

  local j = 0
  while true do
    local sub = reaper.EnumerateSubdirectories(dir, j)
    if not sub then break end
    local full = join(dir, sub)
    full = norm(full)
    scan_dir(full, out)
    j = j + 1
  end
end

local resource = norm(reaper.GetResourcePath())
local found = {}
for _,rel in ipairs(scan_roots) do
  local dir = norm(join(resource, rel))
  if reaper.EnumerateFiles(dir, 0) or reaper.EnumerateSubdirectories(dir, 0) then
    scan_dir(dir, found)
  end
end

-- Remove duplicates
local uniq, seen = {}, {}
for _,p in ipairs(found) do
  if not seen[p] then
    seen[p] = true
    uniq[#uniq+1] = p
  end
end

if #uniq == 0 then
  msg("No DF95/IFLS scripts found to register.\n\nCheck that the repository installed files into your REAPER resource path.")
  return
end

-- Register with AddRemoveReaScript (sectionID 0 = Main actions list)
local ok, fail = 0, 0
reaper.Undo_BeginBlock()
for _,p in ipairs(uniq) do
  local rv = reaper.AddRemoveReaScript(true, 0, p, true)
  if rv ~= 0 then ok = ok + 1 else fail = fail + 1 end
end
reaper.Undo_EndBlock("DF95/IFLS: Register Actions", -1)

msg(("Registered: %d\nFailed: %d\n\nTip: open Action List and search for DF95 or IFLS."):format(ok, fail))
