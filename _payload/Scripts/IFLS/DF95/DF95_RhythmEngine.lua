-- @description Rhythm Engine (Euclid + Step Patterns)
-- @version 1.0
-- @author DF95
-- @about
--   Zentrale Helfer für LoopBuilder2:
--   - Euclid Patterns
--   - Step-Grid-Erzeugung
--   - MIDI-Note-Insertion für Kick/Snare/Hat

local R = {}

--------------------------------------------------------------------
-- Grundlegende Helfer
--------------------------------------------------------------------

--- Erzeugt ein Euclid-Pattern.
-- steps  : Anzahl Steps (z.B. 16)
-- pulses : Anzahl "Treffer" (Onsets)
-- rotate : Rotation (0..steps-1)
-- return : Tabelle mit 0/1-Werten (1 = Hit)
function R.euclid(steps, pulses, rotate)
  steps  = math.max(1, math.floor(steps or 16))
  pulses = math.max(0, math.min(steps, math.floor(pulses or 4)))
  rotate = math.floor(rotate or 0) % steps

  if pulses == 0 then
    local t = {}
    for i = 1, steps do t[i] = 0 end
    return t
  end
  if pulses == steps then
    local t = {}
    for i = 1, steps do t[i] = 1 end
    return t
  end

  -- Bjorklund / Euclid-Algorithmus (vereinfachte Implementierung)
  local pattern = {}
  local counts  = {}
  local rema    = {}
  local divisor = steps - pulses
  rema[1] = pulses
  local level = 1

  while true do
    counts[level] = math.floor(divisor / rema[level])
    rema[level+1] = divisor % rema[level]
    divisor = rema[level]
    level = level + 1
    if rema[level] <= 1 then break end
  end
  counts[level] = divisor

  local function build(level)
    if level == -1 then
      table.insert(pattern, 0)
    elseif level == -2 then
      table.insert(pattern, 1)
    else
      for i = 1, counts[level] do
        build(level-1)
      end
      if rema[level] ~= 0 then
        build(level-2)
      end
    end
  end

  build(level)

  -- Rotation
  local out = {}
  for i = 1, #pattern do
    local idx = ((i-1 + rotate) % #pattern) + 1
    out[i] = pattern[idx]
  end

  return out
end

--- Erzeugt eine Step-Pattern-Tabelle mit Random-Fill.
-- steps      : Anzahl Steps
-- density    : 0..1, Wahrscheinlichkeit für Hit pro Step
-- forbid_all_off : wenn true, wird sichergestellt, dass mind. 1 Hit existiert
function R.random_steps(steps, density, forbid_all_off)
  steps = math.max(1, math.floor(steps or 16))
  density = math.max(0, math.min(1, density or 0.5))
  local t = {}
  local hits = 0
  for i = 1, steps do
    if math.random() < density then
      t[i] = 1
      hits = hits + 1
    else
      t[i] = 0
    end
  end
  if forbid_all_off and hits == 0 then
    t[1] = 1
  end
  return t
end

--------------------------------------------------------------------
-- MIDI-Erzeugung
--------------------------------------------------------------------

--- Schreibt ein mehrspuriges Drum-Pattern als MIDI in ein Item.
-- track       : Reaper-Track
-- start_time  : Start in Sekunden
-- beat_len    : Länge in Beats (z.B. 4 = 1 Takt in 4/4)
-- lanes       : Liste: { {name="Kick", note=36, pattern={...}, vel=100}, ... }
-- swing       : 0..1 (0 = kein Swing)
function R.write_drum_pattern_as_midi(track, start_time, beat_len, lanes, swing)
  local r = reaper
  if not track or not lanes or #lanes == 0 then return end
  swing = swing or 0.0

  local steps = #lanes[1].pattern
  local qn_start = r.TimeMap2_timeToQN(0, start_time)
  local qn_len   = beat_len
  local qn_end   = qn_start + qn_len
  local item = r.CreateNewMIDIItemInProj(track, start_time, r.TimeMap2_QNToTime(0, qn_end), false)
  local take = r.GetActiveTake(item)
  if not take then return end

  local ppq_start = r.MIDI_GetPPQPosFromProjTime(take, start_time)
  local ppq_end   = r.MIDI_GetPPQPosFromProjTime(take, r.TimeMap2_QNToTime(0, qn_end))
  local ppq_len   = (ppq_end - ppq_start)
  local ppq_step  = ppq_len / steps

  r.MIDI_DisableSort(take)

  for _, lane in ipairs(lanes) do
    local patt = lane.pattern
    local note = lane.note or 36
    local vel  = lane.vel or 100
    for i = 1, #patt do
      if patt[i] == 1 then
        local ppq_pos = ppq_start + (i-1) * ppq_step
        if swing > 0 and (i % 2 == 0) then
          ppq_pos = ppq_pos + ppq_step * 0.5 * swing
        end
        local ppq_end_note = ppq_pos + ppq_step * 0.9
        r.MIDI_InsertNote(take, false, false, ppq_pos, ppq_end_note, 0, note, vel, false)
      end
    end
  end

  r.MIDI_Sort(take)
end

--------------------------------------------------------------------
-- Preset-Patterns / Convenience
--------------------------------------------------------------------

--- Baut ein klassisches IDM/Techno-Pattern (Kick/Snare/Hat) mit Euclid.
-- steps : Anzahl Steps (typisch 16)
-- returns: lanes-Tabelle für write_drum_pattern_as_midi
function R.make_euclid_idm_kit(steps)
  steps = steps or 16
  local lanes = {}

  local kick = {
    name    = "Kick",
    note    = 36,
    vel     = 110,
    pattern = R.euclid(steps, 4, 0)
  }

  local snare = {
    name    = "Snare",
    note    = 38,
    vel     = 105,
    pattern = R.euclid(steps, 2, math.floor(steps/4))
  }

  local ch = {
    name    = "CH",
    note    = 42,
    vel     = 90,
    pattern = R.euclid(steps, math.floor(steps * 0.5), 1)
  }

  local mp = {
    name    = "MicroPerc",
    note    = 37,
    vel     = 80,
    pattern = R.random_steps(steps, 0.2, false)
  }

  table.insert(lanes, kick)
  table.insert(lanes, snare)
  table.insert(lanes, ch)
  table.insert(lanes, mp)

  return lanes
end

--- Baut ein "Elektron/Maschine"-ähnliches Grid mit random density.
function R.make_stepgrid_idm_kit(steps, density_kick, density_snare, density_hat)
  steps = steps or 16
  density_kick  = density_kick or 0.25
  density_snare = density_snare or 0.2
  density_hat   = density_hat or 0.6

  local lanes = {}

  local kick = {
    name    = "Kick",
    note    = 36,
    vel     = 115,
    pattern = R.random_steps(steps, density_kick, true)
  }

  local snare = {
    name    = "Snare",
    note    = 38,
    vel     = 108,
    pattern = R.random_steps(steps, density_snare, true)
  }

  local ch = {
    name    = "CH",
    note    = 42,
    vel     = 92,
    pattern = R.random_steps(steps, density_hat, true)
  }

  table.insert(lanes, kick)
  table.insert(lanes, snare)
  table.insert(lanes, ch)

  return lanes
end

return R
