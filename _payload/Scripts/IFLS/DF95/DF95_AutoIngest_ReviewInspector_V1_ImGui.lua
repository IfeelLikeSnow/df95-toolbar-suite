-- @description DF95 AutoIngest Review Inspector V1 (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Zeigt Items der DF95 Multi-UCS SampleDB (DF95_SampleDB_Multi_UCS.json)
--   mit Fokus auf:
--     * df95_ai_review_flag  (OK_HIGH / REVIEW_MED / REVIEW_LOW / REVIEW_*)
--     * df95_ai_confidence   (0.0–1.0)
--     * ai_status            (auto_safe / auto_high / auto_med / manual / ...)
--   Filterbar nach Review-Flag & Min-Confidence.
--   Buttons pro Item:
--     * Mark as OK (setzt REVIEW_OK_MANUAL)
--     * Mark as Problem (setzt REVIEW_PROBLEM)
--
--   Gedacht als manueller Review-Layer nach AutoIngest V3.

local r = reaper

local ctx = r.ImGui_CreateContext('DF95 AutoIngest ReviewInspector V1')
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

------------------------------------------------------------
-- JSON Helper (gleiche Logik wie in AutoIngest V3)
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

local function encode_json_table(t, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)
  local parts = {}

  if type(t) ~= "table" then
    if type(t) == "string" then
      return string.format("%q", t)
    elseif type(t) == "number" then
      return tostring(t)
    elseif type(t) == "boolean" then
      return t and "true" or "false"
    else
      return "null"
    end
  end

  local is_array = true
  local max_index = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then
      is_array = false
      break
    else
      if k > max_index then max_index = k end
    end
  end

  if is_array then
    table.insert(parts, "[\n")
    for i = 1, max_index do
      local v = t[i]
      table.insert(parts, pad .. "  " .. encode_json_table(v, indent+1))
      if i < max_index then table.insert(parts, ",") end
      table.insert(parts, "\n")
    end
    table.insert(parts, pad .. "]")
  else
    table.insert(parts, "{\n")
    local first = true
    for k, v in pairs(t) do
      if not first then
        table.insert(parts, ",\n")
      end
      first = false
      table.insert(parts, pad .. "  " .. string.format("%q", tostring(k)) .. ": " .. encode_json_table(v, indent+1))
    end
    table.insert(parts, "\n" .. pad .. "}")
  end

  return table.concat(parts)
end

local function is_nonempty(v)
  return v ~= nil and v ~= ""
end

------------------------------------------------------------
-- State
------------------------------------------------------------

local state = {
  db_path = "",
  db = nil,
  items = {},
  filter_text = "",
  filter_flag = "ALL",
  conf_min = 0.0,
  last_msg = "",
}

local flag_options = {
  "ALL",
  "OK_HIGH",
  "REVIEW_MED",
  "REVIEW_LOW",
  "REVIEW_PROBLEM",
  "REVIEW_OK_MANUAL",
}

------------------------------------------------------------
-- Load / Save
------------------------------------------------------------

local function load_db()
  local path = (state.db_path or ""):gsub("^%s+",""):gsub("%s+$","")
  if path == "" then
    path = get_default_db_path()
    state.db_path = path
  end

  local f, err = io.open(path, "r")
  if not f then
    state.last_msg = "Fehler beim Öffnen der DB: " .. tostring(err or "unbekannt")
    return
  end
  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    state.last_msg = "Fehler beim Dekodieren der DB: " .. tostring(derr or "unbekannt")
    return
  end

  local items = db.items or db
  if type(items) ~= "table" then
    state.last_msg = "DB enthält keine items-Tabelle."
    return
  end

  state.db = db
  state.items = items
  state.last_msg = string.format("DB geladen: %s (%d Items)", path, #items)
end

local function save_db()
  if not state.db then
    state.last_msg = "Keine DB im Speicher."
    return
  end
  local path = state.db_path or get_default_db_path()
  local text = encode_json_table(state.db, 0)
  local f, err = io.open(path, "w")
  if not f then
    state.last_msg = "Fehler beim Schreiben: " .. tostring(err or "unbekannt")
    return
  end
  f:write(text)
  f:close()
  state.last_msg = "DB gespeichert."
end

------------------------------------------------------------
-- Filter
------------------------------------------------------------

local function passes_filters(it)
  local ftxt = (state.filter_text or ""):lower()
  if ftxt ~= "" then
    local name = (it.name or it.filepath or ""):lower()
    if not name:find(ftxt, 1, true) then
      return false
    end
  end

  local conf = tonumber(it.df95_ai_confidence or 0.0) or 0.0
  if conf < (state.conf_min or 0.0) then
    return false
  end

  local flag = tostring(it.df95_ai_review_flag or ""):upper()
  local fflag = state.filter_flag or "ALL"
  if fflag ~= "ALL" then
    if flag ~= fflag then
      return false
    end
  end

  return true
end

------------------------------------------------------------
-- UI Row
------------------------------------------------------------

local function draw_item_row(it, idx)
  r.ImGui_TableNextRow(ctx)
  r.ImGui_TableSetColumnIndex(ctx, 0)
  r.ImGui_Text(ctx, tostring(idx))

  r.ImGui_TableSetColumnIndex(ctx, 1)
  r.ImGui_Text(ctx, it.name or it.filepath or "(ohne Name)")

  r.ImGui_TableSetColumnIndex(ctx, 2)
  local session = (it.session_location or "") .. " / " .. (it.session_subzone or "") .. " / " .. (it.session_scene or "")
  r.ImGui_TextWrapped(ctx, session)

  r.ImGui_TableSetColumnIndex(ctx, 3)
  local home = (it.home_zone or "") .. " / " .. (it.home_zone_sub or "")
  r.ImGui_TextWrapped(ctx, home)

  r.ImGui_TableSetColumnIndex(ctx, 4)
  local ucs = (it.ucs_category or "") .. " | " .. (it.df95_catid or "")
  r.ImGui_TextWrapped(ctx, ucs)

  r.ImGui_TableSetColumnIndex(ctx, 5)
  local conf = tonumber(it.df95_ai_confidence or 0.0) or 0.0
  local label = string.format("%.2f", conf)
  if is_nonempty(it.ai_status) then
    label = label .. " (" .. tostring(it.ai_status) .. ")"
  end
  r.ImGui_Text(ctx, label)

  r.ImGui_TableSetColumnIndex(ctx, 6)
  local flag = tostring(it.df95_ai_review_flag or "")
  r.ImGui_Text(ctx, flag ~= "" and flag or "(none)")

  r.ImGui_TableSetColumnIndex(ctx, 7)
  if r.ImGui_SmallButton(ctx, "Mark as OK##" .. tostring(idx)) then
    it.df95_ai_review_flag = "REVIEW_OK_MANUAL"
    state.last_msg = "Item " .. tostring(idx) .. " als REVIEW_OK_MANUAL markiert."
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_SmallButton(ctx, "Problem##" .. tostring(idx)) then
    it.df95_ai_review_flag = "REVIEW_PROBLEM"
    state.last_msg = "Item " .. tostring(idx) .. " als REVIEW_PROBLEM markiert."
  end
end

------------------------------------------------------------
-- Main UI Loop
------------------------------------------------------------

local function loop()
  load_font()
  r.ImGui_SetNextWindowSize(ctx, 1200, 640, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 AutoIngest ReviewInspector V1", true)
  if visible then
    if font then r.ImGui_PushFont(ctx, font) end

    r.ImGui_Text(ctx, "DF95 AutoIngest ReviewInspector V1 – ReviewFlags / Confidence / ai_status")
    r.ImGui_Separator(ctx)

    if state.db_path == "" then
      state.db_path = get_default_db_path()
    end

    local changed, new_path = r.ImGui_InputText(ctx, "DB-Pfad (Multi-UCS JSON)", state.db_path or "", 1024)
    if changed then
      state.db_path = new_path
    end

    if r.ImGui_Button(ctx, "DB laden") then
      load_db()
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "DB speichern") then
      save_db()
    end

    r.ImGui_Separator(ctx)

    local ft_changed, ftxt = r.ImGui_InputText(ctx, "Filter (Name/Filepath)", state.filter_text or "", 256)
    if ft_changed then
      state.filter_text = ftxt
    end

    local conf_changed, conf_val = r.ImGui_SliderDouble(ctx, "Min. Confidence", state.conf_min or 0.0, 0.0, 1.0, "%.2f")
    if conf_changed then
      state.conf_min = conf_val
    end

    local current_flag_index = 0
    for i, v in ipairs(flag_options) do
      if v == state.filter_flag then
        current_flag_index = i - 1
        break
      end
    end
    local combo_str = table.concat(flag_options, "\0")
    local combo_changed, new_index = r.ImGui_Combo(ctx, "ReviewFlag Filter", current_flag_index, combo_str)
    if combo_changed then
      state.filter_flag = flag_options[new_index + 1] or "ALL"
    end

    r.ImGui_Separator(ctx)

    local items = state.items or {}
    if #items == 0 then
      r.ImGui_Text(ctx, "Noch keine Items geladen. AutoIngest V3 (ANALYZE/SAFE/AGGR) ausführen, dann hier öffnen.")
    else
      local flags = r.ImGui_TableFlags_Borders()
                 | r.ImGui_TableFlags_RowBg()
                 | r.ImGui_TableFlags_ScrollY()
                 | r.ImGui_TableFlags_Resizable()
      local avail_w, avail_h = r.ImGui_GetContentRegionAvail(ctx)
      if r.ImGui_BeginTable(ctx, "DF95_REVIEW_ITEMS", 8, flags, avail_w, avail_h - 80) then
        r.ImGui_TableSetupScrollFreeze(ctx, 0, 1)
        r.ImGui_TableSetupColumn(ctx, "#", r.ImGui_TableColumnFlags_WidthFixed(), 40)
        r.ImGui_TableSetupColumn(ctx, "Name", r.ImGui_TableColumnFlags_WidthStretch(), 200)
        r.ImGui_TableSetupColumn(ctx, "Session", r.ImGui_TableColumnFlags_WidthStretch(), 220)
        r.ImGui_TableSetupColumn(ctx, "HomeZone", r.ImGui_TableColumnFlags_WidthStretch(), 220)
        r.ImGui_TableSetupColumn(ctx, "UCS/CatID", r.ImGui_TableColumnFlags_WidthStretch(), 220)
        r.ImGui_TableSetupColumn(ctx, "Confidence / ai_status", r.ImGui_TableColumnFlags_WidthFixed(), 180)
        r.ImGui_TableSetupColumn(ctx, "ReviewFlag", r.ImGui_TableColumnFlags_WidthFixed(), 140)
        r.ImGui_TableSetupColumn(ctx, "Aktion", r.ImGui_TableColumnFlags_WidthFixed(), 220)
        r.ImGui_TableHeadersRow(ctx)

        local shown = 0
        for idx, it in ipairs(items) do
          if passes_filters(it) then
            draw_item_row(it, idx)
            shown = shown + 1
          end
        end

        r.ImGui_EndTable(ctx)
        r.ImGui_Text(ctx, string.format("Angezeigte Items: %d / %d", shown, #items))
      end
    end

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
