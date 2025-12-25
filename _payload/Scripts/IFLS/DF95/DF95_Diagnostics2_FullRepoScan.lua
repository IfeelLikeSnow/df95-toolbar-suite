-- DF95_Diagnostics2_FullRepoScan.lua
-- Phase 115: Diagnostics 2.0 – Vollständiger Skript- und FX-Scan für IFLS/DF95
--
-- ZWECK
-- =====
-- Dieses Script analysiert das IFLS/DF95-Universum unterhalb von "IfeelLikeSnow":
--
--   * Lua-Syntaxcheck für alle .lua-Skripte unterhalb von Scripts/IfeelLikeSnow
--   * Auflistung fehlerhafter Lua-Dateien (Compile-Fehler)
--   * Übersicht über gefundene JSFX- und EEL-Dateien unterhalb von
--        Scripts/IfeelLikeSnow und Effects/IfeelLikeSnow
--   * Ausgabe als:
--        - Text-Report:  Support/DF95_Diagnostics2/DF95_Diagnostics_Report.txt
--        - JSON:         Support/DF95_Diagnostics2/DF95_Diagnostics_Report.json
--
-- HINWEIS:
--   * Es werden KEINE Skripte ausgeführt, nur kompiliert (Lua: loadfile),
--     d.h. keine Seiteneffekte.
--   * Für JSFX/EEL kann nur eine Struktur-/Header-Prüfung vorgenommen werden,
--     kein echter Parser.
--   * Dieses Tool ist als Überblick gedacht; es ersetzt keinen manuellen Test
--     aller Workflows, hilft aber, Syntaxfehler und fehlende Dateien schnell zu finden.

local r = reaper

------------------------------------------------------------
-- Pfad-Helfer
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function get_repo_root_from_this_script()
  local info = debug.getinfo(1, "S")
  local this_path = info and info.source:match("^@(.+)$") or ""
  if this_path == "" then return nil end
  local sep = package.config:sub(1,1)
  -- this_path: .../Scripts/IFLS/DF95/DF95_Diagnostics2_FullRepoScan.lua
  local base = this_path:match("^(.*"..sep..")") or ""

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
  if base == "" then return nil end
  -- gehe drei Ebenen nach oben: DF95 -> IfeelLikeSnow -> Scripts -> (RepoRoot)
  local up = base:gsub(sep.."[^"..sep.."]*"..sep.."$", sep)
  up = up:gsub(sep.."[^"..sep.."]*"..sep.."$", sep)
  up = up:gsub(sep.."[^"..sep.."]*"..sep.."$", sep)
  return up
end

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if not a or a == "" then return b end
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function ensure_dir(path)
  local sep = package.config:sub(1,1)
  local accum = ""
  for part in string.gmatch(path, "[^"..sep.."]+") do
    accum = accum == "" and part or (accum .. sep .. part)
    r.RecursiveCreateDirectory(accum, 0)
  end
end

------------------------------------------------------------
-- Directory Walk (rekursiv)
------------------------------------------------------------

local function scan_dir_collect_files(root, exts)
  local sep = package.config:sub(1,1)
  local files = {}

  local function scan(path)
    local i = 0
    while true do
      local fname = r.EnumerateFiles(path, i)
      if not fname then break end
      local full = path .. sep .. fname
      local lower = fname:lower()
      for _, ext in ipairs(exts) do
        if lower:sub(-#ext) == ext then
          files[#files+1] = full
          break
        end
      end
      i = i + 1
    end

    i = 0
    while true do
      local dname = r.EnumerateSubdirectories(path, i)
      if not dname then break end
      scan(path .. sep .. dname)
      i = i + 1
    end
  end

  scan(root)
  return files
end

------------------------------------------------------------
-- Lua-Syntaxcheck
------------------------------------------------------------

local function check_lua_file(path)
  local fn, err = loadfile(path)
  if not fn then
    return false, err or "unknown Lua compile error"
  end
  return true, nil
end

------------------------------------------------------------
-- JSFX/EEL Basic Check
------------------------------------------------------------

local function basic_jsfx_check(path)
  local f = io.open(path, "r")
  if not f then return false, "cannot open file" end
  local first = f:read("*l") or ""
  f:close()
  if not first:match("^%s*desc:") then
    return false, "missing 'desc:' in first line"
  end
  return true, nil
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local repo_root = get_repo_root_from_this_script()
  if not repo_root then
    r.ShowMessageBox(
      "Konnte Repo-Root nicht bestimmen.\n" ..
      "Bitte stelle sicher, dass dieses Script im IFLS/DF95-Ordner liegt.",
      "DF95 Diagnostics 2.0",
      0
    )
    return
  end

  local sep = package.config:sub(1,1)

  local scripts_root = join_path(repo_root, "Scripts")
  local effects_root = join_path(repo_root, "Effects")
  local support_root = join_path(repo_root, "Support")
  local diag_root = join_path(support_root, "DF95_Diagnostics2")
  ensure_dir(diag_root)

  local report_txt = join_path(diag_root, "DF95_Diagnostics_Report.txt")
  local report_json = join_path(diag_root, "DF95_Diagnostics_Report.json")

  local lua_files = {}
  local jsfx_files = {}
  local eel_files = {}

  -- Nur IfeelLikeSnow-Namespace scannen
  local ifls_scripts = join_path(scripts_root, "IfeelLikeSnow")
  local ifls_effects = join_path(effects_root, "IfeelLikeSnow")

  local exts_lua = { ".lua" }
  local exts_jsfx = { ".jsfx" }
  local exts_eel = { ".eel" }

  -- Scripts/IfeelLikeSnow
  local attr_scripts = r.EnumerateFiles(ifls_scripts, 0)
  if attr_scripts then
    for _, f in ipairs(scan_dir_collect_files(ifls_scripts, exts_lua)) do
      lua_files[#lua_files+1] = f
    end
    for _, f in ipairs(scan_dir_collect_files(ifls_scripts, exts_eel)) do
      eel_files[#eel_files+1] = f
    end
  end

  -- Effects/IfeelLikeSnow
  local attr_fx = r.EnumerateFiles(ifls_effects, 0)
  if attr_fx then
    for _, f in ipairs(scan_dir_collect_files(ifls_effects, exts_jsfx)) do
      jsfx_files[#jsfx_files+1] = f
    end
  end

  local lua_ok = {}
  local lua_err = {}

  for _, path in ipairs(lua_files) do
    local ok, err = check_lua_file(path)
    if ok then
      lua_ok[#lua_ok+1] = path
    else
      lua_err[#lua_err+1] = { path = path, error = err }
    end
  end

  local jsfx_ok = {}
  local jsfx_err = {}

  for _, path in ipairs(jsfx_files) do
    local ok, err = basic_jsfx_check(path)
    if ok then
      jsfx_ok[#jsfx_ok+1] = path
    else
      jsfx_err[#jsfx_err+1] = { path = path, error = err }
    end
  end

  local eel_list = {}
  for _, path in ipairs(eel_files) do
    eel_list[#eel_list+1] = path
  end

  -- Text-Report
  local tf, terr = io.open(report_txt, "w")
  if not tf then
    r.ShowMessageBox(
      "Konnte Text-Report nicht schreiben:\n" .. tostring(terr),
      "DF95 Diagnostics 2.0",
      0
    )
    return
  end

  local function w(line)
    tf:write(line .. "\n")
  end

  w("DF95 Diagnostics 2.0 – Full IFLS Scan (Scripts/IfeelLikeSnow & Effects/IfeelLikeSnow)")
  w("Repo Root: " .. tostring(repo_root))
  w("")
  w("Lua Files: " .. tostring(#lua_files))
  w("JSFX Files: " .. tostring(#jsfx_files))
  w("EEL Files: " .. tostring(#eel_files))
  w("")
  w("=== Lua OK ===")
  for _, path in ipairs(lua_ok) do
    w(path)
  end
  w("")
  w("=== Lua ERRORS ===")
  for _, e in ipairs(lua_err) do
    w(string.format("%s :: %s", e.path, e.error or "?"))
  end
  w("")
  w("=== JSFX OK (Header check: desc:) ===")
  for _, path in ipairs(jsfx_ok) do
    w(path)
  end
  w("")
  w("=== JSFX WARN/ERROR ===")
  for _, e in ipairs(jsfx_err) do
    w(string.format("%s :: %s", e.path, e.error or "?"))
  end
  w("")
  w("=== EEL Files (nicht tief analysiert) ===")
  for _, path in ipairs(eel_list) do
    w(path)
  end

  tf:close()

  -- JSON-Report
  local jf, jerr = io.open(report_json, "w")
  if jf then
    local report = {
      repo_root = repo_root,
      scope = "IfeelLikeSnow only",
      roots = {
        scripts = ifls_scripts,
        effects = ifls_effects,
      },
      counts = {
        lua  = #lua_files,
        jsfx = #jsfx_files,
        eel  = #eel_files,
        lua_ok = #lua_ok,
        lua_err = #lua_err,
        jsfx_ok = #jsfx_ok,
        jsfx_err = #jsfx_err,
      },
      lua_ok   = lua_ok,
      lua_err  = lua_err,
      jsfx_ok  = jsfx_ok,
      jsfx_err = jsfx_err,
      eel_files= eel_list,
    }

    local function encode(o, indent)
      indent = indent or 0
      local sp = string.rep("  ", indent)
      if type(o) == "table" then
        local is_array = true
        local n = 0
        for k, _ in pairs(o) do
          if type(k) ~= "number" then is_array = false break end
          if k > n then n = k end
        end
        local parts = {}
        if is_array then
          for i = 1, n do
            parts[#parts+1] = encode(o[i], indent+1)
          end
          return "[\n" .. sp .. "  " .. table.concat(parts, ",\n" .. sp .. "  ") .. "\n" .. sp .. "]"
        else
          for k, v in pairs(o) do
            parts[#parts+1] = string.format("%s  %q: %s", sp, tostring(k), encode(v, indent+1))
          end
          return "{\n" .. table.concat(parts, ",\n") .. "\n" .. sp .. "}"
        end
      elseif type(o) == "string" then
        return string.format("%q", o)
      elseif type(o) == "number" or type(o) == "boolean" then
        return tostring(o)
      else
        return "null"
      end
    end

    jf:write(encode(report, 0))
    jf:close()
  end

  r.ShowMessageBox(
    "Diagnostics 2.0 (IfeelLikeSnow) abgeschlossen.\n\n" ..
    "Text-Report:\n  " .. report_txt .. "\n\n" ..
    "JSON-Report:\n  " .. report_json .. "\n\n" ..
    "Lua-Dateien mit Fehlern werden im Abschnitt 'Lua ERRORS' aufgeführt.",
    "DF95 Diagnostics 2.0 – IfeelLikeSnow Namespace",
    0
  )
end

main()
