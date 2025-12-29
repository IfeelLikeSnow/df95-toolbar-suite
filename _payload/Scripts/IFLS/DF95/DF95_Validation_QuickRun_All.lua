-- @description DF95 Validation – QuickRun All Validators
-- @version 1.0
-- @author DF95 (auto-generated helper)
-- @about
--   Führt die wichtigsten DF95-Validatoren in Folge aus:
--     * PostInstall_Validator
--     * PostInstall_Validator2 (Report: DF95_Validation_Report.txt)
--     * SampleDB_Validator_V3 (Report im DF95_SampleDB-Unterordner)
--     * Validator_Pro (Report: DF95_ValidatorPro_Report.txt)
--   und zeigt am Ende eine zusammenfassende OK/FAIL-Übersicht an.
--
--   Hinweis:
--     Die einzelnen Validatoren können eigene MessageBoxen anzeigen.
--     Dieses Script fasst zusätzlich zusammen, ob:
--       * alle Validator-Skripte gefunden wurden
--       * alle Validatoren ohne Lua-Fehler liefen
--       * die bekannten Reports MISS-/WARN-Einträge enthalten.

local r   = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

local function read_all(p)
  local f = io.open(p, "rb")
  if not f then return nil end
  local d = f:read("*all")
  f:close()
  return d
end

local results = {}

local function add_result(label, status, detail)
  results[#results+1] = {
    label  = label,
    status = status,
    detail = detail or "",
  }
end

local function run_dofile(label, relpath)
  local base = join_path(res, "Scripts")
  base = join_path(base, "IfeelLikeSnow")
  base = join_path(base, "DF95")
  local full = join_path(base, relpath)

  if not file_exists(full) then
    add_result(label, "MISS", "Script nicht gefunden: " .. full)
    return
  end

  local ok, err = pcall(dofile, full)
  if not ok then
    add_result(label, "FAIL", "Lua-Fehler: " .. tostring(err))
  else
    add_result(label, "OK", "")
  end
end

---------------------------------------------
-- 1) PostInstall_Validator
---------------------------------------------
run_dofile("PostInstall_Validator", "DF95_PostInstall_Validator.lua")

---------------------------------------------
-- 2) PostInstall_Validator2 + DF95_Validation_Report.txt auswerten
---------------------------------------------
run_dofile("PostInstall_Validator2", "DF95_PostInstall_Validator2.lua")

do
  local report_path = join_path(res, "DF95_Validation_Report.txt")
  local txt = read_all(report_path)
  if txt then
    local has_miss = txt:find("%[MISS%]") ~= nil
    local has_warn = txt:find("%[WARN%]") ~= nil

    if has_miss then
      add_result("PostInstall_Validator2-Report", "FAIL", "Report enthält [MISS].")
    elseif has_warn then
      add_result("PostInstall_Validator2-Report", "WARN", "Report enthält [WARN].")
    else
      add_result("PostInstall_Validator2-Report", "OK", "Report ohne MISS/WARN.")
    end
  else
    add_result("PostInstall_Validator2-Report", "MISS", "DF95_Validation_Report.txt nicht gefunden.")
  end
end

---------------------------------------------
-- 3) SampleDB_Validator_V3 (Multi-UCS)
---------------------------------------------
run_dofile("SampleDB_Validator_V3", "DF95_SampleDB_Validator_V3.lua")

do
  local support = join_path(res, "Support")
  support = join_path(support, "DF95_SampleDB")
  local report_path = join_path(support, "DF95_SampleDB_Validator_V3_Report.txt")
  local txt = read_all(report_path)
  if txt then
    -- Simple Heuristik: wenn "WARN" oder "ERROR" im Report vorkommt -> WARN
    local has_error = txt:lower():find("error", 1, true) ~= nil
    local has_warn  = txt:lower():find("warn",  1, true) ~= nil
    if has_error then
      add_result("SampleDB_Validator_V3-Report", "FAIL", "Report enthält ERROR.")
    elseif has_warn then
      add_result("SampleDB_Validator_V3-Report", "WARN", "Report enthält WARN.")
    else
      add_result("SampleDB_Validator_V3-Report", "OK", "Report ohne WARN/ERROR.")
    end
  else
    add_result("SampleDB_Validator_V3-Report", "MISS", "SampleDB_Validator_V3_Report.txt nicht gefunden.")
  end
end

---------------------------------------------
-- 4) Validator Pro
---------------------------------------------
run_dofile("Validator_Pro", "DF95_Validator_Pro.lua")

do
  local data_dir = join_path(res, "Data")
  data_dir = join_path(data_dir, "DF95")
  local report_path = join_path(data_dir, "DF95_ValidatorPro_Report.txt")
  local txt = read_all(report_path)
  if txt then
    local has_error = txt:lower():find("error", 1, true) ~= nil
    local has_missing = txt:lower():find("missing", 1, true) ~= nil
    if has_error or has_missing then
      add_result("Validator_Pro-Report", "FAIL", "Report enthält ERROR/MISSING.")
    else
      add_result("Validator_Pro-Report", "OK", "Report ohne ERROR/MISSING.")
    end
  else
    add_result("Validator_Pro-Report", "MISS", "DF95_ValidatorPro_Report.txt nicht gefunden.")
  end
end

---------------------------------------------
-- Zusammenfassung anzeigen
---------------------------------------------
local any_fail = false
local any_warn = false
local lines = {}

for _, rsl in ipairs(results) do
  local tag = rsl.status
  if tag == "FAIL" or tag == "MISS" then
    any_fail = true
  elseif tag == "WARN" then
    any_warn = true
  end
  local line = string.format("[%s] %s", tag, rsl.label)
  if rsl.detail ~= "" then
    line = line .. " – " .. rsl.detail
  end
  table.insert(lines, line)
end

local title = "DF95 Validation – Gesamtstatus"
local head

if any_fail then
  head = "GESAMT: FEHLER / PROBLEME gefunden."
elseif any_warn then
  head = "GESAMT: OK mit WARNUNGEN."
else
  head = "GESAMT: OK. Keine Probleme in den Reports gefunden."
end

local msg = head .. "\n\n" .. table.concat(lines, "\n")
r.ShowMessageBox(msg, title, 0)
