-- @description DF95_V161 SampleDB – AI Tag Browser
-- @version 1.0
-- @author DF95
-- @about
--   Kleines Tool, das die DF95 SampleDB Multi-UCS analysiert und eine Übersicht
--   aller vorkommenden AI-Tags (ai_tags / ai_labels) anzeigt:
--     * pro Tag: Anzahl Items
--     * optionaler Filter nach UCS-Category oder AI-Model
--
--   Datenquelle:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json

local r = reaper

------------------------------------------------------------
-- Pfade / JSON
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function decode_json(text)
  if not text or text == "" then return nil, "empty" end
  local f, err = load("return " .. text, "json", "t", {})
  if not f then return nil, err end
  local ok, res = pcall(f)
  if not ok then return nil, res end
  return res
end

------------------------------------------------------------
-- Tag-Browser Hauptlogik
------------------------------------------------------------

local function collect_tag_stats(items, filters)
  local stats = {}

  local function add(tag)
    if not tag or tag == "" then return end
    stats[tag] = (stats[tag] or 0) + 1
  end

  for _, it in ipairs(items) do
    if filters then
      if filters.ucs_cat then
        local uc = (it.ucs_category or ""):upper()
        if not uc:find(filters.ucs_cat:upper(), 1, true) then
          goto continue_item
        end
      end
      if filters.ai_model then
        local am = (it.ai_model or ""):upper()
        if not am:find(filters.ai_model:upper(), 1, true) then
          goto continue_item
        end
      end
    end

    if type(it.ai_tags) == "table" then
      for _, t in ipairs(it.ai_tags) do
        add(tostring(t or ""))
      end
    end
    if type(it.ai_labels) == "table" then
      for _, t in ipairs(it.ai_labels) do
        add(tostring(t or ""))
      end
    end

    ::continue_item::
  end

  local list = {}
  for tag, count in pairs(stats) do
    list[#list+1] = { tag = tag, count = count }
  end
  table.sort(list, function(a, b)
    if a.count == b.count then
      return a.tag < b.tag
    end
    return a.count > b.count
  end)
  return list
end

local function main()
  local db_path = get_db_path()
  local f = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "DF95 SampleDB Multi-UCS nicht gefunden:\n"..tostring(db_path),
      "DF95 AI Tag Browser",
      0
    )
    return
  end
  local text = f:read("*all")
  f:close()

  local db, err = decode_json(text)
  if not db then
    r.ShowMessageBox(
      "Fehler beim Lesen der JSON-Datenbank:\n"..tostring(err),
      "DF95 AI Tag Browser",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die JSON-Datenbank enthält keine Items.\n"..db_path,
      "DF95 AI Tag Browser",
      0
    )
    return
  end

  local ok, vals = r.GetUserInputs(
    "DF95 AI Tag Browser – Filter",
    2,
    "UCS Category-Filter (Substring, leer=alle),AI Model-Filter (Substring, leer=alle)",
    ","
  )
  if not ok then return end

  local s1, s2 = vals:match("([^,]*),([^,]*)")
  local function norm(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
  end

  local filters = {
    ucs_cat  = norm(s1),
    ai_model = norm(s2),
  }

  local stats = collect_tag_stats(items, filters)

  r.ShowConsoleMsg("")
  r.ShowConsoleMsg("============================================================\n")
  r.ShowConsoleMsg(" DF95 SampleDB – AI Tag Browser\n")
  r.ShowConsoleMsg(" DB: "..tostring(db_path).."\n")
  r.ShowConsoleMsg(" Items gesamt: "..tostring(#items).."\n")
  r.ShowConsoleMsg(" Filter UCS Category: "..tostring(filters.ucs_cat or "(alle)").."\n")
  r.ShowConsoleMsg(" Filter AI Model    : "..tostring(filters.ai_model or "(alle)").."\n")
  r.ShowConsoleMsg("------------------------------------------------------------\n")

  if #stats == 0 then
    r.ShowConsoleMsg("Keine AI-Tags gefunden (ai_tags / ai_labels leer).\n")
  else
    r.ShowConsoleMsg(string.format("%-6s  %s\n", "Count", "Tag"))
    r.ShowConsoleMsg("------------------------------------------------------------\n")
    local max_show = 500
    for i, entry in ipairs(stats) do
      if i > max_show then
        r.ShowConsoleMsg(string.format("... (%d weitere Tags nicht angezeigt)\n", #stats - max_show))
        break
      end
      r.ShowConsoleMsg(string.format("%6d  %s\n", entry.count, entry.tag))
    end
  end

  r.ShowConsoleMsg("============================================================\n")
end

main()
