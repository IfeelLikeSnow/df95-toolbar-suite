-- @description DF95 Setup / QA Hub (ImGui) – Finalizer
-- @version 1.0
-- @author DF95
-- @about
--   Zentrales Setup- und QA-Panel für das DF95-System.
--   Zeigt:
--     * System- und Abhängigkeitsstatus (REAPER, SWS, ReaImGui, Python, SampleDB, AIWorker)
--     * Buttons zum Starten der wichtigsten Self-Check- und Validator-Tools
--   Macht keine automatischen Änderungen, sondern dient als "Control Panel".

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox(
    "DF95 Setup / QA Hub benötigt REAPER mit ReaImGui-Unterstützung (REAPER v6.80+).",
    "DF95 Setup / QA Hub", 0)
  return
end

local ctx = r.ImGui_CreateContext("DF95 Setup / QA Hub")
local ig = r.ImGui

local sep = package.config:sub(1,1)

local function join_path(...)
  local parts = { ... }
  return table.concat(parts, sep)
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function get_res()
  return r.GetResourcePath()
end

------------------------------------------------------------
-- Status-Checks
------------------------------------------------------------

local function status_color(level)
  if level == "OK" then
    return 0.0, 0.8, 0.0
  elseif level == "WARN" then
    return 0.9, 0.6, 0.0
  else
    return 0.8, 0.2, 0.2
  end
end

local function check_reaper()
  local v = r.GetAppVersion()
  return "OK", "REAPER " .. tostring(v)
end

local function check_sws()
  if r.BR_GetMouseCursorContext then
    return "OK", "SWS/S&M Extension gefunden."
  else
    return "WARN", "SWS/S&M Extension nicht gefunden – einige DF95-Funktionen benötigen SWS."
  end
end

local function check_imgui()
  if r.ImGui_CreateContext then
    return "OK", "ReaImGui API verfügbar."
  else
    return "FAIL", "ReaImGui nicht gefunden – ImGui-Hubs & Brain funktionieren nicht."
  end
end

local function check_python()
  -- Konservativ: wir versuchen, ExecProcess zu nutzen, wenn vorhanden.
  if not r.ExecProcess then
    return "WARN", "Kann Python-Version nicht prüfen (ExecProcess nicht verfügbar)."
  end
  local cmd = "python --version"
  local ok, ret = pcall(function()
    local exit_code, out = r.ExecProcess(cmd, 0)
    return exit_code, out
  end)
  if not ok then
    return "WARN", "Python-Check fehlgeschlagen (ExecProcess-Fehler)."
  end
  if ret and (ret:match("Python%s+%d+%.%d+") or ret:match("Python %d+%.%d+")) then
    return "OK", ret:gsub("\n","")
  else
    return "WARN", "Python nicht eindeutig gefunden (Ausgabe: " .. tostring(ret):gsub("\n"," ") .. ")"
  end
end

local function check_sampledb()
  local res = get_res()
  local support = join_path(res, "Support")
  local db_dir = join_path(support, "DF95_SampleDB")
  local db_path = join_path(db_dir, "DF95_SampleDB_Multi_UCS.json")
  if file_exists(db_path) then
    return "OK", db_path
  else
    return "WARN", "SampleDB Multi-UCS nicht gefunden unter:\n" .. db_path
  end
end

local function df95_get_aiworker_status()
  local res = get_res()
  local base = join_path(res, "Scripts", "IfeelLikeSnow", "DF95")

  local hub_path    = join_path(base, "DF95_AIWorker_Hub_ImGui.lua")
  local engine_path = join_path(base, "DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua")
  local safety_path = join_path(base, "DF95_Safety_AIWorker.lua")

  local hub_ok    = file_exists(hub_path)
  local engine_ok = file_exists(engine_path)

  local zoom_ok = false
  if file_exists(safety_path) then
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

local function check_toolbars()
  local res = get_res()
  local menus = join_path(res, "Menus")
  local main = join_path(menus, "DF95_SuperToolbar_Main.ReaperMenuSet")
  if file_exists(main) then
    return "OK", "DF95_SuperToolbar_Main gefunden."
  else
    return "WARN", "DF95 SuperToolbar Main-Menü nicht gefunden – ggf. nicht installiert."
  end
end

------------------------------------------------------------
-- Runner für externe Tools
------------------------------------------------------------

local function run_script(rel)
  local res = get_res()
  local full = join_path(res, rel:gsub("[/\\]", sep))
  if not file_exists(full) then
    r.ShowMessageBox("DF95 Setup/QA Hub:\nScript nicht gefunden:\n" .. full,
      "DF95 Setup/QA Hub", 0)
    return
  end
  local f, err = loadfile(full)
  if not f then
    r.ShowMessageBox("DF95 Setup/QA Hub:\nKonnte Script nicht laden:\n" .. full ..
      "\nFehler: " .. tostring(err), "DF95 Setup/QA Hub", 0)
    return
  end
  local ok, perr = pcall(f)
  if not ok then
    r.ShowMessageBox("DF95 Setup/QA Hub:\nFehler beim Ausführen des Scripts:\n" .. full ..
      "\nFehler: " .. tostring(perr), "DF95 Setup/QA Hub", 0)
  end
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

local function draw_status_row(label, level, msg)
  local cr, cg, cb = status_color(level)
  ig.Text(label .. ":")
  ig.SameLine()
  ig.TextColored(cr, cg, cb, 1.0, level)
  if msg and msg ~= "" then
    ig.SameLine()
    ig.Text(" – ")
    ig.SameLine()
    ig.TextWrapped(msg)
  end
end

local function loop()
  ig.ImGui_SetNextWindowSize(ctx, 720, 480, ig.Cond_FirstUseEver())
  local visible, open = ig.ImGui_Begin(ctx, "DF95 Setup / QA Hub", true)

  if visible then
    ig.Text("DF95 Setup / QA Hub – Finalizer")
    ig.Separator()
    ig.TextWrapped("Zentrales Control Panel für DF95 Setup und QA. Prüft Kernabhängigkeiten (REAPER, SWS, ReaImGui, Python, SampleDB, AIWorker, SuperToolbar) und bietet Buttons für Self-Check- und Validator-Tools.")
    ig.Spacing()

    if ig.CollapsingHeader("System-Status (Core Dependencies)", true) then
      local lvl_reaper, msg_reaper = check_reaper()
      local lvl_sws, msg_sws       = check_sws()
      local lvl_imgui, msg_imgui   = check_imgui()
      local lvl_py, msg_py         = check_python()
      local lvl_db, msg_db         = check_sampledb()
      local lvl_aiw, msg_aiw       = df95_get_aiworker_status()
      local lvl_tb, msg_tb         = check_toolbars()

      draw_status_row("REAPER", lvl_reaper, msg_reaper)
      draw_status_row("SWS", lvl_sws, msg_sws)
      draw_status_row("ReaImGui", lvl_imgui, msg_imgui)
      draw_status_row("Python", lvl_py, msg_py)
      draw_status_row("SampleDB Multi-UCS", lvl_db, msg_db)
      draw_status_row("AIWorker", lvl_aiw, msg_aiw)
      draw_status_row("SuperToolbar", lvl_tb, msg_tb)

      ig.Spacing()
    end

    if ig.CollapsingHeader("Self-Checks & Validatoren", true) then
      ig.Text("Self-Check & Diagnostics")
      if ig.Button("DF95 Self-Check Toolkit", 220, 0) then
        run_script("Scripts/IFLS/DF95/DF95_SelfCheck_Toolkit.lua")
      end
      ig.SameLine()
      if ig.Button("Safety SelfCheck Tool (Stufe 4)", 260, 0) then
        run_script("Scripts/IFLS/DF95/DF95_Safety_SelfCheck_Tool.lua")
      end

      ig.Spacing()
      ig.Text("Validatoren")
      if ig.Button("Validator Pro (Deep System Check)", 260, 0) then
        run_script("Scripts/IFLS/DF95/DF95_Validator_Pro.lua")
      end
      ig.SameLine()
      if ig.Button("Dashboard Center (Legacy Menu)", 260, 0) then
        run_script("Scripts/IFLS/DF95/DF95_Dashboard_Center.lua")
      end

      ig.Spacing()
      ig.Text("SampleDB / Drone Validatoren")
      if ig.Button("SampleDB Validator V3", 220, 0) then
        run_script("Scripts/IFLS/DF95/DF95_SampleDB_Validator_V3.lua")
      end
      ig.SameLine()
      if ig.Button("Drone QA Validator", 200, 0) then
        run_script("Scripts/IFLS/DF95/DF95_SampleDB_Drone_QA_Validator.lua")
      end
    end

    if ig.CollapsingHeader("AI / QA Hubs", false) then
      ig.Text("AI / QA Zentren")
      if ig.Button("AIWorker Hub (ImGui)", 220, 0) then
        run_script("Scripts/IFLS/DF95/DF95_AIWorker_Hub_ImGui.lua")
      end
      ig.SameLine()
      if ig.Button("AI QA Center (ImGui)", 220, 0) then
        run_script("Scripts/IFLS/DF95/DF95_AI_QA_Center_ImGui.lua")
      end

      ig.Spacing()
      if ig.Button("Safety AIWorker Status", 220, 0) then
        run_script("Scripts/IFLS/DF95/DF95_Safety_AIWorker.lua")
      end
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
