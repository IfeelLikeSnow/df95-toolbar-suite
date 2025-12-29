-- @description DF95_V107_Fieldrec_AdaptiveBeatEngine_MIDI
-- @version 1.2
-- @author DF95
-- @about
--   Prototypische BeatEngine für das DF95 Fieldrec/Artist/Euclid/Adaptive-System.
--
--   Diese Version:
--     * liest Artist & Style (DF95_ARTIST/NAME, DF95_STYLE/NAME),
--     * liest Adaptive Sample Info (DF95_ADAPTIVE/*, aus V105),
--     * liest Permission/Policy (DF95_ADAPTIVE_CONFIG/*, aus V106),
--     * generiert ein mehrtaktiges MIDI-Beatpattern (Kick/Snare/Hat/Perc/Extra),
--     * respektiert den Minimal-Mode ("nur vorhandenes Material") vs. Full-Mode,
--       indem Lanes ohne reale Samples im Minimal-Mode stumm bleiben,
--     * optional: kombiniert Artist-inspirierte Pattern mit Euclid-Vorgaben
--       (DF95_EUCLID_MULTI, aus V104),
--     * schreibt das Ergebnis als MIDI-Item auf den selektierten Track oder
--       legt einen neuen Beat-Track an.
--
--   WICHTIG (Prototyp-Status):
--     - Diese BeatEngine verwendet die Adaptive-Infos aktuell nur für die
--       Entscheidung "Lane aktiv ja/nein" (Minimal/Full, Fallbacks),
--       NICHT für GUID-spezifische Sample-Zuweisung.
--     - Die MIDI-Noten sind standardisiert (Kick=36, Snare=38, Hat=42, Perc=39, Extra=40),
--       und können z.B. auf ein DF95 SliceKit/RS5k geroutet werden.
--     - Spätere Versionen (V108+) können die GUID-Listen nutzen, um
--       tatsächlich Item-/Sample-spezifische Sub-Presets zu bauen.
--

local r = reaper
local math = math

------------------------------------------------------------
-- ExtState Helpers
------------------------------------------------------------

local function get_proj_ext(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if not v or v == "" then return default end
  return v
end

local function get_proj_ext_num(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  local n = tonumber(v)
  if not n then return default end
  return n
end

local function get_proj_ext_bool(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if v == "1" then return true end
  if v == "0" then return false end
  return default
end

------------------------------------------------------------
-- Artist & Style
------------------------------------------------------------

local function read_artist_style()
  local artist = get_proj_ext("DF95_ARTIST", "NAME", "Aphex Twin")
  local style  = get_proj_ext("DF95_STYLE",  "NAME", "Neutral")

  -- grobe Artist-Profile (Prototyp)
  local profiles = {
    ["Aphex Twin"] = {
      complexity = 0.9, breakbeat = 0.7, swing = 0.3, jitter = 0.2,
      hat_density = 0.8, ghost_prob = 0.4,
    },
    ["Autechre"] = {
      complexity = 1.0, breakbeat = 0.8, swing = 0.1, jitter = 0.6,
      hat_density = 0.6, ghost_prob = 0.7,
    },
    ["Boards of Canada"] = {
      complexity = 0.4, breakbeat = 0.2, swing = 0.5, jitter = 0.1,
      hat_density = 0.5, ghost_prob = 0.3,
    },
    ["Squarepusher"] = {
      complexity = 1.0, breakbeat = 0.9, swing = 0.4, jitter = 0.3,
      hat_density = 0.9, ghost_prob = 0.6,
    },
    ["Burial"] = {
      complexity = 0.5, breakbeat = 0.1, swing = 0.8, jitter = 0.4,
      hat_density = 0.7, ghost_prob = 0.2,
    },
  }

  local base = profiles[artist] or profiles["Aphex Twin"]

  -- Style-Layer als einfache Modifikatoren
  if style == "IDM_Style" then
    base.complexity = math.min(1.0, base.complexity + 0.2)
    base.breakbeat  = math.min(1.0, base.breakbeat + 0.2)
  elseif style == "Glitch_Style" then
    base.jitter     = math.min(1.0, base.jitter + 0.4)
    base.ghost_prob = math.min(1.0, base.ghost_prob + 0.2)
  elseif style == "WarmTape_Style" then
    base.jitter     = math.max(0.0, base.jitter - 0.2)
    base.hat_density= math.max(0.0, base.hat_density - 0.1)
  elseif style == "HarshDigital_Style" then
    base.hat_density= math.min(1.0, base.hat_density + 0.2)
  end

  base.artist = artist
  base.style  = style
  return base
end

------------------------------------------------------------
-- Adaptive Sample Info (V105)
------------------------------------------------------------

local function read_adaptive()
  local sect = "DF95_ADAPTIVE"
  local info = {}

  info.kick_count  = get_proj_ext_num(sect, "KICK_REAL_COUNT", 0)
  info.snare_count = get_proj_ext_num(sect, "SNARE_REAL_COUNT", 0)
  info.hat_count   = get_proj_ext_num(sect, "HAT_REAL_COUNT", 0)
  info.perc_count  = get_proj_ext_num(sect, "PERC_REAL_COUNT", 0)
  info.other_count = get_proj_ext_num(sect, "OTHER_COUNT", 0)

  info.kick_fb  = get_proj_ext(sect, "KICK_FALLBACK", "")
  info.snare_fb = get_proj_ext(sect, "SNARE_FALLBACK", "")
  info.hat_fb   = get_proj_ext(sect, "HAT_FALLBACK", "")
  info.perc_fb  = get_proj_ext(sect, "PERC_FALLBACK", "")

  info.kick_virt  = get_proj_ext_num(sect, "KICK_VIRTUAL_COUNT", 0)
  info.snare_virt = get_proj_ext_num(sect, "SNARE_VIRTUAL_COUNT", 0)
  info.hat_virt   = get_proj_ext_num(sect, "HAT_VIRTUAL_COUNT", 0)
  info.perc_virt  = get_proj_ext_num(sect, "PERC_VIRTUAL_COUNT", 0)

  return info
end

------------------------------------------------------------
-- Permission / Policy (V106)
------------------------------------------------------------

local function read_policy()
  local sect = "DF95_ADAPTIVE_CONFIG"
  local policy = {}

  policy.allow_reconstruct_kick  = get_proj_ext_bool(sect, "ALLOW_RECONSTRUCT_KICK", false)
  policy.allow_reconstruct_snare = get_proj_ext_bool(sect, "ALLOW_RECONSTRUCT_SNARE", false)
  policy.allow_reconstruct_hat   = get_proj_ext_bool(sect, "ALLOW_RECONSTRUCT_HAT", false)
  policy.allow_virtual_dupes     = get_proj_ext_bool(sect, "ALLOW_VIRTUAL_DUPES", false)
  policy.prefer_minimal_beat     = get_proj_ext_bool(sect, "PREFER_MINIMAL_BEAT", true)
  policy.prefer_full_beat        = get_proj_ext_bool(sect, "PREFER_FULL_BEAT", false)

  -- einfachen Mode ableiten
  if policy.prefer_full_beat then
    policy.mode = "full"
  else
    policy.mode = "minimal"
  end

------------------------------------------------------------
-- Time Signature / Meter (V109)
------------------------------------------------------------

local function read_time_config()
  local sect = "DF95_TIME"
  local cfg = {}
  cfg.num = get_proj_ext_num(sect, "NUMERATOR", 0)
  cfg.denom = get_proj_ext(sect, "DENOMINATOR", "")
  cfg.bar_steps = get_proj_ext_num(sect, "BAR_STEPS", 0)
  cfg.mode = get_proj_ext(sect, "MODE", "Artist+Euclid (Hybrid)")
  cfg.bars = get_proj_ext_num(sect, "BARS", 4)
  cfg.lock_euclid = get_proj_ext(sect, "LOCK_EUCLID_TO_METER", "1") == "1"
  return cfg
end

  return policy
end

------------------------------------------------------------
-- Euclid Info (V104) – optionales Overlay
------------------------------------------------------------

local function euclid_pattern(steps, pulses)
  local pattern = {}
  if pulses <= 0 then
    for i=1,steps do pattern[i] = false end
    return pattern
  end
  if pulses >= steps then
    for i=1,steps do pattern[i] = true end
    return pattern
  end

  local pauses = steps - pulses
  local groups = {}
  for i=1,pulses do groups[i] = {1} end
  local gidx = 1
  while pauses > 0 do
    groups[gidx][#groups[gidx]+1] = 0
    pauses = pauses - 1
    gidx = gidx + 1
    if gidx > pulses then gidx = 1 end
  end

  local out = {}
  for _,g in ipairs(groups) do
    for _,v in ipairs(g) do
      out[#out+1] = (v == 1)
    end
  end

  while #out > steps do table.remove(out) end
  while #out < steps do out[#out+1] = false end

  return out
end

local function rotate_pattern(pattern, rot)
  local n = #pattern
  if n == 0 then return pattern end
  rot = rot % n
  if rot == 0 then return pattern end
  local out = {}
  for i=1,n do
    local idx = ((i-1-rot) % n) + 1
    out[i] = pattern[idx]
  end
  return out
end

local function read_euclid()
  local sect = "DF95_EUCLID_MULTI"
  local steps = get_proj_ext_num(sect, "STEPS", 0)
  local div = get_proj_ext(sect, "DIVISION", "1/16")

  local function lane(id_default_pulses)
    return {
      pulses = get_proj_ext_num(sect, id_default_pulses .. "_PULSES", 0),
      rot    = get_proj_ext_num(sect, id_default_pulses .. "_ROT", 0),
      en     = get_proj_ext_bool(sect, id_default_pulses .. "_EN", false),
    }
  end

  local info = {
    steps = steps,
    division = div,
    lanes = {
      KICK  = lane("KICK"),
      SNARE = lane("SNARE"),
      HAT   = lane("HAT"),
      EXTRA = lane("EXTRA"),
    }
  }

  return info
end

------------------------------------------------------------
-- Pattern-Generation (Artist-basiert)
------------------------------------------------------------

local function generate_artist_patterns(ctx, bars, steps_per_bar)
  local total_steps = bars * steps_per_bar
  local lanes = {
    KICK  = {pattern = {}},
    SNARE = {pattern = {}},
    HAT   = {pattern = {}},
    PERC  = {pattern = {}},
    EXTRA = {pattern = {}},
  }

  local complexity    = ctx.complexity or 0.7
  local breakbeat     = ctx.breakbeat or 0.5
  local hat_density   = ctx.hat_density or 0.7
  local ghost_prob    = ctx.ghost_prob or 0.3

  -- einfache Wahrscheinlichkeitsprofile für Positionen in einem 16er-Raster
  local function base_probs_for_step(pos)
    -- pos = 0..steps_per_bar-1
    local is_beat       = (pos % (steps_per_bar/4) == 0)      -- 1,2,3,4
    local is_offbeat_8  = (pos % (steps_per_bar/8) == 0)      -- Achtel
    local is_16th       = true

    local pk, ps, ph, pp = 0.0, 0.0, 0.0, 0.0

    -- Kick: starke Betonung auf 1 & 3
    if is_beat and (pos == 0 or pos == steps_per_bar/2) then
      pk = 0.8
    elseif is_offbeat_8 then
      pk = 0.3
    end

    -- Snare: Betonung auf 2 & 4
    if is_beat and (pos == steps_per_bar/4 or pos == 3*steps_per_bar/4) then
      ps = 0.9
    elseif is_offbeat_8 then
      ps = 0.2
    end

    -- Hats: laufende 16tel plus leichte Betonung
    if is_16th then
      ph = 0.3 + hat_density * 0.5
    end

    -- Perc: mehr in komplexeren Settings
    if complexity > 0.5 and is_offbeat_8 then
      pp = 0.2 + (complexity-0.5) * 0.5
    end

    return pk, ps, ph, pp
  end

  math.randomseed(os.time())

  for bar=0,bars-1 do
    for s=0,steps_per_bar-1 do
      local step_index = bar * steps_per_bar + s + 1
      local pk, ps, ph, pp = base_probs_for_step(s)

      -- Artist-/Style-Skalierung
      pk = pk * (0.7 + complexity*0.3)
      ps = ps * (0.7 + breakbeat*0.3)
      ph = ph * (0.5 + hat_density*0.5)
      pp = pp * (0.5 + complexity*0.5)

      if math.random() < pk then lanes.KICK.pattern[step_index] = true end
      if math.random() < ps then lanes.SNARE.pattern[step_index] = true end
      if math.random() < ph then lanes.HAT.pattern[step_index] = true end
      if math.random() < pp then lanes.PERC.pattern[step_index] = true end

      -- EXTRA-Lane: z.B. Ghost-Snare oder FX an random Stellen
      if math.random() < ghost_prob * 0.2 then
        lanes.EXTRA.pattern[step_index] = true
      end
    end
  end

  return lanes, total_steps
end

------------------------------------------------------------
-- Euclid-Overlay auf existierende Patterns
------------------------------------------------------------

local function apply_euclid_overlay(lanes, total_steps, steps_per_bar, meter_mode)
  local eu = read_euclid()
  if not eu or not eu.steps or eu.steps <= 0 then return end

  -- meter_mode:
  -- "Artist+Euclid (Hybrid)" -> OR-Overlay (Standard)
  -- "Artist only"            -> keine Euclid-Überlagerung
  -- "Euclid only"            -> Artist-Pattern ignorieren, nur Euclid-Muster verwenden
  meter_mode = meter_mode or "Artist+Euclid (Hybrid)"
  if meter_mode == "Artist only" then
    return
  end

  local e_steps = eu.steps

  local function lane_euclid(laneKey, laneInfo)
    local laneConf = eu.lanes[laneKey]
    if not laneConf or not laneConf.en or laneConf.pulses <= 0 then return end
    local base_pat = euclid_pattern(e_steps, laneConf.pulses)
    base_pat = rotate_pattern(base_pat, laneConf.rot or 0)

    if meter_mode == "Euclid only" then
      -- Erst alles löschen, dann nur Euclid setzen
      for i=1,total_steps do
        laneInfo.pattern[i] = false
      end
    end

    for i=1,total_steps do
      local pos_in_e = ((i-1) % e_steps) + 1
      if base_pat[pos_in_e] then
        laneInfo.pattern[i] = true
      end
    end
  end

  lane_euclid("KICK",  lanes.KICK)
  lane_euclid("SNARE", lanes.SNARE)
  lane_euclid("HAT",   lanes.HAT)
  lane_euclid("EXTRA", lanes.EXTRA)
end

------------------------------------------------------------
-- Mode-Filter: Minimal vs. Full
: Minimal vs. Full
------------------------------------------------------------

local function apply_mode_filter(lanes, total_steps, adaptive, policy)
  -- Helper: echte Verfügbarkeit
  local function real_count(cat)
    if cat == "KICK"  then return adaptive.kick_count end
    if cat == "SNARE" then return adaptive.snare_count end
    if cat == "HAT"   then return adaptive.hat_count end
    if cat == "PERC"  then return adaptive.perc_count end
    return 0
  end

  local function has_fallback(cat)
    if cat == "KICK"  then return adaptive.kick_fb  ~= "" end
    if cat == "SNARE" then return adaptive.snare_fb ~= "" end
    if cat == "HAT"   then return adaptive.hat_fb   ~= "" end
    if cat == "PERC"  then return adaptive.perc_fb  ~= "" end
    return false
  end

  local function lane_cat(laneName)
    if laneName == "KICK"  then return "KICK" end
    if laneName == "SNARE" then return "SNARE" end
    if laneName == "HAT"   then return "HAT" end
    if laneName == "PERC"  then return "PERC" end
    if laneName == "EXTRA" then return "PERC" end -- EXTRA = Perc/FX-artig
    return "OTHER"
  end

  for lname, lane in pairs(lanes) do
    local cat = lane_cat(lname)
    local rc = real_count(cat)

    if policy.mode == "minimal" then
      -- Nur Lanes mit realen Samples sind erlaubt
      if rc <= 0 then
        for i=1,total_steps do lane.pattern[i] = false end
      end
    else
      -- Full-Mode: Fallback und Rekonstruktion erlaubt?
      if rc <= 0 then
        local allow_recon = false
        if cat == "KICK"  then allow_recon = policy.allow_reconstruct_kick end
        if cat == "SNARE" then allow_recon = policy.allow_reconstruct_snare end
        if cat == "HAT"   then allow_recon = policy.allow_reconstruct_hat end
        if cat == "PERC"  then allow_recon = true end -- Perc relativ frei

        if (not allow_recon) or (not has_fallback(cat)) then
          -- trotzdem stumm, wenn Rekonstruktion nicht erlaubt oder kein Fallback
          for i=1,total_steps do lane.pattern[i] = false end
        else
          -- Fallback wäre möglich -> Lane bleibt aktiv (Prototyp: wir muten sie NICHT)
          -- Spätere Engine könnte hier Samples aus Fallback-Kategorie ziehen.
        end
      end
    end
  end
end

------------------------------------------------------------
-- Beat als MIDI auf einen Track schreiben
------------------------------------------------------------

local function get_or_create_target_track()
  local sel_track = r.GetSelectedTrack(0, 0)
  if sel_track then return sel_track end

  r.Undo_BeginBlock()
  r.InsertTrackAtIndex(r.CountTracks(0), true)
  local tr = r.GetTrack(0, r.CountTracks(0)-1)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95_V107_Beat", true)
  r.Undo_EndBlock("DF95 V107 BeatEngine: Track erstellt", -1)
  return tr
end

local function write_midi(lanes, total_steps, steps_per_bar, bars, ctx, policy)
  local track = get_or_create_target_track()
  if not track then
    r.ShowMessageBox("Kein Track gefunden/erstellbar.", "DF95 V107", 0)
    return
  end

  local proj = 0
  local start_time = r.GetCursorPosition()
  local _, start_beat = r.TimeMap2_timeToBeats(proj, start_time)
  local beats_per_bar = 4.0
  local step_beat = beats_per_bar / steps_per_bar
  local total_beats = bars * beats_per_bar
  local end_time = r.TimeMap2_beatsToTime(proj, start_beat + total_beats, 0)

  r.Undo_BeginBlock()

  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", start_time)
  r.SetMediaItemInfo_Value(item, "D_LENGTH", end_time - start_time)
  local take = r.AddTakeToMediaItem(item)
  local PPQ = 960
  local function beat_to_ppq(b) return b * PPQ end

  local function lane_note(lname)
    if lname == "KICK"  then return 36 end
    if lname == "SNARE" then return 38 end
    if lname == "HAT"   then return 42 end
    if lname == "PERC"  then return 39 end
    if lname == "EXTRA" then return 40 end
    return 36
  end

  -- Velocity-Basis je Lane
  local base_vel = {
    KICK  = 112,
    SNARE = 108,
    HAT   = 96,
    PERC  = 100,
    EXTRA = 90,
  }

  -- kleine Artist-/Style-Abwandlungen
  local function lane_vel(lname, step_idx)
    local v = base_vel[lname] or 100
    local pos_in_bar = (step_idx-1) % steps_per_bar
    -- einfache Akzentuierung auf Beats
    if pos_in_bar == 0 or pos_in_bar == steps_per_bar/4*2 then
      v = v + 8
    end
    if ctx.style == "Glitch_Style" then
      v = v + math.random(-12, 12)
    end
    if v < 1 then v = 1 end
    if v > 127 then v = 127 end
    return v
  end

  local note_len_beats = step_beat * 0.8

  for lname, lane in pairs(lanes) do
    local note_num = lane_note(lname)
    for step_idx=1,total_steps do
      if lane.pattern[step_idx] then
        local beat_pos = start_beat + (step_idx-1) * step_beat
        local s_ppq = beat_to_ppq(beat_pos - start_beat)
        local e_ppq = beat_to_ppq(beat_pos - start_beat + note_len_beats)
        local vel = lane_vel(lname, step_idx)
        r.MIDI_InsertNote(take, false, false, s_ppq, e_ppq, 0, note_num, vel, false)
      end
    end
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()

  local msg = string.format(
    "DF95 V107 BeatEngine fertig. Mode: %s\nArtist: %s / Style: %s\nBars: %d, Steps/Bar: %d",
    policy.mode or "minimal",
    ctx.artist or "unknown",
    ctx.style or "unknown",
    bars, steps_per_bar
  )
  r.ShowMessageBox(msg, "DF95 V107", 0)

  r.Undo_EndBlock("DF95 V107 BeatEngine – MIDI erstellt", -1)
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local ctx    = read_artist_style()
  local adapt  = read_adaptive()
  local policy = read_policy()

  -- Wenn gar keine Adaptive-Infos: Hinweis anzeigen
  local total_real = (adapt.kick_count or 0) + (adapt.snare_count or 0) + (adapt.hat_count or 0)
                      + (adapt.perc_count or 0) + (adapt.other_count or 0)
  if total_real == 0 then
    r.ShowMessageBox(
      "Keine DF95_ADAPTIVE-Infos gefunden. Bitte zuerst:\n" ..
      "1. Fieldrec-Slices selektieren\n" ..
      "2. DF95_V105_AdaptiveSampleEngine_FieldrecKit ausführen\n" ..
      "3. Optional: DF95_V106_AdaptiveBeat_PermissionPanel konfigurieren.",
      "DF95 V107", 0)
    return
  end

  -- Pattern-Grundraster: Bars & Steps/Bar
  local bars = 4
  local steps_per_bar = 16

  -- Time Signature / Meter (V109)
  local time_cfg = read_time_config()
  if time_cfg then
    if time_cfg.bar_steps and time_cfg.bar_steps > 0 then
      steps_per_bar = time_cfg.bar_steps
    else
      local e_steps = get_proj_ext_num("DF95_EUCLID_MULTI", "STEPS", 0)
      if e_steps > 0 then
        steps_per_bar = e_steps
      end
    end
    if time_cfg.bars and time_cfg.bars > 0 then
      bars = time_cfg.bars
    end
  else
    local e_steps = get_proj_ext_num("DF95_EUCLID_MULTI", "STEPS", 0)
    if e_steps > 0 then
      steps_per_bar = e_steps
    end
  end

  local lanes, total_steps = generate_artist_patterns(ctx, bars, steps_per_bar)

  -- Optional: Euclid-Overlay (abhängig von Meter Mode)
  local meter_mode = time_cfg and time_cfg.mode or "Artist+Euclid (Hybrid)"
  apply_euclid_overlay(lanes, total_steps, steps_per_bar, meter_mode)

  -- Mode-Filter (Minimal vs. Full)
  apply_mode_filter(lanes, total_steps, adapt, policy)

  -- MIDI schreiben
  write_midi(lanes, total_steps, steps_per_bar, bars, ctx, policy)
end

main()
