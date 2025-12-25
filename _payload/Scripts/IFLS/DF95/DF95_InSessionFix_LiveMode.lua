-- @description LiveMode – Latency-based Toggle (Bypass/Restore heavy FX)
-- @version 2.1
-- @author DF95
local r = reaper
local LAT_SAMPLES = math.max(512, math.floor((reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false) or 48000) * 0.025)) -- ~21ms @48k
local function toggle_heavy_by_latency(tr)
  local n = r.TrackFX_GetCount(tr)
  local toggled = 0
  for i=0, n-1 do
    local lat = r.TrackFX_GetLatency(tr, i)
    if lat > LAT_SAMPLES then
      local en = r.TrackFX_GetEnabled(tr, i)
      r.TrackFX_SetEnabled(tr, i, not en)
      toggled = toggled + 1
    end
  end
  return toggled
end
r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
local total=0
for i=0, sel-1 do total = total + toggle_heavy_by_latency(r.GetSelectedTrack(0,i)) end
r.Undo_EndBlock("DF95: LiveMode – Latency toggle ("..tostring(total).." slots)", -1)