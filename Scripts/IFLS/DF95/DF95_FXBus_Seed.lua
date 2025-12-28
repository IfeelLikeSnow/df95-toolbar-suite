if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description FX Bus – Seed (generative randomizer)
-- @version 1.1
local r = reaper; math.randomseed(os.time())
local FXBUS_NAME="DF95 FX Bus"; local SMALL=0.15; local MIX_MIN, MIX_MAX = 0.2, 0.8
local PREF={"argotlunar","fracture","hysteresis","shaperbox","magic dice","supermassive","spaced out","decimort","krush","smooth operator","pitch drift"}
local SKIP={"bypass","output","out","ceiling","makeup","gain","volume","limiter","threshold"}
local function tl(s) return (s or ""):lower() end
local function preferred(n) n=tl(n); for _,k in ipairs(PREF) do if n:find(k,1,true) then return true end end return false end
local function looks_mix(n) n=tl(n); return n:find("mix") or n:find("wet") end
local function skippable(n) n=tl(n); for _,k in ipairs(SKIP) do if n:find(k,1,true) then return true end end return false end
local function get_fxbus() for i=0,reaper.CountTracks(0)-1 do local tr=reaper.GetTrack(0,i); local _,n=reaper.GetSetMediaTrackInfo_String(tr,"P_NAME","",false); if n==FXBUS_NAME then return tr end end end
local function rb(a,b) return a+(b-a)*math.random() end
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end
local function mutate(tr,fx,p,full) local _,pn=reaper.TrackFX_GetParamName(tr,fx,p,""); local v0,vmin,vmax=reaper.TrackFX_GetParam(tr,fx,p); if skippable(pn) then return false end
  local v=v0; if looks_mix(pn) then v=rb(MIX_MIN,MIX_MAX) else if full then v=rb(vmin,vmax) else local span=(vmax-vmin)*SMALL; v=clamp(v0+rb(-span,span),vmin,vmax) end end
  reaper.TrackFX_SetParam(tr,fx,p,v); return true end
local function run(full) local tr=get_fxbus(); if not tr then reaper.ShowMessageBox("Kein 'DF95 FX Bus' gefunden.","DF95 FX Seed",0) return end
  reaper.Undo_BeginBlock(); local cnt=0
  for fx=0,reaper.TrackFX_GetCount(tr)-1 do local _,name=reaper.TrackFX_GetFXName(tr,fx,""); local pref=preferred(name)
    for p=0,reaper.TrackFX_GetNumParams(tr,fx)-1 do local _,pn=reaper.TrackFX_GetParamName(tr,fx,p,"")
      if pref then if mutate(tr,fx,p,full) then cnt=cnt+1 end else if looks_mix(pn) then if mutate(tr,fx,p,full) then cnt=cnt+1 end end
    end end
  end
  reaper.Undo_EndBlock("DF95 FX Seed ("..(full and "Full" or "Small")..")",-1); reaper.UpdateArrange(); reaper.ShowMessageBox("Seed OK. Params: "..cnt,"DF95 FX Seed",0)
end
local function menu() local t={"||DF95 FX Seed:","🎲 Randomize (Full)","🌱 Small Variations"} return table.concat(t,"|") end
gfx.init("DF95 – FX Seed",0,0); gfx.x,gfx.y=gfx.mouse_x,gfx.mouse_y; local idx=gfx.showmenu(menu()); gfx.quit(); if idx<=0 then return end; run(idx==2)

-- NOTE: Seed persistence via ExtState('DF95_SEED', projectGUID)
