-- @description FXChain Loader (stock-safe parser)
-- @version 1.1
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function readall(fp)
  local f = io.open(fp,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

local function parse_fx_names(txt)
  local t = {}
  for line in txt:gmatch("[^\r\n]+") do
    local v = line:match('^%s*<VST3%s+"([^"]+)"') or line:match('^%s*<VST%s+"([^"]+)"') or line:match('^%s*<JS:%s*([^>]+)')
    if v then t[#t+1]=v end
  end
  return t
end

local function ensure_track()
  if r.CountSelectedTracks(0)==0 then r.Main_OnCommand(40296,0) end
  return r.GetSelectedTrack(0,0)
end

local function clear_fx(tr) for i=r.TrackFX_GetCount(tr)-1,0,-1 do r.TrackFX_Delete(tr,i) end end

local function add_fx(tr, name)
  local idx = r.TrackFX_AddByName(tr, name, false, 1)
  if idx==-1 then
    local short = name:match("VST3:%s*([^%(]+)") or name:match("VST:%s*([^%(]+)")
    if short then idx = r.TrackFX_AddByName(tr, short:gsub("%s+$",""), false, 1) end
  end
  return idx
end

function DF95_LoadRFXChain(fp, replace)
  local txt = readall(fp); if not txt then return false end
  local tr = ensure_track(); if replace then clear_fx(tr) end
  local names = parse_fx_names(txt); local missing={}
  for _,nm in ipairs(names) do
    local idx = add_fx(tr, nm); if idx<0 then missing[#missing+1]=nm end
  end
  if #missing>0 then reaper.ShowConsoleMsg("[DF95] Missing FX:\n - "..table.concat(missing,"\n - ").."\n") end
  return true
end

return DF95_LoadRFXChain
