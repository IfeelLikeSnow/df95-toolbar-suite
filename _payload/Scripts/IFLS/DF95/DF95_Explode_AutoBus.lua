-- @description Explode – Auto-create Tracks (FX → Coloring → Master) + Routing
-- @version 1.44.0
local r = reaper
local function ensure_track_named(name)
  for i=0,r.CountTracks(0)-1 do local tr=r.GetTrack(0,i); local _,n=r.GetSetMediaTrackInfo_String(tr,"P_NAME","",false); if n==name then return tr end end
  r.InsertTrackAtIndex(r.CountTracks(0), true); local tr=r.GetTrack(0,r.CountTracks(0)-1); r.GetSetMediaTrackInfo_String(tr,"P_NAME",name,true); return tr
end
local function route_parent(child,parent) r.SetMediaTrackInfo_Value(child,"B_MAINSEND",0); local s=r.CreateTrackSend(child,parent); r.SetTrackSendInfo_Value(child,0,s,"I_SENDMODE",0) end
r.Undo_BeginBlock()
local fx=ensure_track_named("DF95 FX Bus")
local color=ensure_track_named("DF95 Coloring Master")
local master=ensure_track_named("DF95 Master Bus")
route_parent(fx,color); route_parent(color,master); r.SetMediaTrackInfo_Value(master,"B_MAINSEND",1)
r.Undo_EndBlock("DF95: Explode + Auto Buses + Routing",-1)
