-- @description DF95 IFLS InstallDoctor - Create Root Shims + Bootstrap
-- @version 1.0
-- @author DF95/IFLS helper (generated)
-- @about
--   Creates root-level compatibility shims in REAPER's Scripts folder:
--     - IFLS_ImGui_Core.lua
--     - IFLS_Diagnostics.lua
--     - RealmGui.lua
--   Also creates IFLS_Bootstrap.lua which extends package.path to find Scythe/IFLS libs.
--   Then shows next steps.
--
--   Safe to re-run: files are overwritten only if content differs.

local r = reaper

local function msg(s) r.ShowConsoleMsg(tostring(s) .. "\n") end

local function join(a,b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then return a .. b end
  return a .. "/" .. b
end

local function norm(p) return (p:gsub("\\","/")) end

local function file_read(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local c = f:read("*all")
  f:close()
  return c
end

local function file_write_if_changed(path, content)
  local old = file_read(path)
  if old == content then return false end
  local f = assert(io.open(path, "wb"))
  f:write(content)
  f:close()
  return true
end

-- Depth-limited recursive file finder under root
local function find_file_under(root, target_filename, max_depth)
  root = norm(root)
  max_depth = max_depth or 8
  local function walk(dir, depth)
    if depth > max_depth then return nil end

    -- files
    local i = 0
    while true do
      local fn = r.EnumerateFiles(dir, i)
      if not fn then break end
      if fn == target_filename then
        return norm(join(dir, fn))
      end
      i = i + 1
    end

    -- subdirs
    local j = 0
    while true do
      local sub = r.EnumerateSubdirectories(dir, j)
      if not sub then break end
      local found = walk(norm(join(dir, sub)), depth + 1)
      if found then return found end
      j = j + 1
    end

    return nil
  end
  return walk(root, 0)
end

local function build_shim(filename, friendly_name, hints)
  hints = hints or {}
  local hints_lua = "{\n"
  for _,h in ipairs(hints) do
    hints_lua = hints_lua .. string.format("  %q,\n", h)
  end
  hints_lua = hints_lua .. "}"

  return string.format([[
-- Auto-generated compatibility shim for %s
-- This file is placed in REAPER/Scripts to satisfy legacy require()/dofile() references.
-- If you are editing IFLS, do NOT edit this shim; edit the real source instead.

local r = reaper
local function join(a,b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then return a .. b end
  return a .. "/" .. b
end
local function norm(p) return (p:gsub("\\","/")) end

local function find_file_under(root, target_filename, max_depth)
  root = norm(root)
  max_depth = max_depth or 10
  local function walk(dir, depth)
    if depth > max_depth then return nil end
    local i = 0
    while true do
      local fn = r.EnumerateFiles(dir, i)
      if not fn then break end
      if fn == target_filename then return norm(join(dir, fn)) end
      i = i + 1
    end
    local j = 0
    while true do
      local sub = r.EnumerateSubdirectories(dir, j)
      if not sub then break end
      local found = walk(norm(join(dir, sub)), depth + 1)
      if found then return found end
      j = j + 1
    end
    return nil
  end
  return walk(root, 0)
end

local scripts_dir = norm(r.GetResourcePath() .. "/Scripts")
local hint_dirs = %s

-- 1) Try hints first (fast)
for _,rel in ipairs(hint_dirs) do
  local base = norm(join(scripts_dir, rel))
  local p = find_file_under(base, %q, 6)
  if p then
    local chunk, err = loadfile(p)
    if not chunk then error(err) end
    local ret = chunk()
    if ret == nil then ret = true end
    return ret
  end
end

-- 2) Fallback: full scan under Scripts (slower, but robust)
local p = find_file_under(scripts_dir, %q, 10)
if p then
  local chunk, err = loadfile(p)
  if not chunk then error(err) end
  local ret = chunk()
  if ret == nil then ret = true end
  return ret
end

r.ShowMessageBox(
  "IFLS InstallDoctor: Could not locate the real file:\\n\\n  " .. %q .. "\\n\\n" ..
  "Searched under:\\n  " .. scripts_dir .. "\\n\\n" ..
  "Fix: install/update DF95 IFLS V3 (and dependencies) via ReaPack or copy the repository into Scripts.",
  "IFLS Shim missing target",
  0
)
return false
]], friendly_name, hints_lua, filename, filename, filename)
end

local function build_bootstrap()
  return [[
-- Auto-generated IFLS bootstrap
-- Purpose: extend package.path so IFLS/Scythe libs are discoverable from any script.

local r = reaper
local function norm(p) return (p:gsub("\\","/")) end
local function join(a,b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then return a .. b end
  return a .. "/" .. b
end

local scripts_dir = norm(r.GetResourcePath() .. "/Scripts")

local function add_path(pat)
  if not package.path:find(pat, 1, true) then
    package.path = package.path .. ";" .. pat
  end
end

-- Depth-limited directory scanner
local function scan_dirs(root, max_depth, on_dir)
  root = norm(root)
  max_depth = max_depth or 6
  local function walk(dir, depth)
    if depth > max_depth then return end
    on_dir(dir)
    local j = 0
    while true do
      local sub = r.EnumerateSubdirectories(dir, j)
      if not sub then break end
      walk(norm(join(dir, sub)), depth + 1)
      j = j + 1
    end
  end
  walk(root, 0)
end

-- Add likely roots
-- 1) Any folder containing "Scythe" (v3) -> add root and lib subfolder
scan_dirs(scripts_dir, 6, function(d)
  local dn = d:lower()
  if dn:find("scythe", 1, true) then
    add_path(norm(join(d, "?.lua")))
    add_path(norm(join(d, "?/init.lua")))
    add_path(norm(join(d, "lib/?.lua")))
    add_path(norm(join(d, "lib/?/init.lua")))
  end
end)

-- 2) Any folder containing "/IFLS" -> add it as module root
scan_dirs(scripts_dir, 6, function(d)
  local dn = d:lower()
  if dn:sub(-5) == "/ifls" or dn:find("/ifls/", 1, true) then
    add_path(norm(join(d, "?.lua")))
    add_path(norm(join(d, "?/init.lua")))
  end
end)

return true
]]
end

-- Main
local resource = norm(r.GetResourcePath())
local scripts_dir = norm(resource .. "/Scripts")
r.RecursiveCreateDirectory(scripts_dir, 0)

local shims = {
  {
    filename = "IFLS_ImGui_Core.lua",
    friendly = "IFLS_ImGui_Core.lua",
    hints = {
      "IFLS",
      "DF95 IFLS V3",
      "DF95 IFLS V3/DF95/01 Core/Scripts",
      "DF95 IFLS V3/DF95/01 Core/Scripts/IFLS",
      "DF95 IFLS V3/DF95/01 Core/Scripts/IFLS/IFLS",
    }
  },
  {
    filename = "IFLS_Diagnostics.lua",
    friendly = "IFLS_Diagnostics.lua",
    hints = {
      "IFLS",
      "DF95 IFLS V3",
      "DF95 IFLS V3/DF95/01 Core/Scripts",
      "DF95 IFLS V3/DF95/01 Core/Scripts/IFLS",
      "DF95 IFLS V3/DF95/01 Core/Scripts/IFLS/IFLS",
    }
  },
  {
    filename = "RealmGui.lua",
    friendly = "RealmGui.lua",
    hints = {
      "IFLS",
      "DF95 IFLS V3",
      "DF95 IFLS V3/DF95/01 Core/Scripts",
      "DF95 IFLS V3/DF95/01 Core/Scripts/IFLS",
      "DF95 IFLS V3/DF95/01 Core/Scripts/IFLS/IFLS",
    }
  }
}

local changed = {}
for _,s in ipairs(shims) do
  local content = build_shim(s.filename, s.friendly, s.hints)
  local out = norm(join(scripts_dir, s.filename))
  local did = file_write_if_changed(out, content)
  table.insert(changed, string.format("%s: %s", s.filename, did and "written/updated" or "already OK"))
end

local boot_path = norm(join(scripts_dir, "IFLS_Bootstrap.lua"))
local boot_did = file_write_if_changed(boot_path, build_bootstrap())
table.insert(changed, string.format("IFLS_Bootstrap.lua: %s", boot_did and "written/updated" or "already OK"))

-- Tell user what to do next
local report = table.concat(changed, "\n")
local next_steps = "\n\nNext steps:\n" ..
  "1) RESTART REAPER (important: refresh Lua module cache).\n" ..
  "2) Open Actions list -> ReaScript -> 'Load' and load your IFLS main scripts if needed.\n" ..
  "3) Run IFLS Toolbar Builder (if you use it) to generate a resolved .ReaperMenuSet.\n" ..
  "4) Only then import the generated Toolbar/MenuSet (prevents empty toolbars).\n\n" ..
  "Tip: If you still see ReaPack index errors, clear ReaPack cache/re-add the repo."

r.ShowMessageBox("IFLS InstallDoctor finished.\n\n" .. report .. next_steps,
  "IFLS InstallDoctor", 0)

r.UpdateArrange()
