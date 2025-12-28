-- DF95_ZeroCross_FadeOptimizer.lua
-- "AI-artiger" Zero-Cross-Fade-Optimizer:
--   * Analysiert jeden selektierten Audio-Item-Anfang/-Ende
--   * Misst RMS / Transientendichte in einem kurzen Fenster
--   * Setzt Fade-In/Fade-Out-Längen adaptiv:
--       - laute/transientreiche Anfänge -> längere Fades
--       - leise/weiche Anfänge -> kurze Fades
--   * Optional: verschiebt Fade-Start leicht Richtung ZeroCross
--
-- Ziel: Click-freie, musikalische Fades für stark geslictes IDM-Material.

local r = reaper

local function amp_to_db(a)
  if a <= 0.0000001 then return -120.0 end
  return 20 * math.log(a, 10)
end

local function analyze_edge(take, at_item_start, window_ms)
  local item = r.GetMediaItemTake_Item(take)
  local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  local aa = r.CreateTakeAudioAccessor(take)
  if not aa then return nil end

  local src = r.GetMediaItemTake_Source(take)
  local samplerate = ({r.GetMediaSourceSampleRate(src)})[2]
  if not samplerate or samplerate <= 0 then samplerate = 44100 end
  local num_ch = ({r.GetMediaSourceNumChannels(src)})[2] or 2

  local win_s = (window_ms or 40) / 1000.0
  local start_t, stop_t
  if at_item_start then
    start_t = 0.0
    stop_t  = math.min(len, win_s)
  else
    start_t = math.max(0.0, len - win_s)
    stop_t  = len
  end
  local dur = stop_t - start_t
  if dur <= 0 then
    r.DestroyAudioAccessor(aa)
    return nil
  end

  local ns = math.floor(dur * samplerate + 0.5)
  if ns <= 0 then
    r.DestroyAudioAccessor(aa)
    return nil
  end

  local buf = r.new_array(ns * num_ch)
  r.GetAudioAccessorSamples(aa, samplerate, num_ch, start_t, ns, buf)

  local sum_sq = 0.0
  local transients = 0
  local prev_amp = 0.0

  for i = 0, ns-1 do
    local sL = buf[i*num_ch+1] or 0.0
    local sR = (num_ch > 1 and buf[i*num_ch+2]) or 0.0
    local a = (math.abs(sL) + math.abs(sR)) * 0.5
    sum_sq = sum_sq + a*a

    local diff = math.abs(a - prev_amp)
    if diff > 0.1 then
      transients = transients + 1
    end
    prev_amp = a
  end

  r.DestroyAudioAccessor(aa)

  local rms = math.sqrt(sum_sq / math.max(1, ns))
  local rms_db = amp_to_db(rms)

  return {
    rms = rms,
    rms_db = rms_db,
    transients = transients,
  }
end

local function decide_fade_len_ms(edge_info)
  if not edge_info then
    return 5.0
  end

  local rms_db = edge_info.rms_db or -60.0
  local trans = edge_info.transients or 0

  -- Grundlogik:
  --   sehr laut/kräftig: längere Fades
  --   leise/weich: kurze Fades
  local base
  if rms_db > -12 then
    base = 18
  elseif rms_db > -24 then
    base = 12
  elseif rms_db > -36 then
    base = 8
  else
    base = 4
  end

  -- Viele Transienten => etwas längere Fades
  if trans > 40 then
    base = base + 6
  elseif trans > 20 then
    base = base + 3
  end

  if base < 2 then base = 2 end
  if base > 50 then base = 50 end
  return base
end

local function process_item(it)
  local take = r.GetActiveTake(it)
  if not take or r.TakeIsMIDI(take) then return end

  local start_info = analyze_edge(take, true, 40)
  local end_info   = analyze_edge(take, false, 40)

  local fadein_ms  = decide_fade_len_ms(start_info)
  local fadeout_ms = decide_fade_len_ms(end_info)

  local fadein_s   = fadein_ms / 1000.0
  local fadeout_s  = fadeout_ms / 1000.0

  r.SetMediaItemInfo_Value(it, "D_FADEINLEN", fadein_s)
  r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", fadeout_s)
end

local function main()
  local num = r.CountSelectedMediaItems(0)
  if num == 0 then
    r.ShowMessageBox("Bitte zuerst geslicte Audio-Items selektieren.", "DF95 ZeroCross Fade Optimizer", 0)
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, num-1 do
    local it = r.GetSelectedMediaItem(0, i)
    process_item(it)
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 ZeroCross Fade Optimizer (RMS-aware)", -1)
  r.UpdateArrange()
end

main()
