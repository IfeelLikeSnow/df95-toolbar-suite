-- IFLS_SceneDomain.lua
-- Phase 13: Scene / Snapshot Domain
-- ---------------------------------
-- Szenen speichern und laden:
--   * BeatDomain-State
--   * ArtistDomain-State
--   * Pattern-Config (DF95_PATTERN ExtState)
--   * TuningDomain-State
--
-- Jede Scene hat eine Slot-ID (1..N) und einen Namen.
-- Daten werden in projektbezogenen ExtStates abgelegt.
--
-- API:
--   local scene = dofile(".../IFLS_SceneDomain.lua")
--   scene.save_scene(slot, opt_name)
--   scene.load_scene(slot)
--   scene.list_scenes() -> { {slot=1,name="..."}, ... }

local r = reaper

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
    del_proj = function() end,
  }
end

local function load_dom(name)
  local ok, mod = pcall(dofile, domain_path .. name .. ".lua")
  if not ok or type(mod) ~= "table" then
    return nil
  end
  return mod
end

local beatdom   = load_dom("IFLS_BeatDomain")
local artistdom = load_dom("IFLS_ArtistDomain")
local tuningdom = load_dom("IFLS_TuningDomain")

local M = {}

local NS_SCENE_META = "DF95_SCENES"
local NS_SCENE_FMT  = "DF95_SCENE_%d"
local NS_PATTERN    = "DF95_PATTERN"
local NS_EUCLIDPRO  = "IFLS_EUCLIDPRO"


local function get_scene_ns(slot)
  slot = tonumber(slot) or 1
  return string.format(NS_SCENE_FMT, slot)
end

local function serialize_table(t)
  local ok, json = pcall(function() return r.NF_SerializeObject and r.NF_SerializeObject(t) end)
  if ok and json then return json end
  -- Fallback: Lua table pretty printer (very simple, keys as strings)
  local parts = {}
  table.insert(parts, "{")
  for k,v in pairs(t) do
    table.insert(parts, string.format("[%q]=%q,", tostring(k), tostring(v)))
  end
  table.insert(parts, "}")
  return table.concat(parts)
end

local function deserialize_table(str)
  if not str or str == "" then return {} end
  local ok, obj = pcall(function()
    if r.NF_DeserializeObject then
      return r.NF_DeserializeObject(str)
    end
    return nil
  end)
  if ok and type(obj) == "table" then return obj end
  return {}
end


-- SceneEvolution helpers (Phase 25)
local function read_sceneevo_cfg()
  local ok, mod = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_SceneEvolutionDomain.lua")
  if ok and type(mod) == "table" and mod.read_cfg then
    return mod.read_cfg()
  end
  return nil
end

local function write_sceneevo_cfg(cfg)
  local ok, mod = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_SceneEvolutionDomain.lua")
  if ok and type(mod) == "table" and mod.write_cfg and mod.apply_to_domains then
    mod.write_cfg(cfg)
    mod.apply_to_domains(cfg)
  elseif ok and type(mod) == "table" and mod.write_cfg then
    mod.write_cfg(cfg)
  end
end

local function read_pattern_cfg()
  local function num(key, def)
    local s = ext.get_proj(NS_PATTERN, key, tostring(def))
    local v = tonumber(s)
    if not v then return def end
    return v
  end
  return {
    mode_hint    = ext.get_proj(NS_PATTERN, "MODE_HINT", ""),
    chaos        = num("CHAOS", 0.7),
    density      = num("DENSITY", 0.4),
    cluster_prob = num("CLUSTER_PROB", 0.35),
    euclid_k     = num("EUCLID_K", 3),
    euclid_n     = num("EUCLID_N", 8),
    euclid_rot   = num("EUCLID_ROT", 0),
  }
end

local function write_pattern_cfg(cfg)
  if not cfg then return end
  ext.set_proj(NS_PATTERN, "MODE_HINT", cfg.mode_hint or "")
  ext.set_proj(NS_PATTERN, "CHAOS", tostring(cfg.chaos or 0.7))
  ext.set_proj(NS_PATTERN, "DENSITY", tostring(cfg.density or 0.4))
  ext.set_proj(NS_PATTERN, "CLUSTER_PROB", tostring(cfg.cluster_prob or 0.35))
  ext.set_proj(NS_PATTERN, "EUCLID_K", tostring(cfg.euclid_k or 3))
  ext.set_proj(NS_PATTERN, "EUCLID_N", tostring(cfg.euclid_n or 8))
  ext.set_proj(NS_PATTERN, "EUCLID_ROT", tostring(cfg.euclid_rot or 0))
end

local function ep_num(key, def)
  local s = ext.get_proj(NS_EUCLIDPRO, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function read_euclidpro_cfg()
  local cfg = {
    steps        = ep_num("STEPS", 16),
    hits         = ep_num("HITS", 5),
    rotation     = ep_num("ROTATION", 0),
    accent_mode  = ext.get_proj(NS_EUCLIDPRO, "ACCENT_MODE", "none"),
    hit_prob     = ep_num("HIT_PROB", 1.0),
    ghost_prob   = ep_num("GHOST_PROB", 0.0),
    ratchet_prob = ep_num("RATCHET_PROB", 0.0),
    ratchet_min  = ep_num("RATCHET_MIN", 2),
    ratchet_max  = ep_num("RATCHET_MAX", 4),
    ratchet_shape= ext.get_proj(NS_EUCLIDPRO, "RATCHET_SHAPE", "up"),
  }

  cfg.lanes = {
    {
      pitch      = ep_num("L1_PITCH", 36),
      div        = ep_num("L1_DIV", 1),
      base_vel   = ep_num("L1_BASE_VEL", 96),
      accent_vel = ep_num("L1_ACCENT_VEL", 118),
    },
    {
      pitch      = ep_num("L2_PITCH", 38),
      div        = ep_num("L2_DIV", 1),
      base_vel   = ep_num("L2_BASE_VEL", 90),
      accent_vel = ep_num("L2_ACCENT_VEL", 112),
    },
    {
      pitch      = ep_num("L3_PITCH", 42),
      div        = ep_num("L3_DIV", 1),
      base_vel   = ep_num("L3_BASE_VEL", 84),
      accent_vel = ep_num("L3_ACCENT_VEL", 108),
    },
  }

  return cfg
end

local function write_euclidpro_cfg(cfg)
  if not cfg then return end


local function get_scene_meta()
----------------------------------------------------------------
-- Scene / Snapshot Domain
-- Hinweis: Polyrhythm (IFLS_POLYRHYTHM) wird aktuell nicht gesnapshottet; eigener State.
-- ---------------------------------
-- Szenen speichern und laden:
--   * BeatDomain-State
--   * ArtistDomain-State
--   * Pattern-Config (DF95_PATTERN ExtState)
--   * TuningDomain-State
--
-- Jede Scene hat eine Slot-ID (1..N) und einen Namen.
-- Daten werden in projektbezogenen ExtStates abgelegt.
--
-- API:
--   local scene = dofile(".../IFLS_SceneDomain.lua")
--   scene.save_scene(slot, opt_name)
--   scene.load_scene(slot)
--   scene.list_scenes() -> { {slot=1,name="..."}, ... }

local r = reaper

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
    del_proj = function() end,
  }
end

local function load_dom(name)
  local ok, mod = pcall(dofile, domain_path .. name .. ".lua")
  if not ok or type(mod) ~= "table" then
    return nil
  end
  return mod
end

local beatdom   = load_dom("IFLS_BeatDomain")
local artistdom = load_dom("IFLS_ArtistDomain")
local tuningdom = load_dom("IFLS_TuningDomain")

local M = {}

local NS_SCENE_META = "DF95_SCENES"
local NS_SCENE_FMT  = "DF95_SCENE_%d"
local NS_PATTERN    = "DF95_PATTERN"
local NS_EUCLIDPRO  = "IFLS_EUCLIDPRO"


local function get_scene_ns(slot)
  slot = tonumber(slot) or 1
  return string.format(NS_SCENE_FMT, slot)
end

local function serialize_table(t)
  local ok, json = pcall(function() return r.NF_SerializeObject and r.NF_SerializeObject(t) end)
  if ok and json then return json end
  -- Fallback: Lua table pretty printer (very simple, keys as strings)
  local parts = {}
  table.insert(parts, "{")
  for k,v in pairs(t) do
    table.insert(parts, string.format("[%q]=%q,", tostring(k), tostring(v)))
  end
  table.insert(parts, "}")
  return table.concat(parts)
end

local function deserialize_table(str)
  if not str or str == "" then return {} end
  local ok, obj = pcall(function()
    if r.NF_DeserializeObject then
      return r.NF_DeserializeObject(str)
    end
    return nil
  end)
  if ok and type(obj) == "table" then return obj end
  return {}
end

local function read_pattern_cfg()
  local function num(key, def)
    local s = ext.get_proj(NS_PATTERN, key, tostring(def))
    local v = tonumber(s)
    if not v then return def end
    return v
  end
  return {
    mode_hint    = ext.get_proj(NS_PATTERN, "MODE_HINT", ""),
    chaos        = num("CHAOS", 0.7),
    density      = num("DENSITY", 0.4),
    cluster_prob = num("CLUSTER_PROB", 0.35),
    euclid_k     = num("EUCLID_K", 3),
    euclid_n     = num("EUCLID_N", 8),
    euclid_rot   = num("EUCLID_ROT", 0),
  }
end

local function write_pattern_cfg(cfg)
  if not cfg then return end
  ext.set_proj(NS_PATTERN, "MODE_HINT", cfg.mode_hint or "")
  ext.set_proj(NS_PATTERN, "CHAOS", tostring(cfg.chaos or 0.7))
  ext.set_proj(NS_PATTERN, "DENSITY", tostring(cfg.density or 0.4))
  ext.set_proj(NS_PATTERN, "CLUSTER_PROB", tostring(cfg.cluster_prob or 0.35))
  ext.set_proj(NS_PATTERN, "EUCLID_K", tostring(cfg.euclid_k or 3))
  ext.set_proj(NS_PATTERN, "EUCLID_N", tostring(cfg.euclid_n or 8))
  ext.set_proj(NS_PATTERN, "EUCLID_ROT", tostring(cfg.euclid_rot or 0))
end

local function ep_num(key, def)
  local s = ext.get_proj(NS_EUCLIDPRO, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function read_euclidpro_cfg()
  local cfg = {
    steps       = ep_num("STEPS", 16),
    hits        = ep_num("HITS", 5),
    rotation    = ep_num("ROTATION", 0),
    accent_mode = ext.get_proj(NS_EUCLIDPRO, "ACCENT_MODE", "none"),
    hit_prob    = ep_num("HIT_PROB", 1.0),
    ghost_prob  = ep_num("GHOST_PROB", 0.0),
  }

  cfg.lanes = {
    {
      pitch      = ep_num("L1_PITCH", 36),
      div        = ep_num("L1_DIV", 1),
      base_vel   = ep_num("L1_BASE_VEL", 96),
      accent_vel = ep_num("L1_ACCENT_VEL", 118),
    },
    {
      pitch      = ep_num("L2_PITCH", 38),
      div        = ep_num("L2_DIV", 1),
      base_vel   = ep_num("L2_BASE_VEL", 90),
      accent_vel = ep_num("L2_ACCENT_VEL", 112),
    },
    {
      pitch      = ep_num("L3_PITCH", 42),
      div        = ep_num("L3_DIV", 1),
      base_vel   = ep_num("L3_BASE_VEL", 84),
      accent_vel = ep_num("L3_ACCENT_VEL", 108),
    },
  }

  return cfg
end

local function write_euclidpro_cfg(cfg)
  if not cfg then return end

  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end
  local function setstr(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end

  setnum("STEPS",       cfg.steps)
  setnum("HITS",        cfg.hits)
  setnum("ROTATION",    cfg.rotation)
  setstr("ACCENT_MODE", cfg.accent_mode or "none")
  setnum("HIT_PROB",    cfg.hit_prob)
  setnum("GHOST_PROB",  cfg.ghost_prob)

  local lanes = cfg.lanes or {}
  local l1 = lanes[1] or {}
  local l2 = lanes[2] or {}
  local l3 = lanes[3] or {}

  setnum("L1_PITCH",       l1.pitch)
  setnum("L1_DIV",         l1.div)
  setnum("L1_BASE_VEL",    l1.base_vel)
  setnum("L1_ACCENT_VEL",  l1.accent_vel)

  setnum("L2_PITCH",       l2.pitch)
  setnum("L2_DIV",         l2.div)
  setnum("L2_BASE_VEL",    l2.base_vel)
  setnum("L2_ACCENT_VEL",  l2.accent_vel)

  setnum("L3_PITCH",       l3.pitch)
  setnum("L3_DIV",         l3.div)
  setnum("L3_BASE_VEL",    l3.base_vel)
  setnum("L3_ACCENT_VEL",  l3.accent_vel)
end


local function get_scene_meta()
  local raw = ext.get_proj(NS_SCENE_META, "LIST", "")
  local meta = deserialize_table(raw)
  if type(meta) ~= "table" then meta = {} end
  return meta
end

local function set_scene_meta(meta)
  local raw = serialize_table(meta or {})
  ext.set_proj(NS_SCENE_META, "LIST", raw)
end

function M.save_scene(slot, opt_name)
  slot = tonumber(slot) or 1
  local ns = get_scene_ns(slot)

  local beat_state   = beatdom   and beatdom.get_state   and beatdom.get_state()   or {}
  local artist_state = artistdom and artistdom.get_artist_state and artistdom.get_artist_state() or {}
  local tuning_state = tuningdom and tuningdom.get_state and tuningdom.get_state() or {}
  local pattern_cfg  = read_pattern_cfg()

  local euclidpro_cfg = read_euclidpro_cfg()
  local sceneevo_cfg  = read_sceneevo_cfg()

  local scene = {
    beat      = beat_state,
    artist    = artist_state,
    tuning    = tuning_state,
    pattern   = pattern_cfg,
    euclidpro = euclidpro_cfg,
    sceneevo  = sceneevo_cfg,
  }

  local payload = serialize_table(scene)
  ext.set_proj(ns, "DATA", payload)

  local meta = get_scene_meta()
  local key = tostring(slot)
  meta[key] = meta[key] or {}
  meta[key].name = opt_name or (meta[key].name or ("Scene " .. key))
  set_scene_meta(meta)

  return true
end

function M.load_scene(slot)
  slot = tonumber(slot) or 1
  local ns = get_scene_ns(slot)
  local payload = ext.get_proj(ns, "DATA", "")
  if payload == "" then return false, "No data for scene " .. tostring(slot) end

  local scene = deserialize_table(payload)
  if type(scene) ~= "table" then
    return false, "Failed to decode scene data"
  end

  if beatdom and beatdom.set_state and type(scene.beat) == "table" then
    beatdom.set_state(scene.beat)
  end
  if artistdom and artistdom.set_state and type(scene.artist) == "table" then
    artistdom.set_state(scene.artist)
  end
  if tuningdom and tuningdom.set_state and type(scene.tuning) == "table" then
    tuningdom.set_state(scene.tuning)
  end
  if type(scene.pattern) == "table" then
    write_pattern_cfg(scene.pattern)
  end
  if type(scene.euclidpro) == "table" then
    write_euclidpro_cfg(scene.euclidpro)
  end

  return true
end


----------------------------------------------------------------
-- Scene Morphing
--   M.morph_scenes(slot_a, slot_b, t)
--   t in [0,1], 0 = Scene A, 1 = Scene B, dazwischen = Interpolation
----------------------------------------------------------------

local function lerp(a, b, t)
  a = tonumber(a) or 0
  b = tonumber(b) or 0
  return a + (b - a) * t
end

local function lerp_int(a, b, t)
  return math.floor(0.5 + lerp(a, b, t))
end

local function mix_bool(a, b, t)
  -- Einfach: bis 0.5 nimm A, danach B
  if t <= 0.5 then return a end
  return b
end

local function mix_string(a, b, t)
  if t <= 0.5 then return a end
  return b
end

local function morph_euclidpro(a, b, t)
  if not a and not b then return nil end
  a = a or {}
  b = b or {}

  local out = {}
  out.steps       = lerp_int(a.steps or 16, b.steps or 16, t)
  out.hits        = lerp_int(a.hits or 4,  b.hits or 4,  t)
  out.rotation    = lerp_int(a.rotation or 0, b.rotation or 0, t)
  out.accent_mode = mix_string(a.accent_mode or "none", b.accent_mode or "none", t)
  out.hit_prob    = lerp(a.hit_prob or 1.0, b.hit_prob or 1.0, t)
  out.ghost_prob  = lerp(a.ghost_prob or 0.0, b.ghost_prob or 0.0, t)

  local la = a.lanes or {}
  local lb = b.lanes or {}
  out.lanes = {}

  for i=1,3 do
    local aa = la[i] or {}
    local bb = lb[i] or {}
    out.lanes[i] = {
      pitch      = lerp_int(aa.pitch or 36,       bb.pitch or 36,       t),
      div        = math.max(1, lerp_int(aa.div or 1,          bb.div or 1,          t)),
      base_vel   = lerp_int(aa.base_vel or 96,    bb.base_vel or 96,    t),
      accent_vel = lerp_int(aa.accent_vel or 118, bb.accent_vel or 118, t),
    }
  end

  return out
end

local function morph_scene_tables(a, b, t)
  a = a or {}
  b = b or {}
  local out = {}

  -- Beat
  out.beat = {
    bpm    = lerp(a.beat and a.beat.bpm or 120,     b.beat and b.beat.bpm or 120,     t),
    ts_num = lerp_int(a.beat and a.beat.ts_num or 4, b.beat and b.beat.ts_num or 4, t),
    ts_den = lerp_int(a.beat and a.beat.ts_den or 4, b.beat and b.beat.ts_den or 4, t),
    bars   = lerp_int(a.beat and a.beat.bars or 4,   b.beat and b.beat.bars or 4,   t),
  }

  -- Artist (Strings / Flags)
  out.artist = {}
  if a.artist or b.artist then
    local aa = a.artist or {}
    local bb = b.artist or {}
    out.artist.name          = mix_string(aa.name,          bb.name,          t)
    out.artist.style_preset  = mix_string(aa.style_preset,  bb.style_preset,  t)
    out.artist.pattern_mode  = mix_string(aa.pattern_mode,  bb.pattern_mode,  t)
    out.artist.use_midi_layers   = mix_bool(aa.use_midi_layers,   bb.use_midi_layers,   t)
    out.artist.use_loop_layers   = mix_bool(aa.use_loop_layers,   bb.use_loop_layers,   t)
    out.artist.use_speech_layers = mix_bool(aa.use_speech_layers, bb.use_speech_layers, t)
    out.artist.use_hybridai      = mix_bool(aa.use_hybridai,      bb.use_hybridai,      t)
  end

  -- Tuning: numerische Felder soweit sinnvoll interpolieren, Rest mischen wie Strings/Bools
  out.tuning = {}
  if a.tuning or b.tuning then
    local ta = a.tuning or {}
    local tb = b.tuning or {}
    out.tuning.enabled     = mix_bool(ta.enabled,     tb.enabled,     t)
    out.tuning.profile     = mix_string(ta.profile,   tb.profile,     t)
    out.tuning.root_note   = lerp_int(ta.root_note or 60, tb.root_note or 60, t)
    out.tuning.transpose   = lerp(ta.transpose or 0,       tb.transpose or 0,       t)
    out.tuning.spread_cents= lerp(ta.spread_cents or 0,    tb.spread_cents or 0,    t)
  end

  -- Pattern: DF95_PATTERN
  out.pattern = {}
  if a.pattern or b.pattern then
    local pa = a.pattern or {}
    local pb = b.pattern or {}
    out.pattern.mode_hint     = mix_string(pa.mode_hint,     pb.mode_hint,     t)
    out.pattern.chaos         = lerp(pa.chaos or 0.0,        pb.chaos or 0.0,        t)
    out.pattern.density       = lerp(pa.density or 0.0,      pb.density or 0.0,      t)
    out.pattern.cluster_prob  = lerp(pa.cluster_prob or 0.0, pb.cluster_prob or 0.0, t)
    out.pattern.euclid_k      = lerp_int(pa.euclid_k or 4,   pb.euclid_k or 4,       t)
    out.pattern.euclid_n      = lerp_int(pa.euclid_n or 16,  pb.euclid_n or 16,      t)
    out.pattern.euclid_rot    = lerp_int(pa.euclid_rot or 0, pb.euclid_rot or 0,     t)
  end

  -- EuclidPro
  out.euclidpro = morph_euclidpro(a.euclidpro, b.euclidpro, t)

  return out
end

function M.morph_scenes(slot_a, slot_b, t)
  slot_a = tonumber(slot_a) or 1
  slot_b = tonumber(slot_b) or 2
  t = tonumber(t) or 0.5
  if t < 0 then t = 0 end
  if t > 1 then t = 1 end

  local ns_a = get_scene_ns(slot_a)
  local ns_b = get_scene_ns(slot_b)

  local payload_a = ext.get_proj(ns_a, "DATA", "")
  local payload_b = ext.get_proj(ns_b, "DATA", "")

  if payload_a == "" or payload_b == "" then
    return false, "One or both scenes are empty."
  end

  local scene_a = deserialize_table(payload_a)
  local scene_b = deserialize_table(payload_b)

  if type(scene_a) ~= "table" or type(scene_b) ~= "table" then
    return false, "Failed to decode one or both scene payloads."
  end

  local mixed = morph_scene_tables(scene_a, scene_b, t)

  -- Schreibe gemorphte States in Domains / ExtStates (ohne neuen Slot anzulegen)
  if beatdom and beatdom.set_state then
    beatdom.set_state(mixed.beat)
  end
  if artistdom and artistdom.set_state and mixed.artist then
    artistdom.set_state(mixed.artist)
  end
  if tuningdom and tuningdom.set_state and mixed.tuning then
    tuningdom.set_state(mixed.tuning)
  end
  if mixed.pattern then
    write_pattern_cfg(mixed.pattern)
  end
  if mixed.euclidpro then
    write_euclidpro_cfg(mixed.euclidpro)
  end
  if mixed.sceneevo then
    write_sceneevo_cfg(mixed.sceneevo)
  end

  return true
end

function M.list_scenes()
  local meta = get_scene_meta()
  local out = {}
  for k,v in pairs(meta) do
    local slot = tonumber(k)
    if slot then
      out[#out+1] = { slot = slot, name = v.name or ("Scene " .. k) }
    end
  end
  table.sort(out, function(a,b) return a.slot < b.slot end)
  return out
end

function M.rename_scene(slot, new_name)
  slot = tonumber(slot) or 1
  local meta = get_scene_meta()
  local key = tostring(slot)
  meta[key] = meta[key] or {}
  meta[key].name = new_name or ("Scene " .. key)
  set_scene_meta(meta)
end

function M.delete_scene(slot)
  slot = tonumber(slot) or 1
  local ns = get_scene_ns(slot)
  ext.del_proj(ns, "DATA")
  local meta = get_scene_meta()
  meta[tostring(slot)] = nil
  set_scene_meta(meta)
end

return M
