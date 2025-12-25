\
-- @description DF95_V170 Fieldrec Fusion Export – MicFX / BusChain GUI (Slices & Full, SampleDB Logging)
-- @version 1.0
-- @author DF95
-- @about
--   Ein zentrales Export-Tool für Fieldrecordings:
--     * Du wählst alle relevanten Mic-Tracks (z.B. XM8500, MD400, Zoom-F6-Kanäle).
--     * Script erkennt Slices aus den Items (vertikal passende Samples).
--     * Du wählst:
--         - Bereich:
--             · Slices innerhalb aktueller Time Selection (oder alle Slices)
--             · Gesamter Bereich (min..max aller Slices)
--         - Kette:
--             · Nur Mic-FX (MicFX-Summe, KEINE Bus-/Master-FX)
--             · Komplette Kette (MicFX → FX-Bus → Color-Bus → Master-Bus → REAPER-Master-FX)
--     * Exportiert entsprechend:
--         - Slices: pro Slice eine Datei
--         - Full: einen kompletten Export
--     * Trägt jeden Export in DF95_SampleDB_Multi_UCS.json ein:
--         export_path, export_slice_index, mic_list, samplerate, bitdepth, naming_preset, ai_tags, ...
--
--   Voraussetzungen:
--     * ReaImGui (über ReaPack).
--     * Optional: DF95_Export_Core.lua für UCS/Naming Tagging.
--
--   Hinweis zur Interpretation deiner Vorgabe:
--     "ausgewählte Samples" wird hier umgesetzt als:
--       · Wenn Time Selection existiert: nur Slices, die diese TS schneiden.
--       · Wenn keine Time Selection existiert: alle Slices.

local r = reaper

------------------------------------------------------------
-- Basics: Pfade / JSON
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function ensure_dir(path)
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(path, 0)
    return true
  else
    if sep == "\\" then
      os.execute(string.format('mkdir "%s"', path))
    else
      os.execute(string.format('mkdir -p "%s"', path))
    end
    return true
  end
end

local function get_sampledb_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  ensure_dir(dir)
  return dir, join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function json_decode(text)
  if not text or text == "" then return nil end
  local f, err = load("return " .. text, "json", "t", {})
  if not f then return nil end
  local ok, res = pcall(f)
  if not ok then return nil end
  return res
end

local function json_encode_simple(v, indent)
  indent = indent or ""
  local function esc(s)
    s = tostring(s or "")
    s = s:gsub("\\","\\\\"):gsub("\"","\\\""):gsub("\n","\\n")
    return s
  end
  local function enc(val, ind)
    ind = ind or ""
    local next_ind = ind .. "  "
    if type(val) == "table" then
      if #val > 0 then
        local parts = {"[\n"}
        for i, item in ipairs(val) do
          parts[#parts+1] = next_ind .. enc(item, next_ind)
          if i < #val then parts[#parts+1] = "," end
          parts[#parts+1] = "\n"
        end
        parts[#parts+1] = ind .. "]"
        return table.concat(parts)
      else
        local parts = {"{\n"}
        local first = true
        for k, item in pairs(val) do
          if not first then parts[#parts+1] = ",\n" end
          first = false
          parts[#parts+1] = next_ind .. "\"" .. esc(k) .. "\": " .. enc(item, next_ind)
        end
        parts[#parts+1] = "\n" .. ind .. "}"
        return table.concat(parts)
      end
    elseif type(val) == "string" then
      return "\"" .. esc(val) .. "\""
    elseif type(val) == "number" then
      return tostring(val)
    elseif type(val) == "boolean" then
      return val and "true" or "false"
    else
      return "null"
    end
  end
  return enc(v, indent)
end

local function load_sampledb()
  local dir, path = get_sampledb_path()
  local f = io.open(path, "r")
  if not f then
    return {
      version = "DF95_MultiUCS",
      created = os.date("%Y-%m-%d %H:%M:%S"),
      items   = {},
      exports = {},
    }, path
  end
  local txt = f:read("*all")
  f:close()
  local db = json_decode(txt)
  if type(db) ~= "table" then
    db = {version="DF95_MultiUCS", items={}, exports={}}
  end
  if type(db.items) ~= "table" then db.items = {} end
  if type(db.exports) ~= "table" then db.exports = {} end
  return db, path
end

local function save_sampledb(db, path)
  local f = io.open(path, "w")
  if not f then
    r.ShowMessageBox("Konnte SampleDB nicht schreiben:\n"..tostring(path),
      "DF95 Fieldrec Fusion Export GUI", 0)
    return false
  end
  f:write(json_encode_simple(db, ""))
  f:close()
  return true
end

------------------------------------------------------------
-- Projekt / Zeit / Format
------------------------------------------------------------

local function get_project()
  return 0
end

local function get_project_path_and_name()
  local _, proj_fn = r.EnumProjects(-1, "")
  local proj_path = r.GetProjectPath("")
  local name = proj_fn:match("([^/\\]+)%.rpp$") or proj_fn
  return proj_path, name
end

local function get_time_selection()
  local start_time, end_time = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if not start_time or not end_time or end_time <= start_time then
    return nil, nil
  end
  return start_time, end_time
end

local function set_time_selection(start_time, end_time)
  r.GetSet_LoopTimeRange(true, false, start_time, end_time, false)
end

-- WAV-Bittiefe
local function get_bits_from_wav(path)
  if not path or path == "" then return nil end
  local f = io.open(path, "rb")
  if not f then return nil end
  local header = f:read(64)
  f:close()
  if not header or #header < 36 then return nil end
  local riff = header:sub(1,4)
  if riff ~= "RIFF" and riff ~= "RF64" then
    return nil
  end
  local b1, b2 = header:byte(35, 36)
  if not b1 or not b2 then return nil end
  local bits = b1 + b2 * 256
  if bits <= 0 then return nil end
  return bits
end

local function bits_to_reaper_bps(bits)
  if not bits or bits <= 0 then return nil end
  if bits <= 16 then
    return 16
  elseif bits <= 24 then
    return 24
  else
    return 3 -- 32-bit float
  end
end

local function collect_format_stats_from_tracks(tracks)
  local formats = {}
  local min_sr, max_sr = nil, nil
  local min_bits, max_bits = nil, nil

  for _, tr in ipairs(tracks) do
    local item_count = r.CountTrackMediaItems(tr)
    for ii = 0, item_count-1 do
      local item = r.GetTrackMediaItem(tr, ii)
      local take = r.GetActiveTake(item)
      if take and not r.TakeIsMIDI(take) then
        local src = r.GetMediaItemTake_Source(take)
        if src then
          local sr = r.GetMediaSourceSampleRate(src)
          local path = r.GetMediaSourceFileName(src, "")
          local bits = path and get_bits_from_wav(path) or nil

          if sr and sr > 0 then
            if not min_sr or sr < min_sr then min_sr = sr end
            if not max_sr or sr > max_sr then max_sr = sr end
          end
          if bits and bits > 0 then
            if not min_bits or bits < min_bits then min_bits = bits end
            if not max_bits or bits > max_bits then max_bits = bits end
          end

          local key = string.format("%s_%s", tostring(sr or "?"), tostring(bits or "?"))
          formats[key] = (formats[key] or 0) + 1
        end
      end
    end
  end

  return {
    formats  = formats,
    min_sr   = min_sr,
    max_sr   = max_sr,
    min_bits = min_bits,
    max_bits = max_bits,
  }
end

------------------------------------------------------------
-- Slice-Erkennung
------------------------------------------------------------

local function collect_slices_from_tracks(tracks)
  local segments = {}
  for _, tr in ipairs(tracks) do
    local item_count = r.CountTrackMediaItems(tr)
    for ii = 0, item_count-1 do
      local item = r.GetTrackMediaItem(tr, ii)
      local s = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      local e = s + len
      if e > s then
        segments[#segments+1] = {start = s, stop = e}
      end
    end
  end
  if #segments == 0 then return {} end

  table.sort(segments, function(a,b) return a.start < b.start end)

  local slices = {}
  local current = {start = segments[1].start, stop = segments[1].stop}
  local eps = 0.0005

  for i = 2, #segments do
    local seg = segments[i]
    if seg.start <= current.stop + eps then
      if seg.stop > current.stop then
        current.stop = seg.stop
      end
    else
      slices[#slices+1] = current
      current = {start = seg.start, stop = seg.stop}
    end
  end
  slices[#slices+1] = current

  return slices
end

local function filter_slices_by_timesel(slices, ts_start, ts_end)
  if not ts_start or not ts_end or ts_end <= ts_start then
    return slices
  end
  local out = {}
  local eps = 0.0005
  for _, sl in ipairs(slices) do
    if not (sl.stop <= ts_start + eps or sl.start >= ts_end - eps) then
      out[#out+1] = sl
    end
  end
  return out
end

------------------------------------------------------------
-- Bus-Kette (FX / Color / Master) für BusChain-Mode
------------------------------------------------------------

local FX_BUS_NAME     = "[DF95] FX Bus"
local COLOR_BUS_NAME  = "[DF95] Color Bus"
local MASTER_BUS_NAME = "[DF95] Master Bus"

local function find_track_by_name(name)
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    local _, tr_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if tr_name == name then
      return tr, i
    end
  end
  return nil, -1
end

local function ensure_bus_track(name)
  local tr, idx = find_track_by_name(name)
  if tr then return tr, idx end
  local cnt = r.CountTracks(0)
  r.InsertTrackAtIndex(cnt, false)
  r.TrackList_AdjustWindows(false)
  tr = r.GetTrack(0, cnt)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr, cnt
end

local function ensure_bus_chain()
  local fx_tr, fx_idx         = ensure_bus_track(FX_BUS_NAME)
  local color_tr, color_idx   = ensure_bus_track(COLOR_BUS_NAME)
  local master_tr, master_idx = ensure_bus_track(MASTER_BUS_NAME)

  r.SetMediaTrackInfo_Value(fx_tr, "B_MAINSEND", 0)
  r.SetMediaTrackInfo_Value(color_tr, "B_MAINSEND", 0)
  r.SetMediaTrackInfo_Value(master_tr, "B_MAINSEND", 1)

  local function ensure_send(src_tr, dest_tr)
    local send_count = r.GetTrackNumSends(src_tr, 0)
    for i = 0, send_count-1 do
      local dest = r.GetTrackSendInfo_Value(src_tr, 0, i, "P_DESTTRACK")
      if dest == dest_tr then
        return i
      end
    end
    local idx = r.CreateTrackSend(src_tr, dest_tr)
    r.SetTrackSendInfo_Value(src_tr, 0, idx, "I_SENDMODE", 0)
    return idx
  end

  ensure_send(fx_tr, color_tr)
  ensure_send(color_tr, master_tr)

  return fx_tr, color_tr, master_tr
end

------------------------------------------------------------
-- Fusion-Bus (nur MicFX-Mode)
------------------------------------------------------------

local FUSION_BUS_NAME = "[DF95] Fieldrec Fusion Bus"

local function create_fusion_bus_track()
  local cnt = r.CountTracks(0)
  r.InsertTrackAtIndex(cnt, false)
  r.TrackList_AdjustWindows(false)
  local tr = r.GetTrack(0, cnt)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", FUSION_BUS_NAME, true)
  r.SetMediaTrackInfo_Value(tr, "B_MAINSEND", 0) -- kein Master
  return tr
end

------------------------------------------------------------
-- Routing / Solo / Render-Settings Backup
------------------------------------------------------------

local function save_render_settings()
  local proj = get_project()
  local function gss(key)
    local _, val = r.GetSetProjectInfo_String(proj, key, "", false)
    return val
  end
  return {
    RENDER_FILE      = gss("RENDER_FILE"),
    RENDER_PATTERN   = gss("RENDER_PATTERN"),
    RENDER_BOUNDS    = gss("RENDER_BOUNDSFLAG"),
    RENDER_SRATE     = gss("RENDER_SRATE"),
    RENDER_SRATE_USE = gss("RENDER_SRATE_USE"),
    RENDER_BPS       = gss("RENDER_BPS"),
    RENDER_CHANNELS  = gss("RENDER_CHANNELS"),
    RENDER_DITHER    = gss("RENDER_DITHER"),
    RENDER_ADDTOPRJ  = gss("RENDER_ADDTOPROJ"),
    RENDER_STEMS     = gss("RENDER_STEMS"),
  }
end

local function restore_render_settings(saved)
  if not saved then return end
  local proj = get_project()
  local function sss(key, val)
    r.GetSetProjectInfo_String(proj, key, val or "", true)
  end
  sss("RENDER_FILE",       saved.RENDER_FILE)
  sss("RENDER_PATTERN",    saved.RENDER_PATTERN)
  sss("RENDER_BOUNDSFLAG", saved.RENDER_BOUNDS)
  sss("RENDER_SRATE",      saved.RENDER_SRATE)
  sss("RENDER_SRATE_USE",  saved.RENDER_SRATE_USE)
  sss("RENDER_BPS",        saved.RENDER_BPS)
  sss("RENDER_CHANNELS",   saved.RENDER_CHANNELS)
  sss("RENDER_DITHER",     saved.RENDER_DITHER)
  sss("RENDER_ADDTOPROJ",  saved.RENDER_ADDTOPROJ)
  sss("RENDER_STEMS",      saved.RENDER_STEMS)
end

local function save_solo_states()
  local states = {}
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    states[i] = r.GetMediaTrackInfo_Value(tr, "I_SOLO")
  end
  return states
end

local function restore_solo_states(states)
  if not states then return end
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    local v = states[i]
    if v ~= nil then
      r.SetMediaTrackInfo_Value(tr, "I_SOLO", v)
    end
  end
end

local function set_solo_for_tracks(track_set)
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    if track_set[tr] then
      r.SetMediaTrackInfo_Value(tr, "I_SOLO", 1)
    else
      r.SetMediaTrackInfo_Value(tr, "I_SOLO", 0)
    end
  end
end

local function backup_mic_routing(mic_tracks)
  local backup = {}
  for _, tr in ipairs(mic_tracks) do
    local info = {}
    info.main_send = r.GetMediaTrackInfo_Value(tr, "B_MAINSEND")
    info.send_count = r.GetTrackNumSends(tr, 0)
    backup[tr] = info
  end
  return backup
end

local function restore_mic_routing(mic_tracks, backup)
  for _, tr in ipairs(mic_tracks) do
    local info = backup[tr]
    if info then
      r.SetMediaTrackInfo_Value(tr, "B_MAINSEND", info.main_send or 1)
      local cur = r.GetTrackNumSends(tr, 0)
      for i = cur-1, (info.send_count or 0), -1 do
        r.RemoveTrackSend(tr, 0, i)
      end
    end
  end
end

local function add_send(src_tr, dest_tr)
  local send_count = r.GetTrackNumSends(src_tr, 0)
  for i = 0, send_count-1 do
    local d = r.GetTrackSendInfo_Value(src_tr, 0, i, "P_DESTTRACK")
    if d == dest_tr then return i end
  end
  local idx = r.CreateTrackSend(src_tr, dest_tr)
  r.SetTrackSendInfo_Value(src_tr, 0, idx, "I_SENDMODE", 0)
  return idx
end

------------------------------------------------------------
-- Naming via DF95 Export Core
------------------------------------------------------------

local function build_render_basename(naming_preset, mode_suffix)
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  local script_dir = script_path and script_path:match("^(.*[\\/])") or ""
  local ok, ExportCore = pcall(dofile, script_dir .. "DF95_Export_Core.lua")
  local proj_dir, proj_name = get_project_path_and_name()
  local dest_root = join_path(proj_dir, "DF95_EXPORT")

  if not ok or type(ExportCore) ~= "table" or type(ExportCore.BuildRenderBasename) ~= "function" then
    local ts = os.date("%Y%m%d_%H%M%S")
    return join_path(dest_root, string.format("DF95_FieldrecFusion_%s_%s_%s", proj_name or "Project", mode_suffix or "Mode", ts))
  end

  local subtype = "Fieldrec_MicSum"
  if mode_suffix == "MicFX_Slices" then
    subtype = "Fieldrec_MicSum_Slices_MicFX"
  elseif mode_suffix == "MicFX_Full" then
    subtype = "Fieldrec_MicSum_Full_MicFX"
  elseif mode_suffix == "BusChain_Slices" then
    subtype = "Fieldrec_MicSum_Slices_BusChain"
  elseif mode_suffix == "BusChain_Full" then
    subtype = "Fieldrec_MicSum_Full_BusChain"
  end

  if naming_preset == "EMF" then
    subtype = subtype .. "_EMF"
  elseif naming_preset == "RoomTone" then
    subtype = subtype .. "_RoomTone"
  end

  local opts = {
    dest_root = dest_root,
    category  = "Fieldrec_Fusion",
    subtype   = subtype,
  }

  local tags = {
    role          = "FieldrecFusion",
    source        = "DF95_FieldrecEngine",
    fxflavor      = mode_suffix or "Fusion",
    ucs_catid     = nil,
    ucs_fxname    = nil,
    ucs_creatorid = nil,
    ucs_sourceid  = nil,
  }

  local bpm = 0
  local index = 1

  return ExportCore.BuildRenderBasename(opts, index, bpm, tags)
end

------------------------------------------------------------
-- SampleDB Logging
------------------------------------------------------------

local function append_export_record(db, args)
  db.exports = db.exports or {}
  db.exports[#db.exports+1] = {
    export_path       = args.path,
    export_slice_index= args.slice_index,
    mic_list          = args.mic_list,
    samplerate        = args.samplerate,
    bitdepth          = args.bitdepth,
    naming_preset     = args.naming_preset,
    ai_tags           = args.ai_tags,
    created           = os.date("%Y-%m-%d %H:%M:%S"),
    project           = args.project_name,
    mode              = args.mode,
  }
end

------------------------------------------------------------
-- Export-Implementierung
------------------------------------------------------------

local function get_mic_names(mic_tracks)
  local mic_names = {}
  for _, tr in ipairs(mic_tracks) do
    local _, n = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    mic_names[#mic_names+1] = n ~= "" and n or "(unnamed)"
  end
  return mic_names
end

local function parse_ai_tags(ai_tags_str)
  local out = {}
  if not ai_tags_str or ai_tags_str == "" then return out end
  for tag in string.gmatch(ai_tags_str, "([^,]+)") do
    local t = tag:gsub("^%s+",""):gsub("%s+$","")
    if t ~= "" then out[#out+1] = t end
  end
  return out
end

-- MicFX-Mode: Fusion-Bus (kein Master, keine Bus-FX)

local function export_micfx_mode(mic_tracks, slices, full_mode, naming_preset, ai_tags)
  if #mic_tracks == 0 then return end
  if not full_mode and #slices == 0 then
    r.ShowMessageBox("Keine Slices gefunden.", "DF95 Fieldrec Fusion Export – MicFX", 0)
    return
  end

  local stats = collect_format_stats_from_tracks(mic_tracks)
  local formats = stats.formats or {}
  local format_count = 0
  for _ in pairs(formats) do format_count = format_count + 1 end

  -- Formatlogik: immer nach bestehender Hertzzahl/Bitrate,
  -- d.h. wir orientieren uns an den KLEINSTEN Werten
  local target_sr = stats.min_sr
  local target_bits = stats.min_bits
  local mode_desc = ""

  if format_count == 0 or not stats.min_sr or not stats.min_bits then
    local proj = get_project()
    local _, proj_sr = r.GetSetProjectInfo_String(proj, "RENDER_SRATE", "", false)
    target_sr = tonumber(proj_sr) or 48000
    target_bits = 24
    mode_desc = "Keine Dateiformat-Infos gefunden – fallback auf Projektformat."
  elseif format_count == 1 and stats.min_sr == stats.max_sr and stats.min_bits == stats.max_bits then
    mode_desc = string.format("Export im Originalformat: %.0f Hz / %d Bit (einheitliche Quellen).", stats.min_sr or 0, stats.min_bits or 0)
  else
    mode_desc = string.format("Mehrere Formate erkannt (%d Kombinationen). Export in KLEINSTER SR/Bittiefe: %.0f Hz / %d Bit.",
      format_count, stats.min_sr or 0, stats.min_bits or 0)
  end

  local proj = get_project()
  local saved_render = save_render_settings()
  local saved_ts_start, saved_ts_end = get_time_selection()
  local had_ts = saved_ts_start ~= nil
  local saved_solo = save_solo_states()

  local fusion_bus = create_fusion_bus_track()
  local mic_backup = backup_mic_routing(mic_tracks)

  for _, tr in ipairs(mic_tracks) do
    add_send(tr, fusion_bus)
  end

  local bps = bits_to_reaper_bps(target_bits)
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true)
RENDER_BOUNDSFLAG", "1", true)

  if target_sr and target_sr > 0 then
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE", tostring(math.floor(target_sr + 0.5)), true)
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE_USE", "1", true)
  end
  if bps then
    r.GetSetProjectInfo_String(proj, "RENDER_BPS", tostring(bps), true)
  end

  r.GetSetProjectInfo_String(proj, "RENDER_CHANNELS", "2", true)
  r.GetSetProjectInfo_String(proj, "RENDER_DITHER", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_ADDTOPROJ", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_STEMS", "1", true) -- Stem: selected tracks

  local mode_suffix = full_mode and "MicFX_Full" or "MicFX_Slices"
  local base = build_render_basename(naming_preset, mode_suffix)
  local _, proj_name = get_project_path_and_name()
  local mic_names = get_mic_names(mic_tracks)
  local ai_tags_arr = parse_ai_tags(ai_tags)

  local db, db_path = load_sampledb()

  r.Undo_BeginBlock()

  local function do_render_for_slice(slice_idx, slice_start, slice_stop)
    set_time_selection(slice_start, slice_stop)

    local slice_base = full_mode and (base .. "_FULL") or string.format("%s_S%03d", base, slice_idx)
    r.GetSetProjectInfo_String(proj, "RENDER_FILE", slice_base, true)

    local cnt = r.CountTracks(0)
    for i = 0, cnt-1 do
      local tr = r.GetTrack(0, i)
      r.SetTrackSelected(tr, tr == fusion_bus)
    end

    local set = {}
    set[fusion_bus] = true
    set_solo_for_tracks(set)

    r.Main_OnCommand(41824, 0)

    append_export_record(db, {
      path          = slice_base .. ".wav",
      slice_index   = slice_idx,
      mic_list      = mic_names,
      samplerate    = target_sr,
      bitdepth      = target_bits,
      naming_preset = naming_preset,
      ai_tags       = ai_tags_arr,
      project_name  = proj_name,
      mode          = mode_suffix,
    })
  end

  if full_mode then
    local min_s, max_e = nil, nil
    for _, sl in ipairs(slices) do
      if not min_s or sl.start < min_s then min_s = sl.start end
      if not max_e or sl.stop > max_e then max_e = sl.stop end
    end
    if min_s and max_e and max_e > min_s then
      do_render_for_slice(0, min_s, max_e)
    end
  else
    for idx, sl in ipairs(slices) do
      do_render_for_slice(idx, sl.start, sl.stop)
    end
  end

  -- Cleanup
  local cnt = r.CountTracks(0)
  for i = cnt-1, 0, -1 do
    local tr = r.GetTrack(0, i)
    if tr == fusion_bus then
      r.DeleteTrack(tr)
      break
    end
  end

  restore_solo_states(saved_solo)
  restore_mic_routing(mic_tracks, mic_backup)
  restore_render_settings(saved_render)
  if had_ts and saved_ts_start and saved_ts_end then
    set_time_selection(saved_ts_start, saved_ts_end)
  else
    set_time_selection(0,0)
  end

  save_sampledb(db, db_path)

  r.Undo_EndBlock("DF95 Fieldrec Fusion Export – MicFX ("..(full_mode and "Full" or "Slices")..")", -1)

  r.ShowMessageBox(
    string.format(
      "Fieldrec Fusion Export (MicFX) abgeschlossen.\n\n%s\nSlices: %d\nSampleDB: %s",
      mode_desc,
      full_mode and 1 or #slices,
      db_path
    ),
    "DF95 Fieldrec Fusion Export – MicFX",
    0
  )
end

-- BusChain-Mode: MicFX → FX/Color/Master-Busse → Reaper-Master (inkl. Master-FX)

local function export_buschain_mode(mic_tracks, slices, full_mode, naming_preset, ai_tags)
  if #mic_tracks == 0 then return end
  if not full_mode and #slices == 0 then
    r.ShowMessageBox("Keine Slices gefunden.", "DF95 Fieldrec Fusion Export – BusChain", 0)
    return
  end

  local stats = collect_format_stats_from_tracks(mic_tracks)
  local formats = stats.formats or {}
  local format_count = 0
  for _ in pairs(formats) do format_count = format_count + 1 end

  -- Formatlogik: immer nach bestehender Hertzzahl/Bitrate
  -- → orientiere dich an den KLEINSTEN Werten, damit nichts hochgesampelt wird.
  local target_sr = stats.min_sr
  local target_bits = stats.min_bits
  local mode_desc = ""

  if format_count == 0 or not stats.min_sr or not stats.min_bits then
    local proj = get_project()
    local _, proj_sr = r.GetSetProjectInfo_String(proj, "RENDER_SRATE", "", false)
    target_sr = tonumber(proj_sr) or 48000
    target_bits = 24
    mode_desc = "Keine Dateiformat-Infos gefunden – fallback auf Projektformat."
  elseif format_count == 1 and stats.min_sr == stats.max_sr and stats.min_bits == stats.max_bits then
    mode_desc = string.format("Export im Originalformat: %.0f Hz / %d Bit (einheitliche Quellen).", stats.min_sr or 0, stats.min_bits or 0)
  else
    mode_desc = string.format("Mehrere Formate erkannt (%d Kombinationen). Export in KLEINSTER SR/Bittiefe: %.0f Hz / %d Bit.",
      format_count, stats.min_sr or 0, stats.min_bits or 0)
  end

  local proj = get_project()
  local saved_render = save_render_settings()
  local saved_ts_start, saved_ts_end = get_time_selection()
  local had_ts = saved_ts_start ~= nil
  local saved_solo = save_solo_states()

  local fx_tr, color_tr, master_tr = ensure_bus_chain()
  local mic_backup = backup_mic_routing(mic_tracks)

  for _, tr in ipairs(mic_tracks) do
    r.SetMediaTrackInfo_Value(tr, "B_MAINSEND", 0)
    add_send(tr, fx_tr)
  end

  local bps = bits_to_reaper_bps(target_bits)
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true)
_reaper_bps(target_bits)
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true)
  if target_sr and target_sr > 0 then
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE", tostring(math.floor(target_sr + 0.5)), true)
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE_USE", "1", true)
  end
  if bps then
    r.GetSetProjectInfo_String(proj, "RENDER_BPS", tostring(bps), true)
  end

  r.GetSetProjectInfo_String(proj, "RENDER_CHANNELS", "2", true)
  r.GetSetProjectInfo_String(proj, "RENDER_DITHER", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_ADDTOPROJ", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_STEMS", "0", true) -- Master

  local mode_suffix = full_mode and "BusChain_Full" or "BusChain_Slices"
  local base = build_render_basename(naming_preset, mode_suffix)
  local _, proj_name = get_project_path_and_name()
  local mic_names = get_mic_names(mic_tracks)
  local ai_tags_arr = parse_ai_tags(ai_tags)

  local db, db_path = load_sampledb()

  r.Undo_BeginBlock()

  local function do_render_for_slice(slice_idx, slice_start, slice_stop)
    set_time_selection(slice_start, slice_stop)
    local slice_base = full_mode and (base .. "_FULL") or string.format("%s_S%03d", base, slice_idx)
    r.GetSetProjectInfo_String(proj, "RENDER_FILE", slice_base, true)

    local set = {}
    for _, tr in ipairs(mic_tracks) do set[tr] = true end
    set[fx_tr] = true
    set[color_tr] = true
    set[master_tr] = true
    set_solo_for_tracks(set)

    r.Main_OnCommand(41824, 0)

    append_export_record(db, {
      path          = slice_base .. ".wav",
      slice_index   = slice_idx,
      mic_list      = mic_names,
      samplerate    = target_sr,
      bitdepth      = target_bits,
      naming_preset = naming_preset,
      ai_tags       = ai_tags_arr,
      project_name  = proj_name,
      mode          = mode_suffix,
    })
  end

  if full_mode then
    local min_s, max_e = nil, nil
    for _, sl in ipairs(slices) do
      if not min_s or sl.start < min_s then min_s = sl.start end
      if not max_e or sl.stop > max_e then max_e = sl.stop end
    end
    if min_s and max_e and max_e > min_s then
      do_render_for_slice(0, min_s, max_e)
    end
  else
    for idx, sl in ipairs(slices) do
      do_render_for_slice(idx, sl.start, sl.stop)
    end
  end

  restore_solo_states(saved_solo)
  restore_mic_routing(mic_tracks, mic_backup)
  restore_render_settings(saved_render)
  if had_ts and saved_ts_start and saved_ts_end then
    set_time_selection(saved_ts_start, saved_ts_end)
  else
    set_time_selection(0,0)
  end

  save_sampledb(db, db_path)

  r.Undo_EndBlock("DF95 Fieldrec Fusion Export – BusChain ("..(full_mode and "Full" or "Slices")..")", -1)

  r.ShowMessageBox(
    string.format(
      "Fieldrec Fusion Export (BusChain) abgeschlossen.\n\n%s\nSlices: %d\nSampleDB: %s",
      mode_desc,
      full_mode and 1 or #slices,
      db_path
    ),
    "DF95 Fieldrec Fusion Export – BusChain",
    0
  )
end

------------------------------------------------------------
-- ImGui GUI
------------------------------------------------------------

local ctx = nil
local gui_naming_idx = 1
local naming_presets = {"Default","EMF","RoomTone"}
local gui_ai_tags = ""
local scope_mode = 0  -- 0 = ausgewählte Slices (TS), 1 = kompletter Bereich
local chain_mode = 0  -- 0 = nur MicFX, 1 = BusChain
local analyzed = false
local mic_tracks_cache = {}
local slice_count_cache = 0
local format_desc_cache = ""

local function ensure_imgui()
  if ctx and r.ImGui_ValidatePtr and r.ImGui_ValidatePtr(ctx, "ImGui_Context*") then
    return ctx
  end
  if not r.ImGui_CreateContext then
    r.ShowMessageBox("ReaImGui nicht gefunden. Bitte über ReaPack installieren.",
      "DF95 Fieldrec Fusion Export GUI", 0)
    return nil
  end
  ctx = r.ImGui_CreateContext("DF95 Fieldrec Fusion Export – Fusion GUI")
  return ctx
end

local function analyze_selection()
  mic_tracks_cache = {}
  local num_sel = r.CountSelectedTracks(0)
  for i = 0, num_sel-1 do
    mic_tracks_cache[#mic_tracks_cache+1] = r.GetSelectedTrack(0, i)
  end

  if #mic_tracks_cache == 0 then
    slice_count_cache = 0
    format_desc_cache = "Keine Tracks selektiert."
    return
  end

  local slices = collect_slices_from_tracks(mic_tracks_cache)
  slice_count_cache = #slices

  local stats = collect_format_stats_from_tracks(mic_tracks_cache)
  if not stats.max_sr or not stats.max_bits then
    format_desc_cache = "Format: unbekannt (fallback auf Projektformat)."
  else
    local fmt_count = 0
    for _ in pairs(stats.formats or {}) do fmt_count = fmt_count + 1 end
    format_desc_cache = string.format("Format: bis %.0f Hz / %d Bit (%d Kombinationen).",
      stats.max_sr or 0, stats.max_bits or 0, fmt_count)
  end
end

local function loop()
  local c = ensure_imgui()
  if not c then return end

  r.ImGui_SetNextWindowSize(c, 580, 280, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.

------------------------------------------------------------
-- Modulation Panel Integration (DF95_Modulation_Panel_Hub_ImGui)
------------------------------------------------------------

local function open_modulation_panel_for_current_track()
  -- Dieses Script geht davon aus, dass DF95_Modulation_Panel_Hub_ImGui.lua
  -- im selben DF95-Script-Ordner liegt wie dieses GUI.
  local _, this_script_path = reaper.get_action_context()
  if not this_script_path or this_script_path == "" then
    return
  end
  local sep = package.config:sub(1,1)
  local dir = this_script_path:match("^(.*"..sep..")") or ""
  local mod_path = dir .. "DF95_Modulation_Panel_Hub_ImGui.lua"
  local f = io.open(mod_path, "r")
  if not f then
    reaper.ShowMessageBox(
      "Konnte DF95_Modulation_Panel_Hub_ImGui.lua nicht finden.\n" ..
      "Erwarte Pfad:\n" .. tostring(mod_path),
      "DF95 Fieldrec Fusion Export",
      0
    )
    return
  end
  f:close()
  dofile(mod_path)
end

ImGui_Begin(c, "DF95 Fieldrec Fusion Export – MicFX / BusChain", true)
  if visible then
    if not analyzed then
      analyze_selection()
      analyzed = true
    end

    local num_sel = #mic_tracks_cache

    r.ImGui_Text(c, "Fieldrec-Fusionsset Export:")
    r.ImGui_Separator(c)

    r.ImGui_Text(c, string.format("Selektierte Mic-Tracks: %d", num_sel))
    if num_sel > 0 then
      r.ImGui_BulletText(c, string.format("Erkannte Slices (Samples): %d", slice_count_cache))
      r.ImGui_BulletText(c, format_desc_cache)
    else
      r.ImGui_TextColored(c, 1,0.4,0.4,1, "Bitte zuerst alle relevanten Mic-Tracks selektieren.")
    end

    r.ImGui_Separator(c)
    r.ImGui_Text(c, "Bereich:")
    if r.ImGui_RadioButton(c, "Ausgewählte Samples (nach Time Selection)", scope_mode == 0) then
      scope_mode = 0
    end
    if r.ImGui_RadioButton(c, "Kompletter Bereich (alle Slices)", scope_mode == 1) then
      scope_mode = 1
    end

    r.ImGui_Separator(c)
    r.ImGui_Text(c, "Kette:")
    if r.ImGui_RadioButton(c, "Nur Mic-FX (keine Bus-/Master-FX)", chain_mode == 0) then
      chain_mode = 0
    end
    if r.ImGui_RadioButton(c, "Mic-FX + FX-Bus + Color-Bus + Master-Bus + REAPER-Master", chain_mode == 1) then
      chain_mode = 1
    end

    r.ImGui_Separator(c)
    r.ImGui_Text(c, "Naming-Preset:")
    local changed, new_idx = r.ImGui_Combo(c, "##NamingPreset", gui_naming_idx-1, table.concat(naming_presets, "\0").."\0")
    if changed then gui_naming_idx = (new_idx or 0) + 1 end

    r.ImGui_Text(c, "AI Tag Autofill (kommagetrennt, z.B. \"roomtone, kitchen, close_mic\"):")
    local ok_i, new_txt = r.ImGui_InputText(c, "##AITags", gui_ai_tags or "", 512)
    if ok_i then gui_ai_tags = new_txt end

    r.ImGui_SameLine(c)
    if r.ImGui_Button(c, "Modulation Panel öffnen", -1, 0) then
      open_modulation_panel_for_current_track()
    end

    r.ImGui_Separator(c)

    if num_sel > 0 and slice_count_cache > 0 then
      if r.ImGui_Button(c, "Fusionsset exportieren", -1, 0) then
        local naming_preset = naming_presets[gui_naming_idx] or "Default"
        local ts_start, ts_end = get_time_selection()
        local slices_all = collect_slices_from_tracks(mic_tracks_cache)
        local slices

        if scope_mode == 0 then
          slices = filter_slices_by_timesel(slices_all, ts_start, ts_end)
          if (#slices == 0) and (#slices_all > 0) then
            slices = slices_all
          end
        else
          slices = slices_all
        end

        local full_mode = (scope_mode == 1)

        if chain_mode == 0 then
          export_micfx_mode(mic_tracks_cache, slices, full_mode, naming_preset, gui_ai_tags)
        else
          export_buschain_mode(mic_tracks_cache, slices, full_mode, naming_preset, gui_ai_tags)
        end
      end
    else
      r.ImGui_TextColored(c, 1,0.4,0.4,1, "Keine gültigen Slices / Tracks gefunden.")
    end

  end
  r.ImGui_End(c)

  if open then
    r.defer(loop)
  end
end

loop()
