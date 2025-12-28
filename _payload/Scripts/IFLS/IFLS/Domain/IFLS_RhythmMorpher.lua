-- IFLS_RhythmMorpher.lua
-- Phase 91: Rhythm Transformation & Morphing

local RhythmStyles = require("IFLS_RhythmStyles")

local RhythmMorpher = {}

local function clamp01(x)
  if x < 0.0 then return 0.0 end
  if x > 1.0 then return 1.0 end
  return x
end

local function ensure_resolution(pattern, style)
  local pres = pattern.resolution or 16
  local sres = style.resolution or 16
  if pres ~= sres then
    return false
  end
  return true
end

local function pattern_to_grid(pattern, instruments)
  local res = pattern.resolution or 16
  local grid = {}
  for _, inst in ipairs(instruments) do
    grid[inst] = {}
    for i = 1, res do grid[inst][i] = 0.0 end
    local track = pattern.tracks[inst]
    if track and track.steps then
      for step, info in pairs(track.steps) do
        local s = tonumber(step)
        if s and s >= 1 and s <= res and info.hit then
          local v = (info.vel or 100) / 127.0
          grid[inst][s] = math.max(grid[inst][s], v)
        end
      end
    end
  end
  return grid
end

local function grid_to_pattern(grid, pattern, instruments, base_velocity, threshold)
  local res = pattern.resolution or 16
  base_velocity = base_velocity or 100
  threshold = threshold or 0.5

  pattern.tracks = pattern.tracks or {}

  for _, inst in ipairs(instruments) do
    local g = grid[inst]
    if g then
      local track = pattern.tracks[inst] or { steps = {} }
      track.steps = track.steps or {}
      for k in pairs(track.steps) do track.steps[k] = nil end

      for i = 1, res do
        local val = g[i] or 0.0
        if val >= threshold then
          local vel = math.floor(base_velocity * clamp01(val) + 0.5)
          track.steps[i] = { hit = true, vel = vel }
        end
      end
      pattern.tracks[inst] = track
    end
  end

  return pattern
end

function RhythmMorpher.morph(pattern, style_name, amount, opts)
  amount = clamp01(amount or 1.0)
  if amount <= 0.0 then return pattern end

  opts = opts or {}
  local style = RhythmStyles.get(style_name)
  if not style then return pattern end
  if not ensure_resolution(pattern, style) then
    return pattern
  end

  local instruments = opts.instruments
  if not instruments or #instruments == 0 then
    instruments = {}
    for inst, _ in pairs(style.instruments or {}) do
      table.insert(instruments, inst)
    end
  end

  local pattern_grid = pattern_to_grid(pattern, instruments)
  local style_grid   = {}
  local res          = style.resolution or pattern.resolution or 16

  for _, inst in ipairs(instruments) do
    local sinst = style.instruments[inst]
    style_grid[inst] = {}
    for i = 1, res do
      local p = sinst and sinst.prob and sinst.prob[i] or 0.0
      local a = sinst and sinst.accent and sinst.accent[i] or 0.0
      style_grid[inst][i] = clamp01(0.7 * p + 0.3 * a)
    end
  end

  local out_grid = {}
  for _, inst in ipairs(instruments) do
    out_grid[inst] = {}
    for i = 1, res do
      local pval = pattern_grid[inst][i] or 0.0
      local sval = style_grid[inst][i] or 0.0
      local val  = (1.0 - amount) * pval + amount * sval

      if opts.preserve_existing and pval > 0.0 then
        if val < pval then val = pval end
      end

      out_grid[inst][i] = clamp01(val)
    end
  end

  local density_bias  = opts.density_bias or 0.0
  local base_threshold = 0.5
  local threshold = base_threshold - 0.2 * density_bias
  if threshold < 0.2 then threshold = 0.2 end
  if threshold > 0.8 then threshold = 0.8 end

  return grid_to_pattern(out_grid, pattern, instruments, 100, threshold)
end

return RhythmMorpher
