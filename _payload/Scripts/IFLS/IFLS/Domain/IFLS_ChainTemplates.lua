-- IFLS_ChainTemplates.lua
-- Phase 89: FX-Chain Templates for IFLS / DF95
--
-- This module defines *abstract* FX-chain templates that describe
-- the *roles* of processors in a chain (EQ, dynamics, texture, etc.)
-- rather than specific plugins.
--
-- The templates are then matched against a context:
--   * instrument (kick, snare, hat, perc, tonal, drone, fx, bus, master)
--   * flavors  (IDM flavors like GlitchCore, AmbientSpace, etc.)
--   * adjectives (punchy, airy, warm, dirty, lofi, etc.)
--
-- A separate recommender (see IFLS_FXChainRecommender.lua) will then
-- choose concrete plugins for each slot using PluginMeta/Flavor data.

local ChainTemplates = {}

----------------------------------------------------------------
-- TEMPLATE MODEL
----------------------------------------------------------------
-- A template is a table:
-- {
--   name    = "Kick_Punchy_Modern",
--   context = {
--     instrument = "kick",
--     flavors    = { "GlitchCore", "DrumFX" },
--     adjectives = { "punchy", "modern" },
--   },
--   slots = {
--     {
--       role = "filter_eq",  -- plugin category
--       tags = { "sub", "tight" }, -- optional hints for PluginMeta
--       optional = false,
--     },
--     {
--       role = "dynamics",
--       tags = { "punch", "bus" },
--     },
--     {
--       role = "saturation",
--       tags = { "clip", "warm" },
--       optional = true,
--     },
--     ...
--   }
-- }

local function make_template(name, context, slots)
  return {
    name    = name,
    context = context or {},
    slots   = slots or {},
  }
end

----------------------------------------------------------------
-- BUILT-IN TEMPLATES
----------------------------------------------------------------

local templates = {}

-- Punchy modern kick
table.insert(templates, make_template(
  "Kick_Punchy_Modern",
  {
    instrument = "kick",
    flavors    = { "GlitchCore", "DrumFX" },
    adjectives = { "punchy", "modern" },
  },
  {
    { role = "filter_eq",   tags = { "sub", "tight" } },
    { role = "dynamics",    tags = { "punch", "fast" } },
    { role = "saturation",  tags = { "clip", "transient" }, optional = true },
    { role = "texture",     tags = { "click", "attack" },    optional = true },
  }
))

-- Snare: cracky and bright
table.insert(templates, make_template(
  "Snare_Cracky_Bright",
  {
    instrument = "snare",
    flavors    = { "GlitchCore", "Microglitch", "DrumFX" },
    adjectives = { "cracky", "bright" },
  },
  {
    { role = "filter_eq",   tags = { "snap", "presence" } },
    { role = "dynamics",    tags = { "snap", "bus" } },
    { role = "texture",     tags = { "noise", "air" }, optional = true },
    { role = "reverb",      tags = { "short", "room" }, optional = true },
  }
))

-- Hats / Cymbals: crisp and controlled
table.insert(templates, make_template(
  "Hat_Crisp_Controlled",
  {
    instrument = "hat",
    flavors    = { "GlitchCore", "Microbeats" },
    adjectives = { "crisp", "tight" },
  },
  {
    { role = "filter_eq", tags = { "highpass", "deharsh" } },
    { role = "dynamics",  tags = { "transient", "tame" }, optional = true },
    { role = "texture",   tags = { "shimmer", "sparkle" }, optional = true },
  }
))

-- Drum bus: glue + color
table.insert(templates, make_template(
  "DrumBus_Glue_Color",
  {
    instrument = "bus_drum",
    flavors    = { "GlitchCore", "DrumFX", "Microbeats" },
    adjectives = { "glue", "color" },
  },
  {
    { role = "filter_eq",     tags = { "bus", "broad" } },
    { role = "dynamics",      tags = { "bus", "glue" } },
    { role = "saturation",    tags = { "bus", "tape" }, optional = true },
    { role = "parallel_comp", tags = { "slam" },        optional = true },
  }
))

-- Ambient drone: wide and evolving
table.insert(templates, make_template(
  "Drone_Wide_Evolving",
  {
    instrument = "drone",
    flavors    = { "AmbientSpace", "Drone" },
    adjectives = { "wide", "evolving" },
  },
  {
    { role = "filter_eq", tags = { "tone", "tilt" }, optional = true },
    { role = "reverb",    tags = { "huge", "modulated" } },
    { role = "delay",     tags = { "feedback", "texture" }, optional = true },
    { role = "modulation",tags = { "chorus", "phaser" }, optional = true },
    { role = "texture",   tags = { "granular", "spectral" }, optional = true },
  }
))

-- Tonal lead: clean but animated
table.insert(templates, make_template(
  "Tonal_Lead_Clean_Animated",
  {
    instrument = "tonal",
    flavors    = { "Microglitch", "Microbeats", "GlitchCore" },
    adjectives = { "clean", "animated" },
  },
  {
    { role = "filter_eq", tags = { "surgical" } },
    { role = "dynamics",  tags = { "control" }, optional = true },
    { role = "modulation",tags = { "movement" }, optional = true },
    { role = "delay",     tags = { "sync", "stereo" }, optional = true },
    { role = "reverb",    tags = { "plate", "short" }, optional = true },
  }
))

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

--- Return list of all templates.
function ChainTemplates.list()
  return templates
end

--- Find template by exact name.
function ChainTemplates.get(name)
  for _, t in ipairs(templates) do
    if t.name == name then return t end
  end
  return nil
end

--- Utility: add custom template (e.g. user-defined).
function ChainTemplates.add(template)
  if not template or not template.name then return end
  for i, t in ipairs(templates) do
    if t.name == template.name then
      templates[i] = template
      return
    end
  end
  table.insert(templates, template)
end

--- Utility: compute a simple similarity score between a template context
--  and a requested context. Higher is better. This is used by the
--  recommender to pick the "closest" template.
function ChainTemplates.score_for_context(template, ctx)
  local score = 0.0
  ctx = ctx or {}
  local tctx = template.context or {}

  if ctx.instrument and tctx.instrument and ctx.instrument == tctx.instrument then
    score = score + 3.0
  end

  local function overlap(a, b)
    if not a or not b then return 0 end
    local set = {}
    for _, v in ipairs(a) do set[v] = true end
    local c = 0
    for _, v in ipairs(b) do if set[v] then c = c + 1 end end
    return c
  end

  local flav_overlap = overlap(ctx.flavors or {}, tctx.flavors or {})
  local adj_overlap  = overlap(ctx.adjectives or {}, tctx.adjectives or {})

  score = score + flav_overlap * 1.5
  score = score + adj_overlap * 1.0

  return score
end

--- Find the best matching template for a given context.
function ChainTemplates.find_best_for_context(ctx)
  local best, best_score
  for _, t in ipairs(templates) do
    local s = ChainTemplates.score_for_context(t, ctx)
    if not best or s > best_score then
      best = t
      best_score = s
    end
  end
  return best, best_score
end

return ChainTemplates
