-- @description GainMatch (LUFS) – Auto-Learn
-- @version 1.1
-- @author DF95
-- @about Measures LUFS over a short window and applies gain to reach a target. Publishes status via FlowBus.
-- Notes: Works best with dpMeter5/Youlean present; will fallback to JS RM/Peak meter estimate if needed.

local r = reaper
local sep = package.config:sub(1,1)
local base = (debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")") or ""
local FB = dofile(base.."DF95_FlowBus.lua")

-- True Peak estimate helper (best effort): reads master peak in dBFS
local function get_true_peak_dbfs(mst)
  -- Fallback: use Track_GetPeakInfo style approximation via envelope or peak sample (API-limited here).
  -- We approximate using master peak sample value from GetTrackUIPeakMeter
  local ch0 = reaper.Track_GetPeakInfo and reaper.Track_GetPeakInfo(mst, 0) or 0.0
  local ch1 = reaper.Track_GetPeakInfo and reaper.Track_GetPeakInfo(mst, 1) or ch0
  local peak = math.max(ch0 or 0.0, ch1 or 0.0)
  if peak <= 0 then return -120.0 end
  return 20*math.log(peak,10)
end

local meters = {
  {name="VST3: dpMeter5 (TBProAudio)", needle={"integrated","int"}},
  {name="VST3: Youlean Loudness Meter 2 (Youlean)", needle={"integrated"}},
  {name="JS: loudness_meter_peak_rms", needle={"rms"}}
}

local function find_or_insert_meter(mst)
  -- prefer existing meter if present
  for i=0, r.TrackFX_GetCount(mst)-1 do
    local _, nm = r.TrackFX_GetFXName(mst, i, "")
    local l = (nm or ""):lower()
    for _,m in ipairs(meters) do
      if l:find((m.name:lower():gsub("^vst3:%s*",""):gsub("^vst:%s*",""))) then return i, m end
    end
  end
  -- insert first workable
  for _,m in ipairs(meters) do
    local fx = r.TrackFX_AddByName(mst, m.name, false, -1000)
    if fx >= 0 then return fx, m end
  end
  return -1, nil
end

local function read_val(mst, fx, needles)
  local pc = r.TrackFX_GetNumParams(mst, fx)
  for _,needle in ipairs(needles) do
    for p=0, pc-1 do
      local _, pn = r.TrackFX_GetParamName(mst, fx, p, "")
      if (pn or ""):lower():find(needle) then
        local fmt = select(2, r.TrackFX_GetFormattedParamValue(mst, fx, p, ""))
        local num = tonumber((fmt or ""):match("[-%d%.]+"))
        if num then return num end
      end
    end
  end
  return nil
end

local function ensure_post_gain(tr)
  -- try to find existing JS: Volume
  for i=0, r.TrackFX_GetCount(tr)-1 do
    local _, nm = r.TrackFX_GetFXName(tr, i, "")
    if (nm or ""):lower():find("js: volume") then return i end
  end
  local fx = r.TrackFX_AddByName(tr, "JS: Volume adjustment", false, -1000)
  return fx
end

local function set_gain_db(tr, fx, delta_db)
  local min_db, max_db = -90.0, 12.0
  if delta_db > 6.0 then delta_db = 6.0 elseif delta_db < -6.0 then delta_db = -6.0 end
  local norm = (delta_db - min_db) / (max_db - min_db)
  if norm < 0 then norm = 0 elseif norm > 1 then norm = 1 end
  r.TrackFX_SetParamNormalized(tr, fx, 0, norm)
end

-- dialog
local ok, s = r.GetUserInputs("DF95 LUFS Auto-Learn", 2, "Target LUFS-I,Window (2..20 s)", "-12.0,8.0")
if not ok then return end
local target, win = s:match("([^,]+),([^,]+)")
local TARGET = tonumber(target or "-12") or -12.0
local WINDOW = tonumber(win or "5") or 5.0
if WINDOW < 2.0 then WINDOW = 2.0 elseif WINDOW > 20.0 then WINDOW = 20.0 end

local mst = r.GetMasterTrack(0)
local fx, meta = find_or_insert_meter(mst)
if fx < 0 then r.ShowMessageBox("Kein kompatibler LUFS/RMS-Meter gefunden.", "DF95", 0) return end

FB.set("GainMatch","AutoLearn")
FB.set("LUFS_Target", TARGET)

-- measurement loop
local t0 = r.time_precise()
local acc, n = 0.0, 0
while (r.time_precise() - t0) < WINDOW do
  r.UpdateArrange()
  local cur = read_val(mst, fx, meta.needle) or -12.0
  acc = acc + cur; n = n + 1
  FB.set("LUFS_Current", string.format("%.1f", cur))
  r.defer(function() end)
end

local avg = acc / math.max(1, n)
local delta = TARGET - avg

-- apply to master (or selected tracks if any selected)
r.Undo_BeginBlock()
local count = r.CountSelectedTracks(0)
if count == 0 then
  local g = ensure_post_gain(mst)
  set_gain_db(mst, g, delta)
else
  for i=0, count-1 do
    local tr = r.GetSelectedTrack(0,i)
    local g = ensure_post_gain(tr)
    set_gain_db(tr, g, delta)
  end
end
FB.set("GainMatch","ON")
FB.set("LUFS_Delta", string.format("%+.1f dB", delta))
local tp = get_true_peak_dbfs(mst)
local tpStat = (tp <= -0.3) and "OK" or string.format("WARN (%.1f dBFS)", tp)
FB.set("TP_Status", tpStat)
if tp > -0.3 then r.ShowMessageBox("True Peak über -0.3 dBFS nach GainMatch: "..string.format("%.1f dBFS", tp),"DF95 TP Warning",0) end
r.Undo_EndBlock(string.format("DF95 LUFS Auto-Learn: avg %.1f → target %.1f (Δ %+.1f dB)", avg, TARGET, delta), -1)