\
-- @description DF95_V88_ReampSuite_SessionLog
-- @version 1.0
-- @author DF95
-- @about
--   Einfaches Session-Log für DF95 ReampSuite.
--   - Schreibt Reamp-Events in eine Log-Datei im ResourcePath/DF95_Logs.
--   - Kann von AutoSession / BatchEngine per dofile() aufgerufen werden.

local r = reaper

local M = {}

local function get_log_dir()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local dir = (res .. sep .. "DF95_Logs"):gsub("\\","/")
  return dir
end

local function ensure_dir(path)
  local sep = package.config:sub(1,1)
  local acc = ""
  for part in string.gmatch(path, "[^"..sep.."]+") do
    acc = acc .. part .. sep
    if not reaper.EnumerateSubdirectories(acc, 0) then
      reaper.RecursiveCreateDirectory(acc, 0)
    end
  end
end

local function get_log_file()
  local dir = get_log_dir()
  ensure_dir(dir .. package.config:sub(1,1))
  local proj, proj_path = r.EnumProjects(-1, "")
  local proj_name = proj_path ~= "" and proj_path or "(unsaved project)"
  proj_name = proj_name:gsub("[^%w%._%-]", "_")
  local date = os.date("%Y%m%d")
  local sep = package.config:sub(1,1)
  local fn = string.format("%s"..sep.."DF95_ReampSession_%s_%s.log", dir, date, proj_name)
  return fn
end

local function append_line(line)
  local fn = get_log_file()
  local f = io.open(fn, "a")
  if not f then return end
  f:write(line .. "\n")
  f:close()
end

-- Public API

function M.log_reamp_event(t)
  -- t: table mit Feldern: action, profile, chain_key, track_name, note etc.
  local parts = {}
  parts[#parts+1] = os.date("%Y-%m-%d %H:%M:%S")
  parts[#parts+1] = t.action or "UNKNOWN"
  parts[#parts+1] = "profile=" .. tostring(t.profile or "-")
  parts[#parts+1] = "chain=" .. tostring(t.chain_key or "-")
  parts[#parts+1] = "track=" .. tostring(t.track_name or "-")
  if t.note and t.note ~= "" then
    parts[#parts+1] = "note=" .. tostring(t.note)
  end
  local line = table.concat(parts, " | ")
  append_line(line)
end

-- Optional: Wenn als Action gestartet, schreibt nur einen Testeintrag.
if not ... then
  M.log_reamp_event({
    action = "MANUAL_LOG_TEST",
    profile = "(none)",
    chain_key = "(none)",
    track_name = "(none)",
    note = "DF95_V88_ReampSuite_SessionLog wurde manuell gestartet."
  })
  reaper.ShowMessageBox("Testeintrag in DF95_Logs wurde geschrieben.", "DF95 SessionLog", 0)
end

return M
