if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description GainMatch A/B (Coloring & Master Buses)
-- @version 1.46.1
-- @author IfeelLikeSnow
-- @about Misst kurz den Ausgangspegel (Playback!), vergleicht Pre/Post und gleicht per Trackfader an.

local r = reaper
local TARGETS = {"DF95 Coloring Master","DF95 Master Bus"}

local function find_tracks(names)
  local t = {}
  for i=0,r.CountTracks(0)-1 do
    local tr = r.GetTrack(0,i)
    local _, n = r.GetSetMediaTrackInfo_String(tr,"P_NAME","",false)
    for _, want in ipairs(names) do
      if n == want then t[#t+1] = tr end
    end
  end
  return t
end

local function get_peak(track)
  -- instantaneous peak (mono-sum); best effort while playing
  return r.Track_GetPeakInfo(track, 0)
end

local function avg_peak(tr, frames, delay_ms)
  local sum = 0.0
  local count = 0
  local function step()
    local p = get_peak(tr) or 0.0
    if p > 0 then sum = sum + p; count = count + 1 end
    if count < frames then r.defer(step) else
      r.SetExtState("DF95_GM","AVG", tostring(sum / math.max(1,count)), false)
    end
  end
  step()
  -- crude wait
  local t0 = r.time_precise()
  while r.time_precise() - t0 < (frames * (delay_ms/1000.0) + 0.05) do end
  local v = tonumber(r.GetExtState("DF95_GM","AVG")) or 0.0
  r.DeleteExtState("DF95_GM","AVG", false)
  return v
end

local function set_track_gain_delta(tr, delta_db)
  local vol = r.GetMediaTrackInfo_Value(tr,"D_VOL")
  local vol_db = 20*math.log(vol,10)
  local new_db = vol_db + delta_db
  local new_vol = 10^(new_db/20)
  r.SetMediaTrackInfo_Value(tr,"D_VOL", new_vol)
end

local function bypass_all_fx(tr, bypass)
  for i=0,r.TrackFX_GetCount(tr)-1 do
    r.TrackFX_SetEnabled(tr, i, not bypass)
  end
end

local function run()
  local trks = find_tracks(TARGETS)
  if #trks == 0 then
    r.ShowMessageBox("Keine DF95 Buses gefunden (Coloring/Master).","DF95 GainMatch",0)
    return
  end
  local menu = "||DF95 GainMatch A/B:|Learn & Match (Playback!)|Toggle A/B"
  gfx.init("DF95 GainMatch",0,0); gfx.x,gfx.y=gfx.mouse_x,gfx.mouse_y
  local idx = gfx.showmenu(menu); gfx.quit(); if idx<=0 then return end

  if idx == 2 then
    -- Learn & Match
    r.Undo_BeginBlock()
    for _, tr in ipairs(trks) do
      -- PRE: bypass FX, sample
      bypass_all_fx(tr, true)
      local pre = avg_peak(tr, 20, 15) -- ~300ms
      -- POST: enable FX, sample
      bypass_all_fx(tr, false)
      local post = avg_peak(tr, 20, 15)
      if pre > 0 and post > 0 then
        local delta = 20*math.log(post/pre,10) -- dB difference
        set_track_gain_delta(tr, -delta)
      end
    end
    r.Undo_EndBlock("DF95 GainMatch – Learn & Match",-1)
  elseif idx == 3 then
    -- Toggle A/B (bypass FX vs enabled)
    r.Undo_BeginBlock()
    for _, tr in ipairs(trks) do
      local any_on = false
      for i=0,r.TrackFX_GetCount(tr)-1 do
        local en = r.TrackFX_GetEnabled(tr, i)
        if en then any_on = true break end
      end
      bypass_all_fx(tr, any_on) -- if any on -> bypass all, else enable all
    end
    r.Undo_EndBlock("DF95 GainMatch – Toggle A/B",-1)
  end
end

run()
