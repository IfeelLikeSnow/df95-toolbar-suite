
-- @description Toggle Zero-Cross Respect (Slicing)
-- @version 1.0
local r = reaper
local _, v = r.GetProjExtState(0, "DF95_SLICING", "ZC_RESPECT")
local new = (v == "1") and "0" or "1"
r.SetProjExtState(0, "DF95_SLICING", "ZC_RESPECT", new)
r.ShowConsoleMsg(string.format("[DF95] Zero-Cross Respect: %s\n", (new=="1") and "ON" or "OFF"))
