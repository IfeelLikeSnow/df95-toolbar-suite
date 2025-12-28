-- IFLS_AudioImportDomain.lua
-- Phase 27: Audio Import / Zoom Polywave / Field Recorder Setup

local r = reaper
local M = {}

local function get_first_selected_item()
  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then return nil end
  return r.GetSelectedMediaItem(0, 0)
end

local function inspect_item_channels(item)
  if not item then return nil end
  local take = r.GetActiveTake(item)
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  if not src then return nil end

  local num_channels = r.GetMediaSourceNumChannels(src) or 2
  local length = r.GetMediaSourceLength(src)
  local sr = r.GetMediaSourceSampleRate(src)
  local file = r.GetMediaSourceFileName(src, "")

  local kind = "mono"
  if num_channels == 1 then
    kind = "mono"
  elseif num_channels == 2 then
    kind = "stereo"
  elseif num_channels > 2 then
    kind = "poly"
  end

  return {
    num_channels = num_channels,
    length = length,
    sample_rate = sr,
    file = file,
    kind = kind,
  }
end

local function create_track_at(index)
  reaper.InsertTrackAtIndex(index, true)
  local tr = reaper.GetTrack(0, index)
  return tr
end

local function get_last_track_index()
  return reaper.CountTracks(0)
end

local function set_track_name(tr, name)
  if tr and name then
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  end
end

local function set_track_color(tr, r_col, g_col, b_col)
  if not tr then return end
  if not r_col then
    reaper.SetTrackColor(tr, 0)
    return
  end
  local color = reaper.ColorToNative(r_col, g_col, b_col) | 0x1000000
  reaper.SetTrackColor(tr, color)
end

local function add_send(src_tr, dst_tr, audio_src_chan, audio_dst_chan)
  if not src_tr or not dst_tr then return -1 end
  local send_idx = reaper.CreateTrackSend(src_tr, dst_tr)
  if send_idx < 0 then return -1 end
  if audio_src_chan then
    reaper.SetTrackSendInfo_Value(src_tr, 0, send_idx, "I_SRCCHAN", audio_src_chan)
  end
  if audio_dst_chan then
    reaper.SetTrackSendInfo_Value(src_tr, 0, send_idx, "I_DSTCHAN", audio_dst_chan)
  end
  return send_idx
end

local function set_track_num_channels(tr, ch)
  if not tr then return end
  reaper.SetMediaTrackInfo_Value(tr, "I_NCHAN", ch or 2)
end

local function build_zoom_poly_setup(item, info, opts)
  opts = opts or {}
  local num_channels = info.num_channels or 4
  local base_index = get_last_track_index()

  reaper.Undo_BeginBlock()

  local parent = create_track_at(base_index)
  set_track_name(parent, opts.parent_name or "Zoom Poly (Source)")
  set_track_color(parent, 80, 80, 110)
  set_track_num_channels(parent, num_channels)

  local src_tr = reaper.GetMediaItem_Track(item)
  reaper.MoveMediaItemToTrack(item, parent)

  local mic_tracks = {}
  for ch = 1, num_channels do
    local tr = create_track_at(base_index + ch)
    local name = string.format("Zoom Mic %d", ch)
    if opts.mic_names and opts.mic_names[ch] then
      name = opts.mic_names[ch]
    end
    set_track_name(tr, name)
    set_track_color(tr, 60 + ch*10, 80 + ch*5, 90 + ch*3)
    set_track_num_channels(tr, 2)

    local src_chan = 1024 + (ch-1)
    local dst_chan = 0
    add_send(parent, tr, src_chan, dst_chan)
    mic_tracks[#mic_tracks+1] = tr
  end

  local fx_tr     = create_track_at(get_last_track_index())
  local color_tr  = create_track_at(get_last_track_index())
  local master_tr = create_track_at(get_last_track_index())

  set_track_name(fx_tr,     opts.fx_name     or "Zoom FX Bus")
  set_track_name(color_tr,  opts.color_name  or "Zoom Color Bus")
  set_track_name(master_tr, opts.master_name or "Zoom Master Bus")

  set_track_color(fx_tr,     100, 120, 160)
  set_track_color(color_tr,  120, 110, 90)
  set_track_color(master_tr, 150, 140, 80)

  set_track_num_channels(fx_tr,     2)
  set_track_num_channels(color_tr,  2)
  set_track_num_channels(master_tr, 2)

  for _, tr in ipairs(mic_tracks) do
    add_send(tr, fx_tr, -1, 0)
  end
  add_send(fx_tr, color_tr, -1, 0)
  add_send(color_tr, master_tr, -1, 0)

  reaper.TrackList_AdjustWindows(false)
  reaper.Undo_EndBlock("IFLS: Build Zoom Poly Setup", -1)
end

local function build_fieldrec_setup(item, info, opts)
  opts = opts or {}
  local base_index = get_last_track_index()

  reaper.Undo_BeginBlock()

  local main_tr = create_track_at(base_index)
  set_track_name(main_tr, opts.main_name or "FieldRec Main")
  set_track_color(main_tr, 70, 90, 70)
  set_track_num_channels(main_tr, info.num_channels or 2)

  reaper.MoveMediaItemToTrack(item, main_tr)

  local fx_tr     = create_track_at(get_last_track_index())
  local color_tr  = create_track_at(get_last_track_index())
  local master_tr = create_track_at(get_last_track_index())

  set_track_name(fx_tr,     opts.fx_name     or "Field FX Bus")
  set_track_name(color_tr,  opts.color_name  or "Field Color Bus")
  set_track_name(master_tr, opts.master_name or "Field Master Bus")

  set_track_color(fx_tr,     110, 130, 100)
  set_track_color(color_tr,  130, 120, 90)
  set_track_color(master_tr, 160, 150, 100)

  set_track_num_channels(fx_tr,     2)
  set_track_num_channels(color_tr,  2)
  set_track_num_channels(master_tr, 2)

  add_send(main_tr,  fx_tr,    -1, 0)
  add_send(fx_tr,    color_tr, -1, 0)
  add_send(color_tr, master_tr,-1, 0)

  reaper.TrackList_AdjustWindows(false)
  reaper.Undo_EndBlock("IFLS: Build Field Recorder Setup", -1)
end

function M.analyze_selected_item()
  local item = get_first_selected_item()
  if not item then return nil, "Kein Item selektiert." end
  local info = inspect_item_channels(item)
  if not info then
    return nil, "Konnte Medienquelle nicht auslesen."
  end
  return { item = item, info = info }, nil
end

function M.build_zoom_setup_from_selection()
  local res, err = M.analyze_selected_item()
  if not res then return false, err end
  local item = res.item
  local info = res.info
  if info.kind ~= "poly" then
    return false, "Ausgewähltes Item ist keine Polywave (Kanäle: " .. tostring(info.num_channels) .. ")."
  end
  build_zoom_poly_setup(item, info, {})
  return true
end

function M.build_fieldrec_setup_from_selection()
  local res, err = M.analyze_selected_item()
  if not res then return false, err end
  local item = res.item
  local info = res.info
  if info.kind == "poly" then
    return false, "Ausgewähltes Item ist Polywave – nutze dafür das Zoom-Setup."
  end
  build_fieldrec_setup(item, info, {})
  return true
end

return M
