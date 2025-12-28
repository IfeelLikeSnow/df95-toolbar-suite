-- DF95_V3_EntryScript_Template.lua
-- Template for a REAPER action (entrypoint script).
-- This file is intended as a starting point for NEW V3 scripts.
--
-- Best practice notes:
--  - Use GetResourcePath() to locate DF95 framework files reliably
--  - Bootstrap package.path only if you need require()
--  - Prefer DF95_PathResolver for locating DF95/IFLS roots

local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

-- Load V3 Core (stable API entrypoint)
local Core = dofile(base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")

-- Optional: bootstrap package.path for require()-based modules
-- (Safe: adds deterministic paths based on RootResolver + known Lib paths)
Core.bootstrap()

-- Example: logging
Core.log_info("Hello from DF95 V3 entry script.")

-- Example: resolve DF95 root and build a path
local df95_root = Core.df95_root()
if not df95_root then
  r.ShowMessageBox("DF95 root could not be resolved.", "DF95 V3 Template", 0)
  return
end

-- Put your actual code here:
-- e.g. call into a module:
-- local MyModule = dofile(df95_root .. "/Modules/MyModule.lua")
-- MyModule.run(Core)

r.ShowMessageBox("DF95 V3 EntryScript Template executed OK.\n\nDF95 root:\n" .. df95_root, "DF95 V3 Template", 0)
