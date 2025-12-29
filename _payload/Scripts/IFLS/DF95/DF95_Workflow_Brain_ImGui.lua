-- @description DF95 Workflow Brain (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Zentrales Orchestrierungs-UI für den DF95 Workflow:
--   Session Setup -> Fieldrec/Slicing -> Beats -> Sound/Mix -> Drones -> Library/Export.
--   Dieses Script öffnet ein ImGui-Fenster mit klar strukturierten Phasen
--   und Buttons, die die bestehenden DF95-Skripte per dofile() ausführen.
--
--   Ziel:
--     * weniger Suchen nach dem "nächsten Script"
--     * klarer visueller Pfad durch die Pipeline
--     * Status pro Phase optional in ExtState speicherbar
--
--   Hinweis:
--     Dieses Script setzt ReaImGui (REAPER v6.80+ / ReaScript API mit ImGui)
--     voraus. Falls ImGui nicht verfügbar ist, wird ein Fehlerdialog angezeigt.

local r = reaper

local ctx = nil
local FONT = nil

local SECTION = "DF95_WORKFLOW_BRAIN"
local KEY_PHASE_PREFIX = "PHASE_STATUS_" -- z.B. PHASE_STATUS_SESSION_SETUP = "TODO|INPROGRESS|DONE"

-- kleine Helper

local function script_path(rel)
  return r.GetResourcePath() .. "/" .. rel
end

local function run_df95_script(rel)
  local full = script_path(rel)
  local f, err = loadfile(full)
  if not f then
    r.ShowMessageBox("DF95 Workflow Brain:\nKonnte Script nicht laden:\n" .. full .. "\n\nFehler:\n" .. tostring(err),
      "DF95 Workflow Brain", 0)
    return
  end
  local ok, perr = pcall(f)
  if not ok then
    r.ShowMessageBox("DF95 Workflow Brain:\nFehler beim Ausführen von:\n" .. full .. "\n\nFehler:\n" .. tostring(perr),
      "DF95 Workflow Brain", 0)
  end


local function df95_file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function df95_get_aiworker_status()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local base = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep

  local hub_path    = base .. "DF95_AIWorker_Hub_ImGui.lua"
  local engine_path = base .. "DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua"
  local safety_path = base .. "DF95_Safety_AIWorker.lua"

  local hub_ok    = df95_file_exists(hub_path)
  local engine_ok = df95_file_exists(engine_path)

  local zoom_ok = false
  if df95_file_exists(safety_path) then
    local f, err = loadfile(safety_path)
    if f then
      local ok, mod = pcall(f)
      if ok and type(mod) == "table" and type(mod.check_zoom_aiworker_present) == "function" then
        local ok2, res2 = pcall(mod.check_zoom_aiworker_present)
        if ok2 and res2 then
          zoom_ok = true
        end
      end
    end
  end

  local level, msg

  if hub_ok and engine_ok then
    if zoom_ok then
      level = "OK"
      msg = "AIWorker Hub + UCS Engine + ZoomF6-Worker vorhanden."
    else
      level = "WARN"
      msg = "AIWorker Hub + UCS Engine vorhanden (ZoomF6-Worker optional, nicht gefunden)."
    end
  elseif hub_ok or engine_ok then
    level = "WARN"
    msg = "AIWorker nur teilweise installiert (Hub/Engine unvollständig)."
  else
    level = "FAIL"
    msg = "AIWorker nicht installiert (Hub + UCS Engine fehlen)."
  end

  return level, msg
end

end



local function df95_dir_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end
  if code == 13 then return true end -- permission denied, but exists
  return false
end

local function df95_get_aiworker_pipeline_status()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local support = res .. sep .. "Support"
  local root = support .. sep .. "DF95_AIWorker"

  if not df95_dir_exists(root) then
    return "MISS", "DF95_AIWorker-Ordner fehlt (Pipelines)", root
  end

  local cfg_path = root .. sep .. "DF95_AIWorker_Pipeline_Config.json"
  if not df95_file_exists(cfg_path) then
    return "WARN", "Pipeline-Config fehlt", cfg_path
  end

  return "OK", "Pipeline-Config gefunden", cfg_path
end

local function df95_find_latest_material_summary_path()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local results = res .. sep .. "Support" .. sep .. "DF95_AIWorker" .. sep .. "Results"

  if not df95_dir_exists(results) then
    return nil, results
  end

  local latest = nil
  local i = 0
  while true do
    local fname = r.EnumerateFiles(results, i)
    if not fname then break end
    if fname:match("_material_conflicts_summary%.json$") then
      if not latest or fname > latest then
        latest = fname
      end
    end
    i = i + 1
  end

  if not latest then return nil, results end
  return results .. sep .. latest, results
end

local function df95_get_aiworker_material_status()
  local path, results_dir = df95_find_latest_material_summary_path()
  if not results_dir or not df95_dir_exists(results_dir) then
    return "MISS", "AIWorker Results-Ordner fehlt", results_dir
  end
  if not path then
    return "WARN", "Keine Material-Summary gefunden", results_dir
  end
  return "OK", "Material-Summary vorhanden", path
end

local function df95_calc_ai_sync_summary()
  local install_level, install_msg = df95_get_aiworker_status()
  local pipe_level, pipe_msg, _ = df95_get_aiworker_pipeline_status()
  local mat_level, mat_msg, _   = df95_get_aiworker_material_status()

  local function weight(lvl)
    if lvl == "FAIL" or lvl == "MISS" then return 3 end
    if lvl == "WARN" then return 2 end
    if lvl == "OK" then return 1 end
    return 0
  end

  local worst = install_level or "UNKNOWN"
  if weight(pipe_level or "") > weight(worst) then
    worst = pipe_level
  end
  if weight(mat_level or "") > weight(worst) then
    worst = mat_level
  end

  local summary
  if worst == "FAIL" or worst == "MISS" then
    summary = "AIWorker nicht einsatzbereit – bitte die Phase 'System / Health' nutzen und AIWorker Setup ausführen."
  elseif pipe_level ~= "OK" then
    summary = "AIWorker installiert, aber Pipelines unvollständig. Bitte AIWorker Hub / Pipeline UI prüfen."
  elseif mat_level ~= "OK" then
    summary = "AIWorker aktiv, aber Material-Summary fehlt oder ist veraltet. Bitte einen Material-Pipeline-Run ausführen."
  else
    summary = "AIWorker Sync OK – Install, Pipelines und Material-Summary sehen gut aus."
  end

  local detail_lines = {}
  detail_lines[#detail_lines+1] = "Install: " .. (install_msg or "-")
  detail_lines[#detail_lines+1] = "Pipelines: " .. (pipe_msg or "-")
  detail_lines[#detail_lines+1] = "Material: " .. (mat_msg or "-")
  local detail = table.concat(detail_lines, "\n")

  return worst, summary, detail
end



local function df95_run_ai_autopilot()
  local level, summary, detail = df95_calc_ai_sync_summary()
  local install_level, install_msg = df95_get_aiworker_status()
  local pipe_level, pipe_msg, _ = df95_get_aiworker_pipeline_status()
  local mat_level, mat_msg, _   = df95_get_aiworker_material_status()

  local title = "DF95 AI Workflow Autopilot"
  local function msgbox(text)
    r.ShowMessageBox(text, title, 0)
  end

  -- Hard Stop: AIWorker nicht installiert
  if level == "FAIL" or level == "MISS" then
    local txt = (summary or "AIWorker nicht einsatzbereit.") ..
      "\n\nEmpfohlene Aktion:\n- System Health Panel öffnen und AIWorker Setup / Installation prüfen."
    msgbox(txt)
    run_df95_script("Scripts/IFLS/DF95/DF95_System_Health_Panel_ImGui.lua")
    return
  end

  -- Hard Stop: Pipeline-Config fehlt/defekt -> User in den Hub schicken
  if pipe_level ~= "OK" then
    local txt = (summary or "Pipelines unvollständig.") ..
      "\n\nEmpfohlene Aktion:\n- AIWorker Hub / Pipeline UI öffnen.\n- Relevante Pipelines konfigurieren oder reparieren."
    msgbox(txt)
    run_df95_script("Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua")
    return
  end

  -- Hard Mode: Material-Summary fehlt/veraltet -> versuche direkten Pipeline FullRun
  if mat_level ~= "OK" then
    local ok, info = df95_ai_autopilot_run_material_fullrun()
    if not ok then
      local txt = (summary or "Material-Summary fehlt oder ist veraltet.") ..
        "\n\nAutopilot konnte keinen direkten Run durchführen:\n" .. tostring(info or "?") ..
        "\n\nBitte AIWorker Hub / Pipeline UI manuell prüfen."
      msgbox(txt)
      run_df95_script("Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua")
      return
    else
      local txt = (summary or "Material-Summary fehlte/war veraltet.") ..
        "\n\nAutopilot hat einen Material-Pipeline-Run durchgeführt:\n" .. tostring(info or "") ..
        "\n\nDu kannst jetzt die System Health / Material-Ampel erneut prüfen."
      msgbox(txt)
      return
    end
  end

  -- Alles OK: Nur Hinweis
  local ok_txt = (summary or "AIWorker Sync OK.") ..
    "\n\nAutopilot-Hinweis:\n- AIWorker ist synchron mit dem DF95-Workflow.\n" ..
    "- Du kannst Library/Export oder weitere Phasen ohne AI-Fix starten."
  msgbox(ok_txt)
end

local function df95_join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then
    return a .. b
  end
  return a .. sep .. b
end

local function df95_load_json(path)
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local reader_path = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_ReadJSON.lua"
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

local function df95_run_aiworker_engine(mode, path, worker_mode)
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local engine_rel = "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua"
  local engine_full = res .. sep .. engine_rel

  local f, err = loadfile(engine_full)
  if not f then
    r.ShowMessageBox("DF95 AI Autopilot:
Konnte AIWorker-Engine nicht laden:
" .. engine_full ..
      "\n\nFehler:\n" .. tostring(err), "DF95 AI Autopilot", 0)
    return false, err
  end

  local orig_GetUserInputs = r.GetUserInputs
  r.GetUserInputs = function(title, num, captions_csv, defaults)
    local combo = (mode or "") .. "," .. (path or "") .. "," .. (worker_mode or "")
    return true, combo
  end

  local ok, perr = pcall(f)
  r.GetUserInputs = orig_GetUserInputs

  if not ok then
    r.ShowMessageBox("DF95 AI Autopilot:
Fehler beim Ausführen der Engine:
" .. tostring(perr),
      "DF95 AI Autopilot", 0)
    return false, perr
  end
  return true, nil
end

local function df95_select_default_material_pipeline(cfg)
  if not cfg or type(cfg.pipelines) ~= "table" then return nil, nil end

  local best_idx, best = nil, nil
  -- 1) Bevorzugt: material + auto_apply_material_proposed_new
  for i, p in ipairs(cfg.pipelines) do
    if p.worker_mode == "material" and p.auto_apply_material_proposed_new then
      return i, p
    end
  end
  -- 2) Nächster Kandidat: irgendein material-Preset
  for i, p in ipairs(cfg.pipelines) do
    if p.worker_mode == "material" then
      return i, p
    end
  end
  -- 3) Fallback: erstes Preset überhaupt
  if #cfg.pipelines > 0 then
    return 1, cfg.pipelines[1]
  end
  return nil, nil
end

local function df95_ai_autopilot_run_material_fullrun()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local support = res .. sep .. "Support"
  local root = support .. sep .. "DF95_AIWorker"
  local results_dir = root .. sep .. "Results"

  -- Pipeline-Config laden
  local cfg_path = root .. sep .. "DF95_AIWorker_Pipeline_Config.json"
  local cfg, err = df95_load_json(cfg_path)
  if not cfg then
    return false, "Pipeline-Config konnte nicht geladen werden: " .. tostring(err or "?")
  end

  local idx, pipe = df95_select_default_material_pipeline(cfg)
  if not idx or not pipe then
    return false, "Keine geeignete Material-Pipeline in der Config gefunden."
  end

  local wmode = pipe.worker_mode or "generic"

  -- Results einsammeln
  if not df95_dir_exists(results_dir) then
    return false, "Results-Ordner nicht gefunden: " .. tostring(results_dir)
  end

  local results = {}
  local i = 0
  while true do
    local fname = r.EnumerateFiles(results_dir, i)
    if not fname then break end
    if fname:match("^DF95_AIWorker_UCSResult_.*%.json$") then
      results[#results+1] = fname
    end
    i = i + 1
  end

  if #results == 0 then
    return false, "Keine DF95_AIWorker_UCSResult_*.json im Results-Ordner gefunden."
  end

  table.sort(results)

  local ok_count, err_count = 0, 0
  for _, fname in ipairs(results) do
    local full = df95_join_path(results_dir, fname)
    local ok, perr = df95_run_aiworker_engine("result/ingest", full, wmode)
    if ok then
      ok_count = ok_count + 1
    else
      err_count = err_count + 1
      r.ShowConsoleMsg("[DF95 AI Autopilot] Fehler beim Ingest von " .. tostring(full) .. ": " .. tostring(perr) .. "\n")
    end
  end

  -- Optional: Material-Auto-Apply
  if pipe.auto_apply_material_proposed_new and wmode == "material" then
    local sroot = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
    local apply_path = sroot .. sep .. "DF95_AIWorker_Material_Apply_ProposedNew.lua"
    if df95_file_exists(apply_path) then
      local ok_a, perr_a = pcall(dofile, apply_path)
      if not ok_a then
        r.ShowMessageBox("DF95 AI Autopilot:
Fehler bei Material_Apply_ProposedNew:
" .. tostring(perr_a),
          "DF95 AI Autopilot", 0)
      end
    else
      r.ShowMessageBox("DF95 AI Autopilot:
DF95_AIWorker_Material_Apply_ProposedNew.lua nicht gefunden – Auto-Apply übersprungen.",
        "DF95 AI Autopilot", 0)
    end
  end

  -- Optional: Phase O / Drone QA
  if pipe.auto_run_phase_o then
    local cmd = r.NamedCommandLookup("_RSDF95_Drone_System_Consistency_PhaseO")
    if cmd ~= 0 then
      r.Main_OnCommand(cmd, 0)
    else
      r.ShowConsoleMsg("[DF95 AI Autopilot] Phase-O Command-ID nicht gefunden.\n")
    end
  end

  if pipe.auto_run_drone_qa then
    local cmd = r.NamedCommandLookup("_RSDF95_SampleDB_Drone_QA_Validator")
    if cmd ~= 0 then
      r.Main_OnCommand(cmd, 0)
    else
      r.ShowConsoleMsg("[DF95 AI Autopilot] Drone-QA Command-ID nicht gefunden.\n")
    end
  end

  local summary = string.format(
    "Autopilot Material-Pipeline-Run abgeschlossen.\nIngest OK: %d, Fehler: %d\nPreset: %s (worker_mode=%s)",
    ok_count, err_count,
    tostring(pipe.name or ("Pipeline #" .. tostring(idx))),
    tostring(wmode)
  )
  return true, summary
end


local function get_phase_status(id)
  local v = r.GetExtState(SECTION, KEY_PHASE_PREFIX .. id)
  if v == nil or v == "" then return "UNKNOWN" end
  return v
end

local function set_phase_status(id, status)
  r.SetExtState(SECTION, KEY_PHASE_PREFIX .. id, status or "", true)
end

-- Phasen-Definitionen

local phases = {
  {
    id    = "SESSION_SETUP",
    label = "Session Setup",
    group = "SESSION",
    help  = "Session vorbereiten: AutoBus, FX-/Color-/Master-Busse, Mic/Input-FX.",
    actions = {
      { label = "Explode AutoBus",            rel = "Scripts/IFLS/DF95/DF95_Explode_AutoBus.lua" },

  {
    id    = "SYSTEM_HEALTH",
    label = "System / Health",
    group = "SYSHEALTH",
    help  = "Ampel-Panel für SampleDB, Drone QA/Phase O, AIWorker (Material/Drum/UCS/Pipelines) und Kern-Skripte.",
    actions = {
      { label = "System Health Panel",        rel = "Scripts/IFLS/DF95/DF95_System_Health_Panel_ImGui.lua" },
      { label = "AI Material Status",         rel = "Scripts/IFLS/DF95/DF95_AIWorker_Material_Status_ImGui.lua" },
      { label = "AI Material Conflict UI",    rel = "Scripts/IFLS/DF95/DF95_AIWorker_Material_Conflict_ImGui.lua" },
      { label = "AIWorker Hub / Pipeline UI", rel = "Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua" },
    }
  },
  {
    id    = "ARTIST_AI",
    label = "Artist / AI",
    group = "ARTIST",
    help  = "AI-gestützte Artist- und FXChain-Auswahl (IDM / Coloring / Bus).",
    actions = {
      {
        label = "AI Artist FXBrain (ImGui)",
        rel   = "Scripts/IFLS/DF95/DF95_AI_ArtistFXBrain_ImGui.lua",
      },
      {
        label = "AI Apply FXChain (ExtState)",
        rel   = "Scripts/IFLS/DF95/DF95_AI_ApplyFXChain_FromExtState.lua",
      },
    },
  },


      { label = "FX Bus Selector",            rel = "Scripts/IFLS/DF95/DF95_FXBus_Selector.lua" },
      { label = "FX Bus Chains GUI",          rel = "Scripts/IFLS/DF95/DF95_FXBus_Chains_ImGui.lua" },
      { label = "Coloring Bus",               rel = "Scripts/IFLS/DF95/DF95_Menu_Coloring_Dropdown.lua" },
      { label = "Master Bus Selector",        rel = "Scripts/IFLS/DF95/DF95_MasterBus_Selector.lua" },
      { label = "Master Chains GUI",          rel = "Scripts/IFLS/DF95/DF95_Master_Chains_ImGui.lua" },
      { label = "MicFX GUI",                  rel = "Scripts/IFLS/DF95/Tools/DF95_MicFX_Profile_GUI.lua" },
      { label = "InputFX Metering",           rel = "Scripts/IFLS/DF95/DF95_InputFX_Metering.lua" },
      { label = "InputFX Tape/Color",         rel = "Scripts/IFLS/DF95/DF95_InputFX_TapeColor.lua" },
    }
  },
  {
    id    = "FIELDREC_SLICING",
    label = "Fieldrec Slicing",
    group = "FIELDREC",
    help  = "Fieldrecordings analysieren, einfärben, slicen und verteilen.",
    actions = {
      { label = "Fieldrec Slicing Hub",       rel = "Scripts/IFLS/DF95/DF95_Fieldrec_Slicing_Hub_ImGui.lua" },
      { label = "Fieldrec Fusion GUI",        rel = "Scripts/IFLS/DF95/DF95_Fieldrec_Fusion_GUI.lua" },
      { label = "SliceKit RS5k Builder (V98)",rel = "Scripts/IFLS/DF95/DF95_V98_Fieldrec_SliceKitBuilder_RS5k.lua" },
    }
  },
  {
    id    = "FIELDREC_BEATS",
    label = "Beats aus Fieldrec",
    group = "FIELDREC",
    help  = "Aus Slices Kits/MIDIs erzeugen, Beats bauen und als Audio rendern.",
    actions = {
      { label = "Artist Beat Engine (V100)",  rel = "Scripts/IFLS/DF95/DF95_V100_Fieldrec_ArtistBeatEngine_MIDI.lua" },
      { label = "Artist Style Engine (V101)", rel = "Scripts/IFLS/DF95/DF95_V101_Fieldrec_ArtistStyleBeatEngine_MIDI.lua" },
      { label = "Adaptive Beat Engine (V107)",rel = "Scripts/IFLS/DF95/DF95_V107_Fieldrec_AdaptiveBeatEngine_MIDI.lua" },
      { label = "Render Beat Audio (V110)",   rel = "Scripts/IFLS/DF95/DF95_V110_FieldrecBeat_RenderAudioFromSlices.lua" },
      -- Beat-Export Scripts können hier ergänzt werden
    }
  },
  {
    id    = "SOUND_MIX",
    label = "Sound / Mix",
    group = "SOUND",
    help  = "FXBus, MasterChains, Coloring, GainMatch, Bias/ColorMaster.",
    actions = {
      { label = "FX Bus Selector",            rel = "Scripts/IFLS/DF95/DF95_FXBus_Selector.lua" },
      { label = "FX Bus Chains GUI",          rel = "Scripts/IFLS/DF95/DF95_FXBus_Chains_ImGui.lua" },
      { label = "Master Chains GUI",          rel = "Scripts/IFLS/DF95/DF95_Master_Chains_ImGui.lua" },
      { label = "Coloring Bus",               rel = "Scripts/IFLS/DF95/DF95_Menu_Coloring_Dropdown.lua" },
      { label = "GainMatch A/B",              rel = "Scripts/IFLS/DF95/DF95_GainMatch_AB.lua" },
      { label = "BiasTools Toolbar Show",     rel = "Scripts/IFLS/DF95/Tools/DF95_Toolbar_BiasTools_Show.lua" },
      { label = "ColorMaster Toolbar Show",   rel = "Scripts/IFLS/DF95/Tools/DF95_Toolbar_ColorMaster_Audition_SWS_Show.lua" },
    }
  },
  {
    id    = "DRONES",
    label = "Drones / Atmos",
    group = "DRONES",
    help  = "Drone-DB, QA, Producer Features und Atmos Builder.",
    actions = {
      { label = "Drone Dashboard (ImGui)",       rel = "Scripts/IFLS/DF95/DF95_DroneAnalyzer_Dashboard_ImGui.lua" },
      { label = "Drone DB Migration (Phase N)",  rel = "Scripts/IFLS/DF95/DF95_SampleDB_Drone_Migrate_PhaseN.lua" },
      { label = "Drone Consistency (Phase O)",   rel = "Scripts/IFLS/DF95/DF95_Drone_System_Consistency_PhaseO.lua" },
      { label = "Drone QA Validator",            rel = "Scripts/IFLS/DF95/DF95_SampleDB_Drone_QA_Validator.lua" },
      { label = "Drone Producer (Phase P)",      rel = "Scripts/IFLS/DF95/DF95_Drone_Producer_PhaseP.lua" },
      { label = "Drone Atmos Builder",           rel = "Scripts/IFLS/DF95/DF95_Drone_Atmos_Builder_From_View_ImGui.lua" },
      { label = "Drone AIWorker Hub (generic/drone)", rel = "Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua" },
    }
  },
  {
    id    = "LIB_EXPORT",
    label = "Library / Export",
    group = "LIBEXPORT",
    help  = "SampleDB pflegen, AIWorker, UCS-Renaming, Packs/PolyWAV/UCS-Export.",
    actions = {
      { label = "SampleDB Scan (Zoom/Fieldrec)",  rel = "Scripts/IFLS/DF95/DF95_V119_SampleDB_ScanFolder_ZoomF6.lua" },
      { label = "SampleDB Scan (UCS-Light Home Field)", rel = "Scripts/IFLS/DF95/DF95_V137_SampleDB_ScanFolder_UCSLight_HomeField.lua" },
      { label = "SampleDB Inspector V4",          rel = "Scripts/IFLS/DF95/DF95_V132_SampleDB_Inspector_V4_AI_Mapping.lua" },
      { label = "Library Analyzer (V138)",        rel = "Scripts/IFLS/DF95/DF95_V138_SampleDB_LibraryAnalyzer.lua" },
      { label = "Record Planner (V139)",          rel = "Scripts/IFLS/DF95/DF95_V139_SampleDB_RecordPlanner.lua" },
      { label = "Session Planner (V140)",         rel = "Scripts/IFLS/DF95/DF95_V140_SampleDB_SessionPlanner_Scenes.lua" },
      { label = "Texture Presets (V141)",         rel = "Scripts/IFLS/DF95/DF95_V141_SampleDB_TexturePresets_UCSLight.lua" },
      { label = "AIWorker Hub (ImGui)",        rel = "Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua" },
      { label = "AI Material Conflict UI",  rel = "Scripts/IFLS/DF95/DF95_AIWorker_Material_Conflict_ImGui.lua" },
      { label = "AI Material Apply ProposedNew",  rel = "Scripts/IFLS/DF95/DF95_AIWorker_Material_Apply_ProposedNew.lua" },
      { label = "AIWorker UCS (AI Engine)",      rel = "Scripts/IFLS/DF95/DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua" },
      { label = "UCS AI + Renamer Glue (V138)",      rel = "Scripts/IFLS/DF95/DF95_V138_UCS_AI_Rename_Glue.lua" },
      { label = "UCS Renamer (V134)",             rel = "Scripts/IFLS/DF95/DF95_V134_UCS_Renamer.lua" },
      { label = "UCS Rename Revert (V136)",       rel = "Scripts/IFLS/DF95/DF95_V136_UCS_RenameRevert_Helper.lua" },
      { label = "Pack Exporter (V142)",           rel = "Scripts/IFLS/DF95/DF95_V142_SampleDB_PackExporter.lua" },
      { label = "PolyWAV Toolbox V2 (V147)",      rel = "Scripts/IFLS/DF95/DF95_V147_PolyWAV_Toolbox_V2.lua" },
      { label = "UCS Export MasterButton",        rel = "Scripts/IFLS/DF95/DF95_Export_UCS_MasterButton.lua" },
    }
  },
}

-- GUI Zeichnen

local function status_color(status)
  if status == "DONE" then
    return 0, 0.8, 0, 1
  elseif status == "INPROGRESS" then
    return 0.9, 0.6, 0, 1
  elseif status == "TODO" then
    return 0.8, 0.2, 0.2, 1
  else
    return 0.4, 0.4, 0.4, 1
  end
end

local function draw_phase(p)
  local ig = r.ImGui
  local status = get_phase_status(p.id)

  ig.Text(p.label)
  ig.SameLine()
  local cr, cg, cb, ca = status_color(status)
  ig.PushStyleColor(ig.Col_Button, cr, cg, cb, ca)
  ig.PushStyleColor(ig.Col_ButtonHovered, cr, cg, cb, ca * 0.8)
  ig.PushStyleColor(ig.Col_ButtonActive, cr, cg, cb, ca)
  ig.SameLine()
  ig.Button("Status: " .. status)
  ig.PopStyleColor(3)

  if status ~= "DONE" then
    ig.SameLine()
    if ig.SmallButton("Mark as DONE##" .. p.id) then
      set_phase_status(p.id, "DONE")
      status = "DONE"
    end
  end
  ig.SameLine()
  if ig.SmallButton("TODO##" .. p.id) then
    set_phase_status(p.id, "TODO")
    status = "TODO"
  end
  ig.SameLine()
  if ig.SmallButton("IN PROGRESS##" .. p.id) then
    set_phase_status(p.id, "INPROGRESS")
    status = "INPROGRESS"
  end

  if p.help and p.help ~= "" then
    ig.TextWrapped(p.help)
  end

  if p.id == "LIB_EXPORT" then
    local level, summary, detail = df95_calc_ai_sync_summary()
    local cr, cg, cb
    if level == "OK" then
      cr, cg, cb = 0.0, 0.8, 0.0
    elseif level == "WARN" then
      cr, cg, cb = 0.9, 0.6, 0.0
    elseif level == "FAIL" or level == "MISS" then
      cr, cg, cb = 0.8, 0.2, 0.2
    else
      cr, cg, cb = 0.7, 0.7, 0.7
    end
    ig.Spacing()
    ig.Text("AIWorker Sync (Export-Phase):")
    ig.SameLine()
    ig.TextColored(cr, cg, cb, 1.0, (level or "UNKNOWN") .. " – " .. (summary or ""))

    if ig.IsItemHovered() and detail and detail ~= "" then
      ig.BeginTooltip()
      ig.TextWrapped(detail)
      ig.EndTooltip()
    end

    ig.Spacing()
    if ig.SmallButton("Run AI Autopilot (Export)##ai_export") then
      df95_run_ai_autopilot()
    end
    ig.Spacing()
  end

  ig.Separator()
  ig.Spacing()
end

local function loop()
  if ctx == nil then return end
  local ig = r.ImGui

  ig.ImGui_SetNextWindowSize(ctx, 640, 720, ig.Cond_FirstUseEver())
  local visible, open = ig.ImGui_Begin(ctx, "DF95 Workflow Brain", true)

  if visible then
    ig.Text("DF95 Workflow Brain")
    ig.Separator()
    ig.TextWrapped("Geführter Workflow durch die wichtigsten DF95-Phasen. Nutze die Status-Buttons, um dir zu merken, was schon erledigt ist, und starte die zugehörigen DF95-Skripte direkt aus diesem Fenster.")

    
    ig.Separator()
    ig.Spacing()

    -- AIWorker Sync Overview (global)
    local ai_level, ai_summary, ai_detail = df95_calc_ai_sync_summary()
    local cr, cg, cb = 0.7, 0.7, 0.7
    if ai_level == "OK" then
      cr, cg, cb = 0.0, 0.8, 0.0
    elseif ai_level == "WARN" then
      cr, cg, cb = 0.9, 0.6, 0.0
    elseif ai_level == "FAIL" or ai_level == "MISS" then
      cr, cg, cb = 0.8, 0.2, 0.2
    end

    ig.Text("AIWorker Sync:")
    ig.SameLine()
    ig.TextColored(cr, cg, cb, 1.0, (ai_level or "UNKNOWN") .. " – " .. (ai_summary or ""))

    if ig.IsItemHovered() and ai_detail and ai_detail ~= "" then
      ig.BeginTooltip()
      ig.TextWrapped(ai_detail)
      ig.EndTooltip()
    end

    ig.Spacing()
    if ig.SmallButton("Open System Health Panel##aiworker_sync") then
      run_df95_script("Scripts/IFLS/DF95/DF95_System_Health_Panel_ImGui.lua")
    end
    ig.SameLine()
    if ig.SmallButton("Open AIWorker Hub / Pipeline UI##aiworker_sync") then
      run_df95_script("Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua")
    end
    ig.SameLine()
    if ig.SmallButton("Run AI Workflow Autopilot##aiworker_sync") then
      df95_run_ai_autopilot()
    end

    ig.Separator()
    ig.Spacing()


    local current_group = nil
    for _, p in ipairs(phases) do
      if p.group ~= current_group then
        current_group = p.group
        ig.Separator()
        ig.TextColored(0.7, 0.9, 1.0, 1.0, "=== " .. current_group .. " ===")
        ig.Separator()
        ig.Spacing()
      end
      draw_phase(p)
    end

    ig.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    -- Fenster geschlossen -> Kontext zerstören
    ig.ImGui_DestroyContext(ctx)
    ctx = nil
  end
end

local function init()
  if not r.ImGui_CreateContext then
    r.ShowMessageBox(
      "DF95 Workflow Brain benötigt ReaImGui-Unterstützung in REAPER (v6.80+).\n" ..
      "Bitte auf eine aktuelle REAPER-Version updaten.",
      "DF95 Workflow Brain", 0)
    return
  end
  ctx = r.ImGui_CreateContext("DF95 Workflow Brain")
  loop()
end

init()
