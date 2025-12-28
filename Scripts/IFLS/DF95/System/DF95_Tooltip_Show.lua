
-- @description Tooltip Show (Console)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local fn = r.GetResourcePath()..sep.."Data"..sep.."DF95"..sep.."DF95_Tooltips.json"
local f = io.open(fn,"rb"); if not f then return end
local d = f:read("*all"); f:close()
if r.JSON_Decode then
  local map = r.JSON_Decode(d)
  for k,v in pairs(map) do r.ShowConsoleMsg(("[TIP] %s → %s\n"):format(k,v)) end
end
