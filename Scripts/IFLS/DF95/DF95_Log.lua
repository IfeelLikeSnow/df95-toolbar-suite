-- DF95_Log.lua
-- Einfache Logging-Engine für DF95-Skripte.
-- Schreibt in Scripts/IFLS/DF95/logs/df95_log.txt

local r = reaper
local M = {}

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function ensure_log_dir()
  local base = df95_root()
  local dir = base .. "logs"
  if not r.EnumerateFiles(dir, 0) then
    r.RecursiveCreateDirectory(dir, 0)
  end
  return dir
end

local function timestamp()
  local t = os.date("*t")
  return string.format("%04d-%02d-%02d %02d:%02d:%02d",
    t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local function write_line(level, tag, msg)
  local dir = ensure_log_dir()
  local path = dir .. "/df95_log.txt"
  local f = io.open(path, "a")
  if not f then return end
  f:write(string.format("[%s] [%s] [%s] %s\n", timestamp(), level or "INFO", tag or "DF95", msg or ""))
  f:close()
end

function M.info(tag, msg)
  write_line("INFO", tag, msg)
end

function M.warn(tag, msg)
  write_line("WARN", tag, msg)
end

function M.error(tag, msg)
  write_line("ERROR", tag, msg)
end

return M
