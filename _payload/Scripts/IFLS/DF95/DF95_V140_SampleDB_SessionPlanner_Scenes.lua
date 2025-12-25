-- @description DF95_V140 SampleDB – Session Planner (Concrete Recording Scenes)
-- @version 1.0
-- @author DF95
-- @about
--   Baut auf der DF95 SampleDB Multi-UCS JSON auf und erzeugt konkrete
--   Vorschläge für Recording-Szenen, z.B.:
--     * BATHROOM/Shower  -> "Shower: Start/Stop, Constant, Behind Curtain, From Hallway"
--     * BASEMENT/Bicycle -> "Bike: Chain, Brakes, Freewheel, Frame Hits, Tyre Air"
--     * CHILDROOM/Lego   -> "Lego: Pour, Search, Build, Knock, Drop"
--
--   Es nutzt:
--     * ucs_category / ucs_subcategory
--     * home_zone
--     * material
--     * action
--
--   Ziel:
--     * Eine ToDo-Liste an konkreten Takes, die deine Library sinnvoll erweitern.
--
--   Hinweis:
--     * Das Script ändert KEINE Dateien und KEINE DB, nur Analyse + Vorschläge.
--     * Optional kann ein CSV-Report mit den Szenen in <REAPER>/Support geschrieben werden.

local r = reaper

------------------------------------------------------------
-- JSON Decoder
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

local function lower(s) return (s or ""):lower() end
local function upper(s) return (s or ""):upper() end

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

local function inc(map, key, amount)
  if not key or key == "" then key = "(none)" end
  map[key] = (map[key] or 0) + (amount or 1)
end

------------------------------------------------------------
-- Szenen-Generator
------------------------------------------------------------

local function scene_templates(cat, sub, zone)
  local key = upper(cat or "") .. "/" .. upper(sub or "")
  local z   = upper(zone or "")

  local scenes = {}

  -- BATHROOM
  if key:find("BATHROOM/SHOWER") then
    scenes = {
      "Shower: Start/Stop, Nah (Innenkabine)",
      "Shower: Konstante Dusche, Nah, verschiedene Lautstärken",
      "Shower: Hinter dem Duschvorhang / Türe",
      "Shower: Aus dem Flur durch die Tür",
      "Shower: Wasser auf Boden/Fliesen (Steps + Wasser)"
    }
  elseif key:find("BATHROOM/SINK") then
    scenes = {
      "Sink: Wasser auf/zu, verschiedene Lautstärken",
      "Sink: Hände waschen, Seife, Reiben",
      "Sink: Geschirr kurz abspülen",
      "Sink: Wasser tropft (Drip / Slow Leak)"
    }
  elseif key:find("BATHROOM/TOILET") then
    scenes = {
      "Toilet: Spülung Nah (Innenraum)",
      "Toilet: Spülung aus dem Flur",
      "Toilet: Deckel auf/zu, Sitz auf/zu",
      "Toilet: Spülkasten befüllt sich"
    }
  -- KITCHEN
  elseif key:find("KITCHEN/DISHES_HANDLING") then
    scenes = {
      "Dishes: Stapeln & Entstapeln (Teller/Schüsseln)",
      "Dishes: In- und aus Spülbecken legen",
      "Dishes: Sanfte vs. harte Klänge (leise/laut)",
      "Dishes: Auf Arbeitsfläche schieben (Ceramic/Stone)"
    }
  elseif key:find("KITCHEN/CUTLERY") then
    scenes = {
      "Cutlery: Besteckschublade öffnen/schließen",
      "Cutlery: Besteck sortieren, suchen, greifen",
      "Cutlery: Löffel/ Messer/ Gabel auf Teller legen",
      "Cutlery: Bund aus Besteck klimpern"
    }
  elseif key:find("KITCHEN/DRAWER") then
    scenes = {
      "Kitchen Drawer: Langsam auf/zu",
      "Kitchen Drawer: Schnell auf/zu, verschiedene Intensitäten",
      "Kitchen Drawer: Mit Inhalt vs. leer",
      "Kitchen Drawer: Griff-Variationen"
    }
  -- CHILDROOM
  elseif key:find("CHILDROOM/LEGO") then
    scenes = {
      "Lego: Ausschütten auf Tisch/Boden",
      "Lego: Suchen/ Wühlen in Kiste",
      "Lego: Steine zusammenstecken/auseinandernehmen",
      "Lego: Kleine Tower umwerfen"
    }
  elseif key:find("CHILDROOM/TOYS") then
    scenes = {
      "Toys: Verschiedene Plastikspielzeuge bewegen",
      "Toys: Quietschspielzeug, langsame und schnelle Bewegungen",
      "Toys: Mehrere kleine Spielzeuge gleichzeitig",
      "Toys: Kindgerecht (sanft) vs. übertrieben (FX)"
    }
  elseif key:find("CHILDROOM/RATTLE") then
    scenes = {
      "Rattle: Verschiedene Geschwindigkeiten, nah",
      "Rattle: Schütteln in verschiedenen Richtungen",
      "Rattle: Über Bett/Decke bewegen",
      "Rattle: In der Hand eines Kindes (leicht chaotisch)"
    }
  -- BASEMENT / FAHRRÄDER
  elseif key:find("BASEMENT/BICYCLE") then
    scenes = {
      "Bicycle: Freilauf/Freewheel, verschiedene Geschwindigkeiten",
      "Bicycle: Kette drehen, leicht vs. stark",
      "Bicycle: Bremsen quietschen, ziehen & lösen",
      "Bicycle: Rahmen-Taps, Metallhits"
    }
  elseif key:find("BASEMENT/BALANCEBIKE") or key:find("BASEMENT/SCOOTER") then
    scenes = {
      "Kids Bike/Scooter: Rollen über verschiedene Böden",
      "Kids Bike/Scooter: Bremsgeräusche (falls vorhanden)",
      "Kids Bike/Scooter: Anheben/Abstellen",
      "Kids Bike/Scooter: Lenker-Bewegungen"
    }
  elseif key:find("BASEMENT/WASHINGMACHINE") then
    scenes = {
      "Washing Machine: Leerlauf – Trommel drehen (ohne Wäsche)",
      "Washing Machine: Waschen – typische Programme",
      "Washing Machine: Pumpe abpumpen",
      "Washing Machine: Tür auf/zu, Knöpfe/Schalter"
    }
  elseif key:find("BASEMENT/DRYER") then
    scenes = {
      "Dryer: Start/Stop, Tür auf/zu",
      "Dryer: Verschiedene Drehzahlen / Programme",
      "Dryer: Mit/ohne Wäsche (Unterschied im Klang)",
      "Dryer: Gebläse Only (wenn möglich)"
    }
  -- DRUMS
  elseif key:find("DRUMS/KICK") then
    scenes = {
      "Kick: Single Hits, konstant (Center)",
      "Kick: Single Hits, variierende Velocity",
      "Kick: Pattern für Groove-Basis",
      "Kick: Dämpfungsvarianten (Kissen/Decke)"
    }
  elseif key:find("DRUMS/SNARE") then
    scenes = {
      "Snare: Center Hits, verschiedene Lautstärken",
      "Snare: Rimshot vs. Center",
      "Snare: Rolls & Flams",
      "Snare: Mit/ohne Snareteppich"
    }
  elseif key:find("DRUMS/TOMHIGH") or key:find("DRUMS/TOMMID") or key:find("DRUMS/TOMLOW") then
    scenes = {
      "Toms: Einzelschläge pro Tom",
      "Toms: Toms-Fills über alle Toms",
      "Toms: Dämpfung (Gaffa/Gel) vs. offen",
      "Toms: Rim vs. Head"
    }
  elseif key:find("DRUMS/HIHAT") then
    scenes = {
      "HiHat: Closed 8tel, verschiedene Lautstärken",
      "HiHat: Open/Close Variationen",
      "HiHat: Pedal-Only Sounds",
      "HiHat: Edge vs. Tip"
    }
  elseif key:find("DRUMS/RIDE") then
    scenes = {
      "Ride: Steady Pattern (Tip auf Ride)",
      "Ride: Bell vs. Bow",
      "Ride: Crescendo Rolls",
      "Ride: Random Hits für FX"
    }
  elseif key:find("DRUMS/CRASH") then
    scenes = {
      "Crash: Single Hits verschiedener Lautstärken",
      "Crash: Swells mit Mallets/Stickroll",
      "Crash: Choke (kurz abgedämpft)",
      "Crash: Edge vs. Bow"
    }
  -- DEFAULT
  else
    scenes = {
      "Verschiedene Aktionen/Intensitäten aufnehmen.",
      "Mehrere Distanzen (nah/mittel/weit).",
      "Unterschiedliche Perspektiven (z.B. Tür auf/zu, von außen/innen).",
      "Varianten in Lautstärke und Geschwindigkeit."
    }
  end

  return scenes
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
      "DF95 SampleDB – Session Planner",
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
      "DF95 SampleDB – Session Planner",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die SampleDB enthält keine Items.\n"..db_path,
      "DF95 SampleDB – Session Planner",
      0
    )
    return
  end

  local ok, vals = r.GetUserInputs(
    "DF95 Session Planner – Optionen",
    3,
    "Min. Length (Sekunden),Max. Szenen,CSV-Report? (YES/NO)",
    "0.0,40,YES"
  )
  if not ok then return end

  local s_minlen, s_max, s_csv = vals:match("([^,]*),([^,]*),([^,]*)")
  local min_len = tonumber(s_minlen or "0.0") or 0.0
  if min_len < 0 then min_len = 0 end
  local max_scenes = tonumber(s_max or "40") or 40
  if max_scenes < 1 then max_scenes = 1 end
  local want_csv = ((s_csv or ""):upper() == "YES")

  -- Count Cat/Sub usage
  local stats_cat_sub = {}
  for _, it in ipairs(items) do
    local len = tonumber(it.length_sec or it.length or 0) or 0
    if len >= min_len then
      local cat = it.ucs_category or "(none)"
      local sub = it.ucs_subcategory or "(none)"
      local zone = it.home_zone or "(none)"
      local key = cat .. "/" .. sub .. "@" .. zone
      inc(stats_cat_sub, key)
    end
  end

  -- Sort ascending by count => wenig Samples zuerst
  local sorted_list = {}
  for k, v in pairs(stats_cat_sub) do
    sorted_list[#sorted_list+1] = { key = k, val = v }
  end
  table.sort(sorted_list, function(a, b)
    if a.val == b.val then
      return a.key < b.key
    end
    return a.val < b.val
  end)

  r.ShowConsoleMsg("")
  r.ShowConsoleMsg("============================================================\n")
  r.ShowConsoleMsg(" DF95 SampleDB – Session Planner (Szenen)\n")
  r.ShowConsoleMsg(" DB: "..tostring(db_path).."\n")
  r.ShowConsoleMsg(string.format(" Items (>= %.3f s): %d\n", min_len, #items))
  r.ShowConsoleMsg("------------------------------------------------------------\n\n")

  local scenes_out = {}

  local count_scenes = 0
  for _, e in ipairs(sorted_list) do
    if count_scenes >= max_scenes then break end
    local key = e.key
    local cnt = e.val

    local cat, rest = key:match("([^/]+)/(.+)")
    if not cat then cat = key rest = "" end
    local sub, zone = rest:match("([^@]+)@(.*)")
    if not sub then sub = rest or "(none)" end
    zone = zone or "(none)"

    local st = scene_templates(cat, sub, zone)

    r.ShowConsoleMsg(string.format("Kategorie: %s / %s   (Zone: %s, vorhandene Samples: %d)\n", cat, sub, zone, cnt))
    for _, s in ipairs(st) do
      r.ShowConsoleMsg("  • "..s.."\n")
      scenes_out[#scenes_out+1] = {
        category = cat,
        sub      = sub,
        zone     = zone,
        existing = cnt,
        idea     = s
      }
      count_scenes = count_scenes + 1
      if count_scenes >= max_scenes then
        break
      end
    end
    r.ShowConsoleMsg("\n")
  end

  r.ShowConsoleMsg("============================================================\n")
  r.ShowConsoleMsg(" Tipp: Nutze diese Szenen als konkrete ToDo-Liste für neue Aufnahmen.\n")
  r.ShowConsoleMsg("============================================================\n")

  if want_csv then
    local support_dir = get_support_dir()
    local csv_name = os.date("DF95_SampleDB_SessionPlanner_%Y%m%d_%H%M%S.csv")
    local csv_path = join_path(support_dir, csv_name)

    local fcsv, err2 = io.open(csv_path, "w")
    if not fcsv then
      r.ShowMessageBox(
        "Fehler beim Schreiben des Session-CSV:\n"..tostring(err2 or csv_path),
        "DF95 SampleDB – Session Planner",
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

    fcsv:write("category,subcategory,zone,existing_samples,idea\n")
    for _, s in ipairs(scenes_out) do
      local row = {
        csv_escape(s.category),
        csv_escape(s.sub),
        csv_escape(s.zone),
        tostring(s.existing),
        csv_escape(s.idea),
      }
      fcsv:write(table.concat(row, ",") .. "\n")
    end

    fcsv:close()

    r.ShowMessageBox(
      "Session-Plan-CSV geschrieben:\n"..csv_path,
      "DF95 SampleDB – Session Planner",
      0
    )
  end
end

main()
