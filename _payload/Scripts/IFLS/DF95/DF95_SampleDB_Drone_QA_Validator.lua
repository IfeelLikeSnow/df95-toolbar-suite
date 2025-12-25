
-- @description DF95 SampleDB Drone QA Validator (Phase J)
-- @version 1.0
-- @author DF95
-- @about
--   Prüft die DF95 SampleDB auf typische Drone-bezogene Inkonsistenzen:
--     * role == "Drone" aber df95_drone_flag fehlt
--     * df95_drone_flag gesetzt aber df95_catid fehlt
--     * df95_catid beginnt mit "DRONE_" aber role ~= "Drone"
--     * Drone-Items ohne Audioanalyse-Features (centerfreq/density/form/motion/tension)
--     * zu kurze Drone-Items
--
--   Schreibt einen CSV-Report nach:
--     <REAPER>/Support/DF95_SampleDB/DF95_Drone_QA_Report.csv
--
--   Diese Version ist read-only: es werden keine DB-Einträge verändert.

local r = reaper

local function join_path(a,b)
  if not a or a == "" then return b end
  local sep = package.config:sub(1,1)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_support_dir()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return dir
end

local function get_db_path()
  local dir = get_support_dir()
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function safe_str(v)
  if v == nil then return "" end
  return tostring(v)
end

local function upper(v)
  return safe_str(v):upper()
end

local function is_nonempty(v)
  return v ~= nil and tostring(v) ~= ""
end

local function load_json_file(path)
  local f = io.open(path, "r")
  if not f then return nil, "Kann Datei nicht öffnen: " .. tostring(path) end
  local txt = f:read("*a")
  f:close()
  if not txt or txt == "" then
    return nil, "Datei ist leer: " .. tostring(path)
  end
  if not r.Json_Decode then
    return nil, "Reaper Json_Decode API nicht verfügbar."
  end
  local ok, obj = pcall(function() return r.Json_Decode(txt) end)
  if not ok or not obj then
    return nil, "JSON-Decode fehlgeschlagen für: " .. tostring(path)
  end
  return obj
end

local function ensure_dir(path)
  return r.RecursiveCreateDirectory(path, 0)
end

local function open_report_file()
  local dir = get_support_dir()
  ensure_dir(dir)
  local path = join_path(dir, "DF95_Drone_QA_Report.csv")
  local f, err = io.open(path, "w")
  if not f then
    return nil, "Fehler beim Öffnen des QA-Reports: " .. tostring(err or path)
  end
  -- CSV-Header
  f:write("issue_type,item_id,path,role,df95_drone_flag,df95_catid,centerfreq,density,form,motion,tension,length_sec,details\n")
  return f, path
end

local function add_issue(issues, issue_type, it, details)
  issues[#issues+1] = {
    type    = issue_type,
    id      = safe_str(it.id or it.item_id or ""),
    path    = safe_str(it.path or it.filepath or ""),
    role    = safe_str(it.role),
    flag    = safe_str(it.df95_drone_flag),
    catid   = safe_str(it.df95_catid),
    cf      = safe_str(it.df95_drone_centerfreq),
    dens    = safe_str(it.df95_drone_density),
    form    = safe_str(it.df95_drone_form),
    motion  = safe_str(it.df95_motion_strength or it.df95_drone_motion),
    tension = safe_str(it.df95_tension),
    len     = tonumber(it.length_sec or it.length or 0) or 0,
    details = safe_str(details),
  }
end

local function run_validator()
  r.ClearConsole()
  r.ShowConsoleMsg("DF95 SampleDB Drone QA Validator (Phase J)\\n")
  r.ShowConsoleMsg("------------------------------------------------------------\\n")

  local db_path = get_db_path()
  r.ShowConsoleMsg("DB: " .. tostring(db_path) .. "\\n")

  local db, err = load_json_file(db_path)
  if not db then
    r.ShowConsoleMsg("FEHLER: " .. tostring(err) .. "\\n")
    return
  end

  local items = db.items
  if type(items) ~= "table" then
    r.ShowConsoleMsg("FEHLER: db.items fehlt oder ist kein Array.\\n")
    return
  end

  local issues = {}
  local total_items   = 0
  local drone_items   = 0
  local too_short_len = 3.0 -- Sekunden

  for _, it in ipairs(items) do
    total_items = total_items + 1
    local len = tonumber(it.length_sec or it.length or 0) or 0

    local role   = upper(it.role)
    local flag   = upper(it.df95_drone_flag)
    local catid  = upper(it.df95_catid)
    local is_drone = false

    if role == "DRONE" then is_drone = true end
    if flag ~= "" then is_drone = true end
    if catid:find("DRONE", 1, true) then is_drone = true end

    if is_drone then
      drone_items = drone_items + 1

      -- 1) role == Drone aber df95_drone_flag leer
      if role == "DRONE" and not is_nonempty(it.df95_drone_flag) then
        add_issue(issues, "MISSING_DRONE_FLAG", it, "role=DRONE aber df95_drone_flag leer")
      end

      -- 2) df95_drone_flag gesetzt aber df95_catid leer
      if is_nonempty(it.df95_drone_flag) and not is_nonempty(it.df95_catid) then
        add_issue(issues, "MISSING_DRONE_CATID", it, "df95_drone_flag gesetzt aber df95_catid leer")
      end

      -- 3) df95_catid beginnt mit DRONE_ aber role ~= Drone
      if catid:match("^DRONE_") and role ~= "DRONE" then
        add_issue(issues, "INCONSISTENT_ROLE_CATID", it,
          "df95_catid beginnt mit DRONE_, aber role ist nicht 'Drone' (role=" .. safe_str(it.role) .. ")")
      end

      -- 4) fehlende Audio-Features
      local cf   = safe_str(it.df95_drone_centerfreq)
      local dens = safe_str(it.df95_drone_density)
      local form = safe_str(it.df95_drone_form)
      local mot  = safe_str(it.df95_motion_strength or it.df95_drone_motion)
      local ten  = safe_str(it.df95_tension)

      if cf == "" and dens == "" and form == "" and mot == "" and ten == "" then
        add_issue(issues, "MISSING_AUDIO_FEATURES", it,
          "Drone-Item ohne Audioanalysis-Felder (centerfreq/density/form/motion/tension)")
      end

      -- 5) zu kurze Drones
      if len > 0 and len < too_short_len then
        add_issue(issues, "TOO_SHORT_DRONE", it,
          string.format("Drone-Item ist sehr kurz (%.3f s, Schwelle=%.3f s)", len, too_short_len))
      end
    end
  end

  local f, report_path = open_report_file()
  if not f then
    r.ShowConsoleMsg("FEHLER: Konnte QA-Report nicht schreiben.\\n")
    return
  end

  for _, iss in ipairs(issues) do
    local row = {
      iss.type,
      iss.id,
      iss.path,
      iss.role,
      iss.flag,
      iss.catid,
      iss.cf,
      iss.dens,
      iss.form,
      iss.motion,
      iss.tension,
      string.format("%.3f", iss.len or 0.0),
      iss.details,
    }
    for i,v in ipairs(row) do
      local s = safe_str(v)
      if s:find("[,\"\n]") then
        s = '"' .. s:gsub('"','""') .. '"'
      end
      row[i] = s
    end
    f:write(table.concat(row, ",") .. "\\n")
  end

  f:close()

  r.ShowConsoleMsg(string.format("Total Items: %d\\n", total_items))
  r.ShowConsoleMsg(string.format("Drone-Items: %d\\n", drone_items))
  r.ShowConsoleMsg(string.format("Gefundene Issues: %d\\n", #issues))
  r.ShowConsoleMsg("Report: " .. tostring(report_path) .. "\\n")
  r.ShowConsoleMsg("Fertig.\\n")
end

run_validator()
