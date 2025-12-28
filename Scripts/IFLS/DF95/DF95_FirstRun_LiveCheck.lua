if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description First‑Run LiveCheck (Auto‑Setup + Test + GainMatch)
-- @version 1.46c
-- @author IfeelLikeSnow
-- @about Erzeugt FX/Coloring/Master‑Bus, lädt eine Test‑Coloring‑Chain und führt GainMatch (Learn) aus. Optionaler A/B‑Vergleich.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep
local COLOR_NAME = "DF95 Coloring Master"
local MASTER_NAME = "DF95 Master Bus"
local FXBUS_NAME = "DF95 FX Bus"

local TEST_CHAIN = "Airwindows/CPU-Light/AW_CPU_PurestDrive_Light" -- relative to FXChains_Coloring

-- helpers
local function ensure_track_named(name)
  for i=0,r.CountTracks(0)-1 do
    local tr = r.GetTrack(0,i)
    local _, n = r.GetSetMediaTrackInfo_String(tr,"P_NAME","",false)
    if n == name then return tr end
  end
  r.InsertTrackAtIndex(r.CountTracks(0), true)
  local tr = r.GetTrack(0, r.CountTracks(0)-1)
  r.GetSetMediaTrackInfo_String(tr,"P_NAME",name,true)
  return tr
end

local function route_parent(child,parent)
  r.SetMediaTrackInfo_Value(child,"B_MAINSEND",0)
  local s = r.CreateTrackSend(child,parent)
  r.SetTrackSendInfo_Value(child,0,s,"I_SENDMODE",0)
end

local function clear_fx(tr)
  for i=r.TrackFX_GetCount(tr)-1,0,-1 do r.TrackFX_Delete(tr,i) end
end

local function add_chain_from_fxlist(tr, rel)
  local p = base .. "FXChains_Coloring" .. sep .. rel .. ".fxlist"
  local f = io.open(p,"r"); if not f then return false, "fxlist nicht gefunden: "..p end
  for line in f:lines() do
    local name = line:match("^%s*(.-)%s*$")
    if name ~= "" then r.TrackFX_AddByName(tr, name, false, -1) end
  end
  f:close(); return true
end

local function ensure_buses_and_routing()
  local fx = ensure_track_named(FXBUS_NAME)
  local color = ensure_track_named(COLOR_NAME)
  local master = ensure_track_named(MASTER_NAME)
  route_parent(fx, color)
  route_parent(color, master)
  r.SetMediaTrackInfo_Value(master,"B_MAINSEND",1)
  return fx, color, master
end

-- GainMatch (simplified, peak-average)
local function track_avg_peak(tr, frames, wait_ms)
  local sum, cnt = 0.0, 0
  local function step()
    local p = r.Track_GetPeakInfo(tr, 0) or 0.0
    if p > 0 then sum = sum + p; cnt = cnt + 1 end
    if cnt < frames then r.defer(step) end
  end
  step()
  local t0 = r.time_precise()
  local dur = frames * (wait_ms/1000.0) + 0.05
  while r.time_precise() - t0 < dur do end
  return (cnt > 0) and (sum / cnt) or 0.0
end

local function set_track_fader_delta_db(tr, delta_db)
  local vol = r.GetMediaTrackInfo_Value(tr,"D_VOL")
  local vol_db = (vol > 0) and (20 * math.log(vol,10)) or -120.0
  local new_db = vol_db + delta_db
  local new_vol = 10^(new_db/20)
  r.SetMediaTrackInfo_Value(tr,"D_VOL", new_vol)
end

local function bypass_all_fx(tr, bypass)
  for i=0,r.TrackFX_GetCount(tr)-1 do r.TrackFX_SetEnabled(tr, i, not bypass) end
end

local function gainmatch_learn(tr)
  -- PRE (bypass)
  bypass_all_fx(tr, true)
  local pre = track_avg_peak(tr, 20, 15)  -- ~300 ms
  -- POST (enable)
  bypass_all_fx(tr, false)
  local post = track_avg_peak(tr, 20, 15)
  if pre > 0 and post > 0 then
    local delta_db = 20 * math.log(post / pre, 10)
    set_track_fader_delta_db(tr, -delta_db)
    return true, delta_db
  end
  return false, 0
end

-- RUN
r.Undo_BeginBlock()
local fx, color, master = ensure_buses_and_routing()

-- Load test chain on Coloring
clear_fx(color)
local ok, err = add_chain_from_fxlist(color, TEST_CHAIN)
if not ok then r.ShowMessageBox(err, "DF95 LiveCheck", 0); r.Undo_EndBlock("DF95 LiveCheck – Fehler", -1); return end

-- GainMatch pass (Coloring and Master)
local msg = {}
local okc, dBc = gainmatch_learn(color)
msg[#msg+1] = "Coloring: GainMatch "..(okc and "OK" or "skip")
local okm, dBm = gainmatch_learn(master)
msg[#msg+1] = "Master: GainMatch "..(okm and "OK" or "skip")

r.Undo_EndBlock("DF95 LiveCheck – Setup+Test", -1)

-- A/B short dialog
gfx.init("DF95 LiveCheck", 400, 80); gfx.x, gfx.y = 100, 100
gfx.printf("DF95 LiveCheck abgeschlossen.\n%s\n\nA/B? 1=Bypass Coloring+Master, 2=Enable All, Esc=Ende", table.concat(msg," | "))
local ch = gfx.getchar()
if ch == string.byte('1') then
  bypass_all_fx(color, true); bypass_all_fx(master, true)
elseif ch == string.byte('2') then
  bypass_all_fx(color, false); bypass_all_fx(master, false)
end
gfx.quit()
