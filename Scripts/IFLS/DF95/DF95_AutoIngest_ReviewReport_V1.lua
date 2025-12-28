-- @description DF95 AutoIngest Review Report V1
-- @version 1.0
-- @author DF95
-- @about
--   Erzeugt einen Text-Report aus der DF95 Multi-UCS SampleDB (DF95_SampleDB_Multi_UCS.json)
--   mit Fokus auf:
--     * df95_ai_review_flag (OK_HIGH / REVIEW_MED / REVIEW_LOW / REVIEW_PROBLEM / REVIEW_OK_MANUAL / ...)
--     * df95_ai_confidence
--     * ai_status
--   Filterbar über:
--     * Liste von ReviewFlags (z.B. "REVIEW_MED;REVIEW_LOW;REVIEW_PROBLEM")
--     * Min. Confidence (0.0–1.0)
--
--   Der Report enthält für jedes Item u.a.:
--     * Flag, Confidence, ai_status
--     * Name / Filepath
--     * Session (Location/Sub/Scene)
--     * HomeZone/Sub
--     * UCS/CatID
--
--   Standardpfad DB:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--   Standardpfad Report:
--     <REAPER>/Support/DF95_SampleDB/DF95_ReviewReport_V1.txt

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
  return join_path(dir, "DF95_ReviewReport_V1.txt")
end

local function trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_flags(s)
  local t = {}
  if not s or s == "" then return t end
  for part in string.gmatch(s, "([^;]+)") do
    local p = trim(part):upper()
    if p ~= "" then
      t[#t+1] = p
    end
  end
  return t
end

local function flags_to_set(list)
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
end

local function is_nonempty(v)
  return v ~= nil and v ~= ""
end

------------------------------------------------------------
-- JSON Helper (wie in AutoIngest V3)
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
-- Main
------------------------------------------------------------

local function main()
  local db_path = get_default_db_path()
  local default_flags = "REVIEW_MED;REVIEW_LOW;REVIEW_PROBLEM"
  local defaults = default_flags .. ",0.00," .. ""  -- Flags, MinConf, ReportName

  local ok, csv = r.GetUserInputs(
    "DF95 Review Report V1",
    3,
    "Flags (;-sep, leer=alle),Min. Confidence (0-1),Report-Dateiname (leer=Default)",
    defaults
  )
  if not ok then return end

  local flags_str, min_conf_str, report_name = csv:match("([^,]*),([^,]*),([^,]*)")
  flags_str = trim(flags_str)
  min_conf_str = trim(min_conf_str)
  report_name = trim(report_name)

  local min_conf = tonumber(min_conf_str) or 0.0
  if min_conf < 0.0 then min_conf = 0.0 end
  if min_conf > 1.0 then min_conf = 1.0 end

  local flag_list = split_flags(flags_str)
  local flag_set = flags_to_set(flag_list)

  local f, err = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox("DB nicht gefunden:\n" .. tostring(db_path) .. "\n\n" .. tostring(err or ""), "DF95 Review Report V1", 0)
    return
  end
  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    r.ShowMessageBox("Fehler beim Lesen/Dekodieren der DB:\n" .. tostring(derr or "unbekannt"), "DF95 Review Report V1", 0)
    return
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    r.ShowMessageBox("DB enthält keine Items oder unbekanntes Format.", "DF95 Review Report V1", 0)
    return
  end

  local total_items = #items
  local selected = {}

  local counts_by_flag = {}
  local function norm_flag(v)
    return tostring(v or ""):upper()
  end

  -- Filterung
  for idx, it in ipairs(items) do
    local flag = norm_flag(it.df95_ai_review_flag)
    local conf = tonumber(it.df95_ai_confidence or 0.0) or 0.0

    local passes_conf = (conf >= min_conf)
    local passes_flag = true

    if flags_str ~= "" and next(flag_set) ~= nil then
      passes_flag = flag_set[flag] == true
    end

    if passes_conf and passes_flag then
      selected[#selected+1] = { index = idx, item = it, flag = flag, conf = conf }
      counts_by_flag[flag] = (counts_by_flag[flag] or 0) + 1
    end
  end

  -- Report-Pfad bestimmen
  local report_path
  if report_name ~= "" then
    -- Wenn Name ohne Pfad, im gleichen Verzeichnis wie DB
    if not report_name:match("[/\\]") then
      local dir = db_path:match("^(.*)[/\\].-$")
      if not dir or dir == "" then
        dir = r.GetResourcePath()
      end
      report_path = join_path(dir, report_name)
    else
      report_path = report_name
    end
  else
    report_path = get_default_report_path()
  end

  local rf, rerr = io.open(report_path, "w")
  if not rf then
    r.ShowMessageBox("Konnte Report-Datei nicht öffnen:\n" .. tostring(report_path) .. "\n\n" .. tostring(rerr or ""), "DF95 Review Report V1", 0)
    return
  end

  local function write_line(s)
    rf:write(s or "")
    rf:write("\n")
  end

  -- Header
  write_line("DF95 Review Report V1")
  write_line(string.rep("=", 72))
  write_line("DB       : " .. tostring(db_path))
  write_line("Report   : " .. tostring(report_path))
  write_line(string.format("Items    : %d gesamt, %d gefiltert", total_items, #selected))
  write_line(string.format("MinConf  : %.2f", min_conf))
  if flags_str ~= "" then
    write_line("Flags    : " .. flags_str)
  else
    write_line("Flags    : (alle)")
  end
  write_line("Erzeugt  : " .. os.date("%Y-%m-%d %H:%M:%S"))
  write_line("")

  -- Flag-Statistik
  write_line("Verteilung nach df95_ai_review_flag (nur gefilterte Items):")
  if next(counts_by_flag) == nil then
    write_line("  (keine Items im Filter)")
  else
    for flag, cnt in pairs(counts_by_flag) do
      write_line(string.format("  %s: %d", flag ~= "" and flag or "(none)", cnt))
    end
  end
  write_line("")
  write_line(string.rep("-", 72))
  write_line("Details:")
  write_line("index\tflag\tconf\tai_status\tname\tfilepath\tsession\tzone\tucs_catid")
  write_line(string.rep("-", 72))

  -- Details
  for _, entry in ipairs(selected) do
    local idx = entry.index
    local it  = entry.item
    local flag = entry.flag
    local conf = entry.conf

    local ai_status = tostring(it.ai_status or "")
    local name = tostring(it.name or ""):gsub("\t", " ")
    local filepath = tostring(it.filepath or ""):gsub("\t", " ")

    local session = string.format("%s/%s/%s",
      tostring(it.session_location or ""),
      tostring(it.session_subzone or ""),
      tostring(it.session_scene or "")
    ):gsub("\t", " ")

    local zone = string.format("%s/%s",
      tostring(it.home_zone or ""),
      tostring(it.home_zone_sub or "")
    ):gsub("\t", " ")

    local ucs_catid = string.format("%s|%s",
      tostring(it.ucs_category or ""),
      tostring(it.df95_catid or "")
    ):gsub("\t", " ")

    local line = string.format("%d\t%s\t%.2f\t%s\t%s\t%s\t%s\t%s\t%s",
      idx,
      flag ~= "" and flag or "(none)",
      conf,
      ai_status,
      name,
      filepath,
      session,
      zone,
      ucs_catid
    )
    write_line(line)
  end

  rf:close()

  r.ShowMessageBox(
    string.format("DF95 Review Report V1 erstellt.\nDB: %s\nItems gesamt: %d\nGefiltert: %d\nReport: %s",
      tostring(db_path), total_items, #selected, tostring(report_path)
    ),
    "DF95 Review Report V1",
    0
  )
end

main()
