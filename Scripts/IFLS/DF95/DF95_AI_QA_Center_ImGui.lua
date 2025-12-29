-- @description DF95 AI QA Center (ImGui) – AutoIngest / Review / Reports Dashboard
-- @version 1.0
-- @author DF95
-- @about
--   Zentrales QA-Panel für die DF95 AI-Workflow-Kette:
--     * AutoIngest Master V3 (ANALYZE / SAFE / AGGR)
--     * AutoIngest ReviewInspector V1 (ImGui)
--     * AutoIngest ReviewReport V1 (Text/Tab Export)
--
--   Zeigt:
--     * Item-Gesamtzahl in DF95_SampleDB_Multi_UCS.json
--     * Verteilung von df95_ai_review_flag (OK_HIGH / REVIEW_MED / REVIEW_LOW / REVIEW_PROBLEM / REVIEW_OK_MANUAL / ...)
--     * Verteilung von ai_status (auto_safe / auto_high / auto_med / manual / ...)
--     * Durchschnittliche df95_ai_confidence
--
--   Zusätzlich Buttons:
--     * AutoIngest V3 starten (via Action)
--     * ReviewInspector öffnen (via Action)
--     * ReviewReport erzeugen (via Action)
--
--   Hinweis:
--     Die Action-Strings (_DF95_AUTOINGEST_V3, _DF95_AUTOINGEST_REVIEWINSPECTOR_V1, _DF95_AUTOINGEST_REVIEWREPORT_V1)
--     müssen in REAPER den entsprechenden Scripts zugeordnet sein.

local r = reaper

local ctx = r.ImGui_CreateContext('DF95 AI QA Center')
local FONT_SIZE = 14
local font = nil

local function load_font()
  if font then return end
  local ok, new_font = pcall(r.ImGui_CreateFont, FONT_SIZE)
  if ok and new_font then
    font = new_font
    r.ImGui_AttachFont(ctx, font)
  end
end

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

local function trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
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
-- State
------------------------------------------------------------

local state = {
  db_path = "",
  stats = nil,
  last_msg = "",
}

------------------------------------------------------------
-- Stats-Berechnung
------------------------------------------------------------

local function compute_stats(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, "Fehler beim Öffnen: " .. tostring(err or "unbekannt")
  end
  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    return nil, "Fehler beim Dekodieren: " .. tostring(derr or "unbekannt")
  end

  local items = db.items or db
  if type(items) ~= "table" then
    return nil, "DB enthält keine items-Tabelle."
  end

  local stats = {
    db_path = path,
    total_items = #items,

    flags = {},      -- flag -> count
    status = {},     -- ai_status -> count

    items_with_conf = 0,
    sum_conf = 0.0,

    -- Quality-Meter-Gruppen:
    -- clean_items   : OK_HIGH + REVIEW_OK_MANUAL
    -- problem_items : REVIEW_LOW + REVIEW_PROBLEM
    clean_items = 0,
    problem_items = 0,

    -- Schema-Health:
    missing_home_zone = 0,
    missing_home_sub = 0,
    missing_ucs = 0,
    missing_catid = 0,
    missing_session_loc = 0,
    missing_session_sub = 0,
    missing_session_scene = 0,
  }

  local function norm_flag(v)
    return tostring(v or ""):upper()
  end

  local function norm_status(v)
    local s = tostring(v or ""):lower()
    if s == "" then return "(none)" end
    return s
  end

  for _, it in ipairs(items) do
    -- review_flag
    local flag = norm_flag(it.df95_ai_review_flag)
    if flag == "" then flag = "(none)" end
    stats.flags[flag] = (stats.flags[flag] or 0) + 1

    -- ai_status
    local st = norm_status(it.ai_status)
    stats.status[st] = (stats.status[st] or 0) + 1

    -- confidence
    local c = tonumber(it.df95_ai_confidence or 0.0)
    if c then
      if c < 0.0 then c = 0.0 end
      if c > 1.0 then c = 1.0 end
      stats.items_with_conf = stats.items_with_conf + 1
      stats.sum_conf = stats.sum_conf + c
    end

    -- Quality-Meter: Clean vs Problem
    if flag == "OK_HIGH" or flag == "REVIEW_OK_MANUAL" then
      stats.clean_items = stats.clean_items + 1
    elseif flag == "REVIEW_LOW" or flag == "REVIEW_PROBLEM" then
      stats.problem_items = stats.problem_items + 1
    end

    -- Schema-Health
    if not it.home_zone or it.home_zone == "" then
      stats.missing_home_zone = stats.missing_home_zone + 1
    end
    if not it.home_zone_sub or it.home_zone_sub == "" then
      stats.missing_home_sub = stats.missing_home_sub + 1
    end
    if not it.ucs_category or it.ucs_category == "" then
      stats.missing_ucs = stats.missing_ucs + 1
    end
    if not it.df95_catid or it.df95_catid == "" then
      stats.missing_catid = stats.missing_catid + 1
    end
    if not it.session_location or it.session_location == "" then
      stats.missing_session_loc = stats.missing_session_loc + 1
    end
    if not it.session_subzone or it.session_subzone == "" then
      stats.missing_session_sub = stats.missing_session_sub + 1
    end
    if not it.session_scene or it.session_scene == "" then
      stats.missing_session_scene = stats.missing_session_scene + 1
    end
  end

  return stats, nil
end

------------------------------------------------------------
-- Actions
------------------------------------------------------------

local function run_named_command(cmd_name)
  if not cmd_name or cmd_name == "" then return end
  local cmd_id = r.NamedCommandLookup(cmd_name)
  if cmd_id ~= 0 then
    r.Main_OnCommand(cmd_id, 0)
  else
    r.ShowMessageBox("Konnte Command '" .. tostring(cmd_name) .. "' nicht finden.\nBitte sicherstellen, dass das Script als ReaScript registriert ist.", "DF95 AI QA Center", 0)
  end
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

local function draw_stats()
  local stats = state.stats
  if not stats then
    r.ImGui_Text(ctx, "Noch keine Stats berechnet. 'Refresh' klicken.")
    return
  end

  local total = stats.total_items or 0
  r.ImGui_Text(ctx, string.format("Items gesamt: %d", total))

  if stats.items_with_conf > 0 then
    local avg_conf = stats.sum_conf / stats.items_with_conf
    r.ImGui_Text(ctx, string.format("Items mit df95_ai_confidence: %d (Ø %.3f)", stats.items_with_conf, avg_conf))
  else
    r.ImGui_Text(ctx, "Keine df95_ai_confidence-Werte vorhanden.")
  end

  -- Quality-Meter: Clean/Problem-Rate + Ampeltext
  local clean = stats.clean_items or 0
  local problem = stats.problem_items or 0
  local clean_rate = 0.0
  local problem_rate = 0.0
  if total > 0 then
    clean_rate = (clean / total) * 100.0
    problem_rate = (problem / total) * 100.0
  end

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Quality-Meter:")
  r.ImGui_BulletText(ctx, string.format("Clean (OK_HIGH + REVIEW_OK_MANUAL): %d (%.1f%%)", clean, clean_rate))
  r.ImGui_BulletText(ctx, string.format("Problem (REVIEW_LOW + REVIEW_PROBLEM): %d (%.1f%%)", problem, problem_rate))

  local ampel = ""
  if problem_rate <= 5.0 then
    ampel = "Status: GRÜN – Library weitgehend sauber. Fein-Review / Einzelkorrekturen."
  elseif problem_rate <= 15.0 then
    ampel = "Status: GELB – Einige Problemfälle. ReviewInspector & Reports nutzen."
  else
    ampel = "Status: ROT – Viele Problemfälle. AI-Heuristik/DeviceProfiles prüfen, dann erneut AutoIngest."
  end
  r.ImGui_TextWrapped(ctx, ampel)

  -- Schema-Health
  local mhz   = stats.missing_home_zone or 0
  local mhs   = stats.missing_home_sub or 0
  local mucs  = stats.missing_ucs or 0
  local mcat  = stats.missing_catid or 0
  local msl   = stats.missing_session_loc or 0
  local mss   = stats.missing_session_sub or 0
  local msc   = stats.missing_session_scene or 0

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Schema-Health (fehlende Felder – grob wie Validator V3):")
  r.ImGui_BulletText(ctx, string.format("missing home_zone        : %d", mhz))
  r.ImGui_BulletText(ctx, string.format("missing home_zone_sub    : %d", mhs))
  r.ImGui_BulletText(ctx, string.format("missing ucs_category     : %d", mucs))
  r.ImGui_BulletText(ctx, string.format("missing df95_catid       : %d", mcat))
  r.ImGui_BulletText(ctx, string.format("missing session_location : %d", msl))
  r.ImGui_BulletText(ctx, string.format("missing session_subzone  : %d", mss))
  r.ImGui_BulletText(ctx, string.format("missing session_scene    : %d", msc))

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Verteilung df95_ai_review_flag:")
  local flags = stats.flags or {}
  if next(flags) == nil then
    r.ImGui_BulletText(ctx, "(keine Flags gefunden)")
  else
    -- sortierte Ausgabe
    local keys = {}
    for k,_ in pairs(flags) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
      local v = flags[k] or 0
      local pct = 0.0
      if total > 0 then pct = (v / total) * 100.0 end
      r.ImGui_BulletText(ctx, string.format("%s: %d (%.1f%%)", k, v, pct))
    end
  end

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Verteilung ai_status:")
  local status = stats.status or {}
  if next(status) == nil then
    r.ImGui_BulletText(ctx, "(keine ai_status-Werte gefunden)")
  else
    local keys = {}
    for k,_ in pairs(status) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
      local v = status[k] or 0
      local pct = 0.0
      if total > 0 then pct = (v / total) * 100.0 end
      r.ImGui_BulletText(ctx, string.format("%s: %d (%.1f%%)", k, v, pct))
    end
  end
end

local function loop()
  load_font()
  r.ImGui_SetNextWindowSize(ctx, 780, 520, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 AI QA Center", true)
  if visible then
    if font then r.ImGui_PushFont(ctx, font) end

    r.ImGui_Text(ctx, "DF95 AI QA Center – AutoIngest / Review / Reports")
    r.ImGui_Separator(ctx)

    if state.db_path == "" then
      state.db_path = get_default_db_path()
    end

    local changed, new_path = r.ImGui_InputText(ctx, "DB-Pfad (Multi-UCS JSON)", state.db_path or "", 1024)
    if changed then
      state.db_path = trim(new_path)
    end

    if r.ImGui_Button(ctx, "Refresh Stats") then
      local path = state.db_path
      if not path or path == "" then
        path = get_default_db_path()
        state.db_path = path
      end
      local stats, err = compute_stats(path)
      if not stats then
        state.stats = nil
        state.last_msg = err or "Fehler beim Berechnen der Stats."
      else
        state.stats = stats
        state.last_msg = string.format("Stats aktualisiert (%d Items).", stats.total_items or 0)
      end
    end

    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "AutoIngest V3 starten") then
      -- Erwartete Action: _DF95_AUTOINGEST_V3
      run_named_command("_DF95_AUTOINGEST_V3")
    end

    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "ReviewInspector öffnen") then
      -- Erwartete Action: _DF95_AUTOINGEST_REVIEWINSPECTOR_V1
      run_named_command("_DF95_AUTOINGEST_REVIEWINSPECTOR_V1")
    end

    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "ReviewReport erzeugen") then
      -- Erwartete Action: _DF95_AUTOINGEST_REVIEWREPORT_V1
      run_named_command("_DF95_AUTOINGEST_REVIEWREPORT_V1")
    end

    r.ImGui_Separator(ctx)
    draw_stats()

    if state.last_msg and state.last_msg ~= "" then
      r.ImGui_Separator(ctx)
      r.ImGui_TextWrapped(ctx, "Status: " .. state.last_msg)
    end

    if font then r.ImGui_PopFont(ctx) end
  end
  r.ImGui_End(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)
