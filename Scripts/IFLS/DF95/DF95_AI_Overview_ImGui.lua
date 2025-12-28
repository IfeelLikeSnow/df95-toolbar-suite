\
-- @description DF95_AI_Overview_ImGui
-- @version 1.1
-- @author DF95
-- @about
--   Zentrales Dashboard fuer die DF95-AI-Pipeline:
--   - zeigt Status von HybridAI-Slices, SampleDB Index V2 und Python/AIWorker
--   - optional: letzten AIWorker-Ingest-Run (Timestamp aus ExtState)
--   - bietet Shortcuts zu den wichtigsten AI-ImGui-Tools

local r = reaper
local ImGui = r.ImGui or reaper.ImGui

if not (ImGui and (r.ImGui_CreateContext or ImGui.CreateContext)) then
  r.ShowMessageBox("ReaImGui ist nicht installiert. Bitte ueber ReaPack nachinstallieren.", "DF95 AI Overview", 0)
  return
end

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function join(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function normalize(path)
  if sep == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function get_df95_data_dir()
  return normalize(join(join(res, "Data"), "DF95"))
end

local function get_sampledb_paths()
  local dd = get_df95_data_dir()
  local hybrid = join(dd, "SampleDB_HybridSlices.jsonl")
  local indexv2 = join(dd, "SampleDB_Index_V2.json")
  return normalize(hybrid), normalize(indexv2)
end

local function get_python_status()
  local ok, val = r.GetProjExtState(0, "DF95_AIWorker", "python_exe")
  local path = (ok ~= 0) and val or ""
  if path == "" then
    return "missing", ""
  end
  return "set", path
end

local function get_aiworker_last_run()
  local ok, ts = r.GetProjExtState(0, "DF95_AIWorker", "last_ingest_ts")
  if ok == 0 or (ts or "") == "" then
    return "unbekannt"
  end
  return ts
end

local function status_color(status)
  if status == "ok" then
    return 0.2, 0.9, 0.3, 1.0
  elseif status == "warn" then
    return 0.95, 0.8, 0.2, 1.0
  elseif status == "missing" or status == "error" then
    return 0.95, 0.3, 0.2, 1.0
  end
  return 0.8, 0.8, 0.8, 1.0
end

local ctx = ImGui.CreateContext("DF95 AI Overview")

local function draw_status_row(label, status, detail)
  local r_col, g_col, b_col, a_col = status_color(status)
  ImGui.Text(ctx, label .. ": ")
  ImGui.SameLine(ctx)
  ImGui.TextColored(ctx, r_col, g_col, b_col, a_col, status)
  if detail and detail ~= "" then
    ImGui.SameLine(ctx)
    ImGui.TextWrapped(ctx, " - " .. detail)
  end
end

local function open_script(rel)
  local path = normalize(join(join(join(res, "Scripts"), "IfeelLikeSnow"), "DF95"))
  path = join(path, rel)
  if not file_exists(path) then
    r.ShowMessageBox("Script nicht gefunden:\n" .. path, "DF95 AI Overview", 0)
    return
  end
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler beim Starten von:\n" .. path .. "\n\n" .. tostring(err), "DF95 AI Overview", 0)
  end
end

local function main_loop()
  ImGui.SetNextWindowSize(ctx, 640, 380, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "DF95 AI Overview", true)
  if visible then
    ImGui.Text(ctx, "DF95 AI-Pipeline Uebersicht")
    ImGui.Separator(ctx)

    local hybrid_path, indexv2_path = get_sampledb_paths()
    local hybrid_exists = file_exists(hybrid_path)
    local index_exists  = file_exists(indexv2_path)
    local py_status, py_path = get_python_status()
    local last_run = get_aiworker_last_run()

    -- HybridAI
    local st_hybrid = hybrid_exists and "ok" or "missing"
    draw_status_row("HybridAI Slices (SampleDB_HybridSlices.jsonl)", st_hybrid, hybrid_exists and hybrid_path or "")

    -- SampleDB Index V2
    local st_index = index_exists and "ok" or "missing"
    draw_status_row("SampleDB Index V2 (SampleDB_Index_V2.json)", st_index, index_exists and indexv2_path or "")

    -- Python / AIWorker
    local st_py = (py_status == "set") and "ok" or "missing"
    draw_status_row("Python / AIWorker", st_py, py_path)

    -- Letzter AIWorker-Run
    draw_status_row("Letzter AIWorker-Ingest", "info", last_run)

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Schnellzugriff:")

    if ImGui.Button(ctx, "Open HybridAI Slicing Hub", 250, 0) then
      open_script("DF95_Slicing_HybridAI_Hub_ImGui.lua")
    end
    if ImGui.Button(ctx, "Open Beat Control Center", 250, 0) then
      open_script("DF95_Beat_ControlCenter_ImGui.lua")
    end
    if ImGui.Button(ctx, "Open Global Beat Preset Loader", 250, 0) then
      open_script("DF95_Global_BeatPresetLoader_ImGui.lua")
    end
    if ImGui.Button(ctx, "Open AIWorker Hub", 250, 0) then
      open_script("DF95_AIWorker_Hub_ImGui.lua")
    end

    ImGui.Separator(ctx)
    ImGui.TextWrapped(ctx,
      "Minimaler Workflow:\n" ..
      "1) HybridAI nutzen, um neue Slices zu erzeugen (optional Auto-Export nach SampleDB).\n" ..
      "2) AIWorker Hub: Ingest laufen lassen -> SampleDB_Index_V2.json aktualisieren.\n" ..
      "3) Beat Control Center oder Global Beat Preset Loader: Artist-Beats & Kits aus SampleDB bauen.\n\n" ..
      "Wenn etwas rot ist, zuerst das hier pruefen, bevor du komplexe Probleme suchst.")
  end
  ImGui.End(ctx)

  if open then
    r.defer(main_loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

main_loop()
