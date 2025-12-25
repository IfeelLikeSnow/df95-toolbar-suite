-- IFLS_SliceDomain.lua
-- Phase 28+32+33: Audio Waveform Slicing Domain
--   * GRID-Mode: musikalisches Raster (1/8, 1/16, 1/32, Bars per Slice)
--   * TRANSIENT-Mode: Transienten-basierte Schnitte via GetMediaItemTake_Peaks + Fades
--   * TRANSIENT_ZC-Mode: Transienten + lokale Zero-Cross-Suche + Fades (max. De-Click)
--
-- Hinweis:
--   Diese Domain ist so gebaut, dass sie in "echtem" REAPER läuft.
--   Zero-Cross wird aus Performancegründen in einem kleinen Fenster um die
--   geschätzte Transientenzeit gesucht (lokale Analyse mit hoher Peakrate).

local r = reaper
local M = {}

local NS = "IFLS_SLICE"

----------------------------------------------------------
-- ExtState Helpers
----------------------------------------------------------

local function get_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function get_num(key, default)
  local v = tonumber(get_ext(key, ""))
  if not v then return default end
  return v
end

local function get_str(key, default)
  local v = get_ext(key, "")
  if v == "" then return default end
  return v
end

local function get_bool(key, default)
  local v = get_ext(key, default and "1" or "0")
  return v == "1"
end

----------------------------------------------------------
-- Config
----------------------------------------------------------

function M.read_cfg()
  local cfg = {
    mode           = get_str("MODE", "GRID"),   -- GRID / TRANSIENT / TRANSIENT_ZC
    note_div       = get_str("NOTE_DIV", "1/16"),
    bars_per_slice = get_num("BARS_PER_SLICE", 0),
    create_regions = get_bool("CREATE_REGIONS", false),
    snap_to_grid   = get_bool("SNAP_TO_GRID", true),

    peakrate       = get_num("PEAKRATE", 1000), -- Peaks/s für globale Analyse
    min_gap_ms     = get_num("MIN_GAP_MS", 25), -- Minimalabstand zwischen Transienten
    thr_rel        = get_num("THR_REL", 30),    -- Threshold in dB unter MaxPeak

    fadein_ms      = get_num("FADEIN_MS", 2),   -- Fade-In für Transient-Slices
    fadeout_ms     = get_num("FADEOUT_MS", 5),  -- Fade-Out für Transient-Slices

    zc_window_ms   = get_num("ZC_WINDOW_MS", 5) -- Fenster um Transientenzeit für ZeroCross-Suche
  }
  return cfg
end

function M.write_cfg(cfg)
  if not cfg then return end
  set_ext("MODE",           cfg.mode or "GRID")
  set_ext("NOTE_DIV",       cfg.note_div or "1/16")
  set_ext("BARS_PER_SLICE", cfg.bars_per_slice or 0)
  set_ext("CREATE_REGIONS", cfg.create_regions and "1" or "0")
  set_ext("SNAP_TO_GRID",   cfg.snap_to_grid and "1" or "0")

  set_ext("PEAKRATE",       cfg.peakrate or 1000)
  set_ext("MIN_GAP_MS",     cfg.min_gap_ms or 25)
  set_ext("THR_REL",        cfg.thr_rel or 30)
  set_ext("FADEIN_MS",      cfg.fadein_ms or 2)
  set_ext("FADEOUT_MS",     cfg.fadeout_ms or 5)
  set_ext("ZC_WINDOW_MS",   cfg.zc_window_ms or 5)
end

----------------------------------------------------------
-- GRID Slicing
----------------------------------------------------------

local function parse_note_div(note_div)
  if note_div == "1/4" then return 1.0
  elseif note_div == "1/8" then return 0.5
  elseif note_div == "1/16" then return 0.25
  elseif note_div == "1/32" then return 0.125
  end
  return 0.25
end

local function slice_item_grid(item, cfg)
  local take = r.GetActiveTake(item)
  if not take then return end

  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  local qn_start = r.TimeMap2_timeToQN(0, item_pos)
  local qn_end   = r.TimeMap2_timeToQN(0, item_pos + item_len)

  local ok_ts, ts_num, ts_den = r.TimeMap_GetTimeSigAtTime(0, item_pos)
  if not ok_ts then ts_num, ts_den = 4, 4 end
  local qn_per_bar = ts_num * (4.0 / ts_den)

  local nd_qn = parse_note_div(cfg.note_div or "1/16")
  local slice_qn = nd_qn
  if cfg.bars_per_slice and cfg.bars_per_slice > 0 then
    slice_qn = qn_per_bar * cfg.bars_per_slice
  end
  if slice_qn <= 0 then return end

  local pos_qn = qn_start + slice_qn
  local epsilon = 1e-6

  while pos_qn < (qn_end - epsilon) do
    local split_time = r.TimeMap2_QNToTime(0, pos_qn)
    local new_item = r.SplitMediaItem(item, split_time)
    if not new_item then
      break
    end
    if cfg.create_regions then
      local item_start = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_end = item_start + r.GetMediaItemInfo_Value(item, "D_LENGTH")
      local _, item_name = r.GetSetMediaItemInfo_String(item, "P_NAME", "", false)
      local reg_name = item_name ~= "" and item_name or "Slice"
      r.AddProjectMarker2(0, true, item_start, item_end, reg_name, -1)
    end
    item = new_item
    pos_qn = pos_qn + slice_qn
  end
end

----------------------------------------------------------
-- TRANSIENT-Analyse (globale Ermittlung von Attack-Zeiten)
----------------------------------------------------------

local function analyze_transients_for_item(item, cfg)
  local take = r.GetActiveTake(item)
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  if not src then return nil end

  local src_len, _ = r.GetMediaSourceLength(src)
  if not src_len or src_len <= 0 then return nil end

  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  local start_offs = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") or 0.0
  local playrate   = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") or 1.0
  if playrate <= 0 then playrate = 1.0 end

  local src_start = start_offs
  local src_end   = start_offs + item_len * playrate
  if src_end > src_len then src_end = src_len end

  local peakrate = cfg.peakrate or 1000
  if peakrate < 200 then peakrate = 200 end
  if peakrate > 8000 then peakrate = 8000 end

  local total_samples = math.floor((src_end - src_start) * peakrate + 0.5)
  if total_samples <= 0 then return nil end

  local block = 4096
  local abs_peaks = {}
  local maxpeak = 0.0
  local processed = 0

  local numch = r.GetMediaSourceNumChannels(src)
  if not numch or numch < 1 then numch = 1 end

  while processed < total_samples do
    local remaining = total_samples - processed
    local this_block = math.min(block, remaining)
    local starttime = src_start + processed / peakrate

    local retval, peaks = r.GetMediaItemTake_Peaks(take, peakrate, starttime, numch, this_block)
    if not retval or not peaks then break end

    local count = this_block * numch
    for i = 1, count, numch do
      local v = peaks[i] or 0.0
      local a = math.abs(v)
      abs_peaks[#abs_peaks+1] = a
      if a > maxpeak then maxpeak = a end
    end

    processed = processed + this_block
  end

  if #abs_peaks == 0 or maxpeak <= 0 then
    return nil
  end

  local thr_rel = cfg.thr_rel or 30
  if thr_rel < 6 then thr_rel = 6 end
  if thr_rel > 60 then thr_rel = 60 end
  local thr_amp = maxpeak * (10 ^ (-thr_rel / 20.0))

  local min_gap_ms = cfg.min_gap_ms or 25
  if min_gap_ms < 5 then min_gap_ms = 5 end
  if min_gap_ms > 200 then min_gap_ms = 200 end
  local min_gap_samples = math.floor(min_gap_ms * peakrate / 1000.0 + 0.5)
  if min_gap_samples < 1 then min_gap_samples = 1 end

  local trans_samples = {}
  local last_idx = -min_gap_samples

  for i, a in ipairs(abs_peaks) do
    if a >= thr_amp then
      if i - last_idx >= min_gap_samples then
        trans_samples[#trans_samples+1] = i
        last_idx = i
      end
    end
  end

  if #trans_samples == 0 then
    return nil
  end

  local times = {}
  for _, sidx in ipairs(trans_samples) do
    local t_rel_src = (sidx-1) / peakrate
    local t_src = src_start + t_rel_src
    local t_proj = item_pos + (t_src - start_offs) / playrate
    if t_proj > item_pos + 0.001 and t_proj < item_pos + item_len - 0.001 then
      times[#times+1] = t_proj
    end
  end

  table.sort(times)
  return times
end

----------------------------------------------------------
-- Zero-Cross-Suche um einen gegebenen Projektzeitpunkt
----------------------------------------------------------

local function find_zero_cross_around_time(item, approx_time, cfg)
  local take = r.GetActiveTake(item)
  if not take then return approx_time end
  local src = r.GetMediaItemTake_Source(take)
  if not src then return approx_time end

  local src_len, _ = r.GetMediaSourceLength(src)
  if not src_len or src_len <= 0 then return approx_time end

  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local start_offs = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") or 0.0
  local playrate   = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") or 1.0
  if playrate <= 0 then playrate = 1.0 end

  local zc_window_ms = cfg.zc_window_ms or 5
  if zc_window_ms < 1 then zc_window_ms = 1 end
  if zc_window_ms > 20 then zc_window_ms = 20 end

  local peakrate = math.min(math.max(cfg.peakrate or 2000, 1000), 8000)

  local approx_src_time = start_offs + (approx_time - item_pos) * playrate
  if approx_src_time < 0 then approx_src_time = 0 end
  if approx_src_time > src_len then approx_src_time = src_len end

  local halfwin = zc_window_ms / 1000.0
  local win_start = approx_src_time - halfwin
  local win_end   = approx_src_time + halfwin
  if win_start < 0 then win_start = 0 end
  if win_end > src_len then win_end = src_len end
  if win_end <= win_start then
    return approx_time
  end

  local samples = math.floor((win_end - win_start) * peakrate + 0.5)
  if samples < 4 then
    return approx_time
  end

  local numch = r.GetMediaSourceNumChannels(src)
  if not numch or numch < 1 then numch = 1 end

  local retval, peaks = r.GetMediaItemTake_Peaks(take, peakrate, win_start, numch, samples)
  if not retval or not peaks then
    return approx_time
  end

  local best_time = nil
  local last_v = nil

  for i = 1, samples do
    local idx = (i-1)*numch + 1
    local v = peaks[idx] or 0.0
    if last_v ~= nil then
      if (last_v <= 0 and v > 0) or (last_v >= 0 and v < 0) then
        local t_src = win_start + (i-1)/peakrate
        best_time = t_src
        break
      end
    end
    last_v = v
  end

  if not best_time then
    return approx_time
  end

  local proj_time = item_pos + (best_time - start_offs) / playrate
  return proj_time
end

----------------------------------------------------------
-- Fades anwenden
----------------------------------------------------------

local function apply_fades_to_items(items, fadein_ms, fadeout_ms)
  local fi = (fadein_ms or 2) / 1000.0
  local fo = (fadeout_ms or 5) / 1000.0
  if fi < 0 then fi = 0 end
  if fo < 0 then fo = 0 end

  for _, it in ipairs(items) do
    if it then
      r.SetMediaItemInfo_Value(it, "D_FADEINLEN", fi)
      r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", fo)
    end
  end
end

----------------------------------------------------------
-- TRANSIENT Slicing
----------------------------------------------------------

local function slice_item_transient(item, cfg, use_zc)
  local times = analyze_transients_for_item(item, cfg)
  if not times or #times == 0 then return end

  local created = { item }

  if use_zc then
    local refined = {}
    for _, t in ipairs(times) do
      refined[#refined+1] = find_zero_cross_around_time(item, t, cfg)
    end
    times = refined
    table.sort(times)
  end

  for i = #times, 1, -1 do
    local t = times[i]
    local new_item = r.SplitMediaItem(item, t)
    if new_item then
      created[#created+1] = new_item
    end
  end

  local fi = cfg.fadein_ms or 2
  local fo = cfg.fadeout_ms or 5
  if use_zc then
    fi = math.max(1, fi)
    fo = math.max(3, fo)
  end
  apply_fades_to_items(created, fi, fo)
end

----------------------------------------------------------
-- Public: Slice Selected Items
----------------------------------------------------------

function M.slice_selected_items()
  local cfg = M.read_cfg()
  local sel_cnt = r.CountSelectedMediaItems(0)
  if sel_cnt == 0 then
    r.ShowMessageBox("Keine Items selektiert.", "IFLS SliceDomain", 0)
    return
  end

  local mode = (cfg.mode or "GRID"):upper()

  r.Undo_BeginBlock2(0)

  local items = {}
  for i = 0, sel_cnt-1 do
    local it = r.GetSelectedMediaItem(0, i)
    if it then items[#items+1] = it end
  end

  if mode == "GRID" then
    for _, item in ipairs(items) do
      slice_item_grid(item, cfg)
    end
  elseif mode == "TRANSIENT" then
    for _, item in ipairs(items) do
      slice_item_transient(item, cfg, false)
    end
  elseif mode == "TRANSIENT_ZC" then
    for _, item in ipairs(items) do
      slice_item_transient(item, cfg, true)
    end
  else
    for _, item in ipairs(items) do
      slice_item_grid(item, cfg)
    end
  end

  r.Undo_EndBlock2(0, "IFLS: Slice selected items (" .. mode .. ")", -1)
end

return M
