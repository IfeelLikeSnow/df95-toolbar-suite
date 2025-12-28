-- @description DF95_V100_Fieldrec_ArtistBeatEngine_MIDI
-- @version 1.0
-- @author DF95
-- @about
--   Artist-gesteuerte BeatEngine für Fieldrec-Kits (V95/V98).
--   Nutzt das DF95-Artist-System (Coloring_ArtistBias_v1.json / DF95_COLORING/ARTIST),
--   um abhängig vom gewählten Artist (z.B. Autechre, AphexTwin, BoardsOfCanada,
--   Squarepusher_JazzBass, IDM, Glitch, Neutral) Drum-Pattern + Humanize-Faktoren
--   zu erzeugen.
--
--   Typischer Workflow:
--     1. Fieldrec via V95/V95.2 splitten + klassifizieren.
--     2. V98_SliceKit_RS5k bauen (Kick=36, Snare=38, Hat=42).
--     3. Artist im Coloring-Artist-Dropdown wählen
--        (DF95_Menu_Coloring_Artist_Dropdown.lua).
--     4. Dieses Script ausführen:
--        -> erzeugt Track "V100_ArtistBeat_MIDI" mit artist-spezifischem Beat-Pattern.
--     5. MIDI-Track auf das SliceKit (oder beliebiges Drum-Instrument) routen.
--
--   Hinweis:
--     - Wenn kein Artist gesetzt ist, fragt das Script nach einem Artist über ein Menü
--       (Keys aus Coloring_ArtistBias_v1.json) und speichert ihn in DF95_COLORING/ARTIST.
--     - Das Pattern-Design ist stilisiert, nicht 1:1-Emulation.
--

local r = reaper

------------------------------------------------------------
-- Hilfsfunktionen
------------------------------------------------------------
local function msg(s)
  r.ShowMessageBox(s, "DF95 V100 Artist BeatEngine", 0)
end

local function get_project_tempo_timesig()
  local proj = 0
  local _, tempo, num, denom, _ = r.GetProjectTimeSignature2(proj)
  return tempo, num, denom
end

------------------------------------------------------------
-- Artist-Ermittlung (über ExtState + Coloring_ArtistBias_v1.json)
------------------------------------------------------------
local function read_artist_cfg()
  local cfg_path = r.GetResourcePath() .. "/Data/DF95/Coloring_ArtistBias_v1.json"
  local f = io.open(cfg_path, "rb")
  if not f then return {} end
  local d = f:read("*all"); f:close()
  if r.JSON_Decode then
    local ok, tbl = pcall(r.JSON_Decode, d)
    if ok and type(tbl)=="table" then return tbl end
  end
  return {}
end

local function choose_artist_if_needed()
  local _, artist = r.GetProjExtState(0, "DF95_COLORING", "ARTIST")
  if artist ~= nil and artist ~= "" then
    return artist
  end

  -- kein Artist gesetzt -> Menü basierend auf JSON-Keys anzeigen
  local cfg = read_artist_cfg()
  local keys = {}
  for k,_ in pairs(cfg) do
    keys[#keys+1] = k
  end
  if #keys == 0 then
    -- Fallback: minimaler Default
    artist = "AphexTwin"
    r.SetProjExtState(0, "DF95_COLORING", "ARTIST", artist)
    return artist
  end
  table.sort(keys)
  local menu_str = table.concat(keys, "|")
  -- kleines Popup-Menü an Mausposition
  local _,_, mx,my = r.GetMousePosition()
  gfx.init("DF95_ArtistSelect", 1,1,0,mx,my)
  local sel = gfx.showmenu(menu_str)
  gfx.quit()
  if sel < 1 or sel > #keys then
    artist = keys[1]
  else
    artist = keys[sel]
  end
  r.SetProjExtState(0, "DF95_COLORING", "ARTIST", artist)
  return artist
end

------------------------------------------------------------
-- Artist-spezifische Beat-/Humanize-Profile
------------------------------------------------------------

local function get_artist_profile(artist)
  -- wir normalisieren ein bisschen: Groß/Kleinschreibung egal
  local a = (artist or ""):lower()

  -- Flags / Parameter:
  local profile = {
    name = artist or "Unknown",
    complexity = 1.0,       -- 0.5..2.0: Dichte der Hats / Zusatz-Events
    swing = 0.0,            -- 0..0.1 Beats (16tel-Swing)
    timing_jitter = 0.0,    -- max Zufall in Beats
    vel_main = 110,
    vel_ghost = 80,
    ghost_prob = 0.0,       -- Wahrscheinlichkeit für Ghost-Hits
    hat_density = 1.0,      -- Faktor auf Hat-Pattern
    kick_variation = 0.0,   -- zusätzliche Kicks
    snare_variation = 0.0,  -- zusätzliche Snares
    breakbeat_bias = 0.0,   -- Tendenz zu offbeat Snare/Kick
  }

  if a:find("autechre") then
    profile.complexity = 1.6
    profile.swing = 0.02
    profile.timing_jitter = 0.03
    profile.ghost_prob = 0.35
    profile.hat_density = 1.8
    profile.kick_variation = 0.5
    profile.snare_variation = 0.6
    profile.breakbeat_bias = 0.7
  elseif a:find("aphextwin") then
    profile.complexity = 1.4
    profile.swing = 0.015
    profile.timing_jitter = 0.02
    profile.ghost_prob = 0.4
    profile.hat_density = 1.6
    profile.kick_variation = 0.4
    profile.snare_variation = 0.5
    profile.breakbeat_bias = 0.6
  elseif a:find("boards") or a:find("boc") then
    profile.complexity = 0.8
    profile.swing = 0.025
    profile.timing_jitter = 0.02
    profile.ghost_prob = 0.2
    profile.hat_density = 0.7
    profile.kick_variation = 0.2
    profile.snare_variation = 0.2
    profile.breakbeat_bias = 0.2
    profile.vel_main = 100
    profile.vel_ghost = 70
  elseif a:find("squarepusher") then
    profile.complexity = 1.8
    profile.swing = 0.0
    profile.timing_jitter = 0.015
    profile.ghost_prob = 0.5
    profile.hat_density = 2.2
    profile.kick_variation = 0.7
    profile.snare_variation = 0.8
    profile.breakbeat_bias = 0.8
    profile.vel_main = 120
    profile.vel_ghost = 90
  elseif a:find("idm") then
    profile.complexity = 1.3
    profile.swing = 0.01
    profile.timing_jitter = 0.02
    profile.ghost_prob = 0.3
    profile.hat_density = 1.4
    profile.kick_variation = 0.4
    profile.snare_variation = 0.4
    profile.breakbeat_bias = 0.5
  elseif a:find("glitch") then
    profile.complexity = 1.5
    profile.swing = 0.0
    profile.timing_jitter = 0.03
    profile.ghost_prob = 0.4
    profile.hat_density = 1.7
    profile.kick_variation = 0.6
    profile.snare_variation = 0.6
    profile.breakbeat_bias = 0.7
  else
    -- Neutral/Moderat/sonstige Artists -> moderater IDM-Style
    profile.complexity = 1.0
    profile.swing = 0.01
    profile.timing_jitter = 0.015
    profile.ghost_prob = 0.2
    profile.hat_density = 1.0
    profile.kick_variation = 0.3
    profile.snare_variation = 0.3
    profile.breakbeat_bias = 0.4
  end

  return profile
end

------------------------------------------------------------
-- Artist-bezogene Pattern-Generatoren (in Beats)
------------------------------------------------------------

local function build_base_patterns(beats_per_bar)
  -- Grund-Backbeat (4/4): auf 1 & 3 Kick, auf 2 & 4 Snare, 8tel Hats
  local K = {0.0, 2.0}
  local S = {1.0, 3.0}
  local H = {}
  local step = 0.5
  local t = 0.0
  while t < beats_per_bar do
    H[#H+1] = t
    t = t + step
  end
  return K, S, H
end

local function add_variations_for_artist(K, S, H, profile, beats_per_bar)
  local function add_kick(pos)
    if pos >= 0 and pos < beats_per_bar then
      K[#K+1] = pos
    end
  end
  local function add_snare(pos)
    if pos >= 0 and pos < beats_per_bar then
      S[#S+1] = pos
    end
  end
  local function add_hat(pos)
    if pos >= 0 and pos < beats_per_bar then
      H[#H+1] = pos
    end
  end

  -- Breakbeat-Bias -> Offbeats auf 1.75, 2.75, 3.75 etc.
  if profile.breakbeat_bias > 0.1 then
    local offbeats = {0.75, 1.75, 2.75, 3.75}
    for _,pos in ipairs(offbeats) do
      if math.random() < profile.breakbeat_bias then
        if math.random() < 0.5 then
          add_kick(pos)
        else
          add_snare(pos)
        end
      end
    end
  end

  -- zusätzliche Kicks relativ zu Grundpattern
  if profile.kick_variation > 0.1 then
    local candidates = {0.5, 1.5, 2.5, 3.5}
    for _,pos in ipairs(candidates) do
      if math.random() < profile.kick_variation then
        add_kick(pos)
      end
    end
  end

  -- zusätzliche Snares (Ghosts + Akzente)
  if profile.snare_variation > 0.1 then
    local candidates = {0.5, 1.5, 2.5, 3.5}
    for _,pos in ipairs(candidates) do
      if math.random() < profile.snare_variation then
        add_snare(pos)
      end
    end
  end

  -- Hat-Dichte anpassen: ggf. 16tel ergänzen
  if profile.hat_density > 1.1 then
    local step = 0.25
    local t = 0.0
    while t < beats_per_bar do
      if math.random() < (profile.hat_density - 1.0) then
        add_hat(t)
      end
      t = t + step
    end
  elseif profile.hat_density < 0.95 then
    -- Hats ausdünnen
    local keep = {}
    for _,pos in ipairs(H) do
      if math.random() < profile.hat_density then
        keep[#keep+1] = pos
      end
    end
    H = keep
  end

  return K, S, H
end

------------------------------------------------------------
-- MIDI Beat-Engine (ähnlich V97, aber artist-driven)
------------------------------------------------------------

local function create_midi_track()
  local proj = 0
  local idx = r.CountTracks(proj)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "V100_ArtistBeat_MIDI", true)
  return tr
end

local function main()
  math.randomseed(os.time())

  local tempo, num, denom = get_project_tempo_timesig()
  local beats_per_bar = num

  -- Artist auswählen
  local artist = choose_artist_if_needed()
  if not artist or artist == "" then
    artist = "AphexTwin"
  end
  local profile = get_artist_profile(artist)

  -- User nach Anzahl Takte fragen
  local default_bars = "8"
  local ret, inp = r.GetUserInputs("DF95 V100 Artist BeatEngine", 1,
                                   "Bars (Anzahl Takte)", default_bars)
  if not ret then return end
  local bars = tonumber(inp) or 8
  if bars < 1 then bars = 1 end

  local proj = 0
  local start_beat = 0.0
  local end_beat = bars * beats_per_bar
  local start_time = r.TimeMap2_beatsToTime(proj, start_beat, 0)
  local end_time   = r.TimeMap2_beatsToTime(proj, end_beat, 0)
  local item_len   = end_time - start_time

  local track = create_midi_track()
  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", start_time)
  r.SetMediaItemInfo_Value(item, "D_LENGTH",  item_len)

  local take = r.AddTakeToMediaItem(item)
  r.SetMediaItemTakeInfo_Value(take, "C_LOCK", 0)
  r.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", 0)

  local PPQ = 960
  local function beat_to_ppq(beat)
    return beat * PPQ
  end

  -- Grundmuster + Artist-Variationen
  local base_K, base_S, base_H = build_base_patterns(beats_per_bar)
  local K,S,H = add_variations_for_artist(base_K, base_S, base_H, profile, beats_per_bar)

  local K_NOTE = 36
  local S_NOTE = 38
  local H_NOTE = 42

  local vel_main = profile.vel_main or 110
  local vel_ghost = profile.vel_ghost or 80
  local note_len_beats = 0.3

  local function apply_swing_and_jitter(pos_beats, is_hat)
    local b = pos_beats
    -- 16tel-Swing: alle Off-16tel nach vorne/hinten schieben
    if profile.swing and profile.swing > 0 then
      local frac = (b * 4.0) % 1.0 -- 16tel-Index innerhalb eines Viertels
      -- wir swingen die "ungeraden" 16tel leicht
      if frac > 0.25 and frac < 0.75 then
        b = b + profile.swing * 0.5
      end
    end
    -- Jitter
    if profile.timing_jitter and profile.timing_jitter > 0 then
      local jitter = (math.random() * 2 - 1) * profile.timing_jitter
      b = b + jitter
    end
    return b
  end

  r.Undo_BeginBlock()

  -- Kicks
  for bar = 0, bars-1 do
    for _, beat in ipairs(K) do
      local pos_beats = bar * beats_per_bar + beat
      pos_beats = apply_swing_and_jitter(pos_beats, false)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, K_NOTE, vel_main, false)
    end
  end

  -- Snares (inkl. Ghost-Option)
  for bar = 0, bars-1 do
    for _, beat in ipairs(S) do
      local pos_beats = bar * beats_per_bar + beat
      local is_ghost = (profile.ghost_prob > 0 and math.random() < profile.ghost_prob * 0.3)
      local vel = is_ghost and vel_ghost or vel_main
      pos_beats = apply_swing_and_jitter(pos_beats, false)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, S_NOTE, vel, false)
      -- zusätzliche Ghost kurz davor?
      if profile.ghost_prob > 0 and math.random() < profile.ghost_prob * 0.2 then
        local ghost_beat = pos_beats - 0.1
        local g_ppq = beat_to_ppq(ghost_beat)
        local g_end = beat_to_ppq(ghost_beat + 0.2)
        r.MIDI_InsertNote(take, false, false, g_ppq, g_end, 0, S_NOTE, vel_ghost, false)
      end
    end
  end

  -- Hats
  for bar = 0, bars-1 do
    for _, beat in ipairs(H) do
      local pos_beats = bar * beats_per_bar + beat
      local vel = vel_main
      local ghost = false
      if profile.ghost_prob and profile.ghost_prob > 0 and math.random() < profile.ghost_prob then
        ghost = true
        vel = vel_ghost
      end
      pos_beats = apply_swing_and_jitter(pos_beats, true)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats * (ghost and 0.8 or 1.0))
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, H_NOTE, vel, false)
    end
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V100 Artist BeatEngine ("..(artist or "?")..")", -1)
end

main()