-- @description DF95_V134 SampleDB – UCS Batch Renamer (Full Version)
-- @version 1.0
-- @author DF95
-- @about
--   Benennt WAV/AIFF-Dateien aus der DF95 SampleDB nach einem konsistenten,
--   UCS-inspirierten Schema um. Arbeitet auf der Multi-UCS-Datenbank:
--
--       <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Pipeline-Idee:
--     * ZUERST: DF95 SampleDB Scanner ausführen (Loudness/Quality/UCS).
--     * DANN (optional): DF95 AI Classify (YAMNet) und Inspector V4 (AI Mapping).
--     * ZULETZT: Dieses Script, um physische Dateien umzubenennen.
--
--   Wichtige Eckpunkte:
--     * Nutzt Felder:
--         path, ucs_category, ucs_subcategory, df95_catid,
--         ai_primary (optional), quality_grade (optional), source_id (optional)
--     * Erzeugt neue Dateinamen im Format:
--
--         <CatID>_<Descriptor>_<Index>_<Src>.ext
--
--       z.B.:
--         DRUMKik_WarmPunch_001_ZF6.wav
--         WATRSea_HeavyWaves_003_H5n.wav
--         WHSHGen_SciFiRise_010_AND.wav
--
--     * "CatID" ist df95_catid oder ein Fallback aus UCS-Category/Subcategory.
--     * "Descriptor" kommt aus ai_primary, UCS-Subcategory oder ursprünglichem Namen.
--     * "Index" ist eine laufende Nummer pro (CatID+Descriptor)-Gruppe.
--     * "Src" ist ein komprimierter SourceID-Tag (z.B. ZoomF6 -> ZF6).
--
--   Sicherheit:
--     * Es gibt einen DRY-RUN Modus (nur Vorschau, keine Umbenennung).
--     * Es wird ein Rename-Log als JSON geschrieben:
--         DF95_SampleDB_UCS_RenameLog_YYYYMMDD_HHMMSS.json
--     * Bei echter Umbenennung werden:
--         - die Dateien mit os.rename() verschoben/umbenannt
--         - die Einträge in DF95_SampleDB_Multi_UCS.json aktualisiert.
--
--   Hinweis:
--     * OFFIZIELLE UCS-Codes werden hier NICHT hart beansprucht; df95_catid ist
--       eine DF95-interne CatID, die UCS-kompatibel gestaltet werden kann.
--     * Dieser Renamer ist bewusst "praktisch" gedacht, nicht als offizielles
--       UCS-Authoring-Tool.

local r = reaper

------------------------------------------------------------
-- JSON Decoder / Encoder
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
-- Helper: Pfad / String
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

local function dirname(path)
  if not path then return "" end
  local dir = path:match("^(.*[\\/])")
  if dir then
    if dir:sub(-1) == "\\" or dir:sub(-1) == "/" then
      dir = dir:sub(1, -2)
    end
    return dir
  end
  return ""
end

local function basename(path)
  return (path or ""):match("([^\\/]+)$") or path
end

local function split_ext(name)
  local base, ext = name:match("^(.*)(%.[^%.]+)$")
  if not base then
    return name, ""
  end
  return base, ext
end

local function upper(s) return (s or ""):upper() end

local function sanitize_token(s)
  s = s or ""
  -- Ersetze nicht-Alphanumerik durch Unterstriche
  s = s:gsub("[^%w]+", "_")
  -- Mehrere Unterstriche zusammenfassen
  s = s:gsub("_+", "_")
  -- führende/trailing _ entfernen
  s = s:gsub("^_", ""):gsub("_$", "")
  -- Begrenze Länge
  if #s > 24 then
    s = s:sub(1,24)
  end
  if s == "" then
    s = "GEN"
  end
  return s
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
-- SourceID-Kürzel
------------------------------------------------------------

local function compress_source_id(src)
  if not src or src == "" then return nil end
  src = src:lower()
  if src:find("zoom") and src:find("f6") then
    return "ZF6"
  elseif src:find("zoom") and (src:find("h5") or src:find("h5n")) then
    return "ZH5"
  elseif src:find("android") or src:find("fieldrecapp") or src:find("fieldrec") then
    return "AND"
  elseif src:find("iphone") or src:find("ios") then
    return "IOS"
  elseif src:find("soma") or src:find("ether") then
    -- SOMA Ether EMF Recorder
    return "SME"
  elseif src:find("telephone") or src:find("phone_pickup") or src:find("pickup_coil") or src:find("pick-up") or src:find("mcm") then
    -- Telephone Pick-Up Coil / Induction
    return "TCO"
  end
  -- Fallback: ersten 3 alphanumerischen Zeichen
  local compact = src:gsub("[^%w]", "")
  if #compact >= 3 then
    return compact:sub(1,3):upper()
  elseif #compact > 0 then
    return compact:upper()
  end
  return nil
end


------------------------------------------------------------
-- CatID aus UCS ableiten (Fallback)
------------------------------------------------------------

local function derive_catid(it)
  local dfcat = it.df95_catid
  if dfcat and dfcat ~= "" then
    return sanitize_token(dfcat)
  end

  local uc  = upper(it.ucs_category or "")
  local sub = upper(it.ucs_subcategory or "")

  if uc:find("DRUM") and sub:find("KICK") then return "DRUMKik" end
  if uc:find("DRUM") and sub:find("SNARE") then return "DRUMSnr" end
  if uc:find("DRUM") and (sub:find("HAT") or sub:find("CYMBAL")) then return "DRUMHat" end
  if uc:find("WATER") or uc:find("LIQUID") then return "WATRGen" end
  if uc:find("WHOOSH") or uc:find("SWISH") then return "WHSHGen" end
  if uc:find("FOLEY") then return "FOLEY" end
  if uc:find("AMB") or uc:find("AMBIENCE") then return "AMBIENT" end

  if uc ~= "" then
    return sanitize_token(uc.."_"..sub)
  end

  return "MISC"
end

------------------------------------------------------------
-- AI-gestützte Label-Ableitung (Material / Instrument / Tags)
------------------------------------------------------------

local function derive_ai_label(it)
  -- Explizites ai_primary Feld hat Vorrang (falls gesetzt)
  if it.ai_primary and it.ai_primary ~= "" then
    return it.ai_primary
  end

  -- Instrument ist oft die beste Kurzbeschreibung (z.B. SNARE, KICK, BELL)
  if it.df95_instrument and it.df95_instrument ~= "" then
    return it.df95_instrument
  end

  -- Kombination aus Material + UCS-Subcategory (z.B. WOOD_HIT, METAL_RATTLE)
  if it.df95_material and it.df95_material ~= "" and it.ucs_subcategory and it.ucs_subcategory ~= "" then
    return string.format("%s_%s", it.df95_material, it.ucs_subcategory)
  end

  -- Nur Material (z.B. WOOD, METAL), wenn sonst nichts da ist
  if it.df95_material and it.df95_material ~= "" then
    return it.df95_material
  end

  -- AI-Tags (vom AIWorker) – nimm den ersten als Primärbeschreibung
  if type(it.ai_tags) == "table" then
    local primary = it.ai_tags[1]
    if primary and primary ~= "" then
      return primary
    end
  end

  return nil
end

------------------------------------------------------------
-- Descriptor ableiten (AI / UCS / Filename)
------------------------------------------------------------

local function derive_descriptor(it)
  local ai = derive_ai_label(it)
  if ai and ai ~= "" then
    return sanitize_token(ai)
  end

  if it.ucs_subcategory and it.ucs_subcategory ~= "" then
    return sanitize_token(it.ucs_subcategory)
  end

  local base = basename(it.path or "")
  local noext = split_ext(base)
  return sanitize_token(noext)
end

------------------------------------------------------------
-- Gruppierung & Zielname bilden
------------------------------------------------------------

local function build_target_name(it, counters)
  local path = it.path
  if not path or path == "" then return nil, "no_path" end

  local dir = dirname(path)
  if dir == "" then
    return nil, "no_dir"
  end

  local base = basename(path)
  local noext, ext = split_ext(base)
  if ext == "" then
    ext = ".wav" -- Fallback
  end

  local catid = derive_catid(it)
  local desc  = derive_descriptor(it)
  local src_tag = compress_source_id(it.source_id or "") or ""

  local group_key = catid .. "|" .. desc .. "|" .. src_tag

  local cur = counters[group_key] or 0
  cur = cur + 1
  counters[group_key] = cur

  local idx_str = string.format("%03d", cur)

  local parts = { catid, desc, idx_str }
  if src_tag ~= "" then
    parts[#parts+1] = src_tag
  end

  local fname = table.concat(parts, "_") .. ext

  local new_path = join_path(dir, fname)
  return new_path, nil
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
      "DF95 SampleDB – UCS Renamer",
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
      "DF95 SampleDB – UCS Renamer",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die JSON-Datenbank enthält keine Items.\n"..db_path,
      "DF95 SampleDB – UCS Renamer",
      0
    )
    return
  end

  local ok, vals = r.GetUserInputs(
    "DF95 UCS Renamer – Optionen",
    3,
    "Mode (DRY oder RENAME),Nur Items ohne RenameHistory? (YES/NO),Min Quality Grade (A/B/C/D, leer=keine)",
    "DRY,YES,"
  )
  if not ok then return end

  local s_mode, s_only, s_grade = vals:match("([^,]*),([^,]*),([^,]*)")
  s_mode  = (s_mode or ""):upper()
  s_only  = (s_only or ""):upper()

  local dry_run = (s_mode ~= "RENAME")
  local only_missing = (s_only == "YES")

  local min_rank = 0
  if s_grade and s_grade ~= "" then
    min_rank = grade_to_rank(s_grade)
  end

  local counters = {}
  local rename_plan = {}

  for idx, it in ipairs(items) do
    local path = it.path
    if path and path ~= "" then
      -- optional: Quality-Filter
      local rank = grade_to_rank(it.quality_grade)
      if rank >= min_rank then
        -- optional: Nur Items ohne vorherige Rename-History
        if (not only_missing) or (it.ucs_renamed_from == nil) then
          local new_path, err_reason = build_target_name(it, counters)
          if new_path and new_path ~= path then
            rename_plan[#rename_plan+1] = {
              index    = idx,
              old_path = path,
              new_path = new_path,
            }
          end
        end
      end
    end
  end

  if #rename_plan == 0 then
    r.ShowMessageBox(
      "Keine Items zum Umbenennen gefunden (Filter/Modus prüfen).",
      "DF95 SampleDB – UCS Renamer",
      0
    )
    return
  end

  -- Preview-Text
  local preview_lines = {}
  local max_preview = 50
  for i = 1, math.min(max_preview, #rename_plan) do
    local rnm = rename_plan[i]
    preview_lines[#preview_lines+1] = string.format("%4d: %s\n      -> %s\n",
      rnm.index, rnm.old_path, rnm.new_path)
  end
  if #rename_plan > max_preview then
    preview_lines[#preview_lines+1] = string.format("... (%d weitere Einträge)\n", #rename_plan - max_preview)
  end

  local summary = string.format(
    "Mode: %s\nNur ohne History: %s\nMin Grade: %s\nGeplante Umbenennungen: %d\n\nBEISPIELE:\n\n%s",
    dry_run and "DRY (nur Vorschau)" or "RENAME (Dateien werden umbenannt)",
    only_missing and "YES" or "NO",
    s_grade ~= "" and s_grade or "(keine)",
    #rename_plan,
    table.concat(preview_lines)
  )

  local btn = r.ShowMessageBox(
    summary .. "\n\nFortfahren?",
    "DF95 SampleDB – UCS Renamer",
    3 -- Yes/No/Cancel
  )
  if btn ~= 6 then -- 6 = Yes
    return
  end

  -- Log-Datei vorbereiten
  local res = r.GetResourcePath()
  local log_name = os.date("DF95_SampleDB_UCS_RenameLog_%Y%m%d_%H%M%S.json")
  local log_path = join_path(join_path(res, "Support"), log_name)

  local log_tbl = {
    db_path   = db_path,
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    mode      = dry_run and "DRY" or "RENAME",
    entries   = {},
  }

  if dry_run then
    -- Nur Log schreiben, DB und Files bleiben unverändert.
    for _, rnm in ipairs(rename_plan) do
      log_tbl.entries[#log_tbl.entries+1] = {
        old_path = rnm.old_path,
        new_path = rnm.new_path,
        status   = "PLANNED"
      }
    end

    local lf = io.open(log_path, "w")
    if lf then
      lf:write(encode_json_table(log_tbl, 0))
      lf:close()
    end

    r.ShowMessageBox(
      "DRY-RUN abgeschlossen.\nLog geschrieben:\n"..log_path,
      "DF95 SampleDB – UCS Renamer",
      0
    )
    return
  end

  -- RENAME-Modus: Dateien umbenennen & DB aktualisieren
  r.Undo_BeginBlock()

  local renamed = 0
  for _, rnm in ipairs(rename_plan) do
    local old_path = rnm.old_path
    local new_path = rnm.new_path

    -- Ziel-Verzeichnis anlegen, falls nötig
    local new_dir = dirname(new_path)
    if new_dir ~= "" then
      -- simple mkdir -p
      local attr = r.GetFileAttributes and r.GetFileAttributes(new_dir)
      if not attr then
        -- REAPER Lua hat kein mkdir; wir benutzen os.execute
        local sep = package.config:sub(1,1)
        if sep == "\\" then
          os.execute(string.format('mkdir "%s"', new_dir))
        else
          os.execute(string.format('mkdir -p "%s"', new_dir))
        end
      end
    end

    local ok_rename = os.rename(old_path, new_path)
    if ok_rename then
      renamed = renamed + 1
      -- DB aktualisieren
      local it = items[rnm.index]
      if it then
        it.ucs_renamed_from = old_path
        it.path = new_path
      end
      log_tbl.entries[#log_tbl.entries+1] = {
        old_path = old_path,
        new_path = new_path,
        status   = "RENAMED"
      }
    else
      log_tbl.entries[#log_tbl.entries+1] = {
        old_path = old_path,
        new_path = new_path,
        status   = "FAILED"
      }
    end
  end

  -- DB zurückschreiben
  local fdb = io.open(db_path, "w")
  if fdb then
    fdb:write(encode_json_table(db, 0))
    fdb:close()
  end

  -- Log schreiben
  local lf = io.open(log_path, "w")
  if lf then
    lf:write(encode_json_table(log_tbl, 0))
    lf:close()
  end

  r.Undo_EndBlock("DF95 SampleDB – UCS Renamer (Batch)", -1)

  r.ShowMessageBox(
    string.format("Umbenennen abgeschlossen.\nErfolgreich: %d\nLog: %s", renamed, log_path),
    "DF95 SampleDB – UCS Renamer",
    0
  )
end

main()
