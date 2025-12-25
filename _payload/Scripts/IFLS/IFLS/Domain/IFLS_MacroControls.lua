-- IFLS_MacroControls.lua
-- Phase 92: Global Macro Controls for IFLS
--
-- This module defines a small set of high-level macro controls that
-- modulate multiple underlying subsystems:
--   * Glitch / MicroSlice intensity
--   * Rhythm chaos / transformation
--   * Texture / FX depth
--   * Human vs Robot (groove vs tight quantize)
--
-- The goal is NOT to directly call BeatEngine, RhythmMorpher, etc.
-- from here, but to centralize the logic that maps macro values
-- (0..1) to lower-level parameters. Your UI reads/writes macros via
-- this module, and your engine code queries the derived settings.

local MacroControls = {}

----------------------------------------------------------------
-- INTERNAL STATE
----------------------------------------------------------------

-- In-memory macro state; persistence is handled via proj extstate.
local state = {
  glitch_intensity = 0.5,  -- 0..1
  rhythm_chaos     = 0.5,  -- 0..1
  texture_depth    = 0.5,  -- 0..1
  human_vs_robot   = 0.5,  -- 0 = robot, 1 = very human
}

-- ExtState keys (adjust namespace/key names to your project)
local NS = "IFLS_MACROS"
local KEYS = {
  glitch_intensity = "glitch_intensity",
  rhythm_chaos     = "rhythm_chaos",
  texture_depth    = "texture_depth",
  human_vs_robot   = "human_vs_robot",
}

local function get_proj()
  return 0 -- current project
end

local function clamp01(x)
  x = tonumber(x) or 0.0
  if x < 0.0 then return 0.0 end
  if x > 1.0 then return 1.0 end
  return x
end

----------------------------------------------------------------
-- EXTSTATE PERSISTENCE
----------------------------------------------------------------

local function load_from_extstate()
  local proj = get_proj()
  for k, ext_key in pairs(KEYS) do
    local rv, val = reaper.GetProjExtState(proj, NS, ext_key)
    if rv ~= 0 and val ~= "" then
      state[k] = clamp01(val)
    end
  end
end

local function save_to_extstate()
  local proj = get_proj()
  for k, ext_key in pairs(KEYS) do
    local v = state[k]
    reaper.SetProjExtState(proj, NS, ext_key, tostring(v))
  end
end

----------------------------------------------------------------
-- PUBLIC API: RAW MACROS
----------------------------------------------------------------

function MacroControls.load()
  load_from_extstate()
end

function MacroControls.save()
  save_to_extstate()
end

function MacroControls.get_all()
  return {
    glitch_intensity = state.glitch_intensity,
    rhythm_chaos     = state.rhythm_chaos,
    texture_depth    = state.texture_depth,
    human_vs_robot   = state.human_vs_robot,
  }
end

function MacroControls.set_all(new_state)
  if not new_state then return end
  for k, v in pairs(new_state) do
    if state[k] ~= nil then
      state[k] = clamp01(v)
    end
  end
  save_to_extstate()
end

function MacroControls.get(name)
  return state[name]
end

function MacroControls.set(name, value)
  if state[name] == nil then return end
  state[name] = clamp01(value)
  save_to_extstate()
end

----------------------------------------------------------------
-- DERIVED SETTINGS
----------------------------------------------------------------
-- These helpers map macro values to suggested settings for
-- subsystems. They do not perform side effects; your engine code
-- calls them when building slice/groove/FX configs.

-- 1) Glitch / MicroSlice
--    * influences slice mode / MicroSlice density
--    * influences "glitchiness" in FX chains (if you map it)
function MacroControls.derive_glitch_settings()
  local g = state.glitch_intensity

  local slice_mode
  if g < 0.33 then
    slice_mode = "classic"
  elseif g < 0.66 then
    slice_mode = "precise"
  else
    slice_mode = "idm_microslice"
  end

  local micro_slice_density = g -- 0..1, can map to threshold/min_gap

  local fx_glitch_amount = g    -- 0..1, to be used by FX recommender

  return {
    slice_mode          = slice_mode,
    micro_slice_density = micro_slice_density,
    fx_glitch_amount    = fx_glitch_amount,
  }
end

-- 2) Rhythm chaos
--    * influences RhythmMorpher style choice + amount + density
function MacroControls.derive_rhythm_settings()
  local r = state.rhythm_chaos

  local style_name
  if r < 0.25 then
    style_name = "Straight_4onFloor"
  elseif r < 0.5 then
    style_name = "Dilla_LateSnare"
  elseif r < 0.75 then
    style_name = "BrokenBeat_Stumble"
  else
    style_name = "IDM_Chaos"
  end

  local morph_amount  = r       -- 0..1
  local density_bias  = (r - 0.5) * 2.0 -- -1..+1

  return {
    style_name   = style_name,
    morph_amount = morph_amount,
    density_bias = density_bias,
  }
end

-- 3) Texture depth
--    * influences FX chain template choice / slot activation
--    * can be mapped to texture bus send levels / plugin selection
function MacroControls.derive_texture_settings()
  local t = state.texture_depth

  local prefer_minimal_fx   = (t < 0.33)
  local prefer_moderate_fx  = (t >= 0.33 and t < 0.66)
  local prefer_heavy_fx     = (t >= 0.66)

  -- Example mapping:
  local texture_slot_weight = t -- how likely to enable "texture" slot in FX chains
  local reverb_wet_scale    = 0.5 + 0.5 * t
  local delay_feedback_scale= 0.5 + 0.5 * t

  return {
    prefer_minimal_fx    = prefer_minimal_fx,
    prefer_moderate_fx   = prefer_moderate_fx,
    prefer_heavy_fx      = prefer_heavy_fx,
    texture_slot_weight  = texture_slot_weight,
    reverb_wet_scale     = reverb_wet_scale,
    delay_feedback_scale = delay_feedback_scale,
  }
end

-- 4) Human vs Robot
--    * influences Groove amount vs straight quantize
--    * influences Humanize randomization depth
function MacroControls.derive_human_settings()
  local h = state.human_vs_robot

  local groove_amount   = h           -- 0..1
  local humanize_timing = h * 0.5     -- e.g. max +/- 50% of base humanize
  local humanize_vel    = h * 0.5

  local quantize_strength = 1.0 - h   -- 1.0 = fully quantized, 0 = free

  return {
    groove_amount      = groove_amount,
    humanize_timing    = humanize_timing,
    humanize_velocity  = humanize_vel,
    quantize_strength  = quantize_strength,
  }
end

-- Combined snapshot for debugging / logging
function MacroControls.get_derived_snapshot()
  return {
    glitch  = MacroControls.derive_glitch_settings(),
    rhythm  = MacroControls.derive_rhythm_settings(),
    texture = MacroControls.derive_texture_settings(),
    human   = MacroControls.derive_human_settings(),
  }
end

----------------------------------------------------------------
-- DEBUG
----------------------------------------------------------------

function MacroControls.debug_dump_to_console()
  local s = MacroControls.get_all()
  local d = MacroControls.get_derived_snapshot()
  reaper.ShowConsoleMsg("=== IFLS MacroControls ===\n")
  reaper.ShowConsoleMsg(string.format("glitch_intensity = %.3f\n", s.glitch_intensity))
  reaper.ShowConsoleMsg(string.format("rhythm_chaos     = %.3f\n", s.rhythm_chaos))
  reaper.ShowConsoleMsg(string.format("texture_depth    = %.3f\n", s.texture_depth))
  reaper.ShowConsoleMsg(string.format("human_vs_robot   = %.3f\n", s.human_vs_robot))
  reaper.ShowConsoleMsg("--- Derived ---\n")
  for k, v in pairs(d) do
    reaper.ShowConsoleMsg("["..k.."]\n")
    for kk, vv in pairs(v) do
      reaper.ShowConsoleMsg(string.format("  %s = %s\n", kk, tostring(vv)))
    end
  end
  reaper.ShowConsoleMsg("=========================\n")
end

-- Auto-load from extstate at first require
MacroControls.load()

return MacroControls
