\
-- @description DF95_V165 Export Fieldrec – Selected Tracks, Original Source Format, Post-Channel-FX (no Master-FX)
-- @version 1.0
-- @author DF95
-- @about
--   Exportiert Fieldrecording-Material (z.B. Zoom F6, H5, Mobile-Recorder) über die
--   jeweiligen Kanal-FX-Ketten, OHNE durch die Projekt-Master-FX zu laufen.
--
--   Workflow:
--     * Du wählst alle relevanten Tracks aus (z.B. F6 Boom/Lav/Amb-Kanäle nach Explode).
--     * Das Script:
--         - ermittelt aus allen verwendeten Audio-Files:
--             -> alle vorhandenen Samplerates / Bittiefen
--         - wenn nur ein Format vorkommt:
--             -> export in genau diesem Originalformat (z.B. 96 kHz / 32 Bit)
--         - wenn mehrere Formate vorkommen:
--             -> Warnung + Export in der HÖCHSTEN SR / Bittiefe (verlustfrei für alle Quellen)
--         - Renderquelle = Track-Stems (post-fader, post-FX), NICHT Master
--         - Master-FX werden nicht in die Stems gerendert
--     * Time Selection:
--         - Wenn eine Time Selection existiert, wird nur dieser Bereich exportiert.
--         - Wenn keine Time Selection existiert:
--             -> Script setzt automatisch eine Time Selection von min(Start) bis max(Ende)
--                aller Items auf den selektierten Tracks.
--
--   WICHTIG:
--     * Es werden NUR Audio-Takes berücksichtigt (keine MIDI).
--     * Für sauberes Arbeiten empfiehlt es sich, die Mic-FX-Ketten direkt auf den
--       Kanaltracks zu haben (EQ, Comp, DeNoise, etc.).
--     * Export erfolgt als Track-Stems (selected tracks), also "pro Kanal eine Summe"
--       mit allen Inserts, ohne zusätzliche Bus-/Master-FX.

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
-- Analyse: Formate der selektierten Tracks
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
-- Naming (optional DF95 Export Core)
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
    local base = string.format("%s%sDF95_Fieldrec_%s_%s", dest_root, sep, proj_name or "Project", ts)
    return base
  end

  local opts = {
    dest_root = dest_root,
    category  = "Fieldrec_Stems",
    subtype   = "Fieldrec_ChannelPostFX",
  }

  local tags = {
    role          = "Fieldrec",
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
-- Hauptlogik
------------------------------------------------------------

local function main()
  local num_sel_tracks = r.CountSelectedTracks(0)
  if num_sel_tracks == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\n\n" ..
      "Bitte wähle alle relevanten Fieldrec-Kanäle (z.B. Zoom F6 Boom/Lav/Amb) aus\n" ..
      "und starte das Script erneut.",
      "DF95 Fieldrec Export – Selected Tracks (OrigSrc)",
      0
    )
    return
  end

  local tracks = {}
  for ti = 0, num_sel_tracks-1 do
    local tr = r.GetSelectedTrack(0, ti)
    tracks[#tracks+1] = tr
  end

  -- Time Selection prüfen oder aus Items ableiten
  local ts_start, ts_end = get_time_selection()
  local had_ts = ts_start ~= nil

  local prev_ts_start, prev_ts_end = nil, nil
  if had_ts then
    prev_ts_start, prev_ts_end = ts_start, ts_end
  else
    local min_start, max_end = nil, nil
    for _, tr in ipairs(tracks) do
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
        "DF95 Fieldrec Export – Selected Tracks (OrigSrc)",
        0
      )
      return
    end
  end

  -- Formate analysieren
  local stats = collect_format_stats_from_tracks(tracks)
  local formats = stats.formats or {}
  local format_count = 0
  for _ in pairs(formats) do format_count = format_count + 1 end

  local target_sr = stats.max_sr
  local target_bits = stats.max_bits
  local mode_desc = ""

  if format_count == 0 or not stats.max_sr or not stats.max_bits then
    -- keine brauchbaren Infos -> auf Projekt-SR zurückfallen
    local proj = get_project()
    local _, proj_sr = r.GetSetProjectInfo_String(proj, "RENDER_SRATE", "", false)
    target_sr = tonumber(proj_sr) or 48000
    target_bits = 24
    mode_desc = "Keine Dateiformat-Infos gefunden – fallback auf Projektformat."
  elseif format_count == 1 and stats.min_sr == stats.max_sr and stats.min_bits == stats.max_bits then
    -- perfekter Originalfall
    mode_desc = string.format(
      "Export im Originalformat: %.0f Hz / %d Bit (einheitliche Quellen).",
      stats.max_sr or 0,
      stats.max_bits or 0
    )
  else
    -- mehrere Formate -> wir nehmen die HÖCHSTEN Werte
    mode_desc = string.format(
      "Mehrere Formate erkannt (%d Kombinationen).\n" ..
      "Export in der HÖCHSTEN SR / Bittiefe: %.0f Hz / %d Bit.",
      format_count,
      stats.max_sr or 0,
      stats.max_bits or 0
    )
  end

  local proj = get_project()
  local saved = save_render_settings()

  -- Render-Settings setzen: Bounds = Time Selection, Track-Stems (selected tracks)
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true) -- 1 = Time Selection

  if target_sr and target_sr > 0 then
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE", tostring(math.floor(target_sr + 0.5)), true)
    r.GetSetProjectInfo_String(proj, "RENDER_SRATE_USE", "1", true)
  end

  local bps = bits_to_reaper_bps(target_bits)
  if bps then
    r.GetSetProjectInfo_String(proj, "RENDER_BPS", tostring(bps), true)
  end

  -- Track-Stems (selected tracks), nicht Master
  r.GetSetProjectInfo_String(proj, "RENDER_CHANNELS", "2", true) -- pro Track typischerweise Mono/Stereo, Reaper handelt das intern
  r.GetSetProjectInfo_String(proj, "RENDER_DITHER", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_ADDTOPROJ", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_STEMS", "1", true) -- 1 = Stems (selected tracks)

  local base = build_render_basepath()
  r.GetSetProjectInfo_String(proj, "RENDER_FILE", base, true)

  -- Render ausführen (nutzt aktuelle Einstellungen)
  r.Undo_BeginBlock()
  r.Main_OnCommand(41824, 0) -- Render project, using most recent render settings
  r.Undo_EndBlock("DF95 Fieldrec Export – Selected Tracks (OrigSrc, Post-FX)", -1)

  restore_render_settings(saved)
  if not had_ts then
    set_time_selection(0, 0)
  else
    if prev_ts_start and prev_ts_end then
      set_time_selection(prev_ts_start, prev_ts_end)
    end
  end

  r.ShowMessageBox(
    "Fieldrec-Export abgeschlossen.\n\n" ..
    mode_desc .. "\n\n" ..
    "Exportbasis:\n" .. tostring(base) .. "_<TrackName>.wav",
    "DF95 Fieldrec Export – Selected Tracks (OrigSrc, Post-FX)",
    0
  )
end

main()
