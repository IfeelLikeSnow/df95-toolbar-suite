-- @description DF95_Beat_ControlCenter_ImGui
-- @version 1.2
-- @author DF95
-- @about
--   Zentrales Beat-Control-Center für das DF95-Ökosystem.
--   Features:
--     - Artist-Auswahl (DF95_ARTIST / NAME)
--     - Beat-Grid (BPM, Taktart, Bars) -> DF95_AI_BEAT + Projekt-Tempo/-Takt
--     - MIDI-Drum-Layer-Generator:
--         * DF95_IDM_Kick       (Note 36)
--         * DF95_IDM_Snare      (Note 38)
--         * DF95_IDM_Hats       (Note 42)
--         * DF95_IDM_MicroPerc  (Note 50)
--     - SampleDB-Layer:
--         * Loop-Layer (DF95_IDM_Loops) aus is_loop/Loop-Samples
--         * Speech-Layer (DF95_IDM_Speech) aus Voice/Vox/Speech-Samples
--     - Preset-System:
--         * bis zu 8 Beat-Presets (Artist, Grid, Layer-Flags) pro Projekt
--     - Render-Button:
--         * rendert den aktuellen Beat-Bereich als Stems (DF95_IDM_* Tracks)
--     - Sampler-Engine-Auswahl:
--         * RS5k, TX16Wx, Sitala 2.0 (Backend-Flag)
--         * Button zum Start des DF95_Sampler_SitalaKitBuilder_v1 Scripts
--
--   Hinweis:
--     - Dieses Script ist eigenständig und nutzt dieselben ExtStates wie
--       V102/V195/V196/V198, so dass alles miteinander kompatibel bleibt.

local r = reaper

if not (r.ImGui_CreateContext or (r.ImGui and r.ImGui.CreateContext)) then
  r.ShowMessageBox("ReaImGui ist nicht installiert. Bitte über ReaPack nachinstallieren.", "DF95 Beat Control Center", 0)
  return
end

local ImGui = r.ImGui or reaper.ImGui

------------------------------------------------------------
-- Artist-Liste (kompatibel zu DF95-Beat-Engines)
------------------------------------------------------------

local ARTIST_LIST = {
  "Aphex Twin",
  "Autechre",
  "Boards of Canada",
  "Squarepusher",
  "µ-ziq",
  "Apparat",
  "Arovane",
  "Björk",
  "Bochum Welt",
  "Bogdan Raczynski",
  "Burial",
  "Cylob",
  "DMX Krew",
  "Flying Lotus",
  "Four Tet",
  "The Future Sound Of London",
  "I am Robot and Proud",
  "Isan",
  "Jan Jelinek",
  "Jega",
  "Legowelt",
  "Matmos",
  "Moderat",
  "Photek",
  "Plaid",
  "Proem",
  "Skylab",
  "Telefon Tel Aviv",
  "Thom Yorke",
  "Tim Hecker",
}

local function find_artist_index_by_name(name)
  if not name or name == "" then return 1 end
  for i, a in ipairs(ARTIST_LIST) do
    if a == name then return i end
  end
  return 1
end

local function get_current_artist_index()
  local _, cur = r.GetProjExtState(0, "DF95_ARTIST", "NAME")
  return find_artist_index_by_name(cur)
end

local function set_project_artist(name)
  if name and name ~= "" then
    r.SetProjExtState(0, "DF95_ARTIST", "NAME", name)
  end
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

  return {
    bpm  = bpm,
    ts_n = ts_n_val,
    ts_d = ts_d_val,
    bars = bars,
  }
end

local function save_beat_settings(bpm, ts_n, ts_d, bars)
  r.SetProjExtState(0, "DF95_AI_BEAT", "BPM",  string.format("%.3f", bpm))
  r.SetProjExtState(0, "DF95_AI_BEAT", "TS_NUM", tostring(ts_n))
  r.SetProjExtState(0, "DF95_AI_BEAT", "TS_DEN", tostring(ts_d))
  r.SetProjExtState(0, "DF95_AI_BEAT", "BARS",   tostring(bars))
end

local function apply_project_tempo_timesig(bpm, ts_n, ts_d)
  r.SetTempoTimeSigMarker(0, -1, 0, -1, -1, bpm, ts_n, ts_d, false)
end

local function calc_pattern_times(ts_n, ts_d, bars)
  if bars < 1 then bars = 1 end
  local beats_per_bar = ts_n * (4.0 / ts_d)
  local total_beats = beats_per_bar * bars
  local proj = 0
  local t_start = r.TimeMap2_beatsToTime(proj, 0, 0)
  local t_end   = r.TimeMap2_beatsToTime(proj, total_beats, 0)
  return beats_per_bar, t_start, t_end
end

------------------------------------------------------------
-- Track / Item / MIDI-Utilities
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

local function create_midi_item(track, t_start, t_end)
  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", t_start)
  r.SetMediaItemInfo_Value(item, "D_LENGTH",  t_end - t_start)
  local take = r.AddTakeToMediaItem(item)
  r.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", 0)
  return item, take
end

local function insert_note_beat(take, note, vel, beat_pos, len_beats)
  local proj = 0
  local t_s = r.TimeMap2_beatsToTime(proj, beat_pos, 0)
  local t_e = r.TimeMap2_beatsToTime(proj, beat_pos + len_beats, 0)
  local ppq_s = r.MIDI_GetPPQPosFromProjTime(take, t_s)
  local ppq_e = r.MIDI_GetPPQPosFromProjTime(take, t_e)
  r.MIDI_InsertNote(take, false, false, ppq_s, ppq_e, 0, note, vel, false)
end

------------------------------------------------------------
-- Artist-Profil
------------------------------------------------------------

local function get_artist_profile(name)
  local p = { chaos = 0.4, density = 0.6, ghost = 0.3 }
  if not name then return p end

  if name == "Autechre" or name == "Squarepusher" or name == "Bogdan Raczynski" or name == "µ-ziq" or name == "Jega" or name == "Cylob" then
    p.chaos   = 0.85
    p.density = 0.85
    p.ghost   = 0.45
  elseif name == "Aphex Twin" or name == "Plaid" or name == "Proem" or name == "Flying Lotus" or name == "Four Tet" or name == "Telefon Tel Aviv" then
    p.chaos   = 0.6
    p.density = 0.75
    p.ghost   = 0.4
  elseif name == "Boards of Canada" or name == "Skylab" or name == "Tim Hecker" or name == "Jan Jelinek" or name == "Isan" or name == "I am Robot and Proud" or name == "The Future Sound Of London" then
    p.chaos   = 0.3
    p.density = 0.5
    p.ghost   = 0.2
  elseif name == "DMX Krew" or name == "Legowelt" or name == "Photek" then
    p.chaos   = 0.5
    p.density = 0.7
    p.ghost   = 0.35
  elseif name == "Burial" or name == "Moderat" or name == "Thom Yorke" or name == "Apparat" or name == "Matmos" or name == "Björk" then
    p.chaos   = 0.55
    p.density = 0.65
    p.ghost   = 0.3
  end
  return p
end

------------------------------------------------------------
-- MIDI-Drum-Layer Generatoren
------------------------------------------------------------

local function generate_kick_layer(artist_name, ts_n, ts_d, bars)
  local prof = get_artist_profile(artist_name)
  local bpb, t_start, t_end = calc_pattern_times(ts_n, ts_d, bars)
  local tr = ensure_track("DF95_IDM_Kick")
  clear_items_in_range(tr, t_start, t_end)
  local item, take = create_midi_item(tr, t_start, t_end)

  local note = 36
  local vel_main = 115
  local vel_ghost = 80
  local note_len = 0.3

  math.randomseed(os.time())

  for bar = 0, bars-1 do
    local bar_start_beats = bar * bpb

    insert_note_beat(take, note, vel_main, bar_start_beats + 0.0, note_len)
    if math.abs(bpb - 4.0) < 0.001 then
      insert_note_beat(take, note, vel_main, bar_start_beats + 2.0, note_len)
    end

    local grid = 0.5
    local steps = math.floor(bpb / grid + 0.5)
    for s = 0, steps-1 do
      local pos = bar_start_beats + s * grid
      if pos > bar_start_beats + 0.05 and pos < bar_start_beats + bpb - 0.05 then
        local p = 0.12 + 0.4 * prof.density
        if math.random() < p then
          local vel = (math.random() < 0.25) and vel_ghost or vel_main
          insert_note_beat(take, note, vel, pos, note_len)
        end
      end
    end
  end

  r.MIDI_Sort(take)
end

local function generate_snare_layer(artist_name, ts_n, ts_d, bars)
  local prof = get_artist_profile(artist_name)
  local bpb, t_start, t_end = calc_pattern_times(ts_n, ts_d, bars)
  local tr = ensure_track("DF95_IDM_Snare")
  clear_items_in_range(tr, t_start, t_end)
  local item, take = create_midi_item(tr, t_start, t_end)

  local note = 38
  local vel_main = 118
  local vel_ghost = 78
  local note_len = 0.25

  math.randomseed(os.time() + 123)

  for bar = 0, bars-1 do
    local bar_start_beats = bar * bpb

    local backbeats = {}
    if math.abs(bpb - 4.0) < 0.001 then
      backbeats = {1.0, 3.0}
    elseif math.abs(bpb - 3.0) < 0.001 then
      backbeats = {1.5}
    else
      backbeats = {bpb * 0.5}
    end

    for _, bb in ipairs(backbeats) do
      insert_note_beat(take, note, vel_main, bar_start_beats + bb, note_len)
    end

    local grid = 0.25
    local steps = math.floor(bpb / grid + 0.5)
    for s = 0, steps-1 do
      local pos = bar_start_beats + s * grid
      local is_back = false
      for _, bb in ipairs(backbeats) do
        if math.abs(pos - (bar_start_beats + bb)) < 1e-3 then
          is_back = true
          break
        end
      end
      if not is_back and math.random() < (0.2 + 0.6 * prof.ghost) then
        insert_note_beat(take, note, vel_ghost, pos, grid * 0.9)
      end
    end
  end

  r.MIDI_Sort(take)
end

local function generate_hats_layer(artist_name, ts_n, ts_d, bars)
  local prof = get_artist_profile(artist_name)
  local bpb, t_start, t_end = calc_pattern_times(ts_n, ts_d, bars)
  local tr = ensure_track("DF95_IDM_Hats")
  clear_items_in_range(tr, t_start, t_end)
  local item, take = create_midi_item(tr, t_start, t_end)

  local note = 42
  local vel_main = 96
  local vel_accent = 112
  local vel_soft = 78

  math.randomseed(os.time() + 321)

  local grid = 0.25
  local total_beats = bpb * bars
  local steps_total = math.floor(total_beats / grid + 0.5)
  local base_skip = 0.15 + (1.0 - prof.density) * 0.4

  for s = 0, steps_total-1 do
    local pos_beats = s * grid
    local bar_pos = pos_beats % bpb

    local accent = (math.abs(bar_pos - 0.0) < 1e-3) or (math.abs(bar_pos - 2.0) < 1e-3)
    local skip_prob = base_skip
    if accent then
      skip_prob = skip_prob * 0.4
    end

    if math.random() > skip_prob then
      local vel
      if accent then vel = vel_accent
      elseif math.random() < 0.3 then vel = vel_soft
      else vel = vel_main end
      insert_note_beat(take, note, vel, pos_beats, grid * 0.9)
    end
  end

  r.MIDI_Sort(take)
end

local function generate_micro_layer(artist_name, ts_n, ts_d, bars)
  local prof = get_artist_profile(artist_name)
  local bpb, t_start, t_end = calc_pattern_times(ts_n, ts_d, bars)
  local tr = ensure_track("DF95_IDM_MicroPerc")
  clear_items_in_range(tr, t_start, t_end)
  local item, take = create_midi_item(tr, t_start, t_end)

  local note = 50
  local vel_main = 88
  local vel_ghost = 70

  math.randomseed(os.time() + 777)

  local grid = 0.125
  local total_beats = bpb * bars
  local steps_total = math.floor(total_beats / grid + 0.5)
  local hit_prob = 0.1 + prof.chaos * 0.35

  for s = 0, steps_total-1 do
    local pos_beats = s * grid
    if math.random() < hit_prob then
      local len = grid * (0.5 + math.random() * 0.5)
      local vel = (math.random() < 0.4) and vel_ghost or vel_main
      insert_note_beat(take, note, vel, pos_beats, len)
    end
  end

  r.MIDI_Sort(take)
end

------------------------------------------------------------
-- SampleDB / Loop / Speech (leichtgewichtig)
------------------------------------------------------------

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

local function decode_json_lua(str)
  local ok, res = pcall(function() return assert(load("return " .. str))() end)
  if ok and type(res) == "table" then
    return res
  end
  return nil, "JSON parse failed"
end

local function load_sampledb(relpath)
  local full = get_resource_based_path(relpath)
  if not file_exists(full) then
    return nil, "SampleDB nicht gefunden: " .. full
  end


local sampledb_cache = { path = nil, db = nil, err = nil }

local function get_sampledb_cached(relpath)
  sampledb_cache = sampledb_cache or { path = nil, db = nil, err = nil }
  if sampledb_cache.path ~= relpath then
    local db, err = load_sampledb(relpath)
    sampledb_cache.path = relpath
    sampledb_cache.db = db
    sampledb_cache.err = err
  end
  return sampledb_cache.db, sampledb_cache.err
end

local function filter_samples_by_artist(db, artist_name)
  local result = {}
  if not db or type(db) ~= "table" or not artist_name or artist_name == "" then
    return result
  end
  for _, e in ipairs(db) do
    local fits = e.artist_fit
    if type(fits) == "table" then
      for _, a in ipairs(fits) do
        if a == artist_name then
          table.insert(result, e)
          break
        end
      end
    end
  end
  return result
end

local function get_filename_from_entry(e)
  if e.file and type(e.file) == "string" and e.file ~= "" then
    local name = e.file:match("([^/\\]+)$")
    return name or e.file
  end

local function filter_loops_for_beat(loop_list, beat_bpm, bpm_tolerance)
  if not loop_list or type(loop_list) ~= "table" then return {} end
local function build_artist_kit_from_sampledb(max_slots)
  local db, err = get_sampledb_cached(state.sampledb_relpath)
  if not db then
    r.ShowMessageBox("SampleDB konnte nicht geladen werden: " .. tostring(err or "unbekannt"), "DF95 Beat Control Center", 0)
    return nil
  end

  local current_artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
  local entries = filter_samples_by_artist(db, current_artist)
  if #entries == 0 then
    r.ShowMessageBox("Keine SampleDB-Eintraege fuer Artist '" .. tostring(current_artist) .. "' gefunden.", "DF95 Beat Control Center", 0)
    return nil
  end

  if max_slots and type(max_slots) == "number" and #entries > max_slots then
    local trimmed = {}
    for i = 1, max_slots do
      trimmed[i] = entries[i]
    end
    entries = trimmed
  end

  local kit_schema_path = get_resource_based_path("Scripts/IFLS/DF95/DF95_Sampler_KitSchema.lua")
  local ok, KitSchema = pcall(dofile, kit_schema_path)
  if not ok or not KitSchema or type(KitSchema.build_from_sampledb_entries) ~= "function" then
    r.ShowMessageBox("KitSchema konnte nicht geladen werden:\n" .. tostring(KitSchema), "DF95 Beat Control Center", 0)
    return nil
  end

  local beat = derive_beat_from_state()
  local bpm = beat and beat.bpm or 0

  local kit = KitSchema.build_from_sampledb_entries(entries, {
    name      = string.format("DF95 %s ArtistKit", tostring(current_artist)),
    artist    = current_artist,
    source    = "SampleDB_V2",
    bpm       = bpm,
    base_note = 36,
  })
  return kit
end

local function build_rs5k_kit_for_current_artist()
  local kit = build_artist_kit_from_sampledb(32)
  if not kit then return end

  local rs5k_path = get_resource_based_path("Scripts/IFLS/DF95/DF95_Sampler_Kit_To_RS5K.lua")
  local ok, RS5K = pcall(dofile, rs5k_path)
  if not ok or not RS5K or type(RS5K.build_on_new_track) ~= "function" then
    r.ShowMessageBox("RS5k-Adapter konnte nicht geladen werden:\n" .. tostring(RS5K), "DF95 Beat Control Center", 0)
    return
  end

  local track_name = (kit.meta and kit.meta.name) or "DF95_RS5K_ArtistKit"
  RS5K.build_on_new_track(kit, { track_name = track_name })
end

local function build_sitala_kit_for_current_artist()
  local kit = build_artist_kit_from_sampledb(16)
  if not kit then return end

local function build_tx16wx_kit_for_current_artist()
  local kit = build_artist_kit_from_sampledb(64)
  if not kit then return end

  local tx_path = get_resource_based_path("Scripts/IFLS/DF95/DF95_Sampler_Kit_To_TX16Wx.lua")
  local ok, TX = pcall(dofile, tx_path)
  if not ok or not TX or type(TX.build_sfz_for_kit) ~= "function" then
    r.ShowMessageBox("TX16Wx-Adapter konnte nicht geladen werden:\n" .. tostring(TX), "DF95 Beat Control Center", 0)
    return
  end

  local sfz_path = TX.build_sfz_for_kit(kit, nil)
  if sfz_path and sfz_path ~= "" then
    r.ShowMessageBox("TX16Wx SFZ-File fuer dieses Artist-Kit wurde erzeugt:\n" .. sfz_path .. "\n\nBitte in TX16Wx laden.", "DF95 Beat Control Center", 0)
  end
end


  local sitala_path = get_resource_based_path("Scripts/IFLS/DF95/DF95_Sampler_Kit_To_Sitala.lua")
  local ok, SITA = pcall(dofile, sitala_path)
  if not ok or not SITA or type(SITA.ensure_sitala_and_print_mapping) ~= "function" then
    r.ShowMessageBox("Sitala-Adapter konnte nicht geladen werden:\n" .. tostring(SITA), "DF95 Beat Control Center", 0)
    return
  end

  SITA.ensure_sitala_and_print_mapping(kit)
end


  if not beat_bpm or type(beat_bpm) ~= "number" then
    return loop_list
  end
  bpm_tolerance = bpm_tolerance or 5.0
  local close = {}
  for _, e in ipairs(loop_list) do
    local a = e.analysis
    if a and type(a.bpm) == "number" then
      if math.abs(a.bpm - beat_bpm) <= bpm_tolerance then
        table.insert(close, e)
      end
    end
  end
  if #close > 0 then
    return close
  end
  return loop_list
end

  if e.sample_id and type(e.sample_id) == "string" then
    return e.sample_id
  end
  return "<unnamed>"
end

  local f = io.open(full, "r")
  if not f then
    return nil, "SampleDB nicht lesbar: " .. full
  end
  local content = f:read("*a")
  f:close()
  local db, err = decode_json_lua(content)
  if not db then
    return nil, "SampleDB-Parse-Fehler: " .. (err or "unbekannt")
  end
  return db
end

local function is_loop_entry(e)
  -- Kompatibel zu alten SampleDB-Einträgen (is_loop-Flag)
  if e.is_loop == true then return true end
  -- Neue SampleDB_Index_V2-Struktur:
  -- - material == "loop" oder "drum" (optional)
  -- - analysis.loopable == true
  if e.material == "loop" then return true end
  if e.analysis and e.analysis.loopable == true then return true end
  local path = (e.path or e.file or ""):lower()
  local cat  = (e.category or e.cat or ""):lower()
  if path:match("loop") or path:match("_lp") or path:match("looped") then
    return true
  end
  if cat:match("loop") then return true end
  return false
end

local function is_speech_entry(e)
  -- Kompatibel zu alten SampleDB-Einträgen (is_speech-Flag)
  if e.is_speech == true then return true end
  -- Neue SampleDB_Index_V2-Struktur:
  -- - material == "speech"
  -- - optionale Tags in e.tags
  if e.material == "speech" then return true end
  if e.tags and type(e.tags) == "table" then
    for _, t in ipairs(e.tags) do
      local tl = tostring(t):lower()
      if tl:find("speech") or tl:find("vox") or tl:find("voice") then
        return true
      end
    end
  end
  local path = (e.path or e.file or ""):lower()
  local cat  = (e.category or e.cat or ""):lower()
  if path:match("vox") or path:match("vocal") or path:match("voice") or path:match("speech") or path:match("talk") or path:match("dialog") then
    return true
  end
  if cat:match("vox") or cat:match("vocal") or cat:match("voice") or cat:match("speech") then
    return true
  end
  return false
end

local function filter_samples(db, pred)
  local out = {}
  for _, e in ipairs(db) do
    if type(e) == "table" and pred(e) then
      out[#out+1] = e
    end
  end
  return out
end

local function select_only_track(tr)
  r.Main_OnCommand(40297, 0)
  if tr then
    r.SetOnlyTrackSelected(tr)
  end
end

local function get_newest_item_on_track(tr)
  local cnt = r.CountTrackMediaItems(tr)
  if cnt == 0 then return nil end
  return r.GetTrackMediaItem(tr, cnt-1)
end

local function build_loop_layer(db, beat)
  -- Zunaechst alle Loop-Eintraege laut Predicate sammeln
  local loops_all = filter_samples(db, is_loop_entry)
  if #loops_all == 0 then
    r.ShowMessageBox("Keine Loop-Samples in SampleDB gefunden.", "DF95 Beat Control Center", 0)
    return
  end

  -- Aktuellen Artist bestimmen und, falls moeglich, darauf filtern
  local current_artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
  local loops_artist = filter_samples_by_artist(loops_all, current_artist)
  local loops = loops_artist

  -- Fallback, falls fuer diesen Artist keine Loops markiert sind
  if #loops == 0 then
    loops = loops_all
  end

  -- Optional: nach BPM an den aktuellen Beat annaehern (Index V2: analysis.bpm)
  loops = filter_loops_for_beat(loops, beat.bpm, 5.0)

  if #loops == 0 then
    r.ShowMessageBox("Keine passenden Loop-Samples (Artist/BPM) gefunden.", "DF95 Beat Control Center", 0)
    return
  end

  math.randomseed(os.time() + 999)
  local entry = loops[math.random(1, #loops)]
  local path = entry.path or entry.file
  if not path or path == "" then
    r.ShowMessageBox("Loop-Eintrag ohne gültigen Pfad.", "DF95 Beat Control Center", 0)
    return
  end

  local full = path
  if not file_exists(full) then
    local base = r.GetResourcePath()
    local sep = package.config:sub(1,1)
    local guess = base .. sep .. path
    if file_exists(guess) then full = guess end
  end
  if not file_exists(full) then
    r.ShowMessageBox("Loop-Datei nicht gefunden:\n" .. tostring(path), "DF95 Beat Control Center", 0)
    return
  end

  local tr = ensure_track("DF95_IDM_Loops")
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
  r.SetEditCurPos(beat.t_start, false, false)
  r.InsertMedia(full, 0)

  local it = get_newest_item_on_track(tr)
  if it then
    r.SetMediaItemInfo_Value(it, "D_POSITION", beat.t_start)
    r.SetMediaItemInfo_Value(it, "D_LENGTH",  beat.t_end - beat.t_start)
    r.SetMediaItemInfo_Value(it, "B_LOOPSRC", 1)
  end

  r.SetEditCurPos(cur_pos, false, false)
  r.Main_OnCommand(40297, 0)
  for _, t in ipairs(prev_sel) do
    r.SetTrackSelected(t, true)
  end

  r.UpdateArrange()
end

local function build_speech_layer(db, beat, max_events)
  -- Alle Speech/Vox-Eintraege laut Predicate sammeln
  local speech_all = filter_samples(db, is_speech_entry)
  if #speech_all == 0 then
    r.ShowMessageBox("Keine Speech/Vox-Samples in SampleDB gefunden.", "DF95 Beat Control Center", 0)
    return
  end

  -- Artist-basiert filtern
  local current_artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
  local speech = filter_samples_by_artist(speech_all, current_artist)

  -- Fallback, falls fuer diesen Artist keine Speech-Eintraege vorhanden sind
  if #speech == 0 then
    speech = speech_all
  end

  math.randomseed(os.time() + 555)

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

  local events = math.min(max_events or 8, beat.bars * 4)
  for i = 1, events do
    local entry = speech[math.random(1, #speech)]
    local path = entry.path or entry.file
    if path and path ~= "" then
      local full = path
      if not file_exists(full) then
        local base = r.GetResourcePath()
        local sep = package.config:sub(1,1)
        local guess = base .. sep .. path
        if file_exists(guess) then full = guess end
      end
      if file_exists(full) then
        local rel = math.random()
        local pos = beat.t_start + (beat.t_end - beat.t_start) * rel
        r.SetEditCurPos(pos, false, false)
        r.InsertMedia(full, 0)
      end
    end
  end

  r.SetEditCurPos(cur_pos, false, false)
  r.Main_OnCommand(40297, 0)
  for _, t in ipairs(prev_sel) do
    r.SetTrackSelected(t, true)
  end

  r.UpdateArrange()
end

------------------------------------------------------------
-- Preset-System
------------------------------------------------------------

local PRESET_SECTION = "DF95_BEAT_PRESETS"

local function encode_bool(b) return b and "1" or "0" end
local function decode_bool(s) return s == "1" or s == "true" end

local function serialize_preset(name, st)
  local artist = ARTIST_LIST[st.artist_idx] or ARTIST_LIST[1]
  local parts = {
    "name=" .. (name or ""),
    "artist=" .. artist,
    "bpm=" .. tostring(st.bpm),
    "ts_n=" .. tostring(st.ts_n),
    "ts_d=" .. tostring(st.ts_d),
    "bars=" .. tostring(st.bars),
    "do_kick=" .. encode_bool(st.do_kick),
    "do_snare=" .. encode_bool(st.do_snare),
    "do_hats=" .. encode_bool(st.do_hats),
    "do_micro=" .. encode_bool(st.do_micro),
    "do_loop=" .. encode_bool(st.do_loop),
    "do_speech=" .. encode_bool(st.do_speech),
    "speech_events=" .. tostring(st.speech_events or 8),
    "sampler_engine=" .. (st.sampler_engine or "RS5K"),
  }
  return table.concat(parts, "|")
end

local function deserialize_preset(s)
  if not s or s == "" then return nil end
  local preset = {}
  for token in string.gmatch(s, "([^|]+)") do
    local k, v = token:match("^([^=]+)=(.*)$")
    if k and v then
      preset[k] = v
    end
  end
  if not preset.artist then return nil end
  return preset
end

local function save_preset_slot(slot, name, st)
  local key = string.format("SLOT_%d", slot)
  local blob = serialize_preset(name, st)
  r.SetProjExtState(0, PRESET_SECTION, key, blob)
end

local function load_preset_slot(slot)
  local key = string.format("SLOT_%d", slot)
  local _, blob = r.GetProjExtState(0, PRESET_SECTION, key)
  if not blob or blob == "" then return nil end
  return deserialize_preset(blob)
end

------------------------------------------------------------
-- Render-Funktion
------------------------------------------------------------

local function select_df95_idm_tracks()
  local proj = 0
  r.Main_OnCommand(40297, 0)
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if name:match("^DF95_IDM_") then
      r.SetTrackSelected(tr, true)
    end
  end
end

local function render_beat_area(ts_n, ts_d, bars)
  local bpb, t_start, t_end = calc_pattern_times(ts_n, ts_d, bars)
  r.GetSet_LoopTimeRange(true, false, t_start, t_end, false)
  select_df95_idm_tracks()
  local CMD_RENDER_STEMS = 40988
  r.Main_OnCommand(CMD_RENDER_STEMS, 0)
end

------------------------------------------------------------
-- Sampler Engine (RS5k / TX16Wx / Sitala)
------------------------------------------------------------

local SAMPLER_ENGINES = { "RS5K", "TX16Wx", "Sitala" }

local function load_sampler_engine()
  local _, eng = r.GetProjExtState(0, "DF95_SAMPLER", "ENGINE")
  if eng == "" or not eng then eng = "RS5K" end
  return eng
end

local function save_sampler_engine(engine)
  r.SetProjExtState(0, "DF95_SAMPLER", "ENGINE", engine or "RS5K")
end

local function run_sitala_kit_builder()
  local sep = package.config:sub(1,1)
  local base = r.GetResourcePath()
  local path = base .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Sampler_SitalaKitBuilder_v1.lua"
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox("Konnte DF95_Sampler_SitalaKitBuilder_v1.lua nicht laden:\n" .. tostring(err) .. "\nPfad: " .. path, "DF95 Beat Control Center", 0)
    return
  end


local function run_rs5k_kit_from_folder()
  local path = get_resource_based_path("Scripts/IFLS/DF95/DF95_Sampler_Build_RS5K_Kit_From_Folder.lua")
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox("Konnte DF95_Sampler_Build_RS5K_Kit_From_Folder.lua nicht laden:\n" .. tostring(err) .. "\nPfad: " .. path, "DF95 Beat Control Center", 0)
    return
  end
  f()
end

  f()
end

------------------------------------------------------------
-- GUI State
------------------------------------------------------------

local state = {
  artist_idx = 1,
  bpm   = 120.0,
  ts_n  = 4,
  ts_d  = 4,
  bars  = 4,

  do_kick   = true,
  do_snare  = true,
  do_hats   = true,
  do_micro  = true,
  do_loop   = false,
  do_speech = false,

  sampledb_relpath = "Data/DF95/SampleDB_Index_V2.json",
  speech_events = 8,

  preset_slot = 1,
  preset_name = "",
  sampler_engine = "RS5K",
}


local function draw_sampledb_artist_panel(ctx)
  ImGui.Separator(ctx)
  ImGui.Text(ctx, "SampleDB V2 – Artist-Samples")

  local current_artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
  ImGui.Text(ctx, ("Current Artist: %s"):format(current_artist))

  local db, err = get_sampledb_cached(state.sampledb_relpath)
  if not db then
    ImGui.TextColored(ctx, 1.0, 0.5, 0.2, 1.0, err or "SampleDB konnte nicht geladen werden.")
    ImGui.Spacing(ctx)
    return
  end

  local filtered = filter_samples_by_artist(db, current_artist)
  local count = #filtered
  ImGui.Text(ctx, string.format("Samples in SampleDB Index V2 fuer Artist: %d", count))

  if count == 0 then
    ImGui.TextWrapped(ctx, "Keine passenden Samples fuer diesen Artist im Index V2 gefunden.")
  else
    if ImGui.CollapsingHeader(ctx, "Beispiel-Eintraege", ImGui.TreeNodeFlags_None or 0) then
      local max_show = math.min(count, 12)
      for i = 1, max_show do
        local e = filtered[i]
        ImGui.BulletText(ctx, "%s", get_filename_from_entry(e))
      end
      if count > max_show then
        ImGui.Text(ctx, string.format("... (%d weitere)", count - max_show))
      end
    end
  end

  ImGui.Spacing(ctx)
  ImGui.Text(ctx, "Sampler-Aktionen (Artist -> Kit):")

  if ImGui.Button(ctx, "Build Sitala Artist Kit", 260, 0) then
    build_sitala_kit_for_current_artist()
  end
  if ImGui.Button(ctx, "Build RS5k Artist Kit", 260, 0) then
    build_rs5k_kit_for_current_artist()
  end
  if ImGui.Button(ctx, "Build TX16Wx Artist Kit (SFZ)", 260, 0) then
    build_tx16wx_kit_for_current_artist()
  end

  ImGui.TextWrapped(ctx,
    "Es werden Kits aus den SampleDB Index V2 Eintraegen fuer den aktuellen Artist erzeugt. " ..
    "RS5k erhaelt einen neuen Track mit Instanzen, Sitala ein Mapping im ReaScript-Log, TX16Wx ein SFZ-File zum Laden.")
end


local ctx = nil

------------------------------------------------------------
-- MAIN GUI LOOP
------------------------------------------------------------

local function main_loop()
  if not ctx then
    ctx = ImGui.CreateContext("DF95 Beat Control Center", ImGui.ConfigFlags_None)
    local io = ImGui.GetIO(ctx)
    io.FontGlobalScale = 1.0

    math.randomseed(os.time())

    state.artist_idx = get_current_artist_index()
    local bs = load_beat_settings()
    state.bpm  = bs.bpm
    state.ts_n = bs.ts_n
    state.ts_d = bs.ts_d
    state.bars = bs.bars
    state.sampler_engine = load_sampler_engine()
  end

  ImGui.SetNextWindowSize(ctx, 720, 640, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "DF95 Beat Control Center", true)
  if visible then
    ImGui.Text(ctx, "DF95 Beat Control Center")
    ImGui.Spacing(ctx)
    ImGui.TextWrapped(ctx,
      "Zentrale Steuerung für die DF95-Beat-Welt:\n" ..
      "- Artist / BPM / Taktart / Bars setzen (DF95_ARTIST / DF95_AI_BEAT).\n" ..
      "- MIDI-Drum-Layer erzeugen (Kick / Snare / Hats / MicroPerc).\n" ..
      "- Loop- und Speech-Layer aus SampleDB ergänzen.\n" ..
      "- Beat-Presets speichern/laden, Sampler-Engine wählen und den Beat als Stems rendern.")

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Artist & Grund-Beat")

    local current_artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
    if ImGui.BeginCombo(ctx, "Artist", current_artist) then
      for i, a in ipairs(ARTIST_LIST) do
        local selected = (i == state.artist_idx)
        if ImGui.Selectable(ctx, a, selected) then
          state.artist_idx = i
          set_project_artist(a)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    local changed
    changed, state.bpm  = ImGui.SliderFloat(ctx, "Tempo (BPM)", state.bpm, 40.0, 220.0, "%.2f")
    changed, state.ts_n = ImGui.InputInt(ctx,  "Taktart Zähler (z.B. 4, 3, 7)", state.ts_n)
    changed, state.ts_d = ImGui.InputInt(ctx,  "Taktart Nenner (z.B. 4, 8)",   state.ts_d)
    changed, state.bars = ImGui.InputInt(ctx,  "Bars (Pattern-Länge)",         state.bars)

    if state.ts_n < 1 then state.ts_n = 1 end
    if state.ts_d < 1 then state.ts_d = 1 end
    if state.bars < 1 then state.bars = 1 end

    if ImGui.Button(ctx, "Beat-Settings speichern (DF95_AI_BEAT + Projekt-Tempo/Takt)", 420, 0) then
      local artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
      set_project_artist(artist)
      save_beat_settings(state.bpm, state.ts_n, state.ts_d, state.bars)
      apply_project_tempo_timesig(state.bpm, state.ts_n, state.ts_d)
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "MIDI-Drum-Layer (IDM)")

    changed, state.do_kick   = ImGui.Checkbox(ctx, "Kick-Layer (DF95_IDM_Kick)",   state.do_kick)
    changed, state.do_snare  = ImGui.Checkbox(ctx, "Snare-Layer (DF95_IDM_Snare)", state.do_snare)
    changed, state.do_hats   = ImGui.Checkbox(ctx, "Hihat-Layer (DF95_IDM_Hats)",  state.do_hats)
    changed, state.do_micro  = ImGui.Checkbox(ctx, "MicroPerc-Layer (DF95_IDM_MicroPerc)", state.do_micro)

    if ImGui.Button(ctx, "Generate MIDI-Layer (Kick/Snare/Hats/Micro)", 360, 0) then
      local artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
      save_beat_settings(state.bpm, state.ts_n, state.ts_d, state.bars)
      apply_project_tempo_timesig(state.bpm, state.ts_n, state.ts_d)
      r.Undo_BeginBlock()
      if state.do_kick   then generate_kick_layer(artist,  state.ts_n, state.ts_d, state.bars) end
      if state.do_snare  then generate_snare_layer(artist, state.ts_n, state.ts_d, state.bars) end
      if state.do_hats   then generate_hats_layer(artist,  state.ts_n, state.ts_d, state.bars) end
      if state.do_micro  then generate_micro_layer(artist, state.ts_n, state.ts_d, state.bars) end
      r.Undo_EndBlock("DF95 BeatControl: Generate MIDI Layers", -1)
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "SampleDB-Layer (Loops / Speech)")

    changed, state.do_loop   = ImGui.Checkbox(ctx, "Loop-Layer (DF95_IDM_Loops)",   state.do_loop)
    changed, state.do_speech = ImGui.Checkbox(ctx, "Speech-Layer (DF95_IDM_Speech)", state.do_speech)

    state.sampledb_relpath = ({ImGui.InputText(ctx, "SampleDB Relativpfad (von REAPER-ResourcePath)", state.sampledb_relpath, 256)})[2]
    changed, state.speech_events = ImGui.SliderInt(ctx, "Max. Speech-Events", state.speech_events, 1, 32)

    if ImGui.Button(ctx, "Generate SampleDB-Layer (Loops/Speech)", 360, 0) then
      local bs = load_beat_settings()
      local beats_per_bar, t_start, t_end = calc_pattern_times(bs.ts_n, bs.ts_d, bs.bars)
      local beat = {
        bpm = bs.bpm,
        ts_n = bs.ts_n,
        ts_d = bs.ts_d,
        bars = bs.bars,
        beats_per_bar = beats_per_bar,
        t_start = t_start,
        t_end   = t_end,
      }

      local db, err = load_sampledb(state.sampledb_relpath)
      if not db then
        r.ShowMessageBox("Konnte SampleDB nicht laden:\n" .. tostring(err), "DF95 Beat Control Center", 0)
      else
        r.Undo_BeginBlock()
        if state.do_loop   then build_loop_layer(db, beat) end
        if state.do_speech then build_speech_layer(db, beat, state.speech_events) end
        r.Undo_EndBlock("DF95 BeatControl: Generate SampleDB Layers", -1)
      end
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Sampler Engine (Backend)")

    -- Dropdown für Sampler Engine
    local current_engine = state.sampler_engine or "RS5K"
    if ImGui.BeginCombo(ctx, "Sampler Engine", current_engine) then
      for _, eng in ipairs(SAMPLER_ENGINES) do
        local selected = (eng == current_engine)
        if ImGui.Selectable(ctx, eng, selected) then
          state.sampler_engine = eng
          save_sampler_engine(eng)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.TextWrapped(ctx,
      "RS5K = klassische ReaSamplomatic-Kits.\n" ..
      "TX16Wx = Multi-Sampler-Backend.\n" ..
      "Sitala = 16-Pad-Drum-Sampler (ideal für IDM-Kits).")

    if state.sampler_engine == "Sitala" then
      if ImGui.Button(ctx, "Sitala Kit Builder starten (DF95_Sampler_SitalaKitBuilder_v1)", 420, 0) then
        run_sitala_kit_builder()
      end
    end

    draw_sampledb_artist_panel(ctx)

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Beat-Presets (pro Projekt)")

    local slot_labels = {"Slot 1","Slot 2","Slot 3","Slot 4","Slot 5","Slot 6","Slot 7","Slot 8"}
    local current_slot_label = slot_labels[state.preset_slot] or ("Slot " .. tostring(state.preset_slot))
    if ImGui.BeginCombo(ctx, "Preset Slot", current_slot_label) then
      for i = 1, 8 do
        local selected = (i == state.preset_slot)
        local label = slot_labels[i] or ("Slot " .. tostring(i))
        if ImGui.Selectable(ctx, label, selected) then
          state.preset_slot = i
          local p = load_preset_slot(i)
          if p and p.name then
            state.preset_name = p.name
          end
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    state.preset_name = ({ImGui.InputText(ctx, "Preset-Name", state.preset_name or "", 128)})[2]

    if ImGui.Button(ctx, "Preset speichern", 140, 0) then
      local name = state.preset_name
      if not name or name == "" then
        name = (ARTIST_LIST[state.artist_idx] or "DF95") .. string.format(" %d Bars @ %.1f BPM", state.bars, state.bpm)
      end
      save_preset_slot(state.preset_slot, name, state)
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Preset laden", 120, 0) then
      local p = load_preset_slot(state.preset_slot)
      if p then
        state.preset_name = p.name or ""
        state.artist_idx = find_artist_index_by_name(p.artist or "")
        state.bpm  = tonumber(p.bpm) or state.bpm
        state.ts_n = tonumber(p.ts_n) or state.ts_n
        state.ts_d = tonumber(p.ts_d) or state.ts_d
        state.bars = tonumber(p.bars) or state.bars
        state.do_kick   = decode_bool(p.do_kick or "1")
        state.do_snare  = decode_bool(p.do_snare or "1")
        state.do_hats   = decode_bool(p.do_hats or "1")
        state.do_micro  = decode_bool(p.do_micro or "1")
        state.do_loop   = decode_bool(p.do_loop or "0")
        state.do_speech = decode_bool(p.do_speech or "0")
        state.speech_events = tonumber(p.speech_events) or state.speech_events
        state.sampler_engine = p.sampler_engine or "RS5K"

        local artist = ARTIST_LIST[state.artist_idx] or ARTIST_LIST[1]
        set_project_artist(artist)
        save_beat_settings(state.bpm, state.ts_n, state.ts_d, state.bars)
        apply_project_tempo_timesig(state.bpm, state.ts_n, state.ts_d)
        save_sampler_engine(state.sampler_engine)
      else
        r.ShowMessageBox("In diesem Slot ist noch kein Preset gespeichert.", "DF95 Beat Control Center", 0)
      end
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Render / Export")

    if ImGui.Button(ctx, "Beat-Bereich als Stems rendern (DF95_IDM_* Tracks)", 420, 0) then
      r.Undo_BeginBlock()
      render_beat_area(state.ts_n, state.ts_d, state.bars)
      r.Undo_EndBlock("DF95 BeatControl: Render Beat Stems", -1)
    end

    ImGui.Spacing(ctx)
    ImGui.TextWrapped(ctx,
      "Tipps:\n" ..
      "- Nutze die SampleDB-Scan- und Tag-Tools, um is_loop / is_speech zu setzen.\n" ..
      "- Route die DF95_IDM_* Spuren auf RS5k, TX16Wx oder Sitala-Kits.\n" ..
      "- Presets eignen sich super für Artist- / TimeSig- / Layer-Kombinationen.\n" ..
      "- Der Render-Button verwendet die Beat-Länge als Time Selection und rendert DF95_IDM_* als Stems.")

    ImGui.Spacing(ctx)
    if ImGui.Button(ctx, "Schließen", 100, 0) then
      open = false
    end
  end

  ImGui.End(ctx)

  if open then
    r.defer(main_loop)
  else
    ImGui.DestroyContext(ctx)
    ctx = nil
  end
end

main_loop()
