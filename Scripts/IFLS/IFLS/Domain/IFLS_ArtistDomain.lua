-- IFLS_ArtistDomain.lua
-- Extended IFLS Artist Domain
-- ---------------------------------------------
-- Rolle:
--   * Zentrale Verwaltung von Artist-/Style-Informationen
--   * Spiegelung nach:
--        - NS_ARTIST      (projektbezogener Artist-State)
--        - NS_BEAT_CC     (Beat Control Center, Artist-Name)
--   * Preset-System für Artists (lokale Tabelle, leicht editierbar)
--   * Helper, um Artist auf BeatDomain-State anzuwenden
--
-- Abhängigkeiten:
--   Scripts/IFLS/IFLS/Core/IFLS_Contracts.lua
--   Scripts/IFLS/IFLS/Core/IFLS_ExtState.lua
--
-- Optional:
--   Scripts/IFLS/IFLS/Domain/IFLS_BeatDomain.lua
--
-- Du kannst dieses Modul schrittweise ausbauen, ohne DF95-Skripte
-- anzufassen: DF95-Artist-/FX-/Kit-Skripte können weiterhin ihre
-- eigene Logik nutzen, IFLS wird zur gemeinsamen Schicht "oben drüber".

local r = reaper
local core_path = r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Core/"

local ok_contracts, contracts = pcall(dofile, core_path .. "IFLS_Contracts.lua")
local ok_ext,       ext       = pcall(dofile, core_path .. "IFLS_ExtState.lua")

if not ok_contracts or type(contracts) ~= "table" then
  r.ShowConsoleMsg("IFLS_ArtistDomain: Failed to load IFLS_Contracts.lua\n")
  contracts = {
    NS_ARTIST   = "DF95_ARTIST",
    NS_BEAT_CC  = "DF95_BEAT_CC",
    ARTIST_KEYS = {},
    BEAT_CC_KEYS= {},
  }
end

if not ok_ext or type(ext) ~= "table" then
  r.ShowConsoleMsg("IFLS_ArtistDomain: Failed to load IFLS_ExtState.lua\n")
  ext = {
    get_proj = function(_,_,default) return default end,
    set_proj = function() end,
  }
end

local M = {}

----------------------------------------------------------------
-- Imported Artist Catalog (from DF95 Artist Profiles)
----------------------------------------------------------------
ARTIST_CATALOG = {
  { id = "amon_tobin", label = "Amon Tobin" },
  { id = "aphex_twin", label = "Aphex Twin" },
  { id = "apparat", label = "Apparat" },
  { id = "arovane", label = "Arovane" },
  { id = "autechre", label = "Autechre" },
  { id = "ben_frost", label = "Ben Frost" },
  { id = "boards_of_canada", label = "Boards Of Canada" },
  { id = "burial", label = "Burial" },
  { id = "clark", label = "Clark" },
  { id = "flying_lotus", label = "Flying Lotus" },
  { id = "four_tet", label = "Four Tet" },
  { id = "jega", label = "Jega" },
  { id = "matmos", label = "Matmos" },
  { id = "moderat", label = "Moderat" },
  { id = "monoceros", label = "Monoceros" },
  { id = "mouse_on_mars", label = "Mouse On Mars" },
  { id = "mu_ziq", label = "Mu Ziq" },
  { id = "proem", label = "Proem" },
  { id = "squarepusher", label = "Squarepusher" },
  { id = "styrofoam", label = "Styrofoam" },
  { id = "telefon_tel_aviv", label = "Telefon Tel Aviv" },
  { id = "tim_hecker", label = "Tim Hecker" },
  { id = "venetian_snares", label = "Venetian Snares" },
}

----------------------------------------------------------------
-- Artist Meta: Tags + TX16Wx Style Mapping
----------------------------------------------------------------

ARTIST_META = {
  autechre = {
    tags        = { "IDM", "Glitch", "PolyRhythm" },
    humanize    = "IDM_DENSE",
    tx16_style  = "IDM_DENSE",
  },
  aphex_twin = {
    tags        = { "IDM", "Ambient", "Microbeat" },
    humanize    = "IDM_SPARSE",
    tx16_style  = "IDM_SPARSE",
  },
  boards_of_canada = {
    tags        = { "IDM", "LoFi", "Tape", "Wonky" },
    humanize    = "MICROBEAT",
    tx16_style  = "MICROBEAT",
  },
  venetian_snares = {
    tags        = { "Breakcore", "Polymeter", "Glitch" },
    humanize    = "MICROSTUTTER",
    tx16_style  = "MICROSTUTTER",
  },
  burial = {
    tags        = { "LoFi", "ClicksPops", "Ambient" },
    humanize    = "CLICKS_POP",
    tx16_style  = "CLICKS_POP",
  },
  four_tet = {
    tags        = { "Organic", "Microbeat", "HouseHybrid" },
    humanize    = "MICROBEAT",
    tx16_style  = "MICROBEAT",
  },
  flying_lotus = {
    tags        = { "Wonky", "IDM", "HipHop" },
    humanize    = "MICROBEAT",
    tx16_style  = "MICROBEAT",
  },
  squarepusher = {
    tags        = { "IDM", "Bass", "Drums" },
    humanize    = "IDM_DENSE",
    tx16_style  = "IDM_DENSE",
  },
  amon_tobin = {
    tags        = { "Cinematic", "Glitch", "Bass" },
    humanize    = "IDM_DENSE",
    tx16_style  = "IDM",
  },
  tim_hecker = {
    tags        = { "Drone", "Texture", "Noise" },
    humanize    = "MICROSTUTTER",
    tx16_style  = "MICROSTUTTER",
  },
  telefon_tel_aviv = {
    tags        = { "ClicksPops", "IDM", "Ambient" },
    humanize    = "CLICKS_POP",
    tx16_style  = "CLICKS_POP",
  },
}



----------------------------------------------------------------
-- Namespaces & Keys
----------------------------------------------------------------

local ns_art     = contracts.NS_ARTIST   or "DF95_ARTIST"
local ns_beat_cc = contracts.NS_BEAT_CC  or "DF95_BEAT_CC"

local AK   = contracts.ARTIST_KEYS       or {}
local BCCK = contracts.BEAT_CC_KEYS      or {}
local BK   = contracts.BEAT_KEYS         or {}
local SK   = contracts.SAMPLEDB_KEYS     or {}

----------------------------------------------------------------
-- Artist-Presets
--
-- Diese Tabelle kannst du beliebig erweitern / ändern. Sie liefert
-- sinnvolle Standard-Mappings von Artist-Namen auf:
--
--   * style_preset
--   * humanize_depth
--   * microtiming_variant
--   * bpm_min / bpm_max
--   * groove
--   * sampler_mode
--   * sampledb_category
--   * sampledb_filter
--
-- Die Werte sind nur Beispiele, du kannst sie an deinen Workflow
-- anpassen oder komplett ersetzen.
----------------------------------------------------------------


----------------------------------------------------------------
-- EuclidPro Defaults Helper (Artist → EuclidPro ExtState)
----------------------------------------------------------------

local NS_EUCLIDPRO = "IFLS_EUCLIDPRO"

local function apply_euclidpro_defaults_from_preset(preset)
  if not preset or not preset.default_euclidpro or not ext or not ext.set_proj then
    return
  end
  local cfg = preset.default_euclidpro

  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end
  local function setstr(key, v)
    if v ~= nil then ext.set_proj(NS_EUCLIDPRO, key, tostring(v)) end
  end

  -- Core
  setnum("STEPS",       cfg.steps)
  setnum("HITS",        cfg.hits)
  setnum("ROTATION",    cfg.rotation)
  setstr("ACCENT_MODE", cfg.accent_mode or "none")
  setnum("HIT_PROB",    cfg.hit_prob)
  setnum("GHOST_PROB",  cfg.ghost_prob)

  -- Ratchets (optional)
  setnum("RATCHET_PROB", cfg.ratchet_prob)
  setnum("RATCHET_MIN",  cfg.ratchet_min)
  setnum("RATCHET_MAX",  cfg.ratchet_max)
  setstr("RATCHET_SHAPE", cfg.ratchet_shape)

  -- Lanes
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

  -- Falls das Artist-Preset ein EuclidPro-Ratchet-Profil referenziert,
  -- wende es zusätzlich an (überschreibt ggf. Ratchet-Felder).
  if preset.ratchet_profile then
    local rp = preset.ratchet_profile
    local ok_p, prof = pcall(dofile, reaper.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_EuclidProProfiles.lua")
    if ok_p and type(prof) == "table" and prof.apply_profile then
      prof.apply_profile(rp, ext)
    end
  end
end

local ARTIST_PRESETS = {
  -- Beispiel 1: Cinematic Orchestral
  Cinematic_Orch = {
    style_preset       = "Cinematic",
    humanize_depth     = "medium",
    microtiming_variant= "laidback",
    bpm_min            = 70,
    bpm_max            = 110,
    groove             = "cinematic_1",
    sampler_mode       = "TX16WX",
    sampledb_category  = "orchestra",
    sampledb_filter    = "cinematic strings brass perc",
  },

  -- Beispiel 2: LoFi Chill
  LoFi_Chill = {
    style_preset       = "LoFi",
    humanize_depth     = "subtle",
    microtiming_variant= "late",
    bpm_min            = 70,
    bpm_max            = 95,
    groove             = "lofi_swing",
    sampler_mode       = "RS5K",
    sampledb_category  = "lofi",
    sampledb_filter    = "dusty vinyl chill swing",
  },

  -- Beispiel 3: EDM Festival
  EDM_Festival = {
    style_preset       = "EDM",
    humanize_depth     = "tight",
    microtiming_variant= "on_grid",
    bpm_min            = 120,
    bpm_max            = 132,
    groove             = "edm_straight",
    sampler_mode       = "TX16WX",
    sampledb_category  = "edm",
    sampledb_filter    = "festival kick clap lead riser impact",
  },
  -- EuclidPro Artists
  IDM_EuclidPro_Core = {
    style_preset       = "idm_euclidpro",
    humanize_depth     = "medium",
    microtiming_variant= "on_grid",
    bpm_min            = 110,
    bpm_max            = 150,
    groove             = "idm_euclid",
    sampler_mode       = "TX16WX",
    sampledb_category  = "idm",
    sampledb_filter    = "glitch idm granular fx",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "glitch_roll",
    default_euclidpro  = {
      steps        = 16,
      hits         = 5,
      rotation     = 3,
      ratchet_prob = 0.4,
      ratchet_min  = 2,
      ratchet_max  = 4,
      ratchet_shape= "random",
      accent_mode  = "cluster",
      hit_prob     = 0.85,
      ghost_prob   = 0.20,
      lanes = {
        { pitch=36, div=1, base_vel=92, accent_vel=118 },
        { pitch=38, div=1, base_vel=84, accent_vel=110 },
        { pitch=42, div=1, base_vel=78, accent_vel=102 },
      },
    },
  },

  Glitch_EuclidPro_Micro = {
    style_preset       = "glitch_euclidpro",
    humanize_depth     = "high",
    microtiming_variant= "early",
    bpm_min            = 120,
    bpm_max            = 170,
    groove             = "glitch_micro",
    sampler_mode       = "RS5K",
    sampledb_category  = "glitch",
    sampledb_filter    = "glitch microbeat click pop",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "glitch_roll",
    default_euclidpro  = {
      steps        = 12,
      hits         = 4,
      rotation     = 1,
      ratchet_prob = 0.7,
      ratchet_min  = 2,
      ratchet_max  = 6,
      ratchet_shape= "random",
      accent_mode  = "alternate",
      hit_prob     = 0.65,
      ghost_prob   = 0.35,
      lanes = {
        { pitch=36, div=1, base_vel=70, accent_vel=95 },
        { pitch=38, div=2, base_vel=60, accent_vel=90 },
        { pitch=42, div=1, base_vel=55, accent_vel=78 },
      },
    },
  },

  BrokenTechno_EuclidPro = {
    style_preset       = "techno_euclidpro",
    humanize_depth     = "medium",
    microtiming_variant= "on_grid",
    bpm_min            = 124,
    bpm_max            = 136,
    groove             = "broken_techno",
    sampler_mode       = "TX16WX",
    sampledb_category  = "techno",
    sampledb_filter    = "broken techno kick snare hat",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "broken_fill",
    default_euclidpro  = {
      steps        = 16,
      hits         = 3,
      rotation     = 6,
      ratchet_prob = 0.3,
      ratchet_min  = 2,
      ratchet_max  = 3,
      ratchet_shape= "up",
      accent_mode  = "downbeat",
      hit_prob     = 0.95,
      ghost_prob   = 0.10,
      lanes = {
        { pitch=36, div=1, base_vel=110, accent_vel=127 },
        { pitch=38, div=1, base_vel=95,  accent_vel=115 },
        { pitch=42, div=2, base_vel=90,  accent_vel=110 },
      },
    },
  },

  Minimal_EuclidPro = {
    style_preset       = "minimal_euclidpro",
    humanize_depth     = "low",
    microtiming_variant= "on_grid",
    bpm_min            = 118,
    bpm_max            = 130,
    groove             = "minimal_straight",
    sampler_mode       = "TX16WX",
    sampledb_category  = "minimal",
    sampledb_filter    = "minimal techno click hat clap",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "minimal_ticks",
    default_euclidpro  = {
      steps        = 16,
      hits         = 4,
      rotation     = 0,
      ratchet_prob = 0.15,
      ratchet_min  = 2,
      ratchet_max  = 3,
      ratchet_shape= "down",
      accent_mode  = "downbeat",
      hit_prob     = 1.0,
      ghost_prob   = 0.0,
      lanes = {
        { pitch=36, div=1, base_vel=100, accent_vel=120 },
        { pitch=38, div=2, base_vel=85,  accent_vel=110 },
        { pitch=42, div=1, base_vel=70,  accent_vel=95 },
      },
    },
  },

  Experimental_AntiEuclid = {
    style_preset       = "experimental_anti_euclid",
    humanize_depth     = "high",
    microtiming_variant= "free",
    bpm_min            = 60,
    bpm_max            = 110,
    groove             = "experimental_free",
    sampler_mode       = "RS5K",
    sampledb_category  = "experimental",
    sampledb_filter    = "texture noise fx perc",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "broken_fill",
    default_euclidpro  = {
      steps        = 24,
      hits         = 3,
      rotation     = 11,
      accent_mode  = "cluster",
      hit_prob     = 0.55,
      ghost_prob   = 0.45,
      lanes = {
        { pitch=36, div=3, base_vel=60, accent_vel=90 },
        { pitch=38, div=2, base_vel=50, accent_vel=80 },
        { pitch=42, div=1, base_vel=45, accent_vel=70 },
      },
    },
  },

  IDM_HardGlitch_Pro = {
    style_preset       = "breakcore_euclidpro",
    humanize_depth     = "high",
    microtiming_variant= "on_grid",
    bpm_min            = 160,
    bpm_max            = 210,
    groove             = "breakcore_hard",
    sampler_mode       = "RS5K",
    sampledb_category  = "breakcore",
    sampledb_filter    = "breakcore amen glitch",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "snare_rush",
    default_euclidpro  = {
      steps        = 32,
      hits         = 7,
      rotation     = 5,
      ratchet_prob = 0.8,
      ratchet_min  = 3,
      ratchet_max  = 7,
      ratchet_shape= "pingpong",
      accent_mode  = "alternate",
      hit_prob     = 0.75,
      ghost_prob   = 0.35,
      lanes = {
        { pitch=36, div=1, base_vel=90, accent_vel=120 },
        { pitch=38, div=1, base_vel=85, accent_vel=115 },
        { pitch=42, div=1, base_vel=78, accent_vel=105 },
      },
    },
  },

  AmbientPerc_EuclidPro = {
    style_preset       = "ambient_euclidpro",
    humanize_depth     = "medium",
    microtiming_variant= "late",
    bpm_min            = 50,
    bpm_max            = 90,
    groove             = "ambient_perc",
    sampler_mode       = "TX16WX",
    sampledb_category  = "ambient",
    sampledb_filter    = "ambient percussion soft bells",
    pattern_mode       = "EUCLIDPRO",
    ratchet_profile    = "ambient_flutters",
    default_euclidpro  = {
      steps        = 12,
      hits         = 4,
      rotation     = 2,
      accent_mode  = "none",
      hit_prob     = 0.60,
      ghost_prob   = 0.30,
      lanes = {
        { pitch=60, div=2, base_vel=40, accent_vel=55 },
        { pitch=62, div=3, base_vel=35, accent_vel=50 },
        { pitch=64, div=1, base_vel=30, accent_vel=45 },
      },
    },
  },

}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function clamp(v, lo, hi)
  if v == nil then return nil end
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function mid(a, b)
  if not a and not b then return nil end
  if not a then return b end
  if not b then return a end
  return (a + b) * 0.5
end

----------------------------------------------------------------
-- Aktuellen Artist holen / setzen
----------------------------------------------------------------

function M.get_current_artist()
  -- Bevorzugt aus Beat_CC (damit BeatControlCenter im Lead bleibt)
  local from_cc = ext.get_proj(ns_beat_cc, BCCK.ARTIST_PROFILE or "ARTIST_PROFILE", "")
  if from_cc and from_cc ~= "" then
    return from_cc
  end
  -- Fallback: Artist-Namespace
  local from_art = ext.get_proj(ns_art, AK.CURRENT_ARTIST or "CURRENT_ARTIST", "")
  return from_art or ""
end

function M.set_current_artist(name)
  name = name or ""
  ext.set_proj(ns_beat_cc, BCCK.ARTIST_PROFILE or "ARTIST_PROFILE", name)
  ext.set_proj(ns_art,     AK.CURRENT_ARTIST   or "CURRENT_ARTIST", name)
end

----------------------------------------------------------------
-- Artist-State (alles, was ArtistDomain verwaltet)
----------------------------------------------------------------

function M.get_artist_state()
  local st = {}

  st.name        = M.get_current_artist()
  st.style_preset= ext.get_proj(ns_art, AK.STYLE_PRESET        or "STYLE_PRESET",        "")
  st.humanize_depth
                = ext.get_proj(ns_art, AK.HUMANIZE_DEPTH      or "HUMANIZE_DEPTH",      "")
  st.microtiming_variant
                = ext.get_proj(ns_art, AK.MICROTIMING_VARIANT or "MICROTIMING_VARIANT", "")

  -- Optionale Felder, falls du sie use-case-spezifisch speichern willst
  -- (nicht zwingend benötigt, können auch ausschließlich aus Presets kommen)
  st.bpm_min          = tonumber(ext.get_proj(ns_art, "BPM_MIN", "")) or nil
  st.bpm_max          = tonumber(ext.get_proj(ns_art, "BPM_MAX", "")) or nil
  st.groove           = ext.get_proj(ns_art, "GROOVE", "")
  st.sampler_mode     = ext.get_proj(ns_art, "SAMPLER_MODE", "")
  st.sampledb_category= ext.get_proj(ns_art, "SAMPLEDB_CATEGORY", "")
  st.sampledb_filter  = ext.get_proj(ns_art, "SAMPLEDB_FILTER", "")

  return st
end

function M.set_artist_state(st)
  if not st then return end

  if st.name then
    M.set_current_artist(st.name)
  end
  if st.style_preset then
    ext.set_proj(ns_art, AK.STYLE_PRESET or "STYLE_PRESET", st.style_preset)
  end
  if st.humanize_depth then
    ext.set_proj(ns_art, AK.HUMANIZE_DEPTH or "HUMANIZE_DEPTH", st.humanize_depth)
  end
  if st.microtiming_variant then
    ext.set_proj(ns_art, AK.MICROTIMING_VARIANT or "MICROTIMING_VARIANT", st.microtiming_variant)
  end

  if st.bpm_min ~= nil then
    ext.set_proj(ns_art, "BPM_MIN", tostring(st.bpm_min))
  end
  if st.bpm_max ~= nil then
    ext.set_proj(ns_art, "BPM_MAX", tostring(st.bpm_max))
  end
  if st.groove ~= nil then
    ext.set_proj(ns_art, "GROOVE", tostring(st.groove))
  end
  if st.sampler_mode ~= nil then
    ext.set_proj(ns_art, "SAMPLER_MODE", tostring(st.sampler_mode))
  end
  if st.sampledb_category ~= nil then
    ext.set_proj(ns_art, "SAMPLEDB_CATEGORY", tostring(st.sampledb_category))
  end
  if st.sampledb_filter ~= nil then
    ext.set_proj(ns_art, "SAMPLEDB_FILTER", tostring(st.sampledb_filter))
  end
end

----------------------------------------------------------------
-- Presets: Zugriff & Anwendung
----------------------------------------------------------------

function M.list_presets()
  local names = {}
  for k in pairs(ARTIST_PRESETS) do
    names[#names+1] = k
  end
  table.sort(names)
  return names
end

function M.get_preset(name)
  if not name or name == "" then return nil end
  return ARTIST_PRESETS[name]
end

function M.apply_preset_to_artist(preset_name, artist_state)
  local preset = M.get_preset(preset_name)
  if not preset then return artist_state end

  artist_state = artist_state or M.get_artist_state()
  artist_state.name                 = artist_state.name or preset_name
  artist_state.style_preset         = artist_state.style_preset         or preset.style_preset
  artist_state.humanize_depth       = artist_state.humanize_depth       or preset.humanize_depth
  artist_state.microtiming_variant  = artist_state.microtiming_variant  or preset.microtiming_variant
  artist_state.bpm_min              = artist_state.bpm_min              or preset.bpm_min
  artist_state.bpm_max              = artist_state.bpm_max              or preset.bpm_max
  artist_state.groove               = artist_state.groove               or preset.groove
  artist_state.sampler_mode         = artist_state.sampler_mode         or preset.sampler_mode
  artist_state.sampledb_category    = artist_state.sampledb_category    or preset.sampledb_category
  artist_state.sampledb_filter      = artist_state.sampledb_filter      or preset.sampledb_filter

  -- EuclidPro Defaults (falls vorhanden)
  apply_euclidpro_defaults_from_preset(preset)

  return artist_state
end

----------------------------------------------------------------
-- Artist → Beat anwenden
--
-- Signatur:
--   apply_artist_to_beat(artist_name, beat_state) -> beat_state
--
-- Wenn artist_name nil/"" ist, wird:
--   * current artist aus ExtState geholt
--   * falls ein Preset gleichen Namens existiert, wird es verwendet
--
-- Beat-State-Felder, die angepasst werden können:
--   * bpm (nur wenn sinnvoll, siehe Code)
--   * groove
--   * sampler_mode
--   * humanize_mode (Beat_CC)
--   * sampledb_category / sampledb_filter (Beat_CC)
--
-- Wichtig:
--   Diese Funktion verändert NICHT direkt ExtState. Das geschieht
--   in der Regel durch IFLS_BeatDomain.set_state().
----------------------------------------------------------------

function M.apply_artist_to_beat(artist_name, beat_state)
  beat_state = beat_state or {}

  local bs = beat_state
  local a_name = artist_name
  if not a_name or a_name == "" then
    a_name = M.get_current_artist()
  end

  -- Artist-State + Preset kombinieren
  local a_state = M.get_artist_state()
  if a_name and a_name ~= "" then
    a_state.name = a_name
  end

  local preset = M.get_preset(a_state.name)
  if preset then
    a_state = M.apply_preset_to_artist(a_state.name, a_state)
  end

  -- BPM anpassen, falls Preset-Bereich sinnvoll
  local bpm_min = a_state.bpm_min or (preset and preset.bpm_min) or nil
  local bpm_max = a_state.bpm_max or (preset and preset.bpm_max) or nil
  local bpm     = bs.bpm

  if bpm_min and bpm_max then
    -- Wenn aktuelles bpm außerhalb liegt oder nil, auf Midpoint setzen
    if not bpm or bpm < bpm_min or bpm > bpm_max then
      bpm = mid(bpm_min, bpm_max)
    end
    bpm = clamp(bpm, bpm_min, bpm_max)
    bs.bpm = bpm
  end

  -- Groove / Sampler-Mode
  if a_state.groove and a_state.groove ~= "" then
    bs.groove = a_state.groove
  end
  if a_state.sampler_mode and a_state.sampler_mode ~= "" then
    bs.sampler_mode = a_state.sampler_mode
  end

  -- Humanize-Mode in Beat-Control-Center-Keys spiegeln
  if a_state.humanize_depth and a_state.humanize_depth ~= "" then
    bs.humanize_mode = a_state.humanize_depth
  end

  -- SampleDB-Integration (über Beat_CC-Felder, wenn BeatDomain diese nutzt)
  if a_state.sampledb_category and a_state.sampledb_category ~= "" then
    bs.sampledb_category = a_state.sampledb_category
  end
  if a_state.sampledb_filter and a_state.sampledb_filter ~= "" then
    bs.sampledb_filter = a_state.sampledb_filter
  end

  -- Artist-Name auch im Beat-State für UIs
  bs.artist_profile = a_state.name or bs.artist_profile

  return bs
end



----------------------------------------------------------------
-- Humanize-Preset Mapping (Artist -> IFLS_Humanize preset_id)
----------------------------------------------------------------

-- einfache Default-Regeln:
--   * Cinematic_Orch    -> STRAIGHT
--   * LoFi_Chill        -> MICROBEAT (leicht)
--   * EDM_Festival      -> STRAIGHT
--   * Glitch_IDM        -> IDM_DENSE
--   * Glitch_ClicksPops -> CLICKS_POP
--   * Experimental_AntiEuclid -> MICROSTUTTER
--   * alles andere      -> STRAIGHT

function M.get_humanize_preset_for_artist(artist_id)
  artist_id = tostring(artist_id or "") or ""

  -- 1) Exakte Zuordnung über ARTIST_META (falls vorhanden)
  if type(ARTIST_META) == "table" then
    local meta = ARTIST_META[artist_id]
    if meta and meta.humanize then
      return meta.humanize
    end
  end

  -- 2) Fallback-Regeln für generische Namen / Profile
  if artist_id == "Cinematic_Orch" then
    return "STRAIGHT"
  elseif artist_id == "LoFi_Chill" then
    return "MICROBEAT"
  elseif artist_id == "EDM_Festival" then
    return "STRAIGHT"
  elseif artist_id:match("Glitch_IDM") or artist_id:match("IDM") then
    return "IDM_DENSE"
  elseif artist_id:match("Clicks") or artist_id:match("ClicksPops") then
    return "CLICKS_POP"
  elseif artist_id:match("AntiEuclid") or artist_id:match("Experimental") then
    return "MICROSTUTTER"
  else
    return "STRAIGHT"
  end
end




----------------------------------------------------------------
-- TX16Wx Style Mapping per Artist
----------------------------------------------------------------

function M.get_tx16_style_for_artist(artist_id)
  artist_id = tostring(artist_id or "") or ""
  if type(ARTIST_META) == "table" then
    local meta = ARTIST_META[artist_id]
    if meta and meta.tx16_style then
      return meta.tx16_style
    end
  end

  -- Fallback: gleiche ID wie Humanize-Preset verwenden
  local h = M.get_humanize_preset_for_artist(artist_id)
  if h and h ~= "" then return h end
  return "STRAIGHT"
end

----------------------------------------------------------------
-- Artist Catalog Helpers
----------------------------------------------------------------

function M.list_artists()
  -- Gibt eine Liste von { id, label } zurück (DF95-Kernkünstler)
  local out = {}
  if type(ARTIST_CATALOG) ~= "table" then return out end
  for i, a in ipairs(ARTIST_CATALOG) do
    out[#out+1] = { id = a.id, label = a.label }
  end
  table.sort(out, function(a,b) return a.label:lower() < b.label:lower() end)
  return out
end

function M.get_label_for_artist(id)
  id = tostring(id or "")
  if type(ARTIST_CATALOG) ~= "table" then return id end
  for _, a in ipairs(ARTIST_CATALOG) do
    if a.id == id then return a.label end
  end
  return id
end

end

return M
