-- @description Micro Gain Match ±0.5 dB (Track trim)
-- @version 0.0.0
local r=reaper; local tr=r.GetSelectedTrack(0,0); if not tr then return end
local vol = ({r.GetMediaTrackInfo_Value(tr,"D_VOL")})[2]
local step = 10^(0.5/20) -- +0.5 dB
-- toggle up/down each call (simple helper)
local t=r.GetExtState("DF95","MGM_DIR"); if t=="" then t="up" end
if t=="up" then vol=vol*step; r.SetExtState("DF95","MGM_DIR","down",false) else vol=vol/step; r.SetExtState("DF95","MGM_DIR","up",false) end
r.SetMediaTrackInfo_Value(tr,"D_VOL",vol)
