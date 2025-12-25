-- @description CPU Monitor → FlowBus
-- @version 1.0
-- @author DF95
local r = reaper
local sep = package.config:sub(1,1)
local FB = dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..package.config:sub(1,1)..")").."DF95_FlowBus.lua")
local function loop()
  local load = r.GetCPUUsage and r.GetCPUUsage() or 0.0
  FB.set("CPU", string.format("%.0f%%", load))
  r.defer(loop)
end
loop()