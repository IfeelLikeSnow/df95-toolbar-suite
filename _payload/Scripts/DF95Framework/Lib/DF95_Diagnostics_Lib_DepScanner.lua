-- DF95_Diagnostics_Lib_DepScanner.lua
-- DF95 / IFLS Dependency Scanner (Lua)
-- Scannt Scripts/IFLS und Scripts/DF95Framework nach require/dofile/loadfile
-- und schreibt einen JSON-Report nach Support/DF95_Reports/DF95_DepGraph_YYYYMMDD_HHMMSS.json

local r = reaper

local M = {}

-- Utility: JSON escape (minimal)
local function json_escape(str)
  str = tostring(str or "")
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  return str
end

-- Read file into table of lines
local function read_lines(path)
  local lines = {}
  local f = io.open(path, "r")
  if not f then return lines end
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  return lines
end

-- Very simple Lua dep parsing:
--  require "mod"
--  require('mod')
--  dofile("path.lua")
--  loadfile("path.lua")()
local function parse_deps(path)
  local lines = read_lines(path)
  local requires = {}
  local dofiles  = {}
  local loadfiles = {}

  for _, line in ipairs(lines) do
    -- strip comments (naiv, aber hilft)
    local code = line:gsub("%-%-.*$", "")

    -- require
    for mod in code:gmatch("require%s*%(?%s*['\"]([^'\"]+)['\"]%s*%)?") do
      table.insert(requires, mod)
    end

    -- dofile
    for fp in code:gmatch("dofile%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
      table.insert(dofiles, fp)
    end

    -- loadfile(... )()
    for fp in code:gmatch("loadfile%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
      table.insert(loadfiles, fp)
    end
  end

  return {
    requires = requires,
    dofiles = dofiles,
    loadfiles = loadfiles
  }
end

local function scan_dir_collect(root_dir, results)
  local function scan(path)
    -- Files
    local i = 0
    while true do
      local fname = r.EnumerateFiles(path, i)
      if not fname then break end
      if fname:lower():match("%.lua$") then
        local full = path .. "/" .. fname
        local deps = parse_deps(full)
        table.insert(results, {
          path = full,
          requires = deps.requires,
          dofiles = deps.dofiles,
          loadfiles = deps.loadfiles,
        })
      end
      i = i + 1
    end
    -- Subdirs
    i = 0
    while true do
      local dname = r.EnumerateSubdirectories(path, i)
      if not dname then break end
      scan(path .. "/" .. dname)
      i = i + 1
    end
  end

  scan(root_dir)
end

function M.run()
  local base = r.GetResourcePath()
  local roots = {
    scripts_ifls        = base .. "/Scripts/IFLS",
    scripts_df95framework = base .. "/Scripts/DF95Framework",
  }

  local support_reports = base .. "/Support/DF95_Reports"
  r.RecursiveCreateDirectory(support_reports, 0)

  local results = {}
  scan_dir_collect(roots.scripts_ifls, results)
  scan_dir_collect(roots.scripts_df95framework, results)

  -- Build JSON
  local ts = os.date("%Y%m%d_%H%M%S")
  local json_path = support_reports .. "/DF95_DepGraph_" .. ts .. ".json"
  local f = io.open(json_path, "w")
  if not f then
    r.ShowMessageBox("Konnte DepGraph JSON nicht schreiben:\n" .. json_path,
                     "DF95 DepScanner", 0)
    return
  end

  f:write("{\n")
  f:write('  "repo_root": "' .. json_escape(base) .. '",\n')
  f:write('  "roots": {\n')
  f:write('    "scripts_ifls": "' .. json_escape(roots.scripts_ifls) .. '",\n')
  f:write('    "scripts_df95framework": "' .. json_escape(roots.scripts_df95framework) .. '"\n')
  f:write("  },\n")
  f:write('  "files": [\n')

  for i, entry in ipairs(results) do
    f:write("    {\n")
    f:write('      "path": "' .. json_escape(entry.path) .. '",\n')

    -- requires
    f:write('      "requires": [')
    for j, mod in ipairs(entry.requires) do
      if j > 1 then f:write(", ") end
      f:write('"' .. json_escape(mod) .. '"')
    end
    f:write("],\n")

    -- dofiles
    f:write('      "dofiles": [')
    for j, fp in ipairs(entry.dofiles) do
      if j > 1 then f:write(", ") end
      f:write('"' .. json_escape(fp) .. '"')
    end
    f:write("],\n")

    -- loadfiles
    f:write('      "loadfiles": [')
    for j, fp in ipairs(entry.loadfiles) do
      if j > 1 then f:write(", ") end
      f:write('"' .. json_escape(fp) .. '"')
    end
    f:write("]\n")

    if i == #results then
      f:write("    }\n")
    else
      f:write("    },\n")
    end
  end

  f:write("  ]\n")
  f:write("}\n")
  f:close()

  r.ShowMessageBox(
    "DF95 DepScanner abgeschlossen.\n\nReport geschrieben nach:\n" .. json_path,
    "DF95 DepScanner",
    0
  )
end

return M
