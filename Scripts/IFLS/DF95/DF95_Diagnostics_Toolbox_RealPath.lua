-- DF95 Diagnostics Toolbox (Failsafe Version)
-- Führt Scripts direkt aus (auch ohne Reaper-Registrierung)

local r = reaper

local base = reaper.GetResourcePath():gsub("\\","/")

-- Feature flag gate (V3): diagnostics can be disabled via Support/DF95_Config.json
do
  local okc, Core = pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
  if okc and type(Core) == "table" and type(Core.get_config) == "function" then
    local cfg = Core.get_config()
    if cfg and cfg.features and cfg.features.enable_diagnostics == false then
      if Core.log_info then Core.log_info("Diagnostics disabled by config: " .. (debug.getinfo(1,'S').source or '?')) end
      return
    end
  end
end
local function try_run_script(script_name)
  local info = debug.getinfo(1, 'S')
  local script_path = info.source:match("@?(.*[/\\])")
  local full_path = script_path .. script_name

  -- Erst versuchen über NamedCommandLookup
  local cmd_id = r.NamedCommandLookup("_RS" .. full_path)
  if cmd_id and cmd_id ~= 0 then
    r.Main_OnCommand(cmd_id, 0)
    return
  end

  -- Fallback: direkt ausführen (auch ohne Registration)
  local ok, err = loadfile(full_path)
  if ok then
    ok()
  else
    r.ShowMessageBox("Script '" .. script_name .. "' konnte nicht gestartet werden.\nPfad: " .. full_path .. "\nFehler: " .. tostring(err), "DF95 Toolbox", 0)
  end
end

local function main()
  gfx.init("DF95 Toolbox Menu", 320, 200)
  local menu = "Diagnostics Toolbox|"
             .. "1. Diagnostics 2.0 (nicht mehr unterstützt)|"
             .. "2. Diagnostics 3.0 (nicht mehr unterstützt)|"
             .. "3. Auto Report Viewer|"
             .. "4. Auto Report Uploader|"
             .. "5. Report Cleaner|"
             .. "6. Self-Test Full Repo (RealPath, Refactored)|"
             .. "7. Self-Test Result Viewer"

  local choice = gfx.showmenu(menu)
  gfx.quit()

  if choice == 6 then
    try_run_script("DF95_Diagnostics_SelfTest_FullRepo_RealPath.lua")
  elseif choice == 7 then
    try_run_script("DF95_SelfTest_ResultViewer.lua")
  elseif choice >= 1 and choice <= 5 then
    r.ShowMessageBox("Menüpunkt " .. choice .. " ist aktuell nicht implementiert.", "DF95 Toolbox", 0)
  else
    r.ShowMessageBox("Kein gültiger Menüpunkt ausgewählt.", "DF95 Toolbox", 0)
  end
end

r.defer(main)
