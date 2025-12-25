-- @description DF95 System Health Panel (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Zeigt einen kompakten Überblick über den aktuellen "Gesundheitszustand"
--   der DF95-Toolchain:
--     - SampleDB vorhanden?
--     - Drone QA / Phase O Reports vorhanden?
--     - AIWorker Material/Drum/UCS/Pipeline Status
--     - Wichtige Kern-Skripte / Ordner vorhanden?
--
--   Dieses Panel liest primär Zustände aus und kann optional Phase O und
--   den Drone QA Validator starten bzw. Reports öffnen.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox(
    "DF95 System Health Panel benötigt REAPER mit ReaImGui-Unterstützung (REAPER v6.80+).",
    "DF95 System Health Panel",
    0
  )
  return
end

local ctx = r.ImGui_CreateContext("DF95 System Health Panel")
local ig = r.ImGui

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\" then
    a = a .. sep
  end
  return a .. b
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function dir_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end


local function try_open_path(path, label)
  if not path or path == "" then
    r.ShowMessageBox("Kein Pfad bekannt für: " .. (label or "Pfad"), "DF95 System Health Panel", 0)
    return
  end
  if r.CF_ShellExecute then
    r.CF_ShellExecute(path)
  else
    r.ShowMessageBox("Kann Pfad nicht öffnen (SWS/CF_ShellExecute nicht verfügbar):\n" .. tostring(path),
      "DF95 System Health Panel", 0)
  end
end

local function run_df95_script(rel)
  local sep = package.config:sub(1,1)
  local base = join_path(join_path(get_resource_path(), "Scripts"), "IfeelLikeSnow")
  base = join_path(base, "DF95")
  local path = join_path(base, rel)
  if not file_exists(path) then
    r.ShowMessageBox("DF95 Script nicht gefunden:\n" .. tostring(path),
      "DF95 System Health Panel", 0)
    return
  end
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox("Fehler beim Laden von:\n" .. tostring(path) ..
      "\n\n" .. tostring(err), "DF95 System Health Panel", 0)
    return
  end
  f()
end

  if code == 13 then return true end -- permission denied, but exists
  return false
end

local function load_json(path)
  local respath = get_resource_path()
  local reader_path = join_path(join_path(respath, "Scripts"), "IfeelLikeSnow")
  reader_path = join_path(reader_path, "DF95")
  reader_path = join_path(reader_path, "DF95_ReadJSON.lua")
  local ok, reader = pcall(dofile, reader_path)
  if not ok or type(reader) ~= "function" then
    return nil, "DF95_ReadJSON.lua konnte nicht geladen werden."
  end
  local ok2, data = pcall(reader, path)
  if not ok2 then
    return nil, "Fehler beim Lesen von JSON: " .. tostring(data)
  end
  return data, nil
end

local function get_sampledb_path()
  local root = join_path(get_resource_path(), "Support")
  root = join_path(root, "DF95_SampleDB")
  return join_path(root, "DF95_SampleDB_Multi_UCS.json")
end

local function get_sampledb_dir()
  local root = join_path(get_resource_path(), "Support")
  return join_path(root, "DF95_SampleDB")
end

local function get_aiworker_root()
  local root = join_path(get_resource_path(), "Support")
  return join_path(root, "DF95_AIWorker")
end

local function get_aiworker_results_dir()
  local root = get_aiworker_root()
  return join_path(root, "Results")
end


local function get_phaseo_dir()
  -- wir nehmen an, dass Phase-O-Reports im SampleDB-Ordner liegen
  return get_sampledb_dir()
end

local function find_latest_file(dir_path, pattern)
  local latest = nil
  local i = 0
  while true do
    local fname = r.EnumerateFiles(dir_path, i)
    if not fname then break end
    if fname:match(pattern) then
      if not latest or fname > latest then
        latest = fname
      end
    end
    i = i + 1
  end
  if not latest then return nil end
  return join_path(dir_path, latest)
end

local function find_latest_material_summary()
  local dir = get_aiworker_results_dir()
  if not dir_exists(dir) then return nil end
  return find_latest_file(dir, "_material_conflicts_summary%.json$")
end

------------------------------------------------------------
-- Health Checks
------------------------------------------------------------

local function check_sampledb()
  local db_path = get_sampledb_path()
  if not file_exists(db_path) then
    return "MISS", "SampleDB fehlt", db_path
  end

  -- grobe Größe / Struktur
  local data, err = load_json(db_path)
  if not data then
    return "WARN", "SampleDB JSON-Fehler", db_path
  end

  local items = 0
  if type(data) == "table" then
    if type(data.items) == "table" then
      items = #data.items
    elseif #data > 0 then
      items = #data
    end
  end

  if items == 0 then
    return "WARN", "SampleDB leer oder unerwartetes Format", db_path
  end

  return "OK", string.format("SampleDB OK (%d Items)", items), db_path
end

local function check_phaseo()
  local dir = get_phaseo_dir()
  if not dir_exists(dir) then
    return "MISS", "Phase-O Report-Ordner nicht gefunden", dir, nil
  end
  local rep = find_latest_file(dir, "DF95_Drone_PhaseO_Report_.*%.txt$")
  if not rep or not file_exists(rep) then
    return "WARN", "Kein Phase-O Report gefunden", dir, nil
  end

  -- Versuchen, grobe Kennzahlen aus dem Report zu parsen
  local f = io.open(rep, "r")
  if not f then
    return "WARN", "Phase-O Report vorhanden, aber kann nicht gelesen werden", rep, nil
  end
  local content = f:read("*a") or ""
  f:close()

  local total_items   = tonumber(content:match("Total Items:%s*(%d+)") or "0") or 0
  local drone_items   = tonumber(content:match("Drone%-Items:%s*(%d+)") or "0") or 0
  local missing_cf    = tonumber(content:match("centerfreq:%s*(%d+)
") or "0") or 0
  local missing_dens  = tonumber(content:match("density%s*:%s*(%d+)") or "0") or 0
  local missing_form  = tonumber(content:match("form%s*:%s*(%d+)") or "0") or 0
  local missing_mot   = tonumber(content:match("motion%s*:%s*(%d+)") or "0") or 0
  local missing_ten   = tonumber(content:match("tension%s*:%s*(%d+)") or "0") or 0
  local invalid_cf    = tonumber(content:match("Invalid enum values %(Drone%-Items%):%s*%s*centerfreq:%s*(%d+)") or "0") or 0
  local invalid_dens  = tonumber(content:gmatch("Invalid enum values %(Drone%-Items%):[\s\S]-density%s*:%s*(%d+)")() or "0") or 0
  local invalid_form  = tonumber(content:gmatch("Invalid enum values %(Drone%-Items%):[\s\S]-form%s*:%s*(%d+)")() or "0") or 0
  local invalid_mot   = tonumber(content:gmatch("Invalid enum values %(Drone%-Items%):[\s\S]-motion%s*:%s*(%d+)")() or "0") or 0
  local invalid_ten   = tonumber(content:gmatch("Invalid enum values %(Drone%-Items%):[\s\S]-tension%s*:%s*(%d+)")() or "0") or 0
  local miss_ms       = tonumber(content:match("missing%s*:%s*(%d+)") or "0") or 0
  local mm_ms         = tonumber(content:match("mismatch:%s*(%d+)") or "0") or 0

  local problem_sum = missing_cf + missing_dens + missing_form + missing_mot + missing_ten
                    + invalid_cf + invalid_dens + invalid_form + invalid_mot + invalid_ten
                    + miss_ms + mm_ms

  local status = "OK"
  local msg
  if problem_sum > 0 then
    status = "WARN"
    msg = string.format("Drone-Items: %d, Probleme gesamt: %d (missing+invalid+motion-strength)", drone_items, problem_sum)
  else
    msg = string.format("Drone-Items: %d, keine Probleme im Phase-O-Report", drone_items)
  end

  local extra = {
    total_items  = total_items,
    drone_items  = drone_items,
    problem_sum  = problem_sum,
    missing = {
      centerfreq = missing_cf,
      density    = missing_dens,
      form       = missing_form,
      motion     = missing_mot,
      tension    = missing_ten,
    },
    invalid = {
      centerfreq = invalid_cf,
      density    = invalid_dens,
      form       = invalid_form,
      motion     = invalid_mot,
      tension    = invalid_ten,
    },
    motion_strength = {
      missing  = miss_ms,
      mismatch = mm_ms,
    },
  }

  return status, msg, rep, extra
end

local function check_aiworker_material()end

local function check_aiworker_material()
  local res_dir = get_aiworker_results_dir()
  if not dir_exists(res_dir) then
    return "MISS", "AIWorker Results-Ordner fehlt", res_dir, nil
  end

  local summary_path = find_latest_material_summary()
  if not summary_path or not file_exists(summary_path) then
    return "WARN", "Keine Material-Summary gefunden", res_dir, nil
  end

  local data, err = load_json(summary_path)
  if not data then
    return "WARN", "Fehler beim Laden der Material-Summary", summary_path, nil
  end

  local overall = data.overall or {}
  local num_conf = overall.num_conflicts or 0
  local num_prop = overall.num_proposed_new or 0
  local min_conf = overall.min_conf or 0.0

  local status = "OK"
  local msg
  if num_conf > 0 then
    status = "WARN"
    msg = string.format("Conflicts: %d, ProposedNew: %d (min_conf=%.2f)", num_conf, num_prop, min_conf)
  else
    msg = string.format("Keine Conflicts, ProposedNew: %d (min_conf=%.2f)", num_prop, min_conf)
  end

  return status, msg, summary_path, data
end
local function check_aiworker_drumrole()
  local root = get_aiworker_root()
  if not dir_exists(root) then
    return "MISS", "DF95_AIWorker-Ordner fehlt (DrumRole)", root, nil
  end

  local config_path  = join_path(root, "df95_aiworker_drumrole_config.json")
  local engine_path  = join_path(root, "df95_aiworker_drumrole_engine.py")
  local example_path = join_path(root, "df95_aiworker_drumrole_example.py")

  local missing = {}
  if not file_exists(config_path) then missing[#missing+1] = "Config" end
  if not file_exists(engine_path) then missing[#missing+1] = "Engine" end
  if not file_exists(example_path) then missing[#missing+1] = "Example" end

  if #missing > 0 then
    local msg = "Fehlende DrumRole-Engine-Komponenten: " .. table.concat(missing, ", ")
    return "WARN", msg, root, { missing = missing, config = config_path, engine = engine_path, example = example_path }
  end

  local cfg, err = load_json(config_path)
  if not cfg then
    return "WARN", "DrumRole-Config JSON-Fehler", config_path, nil
  end

  local backend = cfg.backend or "?"
  local msg = string.format("DrumRole Engine OK (Backend: %s)", tostring(backend))
  return "OK", msg, config_path, cfg
end

local function check_aiworker_ucs()
  local root = get_aiworker_root()
  local res_dir = get_aiworker_results_dir()

  if not dir_exists(root) then
    return "MISS", "DF95_AIWorker-Ordner fehlt (UCS)", root, nil
  end

  local scripts_root = join_path(join_path(get_resource_path(), "Scripts"), "IfeelLikeSnow")
  scripts_root = join_path(scripts_root, "DF95")
  local ucs_lua    = join_path(scripts_root, "DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua")
  local ucs_py     = join_path(root, "df95_aiworker_ucsv1_example.py")

  local missing = {}
  if not file_exists(ucs_lua) then missing[#missing+1] = "UCS Lua-Bridge" end
  if not file_exists(ucs_py)  then missing[#missing+1] = "UCS Example-Python" end

  local num_results = 0
  if dir_exists(res_dir) then
    local i = 0
    while true do
      local fname = r.EnumerateFiles(res_dir, i)
      if not fname then break end
      if fname:match("[Uu][Cc][Ss].*%.json$") then
        num_results = num_results + 1
      end
      i = i + 1
    end
  end

  if #missing > 0 then
    local msg = "UCS Engine unvollständig: " .. table.concat(missing, ", ")
    if num_results > 0 then
      msg = msg .. string.format(" (UCS-Results gefunden: %d)", num_results)
    end
    return "WARN", msg, root, { missing = missing, num_results = num_results }
  end

  if num_results == 0 then
    return "WARN", "UCS Engine vorhanden, aber keine UCS-Result-JSONs gefunden (noch kein Run?)", res_dir, { num_results = 0 }
  end

  local msg = string.format("UCS Engine OK, UCS-Result-JSONs: %d", num_results)
  return "OK", msg, res_dir, { num_results = num_results }
end

local function check_aiworker_pipeline()
  local root = get_aiworker_root()
  if not dir_exists(root) then
    return "MISS", "DF95_AIWorker-Ordner fehlt (Pipelines)", root, nil
  end

  local cfg_path = join_path(root, "DF95_AIWorker_Pipeline_Config.json")
  if not file_exists(cfg_path) then
    return "WARN", "Pipeline-Config fehlt", cfg_path, nil
  end

  local cfg, err = load_json(cfg_path)
  if not cfg then
    return "WARN", "Pipeline-Config JSON-Fehler", cfg_path, nil
  end

  local pipelines = cfg.pipelines
  local num_pipes = (type(pipelines) == "table") and #pipelines or 0

  if num_pipes == 0 then
    return "WARN", "Keine Pipelines definiert", cfg_path, cfg
  end

  local msg = string.format("Pipelines konfiguriert: %d", num_pipes)
  return "OK", msg, cfg_path, cfg
end



local function check_core_files()
  local res = get_resource_path()
  local scripts_root = join_path(join_path(res, "Scripts"), "IfeelLikeSnow")
  scripts_root = join_path(scripts_root, "DF95")

  local missing = {}

  local function need(rel)
    local p = join_path(scripts_root, rel)
    if not file_exists(p) then
      missing[#missing+1] = rel
    end
  end

  need("DF95_Workflow_Brain_ImGui.lua")
  need("DF95_AIWorker_Hub_ImGui.lua")
  need("DF95_Drone_System_Consistency_PhaseO.lua")
  need("DF95_SampleDB_Drone_QA_Validator.lua")
  need("DF95_V134_UCS_Renamer.lua")

  if #missing == 0 then
    return "OK", "Kern-Skripte OK", scripts_root, missing
  else
    return "WARN", "Fehlende Kern-Skripte: " .. table.concat(missing, ", "), scripts_root, missing
  end
end

local function check_drone_qa()
  -- Prüft, ob ein DF95_Drone_QA_Report.csv existiert und wie viele Issues gefunden wurden.
  local db_dir = get_sampledb_dir()
  if not dir_exists(db_dir) then
    return "MISS", "SampleDB-Ordner fehlt (für QA-Report)", db_dir, nil
  end

  local qa_path = join_path(db_dir, "DF95_Drone_QA_Report.csv")
  if not file_exists(qa_path) then
    return "WARN", "Kein DF95_Drone_QA_Report.csv gefunden", qa_path, nil
  end

  local f = io.open(qa_path, "r")
  if not f then
    return "WARN", "QA-Report vorhanden, aber kann nicht gelesen werden", qa_path, nil
  end

  local header = f:read("*l") or ""
  local issue_count = 0
  for line in f:lines() do
    if line ~= "" then
      issue_count = issue_count + 1
    end
  end
  f:close()

  local status = "OK"
  local msg
  if issue_count > 0 then
    status = "WARN"
    msg = string.format("Gefundene Issues: %d (siehe DF95_Drone_QA_Report.csv)", issue_count)
  else
    msg = "Keine Issues im QA-Report"
  end

  local extra = {
    issues = issue_count,
    path   = qa_path,
  }

  return status, msg, qa_path, extra
end

end

------------------------------------------------------------
-- State
------------------------------------------------------------

local state = {
  sampledb_status          = nil,
  phaseo_status            = nil,
  drone_qa_status          = nil,
  aiworker_material_status = nil,
  aiworker_drum_status     = nil,
  aiworker_ucs_status      = nil,
  aiworker_pipeline_status = nil,
  core_status              = nil,
}


local function refresh_all()
  state.sampledb_status          = { check_sampledb() }
  state.phaseo_status            = { check_phaseo() }
  state.drone_qa_status          = { check_drone_qa() }
  state.aiworker_material_status = { check_aiworker_material() }
  state.aiworker_drum_status     = { check_aiworker_drumrole() }
  state.aiworker_ucs_status      = { check_aiworker_ucs() }
  state.aiworker_pipeline_status = { check_aiworker_pipeline() }
  state.core_status              = { check_core_files() }
end


refresh_all()

------------------------------------------------------------
-- UI Helpers
------------------------------------------------------------

local function draw_status_line(label, status_tuple)
  if not status_tuple then
    ig.ImGui_Text(ctx, label .. ": (n/a)")
    return
  end
  local code, msg, path = status_tuple[1], status_tuple[2], status_tuple[3]

  local r_col, g_col, b_col = 0.6, 0.6, 0.6
  if code == "OK" then
    r_col, g_col, b_col = 0.3, 0.9, 0.3
  elseif code == "WARN" then
    r_col, g_col, b_col = 0.9, 0.7, 0.2
  elseif code == "MISS" then
    r_col, g_col, b_col = 1.0, 0.3, 0.3
  end

  ig.ImGui_Text(ctx, label .. ": ")
  ig.ImGui_SameLine(ctx)
  ig.ImGui_TextColored(ctx, r_col, g_col, b_col, 1.0, code .. " – " .. (msg or ""))

  if path and path ~= "" then
    ig.ImGui_SameLine(ctx)
    ig.ImGui_Text(ctx, "(" .. path .. ")")
  end
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------

local function loop()
  ig.ImGui_SetNextWindowSize(ctx, 640, 360, ig.Cond_FirstUseEver())
  local visible, open = ig.ImGui_Begin(ctx, "DF95 System Health Panel", true)
  if visible then
    ig.ImGui_Text(ctx, "DF95 System Health Panel")
    ig.ImGui_Separator(ctx)

    if ig.ImGui_Button(ctx, "Refresh All", 100, 0) then
      refresh_all()
    end

    if ig.ImGui_Button(ctx, "Run Phase O", 110, 0) then
      -- Phase O Konsistenztest starten
      r.Main_OnCommand(r.NamedCommandLookup("_RSDF95_Drone_System_Consistency_PhaseO"), 0)
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Run Drone QA", 120, 0) then
      -- Drone QA Validator starten
      r.Main_OnCommand(r.NamedCommandLookup("_RSDF95_SampleDB_Drone_QA_Validator"), 0)
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Open PhaseO Report", 150, 0) then
      local s = state.phaseo_status
      if s and s[3] and s[3] ~= "" then
        r.CF_ShellExecute(s[3])
      else
        r.ShowMessageBox("Kein Phase-O Report-Pfad bekannt. Bitte zuerst Phase O laufen lassen und Refresh All drücken.",
          "DF95 System Health Panel", 0)
      end
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Open Drone QA CSV", 160, 0) then
      local s = state.drone_qa_status
      if s and s[3] and s[3] ~= "" then
        r.CF_ShellExecute(s[3])
      else
        r.ShowMessageBox("Kein Drone QA CSV-Pfad bekannt. Bitte zuerst den QA-Validator laufen lassen und Refresh All drücken.",
          "DF95 System Health Panel", 0)
      end
    end

    ig.ImGui_Separator(ctx)

    draw_status_line("SampleDB", state.sampledb_status)
    draw_status_line("Phase O (Drone Consistency)", state.phaseo_status)
    draw_status_line("Drone QA (Phase J)", state.drone_qa_status)
    draw_status_line("AIWorker Material", state.aiworker_material_status)
    draw_status_line("AIWorker DrumRole", state.aiworker_drum_status)
    draw_status_line("AIWorker UCS", state.aiworker_ucs_status)
    draw_status_line("AIWorker Pipeline", state.aiworker_pipeline_status)
    draw_status_line("Core Scripts", state.core_status)

    
    ig.ImGui_Separator(ctx)
    ig.ImGui_Text(ctx, "AIWorker System Actions:")

    -- Material Actions
    if ig.ImGui_Button(ctx, "Material: Results Folder", 190, 0) then
      local res_dir = get_aiworker_results_dir()
      if res_dir and res_dir ~= "" then
        try_open_path(res_dir, "AIWorker Results-Ordner")
      else
        r.ShowMessageBox("AIWorker Results-Ordner ist unbekannt.", "DF95 System Health Panel", 0)
      end
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Material: Summary JSON", 190, 0) then
      local s = state.aiworker_material_status
      local p = s and s[3] or nil
      if (not p or p == "") then
        -- Fallback: aktuelle Summary suchen
        p = find_latest_material_summary()
      end
      if p and p ~= "" then
        try_open_path(p, "Material Summary")
      else
        r.ShowMessageBox("Keine Material-Summary gefunden. Bitte AIWorker-Pipeline/Result-Ingest laufen lassen.",
          "DF95 System Health Panel", 0)
      end
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Open AI Material Status UI", 210, 0) then
      run_df95_script("DF95_AIWorker_Material_Status_ImGui.lua")
    end

    if ig.ImGui_Button(ctx, "Open AI Material Conflict UI", 230, 0) then
      run_df95_script("DF95_AIWorker_Material_Conflict_ImGui.lua")
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Material: Apply ProposedNew", 230, 0) then
      run_df95_script("DF95_AIWorker_Material_Apply_ProposedNew.lua")
    end

    ig.ImGui_Separator(ctx)
    ig.ImGui_Text(ctx, "DrumRole / UCS / Pipeline:")

    -- DrumRole Actions
    if ig.ImGui_Button(ctx, "DrumRole: Engine Folder", 210, 0) then
      local root = get_aiworker_root()
      try_open_path(root, "DF95_AIWorker (DrumRole)")
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "DrumRole: Config JSON", 210, 0) then
      local root = get_aiworker_root()
      local cfg = join_path(root, "df95_aiworker_drumrole_config.json")
      try_open_path(cfg, "DrumRole Config")
    end

    -- UCS / Pipeline Actions
    if ig.ImGui_Button(ctx, "Open AIWorker Hub / Pipeline UI", 260, 0) then
      run_df95_script("DF95_AIWorker_Hub_ImGui.lua")
    end
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Pipeline: Config JSON", 210, 0) then
      local root = get_aiworker_root()
      local cfg = join_path(root, "DF95_AIWorker_Pipeline_Config.json")
      try_open_path(cfg, "AIWorker Pipeline Config")
    end

    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Open UCS Lua Bridge", 210, 0) then
      run_df95_script("DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua")
    end

ig.ImGui_Separator(ctx)
    ig.ImGui_Text(ctx, "Hinweis:")
    ig.ImGui_Text(ctx, "- Dieses Panel zeigt Status an und bietet direkte Aktionen (AIWorker / Drone / Phase O).")
    ig.ImGui_Text(ctx, "- Details zu Konflikten: AI Material Conflict UI.")
    ig.ImGui_Text(ctx, "- Auto-Anwendung von Vorschlägen: AI Material Apply ProposedNew.")
    ig.ImGui_Text(ctx, "- Volle DB/Drone Checks: Drone QA Validator + Phase O Script.")

    ig.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ig.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)
