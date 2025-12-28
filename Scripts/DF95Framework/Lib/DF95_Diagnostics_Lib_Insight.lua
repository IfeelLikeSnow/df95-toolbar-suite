-- DF95_Diagnostics_Lib_Insight.lua
-- Analysiert DF95_DepGraph_*.json und erzeugt Findings als TXT + JSON.
-- Output: Support/DF95_Reports/DF95_Insight_YYYYMMDD_HHMMSS.{txt,json}

local r = reaper
local M = {}

-- -------- helpers --------
local function norm(s) return (s or ""):gsub("\\","/") end
local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function read_all(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function json_escape(str)
  str = tostring(str or "")
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  return str
end

-- -------- tiny JSON decoder --------
-- Supports: objects, arrays, strings, numbers, booleans, null
local function json_decode(s)
  local i, n = 1, #s

  local function skip_ws()
    while i <= n do
      local c = s:sub(i,i)
      if c == " " or c == "\t" or c == "\n" or c == "\r" then
        i = i + 1
      else
        break
      end
    end
  end

  local function parse_string()
    -- assumes s[i] == '"'
    i = i + 1
    local out = {}
    while i <= n do
      local c = s:sub(i,i)
      if c == "\"" then
        i = i + 1
        return table.concat(out)
      elseif c == "\\" then
        local nxt = s:sub(i+1,i+1)
        if nxt == "\"" or nxt == "\\" or nxt == "/" then
          table.insert(out, nxt)
          i = i + 2
        elseif nxt == "b" then table.insert(out, "\b"); i = i + 2
        elseif nxt == "f" then table.insert(out, "\f"); i = i + 2
        elseif nxt == "n" then table.insert(out, "\n"); i = i + 2
        elseif nxt == "r" then table.insert(out, "\r"); i = i + 2
        elseif nxt == "t" then table.insert(out, "\t"); i = i + 2
        elseif nxt == "u" then
          -- minimal: keep as-is
          local hex = s:sub(i+2,i+5)
          table.insert(out, "\\u"..hex)
          i = i + 6
        else
          error("Invalid escape at "..i)
        end
      else
        table.insert(out, c)
        i = i + 1
      end
    end
    error("Unterminated string")
  end

  local function parse_number()
    local start = i
    local c = s:sub(i,i)
    if c == "-" then i = i + 1 end
    while i <= n and s:sub(i,i):match("%d") do i = i + 1 end
    if i <= n and s:sub(i,i) == "." then
      i = i + 1
      while i <= n and s:sub(i,i):match("%d") do i = i + 1 end
    end
    if i <= n and (s:sub(i,i) == "e" or s:sub(i,i) == "E") then
      i = i + 1
      local sgn = s:sub(i,i)
      if sgn == "+" or sgn == "-" then i = i + 1 end
      while i <= n and s:sub(i,i):match("%d") do i = i + 1 end
    end
    local num = tonumber(s:sub(start, i-1))
    return num
  end

  local parse_value

  local function parse_array()
    -- assumes s[i] == '['
    i = i + 1
    local arr = {}
    skip_ws()
    if s:sub(i,i) == "]" then i = i + 1; return arr end
    while true do
      skip_ws()
      table.insert(arr, parse_value())
      skip_ws()
      local c = s:sub(i,i)
      if c == "," then i = i + 1
      elseif c == "]" then i = i + 1; break
      else error("Expected , or ] at "..i) end
    end
    return arr
  end

  local function parse_object()
    -- assumes s[i] == '{'
    i = i + 1
    local obj = {}
    skip_ws()
    if s:sub(i,i) == "}" then i = i + 1; return obj end
    while true do
      skip_ws()
      if s:sub(i,i) ~= "\"" then error("Expected string key at "..i) end
      local key = parse_string()
      skip_ws()
      if s:sub(i,i) ~= ":" then error("Expected : at "..i) end
      i = i + 1
      skip_ws()
      obj[key] = parse_value()
      skip_ws()
      local c = s:sub(i,i)
      if c == "," then i = i + 1
      elseif c == "}" then i = i + 1; break
      else error("Expected , or } at "..i) end
    end
    return obj
  end

  function parse_value()
    skip_ws()
    local c = s:sub(i,i)
    if c == "\"" then return parse_string()
    elseif c == "{" then return parse_object()
    elseif c == "[" then return parse_array()
    elseif c == "-" or c:match("%d") then return parse_number()
    else
      local lit = s:sub(i, i+3)
      if s:sub(i, i+3) == "true" then i = i + 4; return true end
      if s:sub(i, i+4) == "false" then i = i + 5; return false end
      if s:sub(i, i+3) == "null" then i = i + 4; return nil end
      error("Unexpected token at "..i)
    end
  end

  local val = parse_value()
  skip_ws()
  return val
end

-- -------- dep resolution --------
local function module_candidates(base, mod)
  local rel = mod:gsub("%.", "/")
  return {
    base .. "/Scripts/IFLS/" .. rel .. ".lua",
    base .. "/Scripts/IFLS/" .. rel .. "/init.lua",
    base .. "/Scripts/DF95Framework/Lib/" .. rel .. ".lua",
    base .. "/Scripts/DF95Framework/Lib/" .. rel .. "/init.lua",
    base .. "/Scripts/DF95Framework/" .. rel .. ".lua",
    base .. "/Scripts/DF95Framework/" .. rel .. "/init.lua",
  }
end

local function resolve_path(base, from_file, target)
  target = norm(target)
  if target:match("^[A-Za-z]:/") or target:sub(1,1) == "/" then
    return file_exists(target) and target or nil
  end

  local from_dir = norm(from_file):match("^(.*)/[^/]+$") or norm(from_file)
  local candidates = {
    base .. "/" .. target,
    from_dir .. "/" .. target,
    base .. "/Scripts/" .. target,
    base .. "/Scripts/IFLS/" .. target,
    base .. "/Scripts/DF95Framework/" .. target,
    base .. "/Scripts/DF95Framework/Lib/" .. target,
  }

  for _, c in ipairs(candidates) do
    if file_exists(c) then return c end
  end
  return nil
end

local function find_latest_depgraph(report_dir)
  local newest = nil
  local newest_name = nil
  local i = 0
  while true do
    local fn = r.EnumerateFiles(report_dir, i)
    if not fn then break end
    if fn:match("^DF95_DepGraph_%d%d%d%d%d%d%d%d_%d%d%d%d%d%d%.json$") then
      if (not newest_name) or (fn > newest_name) then
        newest_name = fn
      end
    end
    i = i + 1
  end
  if newest_name then
    newest = report_dir .. "/" .. newest_name
  end
  return newest
end

function M.run(opts)
  opts = opts or {}
  local base = norm(r.GetResourcePath())
  local report_dir = base .. "/Support/DF95_Reports"
  r.RecursiveCreateDirectory(report_dir, 0)

  local depgraph_path = opts.depgraph_path or find_latest_depgraph(report_dir)
  if not depgraph_path or not file_exists(depgraph_path) then
    r.ShowMessageBox("Kein DepGraph gefunden.\nErwartet unter:\n" .. report_dir .. "\n\nBitte zuerst DepScanner laufen lassen.",
      "DF95 Insight", 0)
    return
  end

  local raw = read_all(depgraph_path)
  if not raw then
    r.ShowMessageBox("Konnte DepGraph nicht lesen:\n" .. depgraph_path, "DF95 Insight", 0)
    return
  end

  local ok, data = pcall(json_decode, raw)
  if not ok or type(data) ~= "table" then
    r.ShowMessageBox("Konnte DepGraph JSON nicht parsen:\n" .. depgraph_path .. "\n\nFehler:\n" .. tostring(data),
      "DF95 Insight", 0)
    return
  end

  local findings = {}
  local function add(sev, code, file, detail, hint)
    table.insert(findings, {
      severity = sev,
      code = code,
      file = file or "",
      detail = detail or "",
      hint = hint or "",
    })
  end

  local files = data.files or {}
  local legacy_hits = 0
  local missing_requires = 0
  local missing_loads = 0

  for _, entry in ipairs(files) do
    local fpath = norm(entry.path or "")
    -- requires
    for _, mod in ipairs(entry.requires or {}) do
      local m = tostring(mod or "")
      if m:lower():find("ifeellikesnow", 1, true) then
        legacy_hits = legacy_hits + 1
        add("WARN", "LEGACY_REQUIRE", fpath, "require(\"" .. m .. "\")", "Legacy-Namespace gefunden. Bitte auf V2-Struktur umstellen (IFLS/DF95Framework) oder package.path sauber bootstrappen.")
      else
        local resolved = nil
        for _, cand in ipairs(module_candidates(base, m)) do
          if file_exists(cand) then resolved = cand; break end
        end
        if not resolved then
          missing_requires = missing_requires + 1
          add("WARN", "MISSING_REQUIRE_TARGET", fpath, "require(\"" .. m .. "\")", "Module nicht auffindbar über Standard-Candidates. Prüfe package.path (DF95_LuaPath.bootstrap) oder Module-Name/Ort.")
        end
      end
    end

    -- dofile / loadfile targets
    for _, tgt in ipairs(entry.dofiles or {}) do
      local t = tostring(tgt or "")
      if t ~= "" then
        local resolved = resolve_path(base, fpath, t)
        if not resolved then
          missing_loads = missing_loads + 1
          add("ERROR", "MISSING_DOFILE_TARGET", fpath, "dofile(\"" .. t .. "\")", "Ziel nicht gefunden (weder absolut noch relativ plausibel).")
        end
      end
    end

    for _, tgt in ipairs(entry.loadfiles or {}) do
      local t = tostring(tgt or "")
      if t ~= "" then
        local resolved = resolve_path(base, fpath, t)
        if not resolved then
          missing_loads = missing_loads + 1
          add("ERROR", "MISSING_LOADFILE_TARGET", fpath, "loadfile(\"" .. t .. "\")", "Ziel nicht gefunden (weder absolut noch relativ plausibel).")
        end
      end
    end
  end

  -- Summary
  add("INFO", "SUMMARY",
      "",
      "files=" .. tostring(#files) .. ", legacy_requires=" .. tostring(legacy_hits) .. ", missing_requires=" .. tostring(missing_requires) .. ", missing_loads=" .. tostring(missing_loads),
      "DepGraph: " .. depgraph_path)

  local ts = os.date("%Y%m%d_%H%M%S")
  local out_txt = report_dir .. "/DF95_Insight_" .. ts .. ".txt"
  local out_json = report_dir .. "/DF95_Insight_" .. ts .. ".json"

  -- write TXT
  local tf = io.open(out_txt, "w")
  if tf then
    tf:write("DF95 Insight Report\n")
    tf:write("Resource Path: " .. base .. "\n")
    tf:write("DepGraph: " .. depgraph_path .. "\n\n")

    local sev_order = { ERROR=1, WARN=2, INFO=3 }
    table.sort(findings, function(a,b)
      local ao = sev_order[a.severity] or 99
      local bo = sev_order[b.severity] or 99
      if ao ~= bo then return ao < bo end
      return (a.code or "") < (b.code or "")
    end)

    for _, fnd in ipairs(findings) do
      tf:write(string.format("[%s] %s\n", fnd.severity, fnd.code))
      if fnd.file ~= "" then tf:write("  file: " .. fnd.file .. "\n") end
      if fnd.detail ~= "" then tf:write("  detail: " .. fnd.detail .. "\n") end
      if fnd.hint ~= "" then tf:write("  hint: " .. fnd.hint .. "\n") end
      tf:write("\n")
    end
    tf:close()
  end

  -- write JSON
  local jf = io.open(out_json, "w")
  if jf then
    jf:write("{\n")
    jf:write('  "repo_root": "' .. json_escape(base) .. '",\n')
    jf:write('  "depgraph": "' .. json_escape(depgraph_path) .. '",\n')
    jf:write('  "summary": {\n')
    jf:write('    "files": ' .. tostring(#files) .. ',\n')
    jf:write('    "legacy_requires": ' .. tostring(legacy_hits) .. ',\n')
    jf:write('    "missing_requires": ' .. tostring(missing_requires) .. ',\n')
    jf:write('    "missing_loads": ' .. tostring(missing_loads) .. '\n')
    jf:write("  },\n")
    jf:write('  "findings": [\n')
    for i, fnd in ipairs(findings) do
      jf:write("    {\n")
      jf:write('      "severity": "' .. json_escape(fnd.severity) .. '",\n')
      jf:write('      "code": "' .. json_escape(fnd.code) .. '",\n')
      jf:write('      "file": "' .. json_escape(fnd.file) .. '",\n')
      jf:write('      "detail": "' .. json_escape(fnd.detail) .. '",\n')
      jf:write('      "hint": "' .. json_escape(fnd.hint) .. '"\n')
      if i == #findings then
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
    "DF95 Insight abgeschlossen.\n\nReports:\n" .. out_txt .. "\n" .. out_json,
    "DF95 Insight", 0
  )
end

return M
