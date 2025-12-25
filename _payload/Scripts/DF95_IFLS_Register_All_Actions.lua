-- DF95/IFLS: Register all installed scripts as Actions (bulk)
-- Runs once. Safe to re-run (existing scripts won't duplicate; REAPER returns 0 if already added).
-- Source: AddRemoveReaScript API in REAPER ReaScript docs. :contentReference[oaicite:1]{index=1}

local function msg(s) reaper.ShowConsoleMsg(tostring(s) .. "\n") end

local function path_join(a, b)
  if a:sub(-1) == "\\" or a:sub(-1) == "/" then return a .. b end
  return a .. package.config:sub(1,1) .. b
end

local function norm(p) return (p:gsub("/", package.config:sub(1,1))) end

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close() return true end
  return false
end

local function read_head(p, max_bytes)
  local f = io.open(p, "rb")
  if not f then return "" end
  local s = f:read(max_bytes or 2048) or ""
  f:close()
  return s
end

-- Heuristik: nur "Action-taugliche" Scripts registrieren
-- (damit nicht tausende Lib-Dateien die Action List zumüllen)
local function is_action_candidate(fullpath, filename)
  local lower = filename:lower()
  if lower:match("^_") then return false end
  if lower:match("lib") and not lower:match("library") then
    -- viele Libs heißen *Lib*; trotzdem erlauben wir DF95_/IFLS_ Entry-Skripte
    -- und Skripte mit @description
  end

  -- Nur ReaScripts: .lua/.eel/.py
  if not (lower:match("%.lua$") or lower:match("%.eel$") or lower:match("%.py$")) then return false end

  -- DF95/IFLS Namenspattern (deckt deine Suite gut ab)
  if filename:match("^DF95_") or filename:match("^IFLS_") then return true end

  -- ReaPack/ReaScript Header: @description etc.
  local head = read_head(fullpath, 4096)
  if head:match("@description") or head:match("@about") or head:match("@version") then
    return true
  end

  return false
end

local function enum_files_recursive(root_dir, out)
  out = out or {}
  local i = 0
  while true do
    local fn = reaper.EnumerateFiles(root_dir, i)
    if not fn then break end
    local full = path_join(root_dir, fn)
    table.insert(out, { full = full, name = fn, is_dir = false })
    i = i + 1
  end

  local j = 0
  while true do
    local dn = reaper.EnumerateSubdirectories(root_dir, j)
    if not dn then break end
    local full = path_join(root_dir, dn)
    table.insert(out, { full = full, name = dn, is_dir = true })
    enum_files_recursive(full, out)
    j = j + 1
  end

  return out
end

local function find_candidate_roots(scripts_root)
  -- Wir suchen typische Install-Pfade innerhalb des Scripts-Ordners
  local roots = {}

  -- 1) häufig: Scripts/DF95 Toolbar Suite/...
  local guess1 = path_join(scripts_root, "DF95 Toolbar Suite")
  if reaper.EnumerateSubdirectories(guess1, 0) ~= nil then table.insert(roots, guess1) end

  -- 2) häufig: Scripts/IfeelLikeSnow/...
  local guess2 = path_join(scripts_root, "IfeelLikeSnow")
  if reaper.EnumerateSubdirectories(guess2, 0) ~= nil then table.insert(roots, guess2) end

  -- 3) häufig: Scripts/IFLS/...
  local guess3 = path_join(scripts_root, "IFLS")
  if reaper.EnumerateSubdirectories(guess3, 0) ~= nil then table.insert(roots, guess3) end

  -- 4) fallback: kompletten Scripts-Ordner scannen (langsamer, aber sicher)
  if #roots == 0 then table.insert(roots, scripts_root) end

  return roots
end

local function main()
  reaper.ClearConsole()
  msg("DF95/IFLS Register: start")

  local resource = reaper.GetResourcePath()
  local scripts_root = path_join(resource, "Scripts")
  scripts_root = norm(scripts_root)

  if not reaper.EnumerateSubdirectories(scripts_root, 0) and not reaper.EnumerateFiles(scripts_root, 0) then
    msg("ERROR: Scripts folder not found/empty: " .. scripts_root)
    return
  end

  local roots = find_candidate_roots(scripts_root)
  msg("Scanning roots:")
  for _, r in ipairs(roots) do msg("  - " .. r) end

  local candidates = {}
  for _, r in ipairs(roots) do
    local entries = enum_files_recursive(r)
    for _, e in ipairs(entries) do
      if not e.is_dir then
        if is_action_candidate(e.full, e.name) then
          table.insert(candidates, e.full)
        end
      end
    end
  end

  -- de-dupe
  local seen, uniq = {}, {}
  for _, p in ipairs(candidates) do
    if not seen[p] and file_exists(p) then
      seen[p] = true
      table.insert(uniq, p)
    end
  end

  table.sort(uniq)
  msg(("Candidates: %d"):format(#uniq))

  if #uniq == 0 then
    msg("No candidate scripts found. Check install path under ResourcePath/Scripts.")
    return
  end

  -- Register into Main section (0)
  -- Signature: reaper.AddRemoveReaScript(add, sectionID, scriptfn, commit). :contentReference[oaicite:2]{index=2}
  local sectionID = 0
  local added, already = 0, 0

  reaper.Undo_BeginBlock()
  for idx, p in ipairs(uniq) do
    local commit = (idx == #uniq) -- commit only at end for speed
    local cmd = reaper.AddRemoveReaScript(true, sectionID, p, commit)
    if cmd ~= 0 then
      added = added + 1
    else
      already = already + 1
    end
  end
  reaper.Undo_EndBlock("DF95/IFLS: register scripts to action list", -1)

  msg(("Done. Added: %d, Already/Skipped: %d"):format(added, already))
  msg("Now open Actions and search for IFLS / DF95. If still empty: restart REAPER once.")
end

main()
