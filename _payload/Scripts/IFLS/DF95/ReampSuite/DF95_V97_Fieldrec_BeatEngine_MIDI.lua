-- @description DF95_V97_Fieldrec_BeatEngine_MIDI
-- @version 1.0
-- @author DF95
-- @about
--   Erzeugt einen MIDI-Beat aus den V95/V95.1-Klassen (Kick/Snare/Hat-Rollen).
--   Idee:
--     - V95/V95.1 haben deine Fieldrec-Slices bereits klassifiziert:
--         * LOW_PERC   -> Kick
--         * SNARE_PERC -> Snare
--         * HAT_CYMBAL -> Hat
--     - Dieses Script erzeugt einen neuen MIDI-Track "V97_Beat_MIDI"
--       und schreibt Noten gemäß eines wählbaren Beat-Styles:
--         * 1 = Basic
--         * 2 = Tegra-ish
--         * 3 = Squarepusher-ish
--   Hinweis:
--     - Dieses Script lädt keine Samples in einen Sampler.
--       Es erzeugt nur das MIDI-Pattern.
--     - Du kannst den MIDI-Track auf einen Sampler routen, der
--       z.B. aus den V95-Slices gebaut wurde (RS5k, DrumRack, etc.).
--     - Standard-Notenbelegung (General MIDI Drum Map):
--         * Kick  = 36
--         * Snare = 38
--         * Hat   = 42

local r = reaper

------------------------------------------------------------
local function msg(s) r.ShowMessageBox(s, "DF95 V97 BeatEngine MIDI", 0) end

local function get_project_tempo_timesig()
  local proj = 0
  local _, tempo, num, denom, _ = r.GetProjectTimeSignature2(proj)
  return tempo, num, denom
end

------------------------------------------------------------
-- Beat-Patterns (identisch zur Audio-Variante)
------------------------------------------------------------
local function get_patterns(style, beats_per_bar)
  local K, S, H = {}, {}, {}
  if style == "1" then
    K = {0, 2}
    S = {1, 3}
    H = {}
    local step = 0.5
    local t = 0.0
    while t < beats_per_bar do
      table.insert(H, t)
      t = t + step
    end
  elseif style == "2" then
    K = {0, 1.75, 2.5}
    S = {1, 3.25}
    H = {}
    local steps = {0,0.5,1,1.5,2,2.5,3,3.5}
    for _,t in ipairs(steps) do
      if t ~= 2 then
        table.insert(H, t)
      end
    end
  else
    K = {0, 2.25}
    S = {1, 1.75, 3}
    H = {}
    local step = 0.25
    local t = 0.0
    while t < beats_per_bar do
      local p = 0.6
      if math.random() < p then
        table.insert(H, t)
      end
      t = t + step
    end
  end
  return K, S, H
end

------------------------------------------------------------
local function create_midi_track()
  local proj = 0
  local idx = r.CountTracks(proj)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "V97_Beat_MIDI", true)
  return tr
end

------------------------------------------------------------
local function main()
  math.randomseed(os.time())

  local tempo, num, denom = get_project_tempo_timesig()
  local beats_per_bar = num

  local default_vals = "2,4"
  local ret, vals = r.GetUserInputs("DF95 V97 BeatEngine MIDI", 2,
    "Style (1=Basic,2=Tegra,3=Square),Bars (Anzahl Takte)", default_vals)
  if not ret then return end
  local style, bars = vals:match("([^,]+),([^,]+)")
  style = style or "2"
  bars = tonumber(bars) or 4
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

  -- Aktiviere MIDI
  r.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", 0)

  local K_pattern, S_pattern, H_pattern = get_patterns(style, beats_per_bar)
  local PPQ = 960 -- Ticks pro Viertel

  local function beat_to_ppq(beat)
    return beat * PPQ
  end

  -- Noten-Definition nach GM-Standard
  local K_NOTE = 36
  local S_NOTE = 38
  local H_NOTE = 42
  local vel_main = 110
  local vel_ghost = 80
  local note_len_beats = 0.3

  r.Undo_BeginBlock()

  -- Kick
  for bar = 0, bars-1 do
    for _, beat in ipairs(K_pattern) do
      local pos_beats = bar * beats_per_bar + beat
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, K_NOTE, vel_main, false)
    end
  end

  -- Snare
  for bar = 0, bars-1 do
    for _, beat in ipairs(S_pattern) do
      local pos_beats = bar * beats_per_bar + beat
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, S_NOTE, vel_main, false)
    end
  end

  -- Hat
  for bar = 0, bars-1 do
    for _, beat in ipairs(H_pattern) do
      local pos_beats = bar * beats_per_bar + beat
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      local vel = vel_main
      if style == "3" and math.random() < 0.3 then
        vel = vel_ghost
      end
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, H_NOTE, vel, false)
    end
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V97 BeatEngine MIDI", -1)
end

main()
