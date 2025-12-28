\
-- @description DF95 AIWorker Hub (ImGui) v2
-- @version 2.0
-- @author DF95
-- @about
--   Zentrale Schaltstelle fuer den DF95 AIWorker:
--     - Uebersicht ueber Slices / SampleDB Index V2
--     - Start des Python-AIWorkers (Ingest)
--     - Zugriff auf Status-/Conflict-/Apply-UIs
--     - Zugriff auf Legacy-Job-Manager (UCS V1)
--
--   Erwartet:
--     - DF95_AIWorker_Run_Ingest.lua
--     - DF95_AIWorker_Material_Status_ImGui.lua
--     - DF95_AIWorker_Material_Conflict_ImGui.lua
--     - DF95_AIWorker_Material_Apply_ProposedNew.lua
--     - DF95_SampleDB_IndexV2_Loader.lua

local r = reaper
local ig = r.ImGui or reaper.ImGui

if not ig then
  r.ShowMessageBox("ReaImGui ist nicht installiert. Bitte ueber ReaPack installieren.", "DF95 AIWorker Hub v2", 0)
  return
end

----------------------------------------------------------------
-- Pfad-Utilities
----------------------------------------------------------------

local function sep()
  return package.config:sub(1,1)
end

local function join(a, b)
  local s = sep()
  if a:sub(-1) == s then
    return a .. b
  else
    return a .. s .. b
  end
end

local function normalize(path)
  local s = sep()
  if s == "\\" then
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

----------------------------------------------------------------
-- SampleDB / Slices / Index V2
----------------------------------------------------------------

local function count_lines(path)
  local f = io.open(path, "r")
  if not f then return 0 end
  local n = 0
  for _ in f:lines() do
    n = n + 1
  end
  f:close()
  return n
end

local function get_aiworker_paths()
  local base = r.GetResourcePath()
  local data_dir = join(join(base, "Data"), "DF95")
  local supp_dir = join(join(base, "Support"), "DF95_AIWorker")

  local slices_jsonl = join(data_dir, "SampleDB_HybridSlices.jsonl")
  local index_json   = join(data_dir, "SampleDB_Index_V2.json")

  local lua_ai_run   = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  lua_ai_run         = join(lua_ai_run, "DF95_AIWorker_Run_Ingest.lua")

  local lua_status   = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  lua_status         = join(lua_status, "DF95_AIWorker_Material_Status_ImGui.lua")

  local lua_conflict = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  lua_conflict       = join(lua_conflict, "DF95_AIWorker_Material_Conflict_ImGui.lua")

  local lua_apply    = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  lua_apply          = join(lua_apply, "DF95_AIWorker_Material_Apply_ProposedNew.lua")

  local lua_index_loader = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  lua_index_loader       = join(lua_index_loader, "DF95_SampleDB_IndexV2_Loader.lua")

  local lua_legacy_hub   = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  lua_legacy_hub         = join(lua_legacy_hub, "DF95_AIWorker_Hub_ImGui_Legacy.lua")

  return {
    data_dir          = normalize(data_dir),
    supp_dir          = normalize(supp_dir),
    slices_jsonl      = normalize(slices_jsonl),
    index_json        = normalize(index_json),
    lua_ai_run        = normalize(lua_ai_run),
    lua_status        = normalize(lua_status),
    lua_conflict      = normalize(lua_conflict),
    lua_apply         = normalize(lua_apply),
    lua_index_loader  = normalize(lua_index_loader),
    lua_legacy_hub    = normalize(lua_legacy_hub)
  }
end

local function load_index_v2_count()
  local paths = get_aiworker_paths()
  if not file_exists(paths.lua_index_loader) then
    return 0, "Loader fehlt"
  end
  local ok, mod = pcall(dofile, paths.lua_index_loader)
  if not ok or type(mod) ~= "table" or type(mod.index) ~= "table" then
    return 0, "Loader-Fehler"
  end
  return #mod.index, ""
end

----------------------------------------------------------------
-- Python-Check
----------------------------------------------------------------

local ai_python_status = {
  checked = false,
  ok      = false,
  msg     = "Noch nicht geprueft."
}

local function get_python_exe()
  local section = "DF95_AIWorker"
  local key = "python_exe"
  local val = r.GetExtState(section, key)
  if not val or val == "" then
    return nil
  end
  return val
end

local function run_python_check()
  local exe = get_python_exe()
  if not exe then
    ai_python_status.checked = true
    ai_python_status.ok = false
    ai_python_status.msg = "Python-Pfad nicht gesetzt (ExtState DF95_AIWorker/python_exe)."
    return
  end

  -- Kleiner Test: librosa + soundfile importieren
  local cmd = string.format('"%s" -c "import librosa, soundfile"', exe)
  local ok = os.execute(cmd)
  ai_python_status.checked = true
  ai_python_status.ok = ok == true or ok == 0
  if ai_python_status.ok then
    ai_python_status.msg = "Python-Umgebung OK (librosa + soundfile importierbar)."
  else
    ai_python_status.msg = "Python-Umgebung FEHLER: libs nicht importierbar."
  end
end

----------------------------------------------------------------
-- Helpers: Scripts starten
----------------------------------------------------------------

local function run_lua_script(path)
  path = normalize(path)
  if not file_exists(path) then
    r.ShowMessageBox("Script nicht gefunden:\n" .. path, "DF95 AIWorker Hub v2", 0)
    return
  end
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler beim Ausfuehren:\n" .. path .. "\n\n" .. tostring(err), "DF95 AIWorker Hub v2", 0)
  end
end

----------------------------------------------------------------
-- ImGui State
----------------------------------------------------------------

local ctx = ig.CreateContext("DF95 AIWorker Hub v2", ig.ConfigFlags_None)
local FONT_SCALE = 1.0

----------------------------------------------------------------
-- Drawing
----------------------------------------------------------------

local function draw_header()
  local paths = get_aiworker_paths()

  local slices_count = 0
  if file_exists(paths.slices_jsonl) then
    slices_count = count_lines(paths.slices_jsonl)
  end

  local idx_count, idx_msg = load_index_v2_count()

  ig.Text("DF95 AIWorker Hub v2")
  ig.Separator()
  ig.Text("Datenpfade:")
  ig.BulletText("Slices JSONL: %s", paths.slices_jsonl)
  ig.BulletText("Index V2 JSON: %s", paths.index_json)

  ig.Spacing()
  ig.Text(string.format("Hybrid Slices (JSONL): %d Eintraege", slices_count))
  if idx_msg ~= "" then
    ig.Text(string.format("SampleDB Index V2: %d Eintraege (%s)", idx_count, idx_msg))
  else
    ig.Text(string.format("SampleDB Index V2: %d Eintraege", idx_count))
  end

  ig.Spacing()
  ig.Separator()
  ig.Text("Python / AIWorker Status:")
  if not ai_python_status.checked then
    ig.TextColored(1.0, 0.8, 0.3, 1.0, "Noch nicht geprueft.")
  else
    if ai_python_status.ok then
      ig.TextColored(0.3, 1.0, 0.3, 1.0, ai_python_status.msg)
    else
      ig.TextColored(1.0, 0.3, 0.3, 1.0, ai_python_status.msg)
    end
  end
  if ig.Button("Python-Check jetzt ausfuehren", 260, 0) then
    run_python_check()
  end

  ig.Spacing()
  ig.Separator()
end

local function draw_tab_ingest()
  local paths = get_aiworker_paths()
  ig.TextWrapped("Ingest-Tab: startet den Python-AIWorker, um aus den Hybrid-Slices (JSONL) einen aktuellen SampleDB_Index_V2.json zu erzeugen.")

  ig.Spacing()

  if not file_exists(paths.slices_jsonl) then
    ig.TextColored(1.0, 0.5, 0.2, 1.0, "Hinweis: Noch keine SampleDB_HybridSlices.jsonl gefunden.")
    ig.TextWrapped("Bitte zuerst DF95_Slicing_HybridAI_ToSampleDB.lua ausfuehren (z.B. aus dem HybridAI Slicing Hub).")
    ig.Spacing()
  end

  if ig.Button("AIWorker Ingest jetzt ausfuehren", 260, 0) then
    run_lua_script(paths.lua_ai_run)
  end

  ig.Spacing()
  ig.Text("Python-Pfad (ExtState DF95_AIWorker/python_exe):")
  local cur = get_python_exe() or "(nicht gesetzt)"
  ig.TextWrapped(cur)
  ig.Spacing()
  ig.TextWrapped("Du kannst den Python-Pfad direkt in DF95_AIWorker_Run_Ingest.lua setzen (Dialog) oder die ExtState manuell anpassen.")
end

local function draw_tab_status()
  local paths = get_aiworker_paths()
  ig.TextWrapped("Status-Tab: zeigt AIWorker-Material-Uebersicht und ggf. Konflikte/Aenderungen.")
  ig.Spacing()
  if ig.Button("Status-Fenster oeffnen (Material Status)", 260, 0) then
    run_lua_script(paths.lua_status)
  end
end

local function draw_tab_conflicts()
  local paths = get_aiworker_paths()
  ig.TextWrapped("Conflicts-Tab: oeffnet das Conflict-UI fuer AIWorker-Mappings (falls vorhanden).")
  ig.Spacing()
  if ig.Button("Conflict-Fenster oeffnen", 220, 0) then
    run_lua_script(paths.lua_conflict)
  end
end

local function draw_tab_apply()
  local paths = get_aiworker_paths()
  ig.TextWrapped("Apply-Tab: oeffnet das Apply-UI, um vorgeschlagene AI-Mappings final anzuwenden.")
  ig.Spacing()
  if ig.Button("Apply-Fenster oeffnen", 220, 0) then
    run_lua_script(paths.lua_apply)
  end
end

local function draw_tab_legacy()
  local paths = get_aiworker_paths()
  ig.TextWrapped("Legacy-Tab: Zugriff auf den bisherigen AIWorker-Job-Hub (UCS V1, Ordner-Jobs usw.).")
  ig.Spacing()
  if not file_exists(paths.lua_legacy_hub) then
    ig.TextColored(1.0, 0.5, 0.2, 1.0, "Legacy-Hub-Script nicht gefunden (DF95_AIWorker_Hub_ImGui_Legacy.lua).")
    ig.TextWrapped("Wenn du alte UCS-Jobs weiter nutzen willst, stelle sicher, dass das Legacy-Script vorhanden ist.")
    return
  end
  if ig.Button("Legacy AIWorker Job Hub oeffnen", 260, 0) then
    run_lua_script(paths.lua_legacy_hub)
  end
end

----------------------------------------------------------------
-- Main Loop
----------------------------------------------------------------

local function loop()
  ig.SetNextWindowSize(ctx, 720, 520, ig.Cond_FirstUseEver)
  local visible, open = ig.Begin(ctx, "DF95 AIWorker Hub v2", true)
  if visible then
    draw_header()

    if ig.BeginTabBar(ctx, "AIWorkerHubTabs", ig.TabBarFlags_None) then
      if ig.BeginTabItem(ctx, "Ingest") then
        draw_tab_ingest()
        ig.EndTabItem(ctx)
      end
      if ig.BeginTabItem(ctx, "Status") then
        draw_tab_status()
        ig.EndTabItem(ctx)
      end
      if ig.BeginTabItem(ctx, "Conflicts") then
        draw_tab_conflicts()
        ig.EndTabItem(ctx)
      end
      if ig.BeginTabItem(ctx, "Apply") then
        draw_tab_apply()
        ig.EndTabItem(ctx)
      end
      if ig.BeginTabItem(ctx, "Legacy Jobs") then
        draw_tab_legacy()
        ig.EndTabItem(ctx)
      end

      ig.EndTabBar(ctx)
    end
  end
  ig.End(ctx)

  if open then
    r.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
