-- @description DF95_V95_Fieldrec_ItemAnalyze_Color
-- @version 1.0
-- @author DF95
-- @about
--   Schritt 1 von V95:
--   - Analysiert selektierte Audio-Items heuristisch (ohne KI)
--   - bestimmt eine dominante Klasse:
--       * LOW_PERC, SNARE_PERC, HAT/CYMBAL, DRONE/TEXTURE, FX/NOISE
--   - färbt das Item entsprechend
--   - hängt das Klassen-Label an den Item-Namen an.

local r = reaper

------------------------------------------------------------
-- Helper: Projekt-Samplerate
------------------------------------------------------------
local function get_project_samplerate()
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr <= 0 then sr = 44100 end
  return sr
end

------------------------------------------------------------
-- Helper: dB -> Amplitude
------------------------------------------------------------
local function db_to_amp(db)
  return 10 ^ (db / 20)
end

------------------------------------------------------------
-- Naive FFT/DFT für Bandenergien
------------------------------------------------------------
local function compute_band_energies(samples, sr)
  local N = #samples
  if N < 8 then
    return 0,0,0,0,0
  end

  local pi = math.pi
  local two_pi_over_N = 2 * pi / N

  local low, lowmid, mid, high, air = 0,0,0,0,0
  local max_k = math.floor(N/2)

  for k = 1, max_k do
    local freq = (k * sr) / N
    local re_sum, im_sum = 0.0, 0.0
    for n = 0, N-1 do
      local w = 0.54 - 0.46 * math.cos(two_pi_over_N * n) -- Hamming
      local x = samples[n+1] * w
      local a = two_pi_over_N * k * n
      re_sum = re_sum + x * math.cos(a)
      im_sum = im_sum - x * math.sin(a)
    end
    local mag2 = re_sum*re_sum + im_sum*im_sum

    if     freq < 150      then low    = low    + mag2
    elseif freq < 500      then lowmid = lowmid + mag2
    elseif freq < 2000     then mid    = mid    + mag2
    elseif freq < 8000     then high   = high   + mag2
    else                        air    = air    + mag2
    end
  end

  return low, lowmid, mid, high, air
end

------------------------------------------------------------
-- Audio-Samples holen (Mono, Ausschnitt)
------------------------------------------------------------
local function get_mono_samples(accessor, sr, start_time, duration)
  local num_samples = math.floor(duration * sr + 0.5)
  if num_samples < 16 then num_samples = 16 end

  local src = r.GetAudioAccessorSource(accessor)
  local numch = r.GetMediaSourceNumChannels(src)
  if numch < 1 then numch = 1 end

  local buf = r.new_array(numch * num_samples)
  r.GetAudioAccessorSamples(accessor, sr, numch, start_time, num_samples, buf)

  local out = {}
  for i = 0, num_samples-1 do
    local s = 0.0
    for c = 0, numch-1 do
      s = s + buf[i*numch + c]
    end
    out[#out+1] = s / numch
  end
  return out
end

------------------------------------------------------------
-- RMS-Hüllkurve für grobe Segmentierung
------------------------------------------------------------
local function compute_envelope(accessor, sr, item_start, item_len, step, window)
  local env = {}
  local t = item_start
  local end_time = item_start + item_len

  while t < end_time do
    local samples = get_mono_samples(accessor, sr, t, window)
    local sum_sq = 0.0
    for i = 1, #samples do
      sum_sq = sum_sq + samples[i]*samples[i]
    end
    local rms = 0.0
    if #samples > 0 then
      rms = math.sqrt(sum_sq / #samples)
    end
    env[#env+1] = { time = t - item_start, rms = rms }
    t = t + step
  end

  return env
end

------------------------------------------------------------
-- Segmente aus Envelope bestimmen (für dominanten Bereich)
------------------------------------------------------------
local function find_segments_from_envelope(env, item_len, rms_thresh, min_seg_len, min_silence)
  local segments = {}

  local above = false
  local seg_start = nil
  local last_above_time = nil

  for i = 1, #env do
    local t = env[i].time
    local rms = env[i].rms
    local is_above = rms >= rms_thresh

    if is_above then
      if not above then
        seg_start = t
        above = true
      end
      last_above_time = t
    else
      if above then
        local seg_end = last_above_time or t
        if seg_end - seg_start >= min_seg_len then
          segments[#segments+1] = { start = seg_start, stop = seg_end }
        end
        above = false
        seg_start = nil
        last_above_time = nil
      end
    end
  end

  if above and seg_start and last_above_time then
    local seg_end = last_above_time
    if seg_end - seg_start >= min_seg_len then
      segments[#segments+1] = { start = seg_start, stop = seg_end }
    end
  end

  if #segments <= 1 then return segments end

  table.sort(segments, function(a,b) return a.start < b.start end)
  local merged = {}
  local cur = segments[1]

  for i = 2, #segments do
    local s = segments[i]
    if s.start - cur.stop <= min_silence then
      cur.stop = s.stop
    else
      merged[#merged+1] = cur
      cur = s
    end
  end
  merged[#merged+1] = cur

  for _, seg in ipairs(merged) do
    if seg.stop > item_len then seg.stop = item_len end
  end

  return merged
end

------------------------------------------------------------
-- Klassifikation pro Segment
------------------------------------------------------------
local function classify_segment(low, lowmid, mid, high, air, dur)
  local total = low + lowmid + mid + high + air
  if total <= 0 then
    return "SILENT", 0
  end

  local low_n    = low    / total
  local lowmid_n = lowmid / total
  local mid_n    = mid    / total
  local high_n   = high   / total
  local air_n    = air    / total

  if dur > 1.0 and (mid_n + high_n + air_n) > 0.3 then
    return "DRONE/TEXTURE", 4
  end

  if (high_n + air_n) > 0.6 and low_n < 0.1 and dur < 0.5 then
    return "HAT/CYMBAL", 3
  end

  if low_n > 0.45 and dur < 0.8 then
    return "LOW_PERC", 2
  end

  if mid_n > (low_n + high_n) * 0.8 and dur < 0.7 then
    return "SNARE_PERC", 2
  end

  return "FX/NOISE", 1
end

------------------------------------------------------------
-- Farbzuweisung
------------------------------------------------------------
local function get_color_for_class(class)
  local r_col, g_col, b_col = 128,128,128
  if class == "LOW_PERC" then
    r_col, g_col, b_col = 50, 120, 255
  elseif class == "SNARE_PERC" then
    r_col, g_col, b_col = 255, 80, 80
  elseif class == "HAT/CYMBAL" then
    r_col, g_col, b_col = 255, 220, 80
  elseif class == "DRONE/TEXTURE" then
    r_col, g_col, b_col = 180, 80, 255
  elseif class == "FX/NOISE" then
    r_col, g_col, b_col = 80, 200, 120
  elseif class == "SILENT" then
    r_col, g_col, b_col = 80, 80, 80
  end
  return r.ColorToNative(r_col, g_col, b_col) | 0x1000000
end

------------------------------------------------------------
-- Item analysieren & dominante Klasse bestimmen
------------------------------------------------------------
local function analyze_item_dominant_class(item)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then return nil end

  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local accessor = r.CreateTakeAudioAccessor(take)
  if not accessor then return nil end

  local sr = get_project_samplerate()

  local env_step     = 0.05
  local env_window   = 0.05
  local rms_thresh   = db_to_amp(-40)
  local min_seg_len  = 0.05
  local min_silence  = 0.05

  local env = compute_envelope(accessor, sr, item_pos, item_len, env_step, env_window)
  local segments = find_segments_from_envelope(env, item_len, rms_thresh, min_seg_len, min_silence)
  if #segments == 0 then
    segments = { { start = 0.0, stop = item_len } }
  end

  local class_energy = {}

  for _, seg in ipairs(segments) do
    local seg_start = item_pos + seg.start
    local seg_dur   = seg.stop - seg.start
    if seg_dur <= 0 then seg_dur = 0.05 end

    local center = seg_start + seg_dur * 0.5
    local win_dur = math.min(seg_dur, 0.25)

    local samples = get_mono_samples(accessor, sr, center - win_dur/2, win_dur)
    local low, lowmid, mid, high, air = compute_band_energies(samples, sr)
    local class, _ = classify_segment(low, lowmid, mid, high, air, seg_dur)

    local total_energy = low + lowmid + mid + high + air
    class_energy[class] = (class_energy[class] or 0) + total_energy
  end

  r.DestroyAudioAccessor(accessor)

  local best_class, best_val = nil, -1
  for c, v in pairs(class_energy) do
    if v > best_val then
      best_val = v
      best_class = c
    end
  end

  return best_class or "FX/NOISE"
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
local function main()
  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then
    r.ShowMessageBox("Bitte mindestens ein Audio-Item auswählen.", "DF95 V95 Analyze+Color", 0)
    return
  end

  r.Undo_BeginBlock()

  for i = 0, cnt-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local class = analyze_item_dominant_class(item)
    if class then
      local color = get_color_for_class(class)
      r.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)

      local take = r.GetActiveTake(item)
      if take then
        local _, name = r.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        name = name or ""
        if not name:match("%[V95_") then
          name = name .. " [V95_" .. class .. "]"
          r.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
        end
      end
    end
  end

  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V95 Fieldrec Item Analyze + Color", -1)
end

main()
