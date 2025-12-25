-- @description GainMatch (LUFS) – Autopilot (best-effort)
-- @version 1.0
-- @author DF95
-- @about Tries to read LUFS from known meters (dpMeter5, Youlean) on Master; else falls back to RMS-based estimate.
local r = reaper

local meters = {
  {name="VST3: dpMeter5 (TBProAudio)", param_contains="integrated"},
  {name="VST3: Youlean Loudness Meter 2 (Youlean)", param_contains="integrated"},
  {name="JS: loudness_meter_peak_rms", param_contains="rms"} -- fallback
}

local function find_or_insert_meter(mst)
  for i=0, r.TrackFX_GetCount(mst)-1 do
    local _, nm = r.TrackFX_GetFXName(mst, i, "")
    local l = (nm or ""):lower()
    for _,m in ipairs(meters) do if l:find(m.name:split(':')[2]:lower():gsub("^%s*","")) then return i, m end end
  end
  -- insert first available
  for _,m in ipairs(meters) do
    local fx = r.TrackFX_AddByName(mst, m.name, false, -1000)
    if fx >= 0 then return fx, m end
  end
  return -1, nil
end

local function read_lufs(mst, fx, needle)
  local pc = r.TrackFX_GetNumParams(mst, fx)
  for p=0, pc-1 do
    local _, pn = r.TrackFX_GetParamName(mst, fx, p, "")
    if (pn or ""):lower():find(needle) then
      local v = select(2, r.TrackFX_GetFormattedParamValue(mst, fx, p, "")) -- formatted string; may include "dB"
      local num = tonumber((v or ""):match("[-%d%.]+"))
      return num
    end
  end
  return nil
end

local function set_post_gain(tr, delta_db)
  -- simple implementation like manual
  local cnt = r.TrackFX_GetCount(tr)
  local pos = math.max(cnt-1, 0)
  local fx = r.TrackFX_AddByName(tr, "JS: Volume adjustment", false, -1000)
  if fx >= 0 and pos >= 0 then r.TrackFX_CopyToTrack(tr, fx, tr, pos, true) end
  local last = r.TrackFX_GetCount(tr)-1
  if last >= 0 then
    local min_db, max_db = -90.0, 12.0
    local norm = (delta_db - min_db) / (max_db - min_db)
    if norm < 0 then norm = 0 elseif norm > 1 then norm = 1 end
    r.TrackFX_SetParamNormalized(tr, last, 0, norm)
  end
end

local target = -14.0 -- default LUFS
local ok, t = r.GetUserInputs("DF95 LUFS Autopilot", 1, "Target LUFS-I", "-14.0")
if ok then target = tonumber(t) or -14.0 end

local mst = r.GetMasterTrack(0)
local fx, meta = find_or_insert_meter(mst)
if fx < 0 then r.ShowMessageBox("Kein kompatibler LUFS-Meter gefunden.", "DF95", 0); return end

-- Assume current (B) reading
local needle = (meta and meta.param_contains) or "integrated"
local B = read_lufs(mst, fx, needle) or -12.0
local delta_db = (target - B)

r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
if sel == 0 then
  set_post_gain(mst, delta_db)
else
  for i=0, sel-1 do set_post_gain(r.GetSelectedTrack(0,i), delta_db) end
end
r.Undo_EndBlock(string.format("DF95 LUFS Autopilot: %.1f → %.1f (Δ %.1f dB)", B, target, delta_db), -1)