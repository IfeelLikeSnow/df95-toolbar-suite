-- @description DF95_Slicing_HybridAI_Engine
-- @version 1.0
-- @author DF95
-- @about
--   Kern-Engine fuer Hybrid-AI-Slicing in DF95.
--   Fokus:
--     - Transienten-basierte Slices
--     - Zero-Crossing-Korrektur
--     - Materialabhaengige Fade-Ins/Fade-Outs
--   Dieses Script ist als Modul gedacht und wird von ImGui-UIs oder
--   anderen DF95-Skripten aufgerufen.

local r = reaper

local M = {}

----------------------------------------------------------------
-- Hilfsfunktionen
----------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function get_take_audio_accessor(take)
  if not take then return nil end
  local item = r.GetMediaItemTake_Item(take)
  local src = r.GetMediaItemTake_Source(take)
  local accessor = r.CreateTakeAudioAccessor(take)
  return accessor, src, item
end

local function destroy_accessor(acc)
  if acc then r.DestroyAudioAccessor(acc) end
end

local function get_source_properties(src)
  if not src then return nil, nil end
  local len = r.GetMediaSourceLength(src)
  local samplerate = r.GetMediaSourceSampleRate(src)
  return len, samplerate
end

-- Suche Zero-Crossing um eine Zeitposition herum
local function find_zero_crossing(take, t, search_ms)
  if not take then return t end
  search_ms = search_ms or 5.0

  local acc, src, item = get_take_audio_accessor(take)
  if not acc or not src then return t end

  local src_len, sr = get_source_properties(src)
  if not sr or sr <= 0 then
    destroy_accessor(acc)
    return t
  end

  local half_window = (search_ms / 1000.0)
  local start_t = math.max(0, t - half_window)
  local end_t   = math.min(src_len, t + half_window)

  -- Wir samplen nur einen Kanal (Mono-Approximation fuer Zero-Cross).
  local numch = r.GetMediaSourceNumChannels(src)
  local chan = 0
  local buf = {}
  local best_t = t
  local best_dist = 1e9

  local step = 1.0 / sr  -- 1 Sample

  local function sample_at(time)
    buf[1] = 0.0
    r.GetAudioAccessorSamples(acc, sr, numch, time, 1, buf)
    return buf[1]
  end

  local prev = sample_at(start_t)
  local tt = start_t + step
  while tt <= end_t do
    local v = sample_at(tt)
    if (prev <= 0 and v > 0) or (prev >= 0 and v < 0) then
      -- Nulldurchgang zwischen tt-step und tt
      local cand = tt
      local d = math.abs(cand - t)
      if d < best_dist then
        best_dist = d
        best_t = cand
      end
    end
    prev = v
    tt = tt + step
  end

  destroy_accessor(acc)
  return best_t
end

-- Erzeuge Transienten-Liste anhand einfacher Amplituden-Analyse
local function detect_transients(take, mode_cfg)
  local acc, src, _ = get_take_audio_accessor(take)
  if not acc or not src then return {} end

  local src_len, sr = get_source_properties(src)
  if not sr or sr <= 0 then
    destroy_accessor(acc)
    return {}
  end

  local window_ms  = mode_cfg.window_ms  or 5.0
  local hop_ms     = mode_cfg.hop_ms     or window_ms
  local thresh     = mode_cfg.threshold  or 0.2
  local min_gap_ms = mode_cfg.min_gap_ms or 30.0

  local window_s = window_ms / 1000.0
  local hop_s    = hop_ms / 1000.0
  local min_gap  = min_gap_ms / 1000.0

  local numch = r.GetMediaSourceNumChannels(src)
  local samples_per_window = math.floor(sr * window_s + 0.5)
  if samples_per_window < 1 then samples_per_window = 1 end

  local buf = {}
  local peaks = {}
  local t = 0.0
  local prev_peak = 0.0

  while t < src_len do
    local nsamp = samples_per_window
    buf = {}
    r.GetAudioAccessorSamples(acc, sr, numch, t, nsamp, buf)
    local peak = 0.0
    for i = 1, nsamp * numch do
      local v = math.abs(buf[i] or 0.0)
      if v > peak then peak = v end
    end
    peaks[#peaks+1] = {t = t, peak = peak, diff = peak - prev_peak}
    prev_peak = peak
    t = t + hop_s
  end

  local transients = {}
  local last_tr_time = -1e9
  for _, p in ipairs(peaks) do
    if p.diff >= thresh and (p.t - last_tr_time) >= min_gap then
      transients[#transients+1] = p.t
      last_tr_time = p.t
    end
  end

  destroy_accessor(acc)
  return transients
end

----------------------------------------------------------------
-- Mode-Profile
----------------------------------------------------------------

local MODE_PROFILES = {
  drum = {
    window_ms  = 3.0,
    hop_ms     = 2.0,
    threshold  = 0.15,
    min_gap_ms = 25.0,
    search_zero_ms = 4.0,
    fade_in_ms = 1.5,
    fade_out_ms = 6.0,
  },
  idm_micro = {
    window_ms  = 2.0,
    hop_ms     = 1.0,
    threshold  = 0.10,
    min_gap_ms = 10.0,
    search_zero_ms = 3.0,
    fade_in_ms = 0.8,
    fade_out_ms = 4.0,
  },
  fieldrec = {
    window_ms  = 10.0,
    hop_ms     = 5.0,
    threshold  = 0.12,
    min_gap_ms = 200.0,
    search_zero_ms = 8.0,
    fade_in_ms = 4.0,
    fade_out_ms = 12.0,
  },
  speech = {
    window_ms  = 8.0,
    hop_ms     = 4.0,
    threshold  = 0.10,
    min_gap_ms = 130.0,
    search_zero_ms = 5.0,
    fade_in_ms = 2.0,
    fade_out_ms = 8.0,
  },
  loop = {
    window_ms  = 6.0,
    hop_ms     = 3.0,
    threshold  = 0.12,
    min_gap_ms = 50.0,
    search_zero_ms = 4.0,
    fade_in_ms = 1.5,
    fade_out_ms = 6.0,
  },
  hybrid = {
    window_ms  = 4.0,
    hop_ms     = 2.0,
    threshold  = 0.13,
    min_gap_ms = 30.0,
    search_zero_ms = 4.0,
    fade_in_ms = 1.5,
    fade_out_ms = 7.0,
  }
}

local function get_mode_profile(mode)
  return MODE_PROFILES[mode] or MODE_PROFILES["hybrid"]
end

local function clone_profile(p)
  local t = {}
  if p then
    for k, v in pairs(p) do
      t[k] = v
    end
  end
  return t
end


----------------------------------------------------------------
-- Haupt-Engine: Items -> Slices -> Fades/Farben
----------------------------------------------------------------

local function set_item_fades(item, fade_in_ms, fade_out_ms)
  local fade_in  = (fade_in_ms or 2.0) / 1000.0
  local fade_out = (fade_out_ms or 6.0) / 1000.0
  r.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
  r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
  r.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade_in)
  r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fade_out)
end

local function color_by_material(item, mat_type)
  local col = 0
  if mat_type == "drum" then
    col = r.ColorToNative(220, 80, 60)|0x1000000
  elseif mat_type == "hat" or mat_type == "high" then
    col = r.ColorToNative(80, 160, 240)|0x1000000
  elseif mat_type == "tonal" then
    col = r.ColorToNative(80, 200, 80)|0x1000000
  elseif mat_type == "noise" then
    col = r.ColorToNative(200, 80, 200)|0x1000000
  elseif mat_type == "speech" then
    col = r.ColorToNative(80, 200, 200)|0x1000000
  elseif mat_type == "click" then
    col = r.ColorToNative(255, 160, 80)|0x1000000
  else
    col = r.ColorToNative(180, 180, 180)|0x1000000
  end
  r.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", col)
end

-- Sehr einfache Material-Heuristik anhand Peak-Level und Fenster-Abstand
local function classify_material(peak, mode)
  if mode == "speech" then return "speech" end
  if mode == "fieldrec" then return "noise" end
  if mode == "idm_micro" then return "noise" end
  if mode == "loop" then return "tonal" end

  -- default/hybrid/drum
  if peak > 0.6 then
    return "drum"
  elseif peak > 0.3 then
    return "tonal"
  else
    return "noise"
  end
end

-- Kernfunktion: Slicing eines Items
local function slice_item_with_profile(item, mode, profile)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then return end

  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- Transientenpositionen in Source-Zeit
  local transients = detect_transients(take, profile)
  if #transients == 0 then return end

  -- Filter: nur Transienten, die innerhalb der Item-Grenzen liegen
  local src = r.GetMediaItemTake_Source(take)
  local src_len, sr = get_source_properties(src)
  if not src_len or not sr then return end

  -- Mapping: Project-Zeit ~ Source-Zeit annehmen (kein Pitch/Rate)
  local slice_times = {}
  for _, st in ipairs(transients) do
    local proj_t = item_pos + st
    if proj_t > item_pos + 0.005 and proj_t < item_pos + item_len - 0.005 then
      slice_times[#slice_times+1] = proj_t
    end
  end

  table.sort(slice_times)

  if #slice_times == 0 then return end

  -- Erst Splits, dann Fades + Farben
  local fades_in  = profile.fade_in_ms
  local fades_out = profile.fade_out_ms
  local search_zero = profile.search_zero_ms or 4.0

  -- Wir arbeiten von hinten nach vorne, um Item-Handles stabil zu halten
  for i = #slice_times, 1, -1 do
    local t = slice_times[i]
    -- Zero-Cross in Source finden, dann in Projektzeit abbilden
    local src_t = t - item_pos
    local zc_src_t = find_zero_crossing(take, src_t, search_zero)
    local zc_proj_t = item_pos + zc_src_t
    r.SplitMediaItem(item, zc_proj_t)
  end

  -- Fades und Colors applizieren
  local track = r.GetMediaItem_Track(item)
  local idx = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
  local items_on_track = r.CountTrackMediaItems(track)
  for i = 0, items_on_track-1 do
    local it = r.GetTrackMediaItem(track, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    if pos >= item_pos-0.0001 and pos < item_pos + item_len + 0.0001 then
      set_item_fades(it, fades_in, fades_out)
      local take2 = r.GetActiveTake(it)
      if take2 then
        local acc, src2, _ = get_take_audio_accessor(take2)
        local p = 0.0
        if acc and src2 then
          local src_len2, sr2 = get_source_properties(src2)
          local numch2 = r.GetMediaSourceNumChannels(src2)
          local buf = {}
          r.GetAudioAccessorSamples(acc, sr2 or 44100, numch2, 0.0, 512, buf)
          for j = 1, #buf do
            local v = math.abs(buf[j] or 0.0)
            if v > p then p = v end
          end
          destroy_accessor(acc)
        end
        local mat = classify_material(p, mode)
        color_by_material(it, mat)
      end
    end
  end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

-- opts:
--   mode      : "hybrid", "drum", "idm_micro", "fieldrec", "speech", "loop"
--   on_before : function(item)
--   on_after  : function(item)
function M.run(mode, opts)
  mode = mode or "hybrid"
  local base_profile = get_mode_profile(mode)
  local profile = clone_profile(base_profile)
  opts = opts or {}

  if opts.profile_override and type(opts.profile_override) == "table" then
    for k, v in pairs(opts.profile_override) do
      profile[k] = v
    end
  end

  local num_sel = r.CountSelectedMediaItems(0)
  if num_sel == 0 then
    r.ShowMessageBox("Keine Items ausgewaehlt fuer DF95 HybridAI Slicing.", "DF95 Slicing HybridAI", 0)
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, num_sel-1 do
    local item = r.GetSelectedMediaItem(0, i)
    if opts.on_before then opts.on_before(item, mode, profile) end
    slice_item_with_profile(item, mode, profile)
    if opts.on_after then opts.on_after(item, mode, profile) end
  end

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 HybridAI Slicing (" .. mode .. ")", -1)
end

return M
