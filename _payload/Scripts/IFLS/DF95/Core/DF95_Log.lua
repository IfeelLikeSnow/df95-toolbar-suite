-- DF95_Log.lua
-- Zentrales Log-System für DF95
-- Version: 1.0

local Log = {}

local reaper = reaper

local ok_json, JSON = pcall(require, "DF95_JSON")

local function get_log_path()
  local res_path = reaper.GetResourcePath()
  local sep = package.config:sub(1,1)
  local dir = res_path .. sep .. "Data" .. sep .. "DF95"
  if reaper.RecursiveCreateDirectory then
    reaper.RecursiveCreateDirectory(dir, 0)
  end
  local log_path = dir .. sep .. "df95_log.txt"
  return log_path
end

local function format_timestamp()
  local t = os.date("*t")
  local function two(n) return (n < 10) and ("0" .. n) or tostring(n) end
  return string.format(
    "%04d-%02d-%02d %02d:%02d:%02d",
    t.year, t.month, t.day, t.hour, t.min, t.sec
  )
end

function Log.log(scope, level, message, extra)
  scope = scope or "GENERIC"
  level = level or "INFO"
  message = message or ""

  local log_path = get_log_path()
  local f, err = io.open(log_path, "a")
  if not f then
    reaper.ShowConsoleMsg("DF95_Log: konnte Log-Datei nicht öffnen: " .. tostring(err) .. "\n")
    return
  end

  local line = string.format(
    "[%s] [%s] [%s] %s",
    format_timestamp(), scope, level, message
  )

  if extra and ok_json and JSON and type(extra) == "table" then
    local ok, encoded = pcall(JSON.encode, extra)
    if ok and encoded then
      line = line .. " | " .. encoded
    end
  end

  f:write(line .. "\n")
  f:close()
end

return Log
