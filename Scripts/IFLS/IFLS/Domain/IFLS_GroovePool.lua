-- IFLS_GroovePool.lua
-- Phase 87: Groove Pool and Artist/BeatEngine integration helpers.
--
-- The Groove Pool is the central access point to groove profiles
-- in IFLS. It wraps the builtin profiles from IFLS_GrooveProfiles
-- and provides:
--
--   * list() / get(name)
--   * get_default_for_artist(artist)
--   * apply_to_note_events(events, profile, amount)
--
-- "events" is intentionally generic so you can reuse the logic for:
--   * MIDI notes
--   * internal BeatEngine steps
--   * or other time-based representations
--
-- The concept of a groove as a "timing + velocity map" is directly
-- in line with how other DAWs implement groove templates and swing: citeturn2search0turn2search11turn2search17
--
--   - We do not compute randomness here (that's Humanize).
--   - We define *fixed* microtiming offsets within the bar (Groove).

local GrooveProfiles = require("IFLS_GrooveProfiles")

local GroovePool = {}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

-- How we quantize to steps for a profile.
-- events must expose a "beat" or "pos" field in beats.
-- You can adapt this to your internal BeatEngine representation.
local function compute_step_index(ev_beat, grid_division)
  -- ev_beat in beats, assume 4 beats per bar (4/4).
  local bar_pos = ev_beat % 4.0
  local step_f = bar_pos * grid_division / 4.0
  local step_index = math.floor(step_f + 0.5) + 1 -- 1-based
  if step_index < 1 then step_index = 1 end
  if step_index > grid_division then step_index = grid_division end
  return step_index
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function GroovePool.list()
  return GrooveProfiles.list()
end

function GroovePool.get(name)
  return GrooveProfiles.get(name)
end

--- Determine which groove should be used for the given artist/profile.
-- "artist" is expected to be a table with a "groove_profile_name"
-- field, but you can adapt to your existing Artist system. fileciteturn1file0
function GroovePool.get_default_for_artist(artist)
  if artist and artist.groove_profile_name then
    local p = GrooveProfiles.get(artist.groove_profile_name)
    if p then return p end
  end
  -- Fallback: Straight16
  return GrooveProfiles.get("Straight16")
end

--- Apply groove to a list of events.
-- params:
--   events: array of { beat = number, vel = number, ... }
--   profile: groove profile table (see IFLS_GrooveProfiles)
--   amount: 0..1, how strong the groove should be applied
--
-- Returns events (mutated in-place for convenience).
function GroovePool.apply_to_note_events(events, profile, amount)
  if not events or not profile then return events end
  amount = amount or 1.0
  if amount <= 0.0 then return events end

  local grid_division = profile.grid_division or 16
  local offsets = profile.offsets or {}
  local velmul = profile.velocity_mul or {}

  for i, ev in ipairs(events) do
    local beat = ev.beat or 0.0
    local vel  = ev.vel  or 100

    local step_index = compute_step_index(beat, grid_division)
    local off = offsets[step_index] or 0.0
    local vm  = velmul[step_index] or 1.0

    -- Apply fractional timing offset:
    -- off = 1.0 -> move one full step towards next grid line.
    -- We scale by "amount".
    local bar_pos = beat % 4.0
    local base_step = (step_index - 1) * (4.0 / grid_division)
    local next_step = base_step + (4.0 / grid_division)
    local target = base_step + off * (4.0 / grid_division)
    -- Interpolate between original and target
    local new_bar_pos = bar_pos + (target - base_step) * amount

    -- Wrap within bar
    while new_bar_pos < 0.0 do new_bar_pos = new_bar_pos + 4.0 end
    while new_bar_pos >= 4.0 do new_bar_pos = new_bar_pos - 4.0 end

    local bar_index = math.floor(beat / 4.0)
    ev.beat = bar_index * 4.0 + new_bar_pos

    -- Apply velocity scaling
    local new_vel = math.floor(vel * (1.0 + (vm - 1.0) * amount) + 0.5)
    if new_vel < 1 then new_vel = 1 end
    if new_vel > 127 then new_vel = 127 end
    ev.vel = new_vel
  end

  return events
end

return GroovePool
