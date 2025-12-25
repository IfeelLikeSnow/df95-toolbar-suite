-- @description DF95_V138 SampleDB – Library Analyzer (UCS-Light + AI)
-- @version 1.0
-- @author DF95
-- @about
--   Analysiert die DF95 SampleDB Multi-UCS JSON und zeigt Statistiken über:
--     * ucs_category / ucs_subcategory / df95_catid
--     * home_zone / material / object_class / action
--     * ai_primary (falls vorhanden)
--     * quality_grade (falls vorhanden)
--   Optional kann zusätzlich ein CSV-Report in <REAPER>/Support geschrieben werden.
--
--   Erwartete DB-Datei:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Typische Nutzung:
--     * Wie viele Samples habe ich pro Raum (KITCHEN, BATHROOM, CHILDROOM, BASEMENT, ...)?
--     * Wie viele Drums (Kick/Snare/Toms/HH/Ride/Crash) gibt es?
--     * Welche Materialien dominieren (WOOD, METAL, PLASTIC, WATER ...)?
--     * Wo fehlen noch Aufnahmen (z.B. wenig BATHROOM/Shower, kaum BASEMENT/Bicycle)?
--     * Welche AI-Labels kommen häufig vor (Water, Whoosh, Footsteps, ...)?
--
--   Hinweis:
--     * Dieses Script ändert KEINE Dateien und KEINE DB-Inhalte, außer beim optionalen
--       CSV-Export (nur Schreiben eines Reports).
--     * Es ist als „Röntgenbild“ deiner Library gedacht.

local r = reaper

------------------------------------------------------------
-- JSON decoder (kompatibel zum DF95-Encoder)
------------------------------------------------------------

local function decode_json(text)
  if type(text) ~= "string" then return nil, "no text" end

  local lua_text = text

  -- Keys in ["..."] = Value Form bringen
  lua_text = lua_text:gsub('"(.-)"%s*:', '["%1"] =')

  -- Arrays zu Lua-Tabellen
  lua_text = lua_text:gsub("%[", "{")
  lua_text = lua_text:gsub("%]", "}")

  -- null → nil
  lua_text = lua_text:gsub("null", "nil")

  lua_text = "return " .. lua_text

  local f, err = load(lua_text)
  if not f then return nil, err end

  local ok, res = pcall(f)
  if not ok then return nil, res end
  return res
end

------------------------------------------------------------
-- Helper: Pfade, Strings, Maps
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

local function grade_to_rank(g)
  if not g then return 0 end
  g = g:upper()
  if g == "A" then return 4
  elseif g == "B" then return 3
  elseif g == "C" then return 2
  elseif g == "D" then return 1
  end
  return 0
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
      "\n\nBitte zuerst einen DF95 SampleDB Scanner ausführen.",
      "DF95 SampleDB – Library Analyzer",
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
      "DF95 SampleDB – Library Analyzer",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die SampleDB enthält keine Items.\n"..db_path,
      "DF95 SampleDB – Library Analyzer",
      0
    )
    return
  end

  -- User-Optionen
  local ok, vals = r.GetUserInputs(
    "DF95 Library Analyzer – Optionen",
    3,
    "Output Mode (CONSOLE/CSV/BOTH),CSV: pro File Zeile? (YES/NO),Min. Length in Sekunden (z.B. 0.1)",
    "CONSOLE,NO,0.0"
  )
  if not ok then return end

  local s_mode, s_row, s_minlen = vals:match("([^,]*),([^,]*),([^,]*)")
  s_mode = (s_mode or ""):upper()
  s_row  = (s_row  or ""):upper()
  local min_len = tonumber(s_minlen or "0.0") or 0.0
  if min_len < 0 then min_len = 0 end

  local want_console = (s_mode == "CONSOLE" or s_mode == "BOTH")
  local want_csv     = (s_mode == "CSV" or s_mode == "BOTH")
  local csv_per_item = (s_row == "YES")

  --------------------------------------------------------
  -- Stat-Sammler
  --------------------------------------------------------

  local stats_cat     = {}
  local stats_sub     = {}
  local stats_cat_sub = {}
  local stats_zone    = {}
  local stats_mat     = {}
  local stats_obj     = {}
  local stats_act     = {}
  local stats_ai      = {}
  local stats_grade   = {}

  local total_items   = 0
  local total_length  = 0.0

  for _, it in ipairs(items) do
    local len = tonumber(it.length_sec or it.length or 0) or 0
    if len >= min_len then
      total_items  = total_items + 1
      total_length = total_length + len

      local cat  = it.ucs_category or "(none)"
      local sub  = it.ucs_subcategory or "(none)"
      local zone = it.home_zone or "(none)"
      local mat  = it.material or "(none)"
      local ocls = it.object_class or "(none)"
      local act  = it.action or "(none)"
      local ai   = it.ai_primary or "(none)"
      local grd  = it.quality_grade or "(none)"

      local cat_sub = cat .. "/" .. sub

      inc(stats_cat,     cat)
      inc(stats_sub,     sub)
      inc(stats_cat_sub, cat_sub)
      inc(stats_zone,    zone)
      inc(stats_mat,     mat)
      inc(stats_obj,     ocls)
      inc(stats_act,     act)
      inc(stats_ai,      ai)
      inc(stats_grade,   grd)
    end
  end

  if total_items == 0 then
    r.ShowMessageBox(
      "Keine Items erfüllen die Mindestlänge (Min. Length = "..tostring(min_len).." s).",
      "DF95 SampleDB – Library Analyzer",
      0
    )
    return
  end

  --------------------------------------------------------
  -- Console-Output
  --------------------------------------------------------

  if want_console then
    r.ShowConsoleMsg("")
    r.ShowConsoleMsg("============================================================\n")
    r.ShowConsoleMsg(" DF95 SampleDB – Library Analyzer (Stufe 10)\n")
    r.ShowConsoleMsg(" DB: "..tostring(db_path).."\n")
    r.ShowConsoleMsg(" Version: "..tostring(db.version or "(unknown)").."\n")
    r.ShowConsoleMsg(string.format(" Items (>= %.3f s): %d\n", min_len, total_items))
    r.ShowConsoleMsg(string.format(" Gesamtspielzeit: %.1f Sekunden (%.2f Stunden)\n",
      total_length, total_length / 3600.0))
    r.ShowConsoleMsg("------------------------------------------------------------\n\n")

    local function print_section(title, map, max_entries)
      r.ShowConsoleMsg(title..":\n")
      local count = 0
      for k, v in sorted_pairs_by_value_desc(map) do
        r.ShowConsoleMsg(string.format("  %-35s : %6d\n", k, v))
        count = count + 1
        if max_entries and count >= max_entries then break end
      end
      r.ShowConsoleMsg("\n")
    end

    print_section("Top UCS Categories",        stats_cat,     50)
    print_section("Top UCS Cat/Sub",           stats_cat_sub, 50)
    print_section("Home Zones (KITCHEN/...)",  stats_zone,    50)
    print_section("Materials",                 stats_mat,     50)
    print_section("Object Classes",            stats_obj,     50)
    print_section("Actions",                   stats_act,     50)
    print_section("AI Primary Labels",         stats_ai,      50)
    print_section("Quality Grades",            stats_grade,   50)

    r.ShowConsoleMsg("============================================================\n")
  end

  --------------------------------------------------------
  -- CSV-Export
  --------------------------------------------------------

  if want_csv then
    local support_dir = get_support_dir()
    local csv_name = os.date("DF95_SampleDB_LibraryReport_%Y%m%d_%H%M%S.csv")
    local csv_path = join_path(support_dir, csv_name)

    local fcsv, err2 = io.open(csv_path, "w")
    if not fcsv then
      r.ShowMessageBox(
        "Fehler beim Schreiben des CSV-Reports:\n"..tostring(err2 or csv_path),
        "DF95 SampleDB – Library Analyzer",
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

    -- Header
    if csv_per_item then
            fcsv:write("path,ucs_category,ucs_subcategory,df95_catid,home_zone,material,object_class,action,ai_primary,quality_grade,role,df95_drone_flag,df95_catid_drone,df95_drone_centerfreq,df95_drone_density,df95_drone_form,df95_motion_strength,df95_tension,length_sec,samplerate,channels\n")
      for _, it in ipairs(items) do
        local len = tonumber(it.length_sec or it.length or 0) or 0
        if len >= min_len then
          local row = {
            csv_escape(it.path),
            csv_escape(it.ucs_category),
            csv_escape(it.ucs_subcategory),
            csv_escape(it.df95_catid),
            csv_escape(it.home_zone),
            csv_escape(it.material),
            csv_escape(it.object_class),
            csv_escape(it.action),
            csv_escape(it.ai_primary),
            csv_escape(it.quality_grade),
            csv_escape(it.role),
            csv_escape(it.df95_drone_flag),
            csv_escape(it.df95_catid),
            csv_escape(it.df95_drone_centerfreq),
            csv_escape(it.df95_drone_density),
            csv_escape(it.df95_drone_form),
            csv_escape(it.df95_motion_strength or it.df95_drone_motion),
            csv_escape(it.df95_tension),
            tostring(len),
            tostring(it.samplerate or ""),
            tostring(it.channels or ""),
          }
          fcsv:write(table.concat(row, ",") .. "\n")
        end
      end
    else
      -- nur Aggregats-Stats
      fcsv:write("# DF95 SampleDB Library Report\n")
      fcsv:write("# DB: "..db_path.."\n")
      fcsv:write(string.format("# Items (>= %.3f s): %d\n", min_len, total_items))
      fcsv:write(string.format("# Gesamtspielzeit: %.1f Sekunden (%.2f Stunden)\n",
        total_length, total_length / 3600.0))
      fcsv:write("\n")

      local function write_section_csv(title, map)
        fcsv:write("# "..title.."\n")
        fcsv:write("key,count\n")
        for k, v in sorted_pairs_by_value_desc(map) do
          fcsv:write(csv_escape(k)..","..tostring(v).."\n")
        end
        fcsv:write("\n")
      end

      write_section_csv("UCS Categories",       stats_cat)
      write_section_csv("UCS Cat_Sub",          stats_cat_sub)
      write_section_csv("Home Zones",           stats_zone)
      write_section_csv("Materials",            stats_mat)
      write_section_csv("Object Classes",       stats_obj)
      write_section_csv("Actions",              stats_act)
      write_section_csv("AI Primary Labels",    stats_ai)
      write_section_csv("Quality Grades",       stats_grade)
    end

    fcsv:close()

    r.ShowMessageBox(
      "CSV-Report geschrieben:\n"..csv_path,
      "DF95 SampleDB – Library Analyzer",
      0
    )
  end
end

main()
