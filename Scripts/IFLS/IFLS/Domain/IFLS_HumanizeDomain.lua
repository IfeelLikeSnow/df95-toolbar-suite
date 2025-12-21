-- IFLS_HumanizeDomain.lua
-- Phase 46: Beat Humanize + Style Presets

local r = reaper
local M = {}

local NAMESPACE = "IFLS_BEAT_HUMANIZE"

M.default_preset = "STRAIGHT"

M.presets = {
  STRAIGHT = {
    name              = "Straight",
    timing_jitter_ms  = 0.0,
    swing_pct         = 0.0,
    vel_spread        = 4.0,
    ghost_prob        = 0.0,
    roll_prob         = 0.0,
    glitch_prob       = 0.0,
  },
  IDM = {
    name              = "IDM / Glitch (balanced)",
    timing_jitter_ms  = 8.0,
    swing_pct         = 5.0,
    vel_spread        = 12.0,
    ghost_prob        = 0.25,
    roll_prob         = 0.20,
    glitch_prob       = 0.25,
  },
  IDM_DENSE = {
    name              = "IDM Dense",
    timing_jitter_ms  = 10.0,
    swing_pct         = 7.0,
    vel_spread        = 14.0,
    ghost_prob        = 0.45,
    roll_prob         = 0.45,
    glitch_prob       = 0.55,
  },
  IDM_SPARSE = {
    name              = "IDM Sparse",
    timing_jitter_ms  = 6.0,
    swing_pct         = 4.0,
    vel_spread        = 10.0,
    ghost_prob        = 0.15,
    roll_prob         = 0.10,
    glitch_prob       = 0.20,
  },
  CLICKS_POP = {
    name              = "Clicks & Pops",
    timing_jitter_ms  = 3.0,
    swing_pct         = 0.0,
    vel_spread        = 8.0,
    ghost_prob        = 0.35,
    roll_prob         = 0.35,
    glitch_prob       = 0.15,
  },
  MICROBEAT = {
    name              = "Microbeats",
    timing_jitter_ms  = 12.0,
    swing_pct         = 10.0,
    vel_spread        = 10.0,
    ghost_prob        = 0.40,
    roll_prob         = 0.30,
    glitch_prob       = 0.40,
  },
  MICROSTUTTER = {
    name              = "Microstutter / Granular",
    timing_jitter_ms  = 5.0,
    swing_pct         = 5.0,
    vel_spread        = 6.0,
    ghost_prob        = 0.20,
    roll_prob         = 0.65,
    glitch_prob       = 0.75,
  },
}


)) or p.timing_jitter_ms,
    swing_pct         = tonumber(load_value(proj, "swing_pct",         p.swing_pct))        or p.swing_pct,
    vel_spread        = tonumber(load_value(proj, "vel_spread",        p.vel_spread))       or p.vel_spread,
    ghost_prob        = tonumber(load_value(proj, "ghost_prob",        p.ghost_prob))       or p.ghost_prob,
    roll_prob         = tonumber(load_value(proj, "roll_prob",         p.roll_prob))        or p.roll_prob,
    glitch_prob       = tonumber(load_value(proj, "glitch_prob",       p.glitch_prob))      or p.glitch_prob,
  }

  return cfg
end

function M.save(proj, cfg)
  proj = proj or 0
  if not cfg then return end
  save_value(proj, "preset_id",        cfg.preset_id or M.default_preset)
  save_value(proj, "timing_jitter_ms", cfg.timing_jitter_ms or 0.0)
  save_value(proj, "swing_pct",        cfg.swing_pct or 0.0)
  save_value(proj, "vel_spread",       cfg.vel_spread or 0.0)
  save_value(proj, "ghost_prob",       cfg.ghost_prob or 0.0)
  save_value(proj, "roll_prob",        cfg.roll_prob or 0.0)
  save_value(proj, "glitch_prob",      cfg.glitch_prob or 0.0)
end

function M.apply_preset(proj, preset_id)
  proj = proj or 0
  local p = M.presets[preset_id] or M.presets[M.default_preset]
  local cfg = {
    preset_id         = preset_id,
    timing_jitter_ms  = p.timing_jitter_ms,
    swing_pct         = p.swing_pct,
    vel_spread        = p.vel_spread,
    ghost_prob        = p.ghost_prob,
    roll_prob         = p.roll_prob,
    glitch_prob       = p.glitch_prob,
  }
  M.save(proj, cfg)
  return cfg
end



----------------------------------------------------------------
-- DF95-Humanize Bridge Helper
--   Konvertiert IFLS-Humanize-Config in ein DF95-kompatibles
--   Profil (Timing / Velocity / Swing / Length).
----------------------------------------------------------------

function M.to_df95_profile(cfg)
  cfg = cfg or M.load(0)
  if not cfg then return nil end

  local timing_ms  = tonumber(cfg.timing_jitter_ms) or 0
  local vel_pct    = tonumber(cfg.vel_spread) or 0
  local swing_pct  = tonumber(cfg.swing_pct) or 0
  local length_ms  = math.max(0, (tonumber(cfg.length_ms) or (timing_ms * 0.5)))

  return {
    timing_ms        = timing_ms,
    velocity_percent = vel_pct,
    swing_percent    = swing_pct,
    length_ms        = length_ms,
  }
end

return M
