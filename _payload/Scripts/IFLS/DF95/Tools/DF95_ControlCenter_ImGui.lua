-- @description DF95 Control Center (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Zentrales Control-Center für DF95:
--   Tabs für Fieldrec/PolyWAV, SampleDB, Artist/IDM, Safety/Diagnose.

local reaper = reaper

local ctx = reaper.ImGui_CreateContext('DF95 Control Center')

local FONT_SIZE = 14
local font = nil

local function load_font()
  if font then return end
  local ok, new_font = pcall(reaper.ImGui_CreateFont, FONT_SIZE)
  if ok and new_font then
    font = new_font
    reaper.ImGui_AttachFont(ctx, font)
  end
end

local function run_named_command(cmd_str)
  if not cmd_str or cmd_str == "" then return end
  local cmd_id = reaper.NamedCommandLookup(cmd_str)
  if cmd_id ~= 0 then
    reaper.Main_OnCommand(cmd_id, 0)
  else
    reaper.ShowConsoleMsg("DF95 ControlCenter: Command not found: " .. tostring(cmd_str) .. "\n")
  end
end


------------------------------------------------------------
-- Analytics / Hotspot State & Helpers
------------------------------------------------------------

local df95_analytics = {
  db_path = "",
  last_msg = "",
  total_items = 0,
  total_problem = 0,
  zones = {},   -- key: "HOME/ZONE[/SUB]", value: {count, problem, review_med, review_low, review_problem, sum_conf}
  status = {},  -- key: ai_status, value: {count, problem}
}

local function df95_join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function df95_get_default_db_path()
  local res = reaper.GetResourcePath()
  local dir = df95_join_path(res, "Support")
  dir = df95_join_path(dir, "DF95_SampleDB")
  return df95_join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function df95_get_inspector_filter_path()
  local res = reaper.GetResourcePath()
  local dir = df95_join_path(res, "Support")
  dir = df95_join_path(dir, "DF95_SampleDB")
  return df95_join_path(dir, "DF95_InspectorV5_HotspotFilter.json")
end

local function df95_write_inspector_hotspot(zone)
  local path = df95_get_inspector_filter_path()
  local f, err = io.open(path, "w")
  if not f then
    df95_analytics.last_msg = "Konnte Inspector-Hotspot-Config nicht schreiben: " .. tostring(err or "unbekannt")
    return
  end
  local json = string.format([[{"filter_zone":%q,"filter_flag":%q,"filter_status":%q,"filter_min_conf":%.3f}]],
                             tostring(zone or ""), "REVIEW_PROBLEM", "ALL", 0.0)
  f:write(json)
  f:close()
end

local function df95_decode_json(text)
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

local function df95_analytics_rebuild()
  if df95_analytics.db_path == "" then
    df95_analytics.db_path = df95_get_default_db_path()
  end

  local path = df95_analytics.db_path
  local f, err = io.open(path, "r")
  if not f then
    df95_analytics.last_msg = "DB nicht gefunden: " .. tostring(path) .. " (" .. tostring(err or "unbekannt") .. ")"
    df95_analytics.total_items = 0
    df95_analytics.total_problem = 0
    df95_analytics.zones = {}
    df95_analytics.status = {}
    return
  end

  local text = f:read("*all")
  f:close()

  local db, derr = df95_decode_json(text)
  if not db then
    df95_analytics.last_msg = "Fehler beim Dekodieren der DB: " .. tostring(derr or "unbekannt")
    df95_analytics.total_items = 0
    df95_analytics.total_problem = 0
    df95_analytics.zones = {}
    df95_analytics.status = {}
    return
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    df95_analytics.last_msg = "DB enthält keine Items oder unbekanntes Format."
    df95_analytics.total_items = 0
    df95_analytics.total_problem = 0
    df95_analytics.zones = {}
    df95_analytics.status = {}
    return
  end

  df95_analytics.total_items = #items
  df95_analytics.total_problem = 0
  df95_analytics.zones = {}
  df95_analytics.status = {}

  local function norm_flag(v)
    return tostring(v or ""):upper()
  end

  local function norm_status(v)
    local s = tostring(v or ""):lower()
    if s == "" then return "(none)" end
    return s
  end

  for _, it in ipairs(items) do
    local hz = it.home_zone or "(none)"
    local hzs = it.home_zone_sub or ""
    local zone = hz
    if hzs ~= "" then
      zone = zone .. "/" .. hzs
    end

    local flag = norm_flag(it.df95_ai_review_flag)
    if flag == "" then flag = "(NONE)" end

    local status = norm_status(it.ai_status)

    local c = tonumber(it.df95_ai_confidence or 0.0) or 0.0
    if c < 0.0 then c = 0.0 end
    if c > 1.0 then c = 1.0 end

    local z = df95_analytics.zones[zone]
    if not z then
      z = {count = 0, problem = 0, review_med = 0, review_low = 0, review_problem = 0, sum_conf = 0.0}
      df95_analytics.zones[zone] = z
    end
    z.count = z.count + 1
    z.sum_conf = z.sum_conf + c

    if flag == "REVIEW_MED" then
      z.review_med = z.review_med + 1
    elseif flag == "REVIEW_LOW" then
      z.review_low = z.review_low + 1
    elseif flag == "REVIEW_PROBLEM" then
      z.review_problem = z.review_problem + 1
    end

    if flag == "REVIEW_LOW" or flag == "REVIEW_PROBLEM" then
      z.problem = z.problem + 1
      df95_analytics.total_problem = df95_analytics.total_problem + 1
    end

    local st = df95_analytics.status[status]
    if not st then
      st = {count = 0, problem = 0}
      df95_analytics.status[status] = st
    end
    st.count = st.count + 1
    if flag == "REVIEW_LOW" or flag == "REVIEW_PROBLEM" then
      st.problem = st.problem + 1
    end
  end

  df95_analytics.last_msg = string.format("Analytics aktualisiert (%d Items).", df95_analytics.total_items)
end

local function draw_analytics_tab()
  if df95_analytics.db_path == "" then
    df95_analytics.db_path = df95_get_default_db_path()
  end

  local changed_path, new_path = reaper.ImGui_InputText(ctx, "DB-Pfad", df95_analytics.db_path or "", 1024)
  if changed_path then
    df95_analytics.db_path = new_path
  end

  if reaper.ImGui_Button(ctx, "Analytics Refresh") then
    df95_analytics_rebuild()
  end

  local total = df95_analytics.total_items or 0
  local problem = df95_analytics.total_problem or 0
  local problem_rate = 0.0
  if total > 0 then
    problem_rate = (problem / total) * 100.0
  end

  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_Text(ctx, string.format("Items: %d, Problem: %d (%.1f%%)", total, problem, problem_rate))

  if df95_analytics.last_msg ~= "" then
    reaper.ImGui_TextWrapped(ctx, "Status: " .. df95_analytics.last_msg)
  end

  -- Hotspots nach HomeZone/SubZone
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "Hotspots nach HomeZone/SubZone (sortiert nach Problem-Items):")

  local zones = {}
  for name, data in pairs(df95_analytics.zones or {}) do
    zones[#zones+1] = {name = name, data = data}
  end
  table.sort(zones, function(a, b)
    local ap = a.data.problem or 0
    local bp = b.data.problem or 0
    if ap == bp then
      return (a.data.count or 0) > (b.data.count or 0)
    end
    return ap > bp
  end)

  local max_rows = 15
  if #zones == 0 then
    reaper.ImGui_BulletText(ctx, "(noch keine Analytics-Daten – 'Analytics Refresh' klicken)")
  else
    reaper.ImGui_Columns(ctx, 6, "df95_analytics_zones", true)
    reaper.ImGui_Text(ctx, "Zone");          reaper.ImGui_NextColumn(ctx)
    reaper.ImGui_Text(ctx, "Items");         reaper.ImGui_NextColumn(ctx)
    reaper.ImGui_Text(ctx, "Problem");       reaper.ImGui_NextColumn(ctx)
    reaper.ImGui_Text(ctx, "Problem %");     reaper.ImGui_NextColumn(ctx)
    reaper.ImGui_Text(ctx, "Ø Conf");        reaper.ImGui_NextColumn(ctx)
    reaper.ImGui_Text(ctx, "Flags (MED/LOW/PROB)"); reaper.ImGui_NextColumn(ctx)
    reaper.ImGui_Separator(ctx)

    local rows = math.min(#zones, max_rows)
    for i = 1, rows do
      local z = zones[i]
      local d = z.data
      local cnt = d.count or 0
      local prob = d.problem or 0
      local pr = 0.0
      if cnt > 0 then
        pr = (prob / cnt) * 100.0
      end
      local avg_conf = 0.0
      if cnt > 0 then
        avg_conf = (d.sum_conf or 0.0) / cnt
      end

      reaper.ImGui_Text(ctx, z.name or "(none)");    reaper.ImGui_NextColumn(ctx)
      reaper.ImGui_Text(ctx, tostring(cnt));         reaper.ImGui_NextColumn(ctx)
      reaper.ImGui_Text(ctx, tostring(prob));        reaper.ImGui_NextColumn(ctx)
      reaper.ImGui_Text(ctx, string.format("%.1f%%", pr)); reaper.ImGui_NextColumn(ctx)
      reaper.ImGui_Text(ctx, string.format("%.3f", avg_conf)); reaper.ImGui_NextColumn(ctx)
      local med = d.review_med or 0
      local low = d.review_low or 0
      local prob_c = d.review_problem or 0
      reaper.ImGui_Text(ctx, string.format("MED:%d LOW:%d PROB:%d", med, low, prob_c))
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, string.format("-> Inspector V5##%d", i)) then
        df95_write_inspector_hotspot(z.name or "")
        df95_analytics.last_msg = "Hotspot nach Inspector V5 geschrieben (Zone: " .. tostring(z.name or "") .. ")"
        run_named_command("_DF95_SAMPLEDB_INSPECTOR_V5")
      end
      reaper.ImGui_NextColumn(ctx)
    end

    reaper.ImGui_Columns(ctx, 1)
  end

  -- ai_status Übersicht
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "ai_status Übersicht (Problem-Anteil):")

  local status = {}
  for name, data in pairs(df95_analytics.status or {}) do
    status[#status+1] = {name = name, data = data}
  end
  table.sort(status, function(a, b)
    return (a.name or "") < (b.name or "")
  end)

  if #status == 0 then
    reaper.ImGui_BulletText(ctx, "(keine ai_status-Werte vorhanden)")
  else
    for _, s in ipairs(status) do
      local d = s.data
      local cnt = d.count or 0
      local prob = d.problem or 0
      local pr = 0.0
      if cnt > 0 then
        pr = (prob / cnt) * 100.0
      end
      reaper.ImGui_BulletText(ctx, string.format("%s: %d Items, Problem: %d (%.1f%%)", s.name, cnt, prob, pr))
    end
  end
end

local function draw_fieldrec_tab()
  if reaper.ImGui_Button(ctx, 'SlicingHub öffnen') then
    run_named_command("_DF95_SLICINGHUB")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'PolyWAV Toolbox') then
    run_named_command("_DF95_POLYWAV_TOOLBOX_V5")
  end

  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "Fieldrec / PolyWAV Status (später live):")
  reaper.ImGui_BulletText(ctx, "Device-Profile-System aktiv (ZOOM / EMF / Fieldrec)")
  reaper.ImGui_BulletText(ctx, "PolyWAV V6 Session-Recall geplant")
end

local function draw_sampledb_tab()
  -- Core SampleDB Tools
  if reaper.ImGui_Button(ctx, 'SampleDB Inspector V4') then
    run_named_command("_DF95_SAMPLEDB_INSPECTOR_V4")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'SampleDB Inspector V5 (AI/Review)') then
    run_named_command("_DF95_SAMPLEDB_INSPECTOR_V5")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'PackExporter') then
    run_named_command("_DF95_SAMPLEDB_PACKEXPORTER")
  end

  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "SampleDB / UCS / Home-Zonen Übersicht:")
  reaper.ImGui_BulletText(ctx, "HomeZone-Schema (HOME_KITCHEN_*, HOME_CELLAR_* ...)")
  reaper.ImGui_BulletText(ctx, "AI Mapping & UCS Light integriert")

  -- AI / AutoIngest / QA
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "AI / AutoIngest / QA:")

  if reaper.ImGui_Button(ctx, 'AutoIngest V3') then
    run_named_command("_DF95_AUTOINGEST_V3")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'ReviewInspector V1') then
    run_named_command("_DF95_AUTOINGEST_REVIEWINSPECTOR_V1")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'ReviewReport V1') then
    run_named_command("_DF95_AUTOINGEST_REVIEWREPORT_V1")
  end

  if reaper.ImGui_Button(ctx, 'AI QA Center') then
    run_named_command("_DF95_AI_QA_CENTER")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'AutoIngest Undo Last Run') then
    run_named_command("_DF95_AUTOINGEST_UNDO_LASTRUN")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Drone/Atmos Builder (from View)') then
    -- Erzeugt Drone/Atmos-Layouts im Projekt auf Basis der aktuellen AutoIngest-Subset-View.
    run_named_command("_DF95_DRONE_ATMOS_BUILDER_FROM_VIEW")
  end

  if reaper.ImGui_Button(ctx, 'Export Preset Picker') then
    -- Oeffnet den DF95 Export Preset Picker (setzt DF95_EXPORT.current_preset_id).
    run_named_command("_DF95_EXPORT_PRESET_PICKER")
  end


  reaper.ImGui_BulletText(ctx, "AutoIngest V3: nutzt df95_ai_confidence und *_suggested Felder")
  reaper.ImGui_BulletText(ctx, "ReviewInspector: manuelles Review von REVIEW_* Items")
  reaper.ImGui_BulletText(ctx, "ReviewReport: Text/Tab-Report der Problemfälle")
  reaper.ImGui_BulletText(ctx, "AI QA Center: Quality-Meter & Verteilung von Flags/ai_status")
  reaper.ImGui_BulletText(ctx, "Undo Last Run: macht den letzten SAFE/AGGR-Lauf auf Basis des ChangeLogs rückgängig")

  -- Maintenance / Validation
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "Maintenance / Validation:")

  if reaper.ImGui_Button(ctx, 'SampleDB Validator V3') then
    run_named_command("_DF95_SAMPLEDB_VALIDATOR_V3")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'SampleDB Migration V2->V3') then
    run_named_command("_DF95_SAMPLEDB_MIGRATE_V2_TO_V3")
  end

  reaper.ImGui_BulletText(ctx, "Validator V3: prüft Pflichtfelder & AI-Felder, schreibt optional Report")
  reaper.ImGui_BulletText(ctx, "Migration V2->V3: ergänzt AI-Felder & normalisiert nil-Felder (vorher Backup machen!)")
end

local function draw_artist_tab()
  if reaper.ImGui_Button(ctx, 'Artist Console öffnen') then
    run_named_command("_DF95_ARTIST_CONSOLE")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Artist/IDM FXBus Selector') then
    run_named_command("_DF95_ARTIST_IDM_FXBUS_SELECTOR")
  end

  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "Artist / IDM / Beat Engine:")
  reaper.ImGui_BulletText(ctx, "Scenes (Intro/Main/Bridge/Outro) geplant")
  reaper.ImGui_BulletText(ctx, "Morphing & Humanization in Entwicklung")

  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "Drone / Atmos Export (Artist Link):")

  if reaper.ImGui_Button(ctx, 'IDM Drone Texture Preset setzen') then
    -- Setzt das Export-Preset fuer IDM Drone Texture (Loop).
    reaper.SetExtState("DF95_EXPORT", "current_preset_id", "DRONE_IDM_TEXTURE_LONG", true)
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Drone/Atmos Builder öffnen') then
    -- Oeffnet den Drone/Atmos Builder (arbeitet auf der aktuellen AutoIngest-Subset-View).
    run_named_command("_DF95_DRONE_ATMOS_BUILDER_FROM_VIEW")
  end

  if reaper.ImGui_Button(ctx, 'Export Preset Picker (Drone/Artist)') then
    -- Oeffnet den Export Preset Picker; dort koennen auch andere Drone/Artist-Presets gewaehlt werden.
    run_named_command("_DF95_EXPORT_PRESET_PICKER")
  end
end

local function draw_safety_tab()
  if reaper.ImGui_Button(ctx, 'Safety SelfCheck Tool') then
    run_named_command("_DF95_SAFETY_SELFCHECK")
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Debug Dashboard (geplant)') then
    reaper.ShowMessageBox("Debug Dashboard ist in Planung.", "DF95 Control Center", 0)
  end

  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Text(ctx, "Safety / Diagnose:")
  reaper.ImGui_BulletText(ctx, "Safety Level 4 aktiv (Routing, MicFX, AIWorker)")
  reaper.ImGui_BulletText(ctx, "Level 5: Globaler Interceptor & Log-Auswertung geplant")
end

local function loop()
  load_font()

  reaper.ImGui_SetNextWindowSize(ctx, 800, 500, reaper.ImGui_Cond_FirstUseEver())

  local visible, open = reaper.ImGui_Begin(ctx, 'DF95 Control Center', true)

  if visible then
    if font then
      reaper.ImGui_PushFont(ctx, font)
    end

    if reaper.ImGui_BeginTabBar(ctx, "DF95_TABS") then

      if reaper.ImGui_BeginTabItem(ctx, "Fieldrec / PolyWAV") then
        draw_fieldrec_tab()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "SampleDB") then
        draw_sampledb_tab()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "Analytics") then
        draw_analytics_tab()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "Artist / IDM") then
        draw_artist_tab()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "Safety / Diagnose") then
        draw_safety_tab()
        reaper.ImGui_EndTabItem(ctx)
      end

      reaper.ImGui_EndTabBar(ctx)
    end

    if font then
      reaper.ImGui_PopFont(ctx)
    end

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)
