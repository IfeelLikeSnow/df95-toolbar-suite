-- @description DF95 SampleDB AIWorker UCS – Python V1
-- @version 1.0
-- @author DF95
-- @about
--   Erzeugt AI-Job-JSONs für eine Audio-Ordnerstruktur (z.B. neue Fieldrec-/Drone-Samples)
--   und kann anschließend Result-JSONs eines externen Python-AIWorkers wieder in die
--   DF95 SampleDB Multi-UCS integrieren.
--
--   Dieses Script ist bewusst so gebaut, dass du:
--     * deine eigenen Python-Modelle / Tools verwenden kannst
--     * das Job-Format verstehst
--     * die Ingestion in die SampleDB kontrolliert erweitern kannst.
--
--   Ablauf (empfohlen):
--     1. "Job erstellen" -> Folder wählen -> Job-JSON landet in Support/DF95_AIWorker/Jobs
--     2. Python-Worker extern ausführen:
--          python df95_aiworker_ucsv1_example.py path/zum/job.json
--     3. "Result ingest" -> Result-JSON wählen -> UCS/AI-Felder in SampleDB aktualisieren
--
--   Hinweis:
--     Diese V1-Version führt Python NICHT automatisch aus (Plattform-Sicherheit),
--     zeigt aber in den Kommentaren, wie du reaper.ExecProcess() nutzen könntest.

local r = reaper

------------------------------------------------------------
-- Konfiguration / Pfade
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_aiworker_root()
  local root = join_path(get_resource_path(), "Support")
  root = join_path(root, "DF95_AIWorker")
  return root
end

local function ensure_dir(path)
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(path, 0)
    return true
  end
  if sep == "\\" then
    os.execute(string.format('mkdir "%s"', path))
  else
    os.execute(string.format('mkdir -p "%s"', path))
  end
  return true
end

local function get_aiworker_paths()
  local root = get_aiworker_root()
  local jobs = join_path(root, "Jobs")
  local results = join_path(root, "Results")
  local logs = join_path(root, "Logs")
  ensure_dir(root); ensure_dir(jobs); ensure_dir(results); ensure_dir(logs)
  return root, jobs, results, logs
end

-- Python / Worker-Script (nur Info, nicht auto-ausgeführt)
local DEFAULT_PYTHON_EXE = "python"
local DEFAULT_WORKER_SCRIPT_REL = "Support/DF95_AIWorker/df95_aiworker_ucsv1_example.py"

------------------------------------------------------------
-- SampleDB Helpers (Multi-UCS JSON)
------------------------------------------------------------

local function get_db_path_multi_ucs()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return dir, join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

-- JSON Codec (minimal, wie in DF95_V160_SampleDB_AIWorker_ZoomF6)

local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  str = str:gsub("\t", "\\t")
  return str
end

local function json_encode_any(val, indent)
  indent = indent or ""
  local next_indent = indent .. "  "
  if type(val) == "table" then
    local is_array = (#val > 0)
    if is_array then
      local parts = {"[\n"}
      for i, item in ipairs(val) do
        parts[#parts+1] = next_indent .. json_encode_any(item, next_indent)
        if i < #val then parts[#parts+1] = "," end
        parts[#parts+1] = "\n"
      end
      parts[#parts+1] = indent .. "]"
      return table.concat(parts)
    else
      local parts = {"{\n"}
      local first = true
      for k, item in pairs(val) do
        if not first then parts[#parts+1] = ",\n" end
        first = false
        parts[#parts+1] = next_indent ..
          "\"" .. json_escape(k) .. "\": " .. json_encode_any(item, next_indent)
      end
      parts[#parts+1] = "\n" .. indent .. "}"
      return table.concat(parts)
    end
  elseif type(val) == "string" then
    return "\"" .. json_escape(val) .. "\""
  elseif type(val) == "number" then
    return tostring(val)
  elseif type(val) == "boolean" then
    return val and "true" or "false"
  else
    return "null"
  end
end

local function json_encode(tbl)
  return json_encode_any(tbl, "")
end

local function json_decode(str)
  if not str or str == "" then return nil end
  local ok, res = pcall(function()
    local f = load("return " .. str, "json", "t", {})
    if f then return f() end
  end)
  if ok and type(res) == "table" then
    return res
  end
  return nil
end

local function load_sampledb_multi_ucs()
  local dir, db_path = get_db_path_multi_ucs()
  ensure_dir(dir)
  local f = io.open(db_path, "r")
  if not f then
    return {
      version = "DF95_MultiUCS_Auto",
      created = os.date("%Y-%m-%d %H:%M:%S"),
      items   = {},
    }, db_path
  end
  local content = f:read("*a")
  f:close()
  local db = json_decode(content)
  if type(db) ~= "table" then
    db = {
      version = "DF95_MultiUCS_Auto",
      created = os.date("%Y-%m-%d %H:%M:%S"),
      items   = {},
    }
  end
  db.items = db.items or {}
  return db, db_path
end

local function save_sampledb_multi_ucs(db, db_path)
  local f = io.open(db_path, "w")
  if not f then
    r.ShowMessageBox("DF95 AIWorker UCS: Konnte DB nicht schreiben:\n" .. tostring(db_path),
      "DF95 AIWorker UCS", 0)
    return false
  end
  f:write(json_encode(db))
  f:close()
  return true
end

------------------------------------------------------------
-- Job-Erstellung (Lua -> JSON)
------------------------------------------------------------

local AUDIO_EXTS = {
  wav=true, wave=true, flac=true, aif=true, aiff=true, ogg=true, mp3=true, m4a=true,
}

local function is_audio_file(name)
  local ext = name:match("%.([^%.]+)$")
  if not ext then return false end
  ext = ext:lower()
  return AUDIO_EXTS[ext] or false
end

local function list_audio_files_in_dir(dir)
  local files = {}
  local i = 0
  while true do
    local fname = r.EnumerateFiles(dir, i)
    if not fname then break end
    if is_audio_file(fname) then
      files[#files+1] = fname
    end
    i = i + 1
  end
  table.sort(files)
  return files
end

local function create_job_for_folder(folder, worker_mode)
  local _, jobs_dir, _, _ = get_aiworker_paths()
  local files = list_audio_files_in_dir(folder)
  if #files == 0 then
    r.ShowMessageBox("DF95 AIWorker UCS:\nIm gewählten Ordner wurden keine Audiodateien gefunden.", "DF95 AIWorker UCS", 0)
    return
  end

  worker_mode = (worker_mode or "generic")
  worker_mode = worker_mode:lower()
  if worker_mode ~= "drone" and worker_mode ~= "material" then
    worker_mode = "generic"
  end

  local job = {
    version         = "DF95_AIWorker_UCS_V1",
    created_utc     = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    audio_root      = folder,
    sampledb_hint   = select(2, get_db_path_multi_ucs()),
    worker_mode     = worker_mode,
    requested_tasks = (worker_mode == "drone")
      and {
        "analyze_drone_character",
        "suggest_ucs_fields",
        "suggest_df95_drone_fields",
        "suggest_ai_tags",
      }
      or (worker_mode == "material"
        and {
          "classify_material",
          "classify_instrument",
          "suggest_ucs_fields",
          "suggest_df95_fields",
          "suggest_ai_tags",
        }
        or {
          "analyze_audio_properties",
          "suggest_ucs_fields",
          "suggest_df95_fields",
          "suggest_ai_tags",
        }),
    files           = {},
  }

  for _, fname in ipairs(files) do
    job.files[#job.files+1] = {
      rel_path  = fname,
      full_path = join_path(folder, fname),
    }
  end

  local ts = os.date("%Y%m%d_%H%M%S")
  local job_name = string.format("DF95_AIWorker_UCSJob_%s.json", ts)
  local job_path = join_path(jobs_dir, job_name)

  local f = io.open(job_path, "w")
  if not f then
    r.ShowMessageBox("DF95 AIWorker UCS:\nKonnte Job-File nicht schreiben:\n" .. tostring(job_path),
      "DF95 AIWorker UCS", 0)
    return
  end
  f:write(json_encode(job))
  f:close()

  local msg = string.format(
    "DF95 AIWorker UCS – Job erstellt.\n\nOrdner:\n%s\nDateien: %d\n\nJob-File:\n%s\n\nNächster Schritt:\n  python %s \"%s\"",
    folder, #files, job_path, DEFAULT_WORKER_SCRIPT_REL, job_path
  )
  r.ShowMessageBox(msg, "DF95 AIWorker UCS – Job erstellt", 0)
end

end

------------------------------------------------------------
-- Result-Ingestion (JSON -> SampleDB)
------------------------------------------------------------

local function build_item_index_by_path(db)
  local index = {}
  for idx, item in ipairs(db.items or {}) do
    local path = (item.path or ""):lower()
    if path ~= "" then
      index[path] = item
    end
  end
  return index
end

local function normalize_path_for_lookup(p)
  p = (p or ""):gsub("\\", "/")
  return p:lower()
end

local function apply_result_to_item(item, res)
  -- UCS Felder (nur setzen, wenn nicht leer)
  if res.ucs_category and res.ucs_category ~= "" then
    item.ucs_category = res.ucs_category
  end
  if res.ucs_subcategory and res.ucs_subcategory ~= "" then
    item.ucs_subcategory = res.ucs_subcategory
  end
  if res.ucs_perspective and res.ucs_perspective ~= "" then
    item.ucs_perspective = res.ucs_perspective
  end
  if res.ucs_rec_medium and res.ucs_rec_medium ~= "" then
    item.ucs_rec_medium = res.ucs_rec_medium
  end
  if res.ucs_channel_config and res.ucs_channel_config ~= "" then
    item.ucs_channel_config = res.ucs_channel_config
  end
  if res.ucs_descriptor and res.ucs_descriptor ~= "" then
    item.ucs_descriptor = res.ucs_descriptor
  end

  -- DF95-spezifische Felder (optional)
  if res.df95_catid and res.df95_catid ~= "" then
    item.df95_catid = res.df95_catid
  end
  if res.df95_drone_flag ~= nil then
    item.df95_drone_flag = res.df95_drone_flag
  end
  if res.df95_drone_centerfreq and res.df95_drone_centerfreq ~= "" then
    item.df95_drone_centerfreq = res.df95_drone_centerfreq
  end
  if res.df95_drone_density and res.df95_drone_density ~= "" then
    item.df95_drone_density = res.df95_drone_density
  end
  if res.df95_drone_form and res.df95_drone_form ~= "" then
    item.df95_drone_form = res.df95_drone_form
  end
  if res.df95_drone_motion and res.df95_drone_motion ~= "" then
    item.df95_drone_motion = res.df95_drone_motion
  end
  if res.df95_motion_strength and res.df95_motion_strength ~= "" then
    item.df95_motion_strength = res.df95_motion_strength
  end
  if res.df95_tension and res.df95_tension ~= "" then
    item.df95_tension = res.df95_tension
  end
  if res.df95_material and res.df95_material ~= "" then
    item.df95_material = res.df95_material
  end
  if res.df95_instrument and res.df95_instrument ~= "" then
    item.df95_instrument = res.df95_instrument
  end

  -- AI-Metadaten
  if res.ai_tags and type(res.ai_tags) == "table" then
    item.ai_tags = res.ai_tags
  end
  if res.ai_model and res.ai_model ~= "" then
    item.ai_model = res.ai_model
  end
  item.ai_last_update = os.date("%Y-%m-%d %H:%M:%S")
  item.ai_status = "done"
end

local function ingest_result_file(path)
  local f = io.open(path, "r")
  if not f then
    r.ShowMessageBox("DF95 AIWorker UCS:\nKonnte Result-File nicht lesen:\n" .. tostring(path),
      "DF95 AIWorker UCS", 0)
    return
  end
  local content = f:read("*a")
  f:close()

  local data = json_decode(content)
  if type(data) ~= "table" then
    r.ShowMessageBox("DF95 AIWorker UCS:\nUngültiges JSON im Result-File:\n" .. tostring(path),
      "DF95 AIWorker UCS", 0)
    return
  end

  local results = data.results or data.files or {}
  if type(results) ~= "table" or #results == 0 then
    r.ShowMessageBox("DF95 AIWorker UCS:\nKeine 'results' im Result-File gefunden:\n" .. tostring(path),
      "DF95 AIWorker UCS", 0)
    return
  end

  local db, db_path = load_sampledb_multi_ucs()
  local index = build_item_index_by_path(db)
  local updated, total = 0, 0
  for _, res in ipairs(results) do
    total = total + 1
    local full = res.full_path or res.path or res.file or ""
    if full ~= "" then
      local key = normalize_path_for_lookup(full)
      local item = index[key]
      if not item then
        -- Versuch: Nur Dateiname matchen (fallback)
        local fname = full:match("([^/\\]+)$")
        if fname then
          for _, it in ipairs(db.items or {}) do
            local ipath = normalize_path_for_lookup(it.path or "")
            if ipath:match(fname:lower().."$") then
              item = it
              break
            end
          end
        end
      end

      if item then
        apply_result_to_item(item, res)
        updated = updated + 1
      end
    end
  end

  if updated > 0 then
    save_sampledb_multi_ucs(db, db_path)
  end

  r.ShowMessageBox(
    string.format("DF95 AIWorker UCS – Ingestion abgeschlossen.\n\nResult-File: %s\nGefundene Einträge: %d\nAktualisiert: %d\nDB: %s",
      path, total, updated, db_path),
    "DF95 AIWorker UCS – Result Ingest", 0
  )
end

------------------------------------------------------------
-- UI / Entry Point
------------------------------------------------------------

local function main()
  local title = "DF95 AIWorker UCS – Modus wählen"
  -- Optional: Vorgaben vom Glue-Hub
  local glue_mode  = reaper.GetExtState("DF95_AI_UCS_GLUE", "MODE")
  local glue_path  = reaper.GetExtState("DF95_AI_UCS_GLUE", "PATH_HINT")
  local glue_worker= reaper.GetExtState("DF95_AI_UCS_GLUE", "WORKER")

  if glue_mode ~= "" or glue_path ~= "" or glue_worker ~= "" then
    -- ExtStates nur einmal verwenden
    reaper.SetExtState("DF95_AI_UCS_GLUE", "MODE",      "", false)
    reaper.SetExtState("DF95_AI_UCS_GLUE", "PATH_HINT", "", false)
    reaper.SetExtState("DF95_AI_UCS_GLUE", "WORKER",    "", false)

    local mode = glue_mode ~= "" and glue_mode or "job/create"
    local path = glue_path or ""
    local worker_mode = glue_worker ~= "" and glue_worker or "generic"

    return (function()
      -- Direkt im gewählten Modus weiter unten einspringen:
      mode = mode:lower()
      if mode == "job/create" or mode == "job" or mode == "create" then
        if path == "" then
          local ok2, folder = reaper.JS_Dialog_BrowseForFolder
            and reaper.JS_Dialog_BrowseForFolder("DF95 AIWorker UCS – Folder wählen", "")
          if ok2 and folder and folder ~= "" then
            path = folder
          end
        end
        if path == "" then return end
        create_job_for_folder(path, worker_mode)
        return
      elseif mode == "result/ingest" or mode == "result" or mode == "ingest" then
        if path == "" then
          local ok2, file = reaper.GetUserFileNameForRead("", "Result-JSON wählen", ".json")
          if not ok2 then return end
          path = file
        end
        if path == "" then return end
        ingest_result_file(path)
        return
      end
    end)()
  end

  local ok, ret = r.GetUserInputs(title, 3,
    "Modus (job/create, result/ingest),Folder/Result-Path (leer = Browser),WorkerMode (generic/drone/material, leer = generic)",
    "job/create,,generic")
  if not ok then return end

  local m1, m2, m3 = ret:match("([^,]*),([^,]*),?(.*)")
  local mode = m1
  local path = m2
  local worker_mode = m3

  if not mode then
    -- Fallback: altes 2-Felder-Format
    mode, path = ret:match("([^,]*),?(.*)")
  end

  mode = (mode or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  path = (path or ""):gsub("^%s+", ""):gsub("%s+$", "")
  worker_mode = (worker_mode or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if worker_mode == "" then worker_mode = "generic" end

  if mode == "job/create" or mode == "job" or mode == "create" then
    if path == "" then
      local retval, dir = r.JS_Dialog_BrowseForFolder and r.JS_Dialog_BrowseForFolder("Ordner mit Audiodateien wählen", get_resource_path())
      if retval and dir and dir ~= "" then
        path = dir
      else
        path = ""
      end
    end
    if path == "" then return end
    create_job_for_folder(path, worker_mode)

  elseif mode == "result/ingest" or mode == "result" or mode == "ingest" then
    if path == "" then
      local ok2, file = r.GetUserFileNameForRead("", "Result-JSON wählen", ".json")
      if not ok2 then return end
      path = file
    end
    ingest_result_file(path)

  else
    r.ShowMessageBox("Ungültiger Modus: " .. tostring(mode) ..
      "\n\nErlaubt:\n  job/create\n  result/ingest", "DF95 AIWorker UCS", 0)
  end
end


main()
