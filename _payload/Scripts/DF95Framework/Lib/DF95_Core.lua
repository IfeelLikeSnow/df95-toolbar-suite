-- DF95_Core.lua (V3)
-- V3 Core Aggregator: Stable API entry point.
-- Goals:
--  - Keep all existing scripts working (no rewrites required)
--  - Provide a single place to access: PathResolver, config, logging, env
--  - Offer safe bootstrapping for package.path (optional)

local r = reaper

local M = {}
M.VERSION = "3.0.0-alpha"
M.BUILD_DATE = os.date("%Y-%m-%d")

local function norm(s)
  local out = (s or ""):gsub("\\","/")
  return out
end

local function join(...)
  local parts = {...}
  local out = {}
  for _, p in ipairs(parts) do
    if p and p ~= "" then table.insert(out, tostring(p)) end
  end
  local s = table.concat(out, "/")
  s = s:gsub("//+","/")
  return s
end

-- -------- Config (minimal) --------
local _config = {
  features = {
    enable_experimental = false,
    enable_diagnostics = true,
  },
  compat = {
    mode = "auto",
  },
  log = {
    to_console = true,
    to_file = true,
    level = "INFO", -- DEBUG, INFO, WARN, ERROR
  },
}

function M.get_config()
  return _config
end

-- Load user overrides from Support/DF95_Config.json (optional)
do
  local base = norm(r.GetResourcePath())
  local cfg_path = base .. "/Scripts/DF95Framework/Lib/DF95_Config.lua"
  local ok, Cfg = pcall(dofile, cfg_path)
  if ok and type(Cfg) == "table" and type(Cfg.load) == "function" then
    local merged, info = Cfg.load(_config)
    _config = merged or _config
    if info and info.loaded then
      -- avoid recursion: use console directly until log is ready
      r.ShowConsoleMsg("[DF95][INFO] Loaded config overrides: " .. tostring(info.path) .. "\n")
    elseif info and info.error and info.error ~= "" then
      r.ShowConsoleMsg("[DF95][WARN] Config overrides not loaded: " .. tostring(info.error) .. "\n")
    end
  end
end

-- -------- Logging (minimal) --------
local _logfile_path = nil
local function ensure_logfile()
  if _logfile_path then return _logfile_path end
  local base = norm(r.GetResourcePath())
  local dir = join(base, "Support", "DF95_Reports")
  r.RecursiveCreateDirectory(dir, 0)
  _logfile_path = join(dir, "DF95_V3_Core.log")
  return _logfile_path
end

local LEVEL_ORDER = { DEBUG=1, INFO=2, WARN=3, ERROR=4 }
local function level_ok(lvl)
  local want = _config.log.level or "INFO"
  return (LEVEL_ORDER[lvl] or 99) >= (LEVEL_ORDER[want] or 2)
end

local function write_file_line(line)
  if not _config.log.to_file then return end
  local p = ensure_logfile()
  local f = io.open(p, "a")
  if f then
    f:write(line .. "\n")
    f:close()
  end
end

local function write_console(line)
  if not _config.log.to_console then return end
  r.ShowConsoleMsg(line .. "\n")
end

function M.log(level, msg)
  level = (level or "INFO"):upper()
  if not level_ok(level) then return end
  msg = tostring(msg or "")
  local line = string.format("[DF95][%s] %s", level, msg)
  write_console(line)
  write_file_line(line)
end

function M.log_debug(msg) M.log("DEBUG", msg) end
function M.log_info(msg)  M.log("INFO",  msg) end
function M.log_warn(msg)  M.log("WARN",  msg) end
function M.log_error(msg) M.log("ERROR", msg) end

-- -------- Env helpers --------
function M.resource_path()
  return norm(r.GetResourcePath())
end

function M.os()
  local sep = package.config:sub(1,1)
  if sep == "\\" then return "windows" end
  return "posix"
end

-- -------- PathResolver access --------
local _resolver = nil
function M.pathresolver()
  if _resolver then return _resolver end
  local base = M.resource_path()
  local p = join(base, "Scripts", "DF95Framework", "Lib", "DF95_PathResolver.lua")
  local ok, PR = pcall(dofile, p)
  if not ok then
    M.log_error("Failed to load DF95_PathResolver.lua: " .. tostring(PR))
    return nil
  end
  _resolver = PR
  return _resolver
end

function M.df95_root()
  local PR = M.pathresolver()
  if not PR or type(PR.get_df95_scripts_root) ~= "function" then return nil end
  return PR.get_df95_scripts_root()
end

function M.ifls_root()
  local PR = M.pathresolver()
  if not PR or type(PR.get_ifls_scripts_root) ~= "function" then return nil end
  return PR.get_ifls_scripts_root()
end

-- Optional: bootstrap module search paths
function M.bootstrap(opts)
  opts = opts or {}
  local added = 0

  -- Prefer RootResolver-based package.path patterns
  local PR = M.pathresolver()
  if PR and type(PR.bootstrap_package_path) == "function" then
    local ok, n = pcall(PR.bootstrap_package_path)
    if ok and type(n) == "number" then added = added + n end
  end

  -- Also add known Lib paths (backward compatible)
  local lua_path = join(M.resource_path(), "Scripts", "DF95Framework", "Lib", "DF95_LuaPath.lua")
  local f = io.open(lua_path, "r")
  if f then
    f:close()
    local ok, LP = pcall(dofile, lua_path)
    if ok and type(LP) == "table" and type(LP.bootstrap) == "function" then
      local ok2, n2 = pcall(LP.bootstrap, { include_ifls=true, include_df95framework=true, include_lib=true })
      if ok2 and type(n2) == "number" then added = added + n2 end
    end
  end

  M.log_info("bootstrap() added package.path entries: " .. tostring(added))
  return added
end

return M
