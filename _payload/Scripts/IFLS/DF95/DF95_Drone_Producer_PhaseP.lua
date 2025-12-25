\
-- DF95_Drone_Producer_PhaseP.lua
-- Phase P – Drone Producer Mode (Library Balancing & Suggestions)
--
-- Zweck:
--   Liefert eine analytische Sicht auf deine Drone-Library und erzeugt
--   Vorschläge, welche Drone-Typen du für zukünftige Sessions aufnehmen
--   könntest, um die Library zu „balancen“.
--
--   Fokus:
--     - Verteilung der Drone-Enums (Phase L) analysieren
--     - Unterrepräsentierte Kombinationen erkennen
--     - Textuellen Report mit Vorschlägen erzeugen
--
--   WICHTIG:
--     - Dieses Script nimmt KEINE Änderungen an der DB vor.
--       Es ist rein analytisch, read-only.
--
--   Output:
--     - REAPER-Konsole: Kurz-Zusammenfassung
--     - <REAPER>/Support/DF95_SampleDB/DF95_Drone_PhaseP_Suggestions_<YYYYMMDD_HHMMSS>.txt
--
--   Beispiel für Vorschläge:
--     - "LOW / STATIC / PAD / LOW tension ist stark unterrepräsentiert – gut
--        als ruhige HOME- oder AMBIENT-Drones."
--     - "HIGH / MOVEMENT / TEXTURE / HIGH tension kommt selten vor – könnte
--        für Action/Thriller-Packs spannend sein."

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function log(msg)
  r.ShowConsoleMsg(tostring(msg) .. "\n")
end

local function upper(str)
  if type(str) ~= "string" then return "" end
  return string.upper(str)
end

local function nil_or_upper(str)
  if str == nil then return "" end
  return upper(str)
end

local function get_db_paths()
  local res_path = r.GetResourcePath()
  local db_dir = res_path .. "/Support/DF95_SampleDB"
  local db_path = db_dir .. "/DF95_SampleDB_Multi_UCS.json"
  return db_dir, db_path
end

local function ensure_dir(path)
  return true
end

------------------------------------------------------------
-- JSON Helper (read-only)
------------------------------------------------------------

local json = nil

local function init_json()
  if json then return true end

  local ok, m = pcall(require, "json")
  if ok and m then
    json = m
    return true
  end

  ok, m = pcall(require, "dkjson")
  if ok and m then
    json = m
    return true
  end

  return false
end

local function json_decode(str)
  if not json then return nil, "JSON library not initialized" end

  if type(json.decode) == "function" then
    local ok, res, pos, err = pcall(json.decode, str)
    if ok and res and not err then
      return res
    elseif ok and res and type(res) == "table" then
      return res
    else
      return nil, err or "JSON decode error"
    end
  end

  return nil, "Unsupported JSON implementation"
end

------------------------------------------------------------
-- Drone Detection (konsistent mit Phase N/O)
------------------------------------------------------------

local function is_drone_item(it)
  if type(it) ~= "table" then return false end

  local role  = upper(it.role)
  local flag  = upper(it.df95_drone_flag)
  local catid = upper(it.df95_catid or "")

  local is_drone = false
  if role == "DRONE" then is_drone = true end
  if flag ~= "" then is_drone = true end
  if catid:find("DRONE", 1, true) then is_drone = true end

  return is_drone
end

------------------------------------------------------------
-- Producer Analysis
------------------------------------------------------------

local function open_report(db_dir)
  local ts = os.date("%Y%m%d_%H%M%S")
  local path = db_dir .. "/DF95_Drone_PhaseP_Suggestions_" .. ts .. ".txt"
  local f, err = io.open(path, "w")
  if not f then
    return nil, "Cannot create suggestions file: " .. tostring(err)
  end

  local function w(line)
    f:write(line or "")
    f:write("\n")
  end

  return {
    path  = path,
    file  = f,
    write = w,
    close = function()
      if not f then return end
      f:flush()
      f:close()
      f = nil
    end
  }
end

local function combo_key(cf, dens, form, mot, ten)
  return table.concat({
    cf ~= ""   and cf   or "-",
    dens ~= "" and dens or "-",
    form ~= "" and form or "-",
    mot ~= ""  and mot  or "-",
    ten ~= ""  and ten  or "-",
  }, "|")
end

local function run_phaseP()
  r.ClearConsole()

  log("DF95 Drone Producer Mode – Phase P")
  log("----------------------------------")
  log("")

  -- Init JSON
  if not init_json() then
    r.ShowMessageBox(
      "Konnte keine JSON-Library laden (json oder dkjson).\n" ..
      "Bitte Phase P Script an deine DF95-JSON-Utility anpassen.",
      "DF95 Phase P – Fehler",
      0
    )
    return
  end

  local db_dir, db_path = get_db_paths()
  ensure_dir(db_dir)

  if not r.file_exists(db_path) then
    r.ShowMessageBox(
      "DB-Datei nicht gefunden:\n" .. db_path .. "\n\n" ..
      "Stelle sicher, dass deine DF95 SampleDB vorhanden ist.",
      "DF95 Phase P – Fehler",
      0
    )
    return
  end

  local f, err = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "Kann DB nicht öffnen:\n" .. tostring(err),
      "DF95 Phase P – Fehler",
      0
    )
    return
  end
  local content = f:read("*a")
  f:close()

  local db, dberr = json_decode(content)
  if not db then
    r.ShowMessageBox(
      "JSON Decode-Fehler in DB:\n" .. tostring(dberr),
      "DF95 Phase P – Fehler",
      0
    )
    return
  end

  local items = nil
  if type(db) == "table" and type(db.items) == "table" then
    items = db.items
  elseif type(db) == "table" and #db > 0 then
    items = db
  else
    r.ShowMessageBox(
      "Unbekannte DB-Struktur.\n" ..
      "Erwarte entweder db.items = { ... } oder ein top-level Array.",
      "DF95 Phase P – Fehler",
      0
    )
    return
  end

  local report, rerr = open_report(db_dir)
  if not report then
    r.ShowMessageBox(
      "Kann Suggestions-Datei nicht erstellen:\n" .. tostring(rerr),
      "DF95 Phase P – Fehler",
      0
    )
    return
  end

  local w = report.write

  ----------------------------------------------------------------
  -- Data aggregation
  ----------------------------------------------------------------

  local stats = {
    total_items   = 0,
    drone_items   = 0,
    combos        = {}, -- key -> count
    by_cf         = {}, -- cf   -> count
    by_density    = {}, -- dens -> count
    by_form       = {}, -- form -> count
    by_motion     = {}, -- mot  -> count
    by_tension    = {}, -- ten  -> count
  }

  local function inc(map, key)
    if key == "" or key == nil then return end
    map[key] = (map[key] or 0) + 1
  end

  for _, it in ipairs(items) do
    stats.total_items = stats.total_items + 1
    if is_drone_item(it) then
      stats.drone_items = stats.drone_items + 1

      local cf   = nil_or_upper(it.df95_drone_centerfreq)
      local dens = nil_or_upper(it.df95_drone_density)
      local form = nil_or_upper(it.df95_drone_form)
      local mot  = nil_or_upper(it.df95_drone_motion)
      local ten  = nil_or_upper(it.df95_tension)

      inc(stats.by_cf, cf ~= "" and cf or "(none)")
      inc(stats.by_density, dens ~= "" and dens or "(none)")
      inc(stats.by_form, form ~= "" and form or "(none)")
      inc(stats.by_motion, mot ~= "" and mot or "(none)")
      inc(stats.by_tension, ten ~= "" and ten or "(none)")

      local key = combo_key(cf, dens, form, mot, ten)
      stats.combos[key] = (stats.combos[key] or 0) + 1
    end
  end

  ----------------------------------------------------------------
  -- Helper to sort maps by count ascending
  ----------------------------------------------------------------

  local function map_to_sorted_list(map)
    local t = {}
    for k, v in pairs(map) do
      table.insert(t, { key = k, count = v })
    end
    table.sort(t, function(a, b)
      if a.count == b.count then
        return tostring(a.key) < tostring(b.key)
      end
      return a.count < b.count
    end)
    return t
  end

  ----------------------------------------------------------------
  -- Heuristik: Ziel-Balance
  --
  -- Grobe Idee:
  --   - Wir betrachten nur Kombinationen, die bereits existieren
  --   - Wir werten die Verteilung aus
  --   - Unterrepräsentiert ≈ zählt weit unter Median oder Durchschnitt
  ----------------------------------------------------------------

  local combo_list = map_to_sorted_list(stats.combos)

  local total_drone = stats.drone_items
  local total_combos = #combo_list

  local avg_per_combo = total_combos > 0 and (total_drone / total_combos) or 0

  -- Median berechnen
  local median_per_combo = 0
  if total_combos > 0 then
    local mid = math.floor((total_combos + 1) / 2)
    median_per_combo = combo_list[mid].count
  end

  -- Schwellenwerte
  local threshold_very_low = math.max(1, math.floor(median_per_combo * 0.25))
  local threshold_low      = math.max(1, math.floor(median_per_combo * 0.5))

  ----------------------------------------------------------------
  -- Suggestions ableiten
  ----------------------------------------------------------------

  local suggestions = {}

  local function add_suggestion(combo, reason, extra_hint)
    table.insert(suggestions, {
      combo      = combo,
      reason     = reason,
      extra_hint = extra_hint,
    })
  end

  for _, entry in ipairs(combo_list) do
    local key   = entry.key
    local count = entry.count

    local cf, dens, form, mot, ten = key:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)")
    cf   = cf   or "-"
    dens = dens or "-"
    form = form or "-"
    mot  = mot  or "-"
    ten  = ten  or "-"

    -- Nur sinnvolle, weitgehend definierte Kombinationen betrachten
    local undefined_fields = 0
    if cf == "-"   then undefined_fields = undefined_fields + 1 end
    if dens == "-" then undefined_fields = undefined_fields + 1 end
    if form == "-" then undefined_fields = undefined_fields + 1 end
    if mot == "-"  then undefined_fields = undefined_fields + 1 end
    if ten == "-"  then undefined_fields = undefined_fields + 1 end

    if undefined_fields <= 2 then
      if count <= threshold_very_low then
        local reason = string.format("stark unterrepräsentiert (nur %d Items, Median ~%d)", count, median_per_combo)
        local extra = nil

        -- Grobe Kreativ-Hints anhand der Enums
        if cf == "LOW" and mot == "STATIC" then
          extra = "Ideal für ruhige HOME/AMBIENT Drones (Betten, lange Pads, unaufdringliche Atmos)."
        elseif cf == "LOW" and mot ~= "STATIC" then
          extra = "Kann als subtile Bewegung im Low-End wirken (City-Rumble, Distante Maschinen, ferne Wetterlagen)."
        elseif cf == "MID" and form == "TEXTURE" then
          extra = "Gut für „in-your-face“ Texturen, Foley-artige Drones, Sci-Fi Zischen / Kontaktgeräusche."
        elseif cf == "HIGH" and (mot == "MOVEMENT" or mot == "PULSE") then
          extra = "Spannend für Thriller/Horror/Tension-Builds, modulierende High-Freq-Spannung."
        elseif ten == "EXTREME" then
          extra = "EXTREME Tension Drones funktionieren gut als Spitzenpunkte in Cue-Strukturen (Climax / Stinger)."
        end

        add_suggestion({
          centerfreq = cf,
          density    = dens,
          form       = form,
          motion     = mot,
          tension    = ten,
          count      = count,
        }, reason, extra)
      elseif count <= threshold_low then
        local reason = string.format("unterrepräsentiert (nur %d Items, Median ~%d)", count, median_per_combo)
        add_suggestion({
          centerfreq = cf,
          density    = dens,
          form       = form,
          motion     = mot,
          tension    = ten,
          count      = count,
        }, reason, nil)
      end
    end
  end

  ----------------------------------------------------------------
  -- Report schreiben
  ----------------------------------------------------------------

  w("DF95 Drone Producer Mode – Phase P")
  w("Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"))
  w("")
  w("DB: " .. db_path)
  w("")
  w(string.format("Total Items   : %d", stats.total_items))
  w(string.format("Drone-Items   : %d", stats.drone_items))
  w(string.format("Distinct combos (cf/dens/form/mot/tension): %d", total_combos))
  w(string.format("Avg Items per combo   : %.2f", avg_per_combo))
  w(string.format("Median Items per combo: %d", median_per_combo))
  w("")
  w(string.format("Threshold (very low)  : <= %d", threshold_very_low))
  w(string.format("Threshold (low)       : <= %d", threshold_low))
  w("")
  w("------------------------------------------------------------")
  w("Distribution (per field)")
  w("------------------------------------------------------------")
  local function dump_map(title, map)
    w("")
    w(title .. ":")
    local list = {}
    for k, v in pairs(map) do
      table.insert(list, { key = k, count = v })
    end
    table.sort(list, function(a, b)
      return a.count < b.count
    end)
    for _, e in ipairs(list) do
      w(string.format("  %-12s : %d", tostring(e.key), e.count))
    end
  end

  dump_map("Centerfreq", stats.by_cf)
  dump_map("Density",    stats.by_density)
  dump_map("Form",       stats.by_form)
  dump_map("Motion",     stats.by_motion)
  dump_map("Tension",    stats.by_tension)

  w("")
  w("------------------------------------------------------------")
  w("Suggested Focus Areas for Future Recording Sessions")
  w("------------------------------------------------------------")
  w("")

  if #suggestions == 0 then
    w("Aktuell wurden keine klar unterrepräsentierten Kombinationen gefunden.")
    w("Deine Drone-Library wirkt aus Phase-P-Sicht relativ ausgewogen.")
  else
    for _, s in ipairs(suggestions) do
      local c = s.combo
      w(string.format("- %s / %s / %s / %s / %s  (Items: %d)",
        c.centerfreq, c.density, c.form, c.motion, c.tension, c.count))
      w(string.format("    → %s", s.reason))
      if s.extra_hint and s.extra_hint ~= "" then
        w(string.format("    Kreativ-Hinweis: %s", s.extra_hint))
      end
      w("")
    end
  end

  report.close()

  ----------------------------------------------------------------
  -- Console Summary
  ----------------------------------------------------------------

  log("Phase P Suggestions written to:")
  log("  " .. report.path)
  log("")
  log(string.format("Total Items : %d", stats.total_items))
  log(string.format("Drone-Items : %d", stats.drone_items))
  log(string.format("Distinct combos (cf/dens/form/mot/tension): %d", total_combos))
  log("")
  log(string.format("Identified underrepresented combos (suggestions): %d", #suggestions))
  log("")

  local msg =
    "DF95 Drone Producer Mode – Phase P\n\n" ..
    string.format("Drone-Items: %d\n", stats.drone_items) ..
    string.format("Distinct combos: %d\n", total_combos) ..
    string.format("Suggestions: %d\n\n", #suggestions) ..
    "Detaillierte Vorschläge wurden geschrieben nach:\n" ..
    report.path .. "\n\n" ..
    "Empfohlene Nutzung:\n" ..
    "1) Report lesen und 3–5 Fokus-Kombinationen auswählen\n" ..
    "2) Daraus konkrete Recording-Sessions planen\n" ..
    "3) Nach neuen Aufnahmen: Phase N (wenn nötig) + Phase O für Konsistenz\n"

  r.ShowMessageBox(msg, "DF95 Phase P – Producer Suggestions", 0)
end

------------------------------------------------------------
-- Run
------------------------------------------------------------

run_phaseP()
