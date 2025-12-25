-- @description DF95_MicFX_Manager (wrapper)
-- @version 1.1

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local path = (res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_MicFX_Manager.lua"):gsub("\\","/")

dofile(path)
