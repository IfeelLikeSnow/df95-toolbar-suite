-- @description MicFX ParamApply v3.5 (Fallback Drive & Comp Bias)
-- @version 1.0
local r = reaper
local function find_fx(tr)
  local n=r.TrackFX_GetCount(tr); local fx={eq=-1,comp=-1,flavor=-1}
  for i=0,n-1 do
    local _,nm=r.TrackFX_GetFXName(tr,i,""); local l=(nm or ""):lower()
    if l:find("reaeq") then fx.eq=i end
    if l:find("reacomp") then fx.comp=i end
    if l:find("purestdrive") or l:find("britpre") or l:find("burier") or l:find("totape") or l:find("channel8") then fx.flavor=i end
  end
  return fx
end
local function apply(tr)
  local fx=find_fx(tr)
  -- conservative fallback levels
  local peak_db = -18
  -- drive scale
  local scale = (peak_db<=-24) and 1.9 or (peak_db<=-14) and 1.25 or 0.85
  if fx.flavor>=0 then
    local pc=r.TrackFX_GetNumParams(tr,fx.flavor)
    for p=0,pc-1 do
      local _,pn=r.TrackFX_GetParamName(tr,fx.flavor,p,""); pn=(pn or ""):lower()
      if pn:find("drive") or pn:find("amount") then
        local _,cur=r.TrackFX_GetParam(tr,fx.flavor,p)
        r.TrackFX_SetParam(tr,fx.flavor,p, math.max(0, math.min(1, cur*scale)))
      end
    end
  end
  if fx.comp>=0 then
    r.TrackFX_SetNamedConfigParm(tr,fx.comp,"ATTACK","10")
    r.TrackFX_SetNamedConfigParm(tr,fx.comp,"RELEASE","150")
  end
end
r.Undo_BeginBlock(); local sel=r.CountSelectedTracks(0); for i=0,sel-1 do apply(r.GetSelectedTrack(0,i)) end; r.Undo_EndBlock("DF95 v3.5 Apply", -1)
