-- IFLS_SampleEmbeddings.lua
-- Phase 90: Sample Embeddings & Vector Store
--
-- This module manages fixed-size numeric embeddings for samples/slices.
-- Embeddings are simple numeric vectors derived from existing analysis
-- features (spectral centroid, flux, transient sharpness, tonalness,
-- loudness, etc.). You already compute many of these in your Slice /
-- Feature pipeline; this module just packs them into vectors and gives
-- you basic distance operations.
--
-- It is intentionally minimal and in-memory. Persistence (storing /
-- loading embeddings to disk or SampleDB) should be handled by the
-- surrounding system (e.g. IFLS_SampleDB).

local SampleEmbeddings = {}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

-- Define which features and in what order they form the embedding.
-- Adapt this list to your actual feature names.
local FEATURE_ORDER = {
  "spectral_centroid",
  "spectral_spread",
  "spectral_flux",
  "spectral_flatness",
  "zcr",
  "transient_sharpness",
  "tonalness",
  "loudness",
  "brightness",
  "noisiness",
}

-- In-memory index: sample_id -> { id = sample_id, vec = {...}, meta = {...} }
local emb_index = {}

----------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- simple normalization helper
local function normalize_vec(vec)
  local max_abs = 0.0
  for i = 1, #vec do
    local a = math.abs(vec[i] or 0.0)
    if a > max_abs then max_abs = a end
  end
  if max_abs <= 1e-12 then return vec end
  local out = {}
  for i = 1, #vec do
    out[i] = vec[i] / max_abs
  end
  return out
end

----------------------------------------------------------------
-- EMBEDDING CONSTRUCTION
----------------------------------------------------------------

--- Build an embedding vector from a feature table.
-- features: table with numeric fields matching FEATURE_ORDER keys, e.g.:
--   {
--     spectral_centroid   = ...,
--     spectral_spread     = ...,
--     spectral_flux       = ...,
--     spectral_flatness   = ...,
--     zcr                 = ...,
--     transient_sharpness = ...,
--     tonalness           = ...,
--     loudness            = ...,
--     brightness          = ...,
--     noisiness           = ...,
--   }
--
-- The caller is responsible for making sure these numbers are already
-- normalized or scaled sensibly (e.g. z-scored across the dataset).
function SampleEmbeddings.from_features(features)
  local vec = {}
  for i, key in ipairs(FEATURE_ORDER) do
    local v = features[key] or 0.0
    vec[i] = v
  end
  return normalize_vec(vec)
end

--- Register/update an embedding for a sample.
-- sample_id: string or numeric id
-- features : table of features (see from_features) OR
--            direct numeric vector if is_vector == true
-- meta     : optional table with metadata (e.g. path, tags, flavor)
-- is_vector: if true, "features" is treated as vector directly
function SampleEmbeddings.set(sample_id, features, meta, is_vector)
  if not sample_id or not features then return end
  local vec
  if is_vector then
    vec = {}
    for i = 1, #features do
      vec[i] = tonumber(features[i]) or 0.0
    end
    vec = normalize_vec(vec)
  else
    vec = SampleEmbeddings.from_features(features)
  end
  emb_index[sample_id] = {
    id   = sample_id,
    vec  = vec,
    meta = meta or {},
  }
end

--- Get embedding entry for sample_id.
function SampleEmbeddings.get(sample_id)
  return emb_index[sample_id]
end

--- Return all embedding entries as an array.
function SampleEmbeddings.all()
  local out = {}
  for _, entry in pairs(emb_index) do
    table.insert(out, entry)
  end
  return out
end

--- Remove embedding for given sample_id.
function SampleEmbeddings.remove(sample_id)
  emb_index[sample_id] = nil
end

--- Clear all embeddings (e.g. before rebuild).
function SampleEmbeddings.clear()
  for k in pairs(emb_index) do
    emb_index[k] = nil
  end
end

----------------------------------------------------------------
-- DISTANCE METRICS
----------------------------------------------------------------

--- Euclidean distance between two vectors.
local function euclidean(a, b)
  local n = math.min(#a, #b)
  local sum = 0.0
  for i = 1, n do
    local d = (a[i] or 0.0) - (b[i] or 0.0)
    sum = sum + d * d
  end
  return math.sqrt(sum)
end

--- Cosine distance (1 - cosine similarity) between two vectors.
local function cosine_distance(a, b)
  local n = math.min(#a, #b)
  local dot, na, nb = 0.0, 0.0, 0.0
  for i = 1, n do
    local va = a[i] or 0.0
    local vb = b[i] or 0.0
    dot = dot + va * vb
    na = na + va * va
    nb = nb + vb * vb
  end
  if na <= 1e-12 or nb <= 1e-12 then
    return 1.0
  end
  local sim = dot / (math.sqrt(na) * math.sqrt(nb))
  return 1.0 - sim
end

--- Expose distance functions.
function SampleEmbeddings.distance(a, b, metric)
  metric = metric or "cosine"
  if metric == "euclidean" then
    return euclidean(a, b)
  else
    return cosine_distance(a, b)
  end
end

return SampleEmbeddings
