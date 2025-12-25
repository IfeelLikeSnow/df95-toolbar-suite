-- IFLS_GeneratePattern_FromArtist.lua
-- Artist/Beat → PatternDomain Generator mit Parametern

local r = reaper
local resource_path = r.GetResourcePath()
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"

local function load_mod(path, name)
  local ok, mod = pcall(dofile, path .. name .. ".lua")
  if not ok or type(mod) ~= "table" then
    r.ShowMessageBox("IFLS_GeneratePattern_FromArtist: Konnte " .. name .. ".lua nicht laden.", "IFLS Pattern Generator", 0)
    return nil
  end
  return mod
end

local beatdom   = load_mod(domain_path, "IFLS_BeatDomain")
local artistdom = load_mod(domain_path, "IFLS_ArtistDomain")
local patternd  = load_mod(domain_path, "IFLS_PatternDomain")
if not beatdom or not artistdom or not patternd then return end

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
local NS_PATTERN = "DF95_PATTERN"

local function load_cfg()
  if not ok_ext or type(ext) ~= "table" then return {} end
  local function num(key, def)
    local s = ext.get_proj(NS_PATTERN, key, tostring(def))
    local v = tonumber(s)
    if not v then return def end
    return v
  end
  local cfg = {
    chaos          = num("CHAOS", 0.7),
    density        = num("DENSITY", 0.4),
    cluster_prob   = num("CLUSTER_PROB", 0.35),
    euclid_k       = num("EUCLID_K", 3),
    euclid_n       = num("EUCLID_N", 8),
    euclid_rotation= num("EUCLID_ROT", 0),
  }
  return cfg
end

local bs = beatdom.get_state and beatdom.get_state() or {}
local as = artistdom.get_artist_state and artistdom.get_artist_state() or {}
local cfg = load_cfg()

patternd.generate(as, bs, nil, cfg)
