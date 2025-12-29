-- DF95 FullRepo SelfTest (V2, RealPath, REAPER-native + JSON)
-- Scannt DF95Framework + IFLS + FX-Ordner und schreibt TXT- und JSON-Report

local r = reaper

local base = r.GetResourcePath()

-- Feature flag gate (V3): diagnostics can be disabled via Support/DF95_Config.json
do
  local okc, Core = pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
  if okc and type(Core) == "table" and type(Core.get_config) == "function" then
    local cfg = Core.get_config()
    if cfg and cfg.features and cfg.features.enable_diagnostics == false then
      if Core.log_info then Core.log_info("Diagnostics disabled by config: " .. (debug.getinfo(1,'S').source or '?')) end
      return
    end
  end
end

local roots = {
  ["Effects/IFLS"]          = base .. "/Effects/IFLS",
  ["Scripts/IFLS"]          = base .. "/Scripts/IFLS",
  ["Effects/DF95"]          = base .. "/Effects/DF95",
  ["Scripts/DF95Framework"] = base .. "/Scripts/DF95Framework",
}

local support_dir = base .. "/Support/DF95_SelfTest"
r.RecursiveCreateDirectory(support_dir, 0)

local function new_counts()
  return {
    total = 0,
    by_ext = {}
  }
end

local function add_file(counts, filename)
  counts.total = counts.total + 1
  local ext = filename:match("%.([A-Za-z0-9_]+)$")
  if ext then
    ext = ext:lower()
    counts.by_ext[ext] = (counts.by_ext[ext] or 0) + 1
  else
    counts.by_ext["(ohne Endung)"] = (counts.by_ext["(ohne Endung)"] or 0) + 1
  end
end

local function scan_dir(path, counts)
  local i = 0
  while true do
    local fname = r.EnumerateFiles(path, i)
    if not fname then break end
    add_file(counts, fname)
    i = i + 1
  end

  i = 0
  while true do
    local dname = r.EnumerateSubdirectories(path, i)
    if not dname then break end
    local sub = path .. "/" .. dname
    scan_dir(sub, counts)
    i = i + 1
  end
end

local report_path = support_dir .. "/DF95_SelfTest_Report.txt"
local f = io.open(report_path, "w")
if not f then
  r.ShowMessageBox("Konnte Report-Datei nicht schreiben:\n" .. report_path,
                   "DF95 FullRepo SelfTest", 0)
  return
end

f:write("DF95 FullRepo SelfTest (V2 RealPath)\n")
f:write("Resource Path: " .. base .. "\n\n")

local global_counts = new_counts()
local scan_results = {}

for label, root in pairs(roots) do
  f:write("Scan: " .. label .. " -> " .. root .. "\n")
  local counts = new_counts()
  scan_dir(root, counts)
  f:write(string.format("  Dateien gefunden: %d\n", counts.total))

  for ext, n in pairs(counts.by_ext) do
    f:write(string.format("    %-8s: %d\n", ext, n))
  end
  f:write("\n")

  table.insert(scan_results, {
    label = label,
    path = root,
    total = counts.total,
    by_ext = counts.by_ext
  })

  global_counts.total = global_counts.total + counts.total
  for ext, n in pairs(counts.by_ext) do
    global_counts.by_ext[ext] = (global_counts.by_ext[ext] or 0) + n
  end
end

f:write("\nGesamtübersicht:\n")
for ext, n in pairs(global_counts.by_ext) do
  f:write(string.format("  %-8s: %d\n", ext, n))
end
f:write(string.format("\nTotal: %d Dateien\n\n", global_counts.total))

-- Lib-SelfTest prüfen (am neuen Ort!)
local lib_path = base .. "/Scripts/DF95Framework/Lib/DF95_Diagnostics_Lib_SelfTest.lua"
local lib_ok = false
local lib_error = nil
local lib_file = io.open(lib_path, "r")
if lib_file then
  lib_file:close()
  lib_ok = true
  f:write("DF95 Lib Self-Test: OK\n")
  f:write("  Gefunden unter: " .. lib_path .. "\n")
else
  lib_ok = false
  lib_error = "DF95_Diagnostics_Lib_SelfTest.lua NICHT gefunden unter: " .. lib_path
  f:write("DF95 Lib Self-Test: FALSE\n")
  f:write("  DF95_Diagnostics_Lib_SelfTest.lua NICHT gefunden unter:\n    " .. lib_path .. "\n")
end

f:close()

-- JSON-Report schreiben
local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  return str
end

local json_path = support_dir .. "/DF95_SelfTest_Report.json"
local jf = io.open(json_path, "w")
if jf then
  jf:write("{\n")
  jf:write('  "repo_root": "' .. json_escape(base) .. '",\n')
  jf:write('  "roots": {\n')
  jf:write('    "effects_ifls": "' .. json_escape(roots["Effects/IFLS"] or "") .. '",\n')
  jf:write('    "scripts_ifls": "' .. json_escape(roots["Scripts/IFLS"] or "") .. '",\n')
  jf:write('    "effects_df95": "' .. json_escape(roots["Effects/DF95"] or "") .. '",\n')
  jf:write('    "scripts_df95framework": "' .. json_escape(roots["Scripts/DF95Framework"] or "") .. '"\n')
  jf:write("  },\n")

  -- totals
  jf:write('  "counts": {\n')
  jf:write('    "total": ' .. tostring(global_counts.total) .. ',\n')
  jf:write('    "by_ext": {\n')
  local first_ext = true
  for ext, n in pairs(global_counts.by_ext) do
    if not first_ext then jf:write(",\n") end
    first_ext = false
    jf:write('      "' .. json_escape(ext) .. '": ' .. tostring(n))
  end
  jf:write("\n    }\n")
  jf:write("  },\n")

  -- df95_lib_selftest
  jf:write('  "df95_lib_selftest": {\n')
  jf:write('    "ok": "' .. (lib_ok and "true" or "false") .. '",\n')
  jf:write('    "path": "' .. json_escape(lib_path) .. '",\n')
  if lib_error then
    jf:write('    "error": "' .. json_escape(lib_error) .. '"\n')
  else
    jf:write('    "error": ""\n')
  end
  jf:write("  },\n")

  -- scans
  jf:write('  "scans": [\n')
  for i, entry in ipairs(scan_results) do
    jf:write("    {\n")
    jf:write('      "label": "' .. json_escape(entry.label) .. '",\n')
    jf:write('      "path": "' .. json_escape(entry.path) .. '",\n')
    jf:write('      "total": ' .. tostring(entry.total) .. ',\n')
    jf:write('      "by_ext": {\n')
    local first2 = true
    for ext, n in pairs(entry.by_ext) do
      if not first2 then jf:write(",\n") end
      first2 = false
      jf:write('        "' .. json_escape(ext) .. '": ' .. tostring(n))
    end
    jf:write("\n      }\n")
    if i == #scan_results then
      jf:write("    }\n")
    else
      jf:write("    },\n")
    end
  end
  jf:write("  ]\n")
  jf:write("}\n")
  jf:close()
end

r.ShowMessageBox(
  "DF95 FullRepo SelfTest abgeschlossen.\n\nReports geschrieben nach:\n" ..
  report_path .. "\n" .. json_path,
  "DF95 FullRepo SelfTest",
  0
)
