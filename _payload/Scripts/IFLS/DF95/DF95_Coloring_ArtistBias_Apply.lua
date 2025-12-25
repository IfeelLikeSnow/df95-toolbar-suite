
-- @description Coloring Artist Bias – Apply to selected bus
-- @version 1.0
local r = reaper
local function read_json(path)
  local f=io.open(path,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
  return nil
end
local cfg = read_json(reaper.GetResourcePath().."/Data/DF95/Coloring_ArtistBias_v1.json") or {}
local _, artist = r.GetProjExtState(0,"DF95_COLORING","ARTIST")
if artist == "" then
  local keys = {}; for k,_ in pairs(cfg) do keys[#keys+1]=k end
  table.sort(keys)
  local list = table.concat(keys, "|")
  local ok, idx = r.GetUserInputs("DF95 Artist Bias", 1, "Artist ("..list..")", "")
  if not ok then return end
  artist = idx
  r.SetProjExtState(0,"DF95_COLORING","ARTIST", artist)
end

local p = cfg[artist]
if not p then r.ShowMessageBox("Artist '"..artist.."' nicht in Bias-Config.","DF95",0) return end

local tr = r.GetSelectedTrack(0,0)
if not tr then r.ShowMessageBox("Bitte Bus-Track auswählen.","DF95",0) return end

-- find ReaEQ
local function find_fx(tr, name)
  local n = r.TrackFX_GetCount(tr)
  for i=0,n-1 do
    local _,nm=r.TrackFX_GetFXName(tr,i,"")
    if nm:lower():find(name) then return i end
  end
  return -1
end

local eq = find_fx(tr, "reaeq")
if eq<0 then
  eq = r.TrackFX_AddByName(tr, "ReaEQ (Cockos)", false, 1)
end
-- simple tilt via two shelves (low and high)
local function set_shelf(fx, band, freq, gain, q, typ)
  r.TrackFX_SetParam(tr, fx, 0, 1) -- ensure band count >=1 (ReaEQ auto-manages)
  r.TrackFX_SetNamedConfigParm(tr, fx, "BANDTYPE"..band, tostring(typ or 5)) -- HS=5, LS=3
  r.TrackFX_SetNamedConfigParm(tr, fx, "BANDENABLED"..band, "1")
  r.TrackFX_SetNamedConfigParm(tr, fx, "BANDGAIN"..band, tostring(gain))
  r.TrackFX_SetNamedConfigParm(tr, fx, "BANDWIDTH"..band, tostring(q or 0.7))
  r.TrackFX_SetNamedConfigParm(tr, fx, "BANDFREQ"..band, tostring(freq))
end

-- Apply low shelf
set_shelf(eq, 0, 120, p.low_shelf_db or 0.0, 0.7, 3)
-- Apply high shelf (tilt approximation)
set_shelf(eq, 1, 8000, (p.tilt_db_per_oct or 0.0)*1.5, 0.7, 5)

-- Gentle drive push on AW/AO if present
local function drive_push(fxidx, amt)
  local np = r.TrackFX_GetNumParams(tr, fxidx)
  for i=0, np-1 do
    local _, pn = r.TrackFX_GetParamName(tr, fxidx, i, "")
    pn = (pn or ""):lower()
    if pn:find("drive") or pn:find("amount") or pn:find("mojo") then
      local _, v = r.TrackFX_GetParam(tr, fxidx, i)
      r.TrackFX_SetParam(tr, fxidx, i, math.min(1.0, v + amt))
    end
  end
end

local n = r.TrackFX_GetCount(tr)
for i=0,n-1 do
  local _, nm = r.TrackFX_GetFXName(tr, i, "")
  local l = (nm or ""):lower()
  if l:find("airwindows") or l:find("analog obsession") or l:find("analogobsession") then
    drive_push(i, (p.drive_push or 0.04))
  end
end

r.ShowConsoleMsg(string.format("[DF95] ArtistBias applied: %s\n", artist))
