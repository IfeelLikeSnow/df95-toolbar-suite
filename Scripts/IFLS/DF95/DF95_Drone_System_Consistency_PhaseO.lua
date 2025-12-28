\
-- DF95_Drone_System_Consistency_PhaseO.lua
-- Phase O – Full Drone System Consistency Test (V2)
--
-- Zweck:
--   Führt einen End-to-End-Konsistenzcheck über das DF95 Drone-Subsystem durch,
--   mit Fokus auf:
--     - Vollständigkeit der Drone-Felder
--     - Gültigkeit aller Enum-Werte (Phase L)
--     - Struktur der DB
--     - optional: Anstoßen weiterer Subsystem-Checks (Phase J, Dashboard/Inspector)
--
--   WICHTIG:
--     - Dieses Script nimmt KEINE Änderungen an der DB vor (read-only).
--     - Es erzeugt einen Report auf Dateiebene + Konsolen-Summary.
--
--   Output:
--     - REAPER-Konsole: Kurz-Zusammenfassung
--     - <REAPER>/Support/DF95_SampleDB/DF95_Drone_PhaseO_Report_<YYYYMMDD_HHMMSS>.txt
--     - MessageBox mit OK/WARN/FAIL Status
--
--   Phase O V2:
--     - Alles aus V1 (DB-/Enum-Konsistenz)
--     - + optionale Hooks zu:
--         * Phase J (Drone QA Validator)
--         * Dashboard-Testaktion(en)
--         * Inspector-Testaktion(en)
--
--   Hinweis zu den Hooks:
--     - REAPER bietet keine API, Actions per Name zu suchen.
--       Du musst daher Named Command Strings konfigurieren (z. B. "_RS1234567890ABCDE").
--     - Siehe CFG unten.

local r = reaper

------------------------------------------------------------
-- Konfiguration (Subsystem Hooks)
------------------------------------------------------------

local CFG = {
  -- Phase J: Drone QA Validator
  enable_phaseJ       = false,
  phaseJ_cmd_str      = "", -- z.B. "_RSabcdef123456789"

  -- Dashboard Test (Phase K / Drilldown)
  enable_dashboard    = false,
  dashboard_cmd_str   = "", -- z.B. "_RS1234567890abcd"

  -- Inspector Test (Phase K / Inspector)
  enable_inspector    = false,
  inspector_cmd_str   = "", -- z.B. "_RSfedcba987654321",
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function log(msg)
  r.ShowConsoleMsg(tostring(msg) .. "\n")
end

local function upper(str)
  if type(str) ~= "string" then return "" end
  return string.upper(str)
end

local function get_db_paths()
  local res_path = r.GetResourcePath()
  local db_dir = res_path .. "/Support/DF95_SampleDB"
  local db_path = db_dir .. "/DF95_SampleDB_Multi_UCS.json"
  return db_dir, db_path
end

local function ensure_dir(path)
  return true
end

------------------------------------------------------------
-- JSON Helper (wie in Phase N, read-only)
------------------------------------------------------------

local json = nil

local function init_json()
  if json then return true end

  local ok, m = pcall(require, "json")
  if ok and m then
    json = m
    return true
  end

  ok, m = pcall(require, "dkjson")
  if ok and m then
    json = m
    return true
  end

  return false
end

local function json_decode(str)
  if not json then return nil, "JSON library not initialized" end

  if type(json.decode) == "function" then
    local ok, res, pos, err = pcall(json.decode, str)
    if ok and res and not err then
      return res
    elseif ok and res and type(res) == "table" then
      return res
    else
      return nil, err or "JSON decode error"
    end
  end

  return nil, "Unsupported JSON implementation"
end

------------------------------------------------------------
-- DF95 Drone Enums (Phase L)
------------------------------------------------------------

local DroneEnums = nil

local function init_drone_enums()
  if DroneEnums then return true end

  local res_path = r.GetResourcePath()
  local path = res_path .. "/Scripts/IFLS/DF95/DF95_Drone_Enums_PhaseL.lua"
  local ok, m = pcall(dofile, path)
  if not ok or not m then
    return false, "Could not load DF95_Drone_Enums_PhaseL.lua\nTried: " .. path
  end
  DroneEnums = m
  return true
end

------------------------------------------------------------
-- Drone Detection (konsistent mit Phase N)
------------------------------------------------------------

local function is_drone_item(it)
  if type(it) ~= "table" then return false end

  local role  = upper(it.role)
  local flag  = upper(it.df95_drone_flag)
  local catid = upper(it.df95_catid or "")

  local is_drone = false
  if role == "DRONE" then is_drone = true end
  if flag ~= "" then is_drone = true end
  if catid:find("DRONE", 1, true) then is_drone = true end

  return is_drone
end

------------------------------------------------------------
-- Allowed Enums (Phase L Mirror)
-- Halte diese Listen in Sync mit Phase L.
------------------------------------------------------------

local ALLOWED_CENTERFREQ = {
  LOW  = true,
  MID  = true,
  HIGH = true,
}

local ALLOWED_DENSITY = {
  LOW = true,
  MED = true,
  HIGH = true,
}

local ALLOWED_FORM = {
  PAD      = true,
  TEXTURE  = true,
  SWELL    = true,
  MOVEMENT = true,
  GROWL    = true,
}

local ALLOWED_MOTION = {
  STATIC   = true,
  MOVEMENT = true,
  PULSE    = true,
  SWELL    = true,
}

local ALLOWED_TENSION = {
  LOW     = true,
  MED     = true,
  HIGH    = true,
  EXTREME = true,
}

------------------------------------------------------------
-- Report Writer
------------------------------------------------------------

local function open_report(db_dir)
  local ts = os.date("%Y%m%d_%H%M%S")
  local report_path = db_dir .. "/DF95_Drone_PhaseO_Report_" .. ts .. ".txt"
  local f, err = io.open(report_path, "w")
  if not f then
    return nil, "Cannot open report file: " .. tostring(err)
  end

  local function w(line)
    f:write(line or "")
    f:write("\n")
  end

  return {
    path    = report_path,
    file    = f,
    write   = w,
    close   = function()
      if not f then return end
      f:flush()
      f:close()
      f = nil
    end
  }
end

------------------------------------------------------------
-- Subsystem Hook Helper
------------------------------------------------------------

local function run_named_command_if_enabled(enabled, cmd_str, label, report)
  local summary = {
    enabled = enabled,
    cmd_str = cmd_str or "",
    found   = false,
    ran     = false,
    error   = nil,
  }

  if not enabled then
    summary.error = "disabled in CFG"
    if report and report.write then
      report.write(string.format("SUBSYSTEM: %s -> SKIPPED (disabled in CFG)", label))
    end
    return summary
  end

  if not cmd_str or cmd_str == "" then
    summary.error = "no named command string configured"
    if report and report.write then
      report.write(string.format("SUBSYSTEM: %s -> ERROR (no cmd_str configured)", label))
    end
    return summary
  end

  local cmd_id = r.NamedCommandLookup(cmd_str)
  if not cmd_id or cmd_id == 0 then
    summary.error = "NamedCommandLookup returned 0 (command not found)"
    if report and report.write then
      report.write(string.format("SUBSYSTEM: %s -> ERROR (command not found: %s)", label, cmd_str))
    end
    return summary
  end

  summary.found = true

  -- Wir gehen davon aus, dass diese Actions selbst non-interaktiv / testfähig sind.
  local ok, err = pcall(function()
    r.Main_OnCommand(cmd_id, 0)
  end)

  if not ok then
    summary.error = "error running command: " .. tostring(err)
    if report and report.write then
      report.write(string.format("SUBSYSTEM: %s -> ERROR during run (%s)", label, tostring(err)))
    end
    return summary
  end

  summary.ran = true
  if report and report.write then
    report.write(string.format("SUBSYSTEM: %s -> OK (ran %s)", label, cmd_str))
  end

  return summary
end

------------------------------------------------------------
-- Core Consistency Check
------------------------------------------------------------

local function run_phaseO()
  r.ClearConsole()

  log("DF95 Drone System – Phase O Consistency Test (V2)")
  log("-------------------------------------------------")
  log("")

  -- Warnen, falls Phase N evtl. noch nicht lief
  local db_dir, db_path = get_db_paths()
  ensure_dir(db_dir)

  local phaseN_marker = db_dir .. "/DF95_Drone_PhaseN_COMPLETE.txt"
  local phaseN_done = r.file_exists(phaseN_marker)

  if not phaseN_done then
    log("WARN: Phase N Marker-Datei nicht gefunden:")
    log("  " .. phaseN_marker)
    log("Es sieht so aus, als wäre die Phase-N-Migration evtl. noch nicht gelaufen.")
    log("Der Test wird trotzdem durchgeführt, kann aber viele Enum-Warnungen erzeugen.")
    log("")
  end

  -- JSON init
  if not init_json() then
    r.ShowMessageBox(
      "Konnte keine JSON-Library laden (json oder dkjson).\n" ..
      "Bitte Phase O Script an deine DF95-JSON-Utility anpassen.",
      "DF95 Phase O – Fehler",
      0
    )
    return
  end

  -- Drone Enums (Phase L) init (nur als sanity check)
  local ok_enums, enums_err = init_drone_enums()
  if not ok_enums then
    r.ShowMessageBox(
      "Fehler beim Laden der DF95 Drone Enums (Phase L):\n\n" ..
      tostring(enums_err),
      "DF95 Phase O – Fehler",
      0
    )
    return
  end

  -- DB vorhanden?
  if not r.file_exists(db_path) then
    r.ShowMessageBox(
      "DB-Datei nicht gefunden:\n" .. db_path .. "\n\n" ..
      "Stelle sicher, dass deine DF95 SampleDB vorhanden ist.",
      "DF95 Phase O – Fehler",
      0
    )
    return
  end

  -- DB laden
  local f, err = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "Kann DB nicht öffnen:\n" .. tostring(err),
      "DF95 Phase O – Fehler",
      0
    )
    return
  end
  local content = f:read("*a")
  f:close()

  local db, dberr = json_decode(content)
  if not db then
    r.ShowMessageBox(
      "JSON Decode-Fehler in DB:\n" .. tostring(dberr),
      "DF95 Phase O – Fehler",
      0
    )
    return
  end

  local items = nil
  if type(db) == "table" and type(db.items) == "table" then
    items = db.items
  elseif type(db) == "table" and #db > 0 then
    items = db
  else
    r.ShowMessageBox(
      "Unbekannte DB-Struktur.\n" ..
      "Erwarte entweder db.items = { ... } oder ein top-level Array.",
      "DF95 Phase O – Fehler",
      0
    )
    return
  end

  local report, rerr = open_report(db_dir)
  if not report then
    r.ShowMessageBox(
      "Kann Report-Datei nicht erstellen:\n" .. tostring(rerr),
      "DF95 Phase O – Fehler",
      0
    )
    return
  end

  local w = report.write

  --------------------------------------------------------
  -- Stats / Counters
  --------------------------------------------------------

  local stats = {
    total_items              = 0,
    drone_items              = 0,

    missing_centerfreq       = 0,
    missing_density          = 0,
    missing_form             = 0,
    missing_motion           = 0,
    missing_tension          = 0,

    invalid_centerfreq       = 0,
    invalid_density          = 0,
    invalid_form             = 0,
    invalid_motion           = 0,
    invalid_tension          = 0,

    motion_strength_miss     = 0,
    motion_strength_mismatch = 0,

    problems_examples        = {},
  }

  local function add_example(idx, it, msg)
    if #stats.problems_examples >= 50 then return end
    local label = it and (it.name or it.file or it.filename or it.id) or ("index " .. tostring(idx))
    table.insert(stats.problems_examples, {
      index = idx,
      label = label,
      msg   = msg,
    })
  end

  --------------------------------------------------------
  -- Header im Report
  --------------------------------------------------------

  w("DF95 Drone System – Phase O Consistency Report (V2)")
  w("Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"))
  w("")
  w("DB: " .. db_path)
  if phaseN_done then
    w("Phase N Marker: FOUND (" .. phaseN_marker .. ")")
  else
    w("Phase N Marker: NOT FOUND (" .. phaseN_marker .. ")")
  end
  w("")
  w("Subsystem Hooks (CFG):")
  w(string.format("  Phase J (QA)      : %s | %s", tostring(CFG.enable_phaseJ), CFG.phaseJ_cmd_str or ""))
  w(string.format("  Dashboard Test    : %s | %s", tostring(CFG.enable_dashboard), CFG.dashboard_cmd_str or ""))
  w(string.format("  Inspector Test    : %s | %s", tostring(CFG.enable_inspector), CFG.inspector_cmd_str or ""))
  w("")
  w("------------------------------------------------------------")
  w("DB / Enum Consistency Checks")
  w("------------------------------------------------------------")
  w("")

  --------------------------------------------------------
  -- DB/Enum Check Loop
  --------------------------------------------------------

  for idx, it in ipairs(items) do
    stats.total_items = stats.total_items + 1

    if is_drone_item(it) then
      stats.drone_items = stats.drone_items + 1

      local cf   = upper(it.df95_drone_centerfreq)
      local dens = upper(it.df95_drone_density)
      local form = upper(it.df95_drone_form)
      local mot  = upper(it.df95_drone_motion)
      local ten  = upper(it.df95_tension)
      local mstr = upper(it.df95_motion_strength)

      local item_has_problem = false

      -- Missing checks
      if cf == ""   then stats.missing_centerfreq = stats.missing_centerfreq + 1; item_has_problem = true end
      if dens == "" then stats.missing_density    = stats.missing_density    + 1; item_has_problem = true end
      if form == "" then stats.missing_form       = stats.missing_form       + 1; item_has_problem = true end
      if mot == ""  then stats.missing_motion     = stats.missing_motion     + 1; item_has_problem = true end
      if ten == ""  then stats.missing_tension    = stats.missing_tension    + 1; item_has_problem = true end

      -- Invalid enum checks (only wenn nicht leer)
      if cf ~= "" and not ALLOWED_CENTERFREQ[cf] then
        stats.invalid_centerfreq = stats.invalid_centerfreq + 1
        item_has_problem = true
      end
      if dens ~= "" and not ALLOWED_DENSITY[dens] then
        stats.invalid_density = stats.invalid_density + 1
        item_has_problem = true
      end
      if form ~= "" and not ALLOWED_FORM[form] then
        stats.invalid_form = stats.invalid_form + 1
        item_has_problem = true
      end
      if mot ~= "" and not ALLOWED_MOTION[mot] then
        stats.invalid_motion = stats.invalid_motion + 1
        item_has_problem = true
      end
      if ten ~= "" and not ALLOWED_TENSION[ten] then
        stats.invalid_tension = stats.invalid_tension + 1
        item_has_problem = true
      end

      -- motion_strength Konsistenz checken
      if mstr == "" then
        stats.motion_strength_miss = stats.motion_strength_miss + 1
        item_has_problem = true
      else
        if mot == "STATIC" and mstr ~= "LOW" then
          stats.motion_strength_mismatch = stats.motion_strength_mismatch + 1
          item_has_problem = true
        end
      end

      if item_has_problem then
        add_example(idx, it, "Drone enums or fields inconsistent")
      end
    end
  end

  --------------------------------------------------------
  -- Write Stats to report
  --------------------------------------------------------

  w("SUMMARY")
  w("-------")
  w(string.format("Total Items: %d", stats.total_items))
  w(string.format("Drone-Items: %d", stats.drone_items))
  w("")
  w("Missing fields (Drone-Items):")
  w(string.format("  centerfreq: %d", stats.missing_centerfreq))
  w(string.format("  density   : %d", stats.missing_density))
  w(string.format("  form      : %d", stats.missing_form))
  w(string.format("  motion    : %d", stats.missing_motion))
  w(string.format("  tension   : %d", stats.missing_tension))
  w("")
  w("Invalid enum values (Drone-Items):")
  w(string.format("  centerfreq: %d", stats.invalid_centerfreq))
  w(string.format("  density   : %d", stats.invalid_density))
  w(string.format("  form      : %d", stats.invalid_form))
  w(string.format("  motion    : %d", stats.invalid_motion))
  w(string.format("  tension   : %d", stats.invalid_tension))
  w("")
  w("Motion-Strength Konsistenz (Drone-Items):")
  w(string.format("  missing : %d", stats.motion_strength_miss))
  w(string.format("  mismatch: %d", stats.motion_strength_mismatch))
  w("")

  if #stats.problems_examples > 0 then
    w("")
    w("Examples (up to 50) of problematic Drone-Items:")
    w("------------------------------------------------")
    for _, ex in ipairs(stats.problems_examples) do
      w(string.format("- idx=%d | label=%s | issue=%s",
        ex.index, tostring(ex.label), tostring(ex.msg)))
    end
  else
    w("")
    w("No problematic Drone-Items found based on the current Phase-O checks.")
  end

  --------------------------------------------------------
  -- Subsystem Hooks (Phase J / Dashboard / Inspector)
  --------------------------------------------------------

  w("")
  w("------------------------------------------------------------")
  w("Subsystem Hooks (Phase J / Dashboard / Inspector)")
  w("------------------------------------------------------------")

  local subsystems = {}

  subsystems.phaseJ = run_named_command_if_enabled(
    CFG.enable_phaseJ,
    CFG.phaseJ_cmd_str,
    "Phase J – Drone QA Validator",
    report
  )

  subsystems.dashboard = run_named_command_if_enabled(
    CFG.enable_dashboard,
    CFG.dashboard_cmd_str,
    "Dashboard / Drilldown Test",
    report
  )

  subsystems.inspector = run_named_command_if_enabled(
    CFG.enable_inspector,
    CFG.inspector_cmd_str,
    "Inspector Test",
    report
  )

  report.close()

  --------------------------------------------------------
  -- Console Summary
  --------------------------------------------------------

  log("Phase O Report written to:")
  log("  " .. tostring(report.path))
  log("")
  log("SUMMARY")
  log(string.format("  Total Items          : %d", stats.total_items))
  log(string.format("  Drone-Items          : %d", stats.drone_items))
  log("")
  log("  Missing fields (Drone-Items):")
  log(string.format("    centerfreq: %d", stats.missing_centerfreq))
  log(string.format("    density   : %d", stats.missing_density))
  log(string.format("    form      : %d", stats.missing_form))
  log(string.format("    motion    : %d", stats.missing_motion))
  log(string.format("    tension   : %d", stats.missing_tension))
  log("")
  log("  Invalid enum values (Drone-Items):")
  log(string.format("    centerfreq: %d", stats.invalid_centerfreq))
  log(string.format("    density   : %d", stats.invalid_density))
  log(string.format("    form      : %d", stats.invalid_form))
  log(string.format("    motion    : %d", stats.invalid_motion))
  log(string.format("    tension   : %d", stats.invalid_tension))
  log("")
  log("  Motion-Strength Konsistenz (Drone-Items):")
  log(string.format("    missing : %d", stats.motion_strength_miss))
  log(string.format("    mismatch: %d", stats.motion_strength_mismatch))
  log("")
  log("Subsystem Hooks:")
  for label, s in pairs({
    ["Phase J (QA)"]   = subsystems.phaseJ,
    ["Dashboard Test"] = subsystems.dashboard,
    ["Inspector Test"] = subsystems.inspector,
  }) do
    if s.enabled == false then
      log(string.format("  %s: SKIPPED (disabled in CFG)", label))
    elseif s.ran then
      log(string.format("  %s: OK (ran %s)", label, s.cmd_str or ""))
    else
      log(string.format("  %s: ERROR (%s)", label, s.error or "unknown"))
    end
  end
  log("")

  --------------------------------------------------------
  -- Severity & MessageBox
  --------------------------------------------------------

  local problem_count =
      stats.missing_centerfreq + stats.missing_density + stats.missing_form +
      stats.missing_motion + stats.missing_tension +
      stats.invalid_centerfreq + stats.invalid_density + stats.invalid_form +
      stats.invalid_motion + stats.invalid_tension +
      stats.motion_strength_miss + stats.motion_strength_mismatch

  local status
  local icon = 0 -- info
  if problem_count == 0 then
    status = "OK"
  elseif problem_count <= 50 then
    status = "WARN"
    icon = 48 -- exclamation
  else
    status = "FAIL"
    icon = 16 -- stop
  end

  local msg =
    "DF95 Drone System – Phase O Consistency Test (V2)\n\n" ..
    "Status: " .. status .. "\n\n" ..
    string.format("Total Items : %d\n", stats.total_items) ..
    string.format("Drone-Items : %d\n\n", stats.drone_items) ..
    string.format("Problems (sum of all counters): %d\n\n", problem_count) ..
    "Report:\n" ..
    tostring(report.path) .. "\n\n" ..
    "Subsystem Hooks (Phase J / Dashboard / Inspector):\n" ..
    string.format("  Phase J (enabled=%s, ran=%s, error=%s)\n",
      tostring(subsystems.phaseJ.enabled),
      tostring(subsystems.phaseJ.ran),
      tostring(subsystems.phaseJ.error)) ..
    string.format("  Dashboard (enabled=%s, ran=%s, error=%s)\n",
      tostring(subsystems.dashboard.enabled),
      tostring(subsystems.dashboard.ran),
      tostring(subsystems.dashboard.error)) ..
    string.format("  Inspector (enabled=%s, ran=%s, error=%s)\n\n",
      tostring(subsystems.inspector.enabled),
      tostring(subsystems.inspector.ran),
      tostring(subsystems.inspector.error)) ..
    "Empfohlene nächsten Schritte:\n" ..
    "1) Report durchsehen\n" ..
    "2) Falls größere Probleme: Phase N Backup prüfen / gezielt korrigieren\n" ..
    "3) Drone QA Validator (Phase J) ggf. separat mit UI prüfen\n" ..
    "4) Dashboard/Inspector Drilldown auf auffällige Kombinationen testen\n"

  r.ShowMessageBox(msg, "DF95 Phase O – Consistency Result (V2)", icon)
end

------------------------------------------------------------
-- Run
------------------------------------------------------------

run_phaseO()
