-- @description MetaCore VSTi module (auto-extracted)
-- @version 0.0.0
-- @author DF95 + Reaper DAW Ultimate Assistant
-- @noindex

local M = {

------------------------------------------------------------------
-- DF95 ParamMaps integration
-- (optional) tries to load DF95_MetaCore_ParamMaps.lua and expose
-- helper functions on this module.
------------------------------------------------------------------

local DF95_ParamMaps = nil
local ok_pm, pm_mod = pcall(function()
  local resource_path = reaper and reaper.GetResourcePath and reaper.GetResourcePath() or ""
  if resource_path == "" then return nil end
  local pm_path = resource_path .. "/Scripts/IFLS/DF95/core/DF95_MetaCore_ParamMaps.lua"
  local ok_dofile, mod = pcall(dofile, pm_path)
  if not ok_dofile then return nil end
  return mod
end)

if ok_pm and type(pm_mod) == "table" then
  DF95_ParamMaps = pm_mod
end

-- Expose small wrappers on this MetaCore module:
function M.get_param_map_for_fx_name(fx_name)
  if not DF95_ParamMaps then return nil end
  return DF95_ParamMaps.get_by_name(fx_name)
end

function M.get_param_map_for_fx_instance(track, fx_index)
  if not DF95_ParamMaps then return nil end
  return DF95_ParamMaps.get_for_fx(track, fx_index)
end



  ------------------------------------------------------------------
  -- ADSR Sample Manager (ADSR) – Sample-Browser/Trigger-Engine
  ------------------------------------------------------------------
  adsr_sample_manager = {
    id      = "adsr_sample_manager",
    display = "ADSR Sample Manager (ADSR)",
    match   = {"adsr sample manager"},
    vendor  = "ADSR",
    type    = "sample_browser_engine",
    roles   = {"Browser","Sample Trigger","Drums","Loops","One-Shots"},

    sections = {
      "LIBRARY / DATABASE",
      "TAGGING & SEARCH",
      "PLAYBACK / SYNC",
      "MIDI TRIGGER / OUTPUT",
    },

    key_params = {
      library_paths   = "Verzeichnisse, die gescannt und indiziert werden",
      tag_filters     = "Tag-Filter / Kategorien (z.B. Kick, Snare, Pad)",
      bpm_sync        = "Sync zum Host-Tempo für Loops",
      key_match       = "Auto-Tuning / Key Matching",
      gain            = "Output-Gain des Players",
    },
  },

  ------------------------------------------------------------------
  -- Attracktive (Tracktion) – FM/Wavetable-Hybrid (IDM Pads/Leads)
  ------------------------------------------------------------------
  attracktive = {
    id      = "attracktive",
    display = "Attracktive (Tracktion)",
    match   = {"attracktive %(tracktion%)","tracktion attracktive"},
    vendor  = "Tracktion / Dawesome",
    type    = "hybrid_textural",
    roles   = {"Pads","Textures","IDM","Sounddesign"},

    sections = {
      "OSC / SOURCE (Wavetables & Noise)",
      "FILTER / DRIVE",
      "ENVELOPES (Amp/Mod)",
      "LFO / MOD ROUTING",
      "FX (Delay, Reverb, etc.)",
    },

    key_params = {
      osc_mix        = "Mix der Haupt-Oszillator-Layer",
      osc_morph      = "Wavetable-Scroll / Morph",
      filter_cutoff  = "Filter Cutoff / Mode",
      filter_res     = "Filter Resonanz",
      env_amp        = "Amp-Hüllkurve (Attack/Decay/Sustain/Release)",
      lfo_rate       = "Primäre LFO-Geschwindigkeit",
      fx_reverb      = "Reverb-Anteil",
      fx_delay       = "Delay-Anteil",
    },
  },

  ------------------------------------------------------------------
  -- BucketPops – CR-78 Emulation (Full Bucket)
  ------------------------------------------------------------------
  bucketpops = {
    id      = "bucketpops",
    display = "BucketPops (Full Bucket Music) (16 out)",
    match   = {"bucketpops %(full bucket music%)","bucketpops"},
    vendor  = "Full Bucket Music",
    type    = "drum_machine_vintage",
    roles   = {"Drums","Patterns","Vintage","IDM","Electro"},

    sections = {
      "PATTERN SELECT / VARIATION",
      "VOICE MIXER (Kick/Snare/Toms/Cymbals/etc.)",
      "TONE / FILTER je Voice",
      "ACCENT / SWING",
      "MULTI-OUT ROUTING",
    },

    key_params = {
      pattern_select = "Pattern-Nummer/Bank",
      pattern_fill   = "Fill- oder Variation-Trigger",
      voice_levels   = "Lautstärke der Drum-Stimmen",
      tone_controls  = "Grundlegende Klangregler je Stimme (Brightness/Decay)",
      accent_amount  = "Akzentstärke im Pattern",
    },
  },

  ------------------------------------------------------------------
  -- ChowKick – Physical-Model-Kick (chowdsp)
  ------------------------------------------------------------------
  chowkick = {
    id      = "chowkick",
    display = "ChowKick (chowdsp)",
    match   = {"chowkick","chow kick"},
    vendor  = "chowdsp",
    type    = "kick_synth_physical_model",
    roles   = {"Kick","Bass-Drum","IDM","Techno","Sounddesign"},

    sections = {
      "RESONATOR / BODY",
      "CLICK / TRANSIENT",
      "DRIVE / DISTORTION",
      "ENVELOPE (Pitch/Amp)",
      "MIX / OUTPUT",
    },

    key_params = {
      freq_base      = "Grundfrequenz des Resonators (Kick-Pitch)",
      decay_body     = "Decay des Korpus",
      click_level    = "Anteil des Transienten/Click",
      drive_amount   = "Drive/Distortion",
      pitch_env_amt  = "Pitch-Envelope Amount",
      output_gain    = "Output-Gain",
    },
  },

  ------------------------------------------------------------------
  -- Drum Boxx & Drumatic 3 – klassische Drum-Synths
  ------------------------------------------------------------------
  drum_boxx = {
    id      = "drum_boxx_synth_free",
    display = "Drum Boxx Synth Free (SonicXTC)",
    match   = {"drum boxx synth free","drum boxx"},
    vendor  = "SonicXTC",
    type    = "drum_synth_multi",
    roles   = {"Drums","Electro","House","IDM"},

    sections = {
      "VOICE SELECT (Kick/Snare/Toms/Cymbals)",
      "OSC/TONE pro Voice",
      "ENVELOPES (Amp/Pitch)",
      "MIXER",
    },

    key_params = {
      voice_select   = "Aktuelle Drum-Stimme",
      pitch          = "Pitch/Frequenz",
      decay          = "Decay/Länge",
      tone           = "Tone/Brightness",
      pan            = "Panorama der Voice",
      level          = "Lautstärke der Voice",
    },
  },

  drumatic3 = {
    id      = "drumatic3",
    display = "Drumatic 3 (Pieter-Jan Arts) (12 out)",
    match   = {"drumatic 3","drumatic3"},
    vendor  = "Pieter-Jan Arts",
    type    = "drum_synth_analog_style",
    roles   = {"Drums","Electro","Techno","IDM"},

    sections = {
      "VOICE ENGINES (6–8 Drum Engines)",
      "OSC / NOISE pro Voice",
      "FILTER / TONE",
      "AMP ENVELOPE",
      "MULTI-OUT ROUTING",
    },

    key_params = {
      osc_pitch      = "Oszillator-Pitch der gewählten Voice",
      noise_level    = "Noise-Anteil",
      filter_cutoff  = "Filter Cutoff/Tone",
      env_attack     = "Attack der Amp-Hüllkurve",
      env_decay      = "Decay/Release",
      voice_level    = "Lautstärke der Voice",
    },
  },

  ------------------------------------------------------------------
  -- Puremagnetik: Expanse, Leems, Verv – Texturen, LoFi, Tape
  ------------------------------------------------------------------
  expanse = {
    id      = "expanse_puremagnetik",
    display = "Expanse (Puremagnetik)",
    match   = {"expanse %(puremagnetik%)","expanse | texture generator"},
    vendor  = "Puremagnetik",
    type    = "texture_noise_drone",
    roles   = {"Noise","Drone","Texture","Ambient","IDM"},

    sections = {
      "SOURCE NOISE / TEXTURE",
      "PITCH / SHIFT",
      "SPECTRAL BLUR / STASIS",
      "FILTER / SPACE",
      "OUTPUT",
    },

    key_params = {
      filter         = "Filter (Frequenz/Art)",
      stasis         = "Stasis / Spectral Blur – Bewegungsgrad",
      shift          = "Pitch Shift",
      blend          = "Blend verschiedener Texturanteile",
      space          = "Space / Reverb-Anteil",
      size           = "Größe / Tiefenwirkung",
      output_gain    = "Output-Gain",
    },
  },

  leems = {
    id      = "leems_puremagnetik",
    display = "Leems (Puremagnetik)",
    match   = {"leems %(puremagnetik%)","leems | supernatural lo%-fi portal"},
    vendor  = "Puremagnetik",
    type    = "lofi_portal_fx_synth",
    roles   = {"LoFi","Texture","Ambient","Experimental"},

    sections = {
      "INPUT / SAMPLE",
      "LO-FI / DEGRADE",
      "FILTER / TONE",
      "SPACE / REVERB",
      "MIX / OUTPUT",
    },

    key_params = {
      degrade        = "Degrade/LoFi-Intensität",
      tone           = "Tonale Färbung (dunkel/hell)",
      space          = "Reverb/Space",
      mix            = "Dry/Wet",
      output_gain    = "Output",
    },
  },

  verv = {
    id      = "verv_puremagnetik",
    display = "Verv (Puremagnetik)",
    match   = {"verv %(puremagnetik%)","verv | sunbaked tape loop","sunbaked tape loop"},
    vendor  = "Puremagnetik",
    type    = "string_tape_loop",
    roles   = {"Strings","Pads","Tape","LoFi","Ambient"},

    sections = {
      "DUAL OSC / STRING SOURCE",
      "ENVELOPE / SHAPE",
      "TONE / ENSEMBLE",
      "BAKE (Tape Degradation)",
      "OUTPUT",
    },

    key_params = {
      osc_mix        = "Mix zweier String-Oszillatoren",
      env_attack     = "Attack der Amp-Hüllkurve",
      env_release    = "Release",
      tone           = "Tone / Helligkeit",
      ensemble       = "Ensemble / Chorus-Style Modulation",
      bake           = "Bake – Tape-Degradation (Wow/Flutter, Noise, Artefakte)",
      output_gain    = "Output-Gain",
    },
  },

  ------------------------------------------------------------------
  -- MNDALA 2 – MNTRA Engine
  ------------------------------------------------------------------
  mndala2 = {
    id      = "mndala2",
    display = "MNDALA 2 (MNTRA)",
    match   = {"mndala 2 %(mntra%)","mndala2 %(mntra%)"},
    vendor  = "MNTRA",
    type    = "multi_sampler_engine",
    roles   = {"Hybrid","Texture","Acoustic Hybrid","IDM","Cinematic"},

    sections = {
      "LIBRARY / PRESET VIEW",
      "PERFORM VIEW (X/Y/Z RTPC)",
      "MATRIX PAGE (Mod Routing)",
      "SAMPLER PAGE (Layer Samplers + AHDSR)",
      "SEQUENCERS (Arp/Pattern)",
      "GLOBAL FX (Reverb, Delay, etc.)",
      "ANIMOD MODULATION SYSTEM",
      "SETTINGS (Tuning, Sample Paths)",
    },

    key_params = {
      axis_x         = "X-Achse – Makro für zugewiesene Klangparameter",
      axis_y         = "Y-Achse – Makro",
      axis_z         = "Z-Achse – Makro/Expression",
      layer_levels   = "Lautstärken der Sampler-Layer",
      layer_ahdsr    = "AHDSR-Hüllkurven pro Layer",
      seq_rate       = "Sequencer-Rate / Steps",
      global_reverb  = "Global Reverb Amount",
      global_delay   = "Global Delay Amount",
      vib_amount     = "Expressive Vibrato (bis ±2 Halbtöne)",
    },
  },

  ------------------------------------------------------------------
  -- Pendulate – Chaotic Mono-Synth (Newfangled Audio)
  ------------------------------------------------------------------
  pendulate = {
    id      = "pendulate",
    display = "Pendulate (Newfangled Audio)",
    match   = {"pendulate %(newfangled audio%)","pendulate"},
    vendor  = "Newfangled Audio",
    type    = "chaotic_mono_synth",
    roles   = {"Bass","Lead","FX","IDM","Experimental"},

    sections = {
      "DOUBLE-PENDULUM OSCILLATOR",
      "WAVEFOLDER",
      "LOW PASS GATE",
      "MODULATION (Env, LFO, MPE)",
      "GLOBAL (Voices/Pitch/Glide)",
    },

    key_params = {
      chaos_amount   = "Chaos Amount – Stärke des chaotischen Pendelverhaltens",
      osc_shape      = "Übergang Sinus → Chaos",
      wavefold_drive = "Wavefolder Drive",
      wavefold_sym   = "Wavefolder Symmetry",
      lpg_cutoff     = "Low Pass Gate Cutoff",
      lpg_resonance  = "LPG Resonanz",
      env_attack     = "Hüllkurven-Attack",
      env_decay      = "Hüllkurven-Decay",
      lfo_rate       = "LFO Rate",
      glide_time     = "Portamento / Glide",
    },
  },

  ------------------------------------------------------------------
  -- Podolski / Tyrell / ZebraHZ / TripleCheese – u-he Familie
  ------------------------------------------------------------------
  podolski = {
    id      = "podolski",
    display = "Podolski (u-he)",
    match   = {"podolski %(u%-he%)","u%-he podolski"},
    vendor  = "u-he",
    type    = "mono_synth_simple",
    roles   = {"Bass","Lead","Seq","Arp"},

    sections = {
      "OSC / SUB / NOISE",
      "FILTER",
      "AMP ENVELOPE",
      "MOD ENVELOPE / LFO",
      "ARPEGGIATOR",
    },

    key_params = {
      osc_pitch      = "Oszillator-Pitch",
      osc_wave       = "Wellenform / Shape",
      filter_cutoff  = "Filter Cutoff",
      filter_res     = "Resonanz",
      env_amp        = "Amp-Hüllkurve",
      lfo_rate       = "LFO Geschwindigkeit",
      arp_mode       = "Arp-Modus / Richtung",
    },
  },

  triplecheese = {
    id      = "triplecheese",
    display = "TripleCheese (u-he)",
    match   = {"triplecheese %(u%-he%)","triple cheese"},
    vendor  = "u-he",
    type    = "comb_filter_synth",
    roles   = {"Pads","Plucks","Textures","IDM"},

    sections = {
      "3 OSC / MODULE SLOTS (Comb/Noise/etc.)",
      "FILTER / TONE",
      "MOD ENVELOPES",
      "LFOs",
      "FX (Chorus/Delay/Reverb)",
    },

    key_params = {
      module_types   = "Modultypen in den 3 Slots (Comb/Noise/etc.)",
      module_pitch   = "Tonhöhe pro Modul",
      filter_cutoff  = "Filter Cutoff",
      mod_env_amt    = "Mod Envelope Amount",
      lfo_rate       = "LFO Rate",
      fx_mix         = "FX Mix-Level",
    },
  },

  tyrelln6 = {
    id      = "tyrelln6",
    display = "TyrellN6 (u-he)",
    match   = {"tyrelln6 %(u%-he%)","tyrell n6"},
    vendor  = "u-he",
    type    = "va_synth",
    roles   = {"Bass","Lead","Pads","Classic VA"},

    sections = {
      "OSC 1/2 + SUB",
      "MIXER / NOISE",
      "FILTER (VCF)",
      "AMP / FILTER ENVS",
      "LFOs / MOD MATRIX",
      "FX (Chorus/etc.)",
    },

    key_params = {
      osc_wave       = "Wellenform OSC1/2",
      osc_detune     = "Detune / Unison",
      filter_cutoff  = "Cutoff",
      filter_res     = "Resonanz",
      env_filter     = "Filter-Hüllkurve",
      env_amp        = "Amp-Hüllkurve",
      lfo_rate       = "LFO Geschwindigkeiten",
      fx_chorus      = "Chorus-Anteil",
    },
  },

  zebra_hz = {
    id      = "zebra_hz",
    display = "ZebraHZ (u-he)",
    match   = {"zebra hz","zebrahz","zebra2 hz"},
    vendor  = "u-he",
    type    = "modular_synth",
    roles   = {"Complex","Cinematic","IDM","Sounddesign"},

    sections = {
      "OSC / SPECTRAL OSC MODULES",
      "FILTER MODULES",
      "ENVELOPES / MSEG",
      "LFOs / MOD SOURCES",
      "GRID (Modular Routing)",
      "FX (Comp, Delay, Reverb, etc.)",
    },

    key_params = {
      osc_config     = "Oszillator-Konfigurationen im Grid",
      filter_routing = "Routing der Filter im Grid",
      env_mseg       = "MSEG-/Multi-Segment Envelopes",
      lfo_rate       = "LFO Rates",
      fx_chain       = "FX-Kettenkonfiguration",
    },
  },

  ------------------------------------------------------------------
  -- Noise Engineering – Sinc/Virt Vereor
  ------------------------------------------------------------------
  sinc_vereor = {
    id      = "sinc_vereor",
    display = "Sinc Vereor (Noise Engineering)",
    match   = {"sinc vereor","noise engineering sinc"},
    vendor  = "Noise Engineering",
    type    = "hybrid_digital_synth",
    roles   = {"Bass","Lead","IDM","Aggro","Experimental"},

    sections = {
      "ALGORITHM SELECT",
      "PITCH / TONE",
      "ENVELOPES (Amp/Mod)",
      "MODULATION (LFO/Velocity/etc.)",
      "FX (falls angeboten)",
    },

    key_params = {
      algo_select    = "Synth-Algorithmus (verschiedene Engines)",
      pitch          = "Grundton",
      tone           = "Helligkeit/Färbung",
      env_amp        = "Amp-Hüllkurve",
      env_mod        = "Mod-Hüllkurve",
    },
  },

  virt_vereor = {
    id      = "virt_vereor",
    display = "Virt Vereor (Noise Engineering)",
    match   = {"virt vereor","noise engineering virt"},
    vendor  = "Noise Engineering",
    type    = "hybrid_digital_synth",
    roles   = {"Pads","Leads","Experimental"},

    sections = {
      "ALGORITHM SELECT",
      "PITCH / TONE",
      "ENVELOPES",
      "MODULATION",
      "FX",
    },

    key_params = {
      algo_select    = "Algorithmus / Engine",
      pitch          = "Grundton",
      tone           = "Klangfarbe",
      env_amp        = "Amp-Hüllkurve",
      env_mod        = "Mod-Hüllkurve",
    },
  },

  ------------------------------------------------------------------
  -- Vital – Wavetable-Flaggschiff (Vital Audio)
  ------------------------------------------------------------------
  vital = {
    id      = "vital",
    display = "Vital (Vital Audio)",
    match   = {"vital %(vital audio%)","vital vst"},
    vendor  = "Vital Audio",
    type    = "wavetable_synth_modular_mod",
    roles   = {"Everything","Bass","Lead","Pads","FX","IDM"},

    sections = {
      "OSCILLATORS (3x + SAMPLER)",
      "FILTERS (2x)",
      "ENVELOPES (3x)",
      "LFOs (4x + Random)",
      "MOD MATRIX / MACROS",
      "FX RACK (Multiband, Delay, Reverb, Chorus, Distortion, etc.)",
    },

    key_params = {
      osc_wavetables = "Wahl und Position der Wavetables (OSC1–3)",
      osc_unison     = "Unison-Stimmen + Detune",
      filter_cutoff  = "Cutoff der Filter 1/2",
      filter_res     = "Resonanz",
      env1_amp       = "Envelope 1 – Haupt-Amp-Hüllkurve",
      lfo_shapes     = "LFO-Shapes (frei zeichnen, Presets)",
      macro_assign   = "Macro-Zuweisungen auf Zielparameter",
      fx_order       = "Reihenfolge der FX im Rack",
    },
  },

  ------------------------------------------------------------------
  -- bx_oberhausen – SEM-inspirierter VA-Synth (Plugin Alliance)
  ------------------------------------------------------------------
  bx_oberhausen = {
    id      = "bx_oberhausen",
    display = "bx_oberhausen (Plugin Alliance)",
    match   = {"bx_oberhausen","oberhausen %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "va_sem_style",
    roles   = {"Bass","Lead","Poly","Pads","Analog-Style"},

    sections = {
      "OSCILLATORS (2x) + NOISE",
      "MIXER",
      "FILTER (SEM-Style Multimode)",
      "ENVELOPES (Amp/Filter)",
      "UNISON / VOICES",
      "MODULATION (LFO, Mod Wheel, etc.)",
      "FX (FX Rack/Drive/etc.)",
    },

    key_params = {
      osc1_pitch     = "OSC1 Pitch/Range",
      osc2_pitch     = "OSC2 Pitch/Detune",
      osc_shape      = "Wellenformen",
      noise_level    = "Noise-Level",
      filter_mode    = "Filter-Modus (LP/BP/HP/Notch)",
      filter_cutoff  = "Filter Cutoff",
      filter_res     = "Resonanz",
      env_amp        = "Amp-Envelope",
      env_filter     = "Filter-Envelope",
      unison_voices  = "Unison-Stimmen/Detune",
    },
  },

  ------------------------------------------------------------------
  -- gRainbow – Pitch-detecting Granular-Synth
  ------------------------------------------------------------------
  grainbow = {
    id      = "grainbow",
    display = "gRainbow (StrangeLoops)",
    match   = {"grainbow","grainbow %(strangeloops%)","grainbow %(strange loops%)","grainbow %(brady boettcher%)"},
    vendor  = "Strange Loops",
    type    = "granular_pitch_detect",
    roles   = {"Granular","Texture","IDM","Experimental"},

    sections = {
      "INPUT / SAMPLE / BUFFER",
      "PITCH DETECTION / CANDIDATE SELECTION",
      "GRAIN ENGINE (Length/Density/Position)",
      "FILTER / TONE",
      "MODULATION (LFO/Random)",
    },

    key_params = {
      input_mode     = "Live Input oder Sample-File",
      grain_length   = "Grain-Länge",
      grain_density  = "Grain-Dichte",
      position       = "Position im Buffer",
      pitch_quant    = "Pitch-Quantisierung der Grains",
      filter_cutoff  = "Filter Cutoff",
      mix            = "Dry/Wet",
    },
  },

  ------------------------------------------------------------------
  -- Thump One – Kick/Bass/Lead Wavetable-Synth (Toybox)
  ------------------------------------------------------------------
  thump_one = {
    id      = "thump_one",
    display = "Thump One (Toybox)",
    match   = {"thump one","thump one %(toybox%)"},
    vendor  = "Toybox",
    type    = "wavetable_kick_bass",
    roles   = {"Kick","Bass","Lead","IDM","EDM"},

    sections = {
      "KICK ENGINE",
      "LAYER ENGINE",
      "MULTI-SEGMENT ENVELOPES",
      "FILTER / DRIVE",
      "FX (falls aktiv)",
    },

    key_params = {
      kick_env       = "Pitch/Amplitude Envelope der Kick",
      layer_wave     = "Wavetable-Auswahl für Layer",
      layer_env      = "Envelope für Layer-Anteil",
      filter_cutoff  = "Filter Cutoff",
      drive_amount   = "Drive/Distortion",
      mix            = "Kick/Layer-Mix",
    },
  },

  ------------------------------------------------------------------
  -- Tactic – Glitch Machines Step-Sequencer/Shot Player
  ------------------------------------------------------------------
  tactic = {
    id      = "tactic",
    display = "Tactic (Glitchmachines)",
    match   = {"tactic %(glitchmachines%)","glitchmachines tactic"},
    vendor  = "Glitchmachines",
    type    = "step_shot_engine",
    roles   = {"Glitch","IDM","Drums","Loops","Random"},

    sections = {
      "SAMPLE SLOTS / SHOTS",
      "STEP SEQUENCER",
      "TRIGGER MODES / RANDOM",
      "FILTER / FX",
    },

    key_params = {
      slot_assign    = "Zuordnung von Samples zu Slots",
      step_pattern   = "Step-Pattern / Trigger-Matrix",
      random_prob    = "Randomisierung / Probability",
      filter_cutoff  = "Filter Cutoff",
      fx_amount      = "FX-Intensität",
    },
  },

  ------------------------------------------------------------------
  -- Diverse weitere VSTi (Kurzmodelle)
  ------------------------------------------------------------------
  reasamplomatic = {
    id      = "reasamplomatic5000",
    display = "ReaSamplOmatic5000 (Cockos)",
    match   = {"reasamplomatic5000","reasamplomatic"},
    vendor  = "Cockos",
    type    = "sampler_single",
    roles   = {"Drums","One-Shots","Multi-Layer","Utility"},
    sections = {"SAMPLE","AMPLITUDE","PITCH","FILTER","MOD"},
    key_params = {
      sample_path    = "Sample-Datei",
      start_end      = "Start/Ende im Sample",
      pitch          = "Pitch/Transpose",
      vel_zones      = "Velocity-Layer",
    },
  },

  reasynth = {
    id      = "reasynth",
    display = "ReaSynth (Cockos)",
    match   = {"reasynth"},
    vendor  = "Cockos",
    type    = "basic_va",
    roles   = {"Bass","Lead","Test","Utility"},
    sections = {"OSC","FILTER","AMP ENV"},
    key_params = {
      osc_shape      = "Oszillator-Wellenform",
      filter_cutoff  = "Filter Cutoff",
      env_attack     = "Attack",
      env_release    = "Release",
    },
  },

  reasyn_dr = {
    id      = "reasyn_dr",
    display = "ReaSynDr (Cockos) (4 out)",
    match   = {"reasyndr","reasyn dr"},
    vendor  = "Cockos",
    type    = "drum_synth_simple",
    roles   = {"Drums","Test","Utility"},
    sections = {"VOICE PARAMS","MIXER"},
    key_params = {
      pitch          = "Voice Pitch",
      decay          = "Decay",
      level          = "Level",
    },
  },

  sqkone = {
    id      = "sqkone",
    display = "SQKONE (EvilTurtleProductions)",
    match   = {"sqkone"},
    vendor  = "EvilTurtleProductions",
    type    = "va_synth_simple",
    roles   = {"Bass","Lead"},
    sections = {"OSC","FILTER","ENV","LFO"},
    key_params = {
      osc_wave       = "Waveform",
      filter_cutoff  = "Cutoff",
      env_amp        = "Amp Envelope",
    },
  },

  thump_bass_alt = {
    id      = "thump_one_alias",
    display = "Thump One (Toybox) (Alias)",
    match   = {"thump one 2","thump one v2"},
    vendor  = "Toybox",
    type    = "wavetable_kick_bass",
    roles   = {"Kick","Bass"},
    sections = {"KICK","LAYER","ENV"},
    key_params = {},
  },

  unfiltered_battalion = {
    id      = "ua_battalion",
    display = "Unfiltered Audio Battalion (Plugin Alliance) (18 out)",
    match   = {"battalion %(plugin alliance%)","unfiltered audio battalion"},
    vendor  = "Unfiltered Audio",
    type    = "drum_synth_drum_machine",
    roles   = {"Drums","IDM","Glitch","Rhythm Designer"},
    sections = {"VOICE ENGINES","SEQUENCER","MOD MATRIX","FX"},
    key_params = {
      voice_params   = "Parameter je Drum-Engine",
      seq_steps      = "Sequencer-Steps",
    },
  },

  adc_clap = {
    id      = "adc_clap_instrument",
    display = "adc Clap (Audec)",
    match   = {"adc clap","adc_clap !!!vsti"},
    vendor  = "Audec",
    type    = "clap_synth",
    roles   = {"Clap","Percussion","Drums"},
    sections = {"TRANSIENT","BODY","TONE","WIDTH"},
    key_params = {
      attack_shape   = "Transient-Shape",
      decay          = "Decay",
      tone           = "Tone",
      width          = "Stereo Width",
    },
  },

  bong = {
    id      = "bong",
    display = "bong (rurik leffanta) (12 out)",
    match   = {"bong %(rurik leffanta%)","bong 12 out"},
    vendor  = "Rurik Leffanta",
    type    = "drum_synth_multi",
    roles   = {"Drums","IDM","Glitch"},
    sections = {"VOICE PARAMS","MIXER","MULTI-OUT"},
    key_params = {
      voice_pitch    = "Pitch",
      voice_decay    = "Decay",
      voice_timbre   = "Timbre/Tone",
    },
  },

  stoooner = {
    id      = "stoooner",
    display = "stoooner (rurik leffanta)",
    match   = {"stoooner"},
    vendor  = "Rurik Leffanta",
    type    = "drone_fx_instrument",
    roles   = {"Drone","Noise","Experimental"},
    sections = {"OSC/NOISE","FILTER","MOD"},
    key_params = {
      noise_level    = "Noise",
      filter_cutoff  = "Cutoff",
      mod_rate       = "Modulation Rate",
    },
  },

  voltage_modular = {
    id      = "voltage_modular",
    display = "Voltage Modular (Cherry Audio) (4->8ch)",
    match   = {"voltage modular","voltage modular %(cherry audio%)"},
    vendor  = "Cherry Audio",
    type    = "modular_host",
    roles   = {"Modular","FX Host","Instrument Host"},
    sections = {"RACK","MODULES","ROUTING","IO"},
    key_params = {
      patch_state    = "Aktuelle Patch-Konfiguration",
    },
  },


  ------------------------------------------------------------------
  -- Dexed (Digital Suburban) – DX7-FM-Synth
  ------------------------------------------------------------------
  dexed = {
    id      = "dexed",
    display = "Dexed (Digital Suburban)",
    match   = {"dexed %(digital suburban%)", "dexed"},
    vendor  = "Digital Suburban",
    type    = "fm_classic_dx7",
    roles   = {"Bass","Keys","E-Piano","Pads","FX","80s"},

    sections = {
      "GLOBAL (Algorithm, Feedback, Mono/Poly)",
      "LFO (Speed / Delay / Depth / Waveform)",
      "PITCH EG",
      "OP1–OP6 Envelopes",
      "OP1–OP6 Frequency / Detune / Level",
    },

    key_params = {
      algorithm    = "FM-Algorithmus (Routing der 6 Operatoren)",
      feedback     = "Globales Feedback des Operators 6",
      lfo_speed    = "Globale LFO-Geschwindigkeit",
      pitch_eg     = "Tonhöhen-Hüllkurve (Rate/Level 1–4)",
      op_levels    = "Lautstärken der 6 Operatoren",
      op_ratios    = "Coarse/Fine-Frequenzen der Operatoren",
    },
  },

  ------------------------------------------------------------------
  -- TAL-NoiseMaker – VA-Synth mit 3 Oszillatoren
  ------------------------------------------------------------------
  tal_noisemaker = {
    id      = "tal_noisemaker",
    display = "TAL-NoiseMaker (TAL-Togu Audio Line)",
    match   = {"tal%-noisemaker","tal noisemaker"},
    vendor  = "TAL - Togu Audio Line",
    type    = "virtual_analog",
    roles   = {"Bass","Leads","Pads","Arp","Chords","Effects"},

    sections = {
      "OSC SECTION (3 Oszillatoren + Noise/Sub)",
      "FILTER (LP/HP/BP/Notch, Drive)",
      "AMP & FILTER ENVELOPES",
      "LFOs / MODULATION",
      "FX (Chorus, Reverb, Bitcrusher)",
    },

    key_params = {
      osc_mix     = "Lautstärken der 3 Oszillatoren",
      osc_tune    = "Tune/Fine Tune der Hauptoszillatoren",
      filter_type = "Filtertyp (LP/HP/BP/Notch)",
      cutoff      = "Filter-Cutoff",
      resonance   = "Filter-Resonanz",
      amp_env     = "Amp-Hüllkurve (Attack/Decay/Sustain/Release)",
      lfo_rate    = "Haupt-LFO-Rate",
      fx_chorus   = "Chorus-Intensität",
    },
  },

  ------------------------------------------------------------------
  -- Helm (Matt Tytel) – Modulationsmonster
  ------------------------------------------------------------------
  helm = {
    id      = "helm",
    display = "Helm (Matt Tytel)",
    match   = {"helm %(matt tytel%)","helm %(mtytel%)","helm"},
    vendor  = "Matt Tytel",
    type    = "hybrid_va_modular",
    roles   = {"Bass","Leads","Pads","Sequences","FX","IDM"},

    sections = {
      "OSCILLATORS (2x + Sub, Unison, Cross-Mod)",
      "FILTER (Multimode)",
      "ENVELOPES (Amp/Filter + Mod)",
      "LFOs (3x) & Step-Sequencer",
      "MOD MATRIX / ROUTING",
    },

    key_params = {
      osc_mix     = "Mix der beiden Hauptoszillatoren + Sub",
      osc_unison  = "Unisono-Stimmen & Detune",
      filter_cut  = "Filter-Cutoff",
      filter_res  = "Filter-Resonanz",
      amp_env     = "Amp-Hüllkurve",
      mod_matrix  = "Zuordnung der wichtigsten Mod-Ziele",
    },
  },

  ------------------------------------------------------------------
  -- ExaktLite (Sonicbits) – Einsteiger-FM mit 4 Operatoren
  ------------------------------------------------------------------
  exaktlite = {
    id      = "exaktlite",
    display = "ExaktLite (Sonicbits)",
    match   = {"exaktlite","exakt lite"},
    vendor  = "Sonicbits",
    type    = "fm_four_op",
    roles   = {"Keys","Bell","E-Piano","Pads","Digital FX"},

    sections = {
      "OPERATORS 1–4 (Waveform, Ratio, Detune)",
      "OP ENVELOPES (TX-Style 5-Stage)",
      "FM MATRIX / MOD INDEX",
      "GLOBAL (Polyphony, Glide)",
      "CHORUS / OUTPUT",
    },

    key_params = {
      op_waveforms  = "Auswahl der Operator-Wellenformen (inkl. TX)",
      op_ratios     = "Frequenzverhältnisse der Operatoren",
      op_envelopes  = "Amplitude-Hüllkurven (Rate/Level)",
      fm_index      = "FM-Modulationstiefen zwischen den Ops",
      chorus_amount = "Chorus-Intensität",
    },
  },

  ------------------------------------------------------------------
  -- Surge XT – Hybrid/Wavetable-Synth
  ------------------------------------------------------------------
  surge_xt = {
    id      = "surge_xt",
    display = "Surge XT (Surge Synth Team)",
    match   = {"surge xt","surge_xt","surge synth team"},
    vendor  = "Surge Synth Team",
    type    = "hybrid_wavetable",
    roles   = {"Bass","Leads","Pads","Plucks","Sequences","FX","IDM"},

    sections = {
      "GLOBAL (Scenes A/B, Polyphony, FX Chain)",
      "OSCILLATORS pro Szene (Wavetables / Algorithms)",
      "FILTERS & DRIVE",
      "ENVELOPES & LFOs",
      "FX SLOTS (A/B/S Sends)",
    },

    key_params = {
      scene_select   = "Aktive Szene (A/B/Split)",
      osc_type       = "Oszillator-Modi/Wavetables",
      filter_cutoff  = "Filter-Cutoff je Szene",
      filter_res     = "Filter-Resonanz",
      env_amp        = "Amp-Hüllkurve",
      lfo_main       = "Haupt-LFO-Rate",
      fx_send1       = "FX Send 1 Return",
      fx_send2       = "FX Send 2 Return",
    },
  },

  ------------------------------------------------------------------
  -- T-Force Zenith (Mastrcode Music) – JP-8000 Supersaw-Style
  ------------------------------------------------------------------
  t_force_zenith = {
    id      = "t_force_zenith",
    display = "T-Force Zenith (Mastrcode Music)",
    match   = {"t%-force zenith","t force zenith","zenith %(mastrcode%)"},
    vendor  = "Mastrcode Music",
    type    = "supersaw_hybrid",
    roles   = {"Trance Leads","Supersaw","Pads","Plucks","FX"},

    sections = {
      "OSC 1/2 (7-Voice Supersaw + User-Wavetables)",
      "NOISE / FEEDBACK",
      "FILTER (15 Typen) & DRIVE",
      "ENVELOPES (Amp / Filter / Mod)",
      "LFOs & MOD MATRIX",
      "FX (Distortion, Chorus, EQ, Delay, Reverb, Trance Gate)",
    },

    key_params = {
      osc_detune   = "Supersaw-Detune pro Oszillator",
      osc_mix      = "Mix zwischen den beiden Haupt-Oszillatoren",
      filter_type  = "Filtertyp (Ladder, SVF etc.)",
      cutoff       = "Filter-Cutoff",
      env_amp      = "Amp-Hüllkurve",
      env_filter   = "Filter-Hüllkurve",
      trance_gate  = "Trance-Gate-Depth/Pattern",
    },
  },

  ------------------------------------------------------------------
  -- Zyklop (Dawesome) – Re-Synth Textur-Synth
  ------------------------------------------------------------------
  zyklop = {
    id      = "zyklop",
    display = "Zyklop (Dawesome)",
    match   = {"zyklop %(dawesome%)","zyklop"},
    vendor  = "Dawesome",
    type    = "resynthesis_textural",
    roles   = {"Textures","Pads","FX","Bass","IDM","Glitch"},

    sections = {
      "IRIS OSCILLATOR (Re-Synthesis Engine)",
      "LFO CLUSTERS (LFO1–LFO6, Jitter, Soft, Poly/Mono)",
      "MACROS",
      "FILTER / DRIVE",
      "FX (Delay, Reverb, etc.)",
    },

    key_params = {
      iris_position = "Position im Re-Synthesis-Spektrum",
      lfo_rates     = "LFO-Rate/Sync der Haupt-LFOs",
      lfo_jitter    = "Jitter-Menge für organische Modulation",
      filter_cutoff = "Filter-Cutoff",
      macro1        = "Erster Macro-Knob (meist Timbre/Brightness)",
      macro2        = "Zweiter Macro-Knob (Movement/Modulation)",
    },
  },

  ------------------------------------------------------------------
  -- HALion Sonic – Rompler/Workstation
  ------------------------------------------------------------------
  halion_sonic = {
    id      = "halion_sonic",
    display = "HALion Sonic (Steinberg Media Technologies)",
    match   = {"halion sonic","halion_sonic"},
    vendor  = "Steinberg",
    type    = "rompler_workstation",
    roles   = {"Keys","Pianos","Orchestra","Bread&Butter","GM"},

    sections = {
      "PROGRAM SELECT / LAYER",
      "MIXER (Part Vol / Pan / Sends)",
      "FILTER & AMP ENVELOPES (pro Part)",
      "MODULATION (LFO/ModWheel)",
      "FX (Reverb, Delay, Chorus, etc.)",
    },

    key_params = {
      program       = "Ausgewähltes Programm/Layer",
      part_volume   = "Lautstärke der Parts",
      part_pan      = "Panorama je Part",
      sends_fx      = "Send-Level zu Reverb/Delay",
    },
  },
--------------------------------------------------------------------
-- Elsita-V (Digital Systemic Emulations) – Soviet Analog Drum Machine
--------------------------------------------------------------------
elsita_v = {
  id      = "elsita_v",
  display = "Elsita-V (Digital Systemic Emulations)",
  match   = {"Elsita","Elsita%-V"},
  vendor  = "Digital Systemic Emulations",
  type    = "drum_synth",
  roles   = {"Drums","Analog","Vintage","IDM","Experimental"},

  url     = "https://sites.google.com/site/digitalsystemic/home/elsita-v",

  sections = {
    "4 DRUM CHANNELS (A/B/A/B)",
    "OSC/NOISE SELECT PER CHANNEL",
    "FILTER / DECAY / PITCH",
    "MASTER OUTPUT",
  },

  key_params = {
    ch_mode      = "Kanalmodus (Ton/Noise) pro Drum-Channel",
    pitch        = "Tonhöhe bzw. Grundpitch des jeweiligen Kanals",
    decay        = "Abklingzeit / Hüllkurve pro Drum",
    filter_cutoff= "Filter-Cutoff für die Drum-Klänge",
    level        = "Lautstärke der einzelnen Kanäle",
  },
},

--------------------------------------------------------------------
-- Sitala (Decomposer) – 16-Pad Drum Sampler
--------------------------------------------------------------------
sitala = {
  id      = "sitala",
  display = "Sitala (Decomposer)",
  match   = {"Sitala %(Decomposer%)","Sitala","sitala"},
  vendor  = "Decomposer",
  type    = "drum_sampler",
  roles   = {"Drums","OneShots","Slices","IDM","House","Techno"},

  sections = {
    "PADS (16 Slots)",
    "SAMPLE CONTROLS (Shape/Tune/Comp/Tone/Pan)",
    "OUTPUT / MIX",
  },

  key_params = {
    pad_select   = "Aktiver Pad-Slot für Bearbeitung",
    shape        = "Formt Transient/Decay – von glitchy bis smooth",
    tune         = "Tuning über ca. ±24 Halbtöne",
    comp         = "Einfacher Kompressor pro Pad",
    tone         = "Brightness / Tilt-EQ",
    pan          = "Panorama des Pads",
    volume       = "Lautstärke des Pads",
  },
},

--------------------------------------------------------------------
-- ChowKick (chowdsp) – Kick Drum Synth
--------------------------------------------------------------------
chowkick = {
  id      = "chowkick",
  display = "ChowKick (chowdsp)",
  match   = {"ChowKick %(chowdsp%)","ChowKick","chowkick"},
  vendor  = "chowdsp",
  type    = "kick_synth",
  roles   = {"Kick","Drums","Sub","IDM","Electronic"},

  sections = {
    "OSC / DRIVE",
    "PITCH ENVELOPE",
    "CLICK / NOISE",
    "FILTER",
    "OUTPUT",
  },

  key_params = {
    pitch_env    = "Tonhöhenhüllkurve (Punch / Drop der Kick)",
    drive        = "Drive/Saturation der Kick-Schaltung",
    click_level  = "Anteil des Attack-Click",
    tone         = "Helligkeit / Filterung der Kick",
    output_gain  = "Ausgangslevel",
  },
},

--------------------------------------------------------------------
-- Drum Boxx Synth Free – Drum Synth Engine
--------------------------------------------------------------------
drumboxx = {
  id      = "drumboxx",
  display = "Drum Boxx Synth Free (SonicXTC)",
  match   = {"Drum Boxx Synth Free","Drum Boxx","drum boxx"},
  vendor  = "SonicXTC",
  type    = "drum_synth",
  roles   = {"Drums","Electronic","IDM","House","Techno"},

  sections = {
    "DRUM VOICES",
    "PITCH / DECAY",
    "TONE",
    "MIX",
  },
},

--------------------------------------------------------------------
-- Drumatic 3 – Analog Drum Synth
--------------------------------------------------------------------
drumatic3 = {
  id      = "drumatic3",
  display = "Drumatic 3",
  match   = {"Drumatic 3","drumatic 3"},
  vendor  = "E-Phonic / Pieter-Jan Arts",
  type    = "drum_synth",
  roles   = {"Drums","Analog","Electronic","IDM"},
},

--------------------------------------------------------------------
-- Quilcom B-2 CYMBALLIC – Cymbal Drum Synth
--------------------------------------------------------------------
quilcom_b2_cymballic = {
  id      = "quilcom_b2_cymballic",
  display = "Quilcom B-2 CYMBALLIC",
  match   = {"Quilcom B%-2 CYMBALLIC","CYMBALLIC"},
  vendor  = "Quilcom",
  type    = "drum_synth",
  roles   = {"Cymbal","Drums","Percussion","Experimental"},
},

--------------------------------------------------------------------
-- Quilcom B-2 KICK – Kick Drum Synth
--------------------------------------------------------------------
quilcom_b2_kick = {
  id      = "quilcom_b2_kick",
  display = "Quilcom B-2 KICK",
  match   = {"Quilcom B%-2 KICK","B%-2 KICK"},
  vendor  = "Quilcom",
  type    = "kick_synth",
  roles   = {"Kick","Drums","Sub","Electronic"},
},

--------------------------------------------------------------------
-- Quilcom B-2 TOMSNARE – Toms/Snare Synth
--------------------------------------------------------------------
quilcom_b2_tomsnare = {
  id      = "quilcom_b2_tomsnare",
  display = "Quilcom B-2 TOMSNARE",
  match   = {"Quilcom B%-2 TOMSNARE","TOMSNARE"},
  vendor  = "Quilcom",
  type    = "drum_synth",
  roles   = {"Toms","Snare","Drums","Percussion"},
},

--------------------------------------------------------------------
-- Supermatic S-12 – Vintage Drum Machine
--------------------------------------------------------------------
supermatic_s12 = {
  id      = "supermatic_s12",
  display = "Supermatic S12",
  match   = {"Supermatic S12","Supermatic S%-12"},
  vendor  = "MODE MACHINES / Digital Systemic Emulations",
  type    = "drum_machine",
  roles   = {"Drums","Vintage","LoFi","Electronic"},
},

--------------------------------------------------------------------
-- Synsonics-V – Vintage Drum Machine
--------------------------------------------------------------------
synsonics_v = {
  id      = "synsonics_v",
  display = "Synsonics-V",
  match   = {"Synsonics%-V","Synsonics V"},
  vendor  = "MODE MACHINES / Digital Systemic Emulations",
  type    = "drum_machine",
  roles   = {"Drums","Vintage","Electronic"},
},

--------------------------------------------------------------------
-- adc Clap (Audec) – Clap Synth
--------------------------------------------------------------------
adc_clap = {
  id      = "adc_clap",
  display = "adc Clap (Audec)",
  match   = {"adc Clap","adcClap","adc clap"},
  vendor  = "Audec",
  type    = "clap_synth",
  roles   = {"Clap","Drums","Percussion","IDM"},
},

--------------------------------------------------------------------
-- Xsub – Sub / Kick Module
--------------------------------------------------------------------
xsub = {
  id      = "xsub",
  display = "Xsub",
  match   = {"Xsub","xsub"},
  vendor  = "Various",
  type    = "bass_drum",
  roles   = {"Kick","Sub","Bass","808","Trap"},
},

}

return M
