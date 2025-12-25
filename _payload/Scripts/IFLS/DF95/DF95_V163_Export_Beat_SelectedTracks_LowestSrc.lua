\
-- @description DF95_V163 Export Beat – Selected Tracks, Lowest Source Format, Post-Master
-- @version 1.0
-- @author DF95
-- @about
--   Exportiert den Beat als Stereomix über den Master (inkl. Master-FX),
--   basierend auf den SELEKTIERTEN TRACKS.
--
--   Logik:
--     * Du wählst alle Beat-relevanten Tracks aus (Kick, Snare, Bass, FX, Texture usw.).
--     * Script:
--         - Ermittelt aus allen verwendeten Audio-Files:
--             -> kleinste Sample-Rate
--             -> kleinste Bittiefe (z.B. 16/24/32f)
--         - Setzt die Render-Einstellungen auf diese kleinsten Werte.
--         - Rendern erfolgt NACH der Master-Chain als Master-Summe.
--         - Nur die selektierten Tracks werden gesoloed (Rest bleibt stumm).
--     * Time Selection:
--         - Wenn eine Time Selection existiert: nur dieser Bereich wird exportiert.
--         - Wenn KEINE existiert: das Script setzt automatisch einen Bereich
--           von min(Start) bis max(Ende) aller Items auf den selektierten Tracks.
--
--   Wichtig:
--     * Es werden NUR Audio-Takes berücksichtigt (keine MIDI).
--     * Bittiefe wird aktuell nur für WAV-Dateien zuverlässig bestimmt.
--       Für andere Formate (MP3/FLAC/…) wird die Bittiefe nicht reduziert.
--
--   Dateiname:
--     * Versucht, DF95_Export_Core.lua zu laden und die Naming-Engine zu nutzen.
--     * Falls nicht verfügbar, wird ein einfacher Fallback-Name verwendet.

local r = reaper

------------------------------------------------------------
-- Helpers: Projekt / Pfade / Zeit
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
-- Helpers: WAV-Bittiefe aus Header lesen
------------------------------------------------------------

local function get_bits_from_wav(path)
  if not path or path == "" then return nil end
  local f = io.open(path, "rb")
  if not f then return nil end
  local header = f:read(64)
  f:close()
  if not header or #header < 36 then return nil end

  local riff = header:sub(1,4)
  -- einfache Prüfung auf RIFF/RF64
  if riff ~= "RIFF" and riff ~= "RF64" then
    return nil
  end

  -- BitsPerSample sitzt im klassischen WAV-Header bei Offset 34 (0-basiert)
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
    -- 32-bit float
    return 3
  end
end

------------------------------------------------------------
-- Analyse: Min-SR / Min-Bits auf selektierten Tracks
------------------------------------------------------------

local function collect_min_format_from_selected_tracks()
  local min_sr = nil
  local min_bits = nil

  local num_sel_tracks = r.CountSelectedTracks(0)
  for ti = 0, num_sel_tracks-1 do
    local tr = r.GetSelectedTrack(0, ti)
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
-- Solo-Handling für selektierte Tracks
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

local function solo_selected_tracks_only()
  local cnt = r.CountTracks(0)
  for i = 0, cnt-1 do
    local tr = r.GetTrack(0, i)
    local selected = r.IsTrackSelected(tr)
    r.SetMediaTrackInfo_Value(tr, "I_SOLO", selected and 1 or 0)
  end
end

------------------------------------------------------------
-- Naming: DF95 Export Core (optional)
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

  -- Fallback-Zielverzeichnis
  local sep = package.config:sub(1,1)
  local dest_root = proj_dir .. sep .. "DF95_EXPORT"

  if not ok or type(ExportCore) ~= "table" or type(ExportCore.BuildRenderBasename) ~= "function" then
    -- Fallback-Name ohne Tag-System
    local ts = os.date("%Y%m%d_%H%M%S")
    local base = string.format("%s%sDF95_Beat_%s_%s", dest_root, sep, proj_name or "Project", ts)
    return base
  end

  -- Tags abschätzen: Kategorie/Subtype für Beat-Mix
  local opts = {
    dest_root = dest_root,
    category  = "Beats_Master",
    subtype   = "BeatMix",
  }

  -- einfache Tag-Defaults
  local tags = {
    role        = "BeatMix",
    source      = "DF95_BeatEngine",
    fxflavor    = "Master",
    ucs_catid   = nil,
    ucs_fxname  = nil,
    ucs_creatorid = nil,
    ucs_sourceid  = nil,
  }

  local bpm = 0 -- BuildRenderBasename übernimmt BPM ggf. aus Projekt
  local index = 1

  local base = ExportCore.BuildRenderBasename(opts, index, bpm, tags)
  return base
end

------------------------------------------------------------
-- Hauptlogik: Beat Export
------------------------------------------------------------

local function main()
  local num_sel_tracks = r.CountSelectedTracks(0)
  if num_sel_tracks == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\n\n" ..
      "Bitte wähle alle Beat-relevanten Tracks aus (Kick, Snare, Bass, FX usw.)\n" ..
      "und starte das Script erneut.",
      "DF95 Beat Export – Selected Tracks",
      0
    )
    return
  end

  -- Time Selection prüfen oder aus Items ableiten
  local ts_start, ts_end = get_time_selection()
  local had_ts = ts_start ~= nil

  local prev_ts_start, prev_ts_end = nil, nil
  if had_ts then
    prev_ts_start, prev_ts_end = ts_start, ts_end
  else
    -- Auto: Time Selection = min/max aller Items auf selektierten Tracks
    local min_start, max_end = nil, nil
    for ti = 0, num_sel_tracks-1 do
      local tr = r.GetSelectedTrack(0, ti)
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
      -- Kein Inhalt -> Fehler
      r.ShowMessageBox(
        "Auf den selektierten Tracks wurden keine Items gefunden.\n" ..
        "Bitte prüfe die Trackauswahl oder setze eine Time Selection.",
        "DF95 Beat Export – Selected Tracks",
        0
      )
      return
    end
  end

  -- Min-SR / Min-Bits ermitteln
  local min_sr, min_bits = collect_min_format_from_selected_tracks()
  local bps = bits_to_reaper_bps(min_bits)

  -- Render-Settings sichern
  local saved = save_render_settings()
  local proj = get_project()

  -- Render-Settings setzen: Bounds = Time Selection, Master-Summe
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true) -- 1 = Time selection

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

  -- Solo-Handling
  local prev_solo = save_solo_states()
  solo_selected_tracks_only()

  -- Render ausführen (Master-Summe, aktuelle Settings)
  r.Undo_BeginBlock()
  r.Main_OnCommand(41824, 0) -- Render project, using most recent render settings (auto)
  r.Undo_EndBlock("DF95 Beat Export – Selected Tracks (Post Master)", -1)

  -- Solo & Render-Settings & Time Selection zurücksetzen
  restore_solo_states(prev_solo)
  restore_render_settings(saved)
  if not had_ts then
    -- eigene Auto-TS wieder entfernen
    set_time_selection(0, 0)
  else
    if prev_ts_start and prev_ts_end then
      set_time_selection(prev_ts_start, prev_ts_end)
    end
  end

  r.ShowMessageBox(
    "Beat-Export abgeschlossen.\n\n" ..
    "Exportpfad (Basis):\n" .. tostring(base) .. ".wav",
    "DF95 Beat Export – Selected Tracks",
    0
  )
end

main()
