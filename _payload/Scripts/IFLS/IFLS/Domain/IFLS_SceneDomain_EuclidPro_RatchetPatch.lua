-- PATCH-HINWEIS:
-- Diese Version von read_euclidpro_cfg / write_euclidpro_cfg
-- erwartet, dass NS_EUCLIDPRO = "IFLS_EUCLIDPRO" und ext.* verfügbar sind.
-- Bitte in IFLS_SceneDomain.lua integrieren (alte Version ersetzen).

local function ep_num(key, def)
  local s = ext.get_proj(NS_EUCLIDPRO, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function read_euclidpro_cfg()
  local cfg = {
    steps        = ep_num("STEPS", 16),
    hits         = ep_num("HITS", 5),
    rotation     = ep_num("ROTATION", 0),
    accent_mode  = ext.get_proj(NS_EUCLIDPRO, "ACCENT_MODE", "none"),
    hit_prob     = ep_num("HIT_PROB", 1.0),
    ghost_prob   = ep_num("GHOST_PROB", 0.0),
    ratchet_prob = ep_num("RATCHET_PROB", 0.0),
    ratchet_min  = ep_num("RATCHET_MIN", 2),
    ratchet_max  = ep_num("RATCHET_MAX", 4),
    ratchet_shape= ext.get_proj(NS_EUCLIDPRO, "RATCHET_SHAPE", "up"),
  }

  cfg.lanes = {
    {
      pitch      = ep_num("L1_PITCH", 36),
      div        = ep_num("L1_DIV", 1),
      base_vel   = ep_num("L1_BASE_VEL", 96),
      accent_vel = ep_num("L1_ACCENT_VEL", 118),
    },
    {
      pitch      = ep_num("L2_PITCH", 38),
      div        = ep_num("L2_DIV", 1),
      base_vel   = ep_num("L2_BASE_VEL", 90),
      accent_vel = ep_num("L2_ACCENT_VEL", 112),
    },
    {
      pitch      = ep_num("L3_PITCH", 42),
      div        = ep_num("L3_DIV", 1),
      base_vel   = ep_num("L3_BASE_VEL", 84),
      accent_vel = ep_num("L3_ACCENT_VEL", 108),
    },
  }

  return cfg
end

local function write_euclidpro_cfg(cfg)
  if not cfg then return end

  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end
  local function setstr(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end

  setnum("STEPS",        cfg.steps)
  setnum("HITS",         cfg.hits)
  setnum("ROTATION",     cfg.rotation)
  setstr("ACCENT_MODE",  cfg.accent_mode or "none")
  setnum("HIT_PROB",     cfg.hit_prob)
  setnum("GHOST_PROB",   cfg.ghost_prob)
  setnum("RATCHET_PROB", cfg.ratchet_prob)
  setnum("RATCHET_MIN",  cfg.ratchet_min)
  setnum("RATCHET_MAX",  cfg.ratchet_max)
  setstr("RATCHET_SHAPE", cfg.ratchet_shape or "up")

  local lanes = cfg.lanes or {}
  local l1 = lanes[1] or {}
  local l2 = lanes[2] or {}
  local l3 = lanes[3] or {}

  setnum("L1_PITCH",       l1.pitch)
  setnum("L1_DIV",         l1.div)
  setnum("L1_BASE_VEL",    l1.base_vel)
  setnum("L1_ACCENT_VEL",  l1.accent_vel)

  setnum("L2_PITCH",       l2.pitch)
  setnum("L2_DIV",         l2.div)
  setnum("L2_BASE_VEL",    l2.base_vel)
  setnum("L2_ACCENT_VEL",  l2.accent_vel)

  setnum("L3_PITCH",       l3.pitch)
  setnum("L3_DIV",         l3.div)
  setnum("L3_BASE_VEL",    l3.base_vel)
  setnum("L3_ACCENT_VEL",  l3.accent_vel)
end
