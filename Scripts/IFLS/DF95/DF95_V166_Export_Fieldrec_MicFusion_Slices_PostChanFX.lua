\
-- @description DF95_V166 Export Fieldrec – Mic Fusion Slices (Summe aller Mics, Post-Channel-FX, ohne Bus/Master-FX)
-- @version 1.0
-- @author DF95
-- @about
--   Exportiert geschnittene Fieldrec-Slices als EIN Summen-Signal aller ausgewählten Mic-Tracks:
--     * Du wählst alle relevanten Mic-Tracks (z.B. XM8500, MD400, weitere Mics).
--     * Das Script findet alle zeitlichen Slices (basierend auf Items über alle Tracks).
--     * Für JEDEN Slice erzeugt es eine Summen-Datei:
--         -> Summe aller Mics, inklusive Deren Kanal-FX (EQ, Comp, DeNoise, etc.).
--         -> Keine FX-Busse, kein Coloring-Bus, keine Master-FX.
--     * Wenn auf einem Mic-Track im Slice kein Item liegt:
--         -> wird der Track einfach mit 0 dB Stille beigetragen (kein Problem),
--            die Summe wird trotzdem exportiert.
--
--   Technischer Ansatz:
--     * Es wird ein temporärer "[DF95] Fieldrec Fusion Bus" erzeugt.
--     * Alle ausgewählten Mic-Tracks senden post-fader auf diesen Bus.
--     * RENDER_STEMS wird auf "selected tracks" gesetzt, und NUR der Fusion-Bus wird selektiert.
--     * Pro Slice wird eine Time Selection gesetzt und der Fusion-Bus als Stem gerendert.
--     * Nach dem Render werden Bus-Track & Sends wieder entfernt.
--
--   Format:
--     * Wenn alle verwendeten Audio-Files dasselbe Format haben:
--         -> Export im Originalformat (z.B. 96 kHz / 32 Bit).
--     * Wenn mehrere Formate vorkommen:
--         -> Export in der HÖCHSTEN erkannten Sample-Rate & Bittiefe (verlustfrei).
--
--   Wichtig:
--     * Es werden nur Audio-Takes berücksichtigt (keine MIDI).
--     * Naming über DF95_Export_Core.lua falls vorhanden, sonst Fallback.
--     * Ergebnis: eine Datei pro Sample-Slice (z.B. ..._S001_Fusion.wav, ..._S002_Fusion.wav)

local r = reaper

------------------------------------------------------------
-- Projekt / Pfade / Zeit
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

------------------------------------------------------------
-- WAV-Bittiefe aus Header
------------------------------------------------------------

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

------------------------------------------------------------
-- Analyse: Formate der Tracks
------------------------------------------------------------

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
-- Render-Settings Save/Restore
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
    RENDER_ADDTOPROJ = gss("RENDER_ADDTOPROJ"),
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

------------------------------------------------------------
-- Naming (DF95 Export Core optional)
------------------------------------------------------------

local function get_script_dir()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  return script_path:match("^(.*[\\/])") or ""
end

local function build_render_basepath()
  local script_dir = get_script_dir()
  local ok, ExportCore = pcall(dofile, script_dir .. "DF95_Export_Core.lua")
  local proj_dir, proj_name = get_project_path_and_name()
  local sep = package.config:sub(1,1)
  local dest_root = proj_dir .. sep .. "DF95_EXPORT"

  if not ok or type(ExportCore) ~= "table" or type(ExportCore.BuildRenderBasename) ~= "function" then
    local ts = os.date("%Y%m%d_%H%M%S")
    local base = string.format("%s%sDF95_FieldrecFusion_%s_%s", dest_root, sep, proj_name or "Project", ts)
    return base
  end

  local opts = {
    dest_root = dest_root,
    category  = "Fieldrec_Fusion",
    subtype   = "Fieldrec_MicSum_PostFX",
  }

  local tags = {
    role          = "FieldrecFusion",
    source        = "DF95_FieldrecEngine",
    fxflavor      = "ChannelPostFX",
    ucs_catid     = nil,
    ucs_fxname    = nil,
    ucs_creatorid = nil,
    ucs_sourceid  = nil,
  }

  local bpm = 0
  local index = 1

  local base = ExportCore.BuildRenderBasename(opts, index, bpm, tags)
  return base
end

------------------------------------------------------------
-- Slice-Erkennung: aus Items auf den Tracks
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

  if #segments == 0 then
    return {}
  end

  table.sort(segments, function(a, b) return a.start < b.start end)

  local slices = {}
  local current = {start = segments[0+1].start, stop = segments[0+1].stop}
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

------------------------------------------------------------
-- Temporärer Fusion-Bus
------------------------------------------------------------

local FUSION_BUS_NAME = "[DF95] Fieldrec Fusion Bus"

local function create_fusion_bus_track()
  local cnt = r.CountTracks(0)
  r.InsertTrackAtIndex(cnt, false)
  r.TrackList_AdjustWindows(false)
  local tr = r.GetTrack(0, cnt)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", FUSION_BUS_NAME, true)
  -- Master-Send aktiv lassen, aber wir rendern ihn als Stem, nicht über Master-FX.
  return tr
end

local function add_send(src_tr, dest_tr)
  local send_count = r.GetTrackNumSends(src_tr, 0)
  for i = 0, send_count-1 do
    local dest = r.GetTrackSendInfo_Value(src_tr, 0, i, "P_DESTTRACK")
    if dest == dest_tr then
      return i
    end
  end
  local send_idx = r.CreateTrackSend(src_tr, dest_tr)
  r.SetTrackSendInfo_Value(src_tr, 0, send_idx, "I_SENDMODE", 0) -- post-fader
  return send_idx
end

local function remove_sends_to_track(src_tr, dest_tr)
  local send_count = r.GetTrackNumSends(src_tr, 0)
  for i = send_count-1, 0, -1 do
    local d = r.GetTrackSendInfo_Value(src_tr, 0, i, "P_DESTTRACK")
    if d == dest_tr then
      r.RemoveTrackSend(src_tr, 0, i)
    end
  end
end

------------------------------------------------------------
-- Trackselection Save/Restore
------------------------------------------------------------

local function save_track_selection()
  local sel = {}
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    sel[i] = r.IsTrackSelected(tr)
  end
  return sel
end

local function restore_track_selection(saved)
  if not saved then return end
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    local s = saved[i]
    r.SetTrackSelected(tr, s and true or false)
  end
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  local num_sel_tracks = r.CountSelectedTracks(0)
  if num_sel_tracks == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\n\n" ..
      "Bitte wähle alle relevanten Mic-Tracks (z.B. XM8500, MD400 etc.) aus\n" ..
      "und starte das Script erneut.",
      "DF95 Fieldrec Fusion Export – Slices",
      0
    )
    return
  end

  local mic_tracks = {}
  for ti = 0, num_sel_tracks-1 do
    local tr = r.GetSelectedTrack(0, ti)
    mic_tracks[#mic_tracks+1] = tr
  end

  local slices = collect_slices_from_tracks(mic_tracks)
  if #slices == 0 then
    r.ShowMessageBox(
      "Auf den selektierten Mic-Tracks wurden keine Items gefunden.\n" ..
      "Bitte prüfe die Trackauswahl.",
      "DF95 Fieldrec Fusion Export – Slices",
      0
    )
    return
  end

  local stats = collect_format_stats_from_tracks(mic_tracks)
  local formats = stats.formats or {}
  local format_count = 0
  for _ in pairs(formats) do format_count = format_count + 1 end

  local target_sr = stats.max_sr
  local target_bits = stats.max_bits
  local mode_desc = ""

  if format_count == 0 or not stats.max_sr or not stats.max_bits then
    local proj = get_project()
    local _, proj_sr = r.GetSetProjectInfo_String(proj, "RENDER_SRATE", "", false)
    target_sr = tonumber(proj_sr) or 48000
    target_bits = 24
    mode_desc = "Keine Dateiformat-Infos gefunden – fallback auf Projektformat."
  elseif format_count == 1 and stats.min_sr == stats.max_sr and stats.min_bits == stats.max_bits then
    mode_desc = string.format(
      "Export im Originalformat: %.0f Hz / %d Bit (einheitliche Quellen).",
      stats.max_sr or 0,
      stats.max_bits or 0
    )
  else
    mode_desc = string.format(
      "Mehrere Formate erkannt (%d Kombinationen).\n" ..
      "Export in der HÖCHSTEN SR / Bittiefe: %.0f Hz / %d Bit.",
      format_count,
      stats.max_sr or 0,
      stats.max_bits or 0
    )
  end

  local proj = get_project()
  local saved_render = save_render_settings()
  local saved_ts_start, saved_ts_end = get_time_selection()
  local had_ts = saved_ts_start ~= nil
  local saved_track_sel = save_track_selection()

  r.Undo_BeginBlock()

  local fusion_bus = create_fusion_bus_track()

  for _, tr in ipairs(mic_tracks) do
    add_send(tr, fusion_bus)
  end

  local bps = bits_to_reaper_bps(target_bits)
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true) -- Time Selection

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
  r.GetSetProjectInfo_String(proj, "RENDER_STEMS", "1", true)

  local base = build_render_basepath()

  for idx, sl in ipairs(slices) do
    set_time_selection(sl.start, sl.stop)

    local slice_base = string.format("%s_S%03d", base, idx)
    r.GetSetProjectInfo_String(proj, "RENDER_FILE", slice_base, true)

    local cnt = r.CountTracks(0)
    for i = 0, cnt-1 do
      local tr = r.GetTrack(0, i)
      r.SetTrackSelected(tr, tr == fusion_bus)
    end

    r.Main_OnCommand(41824, 0)
  end

  -- Cleanup: Fusion-Bus & Sends entfernen
  for _, tr in ipairs(mic_tracks) do
    remove_sends_to_track(tr, fusion_bus)
  end
  r.DeleteTrack(fusion_bus)

  restore_render_settings(saved_render)
  if had_ts and saved_ts_start and saved_ts_end then
    set_time_selection(saved_ts_start, saved_ts_end)
  else
    set_time_selection(0, 0)
  end
  restore_track_selection(saved_track_sel)

  r.Undo_EndBlock("DF95 Fieldrec Fusion Export – Slices (Mic-Summe, Post-FX)", -1)

  r.ShowMessageBox(
    string.format(
      "Fieldrec Fusion Export abgeschlossen.\n\n" ..
      "%s\n\n" ..
      "Anzahl Slices: %d\n" ..
      "Exportbasis: %s_SXXX_Fusion_<TrackName>.wav (Reaper hängt den Fusion-Bus-Namen an).",
      mode_desc,
      #slices,
      tostring(base)
    ),
    "DF95 Fieldrec Fusion Export – Slices",
    0
  )
end

main()
