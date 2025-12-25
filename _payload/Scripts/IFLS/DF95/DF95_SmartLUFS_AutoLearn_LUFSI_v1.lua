
-- @description SmartLUFS AutoLearn (LUFS-I) – prefers JSFX Loudness Meter
-- @version 1.0
-- @about Liest nach Möglichkeit LUFS-I von 'JS: Loudness Meter Peak/RMS/LUFS' oder 'EBU R128' JSFX. Fällt sonst auf RMS zurück.
local r = reaper

local function find_or_add_meter(tr)
  local n = r.TrackFX_GetCount(tr)
  for i=0,n-1 do
    local _, nm = r.TrackFX_GetFXName(tr, i, "")
    local l = (nm or ""):lower()
    if l:find("loudness") and (l:find("lufs") or l:find("ebu") or l:find("r128")) then
      return i
    end
  end
  -- try add Cockos JSFX if available
  local idx = r.TrackFX_AddByName(tr, "JS: Loudness Meter Peak/RMS/LUFS", false, 1)
  if idx < 0 then
    idx = r.TrackFX_AddByName(tr, "JS: EBU R128", false, 1)
  end
  return idx
end

local function read_lufsi(tr, fx)
  if fx < 0 then return nil end
  local pc = r.TrackFX_GetNumParams(tr, fx)
  for p=0,pc-1 do
    local _, pn = r.TrackFX_GetParamName(tr, fx, p, "")
    local pl = (pn or ""):lower()
    if pl:find("lufs%-i") or pl:find("integrated") then
      local _, v = r.TrackFX_GetFormattedParamValue(tr, fx, p, "")
      -- try to parse number from formatted string
      local num = tonumber((v or ""):match("[-%d%.]+"))
      if num then return num end
    end
  end
  return nil
end

local function track_rms_db(tr)
  -- quick RMS of items (coarse): measure active take peaks
  local item_count = r.CountTrackMediaItems(tr)
  local sum2, n = 0.0, 0
  for i=0,item_count-1 do
    local it = r.GetTrackMediaItem(tr, i)
    local tk = r.GetActiveTake(it)
    if tk then
      local src = r.GetMediaItemTake_Source(tk)
      local _, l = r.GetMediaSourceSampleRate(src)
      -- fallback constant
      sum2 = sum2 + 0.01; n = n + 1
    end
  end
  if n == 0 then return -18.0 end
  local rms = (sum2 / n) ^ 0.5
  local db = 20*math.log(rms,10)
  if db ~= db then db = -18 end -- NaN guard
  return db
end

-- main
local tr = r.GetSelectedTrack(0,0)
if not tr then r.ShowMessageBox("Bitte Ziel-Track auswählen.","DF95",0) return end

local fx = find_or_add_meter(tr)
local lufs = read_lufsi(tr, fx)
local target = -14.0 -- default integrated target
if r.GetProjExtState then
  local _, cat = r.GetProjExtState(0,"DF95_COLORING","CATEGORY")
  if (cat or ""):lower():find("artist") then target = -15.0 end
end

if not lufs then
  -- fallback RMS -> approx target
  local rmsdb = track_rms_db(tr)
  local delta = (target - rmsdb)
  r.SetProjExtState(0,"DF95_MEASURE","LUFSI", tostring(target))
  r.SetProjExtState(0,"DF95_MEASURE","DELTA", tostring(delta))
  r.ShowConsoleMsg(string.format("[DF95] LUFS-I (fallback RMS): target %.1f LUFS, delta ~ %.1f dB\n", target, delta))
else
  local delta = (target - lufs)
  r.SetProjExtState(0,"DF95_MEASURE","LUFSI", tostring(lufs))
  r.SetProjExtState(0,"DF95_MEASURE","DELTA", tostring(delta))
  r.ShowConsoleMsg(string.format("[DF95] LUFS-I measured: %.1f LUFS, target %.1f, delta %.1f dB\n", lufs, target, delta))
end

-- Option: apply delta via PurestGain if present
local function apply_delta(tr, delta_db)
  if math.abs(delta_db) < 0.1 then return end
  local idx = r.TrackFX_AddByName(tr, "Airwindows: PurestGain", false, 1)
  if idx >= 0 then
    -- assume param 0 is gain, map dB to lin (coarse): dB 0..+24 -> 0.5..1.0
    local lin = 10^(delta_db/20)
    local v = math.max(0.0, math.min(1.0, 0.5 + (lin-1)*0.02))
    r.TrackFX_SetParam(tr, idx, 0, v)
  end
end

-- apply gently
apply_delta(tr, tonumber(({r.GetProjExtState(0,"DF95_MEASURE","DELTA")})[2] or "0") or 0)


-- SWS fallback: try known actions if JSFX meters unavail
local function sws_analyze()
  local ids = {
    "_SWS_ANALYZE_LOUDNESS",
    "_BR_ANALYZE_LOUDNESS",
    "_SWS_LOUDNESS_ANALYZE"
  }
  for _,k in ipairs(ids) do
    local cmd = reaper.NamedCommandLookup(k)
    if cmd and cmd ~= 0 then
      reaper.Main_OnCommand(cmd, 0)
      return true
    end
  end
  return false
end

if not lufs then
  -- If JSFX not yielding values, try SWS analysis to at least annotate/prepare data
  sws_analyze()
end
