-- DF95 Diagnostics DepScanner Runner
-- Ruft DF95_Diagnostics_Lib_DepScanner.run() auf

local r = reaper

local base = r.GetResourcePath()

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
local lib_path = base .. "/Scripts/DF95Framework/Lib/DF95_Diagnostics_Lib_DepScanner.lua"

local ok, dep_lib = pcall(dofile, lib_path)
if not ok then
  r.ShowMessageBox("Konnte DepScanner Lib nicht laden:\n" .. tostring(dep_lib) ..
                   "\n\nPfad:\n" .. lib_path,
                   "DF95 DepScanner Runner", 0)
  return
end

if type(dep_lib) ~= "table" or type(dep_lib.run) ~= "function" then
  r.ShowMessageBox("DepScanner Lib ist ungültig oder hat keine run()-Funktion:\n" ..
                   tostring(lib_path),
                   "DF95 DepScanner Runner", 0)
  return
end

dep_lib.run()
