-- @description DF95 SampleDB Inspector V5 (AI / Review / Confidence) ImGui
-- @version 1.0
-- @author DF95
-- @about
--   Interaktiver Inspector für die DF95 Multi-UCS SampleDB mit Fokus auf
--   AI-/Review-Felder:
--     * df95_ai_review_flag (OK_HIGH / REVIEW_MED / REVIEW_LOW / REVIEW_PROBLEM / REVIEW_OK_MANUAL / ...)
--     * df95_ai_confidence (0..1)
--     * ai_status (auto_safe / auto_high / auto_med / manual / legacy / ...)
--   Features:
--     * Filter nach:
--         - Substring (Name/Filepath)
--         - Review-Flag
--         - ai_status
--         - min. Confidence
--     * Übersichtliche Liste (bis max_rows Items aus der aktuellen Filtermenge)
--     * Quick-Actions:
--         - "Mark view as REVIEW_OK_MANUAL"
--         - "Mark view as REVIEW_PROBLEM"
--         - "Set ai_status in view to manual"
--     * Speichern der DB zurück in DF95_SampleDB_Multi_UCS.json
--
--   Hinweis:
--     Dieses Script arbeitet direkt auf der DF95 Multi-UCS JSON:
--       <REAPER Resource Path>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json

local r = reaper

local ctx = r.ImGui_CreateContext('DF95 SampleDB Inspector V5 – AI/Review')
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

local function safe_str(v)
  if v == nil then return "" end
  return tostring(v)
end

------------------------------------------------------------
-- JSON Decode / Encode (minimal, kompatibel zu anderen DF95-Tools)
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

local function encode_json_value(v, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)

  local t = type(v)
  if t == "string" then
    return string.format("%q", v)
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then
      return "0"
    end
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    -- prüfen, ob Array
    local is_array = true
    local max_index = 0
    for k,_ in pairs(v) do
      if type(k) ~= "number" then
        is_array = false
        break
      else
        if k > max_index then max_index = k end
      end
    end

    local parts = {}
    if is_array then
      table.insert(parts, "[\n")
      for i = 1, max_index do
        local iv = v[i]
        table.insert(parts, pad .. "  " .. encode_json_value(iv, indent+1))
        if i < max_index then table.insert(parts, ",") end
        table.insert(parts, "\n")
      end
      table.insert(parts, pad .. "]")
    else
      table.insert(parts, "{\n")
      local first = true
      for k2, v2 in pairs(v) do
        if not first then
          table.insert(parts, ",\n")
        end
        first = false
        table.insert(parts, pad .. "  " .. string.format("%q", tostring(k2)) .. ": " .. encode_json_value(v2, indent+1))
      end
      table.insert(parts, "\n" .. pad .. "}")
    end
    return table.concat(parts)
  end
  return "null"
end

------------------------------------------------------------
-- State
------------------------------------------------------------

local state = {
  db_path = "",
  db = nil,
  items = nil,          -- array of items
  filtered_indices = {},

  filter_text = "",
  filter_flag = "ALL",
  filter_status = "ALL",
  filter_min_conf = 0.0,
  max_rows = 500,

  -- Drone-spezifische Filter (Phase K)
  filter_drone_only       = false,
  filter_drone_kind       = "ALL",
  filter_drone_centerfreq = "ALL",
  filter_drone_density    = "ALL",
  filter_drone_form       = "ALL",
  filter_drone_motion     = "ALL",
  filter_drone_tension    = "ALL",

  last_msg = "",
  last_stats = "",
}

------------------------------------------------------------
-- Loading / Filtering
------------------------------------------------------------

local function load_db(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, "Fehler beim Öffnen der DB: " .. tostring(err or "unbekannt")
  end
  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    return nil, "Fehler beim Dekodieren der DB: " .. tostring(derr or "unbekannt")
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    return nil, "DB enthält keine Items oder unbekanntes Format."
  end

  return { db = db, items = items }, nil
end

local function norm_flag(v)
  return tostring(v or ""):upper()
end

local function norm_status(v)
  local s = tostring(v or ""):lower()
  if s == "" then return "(none)" end
  return s
end

local function item_matches_filters(it)
  -- Textfilter: Name oder Filepath
  local t = state.filter_text
  if t ~= "" then
    t = t:lower()
    local name = safe_str(it.name):lower()
    local filepath = safe_str(it.filepath):lower()
    if not name:find(t, 1, true) and not filepath:find(t, 1, true) then
      return false
    end
  end

  
  -- HomeZone/SubZone Filter (optional, exakte Zone aus Analytics)
  if state.filter_zone ~= "" then
    local hz  = safe_str(it.home_zone)
    local hzs = safe_str(it.home_zone_sub)
    local full_zone = hz
    if hzs ~= "" then
      full_zone = full_zone .. "/" .. hzs
    end
    if full_zone ~= state.filter_zone then
      return false
    end
  end

-- Review-Flag
  if state.filter_flag ~= "ALL" then
    local f = norm_flag(it.df95_ai_review_flag)
    if f ~= state.filter_flag then
      return false
    end
  end

  -- ai_status
  if state.filter_status ~= "ALL" then
    local st = norm_status(it.ai_status)
    if st ~= state.filter_status then
      return false
    end
  end

  
  -- Drone-Only / Drone-Attribute Filter (Phase K)
  if state.filter_drone_only then
    local role = upper(it.role)
    local flag = upper(it.df95_drone_flag)
    local cat  = upper(it.df95_catid)
    local is_drone = false
    if role == "DRONE" then is_drone = true end
    if flag ~= "" then is_drone = true end
    if cat:find("DRONE", 1, true) then is_drone = true end
    if not is_drone then
      return false
    end
  end

  if state.filter_drone_kind and state.filter_drone_kind ~= "ALL" then
    local flag = upper(it.df95_drone_flag)
    local cat  = upper(it.df95_catid)
    local kind = flag
    if kind == "" then
      if cat:find("HOME", 1, true) then
        kind = "HOME_DRONE"
      elseif cat:find("EMF", 1, true) then
        kind = "EMF_DRONE"
      elseif cat:find("IDM", 1, true) then
        kind = "IDM_DRONE"
      elseif cat:find("DRONE", 1, true) then
        kind = "GENERIC_DRONE"
      else
        kind = "OTHER"
      end
    end
    if kind ~= state.filter_drone_kind then
      return false
    end
  end

  local cf   = upper(it.df95_drone_centerfreq)
  local dens = upper(it.df95_drone_density)
  local form = upper(it.df95_drone_form)
  local mot  = upper(it.df95_motion_strength or it.df95_drone_motion)
  local ten  = upper(it.df95_tension)

  if state.filter_drone_centerfreq and state.filter_drone_centerfreq ~= "ALL" then
    if cf ~= state.filter_drone_centerfreq then
      return false
    end
  end
  if state.filter_drone_density and state.filter_drone_density ~= "ALL" then
    if dens ~= state.filter_drone_density then
      return false
    end
  end
  if state.filter_drone_form and state.filter_drone_form ~= "ALL" then
    if form ~= state.filter_drone_form then
      return false
    end
  end
  if state.filter_drone_motion and state.filter_drone_motion ~= "ALL" then
    if mot ~= state.filter_drone_motion then
      return false
    end
  end
  if state.filter_drone_tension and state.filter_drone_tension ~= "ALL" then
    if ten ~= state.filter_drone_tension then
      return false
    end
  end

-- min. Confidence
  local c = tonumber(it.df95_ai_confidence or 0.0) or 0.0
  if c < state.filter_min_conf then
    return false
  end

  return true
end

local function rebuild_filtered_indices()
  state.filtered_indices = {}
  local items = state.items
  if not items then return end
  for idx, it in ipairs(items) do
    if item_matches_filters(it) then
      state.filtered_indices[#state.filtered_indices+1] = idx
    end
  end

  local total = #items
  local match = #state.filtered_indices
  state.last_stats = string.format("Items: %d, Filter-Matches: %d", total, match)


------------------------------------------------------------
-- Hotspot Filter (von ControlCenter / Analytics)
------------------------------------------------------------

local function get_hotspot_filter_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_InspectorV5_HotspotFilter.json")
end

local function try_apply_hotspot_filter()
  if state.hotspot_applied then return end

  local path = get_hotspot_filter_path()
  local f = io.open(path, "r")
  if not f then
    state.hotspot_applied = true
    return
  end

  local text = f:read("*all")
  f:close()

  local cfg, err = decode_json(text)
  if not cfg then
    state.last_msg = "Konnte Hotspot-Filter nicht lesen: " .. tostring(err or "unbekannt")
    state.hotspot_applied = true
    return
  end

  if cfg.filter_zone then
    state.filter_zone = trim(tostring(cfg.filter_zone))
  end
  if cfg.filter_flag then
    state.filter_flag = tostring(cfg.filter_flag)
  end
  if cfg.filter_status then
    state.filter_status = tostring(cfg.filter_status)
  end
  if cfg.filter_min_conf ~= nil then
    local v = tonumber(cfg.filter_min_conf)
    if v then
      if v < 0.0 then v = 0.0 end
      if v > 1.0 then v = 1.0 end
      state.filter_min_conf = v
    end
  end

  -- Drone-spezifische Filter aus Hotspot (Phase K)
  if cfg.filter_drone_only ~= nil then
    state.filter_drone_only = cfg.filter_drone_only and true or false
  end
  if cfg.filter_drone_kind then
    state.filter_drone_kind = tostring(cfg.filter_drone_kind)
  end
  if cfg.filter_drone_centerfreq then
    state.filter_drone_centerfreq = tostring(cfg.filter_drone_centerfreq)
  end
  if cfg.filter_drone_density then
    state.filter_drone_density = tostring(cfg.filter_drone_density)
  end
  if cfg.filter_drone_form then
    state.filter_drone_form = tostring(cfg.filter_drone_form)
  end
  if cfg.filter_drone_motion then
    state.filter_drone_motion = tostring(cfg.filter_drone_motion)
  end
  if cfg.filter_drone_tension then
    state.filter_drone_tension = tostring(cfg.filter_drone_tension)
  end

  state.hotspot_applied = true
  rebuild_filtered_indices()
  state.last_msg = "Hotspot-Filter aus Analytics übernommen (Zone: " .. (state.filter_zone or "") .. ", DroneKind=" .. (state.filter_drone_kind or "ALL") .. ")"
end

end


local function write_autoingest_subset_from_view()
  if not state.items or not state.filtered_indices or #state.filtered_indices == 0 then
    state.last_msg = "Keine Items in der aktuellen View – nichts für Subset zu schreiben."
    return
  end

  local paths = {}
  local seen = {}

  local max_rows = state.max_rows or 500
  local count = #state.filtered_indices
  if count > max_rows then count = max_rows end

  for i = 1, count do
    local idx = state.filtered_indices[i]
    local it = state.items[idx]
    local fp = safe_str(it.filepath)
    if fp ~= "" and not seen[fp] then
      seen[fp] = true
      paths[#paths+1] = fp
    end
  end

  if #paths == 0 then
    state.last_msg = "Keine gültigen Filepaths in der View gefunden – Subset-Datei wird nicht geschrieben."
    return
  end

  local out = encode_json_value(paths, 0)
  local path = get_autoingest_subset_path()
  local f, err = io.open(path, "w")
  if not f then
    state.last_msg = "Fehler beim Schreiben der Subset-Datei: " .. tostring(err or "unbekannt")
    return
  end
  f:write(out)
  f:close()

  state.last_msg = string.format("Subset für AutoIngest geschrieben (%d eindeutige Paths) nach: %s", #paths, path)
end
------------------------------------------------------------
-- Quick Actions
------------------------------------------------------------

local function apply_flag_to_view(new_flag)
  if not state.items or not state.filtered_indices then return end
  local n = 0
  for _, idx in ipairs(state.filtered_indices) do
    local it = state.items[idx]
    it.df95_ai_review_flag = new_flag
    n = n + 1
  end
  state.last_msg = string.format("df95_ai_review_flag für %d Items auf '%s' gesetzt.", n, new_flag)
end

local function apply_status_to_view(new_status)
  if not state.items or not state.filtered_indices then return end
  local n = 0
  for _, idx in ipairs(state.filtered_indices) do
    local it = state.items[idx]
    it.ai_status = new_status
    n = n + 1
  end
  state.last_msg = string.format("ai_status für %d Items auf '%s' gesetzt.", n, new_status)
end

------------------------------------------------------------
-- Save DB
------------------------------------------------------------

local function save_db()
  if not state.db or not state.items then
    state.last_msg = "Keine DB geladen."
    return
  end

  local out_text = encode_json_value(state.db, 0)
  local f, err = io.open(state.db_path, "w")
  if not f then
    state.last_msg = "Fehler beim Schreiben der DB: " .. tostring(err or "unbekannt")
    return
  end
  f:write(out_text)
  f:close()
  state.last_msg = "DB gespeichert nach: " .. tostring(state.db_path)

local function get_autoingest_subset_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_AutoIngest_Subset.json")
end
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

local review_flag_options = {
  "ALL",
  "OK_HIGH",
  "REVIEW_MED",
  "REVIEW_LOW",
  "REVIEW_PROBLEM",
  "REVIEW_OK_MANUAL",
  "(NONE)",
}

local ai_status_options = {
  "ALL",
  "auto_safe",
  "auto_high",
  "auto_med",
  "manual",
  "legacy",
  "(none)",
}

local function draw_filters()
  try_apply_hotspot_filter()
  -- DB-Pfad
  if state.db_path == "" then
    state.db_path = get_default_db_path()
  end

  local changed_path, new_path = r.ImGui_InputText(ctx, "DB-Pfad", state.db_path or "", 1024)
  if changed_path then
    state.db_path = trim(new_path)
  end

  if r.ImGui_Button(ctx, "DB neu laden") then
    local res, err = load_db(state.db_path)
    if not res then
      state.db = nil
      state.items = nil
      state.filtered_indices = {}
      state.last_msg = err or "Fehler beim Laden der DB."
      state.last_stats = ""
    else
      state.db = res.db
      state.items = res.items
      rebuild_filtered_indices()
      state.last_msg = string.format("DB geladen (%d Items).", #state.items)
    end
  end

  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Filter aktualisieren") then
    rebuild_filtered_indices()
  end

  -- Filterzeile 1: Text + Flags
  local changed_text, new_text = r.ImGui_InputText(ctx, "Filter Text (Name/Path)", state.filter_text or "", 256)
  if changed_text then
    state.filter_text = new_text
  end
  local changed_zone, new_zone = r.ImGui_InputText(ctx, "Filter Zone (HomeZone/SubZone)", state.filter_zone or "", 256)
  if changed_zone then
    state.filter_zone = trim(new_zone)
  end


  -- Review-Flag Combo
  local current_flag_index = 0
  for i, v in ipairs(review_flag_options) do
    if v == state.filter_flag then
      current_flag_index = i - 1
      break
    end
  end
  if r.ImGui_BeginCombo(ctx, "Review-Flag", state.filter_flag or "ALL") then
    for i, v in ipairs(review_flag_options) do
      local selected = (v == state.filter_flag)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_flag = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  -- ai_status Combo
  if r.ImGui_BeginCombo(ctx, "ai_status", state.filter_status or "ALL") then
    for _, v in ipairs(ai_status_options) do
      local selected = (v == state.filter_status)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_status = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end


  -- Drone-Filter (Phase K)
  if r.ImGui_Checkbox(ctx, "Nur Drones", state.filter_drone_only) then
    state.filter_drone_only = not state.filter_drone_only
  end

  local kinds = { "ALL", "HOME_DRONE", "EMF_DRONE", "IDM_DRONE", "GENERIC_DRONE" }
  if r.ImGui_BeginCombo(ctx, "Drone-Kind", state.filter_drone_kind or "ALL") then
    for _, v in ipairs(kinds) do
      local selected = (v == state.filter_drone_kind)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_drone_kind = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  local cf_opts = { "ALL", "LOW", "MID", "HIGH" }
  if r.ImGui_BeginCombo(ctx, "Drone Centerfreq", state.filter_drone_centerfreq or "ALL") then
    for _, v in ipairs(cf_opts) do
      local selected = (v == state.filter_drone_centerfreq)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_drone_centerfreq = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  local dens_opts = { "ALL", "LOW", "MED", "HIGH" }
  if r.ImGui_BeginCombo(ctx, "Drone Density", state.filter_drone_density or "ALL") then
    for _, v in ipairs(dens_opts) do
      local selected = (v == state.filter_drone_density)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_drone_density = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  local form_opts = { "ALL", "PAD", "TEXTURE", "SWELL", "MOVEMENT", "GROWL" }
  if r.ImGui_BeginCombo(ctx, "Drone Form", state.filter_drone_form or "ALL") then
    for _, v in ipairs(form_opts) do
      local selected = (v == state.filter_drone_form)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_drone_form = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  local motion_opts = { "ALL", "STATIC", "MOVEMENT", "PULSE", "SWELL" }
  if r.ImGui_BeginCombo(ctx, "Drone Motion", state.filter_drone_motion or "ALL") then
    for _, v in ipairs(motion_opts) do
      local selected = (v == state.filter_drone_motion)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_drone_motion = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  local tension_opts = { "ALL", "LOW", "MED", "HIGH", "EXTREME" }
  if r.ImGui_BeginCombo(ctx, "Drone Tension", state.filter_drone_tension or "ALL") then
    for _, v in ipairs(tension_opts) do
      local selected = (v == state.filter_drone_tension)
      if r.ImGui_Selectable(ctx, v, selected) then
        state.filter_drone_tension = v
      end
      if selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end


  -- Confidence & max_rows
  local changed_conf, new_conf = r.ImGui_SliderDouble(ctx, "min. Confidence", state.filter_min_conf or 0.0, 0.0, 1.0, "%.2f")
  if changed_conf then
    state.filter_min_conf = new_conf
  end

  local changed_rows, new_rows = r.ImGui_InputInt(ctx, "max. Zeilen in Ansicht", state.max_rows or 500)
  if changed_rows then
    if new_rows < 50 then new_rows = 50 end
    if new_rows > 5000 then new_rows = 5000 end
    state.max_rows = new_rows
  end

  if state.last_stats ~= "" then
    r.ImGui_Text(ctx, state.last_stats)
  end
end

local function draw_actions()
  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Quick-Actions auf aktuelle Filter-View:")

  if r.ImGui_Button(ctx, "View -> REVIEW_OK_MANUAL") then
    apply_flag_to_view("REVIEW_OK_MANUAL")
  end

  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "View -> REVIEW_PROBLEM") then
    apply_flag_to_view("REVIEW_PROBLEM")
  end

  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "View -> ai_status=manual") then
    apply_status_to_view("manual")
  end

  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Filter neu berechnen") then
    rebuild_filtered_indices()
  end

  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "View -> AutoIngest Subset schreiben") then
    write_autoingest_subset_from_view()
  end

  if r.ImGui_Button(ctx, "DB speichern") then
    save_db()
  end
end

local function draw_items_list()
  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Items (aktuelle Filter-View):")

  if not state.items or not state.filtered_indices or #state.filtered_indices == 0 then
    r.ImGui_Text(ctx, "(keine Items für aktuellen Filter)")
    return
  end

  local max_rows = state.max_rows or 500
  local count = #state.filtered_indices
  if count > max_rows then count = max_rows end

  -- Kopfzeile
  r.ImGui_Columns(ctx, 8, "df95_ai_inspector_cols", true)
  r.ImGui_Text(ctx, "Idx");          r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "Flag");         r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "Conf");         r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "Status");       r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "HomeZone");     r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "UCS/CatID");    r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "Name");         r.ImGui_NextColumn(ctx)
  r.ImGui_Text(ctx, "Path");         r.ImGui_NextColumn(ctx)
  r.ImGui_Separator(ctx)

  for i = 1, count do
    local idx = state.filtered_indices[i]
    local it = state.items[idx]

    local flag = norm_flag(it.df95_ai_review_flag)
    if flag == "" then flag = "(none)" end
    local c = tonumber(it.df95_ai_confidence or 0.0) or 0.0
    if c < 0.0 then c = 0.0 end
    if c > 1.0 then c = 1.0 end
    local status = norm_status(it.ai_status)

    local hz  = safe_str(it.home_zone)
    local hzs = safe_str(it.home_zone_sub)
    local ucs = safe_str(it.ucs_category)
    local cat = safe_str(it.df95_catid)
    local name = safe_str(it.name)
    local path = safe_str(it.filepath)

    local hz_full = hz
    if hzs ~= "" then
      hz_full = hz_full .. "/" .. hzs
    end

    local ucs_full = ucs
    if cat ~= "" then
      if ucs_full ~= "" then
        ucs_full = ucs_full .. " / " .. cat
      else
        ucs_full = cat
      end
    end

    r.ImGui_Text(ctx, tostring(idx));      r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, flag);             r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, string.format("%.3f", c)); r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, status);           r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, hz_full);          r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, ucs_full);         r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, name);             r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, path);             r.ImGui_NextColumn(ctx)
  end

  r.ImGui_Columns(ctx, 1)
end

local function loop()
  load_font()
  r.ImGui_SetNextWindowSize(ctx, 1100, 650, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 SampleDB Inspector V5 – AI/Review", true)
  if visible then
    if font then r.ImGui_PushFont(ctx, font) end

    r.ImGui_Text(ctx, "DF95 SampleDB Inspector V5 – AI/Review")
    r.ImGui_Separator(ctx)

    draw_filters()
    draw_actions()
    draw_items_list()

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
