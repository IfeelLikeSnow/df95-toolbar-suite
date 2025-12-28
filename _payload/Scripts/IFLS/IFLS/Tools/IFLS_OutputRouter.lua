-- IFLS_OutputRouter.lua
-- IFLS Output Engine / Pipeline-Orchestrator
-- ------------------------------------------

local r = reaper
local resource_path = r.GetResourcePath()
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local config_path   = resource_path .. "/Scripts/IFLS/IFLS/Config/"

local function load_mod(path, name)
  local ok, mod = pcall(dofile, path .. name .. ".lua")
  if not ok or type(mod) ~= "table" then
    r.ShowMessageBox("IFLS_OutputRouter: Konnte " .. name .. ".lua nicht laden.", "IFLS OutputRouter", 0)
    return nil
  end
  return mod
end

local beatdom   = load_mod(domain_path, "IFLS_BeatDomain")
local artistdom = load_mod(domain_path, "IFLS_ArtistDomain")
local patternd  = load_mod(domain_path, "IFLS_PatternDomain")

if not beatdom or not artistdom or not patternd then return end

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
  }
end

local action_map = {}
do
  local ok_map, map = pcall(dofile, config_path .. "IFLS_ActionMap.lua")
  if ok_map and type(map) == "table" then action_map = map end
end

local function msg(s) r.ShowConsoleMsg(tostring(s) .. "\n") end

local function run_named(named)
  if not named or named == "" then return end
  local cmd = r.NamedCommandLookup(named)
  if cmd == 0 then
    msg("OutputRouter: NamedCommandLookup fehlgeschlagen für " .. tostring(named))
    return
  end
  r.Main_OnCommand(cmd, 0)
end

local function get_map(group, key)
  local g = action_map[group]
  if type(g) == "table" and g[key] and g[key] ~= "" then return g[key] end
  return nil
end

local NS_PATTERN = "DF95_PATTERN"
local function load_cfg()
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

local use_midi   = as.use_midi_layers   and true or false
local use_loop   = as.use_loop_layers   and true or false
local use_speech = as.use_speech_layers and true or false

if use_midi then
  local named = get_map("Layers", "V196_MIDI_LAYERS")
  run_named(named)
end

if use_loop then
  local named = get_map("Layers", "V198_LOOP_LAYERS")
  run_named(named)
end

if use_speech then
  local named = get_map("Layers", "V198_SPEECH_LAYERS")
  run_named(named)
end

msg("IFLS_OutputRouter: Pattern + Layer-Engines (sofern gemappt) ausgeführt.")
