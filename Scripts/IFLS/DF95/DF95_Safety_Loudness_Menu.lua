-- @description Safety & Loudness (ReaLimit – Clean TP)
-- @version 1.44.0
local r=reaper
for i=0,r.CountSelectedTracks(0)-1 do local tr=r.GetSelectedTrack(0,i); for k=r.TrackFX_GetCount(tr)-1,0,-1 do r.TrackFX_Delete(tr,k) end; local names={"JS: Volume Adjustment","VST3: ReaLimit (Cockos)","JS: Loudness Meter Peak/RMS"} for _,n in ipairs(names) do r.TrackFX_AddByName(tr,n,false,-1) end end
