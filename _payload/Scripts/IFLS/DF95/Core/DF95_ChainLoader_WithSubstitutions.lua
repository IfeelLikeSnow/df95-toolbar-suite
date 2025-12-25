
-- @description Chain Loader with Substitutions
-- @version 1.0
-- @param chain_path string Relative path from resource root (e.g., FXChains/DF95/Coloring/Warm/XYZ.rfxchain)
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function readjson(p)
  local f = io.open(p,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close()
  if r.JSON_Decode then return r.JSON_Decode(d) end
  return nil
end
local subs = readjson(res..sep.."Data"..sep.."DF95"..sep.."DF95_PluginSubstitutions.json") or {}
local function add_fx_by_alias(track, name)
  local idx = r.TrackFX_AddByName(track, name, false, 1) -- query
  if idx >= 0 then return idx end
  local key = name:gsub("^VST:%s*",""):gsub("^JS:%s*","")
  local list = subs[key] or {}
  for _, alt in ipairs(list) do
    local id2 = r.TrackFX_AddByName(track, alt, false, 1)
    if id2 >= 0 then return id2 end
  end
  return -1
end

local function load_chain(track, fullpath)
  local ok = r.TrackFX_AddByName(track, fullpath, 0, -1000)
  if ok >= 0 then return true end
  add_fx_by_alias(track, "VST: ReaEQ (Cockos)")
  add_fx_by_alias(track, "VST: ReaLimit (Cockos)")
  return false
end

return function(chain_path)
  local tr
  if r.CountSelectedTracks(0)==0 then
    r.Main_OnCommand(40296,0)
    tr = r.GetSelectedTrack(0,0)
  else
    tr = r.GetSelectedTrack(0,0)
  end
  if not tr then return end
  local full = res..sep..chain_path
  load_chain(tr, full)
end
