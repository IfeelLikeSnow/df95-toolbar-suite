-- @description GainMatch v2 (LUFS-linked simple)
-- @version 1.0
local r = reaper
local function get(ns,k, d) local _,v=r.GetProjExtState(0,ns,k); v=tonumber(v or "") or d; return v end
local lA,lB = get("DF95_MEASURE","LUFS_A",-14), get("DF95_MEASURE","LUFS_B",-12)
local rA,rB = get("DF95_MEASURE","RMS_A",-18),  get("DF95_MEASURE","RMS_B",-17)
local delta = (lA-lB)*0.8 + (rA-rB)*0.2
local sel = r.CountSelectedTracks(0)
for i=0, sel-1 do
  local tr=r.GetSelectedTrack(0,i)
  local vol=r.GetMediaTrackInfo_Value(tr,"D_VOL")
  r.SetMediaTrackInfo_Value(tr,"D_VOL", vol*10^(delta/20))
end
r.ShowConsoleMsg(string.format("[DF95] GainMatch v2 Δ=%.2f dB\n", delta))
