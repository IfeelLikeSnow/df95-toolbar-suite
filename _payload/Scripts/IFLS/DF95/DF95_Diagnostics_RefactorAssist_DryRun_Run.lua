-- DF95 Diagnostics Refactor Assist (Dry Run) Runner
-- Lädt DF95_Diagnostics_Lib_RefactorAssist_DryRun.lua und startet run()

local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

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

-- Optional: package.path bootstrap (für zukünftige require()-Nutzung)
pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_LuaPath.lua")

local lib_path = base .. "/Scripts/DF95Framework/Lib/DF95_Diagnostics_Lib_RefactorAssist_DryRun.lua"
local ok, lib = pcall(dofile, lib_path)
if not ok then
  r.ShowMessageBox("Konnte RefactorAssist Lib nicht laden:\n" .. tostring(lib) .. "\n\nPfad:\n" .. lib_path,
    "DF95 Refactor Assist (Dry Run) Runner", 0)
  return
end

if type(lib) ~= "table" or type(lib.run) ~= "function" then
  r.ShowMessageBox("RefactorAssist Lib ist ungültig oder hat keine run()-Funktion.\nPfad:\n" .. lib_path,
    "DF95 Refactor Assist (Dry Run) Runner", 0)
  return
end

lib.run()
