-- IFLS_RhythmStyles.lua
-- Phase 91: Rhythm Style Templates
--
-- This module defines abstract rhythm style templates that describe
-- how hits are distributed over a bar for each instrument (kick, snare,
-- hat, perc, etc.) and how accents / probabilities behave.

local RhythmStyles = {}

----------------------------------------------------------------
-- STYLE MODEL
----------------------------------------------------------------
-- Style template structure:
--
-- {
--   name        = "IDM_Chaos",
--   resolution  = 16,
--   instruments = {
--     kick = {
--       prob   = { ... 16 values ... },
--       accent = { ... 16 values ... },
--     },
--     snare = { ... },
--     hat   = { ... },
--     perc  = { ... },
--   },
--   meta = {
--     complexity = 0.9,
--     density    = 0.8,
--   }
-- }

local function make_style(name, resolution, instruments, meta)
  return {
    name        = name,
    resolution  = resolution or 16,
    instruments = instruments or {},
    meta        = meta or {},
  }
end

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

local function uniform_prob_for_indices(res, indices, base, other)
  local t = {}
  for i = 1, res do t[i] = other or 0.0 end
  for _, idx in ipairs(indices) do
    if idx >= 1 and idx <= res then
      t[idx] = base or 1.0
    end
  end
  return t
end

local function accent_for_indices(res, indices, base, other)
  local t = {}
  for i = 1, res do t[i] = other or 0.0 end
  for _, idx in ipairs(indices) do
    if idx >= 1 and idx <= res then
      t[idx] = base or 1.0
    end
  end
  return t
end

----------------------------------------------------------------
-- BUILT-IN STYLES
----------------------------------------------------------------

local styles = {}

-- Straight 4/4 basic groove: kick on 1 & 3, snare on 2 & 4, hats on 8ths.
table.insert(styles, make_style(
  "Straight_4onFloor",
  16,
  {
    kick = {
      prob   = uniform_prob_for_indices(16, {1, 9}, 1.0, 0.0),
      accent = accent_for_indices(16, {1, 9}, 1.0, 0.0),
    },
    snare = {
      prob   = uniform_prob_for_indices(16, {5, 13}, 1.0, 0.0),
      accent = accent_for_indices(16, {5, 13}, 1.0, 0.0),
    },
    hat = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 2 == 1) and 0.7 or 0.4 -- 8ths with weaker off 16ths
        end
        return t
      end)(),
      accent = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 4 == 1) and 1.0 or 0.3
        end
        return t
      end)(),
    },
  },
  { complexity = 0.3, density = 0.6 }
))

-- Broken Beat: more off-beat kicks and shifted snares.
table.insert(styles, make_style(
  "BrokenBeat_Stumble",
  16,
  {
    kick = {
      prob   = uniform_prob_for_indices(16, {1, 7, 11, 15}, 0.9, 0.2),
      accent = accent_for_indices(16, {1, 11}, 1.0, 0.6),
    },
    snare = {
      prob   = uniform_prob_for_indices(16, {6, 10, 14}, 0.8, 0.1),
      accent = accent_for_indices(16, {6, 14}, 1.0, 0.5),
    },
    hat = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 2 == 1) and 0.6 or 0.5
        end
        return t
      end)(),
      accent = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 4 == 2 or i % 4 == 4) and 0.8 or 0.3
        end
        return t
      end)(),
    },
  },
  { complexity = 0.7, density = 0.75 }
))

-- IDM Chaos: high density, non-obvious strong beats, micro off-steps.
table.insert(styles, make_style(
  "IDM_Chaos",
  16,
  {
    kick = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          if i == 1 or i == 9 then
            t[i] = 0.8
          elseif i % 2 == 0 then
            t[i] = 0.5
          else
            t[i] = 0.3
          end
        end
        return t
      end)(),
      accent = accent_for_indices(16, {1, 9, 12}, 1.0, 0.5),
    },
    snare = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          if i == 5 or i == 13 then
            t[i] = 0.8
          elseif i % 4 == 3 then
            t[i] = 0.6
          else
            t[i] = 0.3
          end
        end
        return t
      end)(),
      accent = accent_for_indices(16, {5, 13, 15}, 1.0, 0.6),
    },
    hat = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = 0.5 + ((i % 2 == 0) and 0.2 or 0.0)
        end
        return t
      end)(),
      accent = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 4 == 1) and 0.9 or 0.4
        end
        return t
      end)(),
    },
    perc = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 3 == 0) and 0.7 or 0.2
        end
        return t
      end)(),
      accent = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 3 == 0) and 0.8 or 0.3
        end
        return t
      end)(),
    },
  },
  { complexity = 0.95, density = 0.9 }
))

-- Dilla-esque late snares and loose feel (symbolic only; timing comes from Groove).
table.insert(styles, make_style(
  "Dilla_LateSnare",
  16,
  {
    kick = {
      prob   = uniform_prob_for_indices(16, {1, 9}, 0.9, 0.2),
      accent = accent_for_indices(16, {1, 9}, 1.0, 0.6),
    },
    snare = {
      prob   = uniform_prob_for_indices(16, {6, 14}, 0.9, 0.3),
      accent = accent_for_indices(16, {6, 14}, 1.0, 0.6),
    },
    hat = {
      prob   = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 2 == 1) and 0.7 or 0.4
        end
        return t
      end)(),
      accent = (function()
        local t = {}
        for i = 1, 16 do
          t[i] = (i % 4 == 1) and 1.0 or 0.3
        end
        return t
      end)(),
    },
  },
  { complexity = 0.5, density = 0.7 }
))

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function RhythmStyles.list()
  return styles
end

function RhythmStyles.get(name)
  for _, s in ipairs(styles) do
    if s.name == name then return s end
  end
  return nil
end

function RhythmStyles.add(style)
  if not style or not style.name then return end
  for i, s in ipairs(styles) do
    if s.name == style.name then
      styles[i] = style
      return
    end
  end
  table.insert(styles, style)
end

return RhythmStyles
