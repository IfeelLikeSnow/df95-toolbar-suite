
-- @description DF95_V160 SampleDB AI-Worker – ZoomF6 (Heuristik + Hooks)
-- @author DF95
-- @version 1.0
-- @about
--   Liest die DF95 SampleDB Multi-UCS, findet Einträge mit ai_status="pending"
--   (typisch: ZoomF6 PolyWAVs) und ergänzt ai_tags / ai_model / ai_last_update.
--   Aktuell Regel-basiert (Heuristik), aber mit klaren Hooks für spätere
--   ML-Modelle (YAMNet, CLAP, etc.).

local r = reaper

------------------------------------------------------------
-- Pfade / Helpers
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function get_resource_path()
  return r.GetResourcePath()
end

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_db_path_multi_ucs()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return dir, join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function ensure_dir(path)
  if r.GetFileAttributes then
    local attr = r.GetFileAttributes(path)
    if attr then return true end
  end
  if sep == "\\" then
    os.execute(string.format('mkdir "%s"', path))
  else
    os.execute(string.format('mkdir -p "%s"', path))
  end
  return true
end

------------------------------------------------------------
-- Einfacher JSON-Codec (kompatibel mit DF95)
------------------------------------------------------------

local function json_decode_simple(str)
  if not str or str == "" then return nil end
  local ok, res = pcall(function()
    return load("return " .. str, "json", "t", {})()
  end)
  if ok then return res end
  return nil
end

local function json_encode_simple(v, indent)
  indent = indent or ""
  local function json_escape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub("\"","\\\""):gsub("\n","\\n")
    return s
  end

  local function encode_any(val, ind)
    ind = ind or ""
    local next_indent = ind .. "  "
    if type(val) == "table" then
      if #val > 0 then
        local parts = {"[\n"}
        for i, item in ipairs(val) do
          table.insert(parts, next_indent .. encode_any(item, next_indent))
          if i < #val then table.insert(parts, ",") end
          table.insert(parts, "\n")
        end
        table.insert(parts, ind .. "]")
        return table.concat(parts)
      else
        local parts = {"{\n"}
        local first = true
        for k, item in pairs(val) do
          if not first then table.insert(parts, ",\n") end
          first = false
          table.insert(parts, next_indent ..
            "\"" .. json_escape(k) .. "\": " .. encode_any(item, next_indent))
        end
        table.insert(parts, "\n"..ind.."}")
        return table.concat(parts)
      end
    elseif type(val) == "string" then
      return "\"" .. json_escape(val) .. "\""
    elseif type(val) == "number" then
      return tostring(val)
    elseif type(val) == "boolean" then
      return val and "true" or "false"
    else
      return "null"
    end
  end

  return encode_any(v, indent)
end

------------------------------------------------------------
-- DB-Load / Save
------------------------------------------------------------

local function load_sampledb_multi_ucs()
  local dir, db_path = get_db_path_multi_ucs()
  ensure_dir(dir)
  local f = io.open(db_path, "r")
  if not f then
    return {
      version = "DF95_MultiUCS_Auto",
      created = os.date("%Y-%m-%d %H:%M:%S"),
      items   = {},
    }, db_path
  end
  local content = f:read("*a")
  f:close()
  local db = json_decode_simple(content)
  if type(db) ~= "table" then
    db = {
      version = "DF95_MultiUCS_Auto",
      created = os.date("%Y-%m-%d %H:%M:%S"),
      items   = {},
    }
  end
  if type(db.items) ~= "table" then
    db.items = {}
  end
  return db, db_path
end

local function save_sampledb_multi_ucs(db, db_path)
  local f = io.open(db_path, "w")
  if not f then
    r.ShowMessageBox(
      "Kann DF95 SampleDB Multi-UCS nicht schreiben:\n"..tostring(db_path),
      "DF95 SampleDB AI-Worker", 0)
    return false
  end
  f:write(json_encode_simple(db, ""))
  f:close()
  return true
end

------------------------------------------------------------
-- Heuristische AI-Tagging-Logik
------------------------------------------------------------

local function add_tag(set, tag)
  if not tag or tag == "" then return end
  set[tag] = true
end

local function set_to_array(set)
  local arr = {}
  for k,_ in pairs(set) do arr[#arr+1] = k end
  table.sort(arr)
  return arr
end

local function heuristic_tags_for_item(item)
  local tags = {}
  local home   = (item.home_zone or ""):upper()
  local ucat   = (item.ucs_category or ""):upper()
  local usub   = (item.ucs_subcategory or ""):upper()
  local path   = (item.path or ""):lower()
  local roles  = (item.zoom_role_map or ""):lower()

  if ucat == "FIELDREC" then
    add_tag(tags, "fieldrec")
  end
  if usub == "ZOOMF6" then
    add_tag(tags, "zoomf6")
  end

  if roles:find("boom") then
    add_tag(tags, "dialogue")
    add_tag(tags, "voice")
    add_tag(tags, "boom")
  end
  if roles:find("lav") then
    add_tag(tags, "lav")
    add_tag(tags, "bodymic")
  end
  if roles:find("amb") then
    add_tag(tags, "ambience")
    add_tag(tags, "roomtone")
  end
  if roles:find("spare") then
    add_tag(tags, "spare")
  end

  if home == "KITCHEN" then
    add_tag(tags, "kitchen")
    add_tag(tags, "indoor")
  elseif home == "BATHROOM" then
    add_tag(tags, "bathroom")
    add_tag(tags, "tiles")
    add_tag(tags, "indoor")
  elseif home == "BEDROOM" then
    add_tag(tags, "bedroom")
    add_tag(tags, "soft")
    add_tag(tags, "indoor")
  elseif home == "CHILDROOM" then
    add_tag(tags, "childroom")
    add_tag(tags, "kids")
    add_tag(tags, "indoor")
  elseif home == "LIVINGROOM" then
    add_tag(tags, "livingroom")
    add_tag(tags, "indoor")
  elseif home == "BASEMENT" then
    add_tag(tags, "basement")
    add_tag(tags, "concrete")
  elseif home == "HALLWAY" then
    add_tag(tags, "hallway")
    add_tag(tags, "reverb")
  end

  if path:find("emf") or path:find("ether") or path:find("telephone_coil") or path:find("pick%-up") then
    add_tag(tags, "emf")
    add_tag(tags, "electric")
    add_tag(tags, "buzz")
  end

  if path:find("outdoor") or path:find("wald") or path:find("forest") then
    add_tag(tags, "outdoor")
  end

  return set_to_array(tags)
end

------------------------------------------------------------
-- Hook für zukünftige ML-Modelle (YAMNet, CLAP, etc.)
------------------------------------------------------------

local function run_ml_model_on_item(item)
  -- Platzhalter:
  -- Hier könntest du später ein externes Python-Script / Kommandozeilen-Tool
  -- aufrufen, das das File analysiert und Tags zurückgibt.
  --
  -- Beispielstruktur:
  --   return {"speech", "indoor", "small_room"}, "YAMNet_vX.Y"
  --
  -- Aktuell geben wir nil zurück -> Worker fällt auf Heuristik zurück.
  return nil, nil
end

------------------------------------------------------------
-- Main: AI-Worker über DB
------------------------------------------------------------

local function main()
  local db, db_path = load_sampledb_multi_ucs()
  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox("Keine Items in DF95 SampleDB Multi-UCS gefunden.", "DF95 AI-Worker", 0)
    return
  end

  local max_per_run = 32
  local processed   = 0
  local updated     = 0

  for idx, it in ipairs(items) do
    if it.ai_status == "pending" then
      processed = processed + 1

      local tags, model_name = run_ml_model_on_item(it)

      if not tags or #tags == 0 then
        tags = heuristic_tags_for_item(it)
        model_name = model_name or "DF95_RuleBased_v1"
        it.ai_status = "heuristic"
      else
        it.ai_status = "done"
      end

      it.ai_tags = tags
      it.ai_model = model_name
      it.ai_last_update = os.date("%Y-%m-%d %H:%M:%S")

      updated = updated + 1

      if processed >= max_per_run then
        break
      end
    end
  end

  if updated > 0 then
    save_sampledb_multi_ucs(db, db_path)
  end

  r.ShowMessageBox(
    string.format("DF95 AI-Worker ZoomF6:\nVerarbeitet: %d\nAktualisiert: %d\n(DB: %s)",
      processed, updated, db_path),
    "DF95 SampleDB AI-Worker", 0)
end

main()
