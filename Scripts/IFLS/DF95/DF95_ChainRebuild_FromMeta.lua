-- @description ChainRebuild – restore MIC/MODE/CEIL from DF95_META
-- @version 1.0
local r = reaper
local retval, path = r.GetUserFileNameForRead("", "Pick DF95 hardened .RfxChain", ".RfxChain")
if not retval then return end
local f=io.open(path,"rb"); if not f then return end
local head=f:read(4096) or ""; f:close()
local meta = head:match("DF95_META%s+(%b{})"); if not meta then return end
if not reaper.JSON_Decode then return end
local t = reaper.JSON_Decode(meta)
if t and t.MIC then
  r.SetProjExtState(0,"DF95_MICFX","PROFILE_KEY", t.MIC or "")
  r.SetProjExtState(0,"DF95_MICFX","PROFILE_MODE", t.MODE or "")
end
if t and t.CEIL then
  for k,v in pairs(t.CEIL) do r.SetProjExtState(0,"DF95_SMARTCEILING", tostring(k), tostring(v)) end
end
r.ShowConsoleMsg("[DF95] ChainRebuild: MIC/MODE/CEIL restored from meta.\n")
