-- @description DF95_V139 SampleDB – Record Planner (What to record next?)
-- @version 1.0
-- @author DF95
-- @about
--   Nutzt die DF95 SampleDB Multi-UCS JSON (Stufe 9/10) um Vorschläge zu machen:
--     * Welche Räume (home_zone) sind unterrepräsentiert?
--     * Welche Kategorien/Subkategorien (ucs_category/ucs_subcategory) haben wenig Samples?
--     * Welche Materials/Actions/ObjectClasses fehlen?
--   Damit kannst du deine nächsten Field-Recording-Sessions planen
--   (z.B. mehr Keller/Fahrrad, mehr Kinderzimmer-Nacht, mehr Bathroom/Shower etc.).
--
--   Es werden KEINE Dateien geändert. Nur Analyse + Vorschlagsliste (Console + optional CSV).
--
--   Erwartet:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json

local r = reaper

------------------------------------------------------------
-- JSON Decoder (wie in Analyzer)
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
-- Helper
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

local function get_support_dir()
  local res = r.GetResourcePath()
  return join_path(res, "Support")
end

local function inc(map, key, amount)
  if key == nil or key == "" then
    key = "(none)"
  end
  map[key] = (map[key] or 0) + (amount or 1)
end

local function sorted_pairs_by_value_asc(map)
  local arr = {}
  for k, v in pairs(map) do
    arr[#arr+1] = { key = k, val = v }
  end
  table.sort(arr, function(a, b)
    if a.val == b.val then
      return a.key < b.key
    end
    return a.val < b.val
  end)
  local i = 0
  return function()
    i = i + 1
    if arr[i] then return arr[i].key, arr[i].val end
  end
end

local function sorted_pairs_by_value_desc(map)
  local arr = {}
  for k, v in pairs(map) do
    arr[#arr+1] = { key = k, val = v }
  end
  table.sort(arr, function(a, b) return a.val > b.val end)
  local i = 0
  return function()
    i = i + 1
    if arr[i] then return arr[i].key, arr[i].val end
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local db_path = get_db_path()
  local f = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "SampleDB JSON nicht gefunden:\n"..db_path..
      "\n\nBitte zuerst den DF95 UCS-Light Scanner ausführen.",
      "DF95 SampleDB – Record Planner",
      0
    )
    return
  end

  local text = f:read("*all")
  f:close()

  local db, err = decode_json(text)
  if not db then
    r.ShowMessageBox(
      "Fehler beim Lesen der SampleDB:\n"..tostring(err),
      "DF95 SampleDB – Record Planner",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die SampleDB enthält keine Items.\n"..db_path,
      "DF95 SampleDB – Record Planner",
      0
    )
    return
  end

  local ok, vals = r.GetUserInputs(
    "DF95 Record Planner – Optionen",
    4,
    "Min. Length (Sekunden),Ziel-Minimum pro Cat/Sub (z.B. 20),Top N Vorschläge pro Gruppe,CSV-Report? (YES/NO)",
    "0.0,20,10,YES"
  )
  if not ok then return end

  local s_minlen, s_minper, s_topn, s_csv = vals:match("([^,]*),([^,]*),([^,]*),([^,]*)")
  local min_len = tonumber(s_minlen or "0.0") or 0.0
  if min_len < 0 then min_len = 0 end
  local min_per = tonumber(s_minper or "20") or 20
  if min_per < 1 then min_per = 1 end
  local top_n   = tonumber(s_topn or "10") or 10
  if top_n < 1 then top_n = 1 end
  local want_csv = ((s_csv or ""):upper() == "YES")

  local stats_zone    = {}
  local stats_cat     = {}
  local stats_cat_sub = {}
  local stats_mat     = {}
  local stats_obj     = {}
  local stats_act     = {}

  local total_items = 0

  for _, it in ipairs(items) do
    local len = tonumber(it.length_sec or it.length or 0) or 0
    if len >= min_len then
      total_items = total_items + 1

      local zone = it.home_zone or "(none)"
      local cat  = it.ucs_category or "(none)"
      local sub  = it.ucs_subcategory or "(none)"
      local mat  = it.material or "(none)"
      local obj  = it.object_class or "(none)"
      local act  = it.action or "(none)"

      local cat_sub = cat .. "/" .. sub

      inc(stats_zone,    zone)
      inc(stats_cat,     cat)
      inc(stats_cat_sub, cat_sub)
      inc(stats_mat,     mat)
      inc(stats_obj,     obj)
      inc(stats_act,     act)
    end
  end

  if total_items == 0 then
    r.ShowMessageBox(
      "Keine Items erfüllen die Mindestlänge (Min. Length = "..tostring(min_len).." s).",
      "DF95 SampleDB – Record Planner",
      0
    )
    return
  end

  --------------------------------------------------------
  -- Vorschlagslogik: Unterversorgte Bereiche
  --------------------------------------------------------

  local function build_under_list(map, label)
    local under = {}
    for k, v in sorted_pairs_by_value_asc(map) do
      if v < min_per then
        under[#under+1] = { key = k, val = v }
      end
    end
    return under
  end

  local under_zone    = build_under_list(stats_zone,    "home_zone")
  local under_cat     = build_under_list(stats_cat,     "ucs_category")
  local under_cat_sub = build_under_list(stats_cat_sub, "ucs_cat_sub")
  local under_mat     = build_under_list(stats_mat,     "material")
  local under_obj     = build_under_list(stats_obj,     "object_class")
  local under_act     = build_under_list(stats_act,     "action")

  --------------------------------------------------------
  -- Console-Output
  --------------------------------------------------------

  r.ShowConsoleMsg("")
  r.ShowConsoleMsg("============================================================\n")
  r.ShowConsoleMsg(" DF95 SampleDB – Record Planner (Stufe 11)\n")
  r.ShowConsoleMsg(" DB: "..tostring(db_path).."\n")
  r.ShowConsoleMsg(string.format(" Items (>= %.3f s): %d\n", min_len, total_items))
  r.ShowConsoleMsg(string.format(" Ziel-Minimum pro Kategorie: %d Samples\n", min_per))
  r.ShowConsoleMsg("------------------------------------------------------------\n\n")

  local function print_under(title, list)
    r.ShowConsoleMsg(title..":\n")
    if #list == 0 then
      r.ShowConsoleMsg("  (Alles erfüllt das Ziel-Minimum oder darüber)\n\n")
      return
    end
    for i = 1, math.min(#list, top_n) do
      local e = list[i]
      r.ShowConsoleMsg(string.format("  %-40s : %4d / %d\n", e.key, e.val, min_per))
    end
    if #list > top_n then
      r.ShowConsoleMsg(string.format("  ... (%d weitere Einträge)\n", #list - top_n))
    end
    r.ShowConsoleMsg("\n")
  end

  r.ShowConsoleMsg("👉 Vorschläge, wo du mehr aufnehmen könntest:\n\n")
  print_under("Home Zones (Räume)",        under_zone)
  print_under("UCS Categories (z.B. DRUMS, KITCHEN, ...)", under_cat)
  print_under("UCS Cat/Sub (z.B. DRUMS/Kick, BATHROOM/Shower, ...)", under_cat_sub)
  print_under("Materialien (WOOD, METAL, PLASTIC, WATER, ...)", under_mat)
  print_under("Object Classes (FOLEY, DRUM, TOY, APPLIANCE, ...)", under_obj)
  print_under("Actions (OPEN, CLOSE, STEP, HIT, FLOW, ...)", under_act)

  r.ShowConsoleMsg("============================================================\n")
  r.ShowConsoleMsg(" Tipp: Nutze diese Liste als ToDo für Field-Recording-Sessions.\n")
  r.ShowConsoleMsg("============================================================\n")

  --------------------------------------------------------
  -- CSV-Report (optional)
  --------------------------------------------------------

  if want_csv then
    local support_dir = get_support_dir()
    local csv_name = os.date("DF95_SampleDB_RecordPlanner_%Y%m%d_%H%M%S.csv")
    local csv_path = join_path(support_dir, csv_name)

    local fcsv, err2 = io.open(csv_path, "w")
    if not fcsv then
      r.ShowMessageBox(
        "Fehler beim Schreiben des CSV-Reports:\n"..tostring(err2 or csv_path),
        "DF95 SampleDB – Record Planner",
        0
      )
      return
    end

    local function csv_escape(s)
      s = tostring(s or "")
      if s:find("[,;\n\"]") then
        s = "\"" .. s:gsub("\"", "\"\"") .. "\""
      end
      return s
    end

    local function write_section(name, list)
      fcsv:write("# "..name.."\n")
      fcsv:write("key,count,target_min\n")
      for _, e in ipairs(list) do
        fcsv:write(csv_escape(e.key)..","..tostring(e.val)..","..tostring(min_per).."\n")
      end
      fcsv:write("\n")
    end

    write_section("Home Zones",        under_zone)
    write_section("UCS Categories",    under_cat)
    write_section("UCS Cat_Sub",       under_cat_sub)
    write_section("Materials",         under_mat)
    write_section("Object Classes",    under_obj)
    write_section("Actions",           under_act)

    fcsv:close()

    r.ShowMessageBox(
      "Record-Planner-CSV geschrieben:\n"..csv_path,
      "DF95 SampleDB – Record Planner",
      0
    )
  end
end

main()
