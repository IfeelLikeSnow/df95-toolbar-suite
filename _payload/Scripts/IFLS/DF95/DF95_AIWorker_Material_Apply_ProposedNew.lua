-- @description DF95 AIWorker Material – Apply ProposedNew to SampleDB
-- @version 1.0
-- @author DF95
-- @about
--   Liest ein AIWorker-Result (Material-Mode) und trägt nur dort
--   df95_material/df95_instrument in die DF95 Multi-UCS SampleDB ein,
--   wo bisher noch KEINE Material-/Instrument-Information steht.
--
--   Wichtig:
--     - Konflikte (bestehender Wert != AI-Vorschlag) werden NICHT automatisch
--       geändert. Diese sollen im DF95_AIWorker_Material_Conflict_ImGui
--       geprüft werden.
--     - Es wird vor dem Schreiben ein Backup der SampleDB angelegt:
--         DF95_SampleDB_Multi_UCS_backup_MaterialApply_YYYYMMDD_HHMMSS.json
--
--   Erwartete Pfade:
--     SampleDB:
--       <REAPER Resource Path>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--     AIWorker Results:
--       <REAPER Resource Path>/Support/DF95_AIWorker/Results/DF95_AIWorker_UCSResult_*.json
--
--   Workflow:
--     1) AIWorker Material-Mode laufen lassen (Python Worker)
--     2) Result-JSON landet im Results-Ordner
--     3) Dieses Script ausführen:
--          - nimmt das neueste Result-JSON
--          - wendet nur "proposed_new"-Änderungen an
--
--   Hinweis:
--     Benötigt keine externen JSON-Libraries; Decoder/Encoder sind integriert.
--

local r = reaper

------------------------------------------------------------
-- Helpers: Pfade, String
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\" then
    a = a .. sep
  end
  return a .. b
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_default_db_path()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function get_results_dir()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_AIWorker")
  return join_path(dir, "Results")
end

local function norm_path(p)
  if not p or p == "" then return "" end
  p = p:gsub("\\", "/"):gsub("\\", "/"):gsub("\\", "/")
  return p:lower()
end

local function trim(s)
  if not s then return "" end
  return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

------------------------------------------------------------
-- JSON Decoder / Encoder (leichtgewichtige Variante)
--   identisch zur Logik im Inspector V5 AI/Review
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
      table.insert(parts, "[
")
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
-- DB-Load/Save
------------------------------------------------------------

local function load_db(db_path)
  local f, err = io.open(db_path, "r")
  if not f then
    return nil, "Kann DB nicht öffnen: " .. tostring(err or "unbekannt")
  end
  local text = f:read("*a")
  f:close()

  local data, derr = decode_json(text)
  if not data then
    return nil, "JSON-Decode-Fehler: " .. tostring(derr or "unbekannt")
  end
  return data
end

local function save_db(db_path, db_data)
  local out_text = encode_json_value(db_data, 0)
  local f, err = io.open(db_path, "w")
  if not f then
    return false, "Fehler beim Schreiben der DB: " .. tostring(err or "unbekannt")
  end
  f:write(out_text)
  f:close()
  return true
end

------------------------------------------------------------
-- AIWorker Result laden
------------------------------------------------------------

local function load_result_json(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, "Kann Result-JSON nicht öffnen: " .. tostring(err or "unbekannt")
  end
  local text = f:read("*a")
  f:close()
  local data, derr = decode_json(text)
  if not data then
    return nil, "JSON-Decode-Fehler im Result: " .. tostring(derr or "unbekannt")
  end
  return data
end

local function find_latest_result(results_dir)
  local last_name = nil
  local last_time = -1

  local i = 0
  while true do
    local fname = r.EnumerateFiles(results_dir, i)
    if not fname then break end
    if fname:lower():match("%.json$") and fname:find("DF95_AIWorker_UCSResult_", 1, true) then
      local full = join_path(results_dir, fname)
      local attr = r.EnumerateFiles and nil
      -- REAPER hat keinen direkten mtime-Zugriff via ReaScript, also
      -- nehmen wir einfach die lexikographische Sortierung als Proxy:
      if not last_name or fname > last_name then
        last_name = fname
      end
    end
    i = i + 1
  end

  if not last_name then return nil end
  return join_path(results_dir, last_name)
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  local db_path = get_default_db_path()
  if not file_exists(db_path) then
    r.ShowMessageBox("SampleDB nicht gefunden:\n" .. tostring(db_path),
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  local results_dir = get_results_dir()
  if not file_exists(results_dir) then
    r.ShowMessageBox("Results-Ordner nicht gefunden:\n" .. tostring(results_dir),
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  local result_path = find_latest_result(results_dir)
  if not result_path or not file_exists(result_path) then
    r.ShowMessageBox("Kein AIWorker Result-JSON (DF95_AIWorker_UCSResult_*.json) im Results-Ordner gefunden.",
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  local ret = r.ShowMessageBox(
    "Dieses Script wird nur df95_material/df95_instrument setzen,\n"
    .. "wo bisher noch keine Werte in der DB stehen.\n\n"
    .. "Konflikte (bestehende Werte != AI-Vorschlag) werden NICHT automatisch geändert.\n\n"
    .. "Result-Datei:\n"
    .. result_path .. "\n\n"
    .. "Fortfahren?",
    "DF95 AIWorker Material – Apply ProposedNew",
    4 -- Yes/No
  )
  if ret ~= 6 then return end -- 6 = IDYES

  -- DB laden
  local db, derr = load_db(db_path)
  if not db then
    r.ShowMessageBox("Fehler beim Laden der DB:\n" .. tostring(derr),
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  local items = db.items
  if type(items) ~= "table" then
    -- möglicherweise reine Liste
    items = db
  end
  if type(items) ~= "table" then
    r.ShowMessageBox("Unerwartetes DB-Format (weder db.items noch db als Liste).",
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  -- Map: full_path -> item
  local map = {}
  for _, it in ipairs(items) do
    local cand = it.full_path or it.path or it.file or ""
    if cand ~= "" then
      map[norm_path(cand)] = it
    end
  end

  -- Result laden
  local res_data, rerr = load_result_json(result_path)
  if not res_data then
    r.ShowMessageBox("Fehler beim Laden des Result-JSON:\n" .. tostring(rerr),
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  local results = res_data.results
  if type(results) ~= "table" then
    r.ShowMessageBox("Result-JSON hat kein Feld 'results' (Liste).",
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  local MIN_CONF = 0.7
  local changed = 0
  local total_proposed = 0

  for _, res in ipairs(results) do
    local full = res.full_path or res.path or ""
    if full ~= "" then
      local key = norm_path(full)
      local item = map[key]
      if item then
        local ai_conf = tonumber(res.ai_confidence or 0.0) or 0.0
        if ai_conf >= MIN_CONF then
          local new_mat = trim(res.df95_material or "")
          local new_ins = trim(res.df95_instrument or "")
          if new_mat ~= "" or new_ins ~= "" then
            local old_mat = trim(item.df95_material or "")
            local old_ins = trim(item.df95_instrument or "")

            if old_mat == "" and old_ins == "" then
              -- "ProposedNew"-Fall: AI schlägt Werte für bislang leere Felder vor
              total_proposed = total_proposed + 1
              item.df95_material = new_mat ~= "" and new_mat or nil
              item.df95_instrument = new_ins ~= "" and new_ins or nil
              changed = changed + 1
            end
          end
        end
      end
    end
  end

  if changed == 0 then
    r.ShowMessageBox("Keine 'proposed new' Material/Instrument-Einträge gefunden,\n"
      .. "die den Confidence-Threshold (" .. tostring(MIN_CONF) .. ") erfüllen.",
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  -- Backup anlegen
  local db_dir = get_default_db_path():match("^(.*)[/\\][^/\\]+$")
  local ts = os.date("%Y%m%d_%H%M%S")
  local backup_name = "DF95_SampleDB_Multi_UCS_backup_MaterialApply_" .. ts .. ".json"
  local backup_path = join_path(db_dir, backup_name)
  local src_f = io.open(db_path, "rb")
  if src_f then
    local content = src_f:read("*a")
    src_f:close()
    local bf = io.open(backup_path, "wb")
    if bf then
      bf:write(content)
      bf:close()
    end
  end

  -- DB speichern
  local ok, serr = save_db(db_path, db)
  if not ok then
    r.ShowMessageBox("Fehler beim Schreiben der DB:\n" .. tostring(serr or "unbekannt"),
      "DF95 AIWorker Material – Apply ProposedNew", 0)
    return
  end

  r.ShowMessageBox(
    "Material/Instrument 'proposed new' angewendet.\n\n"
    .. "Geänderte Items: " .. tostring(changed) .. "\n"
    .. "Gefundene ProposedNew-Fälle (vor Filter): " .. tostring(total_proposed) .. "\n\n"
    .. "Backup: " .. backup_path,
    "DF95 AIWorker Material – Apply ProposedNew",
    0
  )
end

main()
