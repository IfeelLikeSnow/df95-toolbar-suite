-- @description DF95 Fieldrec – Library SampleDB Ingest (from UCS Regions)
-- @version 1.0
-- @author DF95
-- @about
--   Liest Regions im aktuellen Projekt, deren Namen bereits nach einem
--   UCS-inspirierten Schema aufgebaut sind (z.B. durch:
--     * DF95_Fieldrec_AI_LibraryCommit_FromItems.lua
--     * DF95_Fieldrec_UCS_RegionNormalizer.lua)
--   und schreibt passende Einträge in die DF95 Multi-UCS SampleDB:
--
--       <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Wichtige Eigenschaften:
--     * Es werden WAV/AIFF/FLAC-Dateien in einem angegebenen Zielordner gesucht,
--       deren Basisname (ohne Extension) dem Region-Namen entspricht.
--     * Für jede gefundene Datei wird (falls noch nicht in der DB vorhanden)
--       ein neuer DB-Item-Eintrag erzeugt (path + UCS-Felder).
--     * Bestehende Einträge werden nicht gelöscht.
--     * Vor dem Schreiben wird automatisch ein Backup der SampleDB angelegt.
--
--   Hinweis:
--     * Dies ist eine erste Ingest-Version: Fokus auf Pfad + UCS-Category/Subcategory.
--       Felder wie home_zone, material, object_class, action bleiben vorerst leer
--       oder können später per Analyzer/AI nachgezogen werden.

local r = reaper

------------------------------------------------------------
-- Konfiguration
------------------------------------------------------------

-- Unterstützte Audio-Extensions
local AUDIO_EXTS = {
  [".wav"]  = true,
  [".aif"]  = true,
  [".aiff"] = true,
  [".flac"] = true,
}

-- Nur Regions berücksichtigen, deren Name mind. so viele "_" enthält
local MIN_UNDERSCORES = 2

------------------------------------------------------------
-- Generic Utils
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function sanitize_token(s, upper)
  s = s or ""
  s = s:gsub("[^%w]+", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_+", "")
  s = s:gsub("_+$", "")
  if upper then
    s = s:upper()
  end
  return s
end

local function titlecase_underscore(s)
  s = s or ""
  local parts = {}
  for part in s:gmatch("[^_]+") do
    local first = part:sub(1,1):upper()
    local rest  = part:sub(2):lower()
    parts[#parts+1] = first .. rest
  end
  return table.concat(parts, "_")
end

local function split_ext(name)
  if not name then return "", "" end
  local idx = name:match(".*()%.")
  if idx then
    return name:sub(1, idx-1), name:sub(idx)
  else
    return name, ""
  end
end

------------------------------------------------------------
-- Project Regions lesen & UCS-Namen parsen
------------------------------------------------------------

local function parse_ucs_from_region_name(name)
  if not name or name == "" then return nil end

  -- Nur bis zum ersten Whitespace
  local base = name:match("^(%S+)") or name
  local underscore_count = select(2, base:gsub("_", ""))
  if underscore_count < MIN_UNDERSCORES then
    return nil
  end

  local tokens = {}
  for tok in base:gmatch("([^_]+)") do
    tokens[#tokens+1] = tok
  end
  if #tokens < 2 then
    return nil
  end

  local cat_raw = tokens[1]
  local sub_raw = tokens[2]
  local desc_tokens = {}
  for i = 3, #tokens do
    desc_tokens[#desc_tokens+1] = tokens[i]
  end
  local desc_raw = table.concat(desc_tokens, "_")

  local cat = sanitize_token(cat_raw, true)  -- UCS_CATEGORY: UPPER
  local sub = sanitize_token(sub_raw, false)
  sub = titlecase_underscore(sub)

  local desc = sanitize_token(desc_raw, false)
  desc = titlecase_underscore(desc)

  if cat == "" or sub == "" then
    return nil
  end

  local df95_catid = cat .. "_" .. sub

  return {
    ucs_category     = cat,
    ucs_subcategory  = sub,
    descriptor       = desc,
    df95_catid       = df95_catid,
    raw_name         = name,
    base_token       = base,
  }
end

local function collect_regions_with_ucs()
  local proj = 0
  local num_markers, num_regions = r.CountProjectMarkers(proj)
  local regions = {}

  local idx = 0
  while true do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(idx)
    if retval == 0 then break end
    if isrgn then
      local ucs = parse_ucs_from_region_name(name)
      if ucs then
        regions[#regions+1] = {
          index  = markrgnindexnumber,
          pos    = pos,
          rgnend = rgnend,
          name   = name,
          ucs    = ucs,
        }
      end
    end
    idx = idx + 1
  end

  return regions
end

------------------------------------------------------------
-- Files im Zielordner scannen
------------------------------------------------------------

local function scan_audio_files(base_dir, recursive)
  base_dir = base_dir:gsub("[/\\]+$", "")
  local files = {}
  local map_by_basename = {}

  local function scan_dir(dir)
    local i = 0
    while true do
      local fn = r.EnumerateFiles(dir, i)
      if not fn then break end
      local full = join_path(dir, fn)
      local base = fn
      local name_noext, ext = split_ext(base)
      local ext_lower = ext:lower()
      if AUDIO_EXTS[ext_lower] then
        files[#files+1] = full
        local key = name_noext
        map_by_basename[key] = map_by_basename[key] or {}
        table.insert(map_by_basename[key], full)
      end
      i = i + 1
    end

    if recursive then
      local j = 0
      while true do
        local sub = r.EnumerateSubdirectories(dir, j)
        if not sub then break end
        scan_dir(join_path(dir, sub))
        j = j + 1
      end
    end
  end

  scan_dir(base_dir)
  return files, map_by_basename
end

------------------------------------------------------------
-- Audio-Facts holen
------------------------------------------------------------

local function get_wav_info(path)
  local src = r.PCM_Source_CreateFromFile(path)
  if not src then return nil end

  local len = r.GetMediaSourceLength(src)
  local sr  = r.GetMediaSourceSampleRate(src)
  local ch  = r.GetMediaSourceNumChannels(src)

  r.PCM_Source_Destroy(src)

  return {
    length     = len or 0,
    samplerate = sr or 0,
    channels   = ch or 0,
  }
end

------------------------------------------------------------
-- SampleDB JSON laden/schreiben (Multi-UCS)
------------------------------------------------------------

local function get_db_path()
  local res = r.GetResourcePath()
  local db_dir = res .. sep .. "Support" .. sep .. "DF95_SampleDB"
  local db_path = db_dir .. sep .. "DF95_SampleDB_Multi_UCS.json"
  return db_dir, db_path
end

local function ensure_dir(path)
  if path == "" then return end
  local attr = r.GetFileAttributes and r.GetFileAttributes(path)
  if attr then return true end
  if sep == "\\" then
    os.execute(string.format('mkdir "%s"', path))
  else
    os.execute(string.format('mkdir -p "%s"', path))
  end
end

-- JSON encoder (simple, array/object detection) – übernommen aus UCS-Light Scanner
------------------------------------------------------------

local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  return str
end

local function json_encode_value(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then
    return "\"" .. json_escape(v) .. "\""
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then
      return "null"
    end
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    return json_encode_table(v, indent)
  elseif t == "nil" then
    return "null"
  else
    return "\"" .. json_escape(tostring(v)) .. "\""
  end
end

function json_encode_table(t, indent)
  indent = indent or ""
  local is_array = true
  local max_index = 0
  for k, v in pairs(t) do
    if type(k) ~= "number" then
      is_array = false
      break
    else
      if k > max_index then max_index = k end
    end
  end

  local parts = {}
  local next_indent = indent .. "  "

  if is_array then
    table.insert(parts, "[")
    for i = 1, max_index do
      if i > 1 then
        table.insert(parts, ",")
      end
      table.insert(parts, "\n")
      table.insert(parts, next_indent .. json_encode_value(t[i], next_indent))
    end
    if max_index > 0 then
      table.insert(parts, "\n")
    end
    table.insert(parts, indent .. "]")
  else
    table.insert(parts, "{\n")
    local first = true
    for k, v in pairs(t) do
      if not first then
        table.insert(parts, ",\n")
      end
      first = false
      table.insert(parts, next_indent .. "\"" .. json_escape(k) .. "\": " .. json_encode_value(v, next_indent))
    end
    table.insert(parts, "\n" .. indent .. "}")
  end

  return table.concat(parts)
end

local function write_db(db, db_path)
  local f = io.open(db_path, "w")
  if not f then
    return false, "Kann DB-Datei nicht schreiben: " .. tostring(db_path)
  end
  f:write(json_encode_table(db, ""))
  f:close()
  return true
end

local function load_db(db_path)
  local f = io.open(db_path, "r")
  if not f then
    return nil, "no_file"
  end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then
    return nil, "empty"
  end

  -- DF95_ReadJSON nutzen, falls vorhanden
  local res = r.GetResourcePath()
  local df95_root = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep
  local reader_path = df95_root .. "DF95_ReadJSON.lua"
  local ok, reader = pcall(dofile, reader_path)
  if not ok or type(reader) ~= "function" then
    return nil, "DF95_ReadJSON.lua konnte nicht geladen werden: " .. tostring(reader)
  end

  local ok2, data = pcall(reader, db_path)
  if not ok2 then
    return nil, "Fehler beim Lesen/Parsen der DB: " .. tostring(data)
  end
  return data
end

local function backup_db(db_dir, db_path)
  local f = io.open(db_path, "r")
  if not f then return nil, "no_db" end
  f:close()

  local ts = os.date("%Y%m%d_%H%M%S")
  local backup_name = "DF95_SampleDB_Multi_UCS_backup_FieldrecIngest_" .. ts .. ".json"
  local backup_path = db_dir .. sep .. backup_name

  local in_f = io.open(db_path, "r")
  if not in_f then
    return nil, "Cannot open DB for backup: " .. db_path
  end
  local content = in_f:read("*a")
  in_f:close()

  local out_f, err = io.open(backup_path, "w")
  if not out_f then
    return nil, "Cannot create backup file: " .. tostring(err)
  end
  out_f:write(content or "")
  out_f:close()

  return backup_path
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()
  r.ClearConsole()
  msg("DF95 Fieldrec – Library SampleDB Ingest (from UCS Regions)")
  msg("-------------------------------------------------------")
  msg("")

  -- 1) Regions mit UCS-Namen einsammeln
  local regions = collect_regions_with_ucs()
  if #regions == 0 then
    r.ShowMessageBox(
      "Keine Regions mit UCS-ähnlichen Namen gefunden.\n\n" ..
      "Bitte zuerst DF95_Fieldrec_AI_LibraryCommit_FromItems und ggf.\n" ..
      "DF95_Fieldrec_UCS_RegionNormalizer ausführen.",
      "DF95 Fieldrec – SampleDB Ingest",
      0
    )
    r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (keine Regions)", -1)
    return
  end

  msg(string.format("Regions mit UCS-Pattern gefunden: %d", #regions))

  -- 2) User nach Library-Ordner fragen (wo die Region-Exports liegen)
  local ok, vals = r.GetUserInputs(
    "DF95 Fieldrec – SampleDB Ingest",
    2,
    "Library-Ordner (Region-Exports),Rekursiv (YES/NO)",
    "C:\\Fieldrec_Library_Exports,YES"
  )
  if not ok then
    r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (abgebrochen)", -1)
    return
  end

  local s_dir, s_rec = vals:match("([^,]*),([^,]*)")
  s_dir = (s_dir or ""):gsub("^%s+",""):gsub("%s+$","")
  s_rec = (s_rec or ""):upper()
  if s_dir == "" then
    r.ShowMessageBox("Bitte einen Library-Ordner angeben.", "DF95 Fieldrec – SampleDB Ingest", 0)
    r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (kein Ordner)", -1)
    return
  end
  local recursive = (s_rec ~= "NO")

  msg("")
  msg("Scanne Library-Ordner: " .. s_dir .. " (rekursiv=" .. tostring(recursive) .. ") ...")
  local files, map_by_basename = scan_audio_files(s_dir, recursive)
  msg(string.format("Gefundene Audio-Dateien: %d", #files))

  if #files == 0 then
    r.ShowMessageBox(
      "Keine Audio-Dateien im angegebenen Ordner gefunden.\n" ..
      "(Erwartet: WAV/AIFF/FLAC).",
      "DF95 Fieldrec – SampleDB Ingest",
      0
    )
    r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (keine Files)", -1)
    return
  end

  -- 3) DB laden (oder neu initialisieren)
  local db_dir, db_path = get_db_path()
  ensure_dir(db_dir)

  local db, db_err = load_db(db_path)
  local items = nil
  if not db then
    msg("Keine bestehende SampleDB, neue wird erstellt.")
    items = {}
    db = {
      version = "DF95_MultiUCS_FieldrecIngest",
      created = os.date("%Y-%m-%d %H:%M:%S"),
      items   = items,
    }
  else
    if type(db) == "table" and type(db.items) == "table" then
      items = db.items
    elseif type(db) == "table" and #db > 0 then
      items = db
    else
      r.ShowMessageBox(
        "Unbekannte DB-Struktur.\n" ..
        "Erwarte entweder db.items = { ... } oder ein top-level Array.",
        "DF95 Fieldrec – SampleDB Ingest",
        0
      )
      r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (DB-Strukturfehler)", -1)
      return
    end
  end

  -- Lookup zur Duplikatsvermeidung (nach path)
  local existing_paths = {}
  for _, it in ipairs(items) do
    if type(it) == "table" and it.path then
      existing_paths[it.path] = true
    end
  end

  -- 4) Backup anlegen
  local backup_path, backup_err = backup_db(db_dir, db_path)
  if backup_err and backup_err ~= "no_db" then
    r.ShowMessageBox(
      "Konnte kein Backup der SampleDB anlegen:\n" .. tostring(backup_err),
      "DF95 Fieldrec – SampleDB Ingest",
      0
    )
    r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (Backup-Fehler)", -1)
    return
  end

  if backup_path then
    msg("Backup der SampleDB: " .. backup_path)
  else
    msg("Keine vorherige DB vorhanden – es wird eine neue angelegt.")
  end

  -- 5) Regions auf Files mappen und Items erzeugen
  local added = 0
  local skipped_no_file = 0
  local skipped_duplicates = 0

  for _, rgn in ipairs(regions) do
    local base = rgn.ucs.base_token
    local matches = map_by_basename[base]

    if not matches or #matches == 0 then
      skipped_no_file = skipped_no_file + 1
      msg(string.format("WARN: Keine Datei gefunden für Region '%s' (Basename='%s')", rgn.name, base))
    else
      -- Falls mehrere Files gleichen Namens, nimm die erste und logge
      if #matches > 1 then
        msg(string.format("INFO: Mehrere Dateien für '%s', verwende: %s", base, matches[1]))
      end
      local path = matches[1]
      if existing_paths[path] then
        skipped_duplicates = skipped_duplicates + 1
      else
        local info = get_wav_info(path) or { length = 0, samplerate = 0, channels = 0 }

        local item = {
          path           = path,
          ucs_category   = rgn.ucs.ucs_category,
          ucs_subcategory= rgn.ucs.ucs_subcategory,
          df95_catid     = rgn.ucs.df95_catid,
          home_zone      = nil,
          material       = nil,
          object_class   = nil,
          action         = nil,
          length_sec     = info.length,
          samplerate     = info.samplerate,
          channels       = info.channels,
        }
        items[#items+1] = item
        existing_paths[path] = true
        added = added + 1
      end
    end
  end

  msg("")
  msg(string.format("Neue DB-Items hinzugefügt : %d", added))
  msg(string.format("Übersprungen (kein File)  : %d", skipped_no_file))
  msg(string.format("Übersprungen (Duplikate)  : %d", skipped_duplicates))

  -- 6) DB schreiben
  local ok_db, werr = write_db(db, db_path)
  if not ok_db then
    r.ShowMessageBox(
      "Fehler beim Schreiben der SampleDB:\n" .. tostring(werr),
      "DF95 Fieldrec – SampleDB Ingest",
      0
    )
    r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (Schreibfehler)", -1)
    return
  end

  msg("")
  msg("SampleDB aktualisiert: " .. db_path)

  r.Undo_EndBlock("DF95 Fieldrec – SampleDB Ingest (from UCS Regions)", -1)

  r.ShowMessageBox(
    "DF95 Fieldrec – SampleDB Ingest abgeschlossen.\n\n" ..
    "Regions mit UCS-Pattern : " .. tostring(#regions) .. "\n" ..
    "Neue DB-Items           : " .. tostring(added) .. "\n" ..
    "Übersprungen (kein File): " .. tostring(skipped_no_file) .. "\n" ..
    "Übersprungen (Duplikate): " .. tostring(skipped_duplicates) .. "\n\n" ..
    "Details siehe REAPER-Konsole.\n\n" ..
    "DB: " .. db_path .. (backup_path and ("\nBackup: " .. backup_path) or ""),
    "DF95 Fieldrec – SampleDB Ingest",
    0
  )
end

main()
