-- IFLS_GrooveProfiles.lua
-- Phase 87: GrooveProfile & Groove Pool
--
-- This module defines the data model for groove profiles and a small
-- built-in library of example grooves. The design is inspired by
-- DAW groove/swing systems (Ableton Groove Pool, Cubase Quantize/Groove
-- Templates etc.), where a groove is essentially a timing/velocity
-- "map" applied to notes or transients. citeturn2search0turn2search3turn2search11
--
-- In practice:
--   * grid_division defines the rhythmic resolution (e.g. 16 steps per bar)
--   * offsets define micro-timing offsets relative to the straight grid
--   * velocity_mul defines dynamic accents per step
--
-- Offsets are expressed in fractions of a grid step:
--   offset = 0.0      -> exactly on grid
--   offset = 0.5      -> halfway to the next grid line
--   offset = -0.25    -> early by a quarter step, etc.
--
-- The BeatEngine integration layer can then convert these fractional
-- offsets to beats, seconds or project ticks depending on the host.

local GrooveProfiles = {}

----------------------------------------------------------------
-- INTERNAL UTILS
----------------------------------------------------------------

local function make_profile(name, grid_division, offsets, velocity_mul, prob)
  return {
    name          = name,
    grid_division = grid_division,
    offsets       = offsets,
    velocity_mul  = velocity_mul,
    prob          = prob,
  }
end

----------------------------------------------------------------
-- BUILT-IN GROOVE LIB
----------------------------------------------------------------

-- Straight: no timing change, but kept for explicit selection.
GrooveProfiles.Straight16 = make_profile(
  "Straight16",
  16,
  (function()
    local t = {}
    for i = 1, 16 do t[i] = 0.0 end
    return t
  end)(),
  (function()
    local t = {}
    for i = 1, 16 do t[i] = 1.0 end
    return t
  end)(),
  nil
)

-- Classic 16th swing: pushes off-beats later in time. Similar in spirit
-- to classic MPC / drum machine swing where 2,4,6,... steps are delayed. citeturn2search7turn2search17
GrooveProfiles.SixteenthSwing60 = make_profile(
  "SixteenthSwing60",
  16,
  (function()
    local t = {}
    for i = 1, 16 do
      if i % 2 == 0 then
        t[i] = 0.6 -- off-beats delayed
      else
        t[i] = 0.0
      end
    end
    return t
  end)(),
  (function()
    local t = {}
    for i = 1, 16 do
      if i % 4 == 1 then
        t[i] = 1.1 -- accent on beat 1,2,3,4
      else
        t[i] = 1.0
      end
    end
    return t
  end)(),
  nil
)

-- IDM MicroSwing: subtle alternating microtiming, good for more
-- experimental but still groovy patterns.
GrooveProfiles.IDM_MicroSwing = make_profile(
  "IDM_MicroSwing",
  16,
  (function()
    local t = {}
    for i = 1, 16 do
      local phase = (i - 1) % 4
      if phase == 1 then
        t[i] = 0.15
      elseif phase == 3 then
        t[i] = -0.1
      else
        t[i] = 0.0
      end
    end
    return t
  end)(),
  (function()
    local t = {}
    for i = 1, 16 do
      if i % 4 == 1 then
        t[i] = 1.1
      elseif i % 4 == 3 then
        t[i] = 0.9
      else
        t[i] = 1.0
      end
    end
    return t
  end)(),
  nil
)

-- BrokenBeat: emphasizes off-beats and delays them, for a more
-- "stumbling" feel.
GrooveProfiles.BrokenBeat16 = make_profile(
  "BrokenBeat16",
  16,
  (function()
    local t = {}
    for i = 1, 16 do
      if i % 4 == 2 or i % 4 == 4 then
        t[i] = 0.4
      else
        t[i] = 0.0
      end
    end
    return t
  end)(),
  (function()
    local t = {}
    for i = 1, 16 do
      if i % 4 == 2 or i % 4 == 4 then
        t[i] = 1.1
      else
        t[i] = 0.9
      end
    end
    return t
  end)(),
  nil
)

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

local all_profiles = {
  GrooveProfiles.Straight16,
  GrooveProfiles.SixteenthSwing60,
  GrooveProfiles.IDM_MicroSwing,
  GrooveProfiles.BrokenBeat16,
}

--- Return list of all builtin groove profiles.
function GrooveProfiles.list()
  return all_profiles
end

--- Find a profile by name (case sensitive).
function GrooveProfiles.get(name)
  for _, p in ipairs(all_profiles) do
    if p.name == name then return p end
  end
  return nil
end

--- Add a new profile (e.g. from extracted groove).
function GrooveProfiles.add(profile)
  if not profile or not profile.name then return end
  -- replace if same name exists
  for i, p in ipairs(all_profiles) do
    if p.name == profile.name then
      all_profiles[i] = profile
      return
    end
  end
  table.insert(all_profiles, profile)
end

--- Helper to create a new profile table.
GrooveProfiles.make = make_profile

return GrooveProfiles
