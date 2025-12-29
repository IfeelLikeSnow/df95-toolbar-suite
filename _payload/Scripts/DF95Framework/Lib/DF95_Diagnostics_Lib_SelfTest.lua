
-- DF95_Diagnostics_Lib_SelfTest.lua
-- Library for DF95 diagnostics & self-test routines.
--
-- Usage example from another script:
--   local df95_selftest = dofile(reaper.GetResourcePath()
--       .. "/Scripts/DF95Framework/Lib/DF95_Diagnostics_Lib_SelfTest.lua")
--   local ok, result = df95_selftest.run_full_repo_selftest()
--
-- The library returns a module table and also sets a global
--   DF95_Diagnostics_Lib_SelfTest
-- for convenience.

local M = {}

----------------------------------------------------------------
-- Helpers: paths & filesystem
----------------------------------------------------------------

-- Build DF95 root paths relative to the REAPER resource path.
function M.get_paths()
  local resource = reaper.GetResourcePath()
  local root = resource .. "/Scripts/DF95"
  local paths = {
    resource_root = resource,
    df95_root = root,
    lib_root = root .. "/Lib",
    tools_root = root .. "/Tools",
    support_root = root .. "/Support",
    diagnostics_root = root .. "/Diagnostics"
  }
  return paths
end

-- Check if a file exists.
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  else
    return false
  end
end

M.file_exists = file_exists

-- Check if a directory exists.
local function dir_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end
  -- code 13 = permission denied, but dir exists
  if code == 13 then return true end
  return false
end

M.dir_exists = dir_exists

-- Ensure directory exists (create recursively if needed).
function M.ensure_dir(path)
  if dir_exists(path) then return true end
  local sep = package.config:sub(1,1) or "/"
  local accum = ""
  for part in string.gmatch(path, "[^" .. sep .. "]+") do
    if accum == "" then
      accum = part
    else
      accum = accum .. sep .. part
    end
    if not dir_exists(accum) then
      local ok = os.mkdir and os.mkdir(accum) or os.execute(string.format('mkdir "%s"', accum))
      if not ok then
        -- Best effort: ignore minor failures and let later operations fail loudly
      end
    end
  end
  return dir_exists(path)
end

-- Retrieve a list of files and directories under a root.
-- Uses REAPER's native APIs (EnumerateFiles / EnumerateSubdirectories)
-- for robust, cross-platform scanning.
-- Returns: { files = {...}, dirs = {...} }
function M.scan_tree(root, opts)
  opts = opts or {}
  local result = { files = {}, dirs = {} }

  if not dir_exists(root) then
    return result
  end

  local sep = package.config:sub(1,1) or "/"

  local function join(a, b)
    if a:sub(-1) == sep then return a .. b end
    return a .. sep .. b
  end

  local function recurse(dir, depth)
    depth = depth or 0
    if opts.max_depth and depth > opts.max_depth then return end

    -- collect files
    local fi = 0
    while true do
      local fname = reaper.EnumerateFiles(dir, fi)
      if not fname then break end
      local fpath = join(dir, fname)
      table.insert(result.files, fpath)
      fi = fi + 1
    end

    -- recurse into subdirs
    local di = 0
    while true do
      local dname = reaper.EnumerateSubdirectories(dir, di)
      if not dname then break end
      local dpath = join(dir, dname)
      table.insert(result.dirs, dpath)
      recurse(dpath, depth + 1)
      di = di + 1
    end
  end

  recurse(root, 0)
  return result
end

----------------------------------------------------------------
-- Core file checks
----------------------------------------------------------------

-- A configurable list of "must exist" DF95 core scripts / resources.
-- Adjust these to match your actual master repo layout.
M.CORE_FILES = {
  -- DF95 core libraries
  "Scripts/DF95Framework/Lib/DF95_Diagnostics_Lib_SelfTest.lua",
  "Scripts/DF95Framework/Lib/DF95_Lib_Reporting.lua",

  -- IFLS / DF95 diagnostics application layer
  "Scripts/IFLS/DF95/DF95_Diagnostics_Toolbox_RealPath.lua",
  "Scripts/IFLS/DF95/DF95_Diagnostics2_RealPath.lua",
  "Scripts/IFLS/DF95/DF95_Diagnostics3_RealPath.lua",
  "Scripts/IFLS/DF95/DF95_Diagnostics_SelfTest_FullRepo_RealPath.lua",
}

-- Resolve a relative path (from REAPER resource) to an absolute one.
local function resolve_from_resource(rel)
  local resource = reaper.GetResourcePath()
  local sep = package.config:sub(1,1) or "/"
  rel = rel:gsub("[/\\]", sep)
  return resource .. sep .. rel
end

-- Check core files; returns ok, errors_table
function M.check_core_files(custom_core_files)
  local core = custom_core_files or M.CORE_FILES
  local errors = {}
  for _, rel in ipairs(core) do
    local abs = resolve_from_resource(rel)
    if not file_exists(abs) then
      table.insert(errors, string.format("Missing core file: %s (resolved to: %s)", rel, abs))
    end
  end
  return (#errors == 0), errors
end

----------------------------------------------------------------
-- Full-repo self-test (generic)
----------------------------------------------------------------

-- Run a generic "full repo" self-test.
-- Options table (all optional):
--   opts.core_files      : override list for core file check
--   opts.additional_checks(df95_paths, result) : callback for extra checks
-- Return:
--   ok (boolean), result_table
--
-- result_table structure:
--   {
--     ok = boolean,
--     started_at = os.time(),
--     finished_at = os.time(),
--     duration_sec = number,
--     core_files_ok = boolean,
--     core_file_errors = {...},
--     files_scanned = number,
--     dirs_scanned = number,
--     warnings = {...},
--     notes = {...},
--   }
function M.run_full_repo_selftest(opts)
  opts = opts or {}
  local started = os.time()
  local result = {
    ok = false,
    started_at = started,
    finished_at = started,
    duration_sec = 0,
    core_files_ok = false,
    core_file_errors = {},
    files_scanned = 0,
    dirs_scanned = 0,
    warnings = {},
    notes = {},
  }

  local paths = M.get_paths()

  -- 1) Core files
  local core_ok, core_errors = M.check_core_files(opts.core_files)
  result.core_files_ok = core_ok
  result.core_file_errors = core_errors

  -- 2) Quick tree scan for statistics
  local tree = M.scan_tree(paths.df95_root, { max_depth = 10 })
  result.files_scanned = #tree.files
  result.dirs_scanned = #tree.dirs

  -- 3) Optional additional checks via callback
  if type(opts.additional_checks) == "function" then
    local ok, err = pcall(opts.additional_checks, paths, result)
    if not ok then
      table.insert(result.warnings, "additional_checks failed: " .. tostring(err))
    end
  end

  result.finished_at = os.time()
  result.duration_sec = os.difftime(result.finished_at, result.started_at or result.finished_at)

  -- Overall ok?
  local overall_ok = core_ok and (#result.warnings == 0)
  result.ok = overall_ok

  return overall_ok, result
end

----------------------------------------------------------------
-- Lightweight startup health-check
----------------------------------------------------------------

-- This is a cheaper version that only checks existence of core files,
-- intended to be used from DF95_StartupCheck.lua.
function M.run_light_healthcheck(opts)
  opts = opts or {}
  local res = {
    ok = false,
    core_files_ok = false,
    core_file_errors = {},
  }
  local cf_ok, cf_err = M.check_core_files(opts.core_files)
  res.core_files_ok = cf_ok
  res.core_file_errors = cf_err
  res.ok = cf_ok
  return res.ok, res
end

----------------------------------------------------------------
-- Expose & return module
----------------------------------------------------------------

_G.DF95_Diagnostics_Lib_SelfTest = M

return M
