-- @description ChainHardener v3 – Export .RfxChain + DF95_META
-- @version 1.0
local r = reaper
local function chunk(tr) local ok,c=r.GetTrackStateChunk(tr,"",false); if not ok then return nil end; return c end
local function sanitize(s) return (s or "Track"):gsub('[\\/:*?"<>|]',"_") end
local function fxchunk(tr)
  local c = chunk(tr); if not c then return nil end
  local s=c:find("<FXCHAIN"); if not s then return nil end
  local e=c:find("\n>",s); if not e then e=#c end
  return c:sub(s,e+1)
end
local function export(tr, meta)
  local _,name = r.GetSetMediaTrackInfo_String(tr,"P_NAME","",false); name=sanitize(name~="" and name or "Track")
  local res=r.GetResourcePath().."/FXChains/DF95_Hardened"; reaper.RecursiveCreateDirectory(res,0)
  local path=res.."/"..name..".RfxChain"
  local f=io.open(path,"wb"); if not f then return end
  f:write("<!-- DF95_META "..meta.." -->\n"); f:write(fxchunk(tr) or ""); f:close()
  r.ShowConsoleMsg("[DF95] Hardened v3: "..path.."\n")
end
r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
for i=0,sel-1 do
  local tr = r.GetSelectedTrack(0,i)
  local _,k=r.GetProjExtState(0,"DF95_MICFX","PROFILE_KEY")
  local _,m=r.GetProjExtState(0,"DF95_MICFX","PROFILE_MODE")
  local _,a=r.GetProjExtState(0,"DF95_SMARTCEILING","Artist")
  local _,n=r.GetProjExtState(0,"DF95_SMARTCEILING","Neutral")
  local _,f=r.GetProjExtState(0,"DF95_SMARTCEILING","FXBus")
  local _,d=r.GetProjExtState(0,"DF95_SMARTCEILING","Deep")
  local meta=string.format("{\"MIC\":%q,\"MODE\":%q,\"CEIL\":{\"Artist\":%q,\"Neutral\":%q,\"FXBus\":%q,\"Deep\":%q}}",k or "",m or "",a or "",n or "",f or "",d or "")
  export(tr, meta)
end
r.Undo_EndBlock("DF95 ChainHardener v3", -1)
