
-- DF95_Lib_Reporting.lua
-- Shared library for DF95 diagnostics / autoreport handling.
--
-- Stores reports as Lua table files: each report file is:
--   return {
--     df95_version = "...",
--     reaper_version = "...",
--     ...
--   }
-- so you can load it via:
--   local manifest = dofile(path)
--
-- This avoids needing a full JSON implementation while remaining human-readable.

local M = {}

----------------------------------------------------------------
-- Paths
----------------------------------------------------------------

function M.get_paths()
  local resource = reaper.GetResourcePath()
  local root = resource .. "/Scripts/DF95"
  local support_root = root .. "/Support"
  local reports_root = support_root .. "/DF95_Reports"
  return {
    resource_root = resource,
    df95_root = root,
    support_root = support_root,
    reports_root = reports_root,
  }
end

local function dir_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end
  if code == 13 then return true end
  return false
end

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
        -- ignore, let later operations fail
      end
    end
  end
  return dir_exists(path)
end

----------------------------------------------------------------
-- Manifest creation
----------------------------------------------------------------

-- Build a basic manifest table.
-- You can add additional fields before saving.
function M.build_manifest(params)
  params = params or {}
  local paths = M.get_paths()

  local manifest = {
    df95_version       = params.df95_version or "0.0.0",
    reaper_version     = reaper.GetAppVersion(),
    os                 = reaper.GetOS(),
    diagnostics_variant= params.diagnostics_variant or "unknown",
    timestamp          = os.time(),
    user_privacy_level = params.user_privacy_level or "normal",
    paths_anonymized   = params.paths_anonymized or false,
    notes              = params.notes or {},
    extra              = params.extra or {},
  }

  return manifest
end

-- Serialize Lua table (simple, only for typical manifest structures: strings, numbers, booleans, tables)
local function serialize_value(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then
    -- Escape backslashes and quotes minimally
    v = v:gsub("\\", "\\\\"):gsub("\"", "\\\"")
    return '"' .. v .. '"'
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "table" then
    local parts = {}
    table.insert(parts, "{")
    local inner_indent = indent .. "  "
    for k, val in pairs(v) do
      local key_repr
      if type(k) == "string" and k:match("^[%a_][%w_]*$") then
        key_repr = k
      else
        key_repr = "[" .. serialize_value(k, inner_indent) .. "]"
      end
      local val_repr = serialize_value(val, inner_indent)
      table.insert(parts, string.format("%s  %s = %s,", inner_indent, key_repr, val_repr))
    end
    table.insert(parts, indent .. "}")
    return table.concat(parts, "\n")
  else
    return "nil"
  end
end

-- Write manifest to file. Returns path or nil, err
function M.write_manifest(manifest, custom_name)
  local paths = M.get_paths()
  M.ensure_dir(paths.reports_root)

  local filename
  if custom_name and custom_name ~= "" then
    filename = custom_name
  else
    local ts = os.date("!%Y%m%d_%H%M%S")
    local rand = tostring(math.random(1000, 9999))
    filename = string.format("DF95_Report_%s_%s.lua", ts, rand)
  end

  local fullpath = paths.reports_root .. "/" .. filename
  local f, err = io.open(fullpath, "w")
  if not f then
    return nil, "Failed to open report file for writing: " .. tostring(err)
  end

  f:write("return ")
  f:write(serialize_value(manifest, ""))
  f:write("\n")
  f:close()

  return fullpath
end

-- Load manifest from a given file path.
function M.load_manifest(path)
  local ok, res = pcall(dofile, path)
  if not ok then
    return nil, "Failed to load manifest: " .. tostring(res)
  end
  if type(res) ~= "table" then
    return nil, "Manifest file did not return a table"
  end
  return res
end

-- List all manifest files in the reports directory.
function M.list_manifests()
  local paths = M.get_paths()
  local reports_root = paths.reports_root
  local results = {}

  if not dir_exists(reports_root) then
    return results
  end

  local p = io.popen
  local cmd
  if reaper.GetOS():match("Win") then
    cmd = 'dir /b "' .. reports_root .. '"'
  else
    cmd = 'ls "' .. reports_root .. '"'
  end
  local pipe = p(cmd)
  if not pipe then return results end

  for entry in pipe:lines() do
    if entry:match("^DF95_Report_.*%.lua$") then
      table.insert(results, reports_root .. "/" .. entry)
    end
  end
  pipe:close()

  table.sort(results)
  return results
end

----------------------------------------------------------------
-- Convenience helper: create & store manifest in one go
----------------------------------------------------------------

-- params is same as build_manifest, plus:
--   params.custom_filename (optional)
-- Returns: fullpath or nil, err
function M.create_and_store_manifest(params)
  local manifest = M.build_manifest(params)
  local path, err = M.write_manifest(manifest, params and params.custom_filename or nil)
  return path, err
end

_G.DF95_Lib_Reporting = M

return M
