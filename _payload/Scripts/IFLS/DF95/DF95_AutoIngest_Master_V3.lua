-- @description DF95 AutoIngest Master V3 – Confidence-aware SampleDB Curator
-- @version 1.0
-- @author DF95
-- @about
--   Liest die DF95 SampleDB (Multi-UCS JSON), wertet df95_ai_confidence aus
--   und übernimmt bei Bedarf *_suggested Felder (HomeZone, SubZone, UCS, df95_catid)
--   in die "echten" Felder. Arbeitet in drei Modi:
--
--     * ANALYZE:
--         - Nimmt keine Änderungen an den Items vor (DB wird nicht geschrieben)
--         - Setzt df95_ai_review_flag auf OK_HIGH/REVIEW_MED/REVIEW_LOW
--
--     * SAFE:
--         - Wendet *_suggested nur für HIGH-Confidence-Items an
--         - Nur, wenn Ziel-Felder leer oder generisch sind (z.B. UCS=MISC/FIELDREC)
--
--     * AGGRESSIVE:
--         - Wie SAFE, plus:
--             - MED-Confidence-Items dürfen leere Felder füllen
--             - HIGH-Confidence-Items können generische UCS überschreiben
--
--   Default-DB: <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json

local r = reaper

------------------------------------------------------------
-- JSON Helper (minimal, wie in Inspector V4)
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

local function get_subset_filter_path()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local dir = res
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    dir = dir .. sep
  end
  dir = dir .. "Support" .. sep .. "DF95_SampleDB"
  return dir .. sep .. "DF95_AutoIngest_Subset.json"
end

local function load_subset_map()
  local path = get_subset_filter_path()
  local f = io.open(path, "r")
  if not f then
    return nil, "Subset-Datei nicht gefunden (" .. tostring(path) .. ")"
  end
  local text = f:read("*all")
  f:close()

  local data, err = decode_json(text)
  if not data then
    return nil, "Fehler beim Dekodieren der Subset-Datei: " .. tostring(err or "unbekannt")
  end

  local paths_tbl = nil

  if type(data) == "table" then
    if #data > 0 and type(data[1]) == "string" then
      paths_tbl = data
    elseif type(data.paths) == "table" then
      paths_tbl = data.paths
    end
  end

  if not paths_tbl then
    return nil, "Subset-Datei hat kein gültiges Format (erwartet: Array von Filepaths oder {paths=[...]})"
  end

  local map = {}
  local count = 0
  for _, p in ipairs(paths_tbl) do
    if type(p) == "string" and p ~= "" then
      map[p] = true
      count = count + 1
    end
  end

  if count == 0 then
    return nil, "Subset-Liste ist leer."
  end

  return map, nil
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

local function snapshot_item_state(it)
  return {
    filepath            = tostring(it.filepath or ""),
    df95_ai_review_flag = it.df95_ai_review_flag,
    ai_status           = it.ai_status,
    df95_ai_confidence  = it.df95_ai_confidence,
    home_zone           = it.home_zone,
    home_zone_sub       = it.home_zone_sub,
    ucs_category        = it.ucs_category,
    df95_catid          = it.df95_catid,
  }
end

local function write_changelog_entry(run)
  local path = get_changelog_path()
  local f, err = io.open(path, "a")
  if not f then
    r.ShowMessageBox("Konnte AutoIngest ChangeLog nicht schreiben:\\n" .. tostring(err or "unbekannt"), "DF95 AutoIngest V3", 0)
    return
  end
  local line = encode_json_value(run, 0)
  f:write(line)
  f:write("\n")
  f:close()
end

end

------------------------------------------------------------
-- Confidence & Heuristik
------------------------------------------------------------

local function is_nonempty(v)
  return v ~= nil and v ~= ""
end

local function is_generic_ucs(ucs)
  if not ucs or ucs == "" then return true end
  local u = tostring(ucs):upper()
  return (u == "FIELDREC" or u == "MISC" or u == "UNKNOWN" or u == "OTHER")
end

local function get_confidence(it)
  local c = tonumber(it.df95_ai_confidence or 0.0) or 0.0
  if c < 0.0 then c = 0.0 end
  if c > 1.0 then c = 1.0 end
  return c
end

local function classify_confidence(it, high_thr, med_thr)
  local c = get_confidence(it)
  if c >= high_thr then
    return "HIGH", c
  elseif c >= med_thr then
    return "MED", c
  else
    return "LOW", c
  end
end

------------------------------------------------------------
-- Apply-Logiken
------------------------------------------------------------

local function apply_suggestions_safe(it, level)
  -- Nur HIGH-Confidence, nur leere/generische Felder
  if level ~= "HIGH" then
    return false
  end

  local changed = false

  if is_nonempty(it.home_zone_suggested) and not is_nonempty(it.home_zone) then
    it.home_zone = it.home_zone_suggested
    changed = true
  end
  if is_nonempty(it.home_zone_sub_suggested) and not is_nonempty(it.home_zone_sub) then
    it.home_zone_sub = it.home_zone_sub_suggested
    changed = true
  end
  if is_nonempty(it.ucs_category_suggested) then
    if (not it.ucs_category) or it.ucs_category == "" or is_generic_ucs(it.ucs_category) then
      it.ucs_category = it.ucs_category_suggested
      changed = true
    end
  end
  if is_nonempty(it.df95_catid_suggested) and not is_nonempty(it.df95_catid) then
    it.df95_catid = it.df95_catid_suggested
    changed = true
  end

  if changed then
    it.ai_status = "auto_safe"
  end

  return changed
end

local function apply_suggestions_aggressive(it, level)
  -- HIGH: darf generische UCS überschreiben, leere Felder füllen
  -- MED : darf nur leere Felder füllen
  local changed = false

  local function can_apply_home(current, lvl)
    if not is_nonempty(current) then return true end
    -- Vorläufig konservativ: existierende HomeZone/Sub werden nicht überschrieben.
    return false
  end

  local lvl = level or "LOW"

  if is_nonempty(it.home_zone_suggested) and can_apply_home(it.home_zone, lvl) then
    it.home_zone = it.home_zone_suggested
    changed = true
  end
  if is_nonempty(it.home_zone_sub_suggested) and can_apply_home(it.home_zone_sub, lvl) then
    it.home_zone_sub = it.home_zone_sub_suggested
    changed = true
  end

  if is_nonempty(it.ucs_category_suggested) then
    if lvl == "HIGH" then
      if (not it.ucs_category) or it.ucs_category == "" or is_generic_ucs(it.ucs_category) then
        it.ucs_category = it.ucs_category_suggested
        changed = true
      end
    elseif lvl == "MED" then
      if (not it.ucs_category) or it.ucs_category == "" then
        it.ucs_category = it.ucs_category_suggested
        changed = true
      end
    end
  end

  if is_nonempty(it.df95_catid_suggested) then
    if not is_nonempty(it.df95_catid) then
      it.df95_catid = it.df95_catid_suggested
      changed = true
    end
  end

  if changed then
    if lvl == "HIGH" then
      it.ai_status = "auto_high"
    elseif lvl == "MED" then
      it.ai_status = "auto_med"
    else
      it.ai_status = "auto"
    end
  end

  return changed
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local default_db = get_default_db_path()
  local ok, csv = r.GetUserInputs(
    "DF95 AutoIngest V3 – Modus wählen",
    4,
    "Mode (ANALYZE/SAFE/AGGR),High-Threshold (0-1),Med-Threshold (0-1),Subset-Only? (0=alle,1=Subset)",
    "SAFE,0.85,0.65,0"
  )
  if not ok then return end

  local mode_str, high_str, med_str, subset_str = csv:match("([^,]*),([^,]*),([^,]*),([^,]*)")
  mode_str = (mode_str or ""):upper()
  local high_thr = tonumber(high_str) or 0.85
  local med_thr  = tonumber(med_str)  or 0.65

  if high_thr < 0.0 then high_thr = 0.0 end
  if high_thr > 1.0 then high_thr = 1.0 end
  if med_thr < 0.0 then med_thr = 0.0 end
  if med_thr > 1.0 then med_thr = 1.0 end
  if med_thr > high_thr then
    med_thr = high_thr
  end
  local subset_only = tonumber(subset_str or "0") == 1
  local subset_map = nil
  if subset_only then
    subset_map, err = load_subset_map()
    if not subset_map then
      r.ShowMessageBox("Subset-Mode angefordert, aber Subset-Datei konnte nicht geladen werden:\n" .. tostring(err or "unbekannt") .. "\nEs wird auf ALLE Items zurückgefallen.", "DF95 AutoIngest V3", 0)
      subset_only = false
    end
  end


  if mode_str ~= "ANALYZE" and mode_str ~= "SAFE" and mode_str ~= "AGGR" then
    r.ShowMessageBox("Ungültiger Modus: " .. tostring(mode_str) .. "\nErlaubt: ANALYZE, SAFE, AGGR", "DF95 AutoIngest V3", 0)
    return
  end

  local db_path = default_db
  local f, err = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox("JSON-Datenbank nicht gefunden:\n" .. tostring(db_path) .. "\n\nBitte zuerst den DF95 SampleDB Scanner / Exporter ausführen.", "DF95 AutoIngest V3", 0)
    return
  end

  local text = f:read("*all")
  f:close()

  local db, derr = decode_json(text)
  if not db then
    r.ShowMessageBox("Fehler beim Lesen der JSON-Datenbank:\n" .. tostring(derr), "DF95 AutoIngest V3", 0)
    return
  end

  local items = db.items or db
  if type(items) ~= "table" or #items == 0 then
    r.ShowMessageBox("SampleDB enthält keine Items oder hat ein unbekanntes Format.", "DF95 AutoIngest V3", 0)
    return
  end

  local total = #items
  local cnt_high, cnt_med, cnt_low = 0, 0, 0
  local applied_safe, applied_aggr = 0, 0
  local subset_count = 0

  local changes = {}
  local run_meta = {
    ts           = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    mode         = mode_str,
    high_thr     = high_thr,
    med_thr      = med_thr,
    subset_only  = subset_only,
    subset_size  = 0, -- wird später mit subset_count befüllt
    db_path      = db_path,
  }

  for _, it in ipairs(items) do
    local do_process = true
    if subset_only and subset_map then
      local fp = tostring(it.filepath or "")
      if not subset_map[fp] then
        do_process = false
      end
    end

    if not do_process then
      goto continue_item
    end

    subset_count = subset_count + 1

    local level, conf = classify_confidence(it, high_thr, med_thr)

    if level == "HIGH" then
      cnt_high = cnt_high + 1
    elseif level == "MED" then
      cnt_med = cnt_med + 1
    else
      cnt_low = cnt_low + 1
    end

    if mode_str == "ANALYZE" then
      if level == "MED" then
        it.df95_ai_review_flag = "REVIEW_MED"
      elseif level == "LOW" then
        it.df95_ai_review_flag = "REVIEW_LOW"
      else
        it.df95_ai_review_flag = "OK_HIGH"
      end
    elseif mode_str == "SAFE" then
      local before_state = snapshot_item_state(it)
      local changed = apply_suggestions_safe(it, level)
      if changed then
        applied_safe = applied_safe + 1
        local after_state = snapshot_item_state(it)
        changes[#changes+1] = {
          filepath = tostring(it.filepath or ""),
          before   = before_state,
          after    = after_state,
        }
      end
    elseif mode_str == "AGGR" then
      local before_state = snapshot_item_state(it)
      local changed = apply_suggestions_aggressive(it, level)
      if changed then
        applied_aggr = applied_aggr + 1
        local after_state = snapshot_item_state(it)
        changes[#changes+1] = {
          filepath = tostring(it.filepath or ""),
          before   = before_state,
          after    = after_state,
        }
      end
    end

::continue_item::
  end

  run_meta.subset_size = subset_count

  if (mode_str == "SAFE" or mode_str == "AGGR") and #changes > 0 then
    run_meta.items = changes
    write_changelog_entry(run_meta)
  end

  -- Nur schreiben, wenn Modus nicht ANALYZE ist? 
  -- Wir entscheiden: ANALYZE schreibt auch die review_flags, weil diese zur manuellen Arbeit dienen.
  local out_text = encode_json_table(db, 0)
  local wf, werr = io.open(db_path, "w")
  if not wf then
    r.ShowMessageBox("Fehler beim Schreiben der JSON-Datenbank:\n" .. tostring(werr), "DF95 AutoIngest V3", 0)
    return
  end
  wf:write(out_text)
  wf:close()

  local msg = {}
  msg[#msg+1] = "DF95 AutoIngest V3 abgeschlossen."
  msg[#msg+1] = ""
  msg[#msg+1] = "DB: " .. tostring(db_path)
  msg[#msg+1] = string.format("Items gesamt: %d", total)
  msg[#msg+1] = string.format("HIGH (>= %.2f): %d", high_thr, cnt_high)
  msg[#msg+1] = string.format("MED  (>= %.2f): %d", med_thr, cnt_med)
  msg[#msg+1] = string.format("LOW           : %d", cnt_low)
  if subset_only and subset_map then
    msg[#msg+1] = ""
    msg[#msg+1] = string.format("Subset-Mode aktiv: %d Items im Subset verarbeitet.", subset_count)
  end

  if mode_str == "ANALYZE" then
    msg[#msg+1] = ""
    msg[#msg+1] = "Modus: ANALYZE (nur df95_ai_review_flag aktualisiert, keine Field-Applies)."
  elseif mode_str == "SAFE" then
    msg[#msg+1] = ""
    msg[#msg+1] = "Modus: SAFE"
    msg[#msg+1] = string.format("Angewendete Suggestions (SAFE): %d", applied_safe)
  elseif mode_str == "AGGR" then
    msg[#msg+1] = ""
    msg[#msg+1] = "Modus: AGGRESSIVE"
    msg[#msg+1] = string.format("Angewendete Suggestions (AGGR): %d", applied_aggr)
  end

  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 AutoIngest V3", 0)
end

main()
