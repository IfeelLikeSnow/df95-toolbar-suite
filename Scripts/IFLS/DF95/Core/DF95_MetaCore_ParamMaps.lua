-- DF95_MetaCore_ParamMaps.lua
-- Auto-generated helper from "Parameter dump synths.txt"
-- This module exposes per-synth parameter index maps for DF95 / MetaCore.

local M = {}

----------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------

-- Get param map directly by REAPER FX name string
function M.get_by_name(fx_name)
  return M[fx_name]
end

-- Convenience helper: resolve by track/fx index at runtime
function M.get_for_fx(track, fx_index)
  if not reaper or not track or fx_index == nil then return nil end
  local _, name = reaper.TrackFX_GetFXName(track, fx_index, "")
  return M[name]
end

----------------------------------------------------------------------
-- VITAL (Vital Audio)
-- From: "Parameter Dump for FX: VST3i: Vital (Vital Audio)"
-- Key musical controls only (amp env, main filter, macros, bypass)
----------------------------------------------------------------------

M["VST3i: Vital (Vital Audio)"] = {
  kind = "poly_synth",
  amp_env = {           -- Envelope 1 (main amp env)
    attack  = 48,       -- Envelope 1 Attack
    decay   = 50,       -- Envelope 1 Decay
    sustain = 54,       -- Envelope 1 Sustain
    release = 52,       -- Envelope 1 Release
  },
  filter1 = {
    cutoff    = 104,    -- Filter 1 Cutoff
    resonance = 115,    -- Filter 1 Resonance
  },
  macros = {
    [1] = 118,          -- Macro 1
    [2] = 119,          -- Macro 2
    [3] = 120,          -- Macro 3
    [4] = 121,          -- Macro 4
  },
  bypass = 140,         -- Bypass Vital
}

----------------------------------------------------------------------
-- SURGE XT (Surge Synth Team)
-- From: "Parameter Dump for FX: VST3i: Surge XT (Surge Synth Team) (2->6ch)"
-- We expose: global volume, Scene A main filter, Scene A amp/filter EGs, macros.
----------------------------------------------------------------------

M["VST3i: Surge XT (Surge Synth Team) (2->6ch)"] = {
  kind = "hybrid_synth",
  global = {
    volume       = 12,   -- Global Volume
    active_scene = 13,   -- Active Scene (A/B)
  },
  macros = {
    [1] = 0,             -- M1
    [2] = 1,             -- M2
    [3] = 2,             -- M3
    [4] = 3,             -- M4
    [5] = 4,             -- M5
    [6] = 5,             -- M6
    [7] = 6,             -- M7
    [8] = 7,             -- M8
  },
  sceneA = {
    -- Osc volumes
    osc1_volume = 292,   -- A Osc 1 Volume
    osc2_volume = 296,   -- A Osc 2 Volume
    osc3_volume = 300,   -- A Osc 3 Volume

    -- Filters
    filter1 = {
      cutoff    = 319,   -- A Filter 1 Cutoff
      resonance = 320,   -- A Filter 1 Resonance
    },
    filter2 = {
      cutoff    = 325,   -- A Filter 2 Cutoff
      resonance = 326,   -- A Filter 2 Resonance
    },

    -- Amp EG
    amp_env = {
      attack  = 329,     -- A Amp EG Attack
      decay   = 331,     -- A Amp EG Decay
      sustain = 333,     -- A Amp EG Sustain
      release = 334,     -- A Amp EG Release
    },

    -- Filter EG
    filter_env = {
      attack  = 337,     -- A Filter EG Attack
      decay   = 339,     -- A Filter EG Decay
      sustain = 341,     -- A Filter EG Sustain
      release = 342,     -- A Filter EG Release
    },
  },

  bypass = 774,          -- Bypass Surge XT
}

----------------------------------------------------------------------
-- VIRT VEREOR (Noise Engineering)
-- From: "Parameter Dump for FX: VST3i: Virt Vereor (Noise Engineering)"
----------------------------------------------------------------------

M["VST3i: Virt Vereor (Noise Engineering)"] = {
  kind = "poly_synth",
  amp_env = {
    attack  = 14,       -- Attack
    decay   = 15,       -- Decay
    sustain = 16,       -- Sustain
    release = 17,       -- Release
  },
  volume = 19,          -- Volume

  filter = {
    mix       = 20,     -- Filter Mix
    resonance = 21,     -- Resonance
    env_amt   = 22,     -- Env Amount
    cutoff    = 23,     -- Cutoff
    type      = 25,     -- Filter Type
  },
}

----------------------------------------------------------------------
-- REASYNTH (Cockos)
-- From: "Parameter Dump for FX: VSTi: ReaSynth (Cockos)"
----------------------------------------------------------------------

M["VSTi: ReaSynth (Cockos)"] = {
  kind = "simple_synth",
  amp_env = {
    attack  = 0,        -- Attack
    release = 1,        -- Release
    decay   = 6,        -- Decay
    sustain = 9,        -- Sustain
  },
  osc_mix = {
    square   = 2,       -- Square mix
    saw      = 3,       -- Saw mix
    triangle = 4,       -- Triangle mix
    extra_sine_mix   = 7,
    extra_sine_tune  = 8,
  },
  volume = 5,           -- Volume
}

----------------------------------------------------------------------
-- SQKONE (EvilTurtleProductions)
-- From: "Parameter Dump for FX: VSTi: SQKONE (EvilTurtleProductions)"
----------------------------------------------------------------------

M["VSTi: SQKONE (EvilTurtleProductions)"] = {
  kind = "fm_synth",
  op1_env = {
    attack  = 3,        -- OP1 Attack
    decay   = 4,
    sustain = 5,
    release = 6,
  },
  op2_env = {
    attack  = 11,       -- OP2 Attack
    decay   = 12,
    sustain = 13,
    release = 14,
  },
  filter = {
    cutoff    = 16,     -- Filter Cutoff
    resonance = 17,     -- Filter Resonance
    feedback  = 18,     -- Filter Feedback
  },
  ar_env = {
    attack  = 19,       -- AR Env Attack
    release = 20,
    depth   = 21,
  },
  master_volume = 28,   -- Master Volume
}

----------------------------------------------------------------------
-- TYRELLN6 (u-he)
-- From: "Parameter Dump for FX: VSTi: TyrellN6 (u-he)"
----------------------------------------------------------------------

M["VSTi: TyrellN6 (u-he)"] = {
  kind = "analog_synth",
  env1 = {
    attack  = 18,       -- ENV1 Attack
    decay   = 19,
    sustain = 20,
    release = 22,
  },
  env2 = {
    attack  = 26,       -- ENV2 Attack
    decay   = 27,
    sustain = 28,
    release = 30,
  },
  osc = {
    vol1      = 54,     -- Tyrell: OscVolume1
    vol2      = 55,     -- Tyrell: OscVolume2
    sub_vol   = 56,     -- Tyrell: SubVolume
    noise_vol = 57,     -- Tyrell: NoiseVolume
  },
  filter = {
    cutoff    = 62,     -- Tyrell: Cutoff
    resonance = 68,     -- Tyrell: Resonance
    mode      = 60,     -- Tyrell: VCFMode
    poles     = 61,     -- Tyrell: VCFPoles
  },
}

----------------------------------------------------------------------
-- TRIPLECHEESE (u-he)
-- From: "Parameter Dump for FX: VSTi: TripleCheese (u-he)"
----------------------------------------------------------------------

M["VSTi: TripleCheese (u-he)"] = {
  kind = "physical_model_synth",
  env1 = {
    attack  = 13,       -- ENV1 Attack
    decay   = 14,
    sustain = 15,
    release = 17,
  },
  env2 = {
    attack  = 19,       -- ENV2 Attack
    decay   = 20,
    sustain = 21,
    release = 23,
  },
  cso = {
    cso1_volume = 32,   -- CSO1: Volume
    cso2_volume = 45,   -- CSO2: Volume
  },
}

----------------------------------------------------------------------
-- ATTRACKTIVE (Tracktion)
-- From: "Parameter Dump for FX: VST3i: Attracktive (Tracktion)"
----------------------------------------------------------------------

M["VST3i: Attracktive (Tracktion)"] = {
  kind = "macro_synth",
  amp_env = {
    attack  = 4,
    decay   = 5,
    sustain = 6,
    release = 7,
  },
  filter = {
    cutoff    = 8,
    resonance = 9,
    hp        = 21,
  },
  osc_mix = {
    osc1 = 2,
    osc2 = 3,
  },
  fx = {
    reverb       = 10,
    delay        = 11,
    distortion   = 12,
    distortion_g = 13,
  },
  master_volume = 37,
}

----------------------------------------------------------------------
-- PODOLSKI (u-he)
-- From: "Parameter Dump for FX: VSTi: Podolski (u-he)"
----------------------------------------------------------------------

M["VSTi: Podolski (u-he)"] = {
  kind = "analog_synth",
  env1 = {
    attack  = 27,       -- ENV1 Attack
    decay   = 28,
    sustain = 29,
    release = 31,
  },
  filter = {
    cutoff    = 47,     -- VCF0 Cutoff
    resonance = 48,     -- VCF0 Resonance
    drive     = 49,     -- VCF0 Drive
  },
  amp = {
    volume = 58,        -- VCA1: Volume
    pan    = 57,        -- VCA1: Pan
  },
}

----------------------------------------------------------------------
-- ZYKLOP (Dawesome) — only high‑level hook for now
-- From: "Parameter Dump for FX: VST3i: Zyklop (Dawesome)"
-- (The engine is complex; we mainly flag it as "drum_synth" for MetaCore.)
----------------------------------------------------------------------

M["VST3i: Zyklop (Dawesome)"] = {
  kind = "drum_synth",
  -- Detailed per-voice mappings can be added later as needed.
}

----------------------------------------------------------------------
-- DRUM BOXX / DRUMATIC / OTHER DRUM MACHINES
-- For now we just tag them as "drum_synth" so MetaCore can route roles.
----------------------------------------------------------------------

M["VSTi: Drum Boxx Synth Free (x86) (SonicXTC)"] = {
  kind = "drum_synth",
}

M["VSTi: Drumatic 3 (x86) (Pieter-Jan Arts) (12 out)"] = {
  kind = "drum_synth",
}

----------------------------------------------------------------------
-- FALLBACK
----------------------------------------------------------------------

return M
