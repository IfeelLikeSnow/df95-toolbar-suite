
-- @description Humanize Preset Apply (by name)
-- @version 1.0
local r = reaper
local function read_json(p)
  local f=io.open(p,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
end
local res = r.GetResourcePath()
local prof = read_json(res.."/Data/DF95/Humanize_Profiles_v1.json") or {}
local _, name = r.GetProjExtState(0,"DF95_HUMANIZE","PRESET_NAME")
if name=="" then return end
local cfg = (prof.presets or {})[name]
if not cfg then return end
-- set as artist_profile temp and run apply
r.SetProjExtState(0,"DF95_HUMANIZE","ARTIST_PROFILE","")
r.SetProjExtState(0,"DF95_HUMANIZE","LEVEL","")
-- inject temp config through a temp file
local tmpcfg = res.."/Data/DF95/_Humanize_TMP.json"
local f=io.open(tmpcfg,"wb"); if f then
  f:write(reaper.JSON_Encode(cfg)); f:close()
  dofile((res.."/Scripts/IFLS/DF95/DF95_Humanize_Apply.lua"):gsub("\\","/"))
  os.remove(tmpcfg)
end
