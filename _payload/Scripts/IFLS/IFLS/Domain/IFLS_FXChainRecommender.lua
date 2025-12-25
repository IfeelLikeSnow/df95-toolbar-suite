-- IFLS_FXChainRecommender.lua
-- Phase 89: Intelligent FX-Chain Recommendation
--
-- This module connects:
--   * ChainTemplates (abstract chain structures)
--   * PluginMeta / Flavor classification
--   * Artist / Flavor / Slice context
--
-- and returns a *concrete* FX-chain specification:
--   - which plugin in which slot
--   - and a short "reason" for each decision.
--
-- It does NOT directly instantiate plugins in REAPER; that is the job
-- of your existing ArtistFX Engine / FX Brain. Instead, this module
-- produces a high-level "plan" you can feed into that system.

local ChainTemplates = require("IFLS_ChainTemplates")

----------------------------------------------------------------
-- PLUGIN META ADAPTER
----------------------------------------------------------------
-- We do not know the exact shape of your PluginMetaBridge, so this
-- module uses a small adapter that you can wire up to DF95_PluginMeta /
-- DF95_PluginFlavors / ArtistFX internals.
--
-- You should implement the function "PluginMetaAdapter.find_plugins"
-- so that it returns a list of plugin entries matching a role + hints.

local PluginMetaAdapter = {}

-- Stub: try a couple of common module names, otherwise fall back
-- to a dummy implementation that returns an empty list.
do
  local ok, meta = pcall(require, "DF95_PluginMeta")
  if ok then
    PluginMetaAdapter._meta = meta
  else
    ok, meta = pcall(require, "DF95_PluginFlavors")
    if ok then
      PluginMetaAdapter._meta = meta
    end
  end
end

--- Find candidate plugins for a given slot.
-- params:
--   slot: {
--     role = "filter_eq" | "reverb" | "dynamics" | ...,
--     tags = { "punchy", "bus", ... } (optional),
--   }
--   context: {
--     instrument,
--     flavors,
--     adjectives,
--   }
--
-- return:
--   list of plugin entries, each like:
--     {
--       id      = "<internal plugin id or name>",
--       name    = "Plugin Name",
--       score   = 1.0, -- higher is better
--       tags    = {...},
--       flavor  = "Glitch" | "Granular" | ...,
--       category = "filter_eq" | "reverb" | ...
--     }
function PluginMetaAdapter.find_plugins(slot, context)
  local meta = PluginMetaAdapter._meta
  if not meta or not meta.find_plugins then
    -- Fallback stub: return empty list.
    return {}
  end

  -- This part is intentionally generic; adapt to your DF95_*/IFLS_* APIs.
  local query = {
    category  = slot.role,
    tags      = slot.tags,
    flavors   = context.flavors,
    adjectives= context.adjectives,
    instrument= context.instrument,
  }

  local ok, plugins = pcall(meta.find_plugins, meta, query)
  if not ok or not plugins then
    return {}
  end
  return plugins
end

----------------------------------------------------------------
-- CONTEXT + SCORING
----------------------------------------------------------------

local FXChainRecommender = {}

--- Build a recommendation context from various inputs.
-- This is a convenience helper; if you already have a good context
-- structure, you can ignore this and pass your own "ctx" to recommend().
function FXChainRecommender.build_context(args)
  local ctx = {}

  if args.slice_type then
    -- map slice type to instrument-ish label
    -- (kick, snare, hat, perc, tonal, drone, fx, impact, etc.)
    ctx.instrument = args.slice_type
  elseif args.instrument then
    ctx.instrument = args.instrument
  end

  ctx.flavors    = args.flavors or {}
  ctx.adjectives = args.adjectives or {}

  if args.artist_style_tags then
    -- merge artist style tags into adjectives
    for _, tag in ipairs(args.artist_style_tags) do
      table.insert(ctx.adjectives, tag)
    end
  end

  return ctx
end

--- Select a template given a context.
function FXChainRecommender.select_template(ctx)
  return ChainTemplates.find_best_for_context(ctx)
end

-- Score a candidate plugin for a given slot + context.
local function score_plugin_for_slot(plugin, slot, ctx)
  local score = 0.0

  if plugin.category == slot.role then
    score = score + 2.0
  end

  -- if plugin has flavor/tag data, reward overlaps
  local function overlap(a, b)
    if not a or not b then return 0 end
    local set = {}
    for _, v in ipairs(a) do set[v] = true end
    local c = 0
    for _, v in ipairs(b) do if set[v] then c = c + 1 end end
    return c
  end

  score = score + overlap(plugin.tags or {}, slot.tags or {}) * 1.0
  score = score + overlap(plugin.flavors or {}, ctx.flavors or {}) * 1.2
  score = score + overlap(plugin.adjectives or {}, ctx.adjectives or {}) * 1.0

  -- Optionally, if PluginMeta supplies some quality metric:
  if plugin.quality_score then
    score = score + plugin.quality_score * 0.5
  end

  return score
end

--- For a template slot, choose the best plugin candidate(s).
local function choose_plugin_for_slot(slot, ctx)
  local candidates = PluginMetaAdapter.find_plugins(slot, ctx)
  if not candidates or #candidates == 0 then
    return nil, "no candidates"
  end

  local best, best_score
  for _, p in ipairs(candidates) do
    local s = score_plugin_for_slot(p, slot, ctx)
    if not best or s > best_score then
      best = p
      best_score = s
    end
  end

  if not best then
    return nil, "no scored candidates"
  end

  local reason_parts = {}
  table.insert(reason_parts, ("role=%s"):format(slot.role or ""))
  if slot.tags and #slot.tags > 0 then
    table.insert(reason_parts, "slot_tags=" .. table.concat(slot.tags, ","))
  end
  if best.flavors and #best.flavors > 0 then
    table.insert(reason_parts, "plugin_flavors=" .. table.concat(best.flavors, ","))
  end
  if best.tags and #best.tags > 0 then
    table.insert(reason_parts, "plugin_tags=" .. table.concat(best.tags, ","))
  end

  local reason = table.concat(reason_parts, " | ")

  return {
    slot   = slot,
    plugin = best,
    score  = best_score,
    reason = reason,
  }, nil
end

----------------------------------------------------------------
-- MAIN API
----------------------------------------------------------------

--- Recommend a full FX-chain for the given context.
-- params:
--   ctx: context table as returned by build_context()
-- return:
--   chain_spec: {
--     template_name = ...,
--     context       = ctx,
--     slots         = {
--       {
--         role       = slot.role,
--         optional   = slot.optional,
--         plugin_id  = plugin.id,
--         plugin_name= plugin.name,
--         reason     = "...",
--       },
--       ...
--     },
--     notes         = "Human-readable explanation",
--   }
function FXChainRecommender.recommend(ctx)
  local template, tscore = FXChainRecommender.select_template(ctx)
  if not template then
    return {
      template_name = nil,
      context       = ctx,
      slots         = {},
      notes         = "No matching template found.",
    }
  end

  local chain_slots = {}
  for _, slot in ipairs(template.slots or {}) do
    local rec, err = choose_plugin_for_slot(slot, ctx)
    if rec then
      table.insert(chain_slots, {
        role        = slot.role,
        optional    = slot.optional or false,
        plugin_id   = rec.plugin.id,
        plugin_name = rec.plugin.name,
        reason      = rec.reason,
      })
    else
      -- Keep empty slot info for transparency/debugging
      table.insert(chain_slots, {
        role        = slot.role,
        optional    = true,
        plugin_id   = nil,
        plugin_name = nil,
        reason      = "No plugin selected: " .. tostring(err),
      })
    end
  end

  -- Build human-readable notes
  local notes_lines = {}
  table.insert(notes_lines, ("Template: %s (score %.2f)"):format(template.name, tscore or 0))
  if ctx.instrument then
    table.insert(notes_lines, ("Instrument: %s"):format(ctx.instrument))
  end
  if ctx.flavors and #ctx.flavors > 0 then
    table.insert(notes_lines, ("Flavors: %s"):format(table.concat(ctx.flavors, ", ")))
  end
  if ctx.adjectives and #ctx.adjectives > 0 then
    table.insert(notes_lines, ("Adjectives: %s"):format(table.concat(ctx.adjectives, ", ")))
  end

  local chain_spec = {
    template_name = template.name,
    context       = ctx,
    slots         = chain_slots,
    notes         = table.concat(notes_lines, " | "),
  }

  return chain_spec
end

return FXChainRecommender
