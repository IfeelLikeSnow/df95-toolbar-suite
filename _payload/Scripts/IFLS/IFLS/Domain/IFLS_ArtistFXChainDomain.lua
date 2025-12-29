-- IFLS_ArtistFXChainDomain.lua
-- Artist/Style FX chain builder using installed plugins
-- Generated based on DF95_AllFX_ParamDump_FULL-1 and ArtistMeta.

local r = reaper
local M = {}

local ok_contracts, contracts = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Core/IFLS_Contracts.lua")
local ok_ext, ext           = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Core/IFLS_ExtState.lua")
local ok_idm_flavors, IDM_FLAVORS = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_IDMFlavorProfiles.lua")

local ok_idm_flavors, IDM_FLAVORS = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_IDMFlavorProfiles.lua")

----------------------------------------------------------------
-- Pools: curated candidate FX per Rolle
----------------------------------------------------------------

M.glitch_fx_pool = {
  "JS: Avocado Ducking Glitch Generator",
  "VST3: Convex (Glitchmachines)",
  "VST3: Cryogen (Glitchmachines)",
  "VST3: Fracture (Glitchmachines)",
  "VST3: Hysteresis (Glitchmachines)",
  "VST3: Quadrant (Glitchmachines)",
  "VST3: Subvert2 (Glitchmachines)",
  "VST: Buffer Override (Destroy FX)",
  "VST: Geometer (Destroy FX)",
  "VST: dblue Glitch v1.3 (x86) (dblue)",
}

M.tape_lofi_fx_pool = {
  "VST3: CHOWTapeModel (chowdsp)",
  "VST3: Tape Cassette 2 (Caelum Audio)",
  "VST3: Vinyl (iZotope)",
  "VST: FromTape (airwindows)",
  "VST: Tape (airwindows)",
  "VST: TapeDust (airwindows)",
  "VST: ToTape5 (airwindows)",
  "VST: ToTape6 (airwindows)",
  "VST: ToTape7 (airwindows)",
  "VST: ToTape8 (airwindows)",
  "VST: ToVinyl4 (airwindows)",
}

M.distortion_fx_pool = {
  "JS: Distortion",
  "JS: Distortion (Fuzz)",
  "VST: FinalClip (airwindows)",
  "VST: FreeClip (Venn Audio)",
  "VST: MultiBandDistortion (airwindows)",
}

M.modulation_fx_pool = {
  "JS: 4-Tap Phaser",
  "JS: Chorus",
  "JS: Chorus (Improved Shaping)",
  "JS: Chorus (Stereo)",
  "JS: Flanger",
  "JS: Tremolo",
  "VST3: ValhallaSpaceModulator (Valhalla DSP, LLC)",
}

M.special_reverb_fx_pool = {
  "VST3: LatticeReverb (Uhhyou)",
  "VST3: PSP PianoVerb (PSPaudioware.com)",
  "VST3: Spaced Out (BABY Audio)",
  "VST3: ValhallaSupermassive (Valhalla DSP, LLC)",
}


-- optional: merge additional FX from DF95 PluginMeta (IDM groups)
local ok_bridge, bridge = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_PluginMetaBridgeDomain.lua")
if ok_bridge and bridge and bridge.is_available and bridge.is_available() then
  local function extend_pool_from_group(pool, group, max_add)
    max_add = max_add or 8
    local meta_list = bridge.get_by_group(group) or {}
    local seen = {}
    for _, fxname in ipairs(pool) do
      seen[fxname] = true
    end
    local added = 0
    for _, meta in ipairs(meta_list) do
      if meta.name and not seen[meta.name] then
        pool[#pool+1] = meta.name
        seen[meta.name] = true
        added = added + 1
        if added >= max_add then break end
      end
    end
  end

  extend_pool_from_group(M.glitch_fx_pool,      "IDM_GLITCH", 12)
  extend_pool_from_group(M.tape_lofi_fx_pool,   "IDM_GLITCH", 8)
  extend_pool_from_group(M.distortion_fx_pool,  "IDM_BUSS",   8)
  extend_pool_from_group(M.modulation_fx_pool,  "IDM_STEREO", 8)
  extend_pool_from_group(M.special_reverb_fx_pool, "IDM_SPACE", 8)
end

----------------------------------------------------------------
-- Helper: pick first or simple pseudo-random by index
----------------------------------------------------------------

local function pick(list, seed)
  if not list or #list == 0 then return nil end
  if not seed or seed <= 0 then return list[1] end
  local idx = (seed % #list) + 1
  return list[idx]
end

----------------------------------------------------------------
----------------------------------------------------------------
-- Phase 76: IDM-aware chain profiles using PluginMetaBridge
-- 
-- New API:
--   * M.IDM_CHAIN_PROFILES
--   * M.build_chain_for_idm_profile(profile_id, seed, opts)
--
-- Diese Funktionen bauen FX-Chains direkt auf Basis der IDM-Gruppen aus
-- DF95_PluginMetaDomain (via IFLS_PluginMetaBridgeDomain).
----------------------------------------------------------------

-- vordefinierte Profile für typische IFLS-Szenarien
M.IDM_CHAIN_PROFILES = {
  -- Klassischer IDM/Glitch-Drumbus
  idm_drum_glitch = {
    description      = "IDM/Glitch-Drum-Bus: Buss-Kompressor + Sättigung + EQ, FX-Bus mit Glitch/Texture/Delay, Ambient mit Space/Texture.",
    drum_bus_groups  = { "IDM_BUSS", "IDM_GLITCH", "IDM_TONE" },
    fx_bus_groups    = { "IDM_GLITCH", "IDM_TEXTURE", "IDM_ECHO" },
    ambient_groups   = { "IDM_SPACE", "IDM_TEXTURE" },
    drum_bus_slots   = 3,
    fx_bus_slots     = 3,
    ambient_slots    = 2,
  },

  -- Clean, eher organischer Beat mit viel Raum
  idm_drum_clean_space = {
    description      = "Clean-Beat mit Fokus auf Buss-Kompression und edlen Reverbs.",
    drum_bus_groups  = { "IDM_BUSS", "IDM_TONE" },
    fx_bus_groups    = { "IDM_TONE", "IDM_ECHO" },
    ambient_groups   = { "IDM_SPACE" },
    drum_bus_slots   = 2,
    fx_bus_slots     = 2,
    ambient_slots    = 2,
  },

  -- Melodische IDM / Ambient
  idm_melody_space = {
    description      = "Melodische IDM-/Ambient-Chains: warme Sättigung, Stereo-Modulation, lange Reverbs.",
    drum_bus_groups  = { "IDM_TONE", "IDM_GLITCH" },
    fx_bus_groups    = { "IDM_STEREO", "IDM_ECHO" },
    ambient_groups   = { "IDM_SPACE", "IDM_TEXTURE" },
    drum_bus_slots   = 2,
    fx_bus_slots     = 3,
    ambient_slots    = 3,
  },

  -- Dichte Textur- / Drone-Szene
  idm_ambient_texture = {
    description      = "Dichte Textur-/Drone-Szene: Texture-FX + Space + Stereo.",
    drum_bus_groups  = { "IDM_TEXTURE", "IDM_TONE" },
    fx_bus_groups    = { "IDM_TEXTURE", "IDM_ECHO" },
    ambient_groups   = { "IDM_SPACE", "IDM_STEREO", "IDM_TEXTURE" },
    drum_bus_slots   = 2,
    fx_bus_slots     = 3,
    ambient_slots    = 3,
  },
}

-- interne Helper-Funktion zum Ziehen von FX aus IDM-Gruppen
-- optional mit Flavor-Profil (Phase 84)
local function _idm_add_from_groups(chain_bus, groups, slots, seed_offset, bridge, flavor_profile)
  if not groups or #groups == 0 or slots <= 0 then return end
  if not bridge or not bridge.is_available or not bridge.is_available() then return end

  -- Flavor-Profil aus IFLS_IDMFlavorProfiles
  local include_flavors = nil
  local exclude_flavors = nil
  local prefer_flavors  = nil

  if flavor_profile and type(flavor_profile) == "table" then
    include_flavors = flavor_profile.include
    exclude_flavors = flavor_profile.exclude
    prefer_flavors  = flavor_profile.prefer
  end

  -- Baue ggf. gefilterte Kandidatenlisten pro IDM-Gruppe
  local group_candidates = {}

  local function meta_matches_flavors(meta)
    if not meta or not meta.name then return false end
    if not include_flavors or #include_flavors == 0 then
      -- keine Includes: alles erlaubt, außer explizite Excludes
      if not exclude_flavors or #exclude_flavors == 0 then
        return true
      end
    end
    local tags = bridge.get_flavors_for_plugin and bridge.get_flavors_for_plugin(meta.name) or {}
    local present = {}
    for _, t in ipairs(tags) do present[t] = true end

    if include_flavors and #include_flavors > 0 then
      local ok = false
      for _, f in ipairs(include_flavors) do
        if present[f] then ok = true break end
      end
      if not ok then return false end
    end

    if exclude_flavors and #exclude_flavors > 0 then
      for _, f in ipairs(exclude_flavors) do
        if present[f] then return false end
      end
    end
    return true
  end

  if bridge.get_by_group and (include_flavors or exclude_flavors) then
    for _, g in ipairs(groups) do
      local list = bridge.get_by_group(g) or {}
      local filtered = {}
      for _, meta in ipairs(list) do
        if meta_matches_flavors(meta) then
          filtered[#filtered+1] = meta
        end
      end
      group_candidates[g] = filtered
    end
  end

  local used = {}

  local function pick_from_group(g, idx)
    local cand = group_candidates[g]
    if cand and #cand > 0 then
      -- Versuche, bevorzugte Flavors zu ziehen
      if prefer_flavors and bridge.get_flavors_for_plugin then
        for _, meta in ipairs(cand) do
          if not used[meta.name] then
            local tags = bridge.get_flavors_for_plugin(meta.name) or {}
            local present = {}
            for _, t in ipairs(tags) do present[t] = true end
            local ok = false
            for _, pf in ipairs(prefer_flavors) do
              if present[pf] then ok = true break end
            end
            if ok then
              return meta.name
            end
          end
        end
      end
      -- ansonsten einfach erstes nicht genutztes FX nehmen
      for _, meta in ipairs(cand) do
        if not used[meta.name] then
          return meta.name
        end
      end
    end

    -- Fallback: klassisches pick_name_from_group
    if bridge.pick_name_from_group then
      return bridge.pick_name_from_group(g, (seed_offset or 0) + idx)
    end
    return nil
  end

  for i = 1, slots do
    local g = groups[((i - 1) % #groups) + 1]
    local fxname = pick_from_group(g, i)
    if fxname and not used[fxname] then
      chain_bus[#chain_bus+1] = { { fx_name = fxname, role = g } }
      used[fxname] = true
    end
  end
end

-- Baue Chain für ein IDM-Profil (ohne Artist-spezifische Tags)
function M.build_chain_for_idm_profile(profile_id, seed, opts)
  seed = seed or 1
  opts = opts or {}

  local profile = M.IDM_CHAIN_PROFILES[profile_id]
  if not profile then
    return nil, "Unknown IDM chain profile: " .. tostring(profile_id)
  end

  -- Profil-Vorgabe:
  local flavor_profile = nil
  local flavor_id = profile.flavor_id

  -- ExtState-Override aus IFLS Artist Hub
  if ok_ext and ok_contracts and ext and contracts then
    local ns_art = contracts.NS_ARTIST or "DF95_ARTIST"
    local AK = contracts.ARTIST_KEYS or {}
    local FLAVOR_KEY = AK.IDM_FLAVOR_PROFILE or "IDM_FLAVOR_PROFILE"
    local override_id = ext.get_proj(ns_art, FLAVOR_KEY, "")
    if override_id and override_id ~= "" then
      flavor_id = override_id
    end
  end

  if ok_idm_flavors and IDM_FLAVORS and flavor_id then
    flavor_profile = IDM_FLAVORS[flavor_id]
  end

  local bridge = nil
  local ok_bridge, b = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_PluginMetaBridgeDomain.lua")
  if ok_bridge and b and b.is_available and b.is_available() then
    bridge = b
  end

  local chain = {
    drum_bus    = {},
    fx_bus      = {},
    ambient_bus = {},
  }

  _idm_add_from_groups(chain.drum_bus,    profile.drum_bus_groups or {},    profile.drum_bus_slots or 0,   seed + 10,   bridge, flavor_profile)
  _idm_add_from_groups(chain.fx_bus,      profile.fx_bus_groups   or {},    profile.fx_bus_slots   or 0,   seed + 100,  bridge, flavor_profile)
  _idm_add_from_groups(chain.ambient_bus, profile.ambient_groups  or {},    profile.ambient_slots  or 0,   seed + 1000, bridge, flavor_profile)

  local function ensure_min(bus, pool, min_slots, role_label)
    if not pool or #pool == 0 then return end
    if #bus >= min_slots then return end
    for i = #bus+1, min_slots do
      local fxname = pool[((i - 1) % #pool) + 1]
      bus[#bus+1] = { { fx_name = fxname, role = role_label } }
    end
  end

  ensure_min(chain.drum_bus,    M.distortion_fx_pool,     1, "idm_drum_saturation")
  ensure_min(chain.fx_bus,      M.glitch_fx_pool,         1, "idm_fx_glitch")
  ensure_min(chain.ambient_bus, M.special_reverb_fx_pool, 1, "idm_ambient_space")

  return chain
end

----------------------------------------------------------------
-- Build FX chain spec for a given artist + role
----------------------------------------------------------------

--
-- Rückgabe: Tabelle mit Feldern:
--   drum_bus = {{ fx_name=..., role=... }, ... }
--   fx_bus   = {{...}, ...}
--   ambient_bus = {{...}, ...}
--
-- Diese Funktion nutzt:
--   * IFLS_ArtistDomain (ARTIST_META.tags)
--   * IFLS_ReverbEQDomain (für Reverb + EQ Vorschläge)
----------------------------------------------------------------

function M.build_chain_for_artist(artist_id, artist_domain, rev_eq_domain)
  artist_id     = tostring(artist_id or "")
  artist_domain = artist_domain or {}
  rev_eq_domain = rev_eq_domain or {}

  local tags = nil
  local meta = nil

  if artist_domain and type(artist_domain) == "table" then
    if artist_domain.ARTIST_META and artist_domain.ARTIST_META[artist_id] then
      meta = artist_domain.ARTIST_META[artist_id]
      tags = meta.tags
    end
  end

  if not tags or #tags == 0 then
    tags = {}
  end

  -- Baseline: Reverb + EQ aus ReverbEQDomain
  local chain_rev = nil
  if rev_eq_domain.build_chain_for_artist then
    chain_rev = rev_eq_domain.build_chain_for_artist(artist_id, artist_domain)
  end
  local rv_spec = chain_rev and chain_rev[1] and chain_rev[1].reverb or nil
  local eq_spec = chain_rev and chain_rev[1] and chain_rev[1].eq     or nil

  local function has_tag(t)
    t = tostring(t or ""):lower()
    for _, tag in ipairs(tags) do
      if tostring(tag or ""):lower() == t then
        return true
      end
    end
    return false
  end

  ----------------------------------------------------------------
  -- Rollen-Logik:
  --   * IDM / Glitch-lastig  -> starker Glitch-Bus, Tape optional
  --   * LoFi / Tape / Wonky  -> Tape + Charakter-Reverb
  --   * Drone / Ambient      -> SpecialReverb (Supermassive/Lattice) + Tape leicht
  --   * ClicksPops           -> Minimal Drum-Room, leichte Distortion/Transient
  ----------------------------------------------------------------

  local seed = 0
  for i = 1, #artist_id do
    seed = seed + string.byte(artist_id, i)
  end

  local drum_bus    = {}
  local fx_bus      = {}
  local ambient_bus = {}

  -- DRUM BUS
  if has_tag("Glitch") or has_tag("IDM") then
    local g = pick(M.glitch_fx_pool, seed)
    if g then
      drum_bus[#drum_bus+1] = {{ fx_name = g, role = "glitch" }}
    end
    local d = pick(M.distortion_fx_pool, seed+1)
    if d then
      drum_bus[#drum_bus+1] = {{ fx_name = d, role = "clip" }}
    end
  end

  if has_tag("ClicksPops") or has_tag("Microbeat") then
    local t = pick(M.tape_lofi_fx_pool, seed+2)
    if t then
      drum_bus[#drum_bus+1] = {{ fx_name = t, role = "lofi_color" }}
    end
  end

  if rv_spec and rv_spec.name then
    drum_bus[#drum_bus+1] = {{ fx_name = rv_spec.name, role = "drum_space" }}
  end

  -- FX BUS (Glitch/Ambient)
  if has_tag("Glitch") or has_tag("Experimental") or has_tag("IDM") then
    local g2 = pick(M.glitch_fx_pool, seed+3)
    if g2 then
      fx_bus[#fx_bus+1] = {{ fx_name = g2, role = "glitch_fx" }}
    end
  end

  local mod = pick(M.modulation_fx_pool, seed+4)
  if mod then
    fx_bus[#fx_bus+1] = {{ fx_name = mod, role = "modulation" }}
  end

  -- AMBIENT BUS (Pads / Drones / Atmos)
  if has_tag("Ambient") or has_tag("Drone") or has_tag("LoFi") then
    local srev = pick(M.special_reverb_fx_pool, seed+5)
    if srev then
      ambient_bus[#ambient_bus+1] = {{ fx_name = srev, role = "ambient_space" }}
    end
    local tape = pick(M.tape_lofi_fx_pool, seed+6)
    if tape then
      ambient_bus[#ambient_bus+1] = {{ fx_name = tape, role = "tape_color" }}
    end
  end

  if eq_spec and eq_spec.name then
    ambient_bus[#ambient_bus+1] = {{ fx_name = eq_spec.name, role = "ambient_eq" }}
  end

  return {{
    drum_bus    = drum_bus,
    fx_bus      = fx_bus,
    ambient_bus = ambient_bus,
  }}
end

----------------------------------------------------------------
-- RFXChain Export (optional helper)
----------------------------------------------------------------

function M.save_rfxchain(chain_spec, filepath)
  if not chain_spec or type(chain_spec) ~= "table" then return false end
  if not filepath or filepath == "" then return false end

  local function write_bus(f, bus_name, bus)
    f:write("// " .. bus_name .. "\n")
    for _, slot in ipairs(bus or {{}}) do
      local fx = slot[1]
      if fx and fx.fx_name then
        f:write("BYPASS 0 0 0\n")
        f:write("VST \"" .. fx.fx_name .. "\"\n")
      end
    end
    f:write("\n")
  end

  local ok, err = pcall(function()
    local f = assert(io.open(filepath, "w"))
    local cs = chain_spec[1] or chain_spec

    write_bus(f, "DRUM_BUS", cs.drum_bus)
    write_bus(f, "FX_BUS", cs.fx_bus)
    write_bus(f, "AMBIENT_BUS", cs.ambient_bus)

    f:close()
  end)

  return ok
end

return M