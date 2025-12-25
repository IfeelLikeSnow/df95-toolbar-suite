-- @description LoopBuilder – Build rhythm track from selected slices
-- @version 1.44.0
local r=reaper; if r.CountSelectedMediaItems(0)==0 then return end; r.Undo_BeginBlock(); r.InsertTrackAtIndex(r.CountTracks(0), true); local dst=r.GetTrack(0,r.CountTracks(0)-1); r.GetSetMediaTrackInfo_String(dst,"P_NAME","DF95 Loop",true); r.Main_OnCommand(40698,0); r.SetOnlyTrackSelected(dst); r.Main_OnCommand(40058,0); r.Undo_EndBlock("DF95 LoopBuilder",-1)
