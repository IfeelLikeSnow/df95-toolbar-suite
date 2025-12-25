-- IFLS_SceneEvolutionDomain.lua
-- SceneEvolution + Makro-Bridge zu Variation/Groove/EuclidMelody

local r = reaper
local M = {}
local NS = "IFLS_SCENEEVO"

local function get_proj_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_proj_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function get_num(key, default)
  local v = tonumber(get_proj_ext(key, ""))
  if not v then return default end
  return v
end

local function get_bool(key, default)
  local v = get_proj_ext(key, default and "1" or "0")
  return v == "1"
end

local function clamp01(v)
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

function M.read_cfg()
  local cfg = {
    enabled          = get_bool("ENABLED", true),
    macro_variation  = get_num("MACRO_VARIATION", 0.5),
    macro_melody     = get_num("MACRO_MELODY",    0.5),
    macro_groove     = get_num("MACRO_GROOVE",    0.5),
    macro_chaos      = get_num("MACRO_CHAOS",     0.0),
  }
  return cfg
end

function M.write_cfg(cfg)
  if not cfg then return end
  set_proj_ext("ENABLED",         cfg.enabled and "1" or "0")
  set_proj_ext("MACRO_VARIATION", cfg.macro_variation or 0.5)
  set_proj_ext("MACRO_MELODY",    cfg.macro_melody or 0.5)
  set_proj_ext("MACRO_GROOVE",    cfg.macro_groove or 0.5)
  set_proj_ext("MACRO_CHAOS",     cfg.macro_chaos or 0.0)
end

local function safe_dofile(path)
  local ok, mod = pcall(dofile, path)
  if ok then return mod end
  return nil
end

local function read_variation_cfg()
  local mod = safe_dofile(r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_VariationDomain.lua")
  if mod and mod.read_cfg then return mod.read_cfg(), mod end
  return nil, nil
end

local function write_variation_cfg(cfg, mod)
  if cfg and mod and mod.write_cfg then mod.write_cfg(cfg) end
end

local function read_euclidmelody_cfg()
  local mod = safe_dofile(r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_EuclidMelodyDomain.lua")
  if mod and mod.read_cfg then return mod.read_cfg(), mod end
  return nil, nil
end

local function write_euclidmelody_cfg(cfg, mod)
  if cfg and mod and mod.write_cfg then mod.write_cfg(cfg) end
end

local function read_groove_cfg()
  local mod = safe_dofile(r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_GrooveDomain.lua")
  if mod and mod.read_cfg then return mod.read_cfg(), mod end
  return nil, nil
end

local function write_groove_cfg(cfg, mod)
  if cfg and mod and mod.write_cfg then mod.write_cfg(cfg) end
end

function M.apply_to_domains(cfg)
  cfg = cfg or M.read_cfg()
  if not cfg.enabled then return end

  local macro_var   = clamp01(cfg.macro_variation or 0.5)
  local macro_mel   = clamp01(cfg.macro_melody or 0.5)
  local macro_gro   = clamp01(cfg.macro_groove or 0.5)
  local macro_chaos = clamp01(cfg.macro_chaos or 0.0)

  local vcfg, vmod = read_variation_cfg()
  if vcfg then
    local base_density = vcfg.ratchet_density or 1.0
    local density = base_density * (0.25 + 0.75 * macro_var) * (0.5 + 0.5 * macro_chaos)
    if density > 1.5 then density = 1.5 end
    vcfg.ratchet_density = density

    local function scale_lane(lane, factor)
      if not lane then return end
      lane.rat_light = (lane.rat_light or 0.0) * (0.5 + factor)
      lane.rat_fill  = (lane.rat_fill  or 0.0) * (0.5 + factor * 1.5)
    end

    local factor = 0.5 + macro_var * (1.0 + macro_chaos)
    scale_lane(vcfg.kick_lane,  factor * 0.5)
    scale_lane(vcfg.snare_lane, factor)
    scale_lane(vcfg.hat_lane,   factor * 1.2)

    write_variation_cfg(vcfg, vmod)
  end

  local mcfg, mmod = read_euclidmelody_cfg()
  if mcfg then
    local base_motion = mcfg.motion_prob or 1.0
    local base_leap   = mcfg.leap_prob   or 0.1

    local motion = base_motion * (0.5 + macro_mel * 0.7)
    if motion > 1.5 then motion = 1.5 end
    local leap = base_leap * (0.25 + macro_mel * 1.5 + macro_chaos * 0.8)
    if leap > 1.5 then leap = 1.5 end

    mcfg.motion_prob = motion
    mcfg.leap_prob   = leap

    write_euclidmelody_cfg(mcfg, mmod)
  end

  local gcfg, gmod = read_groove_cfg()
  if gcfg then
    local base_swing = gcfg.swing_amount or 0.0
    local swing = base_swing + (macro_gro - 0.5) * 0.4
    if swing < 0.0 then swing = 0.0 end
    if swing > 1.0 then swing = 1.0 end

    local max_ht = 25.0
    local max_hv = 0.4
    local ht = max_ht * macro_gro
    local hv = max_hv * macro_gro
    ht = ht * (0.7 + 0.6 * macro_chaos)
    hv = hv * (0.7 + 0.6 * macro_chaos)
    if ht > 40.0 then ht = 40.0 end
    if hv > 0.8 then hv = 0.8 end

    gcfg.swing_amount = swing
    gcfg.humanize_t   = ht
    gcfg.humanize_v   = hv
    gcfg.enabled      = true

    write_groove_cfg(gcfg, gmod)
  end
end

function M.bump_macro(name, delta)
  local cfg = M.read_cfg()
  cfg[name] = clamp01((cfg[name] or 0.5) + delta)
  M.write_cfg(cfg)
  M.apply_to_domains(cfg)
end

return M
