-- @description DF95 SampleDB Validator V3 (Multi-UCS)
-- @version 1.0
-- @author DF95
-- @about
--   Prüft die DF95 Multi-UCS SampleDB (DF95_SampleDB_Multi_UCS.json) auf:
--     * fehlende Pflichtfelder (filepath, name, Zonen, UCS/CatID, Session-Felder)
--     * AI-Felder (df95_ai_confidence, ai_status, df95_ai_review_flag)
--     * leere/inkonsistente Werte
--   Gibt eine Kurz-Zusammenfassung als MessageBox und optional einen Text-Report aus.

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function get_default_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function get_default_report_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Validator_V3_Report.txt")
end

local function trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function is_nonempty(v)
  return v ~= nil and v ~= ""
end

------------------------------------------------------------
-- JSON Helper (kompatibel zu AutoIngest V3)
------------------------------------------------------------

local function decode_json(text)
  if type(text) ~= "string" then return nil, "no text" end

  local lua_text = text
  lua_text = lua_text:gsub('"(.-)"%s*:', '["%1"] =')
  lua_text = lua_text:gsub("%[", "{")
  lua_text = lua_text:gsub("%]", "}")
  lua_text = lua_text:gsub("null", "nil")
  lua_text = "return " .. lua_text

  local f, err = load(lua_text)
  if not f then return nil, err end
  local ok, res = pcall(f)
  if not ok then return nil, res end
  return res
end

------------------------------------------------------------
-- Validation
------------------------------------------------------------

local function main()
  local db_path = get_default_db_path()
  local default_flags = "1" -- 1 = Textreport zusätzlich erzeugen

  local ok, csv = r.GetUserInputs(
    "DF95 SampleDB Validator V3",
    2,
    "DB-Pfad (leer=Default),Text-Report erzeugen? (0/1)",
    db_path .. "," .. default_flags
  )
  if not ok then return end

  local path_str, report_flag_str = csv:match("([^,]*),([^,]*)")
  path_str = trim(path_str)
  report_flag_str = trim(report_flag_str)

  if path_str == "" then
    path_str = db_path
  end

  local make_report = tonumber(report_flag_str) == 1

  local f, err = io.open(path_str, "r")
  if not f then
    r.ShowMessageBox("DB nicht gefunden:\n" .. tostring(path_str) .. "\n\n" .. tostring(err or ""), "DF95 SampleDB Validator V3", 0)
    return
  end
  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    r.ShowMessageBox("Fehler beim Lesen/Dekodieren der DB:\n" .. tostring(derr or "unbekannt"), "DF95 SampleDB Validator V3", 0)
    return
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    r.ShowMessageBox("DB enthält keine Items oder unbekanntes Format.", "DF95 SampleDB Validator V3", 0)
    return
  end

  local total = #items

  local stats = {
    missing_filepath = 0,
    missing_name = 0,

    missing_home_zone = 0,
    missing_home_sub = 0,

    missing_ucs = 0,
    missing_catid = 0,

    missing_session_loc = 0,
    missing_session_sub = 0,
    missing_session_scene = 0,

    missing_ai_conf = 0,
    invalid_ai_conf = 0,
    missing_ai_status = 0,
    missing_ai_flag = 0,

    empty_items = 0,
  }

  local lines = {}
  local function add_line(s)
    lines[#lines+1] = s
  end

  add_line("DF95 SampleDB Validator V3")
  add_line(string.rep("=", 72))
  add_line("DB       : " .. tostring(path_str))
  add_line("Items    : " .. tostring(total))
  add_line("Datum    : " .. os.date("%Y-%m-%d %H:%M:%S"))
  add_line("")

  local function safe_str(v)
    if v == nil then return "(nil)" end
    local s = tostring(v)
    s = s:gsub("\t", " ")
    s = s:gsub("\r", " "):gsub("\n", " ")
    return s
  end

  for idx, it in ipairs(items) do
    local filepath = it.filepath
    local name = it.name

    local home_zone = it.home_zone
    local home_sub  = it.home_zone_sub

    local ucs = it.ucs_category
    local catid = it.df95_catid

    local sess_loc   = it.session_location
    local sess_sub   = it.session_subzone
    local sess_scene = it.session_scene

    local ai_conf = it.df95_ai_confidence
    local ai_status = it.ai_status
    local ai_flag   = it.df95_ai_review_flag

    local any_data = false
    for k,v in pairs(it) do
      if v ~= nil and v ~= "" then
        any_data = true
        break
      end
    end
    if not any_data then
      stats.empty_items = stats.empty_items + 1
    end

    if not is_nonempty(filepath) then
      stats.missing_filepath = stats.missing_filepath + 1
      add_line(string.format("Item %d: fehlender filepath (name=%s)", idx, safe_str(name)))
    end
    if not is_nonempty(name) then
      stats.missing_name = stats.missing_name + 1
      add_line(string.format("Item %d: fehlender name (filepath=%s)", idx, safe_str(filepath)))
    end

    if not is_nonempty(home_zone) then
      stats.missing_home_zone = stats.missing_home_zone + 1
    end
    if not is_nonempty(home_sub) then
      stats.missing_home_sub = stats.missing_home_sub + 1
    end

    if not is_nonempty(ucs) then
      stats.missing_ucs = stats.missing_ucs + 1
    end
    if not is_nonempty(catid) then
      stats.missing_catid = stats.missing_catid + 1
    end

    if not is_nonempty(sess_loc) then
      stats.missing_session_loc = stats.missing_session_loc + 1
    end
    if not is_nonempty(sess_sub) then
      stats.missing_session_sub = stats.missing_session_sub + 1
    end
    if not is_nonempty(sess_scene) then
      stats.missing_session_scene = stats.missing_session_scene + 1
    end

    if ai_conf == nil then
      stats.missing_ai_conf = stats.missing_ai_conf + 1
    else
      local c = tonumber(ai_conf)
      if not c or c < 0.0 or c > 1.0 then
        stats.invalid_ai_conf = stats.invalid_ai_conf + 1
        add_line(string.format("Item %d: ungültige df95_ai_confidence=%s (filepath=%s)", idx, safe_str(ai_conf), safe_str(filepath)))
      end
    end

    if not is_nonempty(ai_status) then
      stats.missing_ai_status = stats.missing_ai_status + 1
    end
    if ai_flag == nil then
      stats.missing_ai_flag = stats.missing_ai_flag + 1
    end
  end

  add_line("")
  add_line(string.rep("-", 72))
  add_line("Zusammenfassung (Zähler):")
  add_line(string.format("  fehlender filepath         : %d", stats.missing_filepath))
  add_line(string.format("  fehlender name             : %d", stats.missing_name))
  add_line(string.format("  fehlende home_zone         : %d", stats.missing_home_zone))
  add_line(string.format("  fehlende home_zone_sub     : %d", stats.missing_home_sub))
  add_line(string.format("  fehlende ucs_category      : %d", stats.missing_ucs))
  add_line(string.format("  fehlende df95_catid        : %d", stats.missing_catid))
  add_line(string.format("  fehlende session_location  : %d", stats.missing_session_loc))
  add_line(string.format("  fehlende session_subzone   : %d", stats.missing_session_sub))
  add_line(string.format("  fehlende session_scene     : %d", stats.missing_session_scene))
  add_line(string.format("  df95_ai_confidence fehlt   : %d", stats.missing_ai_conf))
  add_line(string.format("  df95_ai_confidence ungültig: %d", stats.invalid_ai_conf))
  add_line(string.format("  ai_status fehlt/leer       : %d", stats.missing_ai_status))
  add_line(string.format("  df95_ai_review_flag fehlt  : %d", stats.missing_ai_flag))
  add_line(string.format("  komplett leere Items       : %d", stats.empty_items))

  local msg = {}
  msg[#msg+1] = "DF95 SampleDB Validator V3 abgeschlossen."
  msg[#msg+1] = "DB: " .. tostring(path_str)
  msg[#msg+1] = string.format("Items gesamt: %d", total)
  msg[#msg+1] = ""
  msg[#msg+1] = string.format("fehlender filepath         : %d", stats.missing_filepath)
  msg[#msg+1] = string.format("fehlender name             : %d", stats.missing_name)
  msg[#msg+1] = string.format("fehlende home_zone         : %d", stats.missing_home_zone)
  msg[#msg+1] = string.format("fehlende home_zone_sub     : %d", stats.missing_home_sub)
  msg[#msg+1] = string.format("fehlende ucs_category      : %d", stats.missing_ucs)
  msg[#msg+1] = string.format("fehlende df95_catid        : %d", stats.missing_catid)
  msg[#msg+1] = string.format("fehlende session_location  : %d", stats.missing_session_loc)
  msg[#msg+1] = string.format("fehlende session_subzone   : %d", stats.missing_session_sub)
  msg[#msg+1] = string.format("fehlende session_scene     : %d", stats.missing_session_scene)
  msg[#msg+1] = string.format("df95_ai_confidence fehlt   : %d", stats.missing_ai_conf)
  msg[#msg+1] = string.format("df95_ai_confidence ungültig: %d", stats.invalid_ai_conf)
  msg[#msg+1] = string.format("ai_status fehlt/leer       : %d", stats.missing_ai_status)
  msg[#msg+1] = string.format("df95_ai_review_flag fehlt  : %d", stats.missing_ai_flag)
  msg[#msg+1] = string.format("komplett leere Items       : %d", stats.empty_items)

  if make_report then
    local report_path = get_default_report_path()
    local rf, rerr = io.open(report_path, "w")
    if rf then
      for _, line in ipairs(lines) do
        rf:write(line)
        rf:write("\n")
      end
      rf:close()
      msg[#msg+1] = ""
      msg[#msg+1] = "Text-Report geschrieben nach:"
      msg[#msg+1] = report_path
    else
      msg[#msg+1] = ""
      msg[#msg+1] = "Konnte Text-Report nicht schreiben: " .. tostring(rerr or "")
    end
  end

  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 SampleDB Validator V3", 0)
end

main()
