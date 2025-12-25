-- IFLS_EuclidProProfiles.lua
-- Vordefinierte Ratchet-Profile für EuclidPro (IDM / Glitch / Techno / Ambient)
-- Fokus: RATCHET_PROB / MIN / MAX / SHAPE
--
-- Verwendung:
--   local prof = require this module via dofile
--   prof.apply_profile("glitch_roll", ext)
--
-- Profiles wirken direkt auf ExtState "IFLS_EUCLIDPRO" (Ratchet-Felder).

local M = {}

local NS_EUCLIDPRO = "IFLS_EUCLIDPRO"

M.PROFILES = {
  glitch_roll = {
    name = "Glitch Roll",
    desc = "Schnelle, chaotische IDM/Glitch-Rolls",
    ratchet_prob  = 0.7,
    ratchet_min   = 2,
    ratchet_max   = 6,
    ratchet_shape = "random",
  },

  snare_rush = {
    name = "Snare Rush",
    desc = "Klassische Snare-Rolls (ansteigend)",
    ratchet_prob  = 0.5,
    ratchet_min   = 3,
    ratchet_max   = 7,
    ratchet_shape = "up",
  },

  micro_clicks = {
    name = "Micro Clicks",
    desc = "Feine, leise Click-Rolls",
    ratchet_prob  = 0.4,
    ratchet_min   = 2,
    ratchet_max   = 4,
    ratchet_shape = "down",
  },

  minimal_ticks = {
    name = "Minimal Ticks",
    desc = "Sparse, dezente Ratchets für Minimal/Techno",
    ratchet_prob  = 0.15,
    ratchet_min   = 2,
    ratchet_max   = 3,
    ratchet_shape = "down",
  },

  broken_fill = {
    name = "Broken Fill",
    desc = "Unstete Fills, ideal für Broken Techno / IDM",
    ratchet_prob  = 0.6,
    ratchet_min   = 2,
    ratchet_max   = 5,
    ratchet_shape = "pingpong",
  },

  ambient_flutters = {
    name = "Ambient Flutters",
    desc = "Weiche, flatternde Percussion-Rolls",
    ratchet_prob  = 0.35,
    ratchet_min   = 3,
    ratchet_max   = 6,
    ratchet_shape = "random",
  },
}

function M.list_profiles()
  local list = {}
  for key, p in pairs(M.PROFILES) do
    list[#list+1] = { key = key, name = p.name or key, desc = p.desc or "" }
  end
  table.sort(list, function(a,b) return a.name < b.name end)
  return list
end

local function apply_to_ext(ext, cfg)
  if not ext or not cfg then return end

  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end
  local function setstr(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end

  setnum("RATCHET_PROB", cfg.ratchet_prob)
  setnum("RATCHET_MIN",  cfg.ratchet_min)
  setnum("RATCHET_MAX",  cfg.ratchet_max)
  setstr("RATCHET_SHAPE", cfg.ratchet_shape)
end

function M.apply_profile(key, ext_mod)
  local prof = M.PROFILES[key]
  if not prof then return false, "unknown profile: " .. tostring(key) end
  apply_to_ext(ext_mod, prof)
  return true
end

return M
