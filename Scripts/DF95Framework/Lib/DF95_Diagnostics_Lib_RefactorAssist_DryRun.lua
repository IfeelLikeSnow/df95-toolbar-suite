-- DF95_Diagnostics_Lib_RefactorAssist_DryRun.lua
-- Dry-run Refactor Assist (V2 Migration Helper)
-- Scans Lua files under Scripts/IFLS and Scripts/DF95Framework for legacy strings
-- and writes Findings + proposed replacements as TXT + JSON.
--
-- Output:
--   Support/DF95_Reports/DF95_RefactorAssist_DryRun_YYYYMMDD_HHMMSS.txt
--   Support/DF95_Reports/DF95_RefactorAssist_DryRun_YYYYMMDD_HHMMSS.json
--
-- IMPORTANT: This tool does NOT modify any files.

local r = reaper
local M = {}

local function norm(s)
  -- gsub returns (string, nsubs); ensure single return
  local out = (s or ""):gsub("\\\\", "/")
  return out
end
local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

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

local function json_escape(str)
  str = tostring(str or "")
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  return str
end

local function scan_dir_for_lua(root, out_files)
  local function walk(path)
    local i = 0
    while true do
      local fn = r.EnumerateFiles(path, i)
      if not fn then break end
      if fn:lower():match("%.lua$") then
        table.insert(out_files, norm(path .. "/" .. fn))
      end
      i = i + 1
    end
    i = 0
    while true do
      local dn = r.EnumerateSubdirectories(path, i)
      if not dn then break end
      walk(path .. "/" .. dn)
      i = i + 1
    end
  end
  walk(root)
end

-- Rule set: conservative, only for migration/cleanup signals
local RULES = {
  {
    id = "LEGACY_NAMESPACE_IFEELLIKESNOW",
    severity = "WARN",
    match = function(line) return line:find("IfeelLikeSnow", 1, true) ~= nil end,
    propose = function(line)
      -- For namespace-style strings: IfeelLikeSnow.XXX -> IFLS.XXX (suggestion only)
      local s = line:gsub("IfeelLikeSnow%.", "IFLS.")
      return s ~= line and s or nil
    end,
    hint = "Legacy Namespace gefunden. Prüfe, ob require()/Strings auf IFLS/DF95Framework umgestellt werden müssen."
  },
  {
    id = "LEGACY_PATH_SCRIPTS_IFEELLIKESNOW",
    severity = "WARN",
    match = function(line)
      local l = norm(line):lower()
      return l:find("scripts/ifeellikesnow/", 1, true) ~= nil
    end,
    propose = function(line)
      local s = norm(line):gsub("Scripts/IfeelLikeSnow/", "Scripts/IFLS/")
      return s ~= norm(line) and s or nil
    end,
    hint = "Legacy Script-Root Pfad gefunden. Vermutlich auf Scripts/IFLS/ umstellen."
  },
  {
    id = "LEGACY_PATH_EFFECTS_IFEELLIKESNOW",
    severity = "WARN",
    match = function(line)
      local l = norm(line):lower()
      return l:find("effects/ifeellikesnow/", 1, true) ~= nil
    end,
    propose = function(line)
      local s = norm(line):gsub("Effects/IfeelLikeSnow/", "Effects/IFLS/")
      return s ~= norm(line) and s or nil
    end,
    hint = "Legacy Effects-Root Pfad gefunden. Vermutlich auf Effects/IFLS/ umstellen."
  },
  {
    id = "LEGACY_PATH_SCRIPTS_DF95",
    severity = "WARN",
    match = function(line)
      local l = norm(line):lower()
      return l:find("scripts/df95/", 1, true) ~= nil
    end,
    propose = function(line)
      -- Heuristic suggestion: Scripts/DF95/ -> Scripts/DF95Framework/
      local s = norm(line):gsub("Scripts/DF95/", "Scripts/DF95Framework/")
      return s ~= norm(line) and s or nil
    end,
    hint = "Alter DF95-Pfad gefunden. V2 nutzt Scripts/DF95Framework/. Bitte prüfen (Heuristik)."
  },
}

function M.run(opts)
  opts = opts or {}
  local base = norm(r.GetResourcePath())

  local roots = {
    base .. "/Scripts/IFLS",
    base .. "/Scripts/DF95Framework",
  }

  local report_dir = base .. "/Support/DF95_Reports"
  r.RecursiveCreateDirectory(report_dir, 0)

  local lua_files = {}
  for _, root in ipairs(roots) do
    if file_exists(root) or true then
      scan_dir_for_lua(root, lua_files)
    end
  end

  local findings = {}
  local counts_by_rule = {}
  local counts_by_sev = { ERROR=0, WARN=0, INFO=0 }

  for _, fpath in ipairs(lua_files) do
    local lines = read_lines(fpath)
    for ln, line in ipairs(lines) do
      for _, rule in ipairs(RULES) do
        if rule.match(line) then
          counts_by_rule[rule.id] = (counts_by_rule[rule.id] or 0) + 1
          counts_by_sev[rule.severity] = (counts_by_sev[rule.severity] or 0) + 1
          local proposed = rule.propose(line)
          table.insert(findings, {
            severity = rule.severity,
            rule_id = rule.id,
            file = fpath,
            line = ln,
            excerpt = line,
            proposed = proposed or "",
            hint = rule.hint or "",
          })
        end
      end
    end
  end

  local ts = os.date("%Y%m%d_%H%M%S")
  local out_txt = report_dir .. "/DF95_RefactorAssist_DryRun_" .. ts .. ".txt"
  local out_json = report_dir .. "/DF95_RefactorAssist_DryRun_" .. ts .. ".json"

  -- TXT
  local tf = io.open(out_txt, "w")
  if tf then
    tf:write("DF95 Refactor Assist (Dry Run)\n")
    tf:write("Resource Path: " .. base .. "\n")
    tf:write("Scanned roots:\n")
    for _, root in ipairs(roots) do tf:write("  - " .. root .. "\n") end
    tf:write(string.format("\nScanned Lua files: %d\n", #lua_files))
    tf:write(string.format("Findings: %d (WARN=%d, ERROR=%d, INFO=%d)\n\n",
      #findings, counts_by_sev.WARN, counts_by_sev.ERROR, counts_by_sev.INFO))

    tf:write("Counts by rule:\n")
    for rid, c in pairs(counts_by_rule) do
      tf:write(string.format("  %-34s %d\n", rid, c))
    end
    tf:write("\n--- Findings (first by severity, then rule) ---\n\n")

    local sev_order = { ERROR=1, WARN=2, INFO=3 }
    table.sort(findings, function(a,b)
      local ao = sev_order[a.severity] or 99
      local bo = sev_order[b.severity] or 99
      if ao ~= bo then return ao < bo end
      if (a.rule_id or "") ~= (b.rule_id or "") then return (a.rule_id or "") < (b.rule_id or "") end
      if (a.file or "") ~= (b.file or "") then return (a.file or "") < (b.file or "") end
      return (a.line or 0) < (b.line or 0)
    end)

    for _, fnd in ipairs(findings) do
      tf:write(string.format("[%s] %s\n", fnd.severity, fnd.rule_id))
      tf:write(string.format("  file: %s:%d\n", fnd.file, fnd.line))
      tf:write("  excerpt: " .. fnd.excerpt .. "\n")
      if fnd.proposed ~= "" then
        tf:write("  proposed: " .. fnd.proposed .. "\n")
      end
      if fnd.hint ~= "" then
        tf:write("  hint: " .. fnd.hint .. "\n")
      end
      tf:write("\n")
    end
    tf:close()
  end

  -- JSON
  local jf = io.open(out_json, "w")
  if jf then
    jf:write("{\n")
    jf:write('  "repo_root": "' .. json_escape(base) .. '",\n')
    jf:write('  "scanned_roots": [\n')
    for i, root in ipairs(roots) do
      jf:write('    "' .. json_escape(root) .. '"')
      if i == #roots then jf:write("\n") else jf:write(",\n") end
    end
    jf:write("  ],\n")
    jf:write('  "scanned_lua_files": ' .. tostring(#lua_files) .. ",\n")
    jf:write('  "summary": {\n')
    jf:write('    "findings": ' .. tostring(#findings) .. ",\n")
    jf:write('    "warn": ' .. tostring(counts_by_sev.WARN) .. ",\n")
    jf:write('    "error": ' .. tostring(counts_by_sev.ERROR) .. ",\n")
    jf:write('    "info": ' .. tostring(counts_by_sev.INFO) .. "\n")
    jf:write("  },\n")
    jf:write('  "counts_by_rule": {\n')
    local first = true
    for rid, c in pairs(counts_by_rule) do
      if not first then jf:write(",\n") end
      first = false
      jf:write('    "' .. json_escape(rid) .. '": ' .. tostring(c))
    end
    jf:write("\n  },\n")
    jf:write('  "findings_list": [\n')
    for i, fnd in ipairs(findings) do
      jf:write("    {\n")
      jf:write('      "severity": "' .. json_escape(fnd.severity) .. '",\n')
      jf:write('      "rule_id": "' .. json_escape(fnd.rule_id) .. '",\n')
      jf:write('      "file": "' .. json_escape(fnd.file) .. '",\n')
      jf:write('      "line": ' .. tostring(fnd.line) .. ",\n")
      jf:write('      "excerpt": "' .. json_escape(fnd.excerpt) .. '",\n')
      jf:write('      "proposed": "' .. json_escape(fnd.proposed) .. '",\n')
      jf:write('      "hint": "' .. json_escape(fnd.hint) .. '"\n')
      if i == #findings then jf:write("    }\n") else jf:write("    },\n") end
    end
    jf:write("  ]\n")
    jf:write("}\n")
    jf:close()
  end

  r.ShowMessageBox(
    "DF95 Refactor Assist (Dry Run) abgeschlossen.\n\nReports:\n" .. out_txt .. "\n" .. out_json,
    "DF95 Refactor Assist (Dry Run)", 0
  )
end

return M
