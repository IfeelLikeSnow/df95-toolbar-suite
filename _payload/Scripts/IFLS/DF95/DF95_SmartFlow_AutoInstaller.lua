-- @description SmartFlow AutoInstaller (minimal)
-- @version 0.0.0
local r=reaper; local sep=package.config:sub(1,1); local res=r.GetResourcePath()

-- Auto-Index-Hook: führe nach Import den Chain Indexer einmal aus
local idx = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."System"..sep.."DF95_Chain_Indexer_v1.lua"
if reaper.file_exists(idx) then dofile(idx) end
