-- @description SynthMetaCore v2.7 (Hardware + Bridges/Routing, inkl. MicroFreak-CV)
-- @version 2.7
-- @author DF95
-- @about
--   SynthMetaCore – Hardware-Fokus:
--     * Super Space Drum
--     * Bontempi MS-40
--     * Yamaha PSS-380
--     * Yamaha PSS-580
--     * Arturia MicroFreak (inkl. detaillierter CV-/Clock-Patchpunkte)
--     * Behringer Neutron (Patchbay)
--     * Behringer Crave   (Patchbay)
--     * Behringer Edge    (Patchbay)
--
--   + Routing-/Bridge-Hilfsfunktionen:
--     * Rollenbasierte Verkabelung (seq_pitch_out -> pitch_cv, clock_out -> clock_in, etc.)
--     * MicroFreak kann so direkt mit Neutron/Edge/Crave „logisch“ gepatcht werden.
--
--   Beispiel:
--     local M = require("IfeelLikeSnow.DF95.DF95_SynthMetaCore_v2_7")
--     local micro = M.find_hardware_synth("MicroFreak")
--     local edge  = M.find_hardware_synth("Edge")
--     local bridges = M.suggest_bridges(micro, edge)
--     reaper.ShowConsoleMsg(M.format_bridges(bridges) .. "\\n")

local SynthMetaCore = {}

------------------------------------------------------------
-- Helper
------------------------------------------------------------

local function lower(s) return (s or ""):lower() end

local function matches_any(name, patterns)
  local n = lower(name or "")
  for _, pat in ipairs(patterns or {}) do
    if n:find(pat) then return true end
  end
  return false
end

------------------------------------------------------------
-- VST Platzhalter
------------------------------------------------------------

SynthMetaCore.vst = {}

------------------------------------------------------------
-- HARDWARE SYNTHS – inkl. Patchbay
------------------------------------------------------------

SynthMetaCore.hardware = {

  ----------------------------------------------------------------
  -- Super Space Drum (Synare-artiger Drum-Synth)
  ----------------------------------------------------------------
  super_space_drum = {
    id      = "super_space_drum",
    display = "Super Space Drum",
    match   = {"super space drum","space drum","synare"},
    type    = "hardware",
    roles   = {"Drum-Synth","Analog","Sci-Fi","IDM"},

    sections = {
      "TRIGGER SECTION",
      "SOUND CORE (Osc + Noise)",
      "FILTER / SWEEP",
      "MODULATION",
      "OUTPUT",
    },

    controls = {
      trigger_pad        = "Trigger Pad / Sensor (Schlagfläche oder externes Trigger-Signal)",
      sensitivity        = "Sensitivity – legt fest, ab welcher Stärke das Trigger-Signal anspricht",
      pitch              = "Pitch / Frequency – Grundton des Drums",
      sweep_start        = "Sweep Start / Tune – Startfrequenz der Tonhöhenhüllkurve",
      sweep_time         = "Sweep Time / Sweep Range – Dauer / Spannweite der Abwärtsbewegung",
      sweep_decay        = "Sweep Decay – Abklingzeit der Tonhöhen- bzw. Filter-Hüllkurve",
      noise_balance      = "Noise / Tone Balance – Mischverhältnis zwischen Rausch- und Tonanteil",
      mod_on             = "Modulation On/Off – schaltet Mod-Sektion zu",
      mod_depth          = "Modulation Depth – Stärke der Modulation auf Pitch/Filter",
      mod_rate           = "Modulation Rate – Geschwindigkeit (LFO-ähnlich)",
      volume             = "Output Level / Volume",
      aux_in             = "Aux/Trigger In – externer Input für Trigger oder Audio-Processing",
    },

    patchbay = {
      { name="Trigger In", dir="in",  role="trig_in"    },
      { name="Audio Out",  dir="out", role="audio_main" },
      { name="Aux In",     dir="in",  role="audio_in"   },
    },
  },

  ----------------------------------------------------------------
  -- Bontempi MS-40
  ----------------------------------------------------------------
  bontempi_ms40 = {
    id      = "bontempi_ms40",
    display = "Bontempi MS-40",
    match   = {"ms%-40","ms 40","bontempi ms"},
    type    = "hardware",
    roles   = {"Home-Keyboard","LoFi","BoC","Organ"},

    sections = {
      "POWER / MASTER",
      "SOUND / TIMBRE",
      "CHORD / ACCOMP",
      "RHYTHM",
      "MODULATION",
      "GLOBAL / TUNING",
    },

    controls = {
      power_switch    = "Power On/Off",
      master_volume   = "Master Volume Slider / Drehregler",
      timbre_select   = "Timbre / Voice Select – wählt Preset-Klänge (Organ, Piano, etc.)",
      chord_buttons   = "Chord Buttons – Einzeltasten für Begleitakkorde (Single Finger)",
      auto_accomp     = "Auto Accompaniment On/Off – schaltet Begleitautomatik",
      rhythm_select   = "Rhythm / Style Select – Auswahl vorgegebener Rhythmen",
      rhythm_start    = "Rhythm Start/Stop – startet/stoppt Rhythmus",
      vibrato         = "Vibrato On/Off",
      sustain         = "Sustain / Hold – verlängert Ausklang",
      tempo           = "Tempo – Geschwindigkeit der Rhythmen",
      tune            = "Pitch / Tune – Gesamtstimmung des Instruments",
      demo            = "Demo / Song – spielt Demo-Pattern/Songs ab",
      phones_out      = "Phones / Line Out (je nach Revision)",
    },

    patchbay = nil,
  },

  ----------------------------------------------------------------
  -- Yamaha PSS-380
  ----------------------------------------------------------------
  yamaha_pss380 = {
    id      = "yamaha_pss380",
    display = "Yamaha PSS-380",
    match   = {"pss%-380","pss 380"},
    type    = "hardware",
    roles   = {"FM/PCM","Home-Keyboard","LoFi","IDM"},

    sections = {
      "POWER / MASTER",
      "VOICE SELECT",
      "STYLE / RHYTHM",
      "AUTO ACCOMPANIMENT",
      "SYNTH PARAMETER (Pseudo-FM/Digital Synth)",
      "TEMPO / TRANSPOSE",
      "SONG MEMORY / DEMO",
      "CONNECTIVITY",
    },

    controls = {
      power_mode       = "POWER/MODE Lever – schaltet Gerät und ggf. Betriebsmodi",
      master_volume    = "Master Volume Slider",
      display          = "LCD Display – zeigt Voice/Style/Parameter-Infos",
      numeric_buttons  = "Numeric Buttons (0–9) – Eingabe von Voice-/Style-/Songnummern",
      voice_button     = "VOICE Button – Voice-Auswahl-Modus",
      style_button     = "STYLE/RHYTHM Button – Style-/Rhythmusmodus",

      rhythm_start     = "Rhythm START/STOP",
      rhythm_synchro   = "Rhythm SYNCHRO START",
      rhythm_fill      = "Rhythm FILL-IN / Variation",
      auto_accomp_on   = "ACCOMP ON/OFF – schaltet Begleitautomatik",
      auto_single      = "SINGLE FINGER Mode",
      auto_fingered    = "FINGERED Mode",

      tempo_up         = "TEMPO UP",
      tempo_down       = "TEMPO DOWN",
      transpose_up     = "TRANSPOSE UP (falls implementiert)",
      transpose_down   = "TRANSPOSE DOWN",

      dual_voice       = "DUAL VOICE ON/OFF – layered Voices",

      synth_on         = "DIGITAL SYNTH On/Off",
      synth_param_1    = "SYNTH Param 1 – z.B. Brilliance/Spectrum",
      synth_param_2    = "SYNTH Param 2 – z.B. Mod/Chorus",
      synth_param_3    = "SYNTH Param 3 – z.B. Attack/Decay",
      synth_param_4    = "SYNTH Param 4 – weitere Timbre-Funktion",

      song_rec         = "SONG MEMORY RECORD",
      song_play        = "SONG MEMORY PLAY",
      song_stop        = "SONG MEMORY STOP/CLEAR",

      demo             = "DEMO – startet interne Demo-Songs",
      phones_out       = "PHONES/OUTPUT – Stereo/Mono-Ausgang",
      dc_in            = "DC IN – Netzteilanschluss",
      midi_out         = "MIDI OUT (falls vorhanden)",
    },

    patchbay = nil,
  },

  ----------------------------------------------------------------
  -- Yamaha PSS-580
  ----------------------------------------------------------------
  yamaha_pss580 = {
    id      = "yamaha_pss580",
    display = "Yamaha PSS-580",
    match   = {"pss%-580","pss 580"},
    type    = "hardware",
    roles   = {"PCM/FM","Home-Keyboard","Accompaniment","LoFi","IDM"},

    sections = {
      "POWER / MASTER",
      "VOICE / STYLE",
      "PARAMETER EDIT (Attack/Release/Brightness...)",
      "EFFECTS (Vibrato/Sustain/Reverb)",
      "AUTO ACCOMPANIMENT / RHYTHM",
      "MELODY / VOLUME",
      "TRANSPOSE / TUNING",
      "PERCUSSION PADS",
      "SONG MEMORY / DEMO",
      "CONNECTIVITY",
    },

    controls = {
      power_switch     = "Power On/Off",
      master_volume    = "Master Volume Slider",
      display          = "LCD Display",
      numeric_buttons  = "Numeric Buttons (0–9)",
      voice_button     = "VOICE Button",
      style_button     = "STYLE / RHYTHM Button",

      melody_volume    = "MELODY VOLUME Slider",

      fx_vibrato       = "VIBRATO On/Off",
      fx_sustain       = "SUSTAIN On/Off",
      fx_reverb        = "REVERB On/Off",

      param_select     = "PARAMETER SELECT – wählt editierbaren Parameter (Attack, Release, Brightness, etc.)",
      param_value_up   = "PARAMETER VALUE +",
      param_value_down = "PARAMETER VALUE -",

      duet_button      = "DUET Button",
      harmony_easy     = "HARMONY / EASY PLAY",

      transpose_up     = "TRANSPOSE +",
      transpose_down   = "TRANSPOSE -",
      tuning_up        = "TUNING +",
      tuning_down      = "TUNING -",

      style_select     = "STYLE/RHYTHM Auswahl",
      rhythm_start     = "Rhythm START/STOP",
      rhythm_synchro   = "Rhythm SYNCHRO START",
      rhythm_intro     = "Rhythm INTRO/ENDING",
      rhythm_fill      = "Rhythm FILL-IN / Variation",
      rhythm_break     = "Rhythm SYNCHRO BREAK",

      tempo_up         = "TEMPO +",
      tempo_down       = "TEMPO -",

      accomp_on        = "ACCOMP ON/OFF",
      single_finger    = "SINGLE FINGER Mode",
      fingered         = "FINGERED Mode",

      percussion_pads  = "Percussion Pads – mehrere Drum-Trigs",

      song_memory      = "SONG MEMORY (Record/Play/Stop – modellabhängig)",
      demo             = "DEMO Button",
      phones           = "PHONES",
      line_out         = "LINE OUT / AUX (je nach Revision)",
      midi_in_out      = "MIDI IN/OUT (modellabhängig)",
    },

    patchbay = nil,
  },

  ----------------------------------------------------------------
  -- Arturia MicroFreak – jetzt inkl. echter CV-/Clock-Patchpunkte
  ----------------------------------------------------------------
  microfreak = {
    id      = "microfreak",
    display = "Arturia MicroFreak",
    match   = {"microfreak"},
    type    = "hardware",
    roles   = {"Hybrid","Digital Osc","Analog Filter","IDM","Experimental","Controller"},

    sections = {
      "OSCILLATOR",
      "FILTER",
      "MAIN ENVELOPE",
      "CYCLING ENVELOPE",
      "LFO",
      "MOD MATRIX",
      "ARP / SEQ",
      "PERFORMANCE (Keyboard, Spice/Dice)",
      "GLOBAL / PRESETS",
      "CV / GATE / PRESSURE / CLOCK I/O",
    },

    controls = {
      osc_type        = "Oscillator TYPE – Algorithmus (Wavetable, Harmonic, Karplus, etc.)",
      osc_wave        = "Oscillator WAVE – Form/Index",
      osc_timbre      = "Oscillator TIMBRE",
      osc_shape       = "Oscillator SHAPE",

      filter_cutoff   = "Filter CUTOFF (Analog VCF)",
      filter_res      = "Filter RESONANCE",

      env_attack      = "Main Envelope ATTACK",
      env_decay       = "Main Envelope DECAY",
      env_sustain     = "Main Envelope SUSTAIN",
      env_release     = "Main Envelope RELEASE",

      cyenv_rate      = "Cycling Envelope RATE",
      cyenv_rise      = "Cycling Envelope RISE/ATTACK (je nach Modus)",
      cyenv_fall      = "Cycling Envelope FALL/DECAY",
      cyenv_shape     = "Cycling Envelope SHAPE/MODE (One-shot, Loop, etc.)",

      lfo_rate        = "LFO RATE",
      lfo_shape       = "LFO WAVE/SHAPE",
      lfo_amount      = "LFO AMOUNT",

      mod_matrix      = "Mod-Matrix Amount-Potis pro Ziel",
      arp_buttons     = "Arpeggiator Mode/On/Off, Oktaven, Divisions",
      seq_controls    = "Sequencer Record/Play, Step Edit",
      spice           = "SPICE – Variation im Pattern",
      dice            = "DICE – Zufällige Variation",
      glide           = "GLIDE",
      octave_buttons  = "OCT -/+",
      touch_keys      = "Kapazitives Keyboard",
      preset_encoder  = "Preset Encoder / Select",
    },

    -- echte, manual-basierte CV/Gate/Clock Punkte, logisch getrennt
    patchbay = {
      -- CV OUTS
      { name="Pitch CV Out",    dir="out", role="pitch_cv"      },
      { name="Gate Out",        dir="out", role="gate_out"      },
      { name="Pressure CV Out", dir="out", role="mod_pressure"  },

      -- CLOCK (eine physische Buchse, logisch getrennt)
      { name="Clock In",        dir="in",  role="clock_in"      },
      { name="Clock Out",       dir="out", role="clock_out"     },

      -- Meta-Audio (für Routing-Ideen)
      { name="Line Out",        dir="out", role="audio_main"    },
    },
  },

  ----------------------------------------------------------------
  -- Behringer Neutron – inkl. Patchbay
  ----------------------------------------------------------------
  neutron = {
    id      = "neutron",
    display = "Behringer Neutron",
    match   = {"neutron"},
    type    = "hardware",
    roles   = {"Analog","Semi-Modular","IDM","Bass","Drone"},

    sections = {
      "OSCILLATORS (2x)",
      "MIXER / NOISE / EXT IN",
      "FILTER",
      "OVERDRIVE",
      "DELAY",
      "ENVELOPES (2x)",
      "LFO",
      "VCA / OUTPUT",
      "PATCHBAY",
    },

    controls = {
      osc1_freq       = "OSC1 Frequency",
      osc1_shape      = "OSC1 Shape",
      osc2_freq       = "OSC2 Frequency",
      osc2_shape      = "OSC2 Shape",
      osc_mix         = "OSC Mix / Blend",
      noise_level     = "Noise Level",
      ext_in_level    = "External Input Level",

      vcf_cutoff      = "VCF Cutoff",
      vcf_res         = "VCF Resonance",
      vcf_mode        = "VCF Mode / Slope",
      vcf_env_amt     = "VCF Envelope Amount",

      od_drive        = "Overdrive Drive",
      od_tone         = "Overdrive Tone",
      od_level        = "Overdrive Level",

      delay_time      = "Delay Time",
      delay_feedback  = "Delay Feedback",
      delay_mix       = "Delay Mix",

      lfo_rate        = "LFO Rate",
      lfo_shape       = "LFO Shape",

      env1_attack     = "Env1 Attack",
      env1_decay      = "Env1 Decay",
      env1_sustain    = "Env1 Sustain",
      env1_release    = "Env1 Release",

      env2_attack     = "Env2 Attack",
      env2_decay      = "Env2 Decay",
      env2_sustain    = "Env2 Sustain",
      env2_release    = "Env2 Release",

      vca_level       = "Main Output Level",
    },

    patchbay = {
      -- Audio Pfad
      { name="OSC1 Out",         dir="out", role="audio_osc1"       },
      { name="OSC2 Out",         dir="out", role="audio_osc2"       },
      { name="Noise Out",        dir="out", role="audio_noise"      },
      { name="Ext In",           dir="in",  role="audio_ext_in"     },
      { name="VCF In",           dir="in",  role="audio_in_filter"  },
      { name="VCF Out",          dir="out", role="audio_out_filter" },
      { name="VCA In",           dir="in",  role="audio_in_vca"     },
      { name="Main Out",         dir="out", role="audio_main"       },

      -- Modulation
      { name="LFO Out",          dir="out", role="mod_lfo"          },
      { name="Env1 Out",         dir="out", role="mod_env1"         },
      { name="Env2 Out",         dir="out", role="mod_env2"         },
      { name="S&H In",           dir="in",  role="mod_snh_in"       },
      { name="S&H Out",          dir="out", role="mod_snh_out"      },

      -- Pitch / Gate / Clock
      { name="Pitch CV In",      dir="in",  role="pitch_cv"         },
      { name="Gate In",          dir="in",  role="gate_in"          },
      { name="Clock In",         dir="in",  role="clock_in"         },
      { name="Clock Out",        dir="out", role="clock_out"        },

      -- Utility
      { name="Attenuator In",    dir="in",  role="util_att_in"      },
      { name="Attenuator Out",   dir="out", role="util_att_out"     },
      { name="Multiple In",      dir="in",  role="util_mult_in"     },
      { name="Multiple Out A",   dir="out", role="util_mult_out_a"  },
      { name="Multiple Out B",   dir="out", role="util_mult_out_b"  },
    },
  },

  ----------------------------------------------------------------
  -- Behringer Crave – inkl. Patchbay
  ----------------------------------------------------------------
  crave = {
    id      = "crave",
    display = "Behringer Crave",
    match   = {"crave"},
    type    = "hardware",
    roles   = {"Analog","Semi-Modular","Acid","Seq","Bass"},

    sections = {
      "OSCILLATOR",
      "MIXER / NOISE / EXT IN",
      "VCF",
      "ENVELOPE",
      "LFO",
      "SEQUENCER",
      "VCA / OUTPUT",
      "PATCHBAY",
    },

    controls = {
      vco_freq        = "VCO Frequency",
      vco_fine        = "VCO Fine Tune",
      vco_wave        = "VCO Waveform / Pulse Width",
      noise_level     = "Noise Level",
      ext_in_level    = "External Input Level",

      vcf_cutoff      = "VCF Cutoff",
      vcf_res         = "VCF Resonance",

      env_attack      = "Env Attack",
      env_decay       = "Env Decay",
      env_sustain     = "Env Sustain",

      lfo_rate        = "LFO Rate",
      glide           = "Glide / Portamento",

      seq_tempo       = "Sequencer Tempo",
      seq_steps       = "Sequencer Steps",
      seq_pattern     = "Sequencer Pattern",
      seq_swing       = "Sequencer Swing",
      seq_play        = "Seq Play/Stop",
      seq_record      = "Seq Record",

      vca_level       = "Output Level",
    },

    patchbay = {
      -- Audio
      { name="VCO Out",          dir="out", role="audio_osc"        },
      { name="Noise Out",        dir="out", role="audio_noise"      },
      { name="VCF In",           dir="in",  role="audio_in_filter"  },
      { name="VCF Out",          dir="out", role="audio_out_filter" },
      { name="VCA In",           dir="in",  role="audio_in_vca"     },
      { name="Audio Out",        dir="out", role="audio_main"       },

      -- Mod
      { name="Env Out",          dir="out", role="mod_env"          },
      { name="LFO Out",          dir="out", role="mod_lfo"          },
      { name="Mod In 1",         dir="in",  role="mod_in_1"         },
      { name="Mod In 2",         dir="in",  role="mod_in_2"         },

      -- CV / Gate / Clock / Seq
      { name="Pitch CV In",      dir="in",  role="pitch_cv"         },
      { name="Gate In",          dir="in",  role="gate_in"          },
      { name="Clock In",         dir="in",  role="clock_in"         },
      { name="Clock Out",        dir="out", role="clock_out"        },

      { name="Seq Pitch Out",    dir="out", role="seq_pitch_out"    },
      { name="Seq Gate Out",     dir="out", role="seq_gate_out"     },
    },
  },

  ----------------------------------------------------------------
  -- Behringer EDGE – inkl. Patchbay
  ----------------------------------------------------------------
  edge = {
    id      = "edge",
    display = "Behringer EDGE",
    match   = {"edge","behringer edge"},
    type    = "hardware",
    roles   = {"Analog","Semi-Modular","Percussion","DFAM-style","IDM","Drum","Seq"},

    sections = {
      "DUAL OSCILLATORS",
      "NOISE / MIX",
      "FILTER",
      "ENVELOPES (AMP/FILTER)",
      "ACCENT / DRIVE",
      "DUAL 8-STEP SEQUENCER",
      "PATCHBAY",
    },

    controls = {
      osc1_freq       = "VCO1 Pitch",
      osc1_wave       = "VCO1 Wave (Tri/Pulse)",
      osc1_fm         = "VCO1 FM Amount",
      osc1_level      = "VCO1 Level",
      osc2_freq       = "VCO2 Pitch",
      osc2_wave       = "VCO2 Wave (Tri/Pulse)",
      osc2_fm         = "VCO2 FM Amount",
      osc2_level      = "VCO2 Level",
      osc_sync_track  = "Sync/Pitch Track Switch (VCO2 zur Sequencer-Pitchführung)",

      noise_level     = "Noise Level",
      ext_in_level    = "External Audio Level",

      vcf_cutoff      = "VCF Cutoff",
      vcf_res         = "VCF Resonance",
      vcf_env_amt     = "VCF Envelope Amount (bipolar)",
      vcf_mod_noise   = "Noise -> VCF Mod Amount",

      amp_env_attack  = "AMP Env Attack",
      amp_env_decay   = "AMP Env Decay",
      amp_env_amount  = "AMP Env Amount",
      fil_env_attack  = "Filter Env Attack",
      fil_env_decay   = "Filter Env Decay",
      fil_env_amount  = "Filter Env Amount",

      accent_amount   = "Accent Amount",
      drive_amount    = "Drive / Saturation Amount",
      main_level      = "Main Output Level",

      seq_step_pA     = "Seq A – Step Pitches (8 Regler)",
      seq_step_pB     = "Seq B – Step Pitches (8 Regler)",
      seq_step_vA     = "Seq A – Step Velocity/Mod (8 Regler)",
      seq_step_vB     = "Seq B – Step Velocity/Mod (8 Regler)",
      seq_tempo       = "Sequencer Tempo",
      seq_scale       = "Sequencer Scale / Note Division",
      seq_swing       = "Sequencer Swing",
      seq_run_stop    = "Sequencer Run/Stop",
      seq_reset       = "Sequencer Reset",
      seq_direction   = "Sequencer Direction/Mode Selector",
      clock_source    = "Clock Source (Internal/External/MIDI/USB, Auswahl via Settings)",
    },

    patchbay = {
      -- Audio
      { name="Mix Out",          dir="out", role="audio_main"       },
      { name="VCO1 Out",         dir="out", role="audio_osc1"       },
      { name="VCO2 Out",         dir="out", role="audio_osc2"       },
      { name="Noise Out",        dir="out", role="audio_noise"      },
      { name="External In",      dir="in",  role="audio_ext_in"     },
      { name="VCF In",           dir="in",  role="audio_in_filter"  },
      { name="VCF Out",          dir="out", role="audio_out_filter" },
      { name="VCA In",           dir="in",  role="audio_in_vca"     },

      -- CV / Mod
      { name="Pitch CV In",      dir="in",  role="pitch_cv"         },
      { name="Velocity In",      dir="in",  role="vel_cv"           },
      { name="Accent In",        dir="in",  role="accent_cv"        },
      { name="Env Out",          dir="out", role="mod_env"          },
      { name="LFO Out",          dir="out", role="mod_lfo"          },

      -- Sequencer / Clock / Trigger
      { name="Clock In",         dir="in",  role="clock_in"         },
      { name="Clock Out",        dir="out", role="clock_out"        },
      { name="Run/Stop In",      dir="in",  role="run_in"           },
      { name="Reset In",         dir="in",  role="reset_in"         },
      { name="Trigger In",       dir="in",  role="trig_in"          },
      { name="Trigger Out",      dir="out", role="trig_out"         },

      { name="Seq Pitch Out",    dir="out", role="seq_pitch_out"    },
      { name="Seq Velocity Out", dir="out", role="seq_vel_out"      },
      { name="Seq Gate Out",     dir="out", role="seq_gate_out"     },

      -- Utility
      { name="Attenuator In",    dir="in",  role="util_att_in"      },
      { name="Attenuator Out",   dir="out", role="util_att_out"     },
      { name="Multiple In",      dir="in",  role="util_mult_in"     },
      { name="Multiple Out A",   dir="out", role="util_mult_out_a"  },
      { name="Multiple Out B",   dir="out", role="util_mult_out_b"  },
    },
  },

}

------------------------------------------------------------
-- Lookup-Funktionen
------------------------------------------------------------

function SynthMetaCore.find_vst_synth(name)
  return nil -- Hardware-only in diesem Modul
end

function SynthMetaCore.find_hardware_synth(name)
  local n = lower(name or "")
  for _, meta in pairs(SynthMetaCore.hardware or {}) do
    if matches_any(n, meta.match or {}) then
      return meta
    end
  end
  return nil
end

------------------------------------------------------------
-- Routing/Bridge-Hilfsfunktionen
------------------------------------------------------------

-- Alle Patchpunkte eines Geräts mit bestimmter Rolle holen
function SynthMetaCore.get_jacks_by_role(device_meta, role, dir_filter)
  local results = {}
  if not (device_meta and device_meta.patchbay) then return results end
  for _, jack in ipairs(device_meta.patchbay) do
    if jack.role == role and (not dir_filter or jack.dir == dir_filter) then
      results[#results+1] = jack
    end
  end
  return results
end

-- Rollen-Mappings für Bridges (Quelle -> mögliche Ziel-Rollen)
local BRIDGE_ROLE_MAP = {
  seq_pitch_out = {"pitch_cv"},
  seq_gate_out  = {"gate_in","trig_in"},
  seq_vel_out   = {"vel_cv","accent_cv"},

  gate_out      = {"gate_in","trig_in"},
  pitch_cv      = {"pitch_cv"},
  mod_pressure  = {"mod_in_1","mod_in_2","util_att_in","vel_cv","accent_cv"},

  clock_out     = {"clock_in"},
  trig_out      = {"trig_in","gate_in"},

  audio_main       = {"audio_in_filter","audio_in_vca","audio_in"},
  audio_out_filter = {"audio_in_vca","audio_in"},
  audio_osc1       = {"audio_in_filter","audio_in_vca"},
  audio_osc2       = {"audio_in_filter","audio_in_vca"},
  audio_noise      = {"audio_in_filter","audio_in_vca"},
}

-- Vorschläge für Bridges zwischen zwei Geräten erzeugen
function SynthMetaCore.suggest_bridges(src_meta, dst_meta)
  local bridges = {}
  if not (src_meta and dst_meta) then return bridges end
  if not (src_meta.patchbay and dst_meta.patchbay) then return bridges end

  -- Ziel-Patchpoints nach Rolle indexieren
  local dst_by_role = {}
  for _, jack in ipairs(dst_meta.patchbay) do
    dst_by_role[jack.role] = dst_by_role[jack.role] or {}
    table.insert(dst_by_role[jack.role], jack)
  end

  for _, sj in ipairs(src_meta.patchbay) do
    if sj.dir == "out" and BRIDGE_ROLE_MAP[sj.role] then
      for _, dst_role in ipairs(BRIDGE_ROLE_MAP[sj.role]) do
        local candidates = dst_by_role[dst_role]
        if candidates then
          for _, dj in ipairs(candidates) do
            table.insert(bridges, {
              from = sj,
              to   = dj,
              from_device = src_meta.display,
              to_device   = dst_meta.display,
              reason      = "role_map:" .. sj.role .. "->" .. dj.role,
            })
          end
        end
      end
    end
  end

  return bridges
end

-- Bridges als Text formatieren
function SynthMetaCore.format_bridges(bridges)
  local lines = {}
  for _, b in ipairs(bridges or {}) do
    lines[#lines+1] = string.format(
      "%s: %s -> %s: %s  (%s)",
      b.from_device or "?",
      b.from and b.from.name or "?",
      b.to_device or "?",
      b.to and b.to.name or "?",
      b.reason or "auto"
    )
  end
  return table.concat(lines, "\n")
end

return SynthMetaCore
