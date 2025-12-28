-- DF95_Diagnostics_Lib_RefactorAssist_ApplySafe_RootResolver.lua
-- ApplySafe Refactor Assist (RootResolver Mode)
-- Ziel: harte Legacy-DF95-Pfadkonstruktionen auf DF95_PathResolver-Root umstellen.
--
-- Features:
--  - Plan (Dry-run) + Apply in einem Run
--  - pro Datei Backup (*.bak_YYYYMMDD_HHMMSS)
--  - schreibt Report TXT + JSON nach Support/DF95_Reports
--
-- Sehr konservativ: ersetzt nur klare Legacy-DF95-Pfadpatterns:
--   1) "Scripts/IfeelLikeSnow/DF95" (oder Backslashes)
--   2) join(..., "Scripts", "IfeelLikeSnow", "DF95", ...)
--   3) Konkatenationen mit "Scripts".."IfeelLikeSnow".."DF95"
--   4) "Scripts/DF95/" -> "Scripts/DF95Framework/" (optional, heuristisch)
--
-- Es wird ein Header-Snippet eingefügt (nur wenn ein File tatsächlich geändert wird):
--   local PR = dofile(reaper.GetResourcePath().."/Scripts/DF95Framework/Lib/DF95_PathResolver.lua")
--   local DF95_ROOT = PR.get_df95_scripts_root()

local r = reaper
local M = {}

local function norm(s)
  local out = (s or ""):gsub("\\","/")
  return out
end

local function read_all(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function write_all(path, content)
  local f = io.open(path, "w")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
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

local HEADER_SNIPPET = [[
-- DF95 RootResolver injected by ApplySafe (do not duplicate)
local __df95_PR = dofile(reaper.GetResourcePath() .. "/Scripts/DF95Framework/Lib/DF95_PathResolver.lua")
local DF95_ROOT = __df95_PR.get_df95_scripts_root()
]]

local function has_header(content)
  return content:find("DF95 RootResolver injected by ApplySafe", 1, true) ~= nil
end

-- Pattern replacements; return new_content, changes(list)
local function apply_patterns(content)
  local changes = {}
  local out = content

  local function record(kind, from, to)
    table.insert(changes, { kind = kind, from = from, to = to })
  end

  -- 1) Hard-coded DF95 legacy folder path inside strings
  local before = out
  out = out:gsub("Scripts[/\\]IfeelLikeSnow[/\\]DF95", "DF95_ROOT")
  if out ~= before then record("REPLACE_LEGACY_PATH", "Scripts/IfeelLikeSnow/DF95", "DF95_ROOT") end

  -- 2) join(..., "Scripts", "IfeelLikeSnow", "DF95")
  before = out
  out = out:gsub("join%(([^%)]-),%s*\"Scripts\"%s*,%s*\"IfeelLikeSnow\"%s*,%s*\"DF95\"%s*%)", "DF95_ROOT")
  if out ~= before then record("REPLACE_JOIN_LEGACY", "join(...,\"Scripts\",\"IfeelLikeSnow\",\"DF95\")", "DF95_ROOT") end

  -- 3) concat patterns ... "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
  before = out
  -- very conservative: only exact tokens in order
  out = out:gsub("\"Scripts\"%s*%.%.%s*sep%s*%.%.%s*\"IfeelLikeSnow\"%s*%.%.%s*sep%s*%.%.%s*\"DF95\"", "DF95_ROOT")
  if out ~= before then record("REPLACE_CONCAT_LEGACY", "\"Scripts\"..sep..\"IfeelLikeSnow\"..sep..\"DF95\"", "DF95_ROOT") end

  -- 4) Optional heuristic: Scripts/DF95/ -> Scripts/DF95Framework/
  -- Only replace when it clearly looks like a path segment.
  before = out
  out = out:gsub("Scripts[/\\]DF95[/\\]", "Scripts/DF95Framework/")
  if out ~= before then record("HEURISTIC_DF95_TO_DF95FRAMEWORK", "Scripts/DF95/", "Scripts/DF95Framework/") end

  return out, changes
end

local function insert_header_if_needed(content)
  if has_header(content) then return content end

  -- Insert after initial comment header block (lines starting with --) and blank lines
  local lines = {}
  for line in content:gmatch("([^\n]*)\n?") do
    table.insert(lines, line)
  end
  -- last element from gmatch may be empty after final newline; keep fine.

  local insert_at = 1
  for i, line in ipairs(lines) do
    local t = line:match("^%s*(.-)%s*$") or ""
    if t:sub(1,2) == "--" or t == "" then
      insert_at = i + 1
    else
      insert_at = i
      break
    end
  end

  local new_lines = {}
  for i=1, insert_at-1 do table.insert(new_lines, lines[i]) end
  for snip_line in HEADER_SNIPPET:gmatch("([^\n]+)\n?") do
    table.insert(new_lines, snip_line)
  end
  for i=insert_at, #lines do table.insert(new_lines, lines[i]) end

  return table.concat(new_lines, "\n")
end

function M.run(opts)
  opts = opts or {}
  local base = norm(r.GetResourcePath())
  local report_dir = base .. "/Support/DF95_Reports"
  r.RecursiveCreateDirectory(report_dir, 0)

  local roots = {
    base .. "/Scripts/IFLS",
    base .. "/Scripts/DF95Framework",
  }

  local files = {}
  for _, root in ipairs(roots) do
    scan_dir_for_lua(root, files)
  end

  local plan = {}
  local total_files_changed = 0
  local total_replacements = 0

  for _, fpath in ipairs(files) do
    local c = read_all(fpath)
    if c then
      local newc, changes = apply_patterns(c)
      if #changes > 0 and newc ~= c then
        newc = insert_header_if_needed(newc)
        total_files_changed = total_files_changed + 1
        total_replacements = total_replacements + #changes
        table.insert(plan, {
          file = fpath,
          changes = changes,
        })
      end
    end
  end

  local ts = os.date("%Y%m%d_%H%M%S")
  local out_txt = report_dir .. "/DF95_RefactorAssist_ApplySafe_RootResolver_" .. ts .. ".txt"
  local out_json = report_dir .. "/DF95_RefactorAssist_ApplySafe_RootResolver_" .. ts .. ".json"

  -- Write report first (dry plan)
  local tf = io.open(out_txt, "w")
  if tf then
    tf:write("DF95 ApplySafe (RootResolver Mode)\n")
    tf:write("Resource Path: " .. base .. "\n")
    tf:write("Scanned Lua files: " .. tostring(#files) .. "\n")
    tf:write("Planned file edits: " .. tostring(#plan) .. "\n")
    tf:write("Planned replacements: " .. tostring(total_replacements) .. "\n\n")
    for _, p in ipairs(plan) do
      tf:write("FILE: " .. p.file .. "\n")
      for _, ch in ipairs(p.changes) do
        tf:write(string.format("  - %s: %s -> %s\n", ch.kind, ch.from, ch.to))
      end
      tf:write("\n")
    end
    tf:close()
  end

  local jf = io.open(out_json, "w")
  if jf then
    jf:write("{\n")
    jf:write('  "repo_root": "' .. json_escape(base) .. '",\n')
    jf:write('  "scanned_lua_files": ' .. tostring(#files) .. ",\n")
    jf:write('  "planned_file_edits": ' .. tostring(#plan) .. ",\n")
    jf:write('  "planned_replacements": ' .. tostring(total_replacements) .. ",\n")
    jf:write('  "plan": [\n')
    for i, p in ipairs(plan) do
      jf:write("    {\n")
      jf:write('      "file": "' .. json_escape(p.file) .. '",\n')
      jf:write('      "changes": [\n')
      for j, ch in ipairs(p.changes) do
        jf:write("        {\n")
        jf:write('          "kind": "' .. json_escape(ch.kind) .. '",\n')
        jf:write('          "from": "' .. json_escape(ch.from) .. '",\n')
        jf:write('          "to": "' .. json_escape(ch.to) .. '"\n')
        if j == #p.changes then jf:write("        }\n") else jf:write("        },\n") end
      end
      jf:write("      ]\n")
      if i == #plan then jf:write("    }\n") else jf:write("    },\n") end
    end
    jf:write("  ]\n")
    jf:write("}\n")
    jf:close()
  end

  if #plan == 0 then
    r.ShowMessageBox("Keine passenden Legacy-Pfadpatterns für RootResolver-Refactor gefunden.\n\nReport:\n" .. out_txt,
      "DF95 ApplySafe RootResolver", 0)
    return
  end

  local apply = false
  if opts.auto_apply == true then
    apply = true
  else
    local ret = r.ShowMessageBox(
      "ApplySafe RootResolver PLAN erstellt.\n\n" ..
      "Geplante Dateiedits: " .. tostring(#plan) .. "\n" ..
      "Geplante Replacements: " .. tostring(total_replacements) .. "\n\n" ..
      "Report:\n" .. out_txt .. "\n\n" ..
      "JETZT anwenden? (Backups werden erstellt)",
      "DF95 ApplySafe RootResolver",
      4 -- Yes/No
    )
    apply = (ret == 6)
  end

  if not apply then
    r.ShowMessageBox("Dry-run beendet. Keine Dateien geändert.\n\nReport:\n" .. out_txt,
      "DF95 ApplySafe RootResolver", 0)
    return
  end

  -- Apply changes with backups
  local applied = 0
  local failed = 0
  local backup_ts = os.date("%Y%m%d_%H%M%S")

  for _, p in ipairs(plan) do
    local fpath = p.file
    local c = read_all(fpath)
    if c then
      local newc, _ = apply_patterns(c)
      newc = insert_header_if_needed(newc)
      if newc ~= c then
        local bak = fpath .. ".bak_" .. backup_ts
        if write_all(bak, c) then
          if write_all(fpath, newc) then
            applied = applied + 1
          else
            failed = failed + 1
            -- restore attempt
            write_all(fpath, c)
          end
        else
          failed = failed + 1
        end
      end
    end
  end

  r.ShowMessageBox(
    "ApplySafe RootResolver abgeschlossen.\n\n" ..
    "Applied files: " .. tostring(applied) .. "\n" ..
    "Failed files : " .. tostring(failed) .. "\n\n" ..
    "Plan report:\n" .. out_txt .. "\n" .. out_json ..
    "\n\nHinweis: Bitte REAPER neu starten und anschließend DepScanner+Insight erneut laufen lassen.",
    "DF95 ApplySafe RootResolver", 0
  )
end

return M
