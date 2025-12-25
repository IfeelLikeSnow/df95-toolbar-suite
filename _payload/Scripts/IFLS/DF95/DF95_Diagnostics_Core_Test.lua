-- DF95 Diagnostics: V3 Core Test
-- Loads DF95_Core.lua and writes a short report to Support/DF95_Reports

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
local core_path = base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua"

local ok, Core = pcall(dofile, core_path)
if not ok then
  r.ShowMessageBox("Konnte DF95_Core.lua nicht laden:\n" .. tostring(Core) .. "\n\nPfad:\n" .. core_path,
                   "DF95 V3 Core Test", 0)
  return
end

Core.bootstrap()

local report_dir = base .. "/Support/DF95_Reports"
r.RecursiveCreateDirectory(report_dir, 0)
local ts = os.date("%Y%m%d_%H%M%S")
local txt = report_dir .. "/DF95_V3_Core_" .. ts .. ".txt"

local f = io.open(txt, "w")
if f then
  f:write("DF95 V3 Core Test\n")
  f:write("Core version: " .. tostring(Core.VERSION) .. "\n")
  f:write("Build date  : " .. tostring(Core.BUILD_DATE) .. "\n")
  f:write("ResourcePath: " .. tostring(Core.resource_path()) .. "\n")
  f:write("OS          : " .. tostring(Core.os()) .. "\n")
  f:write("DF95 root   : " .. tostring(Core.df95_root()) .. "\n")
  f:write("IFLS root   : " .. tostring(Core.ifls_root()) .. "\n")
  f:close()
end

r.ShowMessageBox("DF95 V3 Core OK.\n\nReport:\n" .. txt, "DF95 V3 Core Test", 0)
