-- @description DF95_V198 SampleDB Speech & Loop Layers for Beats
-- @version 1.0
-- @author DF95
-- @about
--   Ergänzt das DF95-Beat-Ökosystem um zwei Audio-Layer:
--     - Speech-Layer: zieht Sprachsamples aus der DF95_SampleDB (is_speech)
--     - Loop-Layer: zieht Loop-Samples aus der DF95_SampleDB (is_loop)
--
--   Nutzt:
--     - DF95_AI_BEAT / BPM, TS_NUM, TS_DEN, BARS  (für Patternlänge)
--     - DF95_SampleDB.json (+ ExtendedTags: is_speech, is_loop, pitch_*)
--
--   Erzeugt:
--     - Track "DF95_IDM_Speech"
--     - Track "DF95_IDM_Loops"
--   und setzt dort Audio-Items passend zur Beatlänge.
--
--   Hinweis:
--     - Dies ist ein Ergänzungsscript; die MIDI-Beat-Engines (V102, V196)
--       bleiben unverändert, bekommen aber zusätzliche Audio-Schichten.

local r = reaper

------------------------------------------------------------
-- Konfiguration
------------------------------------------------------------

local CFG = {
  sampledb_relpath = "Data/DF95/DF95_SampleDB.json",
  max_speech_events = 8,
  max_speech_variants = 32,
  max_loop_variants = 32,
}

------------------------------------------------------------
-- Utils
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 V198 SampleDB Speech/Loop Layers", 0)
end

local function get_resource_based_path(relpath)
  local sep = package.config:sub(1,1)
  local base = r.GetResourcePath()
  local full = base .. sep .. relpath
  return full:gsub("\\","/")
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

-- sehr einfacher JSON->Lua Parser, kompatibel mit der DF95-SampleDB-Ausgabe
local function decode_json(str)
  local ok, res = pcall(function() return assert(load("return " .. str))() end)
  if ok and type(res) == "table" then
    return res
  end
  return nil, "JSON parse failed"
end

------------------------------------------------------------
-- SampleDB Laden & Filtern
------------------------------------------------------------

local function load_sampledb()
  local path = get_resource_based_path(CFG.sampledb_relpath)
  if not file_exists(path) then
    msg("SampleDB JSON nicht gefunden:\n" .. path)
    return nil
  end
  local f = io.open(path, "r")
  if not f then
    msg("Konnte SampleDB nicht öffnen:\n" .. path)
    return nil
  end
  local content = f:read("*a")
  f:close()

  local db, err = decode_json(content)
  if not db or type(db) ~= "table" then
    msg("Konnte SampleDB nicht parsen:\n" .. (err or "unknown error"))
    return nil
  end
  return db
end

local function filter_samples(db, predicate)
  local out = {}
  for _, entry in ipairs(db) do
    if type(entry) == "table" and predicate(entry) then
      out[#out+1] = entry
    end
  end
  return out
end

local function is_speech_entry(e)
  if e.is_speech == true then return true end
  local cat = (e.category or e.cat or ""):lower()
  if cat:match("vox") or cat:match("vocal") or cat:match("voice") or cat:match("speech") or cat:match("talk") or cat:match("dialog") then
    return true
  end
  local path = (e.path or e.file or ""):lower()
  if path:match("vox") or path:match("vocal") or path:match("voice") or path:match("speech") or path:match("talk") or path:match("dialog") then
    return true
  end
  return false
end

local function is_loop_entry(e)
  if e.is_loop == true then return true end
  local path = (e.path or e.file or ""):lower()
  if path:match("loop") or path:match("_lp") or path:match("looped") then
    return true
  end
  local cat = (e.category or ""):lower()
  if cat:match("loop") then return true end
  return false
end

------------------------------------------------------------
-- Beat-Settings (DF95_AI_BEAT)
------------------------------------------------------------

local function load_beat_settings()
  local _, bpm_s   = r.GetProjExtState(0, "DF95_AI_BEAT", "BPM")
  local _, tsn_s   = r.GetProjExtState(0, "DF95_AI_BEAT", "TS_NUM")
  local _, tsd_s   = r.GetProjExtState(0, "DF95_AI_BEAT", "TS_DEN")
  local _, bars_s  = r.GetProjExtState(0, "DF95_AI_BEAT", "BARS")

  local _, tempo, ts_n, ts_d = r.GetProjectTimeSignature2(0)

  local bpm  = tonumber(bpm_s) or tempo or 120.0
  local ts_n_val = tonumber(tsn_s) or ts_n or 4
  local ts_d_val = tonumber(tsd_s) or ts_d or 4
  local bars = tonumber(bars_s) or 4

  if bars < 1 then bars = 1 end

  local beats_per_bar = ts_n_val * (4.0 / ts_d_val)
  local total_beats = beats_per_bar * bars
  local proj = 0
  local t_start = r.TimeMap2_beatsToTime(proj, 0, 0)
  local t_end   = r.TimeMap2_beatsToTime(proj, total_beats, 0)

  return {
    bpm = bpm,
    ts_n = ts_n_val,
    ts_d = ts_d_val,
    bars = bars,
    beats_per_bar = beats_per_bar,
    t_start = t_start,
    t_end   = t_end,
  }
end

------------------------------------------------------------
-- Track / Item Utilities
------------------------------------------------------------

local function ensure_track(name)
  local proj = 0
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, tr_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if tr_name == name then
      return tr
    end
  end
  r.InsertTrackAtIndex(track_count, true)
  local tr = r.GetTrack(proj, track_count)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function clear_items_in_range(track, t_start, t_end)
  if not track then return end
  local cnt = r.CountTrackMediaItems(track)
  for i = cnt-1, 0, -1 do
    local it = r.GetTrackMediaItem(track, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
    local it_end = pos + len
    if not (it_end <= t_start or pos >= t_end) then
      r.DeleteTrackMediaItem(track, it)
    end
  end
end

local function select_only_track(tr)
  r.Main_OnCommand(40297, 0) -- unselect all tracks
  if tr then
    r.SetOnlyTrackSelected(tr)
  end
end

local function get_new_item_on_track(track)
  local cnt = r.CountTrackMediaItems(track)
  if cnt == 0 then return nil end
  return r.GetTrackMediaItem(track, cnt-1)
end

------------------------------------------------------------
-- Loop-Layer: ein Loop-Sample über die gesamte Beat-Länge
------------------------------------------------------------

local function build_loop_layer(db, beat)
  local loops = filter_samples(db, is_loop_entry)
  if #loops == 0 then
    msg("Keine Loop-Samples in SampleDB gefunden.")
    return
  end

  -- einen zufälligen Loop wählen
  math.randomseed(os.time())
  local choice = loops[math.random(1, math.min(#loops, CFG.max_loop_variants))]
  local path = choice.path or choice.file
  if not path or path == "" then
    msg("Ausgewählter Loop-Eintrag hat keinen gültigen Pfad.")
    return
  end

  local full = path
  if not file_exists(full) then
    -- versuchen, falls SampleDB relative Pfade genutzt hat
    local base = r.GetResourcePath()
    local sep = package.config:sub(1,1)
    local guess = base .. sep .. path
    if file_exists(guess) then
      full = guess
    end
  end
  if not file_exists(full) then
    msg("Loop-Datei nicht gefunden:\n" .. tostring(path))
    return
  end

  local tr = ensure_track("DF95_IDM_Loops")
  clear_items_in_range(tr, beat.t_start, beat.t_end)

  -- aktuellen Cursor & Track-Selektion sichern
  local cur_pos = r.GetCursorPosition()
  local proj = 0
  local prev_sel = {}
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local t = r.GetTrack(proj, i)
    if r.IsTrackSelected(t) then prev_sel[#prev_sel+1] = t end
  end

  select_only_track(tr)
  r.SetEditCurPos(beat.t_start, false, false)
  r.InsertMedia(full, 0) -- insert on selected track at cursor

  local it = get_new_item_on_track(tr)
  if it then
    r.SetMediaItemInfo_Value(it, "D_POSITION", beat.t_start)
    r.SetMediaItemInfo_Value(it, "D_LENGTH",  beat.t_end - beat.t_start)
    r.SetMediaItemInfo_Value(it, "B_LOOPSRC", 1)
  end

  -- restore selection & cursor
  r.SetEditCurPos(cur_pos, false, false)
  r.Main_OnCommand(40297, 0) -- unselect all
  for _,t in ipairs(prev_sel) do
    r.SetTrackSelected(t, true)
  end

  r.UpdateArrange()
end

------------------------------------------------------------
-- Speech-Layer: zufällige Speech-Samples über das Pattern streuen
------------------------------------------------------------

local function build_speech_layer(db, beat)
  local speech = filter_samples(db, is_speech_entry)
  if #speech == 0 then
    msg("Keine Speech-Samples in SampleDB gefunden.")
    return
  end

  math.randomseed(os.time() + 123)

  local tr = ensure_track("DF95_IDM_Speech")
  clear_items_in_range(tr, beat.t_start, beat.t_end)

  local cur_pos = r.GetCursorPosition()
  local proj = 0
  local prev_sel = {}
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local t = r.GetTrack(proj, i)
    if r.IsTrackSelected(t) then prev_sel[#prev_sel+1] = t end
  end

  select_only_track(tr)

  local events = math.min(CFG.max_speech_events, beat.bars * 4)
  for i = 1, events do
    local choice = speech[math.random(1, math.min(#speech, CFG.max_speech_variants))]
    local path = choice.path or choice.file
    if path and path ~= "" then
      local full = path
      if not file_exists(full) then
        local base = r.GetResourcePath()
        local sep = package.config:sub(1,1)
        local guess = base .. sep .. path
        if file_exists(guess) then
          full = guess
        end
      end
      if file_exists(full) then
        -- zufällige Position innerhalb des Patterns
        local rel = math.random()
        local pos = beat.t_start + (beat.t_end - beat.t_start) * rel
        r.SetEditCurPos(pos, false, false)
        r.InsertMedia(full, 0)
      end
    end
  end

  r.SetEditCurPos(cur_pos, false, false)
  r.Main_OnCommand(40297, 0)
  for _,t in ipairs(prev_sel) do
    r.SetTrackSelected(t, true)
  end

  r.UpdateArrange()
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local beat = load_beat_settings()
  local db = load_sampledb()
  if not db then return end

  local ok, ans = r.GetUserInputs("DF95 V198 SampleDB Speech/Loop Layers", 3,
                                  "SampleDB Relativpfad,Loop-Layer erzeugen? (y/n),Speech-Layer erzeugen? (y/n),extrawidth=200",
                                  CFG.sampledb_relpath .. ",y,y")
  if not ok then return end

  local path_s, loop_s, speech_s = ans:match("([^,]*),([^,]*),([^,]*)")
  if path_s and path_s ~= "" then
    CFG.sampledb_relpath = path_s
  end

  local do_loop = (loop_s or ""):lower():match("^y")
  local do_speech = (speech_s or ""):lower():match("^y")

  r.Undo_BeginBlock()

  if do_loop then
    build_loop_layer(db, beat)
  end
  if do_speech then
    build_speech_layer(db, beat)
  end

  r.Undo_EndBlock("DF95 V198 SampleDB Speech/Loop Layers", -1)
end

main()
