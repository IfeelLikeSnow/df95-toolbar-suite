-- @description LUFS AutoTarget (calls Autopilot)
-- @version 1.1
-- @about Delegiert an DF95_GainMatch_LUFS_Autopilot (inkl. Target-Dialog).

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local path = (res
  .. sep .. "Scripts"
  .. sep .. "IfeelLikeSnow"
  .. sep .. "DF95"
  .. sep .. "DF95_GainMatch_LUFS_Autopilot.lua"):gsub("\\","/")

dofile(path)