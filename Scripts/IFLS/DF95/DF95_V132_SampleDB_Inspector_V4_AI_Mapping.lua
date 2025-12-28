-- @description DF95_V132 SampleDB – Inspector V4 (AI Tags & Mapping)
-- @version 1.0
-- @author DF95
-- @about
--   Inspector V4 erweitert die DF95 SampleDB-Tools um eine AI-zentrierte Sicht:
--     * Zeigt Statistiken über AI-Tags (ai_model, ai_primary, ai_labels).
--     * Filtert nach:
--         - AI Primary Label (Substring)
--         - UCS Category (Substring)
--         - Min. Quality Grade (A/B/C/D), falls vorhanden
--     * Bietet einen Mapping-Modus:
--         - Weise allen Items mit bestimmtem AI-Label eine (neue) UCS-Category /
--           Subcategory / df95_catid zu.
--         - Optional nur, wenn die bisherige UCS-Category "leer" oder "MISC" ist.
--
--   Hinweise:
--     * Dieses Script erwartet eine DF95 SampleDB JSON:
--           <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--       mit Feldern wie:
--           path, ucs_category, ucs_subcategory, df95_catid,
--           ai_model, ai_primary, ai_labels, ai_scores,
--           quality_grade (optional)
--     * AI-Felder werden normalerweise durch das Add-On
--           DF95_V131_SampleDB_AI_Classify_YAMNet.lua
--       befüllt.
--     * Mapping kann sowohl "non-destruktiv" (nur *_ml Felder setzen) als auch
--       "destruktiv" (ufu_category/df95_catid überschreiben) genutzt werden.

local r = reaper

------------------------------------------------------------
-- JSON-Decoder / Encoder (wie in AI-Classify)
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
-- Helper
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function get_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
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

local function inc(map, key)
  if key == nil then key = "(nil)" end
  if key == "" then key = "(empty)" end
  map[key] = (map[key] or 0) + 1
end

local function print_sorted_count_map(title, map)
  r.ShowConsoleMsg("\n"..title..":\n")
  local arr = {}
  for k, v in pairs(map) do
    arr[#arr+1] = { key = k, val = v }
  end
  table.sort(arr, function(a,b) return a.val > b.val end)
  for _, e in ipairs(arr) do
    r.ShowConsoleMsg(string.format("  %-30s : %d\n", tostring(e.key), e.val))
  end
end

------------------------------------------------------------
-- Filterfunktionen
------------------------------------------------------------


local function item_matches_view_filters(it, filters)
  if not filters then return true end

  -- Filter nach AI Primary Label
  if filters.ai_label then
    local ap = (it.ai_primary or ""):upper()
    if not ap:find(filters.ai_label:upper(), 1, true) then
      return false
    end
  end

  -- Filter nach UCS Category
  if filters.ucs_cat then
    local uc = (it.ucs_category or ""):upper()
    if not uc:find(filters.ucs_cat:upper(), 1, true) then
      return false
    end
  end

  -- Filter nach AI-Tag (ai_tags / ai_labels)
  if filters.ai_tag then
    local needle = filters.ai_tag:upper()
    local found = false

    -- Neue Struktur: ai_tags (Array of strings, z.B. vom AI-Worker)
    if type(it.ai_tags) == "table" then
      for _, t in ipairs(it.ai_tags) do
        local ts = tostring(t or ""):upper()
        if ts:find(needle, 1, true) then
          found = true
          break
        end
      end
    end

    -- Ältere Struktur: ai_labels (Array of strings)
    if (not found) and type(it.ai_labels) == "table" then
      for _, t in ipairs(it.ai_labels) do
        local ts = tostring(t or ""):upper()
        if ts:find(needle, 1, true) then
          found = true
          break
        end
      end
    end

    if not found then
      return false
    end
  end

  -- Filter nach Quality Grade (A/B/C/D)
  if filters.min_grade then
    local item_rank = grade_to_rank(it.quality_grade)
    local min_rank  = grade_to_rank(filters.min_grade)
    if item_rank < min_rank then
      return false
    end
  end

  return true
end


------------------------------------------------------------
-- VIEW-Modus
------------------------------------------------------------


local function run_view_mode(db, items)
  local ok, vals = r.GetUserInputs(
    "DF95 Inspector V4 – VIEW (AI Tags + Zoom Channels)",
    4,
    "AI Primary Label-Filter (Substring, leer=alle),UCS Category...(Substring, leer=alle),AI Tag-Filter (Substring, leer=alle),Min Quality Grade (A/B/C/D, leer=keine)",
    ",,,"
  )
  if not ok then return end

  local s1, s2, s3, s4 = vals:match("([^,]*),([^,]*),([^,]*),([^,]*)")
  local function norm(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
  end

  local filters = {
    ai_label = norm(s1),
    ucs_cat  = norm(s2),
    ai_tag   = norm(s3),
    min_grade = norm(s4),
  }

  local filtered = {}
  local stats_ai_primary = {}
  local stats_ai_model   = {}
  local stats_ucs_cat    = {}
  local stats_grade      = {}
  local stats_ai_tags    = {}

  for _, it in ipairs(items) do
    if item_matches_view_filters(it, filters) then
      filtered[#filtered+1] = it
      inc(stats_ai_primary, it.ai_primary or "(none)")
      inc(stats_ai_model,   it.ai_model   or "(none)")
      inc(stats_ucs_cat,    it.ucs_category or "(none)")
      inc(stats_grade,      it.quality_grade or "(none)")

      -- AI-Tags aus ai_tags / ai_labels in Statistik aufnehmen
      if type(it.ai_tags) == "table" then
        for _, t in ipairs(it.ai_tags) do
          inc(stats_ai_tags, tostring(t or "(none)"))
        end
      elseif type(it.ai_labels) == "table" then
        for _, t in ipairs(it.ai_labels) do
          inc(stats_ai_tags, tostring(t or "(none)"))
        end
      end
    end
  end

  table.sort(filtered, function(a, b)
    local ap_a = (a.ai_primary or "")
    local ap_b = (b.ai_primary or "")
    if ap_a == ap_b then
      local qa = tonumber(a.quality_score or 0) or 0
      local qb = tonumber(b.quality_score or 0) or 0
      return qa > qb
    end
    return ap_a < ap_b
  end)

  r.ShowConsoleMsg("")
  r.ShowConsoleMsg("============================================================\n")
  r.ShowConsoleMsg(" DF95 SampleDB – Inspector V4 (VIEW / AI Tags + Zoom Channels)\n")
  r.ShowConsoleMsg(" DB: "..tostring(get_db_path()).."\n")
  r.ShowConsoleMsg(" Version: "..tostring(db.version or "unknown").."\n")
  r.ShowConsoleMsg(" Items gesamt: "..tostring(#items).."\n")
  r.ShowConsoleMsg(" Items gefiltert: "..tostring(#filtered).."\n")
  r.ShowConsoleMsg("------------------------------------------------------------\n")

  r.ShowConsoleMsg("\n Filter:\n")
  r.ShowConsoleMsg("  AI Primary Label : "..tostring(filters.ai_label or "(alle)").."\n")
  r.ShowConsoleMsg("  UCS Category     : "..tostring(filters.ucs_cat  or "(alle)").."\n")
  r.ShowConsoleMsg("  AI Tag           : "..tostring(filters.ai_tag   or "(alle)").."\n")
  r.ShowConsoleMsg("  Min Grade        : "..tostring(filters.min_grade or "(keine)").."\n")

  print_sorted_count_map("AI Primary Labels", stats_ai_primary)
  print_sorted_count_map("AI Model",          stats_ai_model)
  print_sorted_count_map("UCS Category",      stats_ucs_cat)
  print_sorted_count_map("Quality Grade",     stats_grade)
  print_sorted_count_map("AI Tags (ai_tags / ai_labels)", stats_ai_tags)

  r.ShowConsoleMsg("\n------------------ Top-Liste (AI / Quality / Tags / Zoom) ----------------\n")

  local max_show = 200
  for idx, it in ipairs(filtered) do
    if idx > max_show then
      r.ShowConsoleMsg(string.format("\n... (%d weitere Items nicht angezeigt)\n", #filtered - max_show))
      break
    end

    local ap    = tostring(it.ai_primary or "(none)")
    local qg    = tostring(it.quality_grade or "(?)")
    local qs    = tonumber(it.quality_score or 0) or 0
    local uc    = tostring(it.ucs_category or "(none)")
    local us    = tostring(it.ucs_subcategory or "(none)")
    local dc    = tostring(it.df95_catid or "(none)")

    local labels = it.ai_labels or {}
    local tags   = it.ai_tags or {}
    local lbl_str = ""
    if type(labels) == "table" and #labels > 0 then
      lbl_str = table.concat(labels, ", ")
    end
    local tag_str = ""
    if type(tags) == "table" and #tags > 0 then
      tag_str = table.concat(tags, ", ")
    end

    local zoomch_str = ""
    if type(it.zoom_channels) == "table" and #it.zoom_channels > 0 then
      local parts = {}
      for _, chinfo in ipairs(it.zoom_channels) do
        local ch   = chinfo.ch or "?"
        local role = chinfo.role or "?"
        parts[#parts+1] = string.format("CH%d:%s", ch, role)
      end
      zoomch_str = table.concat(parts, ", ")
    end

    local line = string.format(
      "[%04d] AI=%s | Q=%3.0f (%s) | UCS=%s/%s (%s)\n" ..
      "      Labels: %s\n" ..
      "      Tags  : %s\n" ..
      "      Zoom  : %s\n" ..
      "      Path  : %s\n",
      idx,
      ap,
      qs,
      qg,
      uc,
      us,
      dc,
      lbl_str,
      tag_str,
      zoomch_str,
      tostring(it.path or "")
    )
    r.ShowConsoleMsg(line)
  end

  r.ShowConsoleMsg("============================================================\n")
end

------------------------------------------------------------
-- MAP-Modus
------------------------------------------------------------

local function run_map_mode(db, items)
  local ok, vals = r.GetUserInputs(
    "DF95 Inspector V4 – MAP (AI → UCS)",
    5,
    "AI Label (Substring),Ziel UCS-Category,Ziel UCS-Subcategory,Ziel df95_catid,Nur wenn UCS leer/MISC? (YES/NO)",
    ",,,,(YES/NO)"
  )
  if not ok then return end

  local s_label, s_cat, s_sub, s_df95, s_only = vals:match("([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")

  local function norm(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
  end

  local ai_label_sub = norm(s_label)
  local target_cat   = norm(s_cat)
  local target_sub   = norm(s_sub)
  local target_df95  = norm(s_df95)
  local only_empty   = (norm(s_only) or ""):upper()

  if not ai_label_sub or not target_cat then
    r.ShowMessageBox(
      "Mindestens AI Label-Substring und Ziel UCS-Category müssen gesetzt sein.",
      "DF95 Inspector V4 – MAP (AI → UCS)",
      0
    )
    return
  end

  local overwrite = false
  if only_empty == "NO" then
    overwrite = true
  end

  r.Undo_BeginBlock()

  local ai_upper = ai_label_sub:upper()
  local changed  = 0
  local matched  = 0

  for _, it in ipairs(items) do
    local ap = (it.ai_primary or ""):upper()
    if ap:find(ai_upper, 1, true) then
      matched = matched + 1
      local cur_cat = (it.ucs_category or "")
      local is_empty = (cur_cat == "" or cur_cat == "MISC" or cur_cat == "(none)")

      if is_empty or overwrite then
        -- ML-spezifische Felder setzen
        it.ucs_category_ml    = target_cat
        it.ucs_subcategory_ml = target_sub
        it.df95_catid_ml      = target_df95

        -- optional auch die Hauptfelder überschreiben
        if overwrite then
          it.ucs_category    = target_cat
          it.ucs_subcategory = target_sub
          it.df95_catid      = target_df95
        end

        changed = changed + 1
      end
    end
  end

  -- DB zurückschreiben
  local db_path = get_db_path()
  local f = io.open(db_path, "w")
  if not f then
    r.ShowMessageBox(
      "Fehler beim Schreiben der aktualisierten SampleDB:\n"..db_path,
      "DF95 Inspector V4 – MAP (AI → UCS)",
      0
    )
    r.Undo_EndBlock("DF95 SampleDB – Inspector V4 MAP (Fehler)", -1)
    return
  end
  f:write(encode_json_table(db, 0))
  f:close()

  r.Undo_EndBlock("DF95 SampleDB – Inspector V4 MAP (AI → UCS)", -1)

  r.ShowMessageBox(
    string.format(
      "Mapping abgeschlossen.\nAI-Label-Filter: %s\nZiel UCS: %s / %s (%s)\nMatched Items: %d\nGeänderte Items: %d\nOverwrite-Modus: %s",
      ai_label_sub,
      tostring(target_cat or ""),
      tostring(target_sub or ""),
      tostring(target_df95 or ""),
      matched,
      changed,
      overwrite and "ALLES" or "nur UCS leer/MISC"
    ),
    "DF95 Inspector V4 – MAP (AI → UCS)",
    0
  )
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local db_path = get_db_path()
  local f = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "JSON-Datenbank nicht gefunden:\n"..db_path..
      "\n\nBitte zuerst den DF95 SampleDB Scanner ausführen.",
      "DF95 SampleDB – Inspector V4 (AI Tags & Mapping)",
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
      "DF95 SampleDB – Inspector V4 (AI Tags & Mapping)",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die JSON-Datenbank enthält keine Items.\n"..db_path,
      "DF95 SampleDB – Inspector V4 (AI Tags & Mapping)",
      0
    )
    return
  end

  local ok, mode = r.GetUserInputs(
    "DF95 Inspector V4 – Modus wählen",
    1,
    "Mode (VIEW oder MAP)",
    "VIEW"
  )
  if not ok then return end

  mode = (mode or ""):upper()
  if mode == "VIEW" then
    run_view_mode(db, items)
  elseif mode == "MAP" then
    run_map_mode(db, items)
  else
    r.ShowMessageBox(
      "Ungültiger Modus: "..tostring(mode).."\nBitte VIEW oder MAP eingeben.",
      "DF95 SampleDB – Inspector V4 (AI Tags & Mapping)",
      0
    )
  end
end

main()
