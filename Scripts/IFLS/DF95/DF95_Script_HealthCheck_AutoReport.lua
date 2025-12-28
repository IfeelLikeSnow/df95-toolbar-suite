-- @description DF95_Script_HealthCheck_AutoReport
-- @version 1.0
-- @author DF95
-- @about
--   Führt einen DF95 Script Health Check aus und schreibt das Ergebnis
--   als Text-Report in den DF95 Data-Ordner (Data/DF95).
--   Ideal für Debugging, Dokumentation und Fehlersuche nach Updates.
--
--   Hinweis:
--     - Es werden alle DF95-Lua-Skripte unter Scripts/IFLS/DF95
--       mit loadfile() geprüft (Syntaxcheck).
--     - Die Skripte werden NICHT ausgeführt.

local r = reaper

local function get_sep()
  return package.config:sub(1,1)
end

local function normalize_path(path)
  local sep = get_sep()
  if sep == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_df95_root()
  local sep = get_sep()
  local base = get_resource_path()
  local dir = base .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
  return normalize_path(dir)
end

local function list_lua_files(root)
  local sep = get_sep()
  local files = {}

  local function scan_dir(path)
    path = normalize_path(path)
    local cmd
    if sep == "\\" then
      cmd = 'dir "' .. path .. '" /b'
    else
      cmd = 'ls "' .. path .. '"'
    end
    local p = io.popen(cmd)
    if not p then return end
    for name in p:lines() do
      local full = path .. sep .. name
      full = normalize_path(full)
      if name:lower():match("%.lua$") then
        files[#files+1] = full
      elseif not name:match("%.") then
        -- einfache Heuristik: Eintrag ohne Punkt -> Unterordner
        scan_dir(full)
      end
    end
    p:close()
  end

  scan_dir(root)
  table.sort(files)
  return files
end

local function run_health_check()
  local root = get_df95_root()
  local files = list_lua_files(root)

  local results = {}
  local ok_count, fail_count = 0, 0

  for _, full in ipairs(files) do
    local rel = full:gsub("^" .. root, "DF95")
    rel = normalize_path(rel)
    local f, err = loadfile(full)
    local entry = {
      full = full,
      rel  = rel,
      ok   = (f ~= nil),
      err  = f and "" or tostring(err)
    }
    if entry.ok then ok_count = ok_count + 1 else fail_count = fail_count + 1 end
    results[#results+1] = entry
  end

  return results, ok_count, fail_count, root
end

local function write_report(results, ok_count, fail_count, root)
  local sep = get_sep()
  local base = get_resource_path()
  local data_dir = base .. sep .. "Data" .. sep .. "DF95"
  data_dir = normalize_path(data_dir)

  -- sicherstellen, dass Data/DF95 existiert
  r.RecursiveCreateDirectory(data_dir, 0)

  local ts = os.date("%Y%m%d_%H%M%S")
  local fname = data_dir .. sep .. "DF95_ScriptHealthReport_" .. ts .. ".txt"

  local f, err = io.open(fname, "w")
  if not f then
    r.ShowMessageBox("Konnte Report-Datei nicht schreiben:\n" .. tostring(err), "DF95 Script HealthCheck AutoReport", 0)
    return nil
  end

  f:write("DF95 Script HealthCheck AutoReport\n")
  f:write("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
  f:write("Root: " .. (root or "") .. "\n")
  f:write(string.rep("-", 60) .. "\n")
  f:write(string.format("Anzahl Skripte: %d\n", #results))
  f:write(string.format("OK: %d\n", ok_count or 0))
  f:write(string.format("FAIL: %d\n", fail_count or 0))
  f:write(string.rep("-", 60) .. "\n\n")

  f:write("DETAILS:\n\n")
  for _, e in ipairs(results) do
    local status = e.ok and "OK" or "FAIL"
    f:write(string.format("[%s] %s\n", status, e.rel or ""))
    if not e.ok and e.err and e.err ~= "" then
      f:write("  -> " .. e.err .. "\n")
    end
  end

  f:close()
  return fname
end

local function open_folder_of(path)
  local sep = get_sep()
  local dir = path:match("^(.*" .. (sep == "\\" and "\\" or "/") .. ")")
  if not dir then return end
  dir = normalize_path(dir)

  local cmd
  if sep == "\\" then
    cmd = 'explorer "' .. dir .. '"'
  else
    cmd = 'open "' .. dir .. '"'
  end
  os.execute(cmd)
end

local function main()
  r.Undo_BeginBlock()
  local results, ok_count, fail_count, root = run_health_check()
  local fname = write_report(results, ok_count, fail_count, root)
  if fname then
    local msg = string.format("DF95 Script HealthCheck AutoReport erstellt.\nOK: %d, FAIL: %d\n\nDatei:\n%s", ok_count or 0, fail_count or 0, fname)
    r.ShowMessageBox(msg, "DF95 Script HealthCheck AutoReport", 0)
  end
  r.Undo_EndBlock("DF95 Script HealthCheck AutoReport", -1)
end

main()
