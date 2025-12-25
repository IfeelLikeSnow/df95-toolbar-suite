\
-- DF95_SampleDB_Drone_Migrate_PhaseN.lua
-- Phase N – Drone SampleDB Migration to Phase-L enums
--
-- Zweck:
--   Einmalige Normalisierung aller Drone-bezogenen Felder in der DF95 SampleDB
--   auf die harmonisierten Phase-L-Enums.
--
--   Betroffene Felder:
--     df95_drone_centerfreq   → LOW, MID, HIGH
--     df95_drone_density      → LOW, MED, HIGH
--     df95_drone_form         → PAD, TEXTURE, SWELL, MOVEMENT, GROWL
--     df95_drone_motion       → STATIC, MOVEMENT, PULSE, SWELL
--     df95_motion_strength    → synchron zu df95_drone_motion
--     df95_tension            → LOW, MED, HIGH, EXTREME
--
--   Ein Item gilt als Drone, wenn (case-insensitive):
--     role == "DRONE"
--       oder df95_drone_flag nicht leer
--       oder df95_catid den String "DRONE" enthält
--
--   Die eigentliche Normalisierung übernimmt Phase L:
--     DF95_Drone_Enums_PhaseL.lua
--     → DroneEnums.normalize_item_drone_fields(it)
--
--   Ziel-DB:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Vor jeder Änderung:
--     DF95_SampleDB_Multi_UCS_backup_<YYYYMMDD_HHMMSS>.json
--
--   Am Ende:
--     Konsolen-Report + „Phase N Bier“-Hinweis in einem MessageBox-Dialog. 🍺
--
-- Hinweis:
--   Dieses Script ist bewusst defensiv geschrieben und geht davon aus,
--   dass eine JSON-Library (json oder dkjson) vorhanden ist und dass
--   DF95_Drone_Enums_PhaseL.lua im DF95-Script-Pfad liegt.
--
--   Falls deine JSON-Utility im DF95-Ökosystem anders heißt, kannst du
--   die load_json/save_json Funktionen unten leicht anpassen.

local r = reaper

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
  -- REAPER legt den Support-Ordner üblicherweise an,
  -- aber wir sichern hier trotzdem ab.
  return true
end

local function copy_file(src, dst)
  local in_f = io.open(src, "rb")
  if not in_f then return false, "Cannot open source for backup: " .. tostring(src) end
  local data = in_f:read("*a")
  in_f:close()

  local out_f, err = io.open(dst, "wb")
  if not out_f then
    return false, "Cannot create backup file: " .. tostring(dst) .. " (" .. tostring(err) .. ")"
  end
  out_f:write(data)
  out_f:close()
  return true
end

------------------------------------------------------------
-- JSON Helper (generic, anpassbar an deine Umgebung)
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

  -- Wenn du eine eigene DF95-JSON-Utility hast, kannst du sie hier einhängen, z. B.:
  -- ok, m = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/DF95/DF95_JSON.lua")
  -- if ok and m then
  --   json = m
  --   return true
  -- end

  return false
end

local function json_decode(str)
  if not json then return nil, "JSON library not initialized" end

  -- Versuch, eine einfache decode API zu verwenden
  if type(json.decode) == "function" then
    local ok, res, pos, err = pcall(json.decode, str)
    if ok and res and not err then
      return res
    elseif ok and res and type(res) == "table" then
      -- dkjson-Style: res, pos, err
      return res
    else
      return nil, err or "JSON decode error"
    end
  end

  return nil, "Unsupported JSON implementation"
end

local function json_encode(tbl)
  if not json then return nil, "JSON library not initialized" end

  if type(json.encode) == "function" then
    local ok, res = pcall(json.encode, tbl, { indent = true })
    if ok and res then return res end
  end

  return nil, "JSON encode error or unsupported JSON implementation"
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
  if type(DroneEnums.normalize_item_drone_fields) ~= "function" then
    return false, "DF95_Drone_Enums_PhaseL.lua does not provide normalize_item_drone_fields(it)"
  end
  return true
end

------------------------------------------------------------
-- SampleDB Load / Save
------------------------------------------------------------

local function load_db(db_path)
  local f, err = io.open(db_path, "r")
  if not f then
    return nil, "Cannot open DB file: " .. tostring(db_path) .. " (" .. tostring(err) .. ")"
  end
  local content = f:read("*a")
  f:close()

  local data, jerr = json_decode(content)
  if not data then
    return nil, "JSON decode error in DB file: " .. tostring(jerr)
  end
  return data
end

local function save_db(db_path, db_data)
  local encoded, err = json_encode(db_data)
  if not encoded then
    return false, "JSON encode error: " .. tostring(err)
  end

  local f, ferr = io.open(db_path, "w")
  if not f then
    return false, "Cannot write DB file: " .. tostring(db_path) .. " (" .. tostring(ferr) .. ")"
  end

  f:write(encoded)
  f:close()
  return true
end

------------------------------------------------------------
-- Drone Detection
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
-- Marker File (optional: dokumentiert, dass Phase N lief)
------------------------------------------------------------

local function write_phaseN_marker(db_dir, backup_name, stats)
  local marker_path = db_dir .. "/DF95_Drone_PhaseN_COMPLETE.txt"
  local f = io.open(marker_path, "w")
  if not f then return end

  f:write("DF95 Drone Phase N Migration\n")
  f:write("Timestamp: " .. (os.date("%Y-%m-%d %H:%M:%S")) .. "\n")
  f:write("Backup: " .. (backup_name or "") .. "\n\n")

  if stats then
    f:write("Total Items: " .. (stats.total_items or 0) .. "\n")
    f:write("Drone-Items: " .. (stats.drone_items or 0) .. "\n")
    f:write("Drone-Items mit Änderungen: " .. (stats.changed_any or 0) .. "\n\n")

    f:write("Feldweise Änderungen (Drone-Items):\n")
    f:write("  centerfreq: " .. (stats.changed_centerfreq or 0) .. "\n")
    f:write("  density   : " .. (stats.changed_density or 0) .. "\n")
    f:write("  form      : " .. (stats.changed_form or 0) .. "\n")
    f:write("  motion    : " .. (stats.changed_motion or 0) .. "\n")
    f:write("  tension   : " .. (stats.changed_tension or 0) .. "\n")
  end

  f:close()
end

------------------------------------------------------------
-- Phase N Migration
------------------------------------------------------------

local function run_phaseN()
  r.ClearConsole()

  log("DF95 Drone SampleDB Phase N Migration")
  log("-------------------------------------")
  log("")

  -- Confirm Dialog
  local ret = r.ShowMessageBox(
    "DF95 – Drone SampleDB Phase N Migration\n\n" ..
    "Dieses Script wird deine Drone-Felder in\n" ..
    "DF95_SampleDB_Multi_UCS.json auf die neuen Phase-L-Enums migrieren.\n\n" ..
    "- Es wird automatisch ein Backup erstellt.\n" ..
    "- Die Migration ist technisch als *einmalig* gedacht.\n\n" ..
    "Fortfahren?",
    "DF95 Phase N – Bist du sicher?",
    4 -- Yes / No
  )
  if ret ~= 6 then -- 6 = IDYES
    log("Abgebrochen durch Benutzer.")
    return
  end

  -- Init JSON
  if not init_json() then
    r.ShowMessageBox(
      "Konnte keine JSON-Library laden (json oder dkjson).\n" ..
      "Bitte passe das Script an deine DF95-JSON-Utility an.",
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  -- Init Drone Enums (Phase L)
  local ok_enums, enums_err = init_drone_enums()
  if not ok_enums then
    r.ShowMessageBox(
      "Fehler beim Laden der DF95 Drone Enums (Phase L):\n\n" ..
      tostring(enums_err),
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  local db_dir, db_path = get_db_paths()
  ensure_dir(db_dir)

  if not r.file_exists(db_path) then
    r.ShowMessageBox(
      "DB-Datei nicht gefunden:\n" .. db_path .. "\n\n" ..
      "Stelle sicher, dass deine DF95 SampleDB vorhanden ist.",
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  log("DB: " .. db_path)

  -- Backup
  local ts = os.date("%Y%m%d_%H%M%S")
  local backup_name = "DF95_SampleDB_Multi_UCS_backup_" .. ts .. ".json"
  local backup_path = db_dir .. "/" .. backup_name

  local ok_backup, backup_err = copy_file(db_path, backup_path)
  if not ok_backup then
    r.ShowMessageBox(
      "Backup fehlgeschlagen:\n" .. tostring(backup_err),
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  log("Backup: " .. backup_path)
  log("")

  -- Load DB
  local db, dberr = load_db(db_path)
  if not db then
    r.ShowMessageBox(
      "Fehler beim Laden der DB:\n" .. tostring(dberr),
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  -- Finde Items-Array
  local items = nil
  if type(db) == "table" and type(db.items) == "table" then
    items = db.items
  elseif type(db) == "table" and #db > 0 then
    items = db
  else
    r.ShowMessageBox(
      "Unbekannte DB-Struktur.\n" ..
      "Erwarte entweder db.items = { ... } oder ein top-level Array.",
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  local stats = {
    total_items        = 0,
    drone_items        = 0,
    changed_any        = 0,
    changed_centerfreq = 0,
    changed_density    = 0,
    changed_form       = 0,
    changed_motion     = 0,
    changed_tension    = 0,
  }

  -- Migration
  for idx, it in ipairs(items) do
    stats.total_items = stats.total_items + 1

    if is_drone_item(it) then
      stats.drone_items = stats.drone_items + 1

      local before_cf   = it.df95_drone_centerfreq
      local before_dens = it.df95_drone_density
      local before_form = it.df95_drone_form
      local before_mot  = it.df95_drone_motion
      local before_ten  = it.df95_tension

      -- Normalize via Phase L
      local ok_norm, norm_err = pcall(DroneEnums.normalize_item_drone_fields, it)
      if not ok_norm then
        log(string.format("WARN: normalize_item_drone_fields failed for item #%d: %s", idx, tostring(norm_err)))
      end

      local after_cf   = it.df95_drone_centerfreq
      local after_dens = it.df95_drone_density
      local after_form = it.df95_drone_form
      local after_mot  = it.df95_drone_motion
      local after_ten  = it.df95_tension

      local changed = false

      if before_cf ~= after_cf then
        stats.changed_centerfreq = stats.changed_centerfreq + 1
        changed = true
      end
      if before_dens ~= after_dens then
        stats.changed_density = stats.changed_density + 1
        changed = true
      end
      if before_form ~= after_form then
        stats.changed_form = stats.changed_form + 1
        changed = true
      end
      if before_mot ~= after_mot then
        stats.changed_motion = stats.changed_motion + 1
        changed = true
      end
      if before_ten ~= after_ten then
        stats.changed_tension = stats.changed_tension + 1
        changed = true
      end

      if changed then
        stats.changed_any = stats.changed_any + 1
      end
    end
  end

  -- Save DB
  local ok_save, save_err = save_db(db_path, db)
  if not ok_save then
    r.ShowMessageBox(
      "Fehler beim Schreiben der migrierten DB:\n" .. tostring(save_err) .. "\n\n" ..
      "Dein Backup liegt hier:\n" .. backup_path,
      "DF95 Phase N – Fehler",
      0
    )
    return
  end

  -- Console Report
  log("Migration erfolgreich abgeschlossen.")
  log("")
  log(string.format("Total Items: %d", stats.total_items))
  log(string.format("Drone-Items: %d", stats.drone_items))
  log(string.format("Drone-Items mit Änderungen: %d", stats.changed_any))
  log("")
  log("Feldweise Änderungen (bei Drone-Items):")
  log(string.format("  centerfreq: %d", stats.changed_centerfreq))
  log(string.format("  density   : %d", stats.changed_density))
  log(string.format("  form      : %d", stats.changed_form))
  log(string.format("  motion    : %d", stats.changed_motion))
  log(string.format("  tension   : %d", stats.changed_tension))
  log("")
  log("Backup: " .. backup_path)
  log("")

  -- Marker File
  write_phaseN_marker(db_dir, backup_name, stats)

  -- ASCII-Bier in der Konsole (optional, einfach spaßig)
  log("   ____  _                 _   _   _      ")
  log("  |  _ \\| | ___   ___ __ _| |_| \\ | | ___ ")
  log("  | |_) | |/ _ \\ / __/ _` | __|  \\| |/ _ \\")
  log("  |  __/| | (_) | (_| (_| | |_| |\\  |  __/")
  log("  |_|   |_|\\___/ \\___\\__,_|\\__|_| \\_|\\___|")
  log("")
  log("  Phase N Migration done – Bier-Zeit! 🍺")
  log("")

  -- Abschluss-Dialog mit „Phase N Bier“ Hinweis
  local msg =
    "DF95 Drone SampleDB – Phase N Migration\n\n" ..
    "Migration erfolgreich abgeschlossen.\n\n" ..
    "Nächste Schritte:\n" ..
    "1) Drone QA Validator (Phase J) laufen lassen\n" ..
    "2) Dashboard & Inspector Drilldown testen (Phase K)\n" ..
    "3) Git-Commit + Tag setzen\n" ..
    "4) -> Offiziell: Phase-N-Bier öffnen 🍺\n\n" ..
    "Backup:\n" .. backup_path .. "\n\n" ..
    "Danke, dass du deine Library so sorgfältig pflegst."

  r.ShowMessageBox(msg, "DF95 Phase N – Done 🎉", 0)
end

------------------------------------------------------------
-- Run
------------------------------------------------------------

run_phaseN()
