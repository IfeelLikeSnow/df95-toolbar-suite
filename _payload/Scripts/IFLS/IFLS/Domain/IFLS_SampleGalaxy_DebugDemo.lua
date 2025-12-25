-- IFLS_SampleGalaxy_DebugDemo.lua
-- Phase 90: Debug/demo script for SampleEmbeddings + SimilaritySearch.
--
-- This script does NOT depend on your real analysis pipeline; it
-- simply seeds some fake embeddings and demonstrates:
--   * k-NN search
--   * 2D timbre-space projection

local SampleEmbeddings = require("IFLS_SampleEmbeddings")
local SimilaritySearch = require("IFLS_SimilaritySearch")

-- clear any previous state
SampleEmbeddings.clear()

-- seed some fake embeddings (normally you'd build them from features)
SampleEmbeddings.set("kick_01",  {0.8, 0.2, 0.3, 0.1, 0.1, 0.9, 0.2, 0.5, 0.4, 0.2}, nil, true)
SampleEmbeddings.set("kick_02",  {0.7, 0.3, 0.2, 0.1, 0.1, 0.8, 0.2, 0.6, 0.3, 0.2}, nil, true)
SampleEmbeddings.set("snare_01", {0.4, 0.7, 0.8, 0.3, 0.3, 0.6, 0.4, 0.7, 0.8, 0.3}, nil, true)
SampleEmbeddings.set("hat_01",   {0.2, 0.9, 0.7, 0.4, 0.5, 0.4, 0.6, 0.5, 0.9, 0.4}, nil, true)
SampleEmbeddings.set("fx_01",    {0.5, 0.5, 0.9, 0.9, 0.2, 0.3, 0.7, 0.4, 0.5, 0.8}, nil, true)

reaper.ShowConsoleMsg("=== SampleGalaxy Debug Demo ===\n")

-- k-NN search for kick_01
local knn = SimilaritySearch.find_similar_to_sample("kick_01", {k = 3})
reaper.ShowConsoleMsg("Similar to kick_01:\n")
for i, r in ipairs(knn) do
  reaper.ShowConsoleMsg(string.format("  #%d id=%s dist=%.3f\n", i, r.id, r.dist))
end

-- Build simple timbre space
local pts = SimilaritySearch.build_timbre_space()
reaper.ShowConsoleMsg("Timbre space points (normalized):\n")
for _, p in ipairs(pts) do
  reaper.ShowConsoleMsg(string.format("  id=%s x=%.3f y=%.3f\n", p.id, p.x, p.y))
end
reaper.ShowConsoleMsg("=== End Demo ===\n")
