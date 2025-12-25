\
-- @description DF95_V164 Export Beat – BusEngine (FX-Bus, Coloring-Bus, Master-Bus, Lowest Source Format, Post-Master)
-- @version 1.0
-- @author DF95
-- @about
--   Erweiterte Beat-Export-Engine:
--     * Du wählst alle Beat-relevanten Tracks aus (Kick, Snare, Bass, FX, Texture usw.).
--     * Script baut (falls nicht vorhanden) eine 3-stufige Bus-Struktur:
--         - [DF95] Beat FX Bus
--         - [DF95] Beat Color Bus
--         - [DF95] Beat Master Bus
--       und routet:
--         Tracks -> FX Bus -> Color Bus -> Master Bus -> REAPER Master
--     * Alle Beat-Tracks senden NUR auf den FX-Bus (Master-Send wird deaktiviert).
--     * Es wird immer die kleinste Sample-Rate & Bittiefe aller verwendeten Audio-Files genommen.
--     * Export erfolgt als Stereo-Mastermix NACH der Master-Chain (inkl. Master-FX).
--
--   Time Selection:
--     * Wenn eine Time Selection gesetzt ist, wird nur dieser Bereich exportiert.
--     * Wenn keine gesetzt ist, wird automatisch min/max der Items auf den selektierten Tracks verwendet.
--
--   Hinweis:
--     * Es werden nur Audio-Takes berücksichtigt (keine MIDI).
--     * Bittiefe wird nur für WAV-Dateien sicher ausgelesen.
--     * Die Bus-Tracks werden automatisch solo-geschaltet zusammen mit den Beat-Tracks.

local r = reaper

------------------------------------------------------------
-- Projekt / Pfade / Zeit
------------------------------------------------------------

local function get_project()
  return 0 -- current project
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
-- WAV-Bittiefe aus Header lesen
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
-- Analyse: Min-SR / Min-Bits von selektierten Tracks
------------------------------------------------------------

local function collect_min_format_from_tracks(tracks)
  local min_sr = nil
  local min_bits = nil

  for _, tr in ipairs(tracks) do
    local item_count = r.CountTrackMediaItems(tr)
    for ii = 0, item_count-1 do
      local item = r.GetTrackMediaItem(tr, ii)
      local take = r.GetActiveTake(item)
      if take and not r.TakeIsMIDI(take) then
        local src = r.GetMediaItemTake_Source(take)
        if src then
          local sr = r.GetMediaSourceSampleRate(src)
          if sr and sr > 0 then
            if not min_sr or sr < min_sr then
              min_sr = sr
            end
          end
          local path = r.GetMediaSourceFileName(src, "")
          if path and path ~= "" then
            local bits = get_bits_from_wav(path)
            if bits and bits > 0 then
              if not min_bits or bits < min_bits then
                min_bits = bits
              end
            end
          end
        end
      end
    end
  end

  return min_sr, min_bits
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
  sss("RENDER_ADDTOPROJ",  saved.RENDER_ADDTOPRJ)
  sss("RENDER_STEMS",      saved.RENDER_STEMS)
end

------------------------------------------------------------
-- Solo-Handling
------------------------------------------------------------

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

local function set_solo_for_tracks(beat_tracks, bus_tracks)
  local cnt = r.CountTracks(0)
  local beat_set = {}
  local bus_set  = {}

  for _, tr in ipairs(beat_tracks or {}) do
    beat_set[tr] = true
  end
  for _, tr in ipairs(bus_tracks or {}) do
    bus_set[tr] = true
  end

  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    if beat_set[tr] or bus_set[tr] then
      r.SetMediaTrackInfo_Value(tr, "I_SOLO", 1)
    else
      r.SetMediaTrackInfo_Value(tr, "I_SOLO", 0)
    end
  end
end

------------------------------------------------------------
-- Bus-Erzeugung & Routing
------------------------------------------------------------

local FX_BUS_NAME     = "[DF95] Beat FX Bus"
local COLOR_BUS_NAME  = "[DF95] Beat Color Bus"
local MASTER_BUS_NAME = "[DF95] Beat Master Bus"

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

  -- FX-Bus: kein direkter Master-Send, sendet an Color-Bus
  r.SetMediaTrackInfo_Value(fx_tr, "B_MAINSEND", 0)
  -- Color-Bus: kein direkter Master-Send, sendet an Master-Bus
  r.SetMediaTrackInfo_Value(color_tr, "B_MAINSEND", 0)
  -- Master-Bus: sendet an REAPER-Master
  r.SetMediaTrackInfo_Value(master_tr, "B_MAINSEND", 1)

  -- Helper: prüft, ob Send existiert
  local function ensure_send(src_tr, dest_tr)
    local send_count = r.GetTrackNumSends(src_tr, 0)
    for i = 0, send_count-1 do
      local dest = r.GetTrackSendInfo_Value(src_tr, 0, i, "P_DESTTRACK")
      if dest == dest_tr then
        return i
      end
    end
    local send_idx = r.CreateTrackSend(src_tr, dest_tr)
    r.SetTrackSendInfo_Value(src_tr, 0, send_idx, "I_SENDMODE", 0) -- 0 post-fader
    return send_idx
  end

  ensure_send(fx_tr, color_tr)
  ensure_send(color_tr, master_tr)

  return fx_tr, color_tr, master_tr
end

local function route_beat_tracks_to_busses(beat_tracks, fx_tr)
  if not fx_tr then return end

  local function remove_sends_to_track(src_tr, target_tr)
    local send_count = r.GetTrackNumSends(src_tr, 0)
    for i = send_count-1, 0, -1 do
      local dest = r.GetTrackSendInfo_Value(src_tr, 0, i, "P_DESTTRACK")
      if dest == target_tr then
        r.RemoveTrackSend(src_tr, 0, i)
      end
    end
  end

  for _, tr in ipairs(beat_tracks or {}) do
    -- Master-Send deaktivieren
    r.SetMediaTrackInfo_Value(tr, "B_MAINSEND", 0)
    -- vorhandene Sends zum FX-Bus entfernen (falls doppelt)
    remove_sends_to_track(tr, fx_tr)
    -- neuen Send zum FX-Bus anlegen (post-fader)
    local send_idx = r.CreateTrackSend(tr, fx_tr)
    r.SetTrackSendInfo_Value(tr, 0, send_idx, "I_SENDMODE", 0)
  end
end

------------------------------------------------------------
-- Naming via DF95 Export Core (optional)
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
    local base = string.format("%s%sDF95_Beat_%s_%s", dest_root, sep, proj_name or "Project", ts)
    return base
  end

  local opts = {
    dest_root = dest_root,
    category  = "Beats_Master",
    subtype   = "BeatMix_BusEngine",
  }

  local tags = {
    role          = "BeatMix",
    source        = "DF95_BeatEngine",
    fxflavor      = "MasterBus",
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
-- Hauptlogik: Beat-Export mit BusEngine
------------------------------------------------------------

local function main()
  local num_sel_tracks = r.CountSelectedTracks(0)
  if num_sel_tracks == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\n\n" ..
      "Bitte wähle alle Beat-relevanten Tracks aus (Kick, Snare, Bass, FX usw.)\n" ..
      "und starte das Script erneut.",
      "DF95 Beat Export – BusEngine",
      0
    )
    return
  end

  -- Beat-Tracks einsammeln
  local beat_tracks = {}
  for ti = 0, num_sel_tracks-1 do
    local tr = r.GetSelectedTrack(0, ti)
    beat_tracks[#beat_tracks+1] = tr
  end

  -- Time Selection prüfen oder aus Beat-Tracks ableiten
  local ts_start, ts_end = get_time_selection()
  local had_ts = ts_start ~= nil

  local prev_ts_start, prev_ts_end = nil, nil
  if had_ts then
    prev_ts_start, prev_ts_end = ts_start, ts_end
  else
    local min_start, max_end = nil, nil
    for _, tr in ipairs(beat_tracks) do
      local item_count = r.CountTrackMediaItems(tr)
      for ii = 0, item_count-1 do
        local item = r.GetTrackMediaItem(tr, ii)
        local s = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local e = s + len
        if not min_start or s < min_start then min_start = s end
        if not max_end or e > max_end then max_end = e end
      end
    end
    if min_start and max_end and max_end > min_start then
      ts_start, ts_end = min_start, max_end
      set_time_selection(ts_start, ts_end)
    else
      r.ShowMessageBox(
        "Auf den selektierten Tracks wurden keine Items gefunden.\n" ..
        "Bitte prüfe die Trackauswahl oder setze eine Time Selection.",
        "DF95 Beat Export – BusEngine",
        0
      )
      return
    end
  end

  -- Min-SR / Min-Bits ermitteln (nur aus Beat-Tracks)
  local min_sr, min_bits = collect_min_format_from_tracks(beat_tracks)
  local bps = bits_to_reaper_bps(min_bits)

  -- Render-Settings sichern
  local saved = save_render_settings()
  local proj = get_project()

  -- Bus-Kette sicherstellen
  local fx_tr, color_tr, master_tr = ensure_bus_chain()
  local bus_tracks = {fx_tr, color_tr, master_tr}

  -- Beat-Tracks auf FX-Bus routen
  route_beat_tracks_to_busses(beat_tracks, fx_tr)

  -- Render-Settings setzen: Bounds = Time Selection, Master-Summe, Stereo
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true) -- 1 = Time Selection

  if min_sr and min_sr > 0 then
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE", tostring(math.floor(min_sr + 0.5)), true)
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE_USE", "1", true)
  end

  if bps then
    r.GetSetProjectInfo_String(proj, "RENDER_BPS", tostring(bps), true)
  end

  r.GetSetProjectInfo_String(proj, "RENDER_CHANNELS", "2", true) -- Stereo
  r.GetSetProjectInfo_String(proj, "RENDER_DITHER", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_ADDTOPROJ", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_STEMS", "0", true)

  -- Dateinamen setzen
  local base = build_render_basepath()
  r.GetSetProjectInfo_String(proj, "RENDER_FILE", base, true)

  -- Solo-Handling: Beat + Bus-Tracks solo
  local prev_solo = save_solo_states()
  set_solo_for_tracks(beat_tracks, bus_tracks)

  -- Render ausführen (Master-Summe, aktuelle Settings)
  r.Undo_BeginBlock()
  r.Main_OnCommand(41824, 0) -- Render project, using most recent render settings
  r.Undo_EndBlock("DF95 Beat Export – BusEngine (Post Master)", -1)

  -- Solo & Render-Settings & Time Selection zurücksetzen
  restore_solo_states(prev_solo)
  restore_render_settings(saved)
  if not had_ts then
    set_time_selection(0, 0)
  else
    if prev_ts_start and prev_ts_end then
      set_time_selection(prev_ts_start, prev_ts_end)
    end
  end

  r.ShowMessageBox(
    "Beat-Export (BusEngine) abgeschlossen.\n\n" ..
    "Exportpfad (Basis):\n" .. tostring(base) .. ".wav",
    "DF95 Beat Export – BusEngine",
    0
  )
end

main()
