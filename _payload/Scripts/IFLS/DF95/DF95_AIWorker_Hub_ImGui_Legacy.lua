-- @description DF95 AIWorker Hub (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   ImGui-Frontend für den DF95 AIWorker UCS V1.
--   Erlaubt:
--     * Jobs für Ordner mit Audiodateien zu erstellen
--     * vorhandene Jobs aufzulisten
--     * Result-JSONs zu listen und zu ingestieren
--   Nutzt intern DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua als Engine.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox(
    "DF95 AIWorker Hub benötigt REAPER mit ReaImGui-Unterstützung (REAPER v6.80+).",
    "DF95 AIWorker Hub", 0)
  return
end

local ctx = r.ImGui_CreateContext("DF95 AIWorker Hub")
local ig = r.ImGui

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

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

------------------------------------------------------------
-- Pipeline-Konfiguration
------------------------------------------------------------

local function load_pipeline_config()
  local res = get_resource_path()
  local cfg_dir = join_path(join_path(res, "Support"), "DF95_AIWorker")
  local cfg_path = join_path(cfg_dir, "DF95_AIWorker_Pipeline_Config.json")
  if not file_exists(cfg_path) then
    return { pipelines = {} }, cfg_path
  end

  -- DF95_ReadJSON.lua als Helper verwenden
  local reader_path = join_path(join_path(join_path(res, "Scripts"), "IfeelLikeSnow"), "DF95")
  reader_path = join_path(reader_path, "DF95_ReadJSON.lua")
  local ok, reader = pcall(dofile, reader_path)
  if not ok or type(reader) ~= "function" then
    return { pipelines = {} }, cfg_path
  end

  local ok2, data = pcall(reader, cfg_path)
  if not ok2 or type(data) ~= "table" then
    return { pipelines = {} }, cfg_path
  end

  if type(data.pipelines) ~= "table" then
    data.pipelines = {}
  end
  return data, cfg_path
end

local pipeline_config, pipeline_config_path = load_pipeline_config()
local pipeline_selected_index = 0  -- 0 = kein Preset
end

local AUDIO_EXTS = {
  wav=true, wave=true, flac=true, aif=true, aiff=true, ogg=true, mp3=true, m4a=true,
}

local function is_audio_file(name)
  local ext = name:match("%.([^%.]+)$")
  if not ext then return false end
  ext = ext:lower()
  return AUDIO_EXTS[ext] or false
end

local function count_audio_files(dir)
  local i = 0
  local count = 0
  while true do
    local fname = r.EnumerateFiles(dir, i)
    if not fname then break end
    if is_audio_file(fname) then
      count = count + 1
    end
    i = i + 1
  end
  return count
end

local function collect_batch_folders(root)
  local folders = {}

  local function walk(path, rel)
    local num = count_audio_files(path)
    if num > 0 then
      folders[#folders+1] = { path = path, rel = rel ~= "" and rel or ".", files = num }
    end
    local j = 0
    while true do
      local sub = r.EnumerateSubdirectories(path, j)
      if not sub then break end
      local sub_path = join_path(path, sub)
      local sub_rel = rel ~= "" and (rel .. "/" .. sub) or sub
      walk(sub_path, sub_rel)
      j = j + 1
    end
  end

  walk(root, "")
  table.sort(folders, function(a,b) return a.rel:lower() < b.rel:lower() end)
  return folders
end

local function scan_dir(dir, ext)
  local t = {}
  local i = 0
  while true do
    local fname = r.EnumerateFiles(dir, i)
    if not fname then break end
    if not ext or fname:lower():sub(-#ext) == ext then
      t[#t+1] = fname
    end
    i = i + 1
  end
  table.sort(t)
  return t
end

local function run_aiworker_script(mode, path, worker_mode)
  local engine_rel = "Scripts/IFLS/DF95/DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua"
  local engine_full = join_path(get_resource_path(), engine_rel)
  local f, err = loadfile(engine_full)
  if not f then
    r.ShowMessageBox("DF95 AIWorker Hub:\nKonnte AIWorker-Engine nicht laden:\n" .. engine_full ..
      "\n\nFehler:\n" .. tostring(err), "DF95 AIWorker Hub", 0)
    return
  end
  -- Monkeypatch GetUserInputs für diesen Aufruf, um ohne Dialog durchzukommen
  local orig_GetUserInputs = r.GetUserInputs
  r.GetUserInputs = function(title, num, captions_csv, defaults)
    local combo = (mode or "") .. "," .. (path or "") .. "," .. (worker_mode or "")
    return true, combo
  end
  local ok, perr = pcall(f)
  r.GetUserInputs = orig_GetUserInputs
  if not ok then
    r.ShowMessageBox("DF95 AIWorker Hub:\nFehler beim Ausführen der Engine:\n" .. tostring(perr),
      "DF95 AIWorker Hub", 0)
  end
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

local last_jobs = {}
local last_results = {}
local selected_job = 0
local selected_result = 0

local worker_mode_labels = { "generic", "drone", "material" }
local worker_mode_index = 1  -- 1=generic, 2=drone

local batch_root = nil
local batch_folders = {}
local batch_selected = {}
local batch_total_files = 0
local batch_total_folders = 0

local function refresh_lists()
  local _, jobs_dir, results_dir, _ = get_aiworker_paths()
  last_jobs = scan_dir(jobs_dir, ".json")
  last_results = scan_dir(results_dir, ".json")
end

refresh_lists()

local function get_current_worker_mode()
  local label = worker_mode_labels[worker_mode_index] or "generic"
  return label
end

local function draw_worker_mode_selector()
  ig.Text("Worker Mode:")
  ig.SameLine()
  local current = worker_mode_labels[worker_mode_index] or "generic"
  if ig.BeginCombo("##worker_mode_combo", current) then
    for i, lbl in ipairs(worker_mode_labels) do
      local selected = (i == worker_mode_index)
      if ig.Selectable(lbl, selected) then
        worker_mode_index = i
      end
      if selected then
        ig.SetItemDefaultFocus()
      end
    end
    ig.EndCombo()
  end
end

local function draw_jobs_tab()
  local _, jobs_dir, _, _ = get_aiworker_paths()

  ig.Text("Jobs")
  ig.Separator()
  ig.TextWrapped("Erzeuge neue AIWorker-Jobs für einen Ordner mit Audiodateien oder verwalte bestehende Job-JSONs.")
  ig.Spacing()
  draw_worker_mode_selector()
  ig.Spacing()

  if ig.Button("Neuen Job für Ordner erstellen...", 260, 0) then
    -- Ordner wählen
    local start_dir = get_resource_path()
    local dir = start_dir
    if r.JS_Dialog_BrowseForFolder then
      local ok, out = r.JS_Dialog_BrowseForFolder("Ordner mit Audiodateien wählen", start_dir)
      if ok and out and out ~= "" then
        dir = out
      else
        dir = nil
      end
    else
      local ok, out = r.GetUserInputs("Ordnerpfad eingeben", 1, "Folder", start_dir)
      if ok and out and out ~= "" then dir = out else dir = nil end
    end
    if dir then
      local wmode = get_current_worker_mode()
      run_aiworker_script("job/create", dir, wmode)
      refresh_lists()
    end
  end

  ig.Spacing()
  ig.Separator()
  ig.Text("Vorhandene Jobs (Support/DF95_AIWorker/Jobs)")
  ig.Spacing()

  if #last_jobs == 0 then
    ig.TextDisabled("Keine Jobs gefunden.")
    return
  end

  if ig.BeginListBox("##jobs_list", -1, 150) then
    for i, name in ipairs(last_jobs) do
      local selected = (i == selected_job)
      if ig.Selectable(name, selected) then
        selected_job = i
      end
    end
    ig.EndListBox()
  end

  if selected_job > 0 and selected_job <= #last_jobs then
    local fname = last_jobs[selected_job]
    local _, jobs_dir2, _, _ = get_aiworker_paths()
    local full = join_path(jobs_dir2, fname)
    ig.TextWrapped("Ausgewählter Job:\n" .. full)
  end
end


------------------------------------------------------------
-- Pipeline FullRun über alle Results
------------------------------------------------------------
local function aiworker_pipeline_fullrun_for_results()
  if not pipeline_config or type(pipeline_config.pipelines) ~= "table" then
    show_message("Keine Pipeline-Konfiguration geladen.")
    return
  end
  if pipeline_selected_index == 0 then
    show_message("Keine Pipeline ausgewählt – bitte im Batch-Tab ein Preset wählen.")
    return
  end
  local p = pipeline_config.pipelines[pipeline_selected_index]
  if not p then
    show_message("Ungültiges Pipeline-Preset.")
    return
  end

  local _, _, results_dir, _ = get_aiworker_paths()
  if not results_dir or results_dir == "" then
    show_message("Results-Ordner nicht gefunden.")
    return
  end

  -- Alle Result-JSONs einsammeln
  local results = {}
  local i = 0
  while true do
    local fname = r.EnumerateFiles(results_dir, i)
    if not fname then break end
    if fname:match("^DF95_AIWorker_UCSResult_.*%.json$") then
      table.insert(results, fname)
    end
    i = i + 1
  end

  if #results == 0 then
    show_message("Keine DF95_AIWorker_UCSResult_*.json im Results-Ordner gefunden.")
    return
  end

  table.sort(results)
  local wmode = p.worker_mode or "generic"
  local ok_count, err_count = 0, 0

  for _, fname in ipairs(results) do
    local full = join_path(results_dir, fname)
    local ok, perr = pcall(function()
      run_aiworker_script("result/ingest", full, wmode)
    end)
    if ok then
      ok_count = ok_count + 1
    else
      err_count = err_count + 1
      r.ShowConsoleMsg("[DF95 AIWorker Pipeline] Fehler beim Ingest von " .. tostring(full) .. ": " .. tostring(perr) .. "\n")
    end
  end

  -- Optional: Material-Auto-Apply
  if p.auto_apply_material_proposed_new and wmode == "material" then
    local res = get_resource_path()
    local sroot = join_path(join_path(res, "Scripts"), "IfeelLikeSnow")
    sroot = join_path(sroot, "DF95")
    local apply_path = join_path(sroot, "DF95_AIWorker_Material_Apply_ProposedNew.lua")
    if file_exists(apply_path) then
      local ok_a, perr_a = pcall(dofile, apply_path)
      if not ok_a then
        show_message("Fehler beim Ausführen von DF95_AIWorker_Material_Apply_ProposedNew.lua: " .. tostring(perr_a))
      end
    else
      show_message("DF95_AIWorker_Material_Apply_ProposedNew.lua nicht gefunden – Auto-Apply übersprungen.")
    end
  end

  -- Optional: Phase O / Drone QA
  if p.auto_run_phase_o then
    local cmd = r.NamedCommandLookup("_RSDF95_Drone_System_Consistency_PhaseO")
    if cmd ~= 0 then
      r.Main_OnCommand(cmd, 0)
    else
      r.ShowConsoleMsg("[DF95 AIWorker Pipeline] Phase-O Command-ID nicht gefunden.\n")
    end
  end

  if p.auto_run_drone_qa then
    local cmd = r.NamedCommandLookup("_RSDF95_SampleDB_Drone_QA_Validator")
    if cmd ~= 0 then
      r.Main_OnCommand(cmd, 0)
    else
      r.ShowConsoleMsg("[DF95 AIWorker Pipeline] Drone-QA Command-ID nicht gefunden.\n")
    end
  end

  show_message(string.format(
    "Pipeline FullRun abgeschlossen.\nIngest OK: %d, Fehler: %d\nAuto-Apply: %s\nPhase O: %s, Drone QA: %s",
    ok_count, err_count,
    tostring(p.auto_apply_material_proposed_new and wmode == "material"),
    tostring(p.auto_run_phase_o),
    tostring(p.auto_run_drone_qa)
  ))
end

local function draw_results_tab()
  local _, _, results_dir, _ = get_aiworker_paths()

  ig.Text("Results")
  ig.Separator()
  ig.TextWrapped("Result-JSONs, die von deinem Python-AIWorker erzeugt wurden. Wähle ein Result und ingestiere es in die SampleDB.")
  ig.Spacing()

  if ig.Button("Result-Liste aktualisieren", 220, 0) then
    refresh_lists()
  end

  ig.Spacing()
  ig.Text("Vorhandene Results (Support/DF95_AIWorker/Results)")
  ig.Spacing()

  if #last_results == 0 then
    ig.TextDisabled("Keine Results gefunden.")
    return
  end

  if ig.BeginListBox("##results_list", -1, 150) then
    for i, name in ipairs(last_results) do
      local selected = (i == selected_result)
      if ig.Selectable(name, selected) then
        selected_result = i
      end
    end
    ig.EndListBox()
  end

  if selected_result > 0 and selected_result <= #last_results then
    local fname = last_results[selected_result]
    local full = join_path(results_dir, fname)
    ig.TextWrapped("Ausgewähltes Result:\n" .. full)
    ig.Spacing()
    if ig.Button("Dieses Result ingestieren", 260, 0) then
      run_aiworker_script("result/ingest", full)
    end
  
  ig.Separator()
  ig.Text("Pipeline FullRun:")
  if not pipeline_config or #pipeline_config.pipelines == 0 then
    ig.TextDisabled("Keine Pipeline-Konfiguration gefunden.")
  else
    if pipeline_selected_index == 0 then
      ig.TextDisabled("Kein Pipeline-Preset ausgewählt (wird im Batch-Tab gesetzt).")
    else
      local p = pipeline_config.pipelines[pipeline_selected_index]
      if p then
        ig.TextWrapped(string.format("Aktives Preset: %s (worker_mode=%s)", p.label or p.id or "?", p.worker_mode or "generic"))
        ig.Text(string.format("Auto-Apply Material: %s, Phase O: %s, Drone QA: %s",
          tostring(p.auto_apply_material_proposed_new),
          tostring(p.auto_run_phase_o),
          tostring(p.auto_run_drone_qa)))
        ig.Spacing()
        if ig.Button("Pipeline FULL RUN (alle Results ingestieren + optional Apply/QA)", 480, 0) then
          aiworker_pipeline_fullrun_for_results()
        end
      else
        ig.TextColored(1.0, 0.4, 0.4, 1.0, "Ungültiges Pipeline-Preset (Index außerhalb der Konfiguration).")
      end
    end
  end
end
end

local function draw_batch_tab()
  local root_path = batch_root

  ig.Text("Batch / Bench Mode")
  ig.Separator()
  ig.TextWrapped("Scanne eine Ordnerstruktur rekursiv nach Audiodateien, zeige eine Übersicht (Benchmark) und erzeuge AIWorker-Jobs für mehrere Ordner in einem Rutsch.")
  ig.Spacing()

  if ig.Button("Root-Ordner wählen & scannen...", 260, 0) then
    local start_dir = get_resource_path()
    local dir = start_dir
    if r.JS_Dialog_BrowseForFolder then
      local ok, out = r.JS_Dialog_BrowseForFolder("Root-Ordner für Batch-Scan wählen", start_dir)
      if ok and out and out ~= "" then
        dir = out
      else
        dir = nil
      end
    else
      local ok, out = r.GetUserInputs("Root-Ordner für Batch-Scan eingeben", 1, "Folder", start_dir)
      if ok and out and out ~= "" then dir = out else dir = nil end
    end
    if dir then
      batch_root = dir
      batch_folders = collect_batch_folders(dir)
      batch_selected = {}
      batch_total_folders = #batch_folders
      batch_total_files = 0
      for _, info in ipairs(batch_folders) do
        batch_total_files = batch_total_files + (info.files or 0)
      end
    end
  end

  ig.Spacing()

  if not batch_root then
    ig.TextDisabled("Noch kein Root-Ordner gewählt.")
    return
  end

  ig.TextWrapped("Root: " .. tostring(batch_root))
  ig.Spacing()
  ig.Text(string.format("Gefundene Ordner mit Audio: %d   |   Gesamt-Dateien: %d", batch_total_folders, batch_total_files))
  ig.Spacing()
  draw_worker_mode_selector()
  ig.Spacing()

  if batch_total_folders == 0 then
    ig.TextDisabled("Keine Ordner mit Audiodateien gefunden.")
    return
  end

  ig.Separator()
  ig.Text("Ordnerübersicht (Checkbox = Ordner für Job-Erstellung markieren)")
  ig.Spacing()

  if ig.BeginChild("##batch_folders_child", -1, 180, true) then
    for i, info in ipairs(batch_folders) do
      local label = string.format("%s  (%d Files)", info.rel or ".", info.files or 0)
      local v = batch_selected[i] or false
      local changed, nv = ig.Checkbox(label, v)
      if changed then
        batch_selected[i] = nv
      end
    end
    ig.EndChild()
  end

  ig.Spacing()
  local any_selected = false
  for i, v in pairs(batch_selected) do
    if v then any_selected = true break end
  end

  if ig.Button("Jobs für ausgewählte Ordner erstellen", 280, 0) then
    local count = 0
    for i, v in pairs(batch_selected) do
      if v and batch_folders[i] then
        run_aiworker_script("job/create", batch_folders[i].path)
        count = count + 1
      end
    end
    if count > 0 then
      refresh_lists()
    end
  end
  if not any_selected then
    ig.SameLine()
    ig.TextDisabled("(Keine Ordner ausgewählt)")
  end

  ig.Spacing()
  if ig.Button("Jobs für ALLE Ordner erstellen", 260, 0) then
    local count = 0
    for i, info in ipairs(batch_folders) do
      local wmode = get_current_worker_mode()
      run_aiworker_script("job/create", info.path, wmode)
      count = count + 1
    end
    if count > 0 then
      refresh_lists()
    end
  end

  -- Pipeline-Section
  ig.Separator()
  ig.Text("Pipeline Presets:")
  if #pipeline_config.pipelines == 0 then
    ig.TextDisabled("Keine Pipeline-Konfiguration gefunden.")
    ig.TextDisabled("Pfad: " .. tostring(pipeline_config_path or "?"))
  else
    if pipeline_selected_index < 0 then pipeline_selected_index = 0 end
    if pipeline_selected_index > #pipeline_config.pipelines then
      pipeline_selected_index = #pipeline_config.pipelines
    end

    ig.Text("Ausgewählte Pipeline:")
    if pipeline_selected_index == 0 then
      ig.SameLine()
      ig.TextColored(0.8, 0.8, 0.8, 1.0, "<kein Preset>")
    else
      local p = pipeline_config.pipelines[pipeline_selected_index]
      if p then
        ig.SameLine()
        ig.TextColored(0.4, 0.9, 0.4, 1.0, p.label or p.id or "<unnamed>")
        if p.description and p.description ~= "" then
          ig.TextWrapped(p.description)
        end
        ig.Text(string.format("worker_mode: %s", p.worker_mode or "generic"))
        ig.Text(string.format("auto_apply_material_proposed_new: %s", tostring(p.auto_apply_material_proposed_new)))
        ig.Text(string.format("auto_run_phase_o: %s, auto_run_drone_qa: %s",
          tostring(p.auto_run_phase_o), tostring(p.auto_run_drone_qa)))
        ig.Text(string.format("min_confidence_apply: %.2f", p.min_confidence_apply or 0.0))
      else
        ig.SameLine()
        ig.TextColored(1.0, 0.4, 0.4, 1.0, "<invalid index>")
      end
    end

    if ig.Button("Vorheriges Preset", 140, 0) then
      if pipeline_selected_index > 0 then
        pipeline_selected_index = pipeline_selected_index - 1
      else
        pipeline_selected_index = #pipeline_config.pipelines
      end
    end
    ig.SameLine()
    if ig.Button("Nächstes Preset", 140, 0) then
      if pipeline_selected_index < #pipeline_config.pipelines then
        pipeline_selected_index = pipeline_selected_index + 1
      else
        pipeline_selected_index = 0
      end
    end

    if pipeline_selected_index > 0 then
      local p = pipeline_config.pipelines[pipeline_selected_index]
      if p then
        ig.Separator()
        if ig.Button("Pipeline-Jobs für ALLE Ordner erstellen", 320, 0) then
          if batch_total_folders == 0 then
            show_message("Keine Ordner in der Batch-Liste. Bitte zuerst Root scannen.")
          else
            local base_paths = get_aiworker_paths()
            if not base_paths then
              show_message("AIWorker-Pfade unvollständig – bitte Setup prüfen.")
            else
              local count = 0
              for _, info in ipairs(batch_folders) do
                local job = {
                  version = 1,
                  created_utc = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                  audio_root = info.path,
                  sampledb_hint = base_paths.db_path or "",
                  worker_mode = p.worker_mode or "generic",
                  requested_tasks = p.requested_tasks or {},
                }
                local fname = string.format("DF95_AIWorker_Job_%s.json", os.date("%Y%m%d_%H%M%S"))
                local full = join_path(base_paths.jobs_dir, fname)
                ensure_dir(base_paths.jobs_dir)
                local ok, err = write_json(full, job)
                if not ok then
                  show_message("Fehler beim Schreiben von Pipeline-Job: " .. tostring(err))
                  break
                end
                count = count + 1
              end
              if count > 0 then
                show_message(string.format("Pipeline-Jobs für %d Ordner erstellt. Bitte Python-Worker laufen lassen und danach den Results-Tab nutzen.", count))
              end
            end
          end
        end
      end
    end
  end
end

  ImGui_Separator(ctx)
  ImGui_Text(ctx, "Pipeline Presets:")
  local items = {"<kein Preset>"}
  for i, p in ipairs(pipeline_config.pipelines) do
    table.insert(items, string.format("%d: %s", i, p.label or p.id or "?"))
  end
  local combo_label = table.concat(items, "##PIPE")
  -- simple combo replacement: show current and buttons to cycle
  ImGui_Text(ctx, "Ausgewählte Pipeline:")
  if pipeline_selected_index == 0 then
    ImGui_SameLine(ctx)
    ImGui_TextColored(ctx, 0.8, 0.8, 0.8, 1.0, "<kein Preset>")
  else
    local p = pipeline_config.pipelines[pipeline_selected_index]
    if p then
      ImGui_SameLine(ctx)
      ImGui_TextColored(ctx, 0.4, 0.9, 0.4, 1.0, p.label or p.id or "<unnamed>")
      if p.description and p.description ~= "" then
        ImGui_TextWrapped(ctx, p.description)
      end
      ImGui_Text(ctx, string.format("worker_mode: %s", p.worker_mode or "generic"))
      ImGui_Text(ctx, string.format("auto_apply_material_proposed_new: %s", tostring(p.auto_apply_material_proposed_new)))
      ImGui_Text(ctx, string.format("auto_run_phase_o: %s, auto_run_drone_qa: %s",
        tostring(p.auto_run_phase_o), tostring(p.auto_run_drone_qa)))
      ImGui_Text(ctx, string.format("min_confidence_apply: %.2f", p.min_confidence_apply or 0.0))
    else
      ImGui_SameLine(ctx)
      ImGui_TextColored(ctx, 1.0, 0.4, 0.4, 1.0, "<invalid index>")
    end
  end

  if ImGui_Button(ctx, "Vorheriges Preset", 140, 0) then
    if pipeline_selected_index > 0 then
      pipeline_selected_index = pipeline_selected_index - 1
    else
      pipeline_selected_index = #pipeline_config.pipelines
    end
  end
  ImGui_SameLine(ctx)
  if ImGui_Button(ctx, "Nächstes Preset", 140, 0) then
    if pipeline_selected_index < #pipeline_config.pipelines then
      pipeline_selected_index = pipeline_selected_index + 1
    else
      pipeline_selected_index = 0
    end
  end

  if pipeline_selected_index > 0 then
    local p = pipeline_config.pipelines[pipeline_selected_index]
    if p then
      ImGui_Separator(ctx)
      if ImGui_Button(ctx, "Jobs für Pipeline erstellen (aus Batch-Ordnern)", 320, 0) then
        if #state.batch_dirs == 0 then
          show_message("Keine Batch-Ordner gesetzt. Bitte zuerst 'Batch-Root durchsuchen'.")
        else
          local base_paths = get_aiworker_paths()
          if not base_paths then
            show_message("AIWorker-Pfade unvollständig – bitte Setup prüfen.")
          else
            -- pro Batch-Ordner einen Job nach Preset erstellen
            for _, dir in ipairs(state.batch_dirs) do
              local job = {
                version = 1,
                created_utc = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                audio_root = dir,
                sampledb_hint = base_paths.db_path or "",
                worker_mode = p.worker_mode or "generic",
                requested_tasks = p.requested_tasks or {},
              }
              local fname = string.format("DF95_AIWorker_Job_%s.json", os.date("%Y%m%d_%H%M%S"))
              local full = join_path(base_paths.jobs_dir, fname)
              ensure_dir(base_paths.jobs_dir)
              local ok, err = write_json(full, job)
              if not ok then
                show_message("Fehler beim Schreiben von Pipeline-Job: " .. tostring(err))
                break
              end
            end
            show_message("Pipeline-Jobs erstellt. Bitte Python-Worker laufen lassen und danach Result-Tab benutzen.")
          end
        end
      end
    end
  end

local function loop()
  ig.ImGui_SetNextWindowSize(ctx, 700, 420, ig.Cond_FirstUseEver())
  local visible, open = ig.ImGui_Begin(ctx, "DF95 AIWorker Hub", true)

  if visible then
    ig.Text("DF95 AIWorker Hub")
    ig.Separator()
    ig.TextWrapped("Zentrale UI für DF95 AIWorker UCS V1. Erzeuge Jobs für neue Audiosets und ingestiere AI-Resultate zurück in die DF95 SampleDB Multi-UCS.")

    ig.Spacing()
    if ig.BeginTabBar("##aiworker_tabs") then
      if ig.BeginTabItem("Jobs") then
        draw_jobs_tab()
        ig.EndTabItem()
      end
      if ig.BeginTabItem("Results") then
        draw_results_tab()
        ig.EndTabItem()
      end
      if ig.BeginTabItem("Batch / Bench") then
        draw_batch_tab()
        ig.EndTabItem()
      end
      ig.EndTabBar()
    end

    ig.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ig.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)
