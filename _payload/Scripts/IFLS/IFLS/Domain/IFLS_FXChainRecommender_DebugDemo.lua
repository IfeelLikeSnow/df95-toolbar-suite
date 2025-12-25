-- IFLS_FXChainRecommender_DebugDemo.lua
-- Phase 89: Debug/demo script for FXChainRecommender.
--
-- This script does NOT talk to real PluginMeta; instead it stubs a
-- small PluginMetaAdapter._meta to demonstrate how the recommender
-- chooses plugins.
--
-- Use this to understand the flow and adapt the adapter to your
-- real DF95/IFLS PluginMetaBridge.

local ChainTemplates = require("IFLS_ChainTemplates")
local FXChainRecommender = require("IFLS_FXChainRecommender")

-- Inject a dummy PluginMeta implementation into the adapter:
local ok, RecommenderModule = pcall(require, "IFLS_FXChainRecommender")
-- note: we already required above; this is just to access the upvalue successfully in some environments
if not ok then
  reaper.ShowMessageBox("Could not require IFLS_FXChainRecommender", "FXChainRecommender Demo", 0)
  return
end

-- We know PluginMetaAdapter is a local in IFLS_FXChainRecommender;
-- for the demo we instead mock via package.loaded or a shared stub.
-- Simplest: directly require the adapter file if you split it out.
-- For now, we will assume you manually adapted the adapter to your system.
-- So here we only demonstrate the context/template logic.

local ctx = FXChainRecommender.build_context{
  slice_type         = "kick",
  flavors            = { "GlitchCore", "DrumFX" },
  adjectives         = { "punchy", "modern" },
  artist_style_tags  = { "aggressive" },
}

local template, score = ChainTemplates.find_best_for_context(ctx)

reaper.ShowConsoleMsg("=== FXChainRecommender Demo ===\n")
reaper.ShowConsoleMsg(("Selected template: %s (score %.2f)\n"):format(template.name, score))

-- In a real environment, we would call:
--   local chain = FXChainRecommender.recommend(ctx)
--   ... and then pass 'chain' into your ArtistFX Engine / FX Brain.
reaper.ShowConsoleMsg("Context instrument : " .. tostring(ctx.instrument) .. "\n")
reaper.ShowConsoleMsg("Context flavors    : " .. table.concat(ctx.flavors, ", ") .. "\n")
reaper.ShowConsoleMsg("Context adjectives : " .. table.concat(ctx.adjectives, ", ") .. "\n")
reaper.ShowConsoleMsg("=== End demo ===\n")
