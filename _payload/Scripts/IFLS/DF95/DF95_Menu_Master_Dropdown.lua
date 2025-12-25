-- DF95_Menu_Master_Dropdown.lua (V3 Hub Entrypoint)
-- Backward compatible Action: delegates to central master hub.
local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

local Hubs = dofile(base .. "/Scripts/DF95Framework/Menus/DF95_Hubs.lua")
Hubs.run_hub("master")

--[[ 
LEGACY CSV-driven implementation moved to:
  DF95_Menu_Master_Dropdown_Legacy.lua
]]
