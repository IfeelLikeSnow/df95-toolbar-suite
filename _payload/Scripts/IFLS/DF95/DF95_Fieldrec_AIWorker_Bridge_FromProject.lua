-- @description DF95 Fieldrec → AIWorker Bridge (From Project Selection)
-- @version 1.0
-- @author DF95
-- @about
--   Baut aus der aktuellen REAPER-Session (ausgewählte Items) einen DF95 AIWorker Job,
--   der speziell für Fieldrecordings gedacht ist. Die Idee:
--     * Du arbeitest mit Fieldrec-Rohaufnahmen oder gesliceten Kits
--     * Du wählst die relevanten Items im Projekt aus
--     * Dieses Script ermittelt die zugehörigen Audiofiles
--     * Es erzeugt einen AIWorker-Job im Material-Mode ("material")
--       mit Tasks wie classify_material, classify_instrument, suggest_ucs_fields etc.
--     * Dein Python-AIWorker verarbeitet den Job und schreibt ein Result-JSON
--     * AIWorker Hub / Pipeline kann die Result-JSONs wieder in die SampleDB integrieren.
--
--   Wichtig:
--     * Dieses Script erzeugt nur den Job – es startet keinen Python-Prozess.
--       Den Python-AIWorker startest du wie gewohnt extern.
--     * Der Job verwendet das gleiche Format wie DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua
--
--   Empfohlener Ablauf:
--     1. Im Fieldrec-Projekt die relevanten Items auswählen
--     2. Dieses Script ausführen -> Job-File im Support/DF95_AIWorker/Jobs-Ordner
--     3. Python-AIWorker mit diesem Job-File ausführen
--     4. Im AIWorker Hub (Results-Tab / Pipeline FullRun) das Result ingestieren
--
--   Tipp:
--     Du kannst das Script z.B. in deine Fieldrec-/Beat-Toolbar integrieren
--     oder über das Workflow Brain (AI/Fieldrec Sektion) aufrufen.

local r = reaper

------------------------------------------------------------
-- Pfad- & FS-Utils
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

------------------------------------------------------------
-- SampleDB / Multi-UCS Pfad
------------------------------------------------------------

local function get_db_path_multi_ucs()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return dir, join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

------------------------------------------------------------
-- JSON Encoder (kompatibel zum AIWorker-Skeleton)
------------------------------------------------------------

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
      for k, v in pairs(val) do
        if not first then
          parts[#parts+1] = ",\n"
        end
        first = false
        parts[#parts+1] = next_indent ..
          "\"" .. json_escape(k) .. "\": " .. json_encode_any(v, next_indent)
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

------------------------------------------------------------
-- Helpers: Auswahl & Pfade
------------------------------------------------------------

local function get_selected_media_files()
  local files = {}
  local set = {} -- dedupe
  local num_items = r.CountSelectedMediaItems(0)
  for i = 0, num_items-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local take = it and r.GetActiveTake(it)
    if take then
      local src = r.GetMediaItemTake_Source(take)
      local buf = ""
      local retval, fn = r.GetMediaSourceFileName(src, "", 1024)
      fn = retval and fn or ""
      if fn ~= "" then
        if not set[fn] then
          set[fn] = true
          files[#files+1] = fn
        end
      end
    end
  end
  return files
end

local function dirname(path)
  if not path or path == "" then return "" end
  local dir = path:match("^(.*"..sep..")")
  if dir then
    if dir:sub(-1) == sep then
      dir = dir:sub(1,-2)
    end
    return dir
  end
  return ""
end

local function common_root_dir(paths)
  if #paths == 0 then return "" end
  local parts = {}
  for part in dirname(paths[1]):gmatch("[^"..sep.."]+") do
    parts[#parts+1] = part
  end
  local root_parts = {}
  for i = 1, #parts do
    local prefix = table.concat(parts, sep, 1, i)
    local prefix_full = sep == "\\" and (prefix) or (sep .. prefix)
    local all_match = true
    for j = 2, #paths do
      local d = dirname(paths[j])
      if d:sub(1, #prefix_full) ~= prefix_full then
        all_match = false
        break
      end
    end
    if all_match then
      root_parts[#root_parts+1] = parts[i]
    else
      break
    end
  end
  if #root_parts == 0 then
    return dirname(paths[1])
  end
  local root = table.concat(root_parts, sep)
  if sep ~= "\\" then
    root = sep .. root
  end
  return root
end

local function relpath(root, full)
  if not root or root == "" then
    return full
  end
  if full:sub(1, #root) == root then
    local rel = full:sub(#root+1)
    if rel:sub(1,1) == sep then
      rel = rel:sub(2)
    end
    return rel
  end
  return full
end

------------------------------------------------------------
-- Hauptlogik: Job aus Projekt-Auswahl erzeugen
------------------------------------------------------------

local function main()
  local files = get_selected_media_files()
  if #files == 0 then
    r.ShowMessageBox(
      "DF95 Fieldrec → AIWorker Bridge:\n\nEs wurden keine Media-Items ausgewählt.\n\n" ..
      "Bitte wähle die relevanten Fieldrec-/Slice-Items im Projekt aus\n" ..
      "und starte das Script erneut.",
      "DF95 Fieldrec → AIWorker", 0
    )
    return
  end

  local root_dir = common_root_dir(files)
  if root_dir == "" then
    root_dir = dirname(files[1])
  end

  local db_dir, db_path = get_db_path_multi_ucs()
  local _, jobs_dir, _, _ = get_aiworker_paths()

  -- Worker-Mode: material (Fieldrecordings -> Material/Instrument/UCS)
  local worker_mode = "material"

  local job_files = {}
  for _, full in ipairs(files) do
    job_files[#job_files+1] = {
      full_path = full,
      rel_path  = relpath(root_dir, full),
    }
  end

  local job = {
    version         = "DF95_AIWorker_UCS_V1",
    created_utc     = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    audio_root      = root_dir,
    sampledb_hint   = db_path,
    worker_mode     = worker_mode,
    requested_tasks = {
      "classify_material",
      "classify_instrument",
      "suggest_ucs_fields",
      "suggest_df95_fields",
      "suggest_ai_tags",
      "classify_drum_role",
    },
    files           = job_files,
    context         = {
      source        = "fieldrec_project_selection",
      project       = r.GetProjectName(0, "") or "",
      num_items     = r.CountSelectedMediaItems(0),
    },
  }

  local ts = os.date("%Y%m%d_%H%M%S")
  local job_name = string.format("DF95_AIWorker_FieldrecJob_%s.json", ts)
  local job_path = join_path(jobs_dir, job_name)

  local f = io.open(job_path, "w")
  if not f then
    r.ShowMessageBox(
      "DF95 Fieldrec → AIWorker Bridge:\n\nKonnte Job-File nicht schreiben:\n" ..
      tostring(job_path),
      "DF95 Fieldrec → AIWorker", 0
    )
    return
  end
  f:write(json_encode(job))
  f:close()

  local msg = string.format(
    "DF95 Fieldrec → AIWorker Bridge\n\n" ..
    "Ausgewählte Items : %d\n" ..
    "Distinct Audiofiles: %d\n" ..
    "Audio Root        : %s\n" ..
    "SampleDB (Hint)   : %s\n\n" ..
    "Job-File:\n%s\n\n" ..
    "Nächster Schritt:\n  Python-AIWorker mit diesem Job ausführen\n" ..
    "  und danach im AIWorker Hub das Result ingestieren\n" ..
    "(z.B. über Pipeline FULL RUN).",
    r.CountSelectedMediaItems(0), #files, tostring(root_dir), tostring(db_path), job_path
  )

  r.ShowMessageBox(msg, "DF95 Fieldrec → AIWorker – Job erstellt", 0)
end

main()
