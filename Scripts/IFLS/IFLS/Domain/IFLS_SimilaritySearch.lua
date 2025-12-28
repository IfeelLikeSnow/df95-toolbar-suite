-- IFLS_SimilaritySearch.lua
-- Phase 90: Similarity Search & Simple 2D "Timbre Space"
--
-- This module builds on IFLS_SampleEmbeddings to:
--   * find similar samples for a given reference
--   * perform k-NN similarity search
--   * provide a simple 2D projection for UI "galaxy" views
--
-- It intentionally stays simple (linear scan) so it works with Lua and
-- mid-sized libraries; you can later swap in a vector index / ANN
-- backend if needed.

local SampleEmbeddings = require("IFLS_SampleEmbeddings")

local SimilaritySearch = {}

----------------------------------------------------------------
-- K-NN SEARCH
----------------------------------------------------------------

--- Internal helper: linear K-NN search over all embeddings.
local function knn_search(ref_vec, opts)
  opts = opts or {}
  local k       = opts.k or 16
  local metric  = opts.metric or "cosine"
  local filter  = opts.filter -- optional function(entry) -> bool

  local all_emb = SampleEmbeddings.all()
  local results = {}

  for _, entry in ipairs(all_emb) do
    if not filter or filter(entry) then
      local d = SampleEmbeddings.distance(ref_vec, entry.vec, metric)
      table.insert(results, {
        id    = entry.id,
        vec   = entry.vec,
        meta  = entry.meta,
        dist  = d,
      })
    end
  end

  table.sort(results, function(a, b) return a.dist < b.dist end)

  -- trim to k
  local out = {}
  local n = math.min(k, #results)
  for i = 1, n do
    out[i] = results[i]
  end
  return out
end

--- Find K nearest neighbours for a given sample_id.
-- opts: { k, metric, filter }
function SimilaritySearch.find_similar_to_sample(sample_id, opts)
  local entry = SampleEmbeddings.get(sample_id)
  if not entry or not entry.vec then
    return {}
  end
  return knn_search(entry.vec, opts)
end

--- Find K nearest neighbours to an arbitrary embedding vector.
-- This is useful when you have a "virtual" point (e.g. centroid of
-- multiple slices, or a user-drawn timbre position).
function SimilaritySearch.find_similar_to_vector(vec, opts)
  return knn_search(vec, opts)
end

----------------------------------------------------------------
-- SIMPLE 2D PROJECTION
----------------------------------------------------------------
-- For a 2D "timbre space" you can:
--   * use actual dimensionality reduction (PCA, t-SNE, UMAP etc.) in
--     an external tool and feed the 2D coords back into IFLS, OR
--   * approximate a 2D view with a linear projection of selected
--     embedding dimensions.
--
-- Here we provide a simple linear projection based on two indices.

local function project_linear(entries, dim_x, dim_y)
  dim_x = dim_x or 1
  dim_y = dim_y or 2

  local points = {}
  local minx, maxx = math.huge, -math.huge
  local miny, maxy = math.huge, -math.huge

  for _, e in ipairs(entries) do
    local vx = e.vec[dim_x] or 0.0
    local vy = e.vec[dim_y] or 0.0
    if vx < minx then minx = vx end
    if vx > maxx then maxx = vx end
    if vy < miny then miny = vy end
    if vy > maxy then maxy = vy end
    table.insert(points, {
      id   = e.id,
      x    = vx,
      y    = vy,
      vec  = e.vec,
      meta = e.meta,
    })
  end

  local rangex = (maxx - minx)
  local rangey = (maxy - miny)
  if rangex <= 1e-9 then rangex = 1.0 end
  if rangey <= 1e-9 then rangey = 1.0 end

  -- normalize to [0,1] range for UI convenience
  for _, p in ipairs(points) do
    p.x = (p.x - minx) / rangex
    p.y = (p.y - miny) / rangey
  end

  return points
end

--- Build a simple 2D projection ("timbre space") from all embeddings.
-- opts:
--   filter: optional function(entry) -> bool
--   dim_x : embedding dimension index used for X (default 1)
--   dim_y : embedding dimension index used for Y (default 2)
--
-- Returns:
--   points: {
--     { id, x, y, vec, meta }, ...
--   }
function SimilaritySearch.build_timbre_space(opts)
  opts = opts or {}
  local filter = opts.filter
  local dim_x  = opts.dim_x
  local dim_y  = opts.dim_y

  local entries = {}
  for _, e in ipairs(SampleEmbeddings.all()) do
    if not filter or filter(e) then
      table.insert(entries, e)
    end
  end

  return project_linear(entries, dim_x, dim_y)
end

return SimilaritySearch
