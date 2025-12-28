-- @description DF95_V95_1_Fieldrec_Split_And_Distribute_MicBundle_AutoGain
-- @version 1.0
-- @author DF95
-- @about
--   Erweiterung von V95: MicBundle + Folder-Master + AutoGain.
--   Erwartet: mehrere synchronisierte Mic-Spuren (Items) ausgewählt.
--   Tut:
--     - nimmt ALLE selektierten Audio-Items als ein Mic-Bundle (Mic1..MicN)
--     - bildet eine gemeinsame Aktivitätshüllkurve über alle Mics
--     - segmentiert in aktive Bereiche (on/off)
--     - klassifiziert jedes Segment heuristisch (ohne KI) in:
--         * LOW_PERC, SNARE_PERC, HAT/CYMBAL, DRONE/TEXTURE, FX/NOISE
--     - erzeugt pro Klasse einen Folder-Master-Track:
--         * V95_SNARE_PERC, V95_LOW_PERC, V95_HAT_CYMBAL, V95_DRONE_TEXTURE, V95_FX_NOISE
--     - darunter: pro Mic einen Child-Track:
--         * z.B. V95_SNARE_PERC_Mic1, V95_SNARE_PERC_Mic2, ...
--     - legt für jedes Segment pro Mic ein neues Item auf dem passenden Child-Track an.
--     - führt ein einfaches AutoGain pro Child-Track durch (Peak-Normalisierung), indem
--       die Item-Gains so angepasst werden, dass die lautesten Items ca. -6 dBFS erreichen.
--
--   Hinweis:
--     - Track-Fader bleiben unberührt, AutoGain arbeitet über Item-Gain.
--     - Alle Mic-Items sollten zeitlich synchron sein (klassische Multitrack-Aufnahme).
--     - Script ist für "ein Bundle auf einmal" gedacht: alle zugehörigen Mics gemeinsam selektieren.

local r = reaper

------------------------------------------------------------
local function get_project_samplerate()
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr <= 0 then sr = 44100 end
  return sr
end

local function db_to_amp(db)
  return 10 ^ (db / 20)
end

------------------------------------------------------------
-- Naive DFT-basierte Bandenergien (Low/LowMid/Mid/High/Air)
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
-- Audio-Samples / Mono
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
-- Envelope pro Mic + gemischte Hüllkurve
------------------------------------------------------------
local function compute_envelope_for_item(accessor, sr, item_start, item_len, step, window)
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
    env[#env+1] = { time = t, rms = rms }
    t = t + step
  end
  return env
end

local function mix_envelopes(env_list, item_start)
  if #env_list == 0 then return {} end
  local mixed = {}
  local count = #env_list[1]
  for i = 1, count do
    local t = env_list[1][i].time
    local m = 0.0
    for j = 1, #env_list do
      local e = env_list[j][i]
      if e.rms > m then m = e.rms end
    end
    mixed[#mixed+1] = { time = t - item_start, rms = m }
  end
  return mixed
end

------------------------------------------------------------
-- Segmentierung aus gemischter Envelope
------------------------------------------------------------
local function find_segments_from_envelope(env, item_len, rms_thresh, min_seg_len, min_silence)
  local segments = {}
  local above = false
  local seg_start = nil
  local last_above_time = nil
  for i = 1, #env do
    local t_rel = env[i].time
    local rms = env[i].rms
    local is_above = rms >= rms_thresh
    if is_above then
      if not above then
        seg_start = t_rel
        above = true
      end
      last_above_time = t_rel
    else
      if above then
        local seg_end = last_above_time or t_rel
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
-- Klassifikation + Track-Namen
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

local function sanitize_class_for_name(class)
  local n = class:gsub("[^%w]+", "_")
  return n
end

local function get_folder_master_name(class)
  local base = sanitize_class_for_name(class)
  return "V95_" .. base
end

local function get_child_name(class, mic_index)
  local base = sanitize_class_for_name(class)
  return string.format("V95_%s_Mic%d", base, mic_index)
end

------------------------------------------------------------
-- Folder-Track-Erzeugung
------------------------------------------------------------
local function create_folder_for_class(class, num_mics)
  local proj = 0
  local master_name = get_folder_master_name(class)
  local track_count = r.CountTracks(proj)
  r.InsertTrackAtIndex(track_count, true)
  local master = r.GetTrack(proj, track_count)
  r.GetSetMediaTrackInfo_String(master, "P_NAME", master_name, true)
  r.SetMediaTrackInfo_Value(master, "I_FOLDERDEPTH", 1)
  local children = {}
  local last_index = track_count
  for i = 1, num_mics do
    r.InsertTrackAtIndex(last_index + i, true)
    local ch = r.GetTrack(proj, last_index + i)
    local child_name = get_child_name(class, i)
    r.GetSetMediaTrackInfo_String(ch, "P_NAME", child_name, true)
    r.SetMediaTrackInfo_Value(ch, "I_FOLDERDEPTH", 0)
    children[#children+1] = ch
  end
  if #children > 0 then
    r.SetMediaTrackInfo_Value(children[#children], "I_FOLDERDEPTH", -1)
  else
    r.SetMediaTrackInfo_Value(master, "I_FOLDERDEPTH", 0)
  end
  return master, children
end

------------------------------------------------------------
-- AutoGain pro Child-Track (Peak-Normalisierung über alle Items)
------------------------------------------------------------
local function autogain_child_track(track, target_peak_db)
  local target_amp = db_to_amp(target_peak_db or -6.0)
  local item_count = r.CountTrackMediaItems(track)
  if item_count == 0 then return end
  local global_peak = 0.0
  for i = 0, item_count-1 do
    local item = r.GetTrackMediaItem(track, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local src = r.GetMediaItemTake_Source(take)
      local len, _ = r.GetMediaSourceLength(src)
      local sr = get_project_samplerate()
      local num_ch = r.GetMediaSourceNumChannels(src)
      if num_ch < 1 then num_ch = 1 end
      local samples = math.min(math.floor(len * sr), 200000)
      if samples > 0 then
        local buf = r.new_array(samples * num_ch)
        r.GetMediaItemTake_Peaks(take, sr, 0, 0, samples, num_ch, buf)
        for s = 0, samples-1 do
          for c = 0, num_ch-1 do
            local v = buf[s*num_ch + c]
            if math.abs(v) > global_peak then
              global_peak = math.abs(v)
            end
          end
        end
      end
    end
  end
  if global_peak <= 0.0 then return end
  local needed_gain = target_amp / global_peak
  for i = 0, item_count-1 do
    local item = r.GetTrackMediaItem(track, i)
    local vol = r.GetMediaItemInfo_Value(item, "D_VOL")
    r.SetMediaItemInfo_Value(item, "D_VOL", vol * needed_gain)
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
local function main()
  local sel_count = r.CountSelectedMediaItems(0)
  if sel_count == 0 then
    r.ShowMessageBox("Bitte alle Mic-Items (z.B. 3 Tracks einer Aufnahme) auswählen.", "DF95 V95.1 MicBundle", 0)
    return
  end

  local mics = {}
  local earliest_start = nil
  local latest_end = nil

  for i = 0, sel_count-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      local acc = r.CreateTakeAudioAccessor(take)
      if acc then
        mics[#mics+1] = { item = item, take = take, accessor = acc, pos = pos, len = len }
        local start_t = pos
        local end_t = pos + len
        if not earliest_start or start_t < earliest_start then earliest_start = start_t end
        if not latest_end or end_t > latest_end then latest_end = end_t end
      end
    end
  end

  if #mics == 0 then
    r.ShowMessageBox("Keine gültigen Audio-Takes in den selektierten Items gefunden.", "DF95 V95.1 MicBundle", 0)
    return
  end

  local proj_sr = get_project_samplerate()
  local env_step   = 0.03
  local env_window = 0.03
  local thresh_db  = -40
  local rms_thresh = db_to_amp(thresh_db)
  local min_seg_len = 0.05
  local min_silence = 0.05

  local earliest_start_local = earliest_start
  local total_len = latest_end - earliest_start_local

  local env_list = {}
  for _, mic in ipairs(mics) do
    local env = compute_envelope_for_item(mic.accessor, proj_sr, earliest_start_local, total_len, env_step, env_window)
    env_list[#env_list+1] = env
  end

  local mixed_env = mix_envelopes(env_list, earliest_start_local)
  local segments = find_segments_from_envelope(mixed_env, total_len, rms_thresh, min_seg_len, min_silence)
  if #segments == 0 then
    segments = { { start = 0.0, stop = total_len } }
  end

  -- Klassifikation pro Segment anhand des ersten Mics
  local ref_mic = mics[1]
  local class_for_segment = {}
  for idx, seg in ipairs(segments) do
    local seg_start = earliest_start_local + seg.start
    local seg_dur   = seg.stop - seg.start
    if seg_dur <= 0 then seg_dur = 0.05 end
    local center  = seg_start + seg_dur * 0.5
    local win_dur = math.min(seg_dur, 0.25)
    local samples = get_mono_samples(ref_mic.accessor, proj_sr, center - win_dur/2, win_dur)
    local low, lowmid, mid, high, air = compute_band_energies(samples, proj_sr)
    local class, _ = classify_segment(low, lowmid, mid, high, air, seg_dur)
    class_for_segment[idx] = class
  end

  r.Undo_BeginBlock()

  local folders = {}

  for seg_idx, seg in ipairs(segments) do
    local class = class_for_segment[seg_idx]
    if class ~= "SILENT" then
      if not folders[class] then
        local master, children = create_folder_for_class(class, #mics)
        folders[class] = { master = master, children = children }
      end
      local folder = folders[class]
      local children = folder.children
      local seg_start_rel = seg.start
      local seg_dur = seg.stop - seg.start
      if seg_dur <= 0 then seg_dur = 0.05 end
      for mic_index, mic in ipairs(mics) do
        local child_track = children[mic_index]
        if child_track then
          local mic_start = mic.pos
          local mic_end   = mic.pos + mic.len
          local seg_start_abs = earliest_start_local + seg_start_rel
          local seg_end_abs   = seg_start_abs + seg_dur
          if seg_end_abs > mic_start and seg_start_abs < mic_end then
            local overlap_start = math.max(seg_start_abs, mic_start)
            local overlap_end   = math.min(seg_end_abs, mic_end)
            local overlap_len   = overlap_end - overlap_start
            if overlap_len > 0.005 then
              local new_item = r.AddMediaItemToTrack(child_track)
              r.SetMediaItemInfo_Value(new_item, "D_POSITION", overlap_start)
              r.SetMediaItemInfo_Value(new_item, "D_LENGTH",  overlap_len)
              local new_take = r.AddTakeToMediaItem(new_item)
              r.SetMediaItemTake_Source(new_take, r.GetMediaItemTake_Source(mic.take))
              local playrate = r.GetMediaItemTakeInfo_Value(mic.take, "D_PLAYRATE")
              if playrate <= 0 then playrate = 1.0 end
              r.SetMediaItemTakeInfo_Value(new_take, "D_PLAYRATE", playrate)
              local orig_startoffs = r.GetMediaItemTakeInfo_Value(mic.take, "D_STARTOFFS")
              local rel_in_mic = (overlap_start - mic.pos) * playrate
              local new_offs = orig_startoffs + rel_in_mic
              r.SetMediaItemTakeInfo_Value(new_take, "D_STARTOFFS", new_offs)
              local label = string.format("V95_%s_Mic%d", sanitize_class_for_name(class), mic_index)
              r.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", label, true)
              local color = get_color_for_class(class)
              r.SetMediaItemInfo_Value(new_item, "I_CUSTOMCOLOR", color)
              -- V95.1 safety fades
              local fade_len = 0.005
              r.SetMediaItemInfo_Value(new_item, "D_FADEINLEN", fade_len)
              r.SetMediaItemInfo_Value(new_item, "D_FADEOUTLEN", fade_len)
            end
          end
        end
      end
    end
  end

  for class, info in pairs(folders) do
    for _, child in ipairs(info.children) do
      autogain_child_track(child, -6.0)
    end
  end

  for _, mic in ipairs(mics) do
    if mic.accessor then
      r.DestroyAudioAccessor(mic.accessor)
    end
  end

  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V95.1 Fieldrec MicBundle Split & Distribute + AutoGain", -1)
end

main()
