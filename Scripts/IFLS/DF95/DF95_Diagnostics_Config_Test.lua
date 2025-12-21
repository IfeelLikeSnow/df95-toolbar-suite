-- DF95 Diagnostics: Config Overrides Test
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

local Core = dofile(base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
Core.bootstrap()

local cfg = Core.get_config()

local report_dir = base .. "/Support/DF95_Reports"
r.RecursiveCreateDirectory(report_dir, 0)
local ts = os.date("%Y%m%d_%H%M%S")
local txt = report_dir .. "/DF95_V3_Config_" .. ts .. ".txt"

local function w(f, k, v)
  f:write(string.format("%-24s %s\n", k, tostring(v)))
end

local f = io.open(txt, "w")
if f then
  f:write("DF95 V3 Config Overrides Test\n\n")
  w(f, "Config path", base .. "/Support/DF95_Config.json")
  w(f, "log.level", cfg.log and cfg.log.level)
  w(f, "log.to_console", cfg.log and cfg.log.to_console)
  w(f, "log.to_file", cfg.log and cfg.log.to_file)
  w(f, "features.enable_diagnostics", cfg.features and cfg.features.enable_diagnostics)
  w(f, "features.enable_experimental", cfg.features and cfg.features.enable_experimental)
  w(f, "compat.mode", cfg.compat and cfg.compat.mode)
  f:close()
end

r.ShowMessageBox("Config test OK.\n\nReport:\n" .. txt, "DF95 V3 Config", 0)
