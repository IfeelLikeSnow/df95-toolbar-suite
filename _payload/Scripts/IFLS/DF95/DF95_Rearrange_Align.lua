-- @description Rearrange – Align slices vertically
-- @version 1.44.0
local r=reaper
local function collect() local t={} for i=0,r.CountSelectedTracks(0)-1 do local tr=r.GetSelectedTrack(0,i); local items={} for k=0,r.CountTrackMediaItems(tr)-1 do local it=r.GetTrackMediaItem(tr,k); if r.IsMediaItemSelected(it) then items[#items+1]=it end end; table.sort(items,function(a,b) return r.GetMediaItemInfo_Value(a,"D_POSITION")<r.GetMediaItemInfo_Value(b,"D_POSITION") end); t[#t+1]={track=tr,items=items} end; return t end
local function align(b) if #b==0 or #b[1].items==0 then return end; local ref={} for i,it in ipairs(b[1].items) do ref[i]=r.GetMediaItemInfo_Value(it,"D_POSITION") end; for k=2,#b do for i,it in ipairs(b[k].items) do if ref[i] then r.SetMediaItemInfo_Value(it,"D_POSITION",ref[i]) end end end end
r.Undo_BeginBlock(); local b=collect(); align(b); r.UpdateArrange(); r.Undo_EndBlock("DF95 Rearrange align",-1)
