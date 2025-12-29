-- @description DF95 SampleDB Migrate V2 -> V3 (AI-Felder & Defaults)
-- @version 1.0
-- @author DF95
-- @about
--   Aktualisiert die DF95 Multi-UCS SampleDB (DF95_SampleDB_Multi_UCS.json)
--   von einem älteren Schema (V2) auf V3, indem:
--     * df95_ai_confidence auf 0.0 gesetzt wird, falls fehlt
--     * ai_status auf "legacy" gesetzt wird, falls fehlt
--     * df95_ai_review_flag auf "(none)" gesetzt wird, falls fehlt
--     * leere Home-/Session-Felder auf "" normalisiert werden (statt nil)
--
--   Optional kann eine Backup-Kopie der DB geschrieben werden.

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

local function trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
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

------------------------------------------------------------
-- Migration
------------------------------------------------------------

local function main()
  local db_path = get_default_db_path()
  local defaults = db_path .. ",1"

  local ok, csv = r.GetUserInputs(
    "DF95 SampleDB Migrate V2 -> V3",
    2,
    "DB-Pfad (leer=Default),Backup-Kopie anlegen? (0/1)",
    defaults
  )
  if not ok then return end

  local path_str, backup_flag_str = csv:match("([^,]*),([^,]*)")
  path_str = trim(path_str)
  backup_flag_str = trim(backup_flag_str)

  if path_str == "" then
    path_str = db_path
  end

  local make_backup = tonumber(backup_flag_str) == 1

  local f, err = io.open(path_str, "r")
  if not f then
    r.ShowMessageBox("DB nicht gefunden:\n" .. tostring(path_str) .. "\n\n" .. tostring(err or ""), "DF95 SampleDB Migrate V2 -> V3", 0)
    return
  end
  local text = f:read("*all")
  f:close()

  if make_backup then
    local backup_path = path_str .. ".backup_V2_" .. os.date("%Y%m%d_%H%M%S")
    local bf, berr = io.open(backup_path, "w")
    if bf then
      bf:write(text)
      bf:close()
    else
      r.ShowMessageBox("Konnte Backup nicht schreiben:\n" .. tostring(backup_path) .. "\n\n" .. tostring(berr or ""), "DF95 SampleDB Migrate V2 -> V3", 0)
    end
  end

  local db, derr = decode_json(text)
  if not db then
    r.ShowMessageBox("Fehler beim Lesen/Dekodieren der DB:\n" .. tostring(derr or "unbekannt"), "DF95 SampleDB Migrate V2 -> V3", 0)
    return
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    r.ShowMessageBox("DB enthält keine Items oder unbekanntes Format.", "DF95 SampleDB Migrate V2 -> V3", 0)
    return
  end

  local total = #items

  local function norm_str(v)
    if v == nil then return "" end
    return tostring(v)
  end

  local cnt_ai_conf_added = 0
  local cnt_ai_status_added = 0
  local cnt_ai_flag_added = 0

  local cnt_home_norm = 0
  local cnt_session_norm = 0

  for _, it in ipairs(items) do
    if it.df95_ai_confidence == nil then
      it.df95_ai_confidence = 0.0
      cnt_ai_conf_added = cnt_ai_conf_added + 1
    end
    if it.ai_status == nil or it.ai_status == "" then
      it.ai_status = "legacy"
      cnt_ai_status_added = cnt_ai_status_added + 1
    end
    if it.df95_ai_review_flag == nil then
      it.df95_ai_review_flag = "(none)"
      cnt_ai_flag_added = cnt_ai_flag_added + 1
    end

    local hz = it.home_zone
    local hzs = it.home_zone_sub
    local sl = it.session_location
    local ss = it.session_subzone
    local sc = it.session_scene

    local changed_home = false
    local changed_session = false

    if hz == nil then
      it.home_zone = ""
      changed_home = true
    end
    if hzs == nil then
      it.home_zone_sub = ""
      changed_home = true
    end
    if sl == nil then
      it.session_location = ""
      changed_session = true
    end
    if ss == nil then
      it.session_subzone = ""
      changed_session = true
    end
    if sc == nil then
      it.session_scene = ""
      changed_session = true
    end

    if changed_home then
      cnt_home_norm = cnt_home_norm + 1
    end
    if changed_session then
      cnt_session_norm = cnt_session_norm + 1
    end
  end

  local out_text = encode_json_table(db, 0)
  local wf, werr = io.open(path_str, "w")
  if not wf then
    r.ShowMessageBox("Fehler beim Schreiben der DB:\n" .. tostring(werr or "unbekannt"), "DF95 SampleDB Migrate V2 -> V3", 0)
    return
  end
  wf:write(out_text)
  wf:close()

  local msg = {}
  msg[#msg+1] = "DF95 SampleDB Migrate V2 -> V3 abgeschlossen."
  msg[#msg+1] = "DB: " .. tostring(path_str)
  msg[#msg+1] = string.format("Items gesamt: %d", total)
  msg[#msg+1] = ""
  msg[#msg+1] = string.format("df95_ai_confidence ergänzt: %d", cnt_ai_conf_added)
  msg[#msg+1] = string.format("ai_status auf 'legacy' gesetzt: %d", cnt_ai_status_added)
  msg[#msg+1] = string.format("df95_ai_review_flag ergänzt: %d", cnt_ai_flag_added)
  msg[#msg+1] = ""
  msg[#msg+1] = string.format("home_zone/home_zone_sub normalisiert (nil -> \"\"): %d Items", cnt_home_norm)
  msg[#msg+1] = string.format("session_* normalisiert (nil -> \"\"): %d Items", cnt_session_norm)

  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 SampleDB Migrate V2 -> V3", 0)
end

main()
