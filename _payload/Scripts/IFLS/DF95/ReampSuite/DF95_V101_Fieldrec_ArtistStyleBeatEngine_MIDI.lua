-- @description DF95_V101_Fieldrec_ArtistStyleBeatEngine_MIDI
-- @version 1.0
-- @author DF95
-- @about
--   Artist+Style Layer BeatEngine für Fieldrec-Kits (V95/V98).
--   Trennung von "Artist" (konkret: Aphex Twin, Autechre, Boards of Canada, Squarepusher)
--   und "Style" (IDM, Glitch, WarmTape, HarshDigital, Neutral).
--
--   Artist bestimmt in diesem Script vor allem die "musikalische Persönlichkeit"
--   (Muster-Komplexität, Breakbeat-Bias, Ghost-Note-Verhalten).
--   Style bestimmt eine zusätzliche Schicht an "Verhaltens-Bias"
--   (z.B. mehr/weniger Swing, mehr/weniger Hats, jitter etc.).
--
--   Typischer Workflow:
--     1. Fieldrec via V95/V95.2 splitten + klassifizieren.
--     2. V98_SliceKit_RS5k bauen (Kick=36, Snare=38, Hat=42).
--     3. Artist und Style wählen (in diesem Script oder via DF95-UI).
--     4. Dieses Script ausführen:
--        -> erzeugt Track "V101_ArtistStyleBeat_MIDI" mit kombiniertem Artist+Style-Pattern.
--     5. MIDI-Track auf dein SliceKit routen.
--
--   Hinweis:
--     - Die vier Artists sind absichtlich klar begrenzt:
--          * Aphex Twin
--          * Autechre
--          * Boards of Canada
--          * Squarepusher
--       IDM / Glitch usw. werden als Styles interpretiert, NICHT als Artists.
--

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function msg(s)
  r.ShowMessageBox(s, "DF95 V101 Artist+Style BeatEngine", 0)
end

local function get_project_tempo_timesig()
  local proj = 0
  local _, tempo, num, denom, _ = r.GetProjectTimeSignature2(proj)
  return tempo, num, denom
end

------------------------------------------------------------
-- Artist/Style Auswahl + Persistenz (ProjExtState)
------------------------------------------------------------

local ARTIST_KEY = "DF95_ARTIST"
local STYLE_KEY  = "DF95_STYLE"

local ARTIST_EXT_KEY = "NAME"
local STYLE_EXT_KEY  = "NAME"

local function get_or_choose_artist()
  local _, cur = r.GetProjExtState(0, ARTIST_KEY, ARTIST_EXT_KEY)

  local valid = {
    "Aphex Twin",
    "Autechre",
    "Boards of Canada",
    "Squarepusher",
  }

  -- Normalisieren: ältere Werte wie "AphexTwin" etc. mappen
  local function normalize_artist(a)
    if not a or a == "" then return nil end
    local al = a:lower()
    if al:find("aphextwin") then return "Aphex Twin" end
    if al:find("autechre") then return "Autechre" end
    if al:find("boards") or al:find("boc") then return "Boards of Canada" end
    if al:find("square") then return "Squarepusher" end
    return nil
  end

  local norm = normalize_artist(cur)
  if norm then
    return norm
  end

  -- Menü anzeigen
  local menu_str = table.concat(valid, "|")
  local _,_, mx,my = r.GetMousePosition()
  gfx.init("DF95 Artist Select", 1,1,0,mx,my)
  local sel = gfx.showmenu(menu_str)
  gfx.quit()
  if sel < 1 or sel > #valid then
    norm = valid[1]
  else
    norm = valid[sel]
  end
  r.SetProjExtState(0, ARTIST_KEY, ARTIST_EXT_KEY, norm)
  return norm
end

local function get_or_choose_style()
  local _, cur = r.GetProjExtState(0, STYLE_KEY, STYLE_EXT_KEY)

  local styles = {
    "Neutral",
    "IDM_Style",
    "Glitch_Style",
    "WarmTape_Style",
    "HarshDigital_Style",
  }

  local function normalize_style(s)
    if not s or s == "" then return nil end
    local sl = s:lower()
    if sl == "neutral" then return "Neutral" end
    if sl:find("idm") then return "IDM_Style" end
    if sl:find("glitch") then return "Glitch_Style" end
    if sl:find("warm") or sl:find("tape") then return "WarmTape_Style" end
    if sl:find("harsh") or sl:find("digital") then return "HarshDigital_Style" end
    return nil
  end

  local norm = normalize_style(cur)
  if norm then
    return norm
  end

  -- Menü anzeigen
  local menu_str = table.concat(styles, "|")
  local _,_, mx,my = r.GetMousePosition()
  gfx.init("DF95 Style Select", 1,1,0,mx,my)
  local sel = gfx.showmenu(menu_str)
  gfx.quit()
  if sel < 1 or sel > #styles then
    norm = styles[1]
  else
    norm = styles[sel]
  end
  r.SetProjExtState(0, STYLE_KEY, STYLE_EXT_KEY, norm)
  return norm
end

------------------------------------------------------------
-- Artist-/Style-Profile
------------------------------------------------------------

local function get_artist_profile(artist)
  -- Basisprofile, wie stark jeder Artist bestimmte Eigenschaften ausprägt.
  -- Werte ~ 0..2
  local p = {
    name = artist or "Unknown",
    complexity = 1.0,
    breakbeat_bias = 0.0,
    ghost_prob = 0.0,
    hat_density = 1.0,
    swing = 0.0,
    jitter = 0.0,
    vel_main = 110,
    vel_ghost = 80,
  }

  if artist == "Autechre" then
    p.complexity      = 1.6
    p.breakbeat_bias  = 0.8
    p.ghost_prob      = 0.35
    p.hat_density     = 1.8
    p.swing           = 0.02
    p.jitter          = 0.03
    p.vel_main        = 115
    p.vel_ghost       = 85
  elseif artist == "Aphex Twin" then
    p.complexity      = 1.4
    p.breakbeat_bias  = 0.6
    p.ghost_prob      = 0.4
    p.hat_density     = 1.6
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 112
    p.vel_ghost       = 82
  elseif artist == "Boards of Canada" then
    p.complexity      = 0.8
    p.breakbeat_bias  = 0.2
    p.ghost_prob      = 0.2
    p.hat_density     = 0.7
    p.swing           = 0.03
    p.jitter          = 0.02
    p.vel_main        = 100
    p.vel_ghost       = 70
  elseif artist == "Squarepusher" then
    p.complexity      = 1.9
    p.breakbeat_bias  = 0.9
    p.ghost_prob      = 0.5
    p.hat_density     = 2.2
    p.swing           = 0.0
    p.jitter          = 0.015
    p.vel_main        = 120
    p.vel_ghost       = 90
  end

  return p
end

local function get_style_profile(style)
  -- Style wirkt als "Layer" auf das Artist-Profil (Multiplikatoren / Offsets)
  -- Werte ~ 0..2
  local s = {
    name = style or "Neutral",
    complexity_mul = 1.0,
    breakbeat_mul  = 1.0,
    ghost_mul      = 1.0,
    hat_density_mul = 1.0,
    swing_add      = 0.0,
    jitter_add     = 0.0,
    vel_main_mul   = 1.0,
    vel_ghost_mul  = 1.0,
  }

  if style == "Neutral" then
    -- keine Änderung
  elseif style == "IDM_Style" then
    s.complexity_mul   = 1.2
    s.breakbeat_mul    = 1.1
    s.ghost_mul        = 1.1
    s.hat_density_mul  = 1.1
    s.swing_add        = 0.005
    s.jitter_add       = 0.005
  elseif style == "Glitch_Style" then
    s.complexity_mul   = 1.4
    s.breakbeat_mul    = 1.3
    s.ghost_mul        = 1.3
    s.hat_density_mul  = 1.3
    s.swing_add        = 0.0
    s.jitter_add       = 0.01
  elseif style == "WarmTape_Style" then
    s.complexity_mul   = 0.9
    s.breakbeat_mul    = 0.9
    s.ghost_mul        = 0.9
    s.hat_density_mul  = 0.8
    s.swing_add        = 0.01
    s.jitter_add       = 0.003
    s.vel_main_mul     = 0.92
    s.vel_ghost_mul    = 0.9
  elseif style == "HarshDigital_Style" then
    s.complexity_mul   = 1.3
    s.breakbeat_mul    = 1.4
    s.ghost_mul        = 1.2
    s.hat_density_mul  = 1.2
    s.swing_add        = -0.005
    s.jitter_add       = 0.008
    s.vel_main_mul     = 1.05
    s.vel_ghost_mul    = 1.05
  end

  return s
end

local function merge_profiles(artist_p, style_p)
  local r = {}

  r.name = (artist_p.name or "?") .. " + " .. (style_p.name or "?")

  r.complexity = (artist_p.complexity or 1.0) * (style_p.complexity_mul or 1.0)
  r.breakbeat_bias = (artist_p.breakbeat_bias or 0.0) * (style_p.breakbeat_mul or 1.0)
  r.ghost_prob = (artist_p.ghost_prob or 0.0) * (style_p.ghost_mul or 1.0)
  r.hat_density = (artist_p.hat_density or 1.0) * (style_p.hat_density_mul or 1.0)

  r.swing = (artist_p.swing or 0.0) + (style_p.swing_add or 0.0)
  r.jitter = (artist_p.jitter or 0.0) + (style_p.jitter_add or 0.0)

  r.vel_main = (artist_p.vel_main or 110) * (style_p.vel_main_mul or 1.0)
  r.vel_ghost = (artist_p.vel_ghost or 80) * (style_p.vel_ghost_mul or 1.0)

  -- clamp some values
  if r.hat_density < 0.1 then r.hat_density = 0.1 end
  if r.hat_density > 2.5 then r.hat_density = 2.5 end
  if r.complexity < 0.3 then r.complexity = 0.3 end
  if r.complexity > 2.5 then r.complexity = 2.5 end

  return r
end

------------------------------------------------------------
-- Pattern-Generation
------------------------------------------------------------

local function build_base_patterns(beats_per_bar)
  -- Grundgerüst: 4/4 Backbeat + 8tel Hats
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

local function add_variations(K, S, H, prof, beats_per_bar)
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

  local complexity = prof.complexity or 1.0

  -- Breakbeat-Bias: Offbeat-Snare/Kick-Kandidaten
  local bb = prof.breakbeat_bias or 0.0
  if bb > 0.05 then
    local offbeats = {0.75, 1.75, 2.75, 3.75}
    for _,pos in ipairs(offbeats) do
      if math.random() < bb then
        if math.random() < 0.5 then add_kick(pos) else add_snare(pos) end
      end
    end
  end

  -- Zusätzliche Kicks/Snares bei steigender Komplexität
  local kv = math.max(0, complexity - 1.0) -- Anteil über 1.0
  local sv = kv

  if kv > 0.05 then
    local candidates = {0.5, 1.5, 2.5, 3.5}
    for _,pos in ipairs(candidates) do
      if math.random() < kv then add_kick(pos) end
    end
  end
  if sv > 0.05 then
    local candidates = {0.25, 0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75}
    for _,pos in ipairs(candidates) do
      if math.random() < sv * 0.7 then add_snare(pos) end
    end
  end

  -- Hat-Dichte
  local hd = prof.hat_density or 1.0
  if hd > 1.05 then
    local step = 0.25
    local t = 0.0
    while t < beats_per_bar do
      if math.random() < (hd - 1.0) then add_hat(t) end
      t = t + step
    end
  elseif hd < 0.95 then
    local keep = {}
    for _,pos in ipairs(H) do
      if math.random() < hd then keep[#keep+1] = pos end
    end
    H = keep
  end

  return K, S, H
end

------------------------------------------------------------
-- MIDI-Beat erzeugen
------------------------------------------------------------

local function create_midi_track()
  local proj = 0
  local idx = r.CountTracks(proj)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "V101_ArtistStyleBeat_MIDI", true)
  return tr
end

local function main()
  math.randomseed(os.time())

  local tempo, num, denom = get_project_tempo_timesig()
  local beats_per_bar = num

  -- Artist + Style wählen
  local artist = get_or_choose_artist()
  local style  = get_or_choose_style()

  local artist_p = get_artist_profile(artist)
  local style_p  = get_style_profile(style)
  local prof     = merge_profiles(artist_p, style_p)

  -- User nach Bars fragen
  local default_bars = "8"
  local ret, inp = r.GetUserInputs("DF95 V101 Artist+Style BeatEngine", 1,
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

  -- Patterns erstellen
  local base_K, base_S, base_H = build_base_patterns(beats_per_bar)
  local K,S,H = add_variations(base_K, base_S, base_H, prof, beats_per_bar)

  local K_NOTE = 36
  local S_NOTE = 38
  local H_NOTE = 42

  local vel_main  = prof.vel_main or 110
  local vel_ghost = prof.vel_ghost or 80
  local note_len_beats = 0.3

  local swing = prof.swing or 0.0
  local jitter = prof.jitter or 0.0
  local ghost_prob = prof.ghost_prob or 0.0

  local function apply_swing_and_jitter(pos_beats, is_hat)
    local b = pos_beats
    if swing ~= 0 then
      local frac = (b * 4.0) % 1.0
      if frac > 0.25 and frac < 0.75 then
        b = b + swing * 0.5
      end
    end
    if jitter ~= 0 then
      local j = (math.random() * 2 - 1) * jitter
      b = b + j
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

  -- Snares
  for bar = 0, bars-1 do
    for _, beat in ipairs(S) do
      local pos_beats = bar * beats_per_bar + beat
      local vel = vel_main
      local is_ghost = false
      if ghost_prob > 0 and math.random() < ghost_prob * 0.3 then
        is_ghost = true
        vel = vel_ghost
      end
      pos_beats = apply_swing_and_jitter(pos_beats, false)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, S_NOTE, vel, false)

      if ghost_prob > 0 and math.random() < ghost_prob * 0.2 then
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
      local is_ghost = false
      if ghost_prob > 0 and math.random() < ghost_prob then
        is_ghost = true
        vel = vel_ghost
      end
      pos_beats = apply_swing_and_jitter(pos_beats, true)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats * (is_ghost and 0.8 or 1.0))
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, H_NOTE, vel, false)
    end
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V101 Artist+Style BeatEngine ("..(prof.name or "?")..")", -1)
end

main()
