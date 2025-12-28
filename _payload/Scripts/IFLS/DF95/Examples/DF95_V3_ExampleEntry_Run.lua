-- DF95_V3_ExampleEntry_Run.lua
-- Example V3 entry script (Action): loads DF95_Core, bootstraps, and runs ExampleModule.

local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

-- Feature flag gate (V3): experimental examples can be disabled via Support/DF95_Config.json
do
  local okc, Core = pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
  if okc and type(Core) == "table" and type(Core.get_config) == "function" then
    local cfg = Core.get_config()
    if cfg and cfg.features and cfg.features.enable_experimental == false then
      if Core.log_info then Core.log_info("Experimental example disabled by config.") end
      reaper.ShowMessageBox("Dieses Beispiel ist deaktiviert (enable_experimental=false in Support/DF95_Config.json).", "DF95 V3 Example", 0)
      return
    end
  end
end

-- Load V3 Core (stable API entrypoint)
local Core = dofile(base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")

-- Optional but recommended: deterministic package.path initialization
Core.bootstrap()

-- Load the example module from DF95 root (RootResolver-backed)
local df95_root = Core.df95_root()
if not df95_root then
  r.ShowMessageBox("DF95 root could not be resolved.", "DF95 V3 Example", 0)
  return
end

local mod_path = df95_root .. "/Modules/DF95_V3_ExampleModule.lua"
local ok, Mod = pcall(dofile, mod_path)
if not ok then
  r.ShowMessageBox("Failed to load ExampleModule:\n" .. tostring(Mod) .. "\n\nPath:\n" .. mod_path, "DF95 V3 Example", 0)
  return
end

local ok2, result = Mod.run(Core)
if not ok2 then
  r.ShowMessageBox("ExampleModule returned error:\n" .. tostring(result), "DF95 V3 Example", 0)
  return
end

r.ShowMessageBox(
  "DF95 V3 Example OK.\n\nSelected tracks: " .. tostring(result.selected_tracks) ..
  "\nTimestamp: " .. tostring(result.timestamp) ..
  "\n\nLog file:\n" .. (Core.resource_path() .. "/Support/DF95_Reports/DF95_V3_Core.log"),
  "DF95 V3 Example", 0
)
