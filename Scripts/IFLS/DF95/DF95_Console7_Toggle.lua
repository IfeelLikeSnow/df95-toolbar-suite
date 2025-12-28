-- @description Console7 Toggle (AW Channel/Buss)
-- @version 1.0
local r = reaper
local function toggle(tr)
  local n=r.TrackFX_GetCount(tr)
  for i=0,n-1 do
    local _,nm=r.TrackFX_GetFXName(tr,i,""); local l=(nm or ""):lower()
    if l:find("console7") or l:find("channel7") then
      local en = r.TrackFX_GetEnabled(tr, i)
      r.TrackFX_SetEnabled(tr, i, not en)
    end
  end
end
local sel=r.CountSelectedTracks(0); for i=0,sel-1 do toggle(r.GetSelectedTrack(0,i)) end
