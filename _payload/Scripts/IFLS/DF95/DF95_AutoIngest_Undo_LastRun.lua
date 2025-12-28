-- @description DF95 AutoIngest Undo Last Run
-- @version 1.0
-- @author DF95
-- @about
--   Liest den letzten AutoIngest ChangeLog-Eintrag (SAFE/AGGR) aus
--   DF95_AutoIngest_ChangeLog.jsonl und setzt die betroffenen Felder
--   (df95_ai_review_flag, ai_status, df95_ai_confidence, home_zone(_sub),
--    ucs_category, df95_catid) für die jeweiligen Items wieder
--   auf den "before"-Zustand zurück.
--
--   Achtung:
--     * Erwartet, dass die Filepaths in der DB noch gültig sind.
--     * Schreibt die SampleDB zurück.
--     * Markiert den verwendeten Log-Eintrag als "undone = true".

local r = reaper

------------------------------------------------------------
-- Paths / JSON helpers
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

local function get_changelog_path()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local dir = res
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    dir = dir .. sep
  end
  dir = dir .. "Support" .. sep .. "DF95_SampleDB"
  return dir .. sep .. "DF95_AutoIngest_ChangeLog.jsonl"
end

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
      for k2,v2 in pairs(v) do
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
-- Load last changelog entry
------------------------------------------------------------

local function load_last_run()
  local path = get_changelog_path()
  local f, err = io.open(path, "r")
  if not f then
    return nil, "ChangeLog nicht gefunden: " .. tostring(err or "unbekannt")
  end
  local lines = {}
  for line in f:lines() do
    if line:match("%S") then
      lines[#lines+1] = line
    end
  end
  f:close()

  if #lines == 0 then
    return nil, "ChangeLog ist leer."
  end

  -- decode all entries to allow marking "undone"
  local entries = {}
  for i, line in ipairs(lines) do
    local obj, derr = decode_json(line)
    if obj then
      entries[#entries+1] = {obj=obj, raw=line}
    else
      -- skip invalid line
    end
  end

  if #entries == 0 then
    return nil, "ChangeLog enthält keine gültigen JSON-Einträge."
  end

  -- last non-undone SAFE/AGGR entry
  for i = #entries, 1, -1 do
    local e = entries[i].obj
    if e and (e.mode == "SAFE" or e.mode == "AGGR") then
      if e.undone then
        -- überspringen, bereits rückgängig gemacht
      else
        return {
          idx     = i,
          entries = entries,
          path    = path,
          run     = e,
        }, nil
      end
    end
  end

  return nil, "Kein SAFE/AGGR-Lauf gefunden, der noch nicht rückgängig gemacht wurde."
end

------------------------------------------------------------
-- Load DB and build filepath->item map
------------------------------------------------------------

local function load_db()
  local db_path = get_default_db_path()
  local f, err = io.open(db_path, "r")
  if not f then
    return nil, nil, "DB nicht gefunden: " .. tostring(db_path) .. " (" .. tostring(err or "unbekannt") .. ")"
  end
  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    return nil, nil, "Fehler beim Dekodieren der DB: " .. tostring(derr or "unbekannt")
  end

  local items = db.items or db
  if type(items) ~= "table" then
    return nil, nil, "Unbekanntes DB-Format (erwarte db.items Array)."
  end

  local map = {}
  for _, it in ipairs(items) do
    local fp = tostring(it.filepath or "")
    if fp ~= "" then
      map[fp] = it
    end
  end

  return db, items, nil, map
end

------------------------------------------------------------
-- Apply undo
------------------------------------------------------------

local function apply_undo(run, db, items, map)
  if not run.items or #run.items == 0 then
    return 0
  end

  local restored = 0
  for _, ch in ipairs(run.items) do
    local fp = tostring(ch.filepath or (ch.before and ch.before.filepath) or "")
    if fp ~= "" then
      local it = map[fp]
      if it and ch.before then
        local b = ch.before
        it.df95_ai_review_flag = b.df95_ai_review_flag
        it.ai_status           = b.ai_status
        it.df95_ai_confidence  = b.df95_ai_confidence
        it.home_zone           = b.home_zone
        it.home_zone_sub       = b.home_zone_sub
        it.ucs_category        = b.ucs_category
        it.df95_catid          = b.df95_catid
        restored = restored + 1
      end
    end
  end

  return restored
end

local function save_db(db)
  local db_path = get_default_db_path()
  local out = encode_json_value(db, 0)
  local f, err = io.open(db_path, "w")
  if not f then
    return "Fehler beim Schreiben der DB: " .. tostring(err or "unbekannt")
  end
  f:write(out)
  f:close()
  return nil
end

local function save_changelog(entries, ctx)
  local path = ctx.path
  local f, err = io.open(path, "w")
  if not f then
    return "Fehler beim Aktualisieren des ChangeLogs: " .. tostring(err or "unbekannt")
  end
  for _, e in ipairs(entries) do
    local line = encode_json_value(e.obj, 0)
    f:write(line)
    f:write("\n")
  end
  f:close()
  return nil
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local ctx, err = load_last_run()
  if not ctx then
    r.ShowMessageBox("Undo nicht möglich:\n" .. tostring(err or "unbekannt"), "DF95 AutoIngest Undo", 0)
    return
  end

  local run = ctx.run
  if not run.items or #run.items == 0 then
    r.ShowMessageBox("Letzter Lauf hat keine Änderungen geloggt – nichts rückgängig zu machen.", "DF95 AutoIngest Undo", 0)
    return
  end

  local db, items, dberr, map = load_db()
  if not db then
    r.ShowMessageBox("DB konnte nicht geladen werden:\n" .. tostring(dberr or "unbekannt"), "DF95 AutoIngest Undo", 0)
    return
  end

  local restored = apply_undo(run, db, items, map)
  if restored == 0 then
    r.ShowMessageBox("Keine Items konnten anhand des ChangeLogs gefunden werden.\nWurden die Pfade/Items seitdem verändert?", "DF95 AutoIngest Undo", 0)
    return
  end

  local serr = save_db(db)
  if serr then
    r.ShowMessageBox("DB konnte nach Undo nicht geschrieben werden:\n" .. tostring(serr), "DF95 AutoIngest Undo", 0)
    return
  end

  -- Mark run as undone und speichere ChangeLog
  run.undone = true
  local cerr = save_changelog(ctx.entries, ctx)
  if cerr then
    r.ShowMessageBox("Undo war in der DB erfolgreich, aber das ChangeLog konnte nicht aktualisiert werden:\n" .. tostring(cerr), "DF95 AutoIngest Undo", 0)
    return
  end

  local msg = {}
  msg[#msg+1] = "AutoIngest-Lauf rückgängig gemacht."
  msg[#msg+1] = ""
  msg[#msg+1] = "Mode       : " .. tostring(run.mode or "(nil)")
  msg[#msg+1] = "Timestamp  : " .. tostring(run.ts or "(none)")
  msg[#msg+1] = string.format("Items (geloggt): %d", #(run.items or {}))
  msg[#msg+1] = string.format("Items (restored): %d", restored)
  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 AutoIngest Undo", 0)
end

main()
