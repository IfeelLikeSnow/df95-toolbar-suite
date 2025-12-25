-- DF95 Diagnostics Insight Runner
-- Liest den neuesten DF95_DepGraph_*.json aus Support/DF95_Reports
-- und erzeugt DF95_Insight_*.{txt,json}

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

-- Optional: package.path bootstrappen (für zukünftige require()-Nutzung)
local lua_path_lib = base .. "/Scripts/DF95Framework/Lib/DF95_LuaPath.lua"
pcall(dofile, lua_path_lib) -- ignore errors, Insight nutzt dofile/paths

local lib_path = base .. "/Scripts/DF95Framework/Lib/DF95_Diagnostics_Lib_Insight.lua"
local ok, lib = pcall(dofile, lib_path)
if not ok then
  r.ShowMessageBox("Konnte Insight Lib nicht laden:\n" .. tostring(lib) .. "\n\nPfad:\n" .. lib_path,
    "DF95 Insight Runner", 0)
  return
end

if type(lib) ~= "table" or type(lib.run) ~= "function" then
  r.ShowMessageBox("Insight Lib ist ungültig oder hat keine run()-Funktion.\nPfad:\n" .. lib_path,
    "DF95 Insight Runner", 0)
  return
end

lib.run()
