-- @description SmartCeiling – Toggle True-Peak Hard Safety
-- @version 1.0
-- @author DF95
local r = reaper
local state = r.GetExtState("DF95_FLOW","TP_HARD")
local v = (state=="1") and "0" or "1"
r.SetExtState("DF95_FLOW","TP_HARD", v, false)
r.ShowMessageBox("TP Hard Safety: "..((v=="1") and "ENABLED (−0.3 dB Nudge enforced)" or "DISABLED"), "DF95", 0)