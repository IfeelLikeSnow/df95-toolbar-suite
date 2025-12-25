-- DF95_V3_Module_Template.lua
-- Template for a reusable module (NOT directly executed as a REAPER action).
--
-- Usage (from an entry script):
--   local Core = dofile(reaper.GetResourcePath() .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
--   Core.bootstrap()
--   local Mod = dofile(Core.df95_root() .. "/Modules/MyModule.lua")
--   Mod.run(Core)

local M = {}

function M.run(Core, opts)
  opts = opts or {}
  if Core and Core.log_info then
    Core.log_info("DF95 V3 module running.")
  end
  -- Do work here...
  return true
end

return M
