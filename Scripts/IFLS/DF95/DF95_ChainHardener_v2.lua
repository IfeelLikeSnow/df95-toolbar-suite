-- @description ChainHardener v2 (.RfxChain + DF95_META)
-- @version 1.0
local r = reaper
local function state_chunk(tr) local ok,c=r.GetTrackStateChunk(tr,"",false); if not ok then return nil end; return c end
local function sanitize(s) return (s or "Track"):gsub('[\\/:*?"<>|]',"_") end
local function fxchunk(tr)
  local c=state_chunk(tr); if not c then return nil end
  local s=c:find("<FXCHAIN"); if not s then return nil end
  local e=c:find("\n>",s); if not e then e=#c end
  return c:sub(s,e+1)
end
local function export(tr, meta)
  local _,nm=r.GetSetMediaTrackInfo_String(tr,"P_NAME","",false); nm=sanitize(nm~="" and nm or "Track")
  local dir=r.GetResourcePath().."/FXChains/DF95_Hardened"; r.RecursiveCreateDirectory(dir,0)
  local f=io.open(dir.."/"..nm..".RfxChain","wb"); if not f then return end
  f:write("<!-- DF95_META "..meta.." -->\n"); f:write(fxchunk(tr) or ""); f:close()
end
r.Undo_BeginBlock()
local sel=r.CountSelectedTracks(0)
for i=0,sel-1 do
  local tr=r.GetSelectedTrack(0,i)
  local _,k=r.GetProjExtState(0,"DF95_MICFX","PROFILE_KEY")
  local _,m=r.GetProjExtState(0,"DF95_MICFX","PROFILE_MODE")
  local _,a=r.GetProjExtState(0,"DF95_SMARTCEILING","Artist")
  local _,n=r.GetProjExtState(0,"DF95_SMARTCEILING","Neutral")
  local _,f=r.GetProjExtState(0,"DF95_SMARTCEILING","FXBus")
  local _,d=r.GetProjExtState(0,"DF95_SMARTCEILING","Deep")
  local meta=string.format("{\"MIC\":%q,\"MODE\":%q,\"CEIL\":{\"Artist\":%q,\"Neutral\":%q,\"FXBus\":%q,\"Deep\":%q}}",k or "",m or "",a or "",n or "",f or "",d or "")
  export(tr, meta)
end
r.Undo_EndBlock("DF95 ChainHardener v2", -1)
