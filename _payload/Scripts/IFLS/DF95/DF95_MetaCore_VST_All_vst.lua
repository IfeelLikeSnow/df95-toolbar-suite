-- @description MetaCore VST module (auto-extracted)
-- @version 0.0.0
-- @author DF95 + Reaper DAW Ultimate Assistant
-- @noindex

local M = {
  --------------------------------------------------------------------
  -- TAL-NoiseMaker – VA-Synth mit vielen Presets, gut für IDM-Bässe
  --------------------------------------------------------------------
  tal_noisemaker = {
    id      = "tal_noisemaker",
    display = "TAL-NoiseMaker",
    match   = {"tal%-noisemaker","tal noisemaker","tal%-Noisemaker"},
    vendor  = "TAL-Togu Audio Line",
    type    = "va_synth",
    roles   = {"Bass","Lead","Pad","Pluck","IDM"},

    sections = {
      "OSCILLATORS (3x inkl. SUB)",
      "MIXER / NOISE",
      "FILTER (LP/HP/BP)",
      "ENVELOPES (AMP/FILTER)",
      "LFOs",
      "FX (Chorus, Delay, Reverb)",
    },

    key_params = {
      osc_wave       = "Wellenformen der Oszillatoren",
      osc_detune     = "Detune/Unison",
      filter_cutoff  = "Filter Cutoff",
      filter_res     = "Resonanz",
      env_amp        = "Amp-Hüllkurve",
      env_filter     = "Filter-Hüllkurve",
      lfo_rate       = "LFO-Geschwindigkeiten",
      fx_chorus      = "Chorus-Anteil",
      fx_delay       = "Delay-Anteil",
    },
  },

  --------------------------------------------------------------------
  -- u-he Triple Cheese – Comb-Filter-Synth für weirde Texturen
  --------------------------------------------------------------------
  uhe_triplecheese = {
    id      = "uhe_triplecheese",
    display = "u-he Triple Cheese",
    match   = {"triplecheese %(u%-he%)","triple cheese %(u%-he%)"},
    vendor  = "u-he",
    type    = "comb_filter_synth",
    roles   = {"Pads","Plucks","Textures","IDM","Ambient"},

    sections = {
      "3 MODULE SLOTS (Comb, Noise, etc.)",
      "ENVELOPES",
      "LFOs",
      "FX (Chorus, Delay, Reverb)",
    },

    key_params = {
      module_types   = "Modultyp-Pro-Slot (Comb/Noise/etc.)",
      module_pitch   = "Pitch je Modul",
      env_amp        = "Amp-Hüllkurve",
      lfo_rate       = "LFO-Rate",
      fx_mix         = "FX-Mix-Level",
    },
  },

  --------------------------------------------------------------------
  -- Surge XT Effects – Multi-FX-Teil von Surge XT
  --------------------------------------------------------------------
  surge_xt_fx = {
    id      = "surge_xt_fx",
    display = "Surge XT Effects",
    match   = {"surge xt effects","surge xt fx"},
    vendor  = "Surge Synth Team",
    type    = "multi_fx_modular",
    roles   = {"Filter","Drive","Delay","Reverb","Modulation","IDM"},

    sections = {
      "FX BLOCKS (Filter, Distortion, Delay, Reverb, etc.)",
      "ROUTING / ORDER",
      "MOD SOURCES (LFO, Env, Random)",
    },

    key_params = {
      block_types    = "Aktive FX-Blöcke und deren Typen",
      block_order    = "Reihenfolge der Blöcke",
      filter_cutoff  = "Cutoff in Filter-Blöcken",
      drive_amount   = "Drive/Sättigung",
      delay_time     = "Delay-Zeiten",
      reverb_mix     = "Reverb-Mix",
    },
  },

  --------------------------------------------------------------------
  -- TDR Nova – Dynamic EQ
  --------------------------------------------------------------------
  tdr_nova = {
    id      = "tdr_nova",
    display = "TDR Nova",
    match   = {"tdr nova","tokyo dawn labs nova"},
    vendor  = "Tokyo Dawn Labs",
    type    = "dynamic_eq",
    roles   = {"EQ","Dynamic-EQ","Master","Bus","Surgical"},

    sections = {
      "STATIC BANDS (Bell/Shelf)",
      "DYNAMIC SECTION (Threshold, Ratio, etc.)",
      "WIDE BAND COMP",
      "OUTPUT / GAIN MATCH",
    },

    key_params = {
      band_freqs     = "Frequenzen der EQ-Bänder",
      band_gain      = "Gain der EQ-Bänder",
      band_q         = "Q-Faktoren",
      dyn_threshold  = "Dyn-Threshold pro Band",
      dyn_ratio      = "Dyn-Ratio pro Band",
      output_gain    = "Ausgangslevel",
    },
  },

  --------------------------------------------------------------------
  -- TDR Kotelnikov – Mastering-Kompressor
  --------------------------------------------------------------------
  tdr_kotelnikov = {
    id      = "tdr_kotelnikov",
    display = "TDR Kotelnikov",
    match   = {"tdr kotelnikov","tokyo dawn labs kotelnikov"},
    vendor  = "Tokyo Dawn Labs",
    type    = "compressor_mastering",
    roles   = {"Compressor","Master","Bus","Clean"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE (Peak/RMS)",
      "SIDECHAIN FILTER",
      "DELTA / OUTPUT",
    },

    key_params = {
      threshold      = "Threshold",
      ratio          = "Ratio",
      attack         = "Attack (Peak/RMS)",
      release        = "Release (Peak/RMS)",
      sc_hpf         = "Sidechain-Highpass",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- BABY Audio Smooth Operator – Spectral Kompressor/EQ
  --------------------------------------------------------------------
  smooth_operator = {
    id      = "smooth_operator",
    display = "BABY Audio Smooth Operator",
    match   = {"smooth operator %(baby audio%)","baby audio smooth operator"},
    vendor  = "BABY Audio",
    type    = "spectral_shaper",
    roles   = {"De-Esser","Tonal Balance","Master","Bus","Vocals"},

    sections = {
      "SPECTRAL CURVE (4 Nodes)",
      "SENSITIVITY / FOCUS",
      "TIME (RESPONSE)",
      "MIX / OUTPUT",
    },

    key_params = {
      node_freqs     = "Knoten-Frequenzen der Kurve",
      node_gain      = "Knoten-Gain/Depth",
      sensitivity    = "Gesamt-Sensitivität der Spektralbearbeitung",
      focus          = "Fokus auf bestimmten Frequenzbereich",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- BABY Audio Spaced Out – Delay+Reverb-Raum
  --------------------------------------------------------------------
  spaced_out = {
    id      = "spaced_out",
    display = "BABY Audio Spaced Out",
    match   = {"spaced out %(baby audio%)","baby audio spaced out"},
    vendor  = "BABY Audio",
    type    = "delay_reverb_space",
    roles   = {"Delay","Reverb","Space","IDM","Ambient"},

    sections = {
      "ECHO GRID / DELAY",
      "REVERB TANK",
      "MIXER (Echo vs Reverb)",
      "MOD / WOBBLE",
      "OUTPUT",
    },

    key_params = {
      delay_time     = "Delay-Zeit/Grid",
      delay_feedback = "Feedback",
      reverb_size    = "Reverb-Größe",
      reverb_decay   = "Reverb-Decay",
      echo_reverb_blend = "Balance Echo vs Reverb",
      mix            = "Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- TBProAudio GSat+ – Saturator
  --------------------------------------------------------------------
  gsat_plus = {
    id      = "gsat_plus",
    display = "TBProAudio GSat+",
    match   = {"gsat%+","tbproaudio gsat"},
    vendor  = "TBProAudio",
    type    = "saturation",
    roles   = {"Saturation","Color","Bus","Mix","Master","Free"},

    sections = {
      "INPUT / DRIVE",
      "SATURATION (MODE, SYMMETRY)",
      "FILTER",
      "OUTPUT",
    },

    key_params = {
      drive          = "Drive/Input",
      sat_mode       = "Sättigungsmodus",
      symmetry       = "Symmetrisch/Asymmetrisch",
      hp_filter      = "Highpass im Sidechain oder Signalweg",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- PaulXStretch – Extreme Time-Stretching
  --------------------------------------------------------------------
  paulxstretch = {
    id      = "paulxstretch",
    display = "PaulXStretch",
    match   = {"paulxstretch","paulx stretch"},
    vendor  = "Xenakios",
    type    = "time_stretch_extreme",
    roles   = {"Ambient","Drone","Sounddesign","Extreme FX"},

    sections = {
      "TIME STRETCH",
      "SPECTRAL BLUR",
      "FILTER / HARMONICS",
      "OUTPUT",
    },

    key_params = {
      stretch_factor = "Streckungsfaktor (z.B. 10x, 100x)",
      window_size    = "Fenstergröße / Glättung",
      spectral_blur  = "Spektrales Verwischen",
      filter_lowcut  = "Lowcut",
      filter_highcut = "Highcut",
    },
  },

  --------------------------------------------------------------------
  -- Noise Engineering Ruina – Distortion/Destruction
  --------------------------------------------------------------------
  ruina = {
    id      = "ruina",
    display = "Noise Engineering Ruina",
    match   = {"ruina %(noise engineering%)","ruina"},
    vendor  = "Noise Engineering",
    type    = "distortion_multi",
    roles   = {"Distortion","Glitch","IDM","Industrial","FSU"},

    sections = {
      "INPUT / GAIN",
      "DISTORTION ENGINES",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      input_gain     = "Input / Drive",
      dist_mode      = "Distortion-Modus/Engine",
      tone           = "Tone / Filter",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },



  --------------------------------------------------------------------
  -- Unfiltered Audio lo-fi-af – Multi-Stage LoFi/Degrader
  --------------------------------------------------------------------
  lo_fi_af = {
    id      = "lo_fi_af",
    display = "Unfiltered Audio lo-fi-af (Plugin Alliance)",
    match   = {"lo%-fi%-af","unfiltered audio lo%-fi%-af"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "lofi_multi_fx_spectral",
    roles   = {"LoFi","Texture","IDM","Sounddesign","Glitch"},

    sections = {
      "INPUT / OUTPUT",
      "SPECTRAL (Zero Shift, Stretch, Iterate, MP3, Ripple)",
      "DIGITAL (Bitrate, Aliasing)",
      "ANALOG (Speaker/Tape/Amp)",
      "NOISE / FILTER",
      "MIX",
    },

    key_params = {
      input_gain     = "Input Gain vor der Bearbeitung",
      spectral_mode  = "Auswahl des spektralen Degraders",
      spectral_depth = "Intensität der spektralen Artefakte",
      bitrate        = "Bitauflösung / Quantisierung",
      samplerate     = "Sample-Rate-Reduktion",
      analog_mode    = "Analog-Charakter (Speaker, Tape, Amp)",
      noise_level    = "Rauschpegel",
      filter_cutoff  = "Low-/Highcut im Effektweg",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Glitchmachines Hysteresis – Glitch-Delay
  --------------------------------------------------------------------
  hysteresis = {
    id      = "hysteresis",
    display = "Hysteresis (Glitchmachines)",
    match   = {"hysteresis %(glitchmachines%)","glitchmachines hysteresis"},
    vendor  = "Glitchmachines",
    type    = "glitch_delay",
    roles   = {"Delay","Glitch","IDM","FSU","Texture"},

    sections = {
      "DELAY (Time/Feedback)",
      "STUTTER / GATE",
      "FILTER",
      "MODULATION",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time     = "Delay-Zeit",
      feedback       = "Feedback-Menge",
      stutter_rate   = "Stutter-Rate / Gate-Geschwindigkeit",
      filter_cutoff  = "Filter Cutoff",
      mod_depth      = "Modulations-Tiefe",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Glitchmachines Quadrant – Modularer Multi-FX
  --------------------------------------------------------------------
  quadrant = {
    id      = "quadrant",
    display = "Quadrant (Glitchmachines)",
    match   = {"quadrant %(glitchmachines%)","glitchmachines quadrant"},
    vendor  = "Glitchmachines",
    type    = "modular_multi_fx",
    roles   = {"Glitch","FSU","IDM","Sounddesign"},

    sections = {
      "MODULE SLOTS (Filter, Delay, Distortion, etc.)",
      "MOD SOURCES (LFO, Env, Random)",
      "ROUTING / MATRIX",
      "GLOBAL MIX",
    },

    key_params = {
      module_types   = "Ausgewählte Module in den Slots",
      module_params  = "Hauptparameter der aktiven Module",
      mod_assign     = "Modulations-Zuweisungen",
      mix            = "Globaler Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- Glitchmachines Subvert2 – Multi-Distortion / FSU
  --------------------------------------------------------------------
  subvert2 = {
    id      = "subvert2",
    display = "Subvert2 (Glitchmachines)",
    match   = {"subvert2 %(glitchmachines%)","glitchmachines subvert2","subvert 2 %(glitchmachines%)"},
    vendor  = "Glitchmachines",
    type    = "multi_distortion_modular",
    roles   = {"Distortion","FSU","Glitch","IDM","Noise"},

    sections = {
      "DISTORTION ENGINES",
      "FILTER / TONE",
      "MODULATION (LFO/ENV)",
      "ROUTING",
      "MIX / OUTPUT",
    },

    key_params = {
      dist_drives    = "Drive der einzelnen Distortion-Stufen",
      dist_modes     = "Modi/Algorithmen der Stufen",
      filter_cutoff  = "Filter Cutoff nach den Stufen",
      mod_depth      = "Modulations-Tiefe",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Tape Cassette 2 (Caelum Audio) – Kassettensimulation
  --------------------------------------------------------------------
  tape_cassette2 = {
    id      = "tape_cassette2",
    display = "Tape Cassette 2 (Caelum Audio)",
    match   = {"tape cassette 2","caelum audio tape cassette"},
    vendor  = "Caelum Audio",
    type    = "tape_lofi",
    roles   = {"LoFi","Tape","Drums","Keys","IDM"},

    sections = {
      "INPUT / DRIVE",
      "WOW / FLUTTER",
      "NOISE / HISS",
      "SATURATION",
      "LOW/HIGH CUT",
      "MIX / OUTPUT",
    },

    key_params = {
      input_gain     = "Input / Drive",
      wow_amount     = "Wow-Intensität",
      flutter_amount = "Flutter-Intensität",
      noise_level    = "Tape-Noise/Hiss",
      saturation     = "Bandsättigung",
      lowcut         = "Lowcut-Frequenz",
      highcut        = "Highcut-Frequenz",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- CHOWTapeModel – Physikalisches Tape-Model
  --------------------------------------------------------------------
  chow_tape = {
    id      = "chow_tapemodel",
    display = "CHOWTapeModel (chowdsp)",
    match   = {"chowtapemodel","chow tape model","chowtapemodel %(chowdsp%)"},
    vendor  = "chowdsp",
    type    = "tape_model",
    roles   = {"Tape","LoFi","Saturation","IDM","Master"},

    sections = {
      "MODEL (Machine Type, Mode)",
      "DRIVE / SATURATION",
      "WOW / FLUTTER / DROP-OUTS",
      "FILTER / TONE",
      "NOISE / HYSTERESIS",
      "MIX / OUTPUT",
    },

    key_params = {
      mode           = "Bandmaschinen-Modus",
      drive          = "Drive/Sättigung",
      wow            = "Wow",
      flutter        = "Flutter",
      dropouts       = "Dropouts / Drop Intensity",
      noise_level    = "Bandrauschen",
      tone           = "Tone / EQ",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Unfiltered Audio Bass Mint – Low-End Enhancer
  --------------------------------------------------------------------
  bass_mint = {
    id      = "bass_mint",
    display = "Unfiltered Audio Bass Mint (Plugin Alliance)",
    match   = {"bass mint","unfiltered audio bass mint"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "bass_enhancer",
    roles   = {"Bass","Mix","Master","Low-End"},

    sections = {
      "LOW END SPLIT",
      "FOCUS / ENHANCE",
      "DRIVE / SAT",
      "STEREO (MONO-MAKER/EXPAND)",
      "MIX / OUTPUT",
    },

    key_params = {
      split_freq     = "Frequenz, unter/über der getrennt wird",
      enhance_amount = "Low-End-Enhance-Menge",
      drive          = "Sättigung des Bassbereichs",
      mono_below     = "Mono-Maker Grenzfrequenz",
      width_above    = "Stereo-Breite im oberen Bereich",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Unfiltered Audio Fault – Spectral Shifter
  --------------------------------------------------------------------
  fault = {
    id      = "fault",
    display = "Unfiltered Audio Fault (Plugin Alliance)",
    match   = {"fault %(plugin alliance%)","unfiltered audio fault"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "spectral_pitch_shift_fx",
    roles   = {"Glitch","Pitch","FSU","IDM","Sounddesign"},

    sections = {
      "PITCH SHIFT",
      "FREQUENCY SHIFT",
      "FEEDBACK MATRIX",
      "MOD MATRIX",
      "MIX / OUTPUT",
    },

    key_params = {
      pitch_shift    = "Tonhöhenverschiebung",
      freq_shift     = "Frequenzverschiebung",
      feedback       = "Feedback-Menge",
      mod_assign     = "Modulations-Zuweisungen",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Unfiltered Audio G8 – Gate / Pattern Tool
  --------------------------------------------------------------------
  g8_gate = {
    id      = "g8_gate",
    display = "Unfiltered Audio G8 (Plugin Alliance) (4ch)",
    match   = {"g8 %(plugin alliance%)","unfiltered audio g8"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "gate_pattern",
    roles   = {"Gate","Transient","Pattern","IDM"},

    sections = {
      "GATE CORE (Threshold/Ratio)",
      "CYCLE / ONE-SHOT / HYSTERESIS",
      "SIDECHAIN / DETECTION",
      "MIDI OUT / PATTERN",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold      = "Schwellwert",
      ratio          = "Ratio (Gate-Intensität)",
      attack         = "Attack",
      release        = "Release",
      hysteresis     = "Hysteresis-Bereich",
      cycle_mode     = "Cycle/One-Shot Modus",
      midi_out       = "MIDI-Out Einstellungen",
      mix            = "Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- Unfiltered Audio Sandman Pro – Sleep Delay / Time-Warp
  --------------------------------------------------------------------
  sandman_pro = {
    id      = "sandman_pro",
    display = "Unfiltered Audio Sandman Pro (Plugin Alliance)",
    match   = {"sandman pro","unfiltered audio sandman pro"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "delay_sleep_buffer",
    roles   = {"Delay","Glitch","Granular","IDM","Ambient"},

    sections = {
      "DELAY CORE (Time/Feedback)",
      "SLEEP BUFFER (Freeze/Loop)",
      "TIME WARP / PITCH",
      "FILTER / DRIVE",
      "MODULATION / MOD MATRIX",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time     = "Delay-Zeit",
      feedback       = "Feedback-Menge",
      sleep_amount   = "Sleep/Freeze-Menge",
      warp_amount    = "Time-Warp/Pitch-Verzerrung",
      filter_cutoff  = "Filter Cutoff",
      mod_assign     = "Modulations-Zuweisungen",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Unfiltered Audio Silo – Granular Spatial FX
  --------------------------------------------------------------------
  silo = {
    id      = "silo",
    display = "Unfiltered Audio Silo (Plugin Alliance)",
    match   = {"silo %(plugin alliance%)","unfiltered audio silo"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "granular_spatial_fx",
    roles   = {"Granular","Reverb","Delay","IDM","Ambient","Texture"},

    sections = {
      "GRAIN ENGINE",
      "SPATIAL (Position/Orbit)",
      "FILTER / DIFFUSION",
      "MODULATION",
      "MIX / OUTPUT",
    },

    key_params = {
      grain_density  = "Dichte der Grains",
      grain_length   = "Länge der Grains",
      grain_pitch    = "Pitch der Grains",
      position       = "Räumliche Position/Orbit",
      diffusion      = "Diffusionsgrad",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Unfiltered Audio Zip – Experimental Kompressor
  --------------------------------------------------------------------
  zip_comp = {
    id      = "zip_comp",
    display = "Unfiltered Audio Zip (Plugin Alliance)",
    match   = {"zip %(plugin alliance%)","unfiltered audio zip"},
    vendor  = "Unfiltered Audio / Plugin Alliance",
    type    = "compressor_modulated",
    roles   = {"Compressor","Rhythmic","Texture","IDM"},

    sections = {
      "COMPRESSOR CORE (Threshold/Ratio)",
      "MOD SOURCES (LFO, Envelope, Spectral, etc.)",
      "MOD DESTINATIONS (Attack/Release/Ratio)",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold      = "Threshold",
      ratio          = "Ratio",
      attack         = "Attack",
      release        = "Release",
      mod_depth      = "Modulations-Tiefe",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- dblue Crusher – Bitcrusher / LoFi
  --------------------------------------------------------------------
  dblue_crusher = {
    id      = "dblue_crusher",
    display = "dblue Crusher",
    match   = {"dblue crusher","crusher %(illformed%)"},
    vendor  = "illformed",
    type    = "bitcrusher_lofi",
    roles   = {"LoFi","Drums","Glitch","IDM"},

    sections = {
      "BIT DEPTH",
      "SAMPLE RATE",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      bit_depth      = "Bitreduzierung",
      sample_rate    = "Sample-Rate-Reduktion",
      tone           = "Tone/Filter",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Bitcrush – Kilohearts Bitcrusher
  --------------------------------------------------------------------
  khs_bitcrush = {
    id      = "khs_bitcrush",
    display = "kHs Bitcrush (Kilohearts)",
    match   = {"khs bitcrush","bitcrush %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "bitcrusher_lofi",
    roles   = {"LoFi","Drums","Glitch","IDM"},

    sections = {
      "BIT DEPTH",
      "SAMPLE RATE",
      "DRIVE",
      "MIX / OUTPUT",
    },

    key_params = {
      bit_depth      = "Bitreduzierung",
      sample_rate    = "Sample-Rate-Reduktion",
      drive          = "Drive/Sättigung",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Geometer – Wellenform-Geometrie (Destroy FX)
  --------------------------------------------------------------------
  geometer = {
    id      = "geometer",
    display = "Geometer (Destroy FX)",
    match   = {"geometer %(destroy fx%)","destroy fx geometer","geometer"},
    vendor  = "Destroy FX",
    type    = "waveform_geometry_fsu",
    roles   = {"FSU","Glitch","IDM","Noise"},

    sections = {
      "GEOMETRY (Segments/Shape)",
      "INPUT / OUTPUT",
      "MIX",
    },

    key_params = {
      segments       = "Anzahl/Größe der Geometrie-Segmente",
      shape          = "Form der Segment-Transformation",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Scrubby – Buffer-Scrub / Time-Stretch (Destroy FX)
  --------------------------------------------------------------------
  scrubby = {
    id      = "scrubby",
    display = "Scrubby (Destroy FX)",
    match   = {"scrubby %(destroy fx%)","destroy fx scrubby","scrubby"},
    vendor  = "Destroy FX",
    type    = "buffer_scrub_fx",
    roles   = {"Glitch","Time","FSU","IDM"},

    sections = {
      "BUFFER (Size/Position)",
      "SPEED / DIRECTION",
      "PITCH",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_size    = "Größe des Scrub-Buffers",
      position       = "Position im Buffer",
      speed          = "Abspielgeschwindigkeit",
      pitch          = "Pitch-Shift",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Transverb – Varispeed Delay / Two-Head (Destroy FX)
  --------------------------------------------------------------------
  transverb = {
    id      = "transverb",
    display = "Transverb (Destroy FX)",
    match   = {"transverb %(destroy fx%)","destroy fx transverb","transverb"},
    vendor  = "Destroy FX",
    type    = "varispeed_delay",
    roles   = {"Delay","Glitch","IDM","Ambient"},

    sections = {
      "READ HEAD A (Time/Speed)",
      "READ HEAD B (Time/Speed)",
      "FEEDBACK / FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      time_a         = "Delay-Zeit/Speed Head A",
      time_b         = "Delay-Zeit/Speed Head B",
      feedback       = "Feedback-Menge",
      filter_cutoff  = "Filter Cutoff",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- IO/RingMod – Ringmodulator (benoit serrano)
  --------------------------------------------------------------------
  io_ringmod = {
    id      = "io_ringmod",
    display = "IO/RingMod (benoit serrano)",
    match   = {"io/ringmod","ringmod %(benoit serrano%)"},
    vendor  = "benoit serrano",
    type    = "ringmod_fx",
    roles   = {"Ringmod","Metallic","IDM","Experimental"},

    sections = {
      "CARRIER (Freq/Shape)",
      "MOD DEPTH",
      "MIX / OUTPUT",
    },

    key_params = {
      carrier_freq   = "Carrier-Frequenz",
      depth          = "Modulations-Tiefe",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ValhallaSpaceModulator – Modulations-FX (Flanger/Chorus)
  --------------------------------------------------------------------
  valhalla_spacemod = {
    id      = "valhalla_spacemod",
    display = "ValhallaSpaceModulator (Valhalla DSP)",
    match   = {"valhallaspacemodulator","valhalla spacemodulator"},
    vendor  = "Valhalla DSP",
    type    = "modulation_fx",
    roles   = {"Flanger","Chorus","Space","IDM","Ambient"},

    sections = {
      "ALGORITHM",
      "RATE / DEPTH",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      algorithm      = "Algorithmus (verschiedene Mod-Varianten)",
      rate           = "Modulationsrate",
      depth          = "Modulationstiefe",
      feedback       = "Feedback-Menge",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Reverser – Reverse Buffer FX (Kilohearts)
  --------------------------------------------------------------------
  khs_reverser = {
    id      = "khs_reverser",
    display = "kHs Reverser (Kilohearts)",
    match   = {"khs reverser","reverser %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "reverse_fx",
    roles   = {"Reverse","Glitch","IDM","Transition"},

    sections = {
      "BUFFER (Size/Sync)",
      "WINDOW / FADE",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_size    = "Länge des Reverse-Buffers",
      sync_mode      = "Synchronisation zum Host (z.B. 1/4, 1/2)",
      fade           = "Fade-In/Out der Umkehrung",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },



  --------------------------------------------------------------------
  -- LatticeReverb (Uhhyou) – experimenteller Lattice-Hall
  --------------------------------------------------------------------
  lattice_reverb = {
    id      = "lattice_reverb",
    display = "LatticeReverb (Uhhyou)",
    match   = {"latticereverb","lattice reverb %(uhhyou%)"},
    vendor  = "Uhhyou",
    type    = "reverb_lattice_experimental",
    roles   = {"Reverb","Space","IDM","Ambient","Experimental"},

    sections = {
      "DELAY LATTICE (mehrere Delays im Gitter)",
      "TONE / DAMPING",
      "SIZE / DENSITY",
      "MIX / OUTPUT",
    },

    key_params = {
      lattice_size   = "Größe des Delay-Gitters (Anzahl/Skalierung der Delays)",
      decay_time     = "Abklingzeit des Halls",
      damping        = "Höhenbedämpfung im Hall",
      tone           = "Tonale Färbung (hell/dunkel)",
      mix            = "Dry/Wet-Mix",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ChowPhaserMono – nichtlinearer Phaser (Mono)
  --------------------------------------------------------------------
  chow_phaser_mono = {
    id      = "chow_phaser_mono",
    display = "ChowPhaserMono (chowdsp)",
    match   = {"chowphasermono","chow phaser mono"},
    vendor  = "chowdsp",
    type    = "phaser_nonlinear",
    roles   = {"Phaser","Modulation","IDM","Texture"},

    sections = {
      "STAGES / POLES",
      "LFO / MODULATION",
      "FEEDBACK / RESONANCE",
      "MIX / OUTPUT",
    },

    key_params = {
      stages         = "Anzahl der Phaser-Stufen",
      lfo_rate       = "LFO-Geschwindigkeit",
      lfo_depth      = "Modulationstiefe",
      feedback       = "Feedback/Resonanz der Phaser-Kette",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ChowPhaserStereo – Stereo-Phaser
  --------------------------------------------------------------------
  chow_phaser_stereo = {
    id      = "chow_phaser_stereo",
    display = "ChowPhaserStereo (chowdsp)",
    match   = {"chowphaserstereo","chow phaser stereo"},
    vendor  = "chowdsp",
    type    = "phaser_nonlinear_stereo",
    roles   = {"Phaser","Modulation","Stereo","IDM","Texture"},

    sections = {
      "STAGES / POLES (L/R)",
      "LFO (ggf. Phasenoffset)",
      "FEEDBACK / RESONANCE",
      "MIX / OUTPUT",
    },

    key_params = {
      stages         = "Anzahl der Phaser-Stufen",
      lfo_rate       = "LFO-Geschwindigkeit",
      lfo_depth      = "Modulationstiefe",
      stereo_phase   = "Phasenoffset zwischen L/R",
      feedback       = "Feedback/Resonanz",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blindfold EQ (AudioThing) – EQ ohne Anzeige
  --------------------------------------------------------------------
  blindfold_eq = {
    id      = "blindfold_eq",
    display = "Blindfold EQ (AudioThing)",
    match   = {"blindfold eq","audiothing blindfold"},
    vendor  = "AudioThing",
    type    = "eq_blind_minimal",
    roles   = {"EQ","Tone","Character","Mix"},

    sections = {
      "4 EQ-BÄNDER (LowShelf, LowMid, HighMid, HighShelf)",
      "INPUT / OUTPUT",
    },

    key_params = {
      band_gain      = "Gain für die 4 Bänder",
      band_freq      = "Grundfrequenzen der Bänder",
      band_q         = "Güte/Q (intern)",
      input_gain     = "Input Gain",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Vinyl (iZotope) – Vinyl-/LoFi-Simulator
  --------------------------------------------------------------------
  izotope_vinyl = {
    id      = "izotope_vinyl",
    display = "Vinyl (iZotope)",
    match   = {"vinyl %(izotope%)","izotope vinyl"},
    vendor  = "iZotope",
    type    = "vinyl_lofi",
    roles   = {"LoFi","Texture","Keys","Drums","IDM"},

    sections = {
      "MECHANICAL NOISE",
      "WEAR / DUST / SCRATCH",
      "WARP / WOW",
      "YEAR (Bandbegrenzung)",
      "MIX / OUTPUT",
    },

    key_params = {
      mech_noise     = "Mechanisches Geräusch (Motor/Tonarm)",
      dust           = "Staubanteil",
      scratch        = "Kratzer-Intensität",
      wear           = "Abnutzung der Platte",
      warp           = "Pitch-Warp / Wow",
      year           = "Zeitepoche/Voicing (z.B. 1930–2000)",
      input_gain     = "Input Gain",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Trash (iZotope) – Multiband-Distortion & Convolver
  --------------------------------------------------------------------
  izotope_trash = {
    id      = "izotope_trash",
    display = "Trash (iZotope)",
    match   = {"trash %(izotope%)","izotope trash"},
    vendor  = "iZotope",
    type    = "distortion_multiband_convolver",
    roles   = {"Distortion","FSU","IDM","Sounddesign"},

    sections = {
      "FILTER PRE",
      "MULTIBAND DISTORTION",
      "CONVOLVE (IRs)",
      "DYNAMICS / COMP",
      "FILTER POST",
      "MIX / OUTPUT",
    },

    key_params = {
      pre_filter     = "Pre-Filter-Curve",
      band_drives    = "Drive pro Frequenzband",
      dist_type      = "Distortion-Typ/Modus",
      convolve_ir    = "Ausgewählte Convolution-IR",
      dynamics       = "Kompressions-/Gate-Einstellungen",
      post_filter    = "Post-Filter-Curve",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Panflow (Audiomodern) – Creative Panning Modulator
  --------------------------------------------------------------------
  panflow = {
    id      = "panflow",
    display = "Panflow (Audiomodern)",
    match   = {"panflow","audiomodern panflow"},
    vendor  = "Audiomodern",
    type    = "panning_sequencer",
    roles   = {"Panning","Rhythm","IDM","Movement"},

    sections = {
      "PAN ENVELOPE GRID",
      "RANDOMIZE / HUMANIZE",
      "SYNC / RATE",
      "MIX / OUTPUT",
    },

    key_params = {
      pattern        = "Panorama-Verlauf über ein Grid",
      sync_rate      = "Host-synchronisierte Rate (z.B. 1/8, 1/16)",
      random_amount  = "Randomisierung der Pan-Hüllkurve",
      smooth         = "Glättung/Interpolation zwischen Steps",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Gatelab (Audiomodern) – Gate-/Volume-Sequencer
  --------------------------------------------------------------------
  gatelab = {
    id      = "gatelab",
    display = "Gatelab (Audiomodern)",
    match   = {"gatelab","audiomodern gatelab"},
    vendor  = "Audiomodern",
    type    = "gate_sequencer",
    roles   = {"Gate","Rhythm","IDM","Glitch"},

    sections = {
      "STEP GATE PATTERN",
      "RANDOM / AUTO-MODE",
      "SYNC / RATE",
      "MIX / OUTPUT",
    },

    key_params = {
      gate_pattern   = "Gate-Step-Pattern über 16/32 Steps",
      random_amount  = "Randomisierung/Mutation der Steps",
      sync_rate      = "Host-synchronisierte Rate",
      swing          = "Swing/Shuffle",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Driftmaker (Puremagnetik) – Delay Disintegration Device
  --------------------------------------------------------------------
  driftmaker = {
    id      = "driftmaker",
    display = "Driftmaker (Puremagnetik)",
    match   = {"driftmaker","driftmaker %(puremagnetik%)"},
    vendor  = "Puremagnetik",
    type    = "delay_disintegration",
    roles   = {"Delay","LoFi","Texture","IDM","Ambient"},

    sections = {
      "TIME / FEEDBACK",
      "DISINTEGRATION / FRAGMENTS",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time     = "Delay-Zeit",
      feedback       = "Feedback-Menge",
      disintegrate   = "Zerfalls-/Fragmentationsgrad",
      tone           = "Tonale Färbung",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Backmask (Freakshow Industries) – Chaos-Reverser
  --------------------------------------------------------------------
  backmask = {
    id      = "backmask",
    display = "Backmask (Freakshow Industries)",
    match   = {"backmask","freakshow backmask"},
    vendor  = "Freakshow Industries",
    type    = "reverse_random_fx",
    roles   = {"Reverse","Glitch","FSU","IDM"},

    sections = {
      "REVERSE LOGIC (Probabilities)",
      "TIME WINDOW",
      "ADDITIONAL FX (Reverb/Delay/Distortion, je nach Version)",
      "MIX / OUTPUT",
    },

    key_params = {
      reverse_prob   = "Wahrscheinlichkeit für Reverse-Ereignisse",
      window_size    = "Zeitfenster der Umkehrung",
      fx_amount      = "Intensität der Zusatz-FX",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- BreadSlicer (Audioblast) – Echtzeit-Slicer
  --------------------------------------------------------------------
  bread_slicer = {
    id      = "bread_slicer",
    display = "BreadSlicer (Audioblast)",
    match   = {"breadslicer","bread slicer","audioblast breadslicer"},
    vendor  = "Audioblast",
    type    = "auto_slicer_glitch",
    roles   = {"Glitch","Slicer","IDM","Breaks"},

    sections = {
      "SLICE GRID / LENGTH",
      "REVERSE / REORDER",
      "RANDOM / VARIATION",
      "SYNC / TEMPO",
      "MIX / OUTPUT",
    },

    key_params = {
      slice_length   = "Länge der Slices (z.B. 1/8, 1/16, 1/32)",
      reverse_prob   = "Wahrscheinlichkeit für Reverse-Slices",
      reorder_mode   = "Reorder/Shuffle Modus",
      random_amount  = "Intensität der Variation",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Panagement 2 (Auburn Sounds) – Binaural Space FX
  --------------------------------------------------------------------
  panagement2 = {
    id      = "panagement2",
    display = "Panagement 2 (Auburn Sounds)",
    match   = {"panagement 2","panagement2","auburn sounds panagement"},
    vendor  = "Auburn Sounds",
    type    = "binaural_space_fx",
    roles   = {"Space","Panning","Delay","Reverb","IDM","Ambient"},

    sections = {
      "PAN / BINAURAL POSITION",
      "DISTANCE / EARLY REFLECTIONS",
      "REVERB",
      "DELAY / ECHOES",
      "LFO / MOD (Pan/Depth)",
      "MIX / OUTPUT",
    },

    key_params = {
      azimuth        = "Horizontaler Winkel um den Kopf",
      elevation      = "Vertikaler Winkel",
      distance       = "Entfernung / Tiefe",
      reverb_amount  = "Reverb-Anteil",
      delay_time     = "Delay-Zeit",
      lfo_rate       = "Tempo der Bewegungsmodulation",
      lfo_depth      = "Tiefe der Panning-Modulation",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Selene (Auburn Sounds) – Reverb mit Ducking & Freeze
  --------------------------------------------------------------------
  selene = {
    id      = "selene",
    display = "Selene (Auburn Sounds)",
    match   = {"selene %(auburn sounds%)","auburn selene"},
    vendor  = "Auburn Sounds",
    type    = "reverb_ducking",
    roles   = {"Reverb","Space","Ambient","IDM"},

    sections = {
      "TIME / SIZE",
      "DUCKING / GATE",
      "TONE / DAMPING",
      "FREEZE / INFINITE",
      "MIX / OUTPUT",
    },

    key_params = {
      decay_time     = "Hall-Abklingzeit",
      size           = "Größe des virtuellen Raums",
      duck_amount    = "Ducking-Intensität (Reverb wird vom Dry-Signal verdrängt)",
      tone           = "Tonalität (hell/dunkel)",
      freeze         = "Freeze-/Infinite-Hall-Schaltung",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Inner Pitch 2 (Auburn Sounds) – Pitch-Shifter
  --------------------------------------------------------------------
  inner_pitch2 = {
    id      = "inner_pitch2",
    display = "Inner Pitch 2 (Auburn Sounds)",
    match   = {"inner pitch 2","innerpitch2","auburn inner pitch"},
    vendor  = "Auburn Sounds",
    type    = "pitch_shifter_hq",
    roles   = {"Pitch","Vocal","FX","IDM"},

    sections = {
      "PITCH / INTERVAL",
      "FORMANT / HARMONICS",
      "CORRECTION / SMOOTH",
      "MIX / OUTPUT",
    },

    key_params = {
      pitch_shift    = "Anzahl Halbtöne (Up/Down)",
      formant_shift  = "Formantverschiebung",
      correction     = "Stabilität/Naturalness der Tonhöhenkorrektur",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Renegate (Auburn Sounds) – Gate/Expander
  --------------------------------------------------------------------
  renegate = {
    id      = "renegate",
    display = "Renegate (Auburn Sounds)",
    match   = {"renegate %(auburn sounds%)","auburn renegate"},
    vendor  = "Auburn Sounds",
    type    = "gate_expander",
    roles   = {"Gate","Expand","Rhythm","IDM"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "LOOKAHEAD",
      "SIDECHAIN / FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold      = "Schwelle für Gate/Expander",
      ratio          = "Verhältnis (wie stark zu/aufgemacht wird)",
      attack         = "Attack-Zeit",
      release        = "Release-Zeit",
      lookahead      = "Look-Ahead-Zeit",
      sc_filter      = "Sidechain-Filter",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- DLYM (Imaginando) – Delay Modulator (Chorus/Flanger)
  --------------------------------------------------------------------
  dlym = {
    id      = "dlym",
    display = "DLYM (Imaginando)",
    match   = {"dlym %(imaginando%)","imaginando dlym"},
    vendor  = "Imaginando",
    type    = "chorus_flanger_mod",
    roles   = {"Chorus","Flanger","Modulation","IDM","Ambient"},

    sections = {
      "ALGORITHM (Chorus/Flanger)",
      "RATE / DEPTH",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      algorithm      = "Chorus- oder Flanger-Modus",
      rate           = "Modulationsrate",
      depth          = "Modulationstiefe",
      feedback       = "Feedback-Menge",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Distox (Analog Obsession) – Multimode-Distortion
  --------------------------------------------------------------------
  distox = {
    id      = "distox",
    display = "Distox (Analog Obsession)",
    match   = {"distox %(analog obsession%)","analog obsession distox","distox"},
    vendor  = "Analog Obsession",
    type    = "distortion_multimode",
    roles   = {"Distortion","Saturation","Color","IDM","Mix","Bus"},

    sections = {
      "INPUT / DRIVE",
      "MODE (OpAmp/Tube/etc.)",
      "FILTER (HP/LP)",
      "MIX / OUTPUT",
    },

    key_params = {
      input_gain     = "Input / Drive",
      mode           = "Distortion-Mode (OpAmp, Tube, etc.)",
      hp_filter      = "Highpass-Frequenz",
      lp_filter      = "Lowpass-Frequenz",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Basslane (Tone Projects) – Bass Mono/Stereo Shaper
  --------------------------------------------------------------------
  basslane = {
    id      = "basslane",
    display = "Basslane (Tone Projects)",
    match   = {"basslane","tone projects basslane"},
    vendor  = "Tone Projects",
    type    = "bass_stereo_shaper",
    roles   = {"Bass","Stereo","Mix","Master"},

    sections = {
      "SPLIT FREQUENCY",
      "LOW MONO",
      "HIGH STEREO",
      "WIDTH / PHASE",
      "MIX / OUTPUT",
    },

    key_params = {
      split_freq     = "Übergangsfrequenz Low/High",
      low_mono       = "Mono-Anteil im Bassbereich",
      high_width     = "Stereo-Breite im oberen Bereich",
      phase_mode     = "Phasen-Verhalten/Summenkompatibilität",
      mix            = "Dry/Wet (falls verfügbar)",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Karanyi Wavesurfer – AI Multi-FX
  --------------------------------------------------------------------
  wavesurfer = {
    id      = "wavesurfer",
    display = "Karanyi Sounds Wavesurfer (Plugin Alliance)",
    match   = {"wavesurfer","karanyi wavesurfer"},
    vendor  = "Karanyi Sounds / Plugin Alliance",
    type    = "multi_fx_ai_vintage",
    roles   = {"LoFi","Texture","IDM","Ambient","Sounddesign"},

    sections = {
      "MODULE CHAINS (Drive/Mod/Delay/Reverb/etc.)",
      "MACROS",
      "ANALOG / VINTAGE COLOR",
      "MIX / OUTPUT",
    },

    key_params = {
      module_states  = "Aktive FX-Module und deren Parameter",
      macro_controls = "Macro-Regler für mehrere interne Parameter",
      color_amount   = "Vintage/Analog-Färbungsstärke",
      mix            = "Globaler Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Toner (Outobugi) – 4-Band Tone Shaper mit Saturation
  --------------------------------------------------------------------
  toner = {
    id      = "toner",
    display = "Toner (Outobugi)",
    match   = {"toner %(outobugi%)","outobugi toner"},
    vendor  = "Outobugi",
    type    = "tone_shaper_saturation",
    roles   = {"EQ","Tone","Saturation","Mix"},

    sections = {
      "4-BAND EQ",
      "SATURATION",
      "MID/SIDE ODER L/R (falls vorhanden)",
      "MIX / OUTPUT",
    },

    key_params = {
      band_gain      = "Gain der 4 Bänder",
      band_freq      = "Frequenzen der 4 Bänder",
      saturation     = "Sättigungsgrad",
      stereo_mode    = "M/S oder L/R Arbeitsmodus",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },



  --------------------------------------------------------------------
  -- Uberloud (BOOM Interactive) – Loudness Maximizer
  --------------------------------------------------------------------
  uberloud = {
    id      = "uberloud",
    display = "UBERLOUD (BOOM Interactive)",
    match   = {"uberloud","uber loud","boom uberloud"},
    vendor  = "BOOM Library / BOOM Interactive",
    type    = "loudness_maximizer",
    roles   = {"Limiter","Maximizer","Bus","Master","Sounddesign"},

    sections = {
      "INPUT / DRIVE",
      "BAND CONTROLS",
      "DENOISER",
      "OUTPUT",
    },

    key_params = {
      input_gain   = "Input/Drive in den Loudness-Algorithmus",
      band_amount  = "Lautheitsanhebung je Band",
      denoiser     = "Reduktion angehobenen Rauschens",
      output_gain  = "Output-Level",
    },
  },

  --------------------------------------------------------------------
  -- TremODeath (EvilTurtleProductions) – Tremolo / Chop FX
  --------------------------------------------------------------------
  tremodeath = {
    id      = "tremodeath",
    display = "TremODeath (Evil Turtle Productions)",
    match   = {"tremodeath","trem%-o%-death"},
    vendor  = "Evil Turtle Productions",
    type    = "tremolo_chopper",
    roles   = {"Tremolo","Rhythm","Glitch","IDM"},

    sections = {
      "RATE / DEPTH",
      "WAVE SHAPE",
      "STEREO / PAN",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Geschwindigkeit des Tremolos",
      depth        = "Modulationstiefe",
      wave_shape   = "LFO-Wellenform (z.B. Sinus, Rechteck)",
      stereo_mode  = "Stereo-/Pan-Modi",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Termos (Outobugi) – Saturation
  --------------------------------------------------------------------
  termos = {
    id      = "termos",
    display = "Termos (Outobugi)",
    match   = {"termos %(outobugi%)","outobugi termos"},
    vendor  = "Outobugi",
    type    = "saturation",
    roles   = {"Saturation","Color","Bus","IDM"},

    sections = {
      "INPUT / DRIVE",
      "SATURATION MODES",
      "TONE / FILTER",
      "OUTPUT",
    },

    key_params = {
      drive        = "Grad der Sättigung",
      sat_mode     = "Sättigungsmodus (z.B. härter/weicher)",
      tone         = "Tonale Färbung",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- TENSjr (Klanghelm) – Spring Reverb Lite
  --------------------------------------------------------------------
  tensjr = {
    id      = "tensjr",
    display = "TENSjr (Klanghelm)",
    match   = {"tensjr","tens jr","klanghelm tensjr"},
    vendor  = "Klanghelm",
    type    = "reverb_spring",
    roles   = {"Reverb","Spring","Guitar","FX","IDM"},

    sections = {
      "DECAY / SIZE",
      "TONE",
      "PREDELAY",
      "MIX / OUTPUT",
    },

    key_params = {
      decay        = "Hallabklingzeit der Feder",
      size         = "Größe/Charakter der Spring-Emulation",
      tone         = "Höhenbetonung / Dämpfung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Sweep (Lese) – Infinity Filter / Shepard Filter
  --------------------------------------------------------------------
  sweep = {
    id      = "sweep",
    display = "Sweep (Lese)",
    match   = {"sweep %(lese%)","lese sweep"},
    vendor  = "Lese",
    type    = "infinity_filter",
    roles   = {"Filter","Riser","Fall","IDM","FX"},

    sections = {
      "FILTER BANK",
      "DIRECTION (RISE/FALL)",
      "STEREO / SPLIT",
      "MIX / OUTPUT",
    },

    key_params = {
      center_freq  = "Zentralfrequenz des Sweeps",
      direction    = "Richtung (aufwärts/abwärts)",
      stereo_split = "Unterschiedliche Bewegung L/R",
      resonance    = "Filter-Resonanz",
      mix          = "Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- PSP stepDelay – Kreatives Tape/Step Delay
  --------------------------------------------------------------------
  psp_stepdelay = {
    id      = "psp_stepdelay",
    display = "PSP stepDelay",
    match   = {"psp stepdelay","stepdelay %(psp%)"},
    vendor  = "PSP Audioware",
    type    = "delay_step_tape",
    roles   = {"Delay","Tape","PingPong","IDM"},

    sections = {
      "STEP DELAY GRID",
      "TAPE SAT / HEAD CUEING",
      "MODULATION",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      step_pattern = "Verteilung der Delays über Steps",
      delay_time   = "Grund-Delay-Zeit",
      feedback     = "Feedback-Menge",
      tape_sat     = "Bandsättigung",
      wow_flutter  = "Tape-Modulation",
      mix          = "Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- Lagrange (UrsaDSP) – Granular Stereo Delay
  --------------------------------------------------------------------
  lagrange = {
    id      = "lagrange",
    display = "Lagrange (UrsaDSP)",
    match   = {"lagrange %(ursadsp%)","ursadsp lagrange"},
    vendor  = "UrsaDSP",
    type    = "delay_granular",
    roles   = {"Delay","Granular","IDM","Ambient","Texture"},

    sections = {
      "GRAIN SETTINGS",
      "DELAY / FEEDBACK",
      "PITCH / TIME",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      grain_size   = "Länge der Grains",
      grain_pos    = "Position im Delay-Buffer",
      delay_time   = "Basis-Delay-Zeit",
      feedback     = "Feedback-Menge",
      pitch_shift  = "Pitch der Grains",
      mix          = "Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- IVGI2 (Klanghelm) – Saturation / Distortion
  --------------------------------------------------------------------
  ivgi2 = {
    id      = "ivgi2",
    display = "IVGI2 (Klanghelm)",
    match   = {"ivgi2","ivgi 2","klanghelm ivgi2"},
    vendor  = "Klanghelm",
    type    = "saturation_dynamic",
    roles   = {"Saturation","Distortion","Bus","Master","IDM"},

    sections = {
      "DRIVE",
      "ASYM MIX / RESPONSE",
      "TRIM / OUTPUT",
      "RANDOM / DYNAMICS",
    },

    key_params = {
      drive        = "Sättigungsgrad",
      asym_mix     = "Asymmetrie der Verzerrung",
      response     = "Frequenzabhängigkeit der Sättigung",
      trim         = "Vor- oder Nachpegel",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Frontier (D16 Group) – Limiter/Maximizer
  --------------------------------------------------------------------
  frontier = {
    id      = "frontier",
    display = "Frontier (D16 Group)",
    match   = {"frontier %(d16%)","d16 frontier"},
    vendor  = "D16 Group",
    type    = "limiter",
    roles   = {"Limiter","Bus","Master","Color"},

    sections = {
      "INPUT / THRESHOLD",
      "RELEASE / AUTO",
      "SOFT CLIP",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Einsatzpunkt des Limiters",
      release      = "Release-Zeit",
      auto_release = "Automatische Release-Funktion",
      soft_clip    = "Soft-Clipping Aktivierung",
      output_gain  = "Output Level",
    },
  },

  --------------------------------------------------------------------
  -- Extend (Outobugi) – Stereo Widener
  --------------------------------------------------------------------
  extend = {
    id      = "extend",
    display = "Extend (Outobugi)",
    match   = {"extend %(outobugi%)","outobugi extend"},
    vendor  = "Outobugi",
    type    = "stereo_widener",
    roles   = {"Stereo","Width","Space","IDM"},

    sections = {
      "WIDTH",
      "MID/SIDE BALANCE",
      "FILTER (falls vorhanden)",
      "OUTPUT",
    },

    key_params = {
      width        = "Verbreiterung des Stereobilds",
      ms_balance   = "Balance zwischen Mid und Side",
      low_mono     = "Mono-Untergrenze für Bass (falls vorhanden)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Dynastor (Outobugi) – Aggressiver Kompressor
  --------------------------------------------------------------------
  dynastor = {
    id      = "dynastor",
    display = "Dynastor (Outobugi)",
    match   = {"dynastor","outobugi dynastor"},
    vendor  = "Outobugi",
    type    = "compressor_multimode",
    roles   = {"Compressor","Bus","Drums","IDM"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MODES (LR / MS / MID / SIDE)",
      "SATURATION / CLIP",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle der Kompression",
      ratio        = "Kompressionsverhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mode         = "Verarbeitungsmodus (LR/MS/MID/SIDE)",
      saturation   = "Sättigung/Soft-Clipping",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Dynastia (Outobugi) – Multiband Compressor (OTT-Style)
  --------------------------------------------------------------------
  dynastia = {
    id      = "dynastia",
    display = "Dynastia (Outobugi)",
    match   = {"dynastia","outobugi dynastia"},
    vendor  = "Outobugi",
    type    = "compressor_multiband_ott",
    roles   = {"Multiband","OTT","IDM","Drums","Bass"},

    sections = {
      "BAND SPLIT",
      "THRESHOLD / RATIO pro Band",
      "UPWARD/DOWNWARD COMP",
      "SATURATION / WIDTH",
      "OUTPUT",
    },

    key_params = {
      crossover    = "Trennfrequenzen der Bänder",
      band_ratio   = "Ratio pro Band",
      band_thresh  = "Threshold pro Band",
      upward_comp  = "Upward-Kompressionsanteil",
      downward_comp= "Downward-Kompressionsanteil",
      width        = "Stereo-Breite",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Dualcut (Outobugi) – Dual Filter
  --------------------------------------------------------------------
  dualcut = {
    id      = "dualcut",
    display = "Dualcut (Outobugi)",
    match   = {"dualcut","outobugi dualcut"},
    vendor  = "Outobugi",
    type    = "filter_dual",
    roles   = {"Filter","Tone","Creative","IDM"},

    sections = {
      "LOW CUT",
      "HIGH CUT",
      "SLOPE / RESONANCE",
      "OUTPUT",
    },

    key_params = {
      low_cut      = "Lowcut-Frequenz",
      high_cut     = "Highcut-Frequenz",
      slope        = "Filterflanke",
      resonance    = "Resonanz (falls vorhanden)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Deelay (Sixth Sample) – Versatiles Delay/Reverb
  --------------------------------------------------------------------
  deelay = {
    id      = "deelay",
    display = "Deelay (Sixth Sample)",
    match   = {"deelay %(sixth sample%)","sixth sample deelay","deelay"},
    vendor  = "Sixth Sample",
    type    = "delay_reverb_mod",
    roles   = {"Delay","Reverb","IDM","Ambient"},

    sections = {
      "DELAY CORE (Time/Feedback)",
      "DIFFUSION (Reverb)",
      "MODULATION",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Delay-Zeit",
      feedback     = "Feedback-Menge",
      diffusion    = "Anteil/Intensität des Diffusions-Reverbs",
      mod_depth    = "Modulationstiefe",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Cramit (Sixth Sample) – Multiband Comp + Distortion (OTT-Style)
  --------------------------------------------------------------------
  cramit = {
    id      = "cramit",
    display = "Cramit (Sixth Sample)",
    match   = {"cramit %(sixth sample%)","sixth sample cramit","cramit"},
    vendor  = "Sixth Sample",
    type    = "compressor_multiband_dist",
    roles   = {"Multiband","OTT","Distortion","Drums","Bass","IDM"},

    sections = {
      "BAND SPLIT",
      "THRESHOLD / RATIO pro Band",
      "DISTORTION SECTION",
      "MIX / OUTPUT",
    },

    key_params = {
      crossover    = "Trennfrequenzen der Bänder",
      band_ratio   = "Kompressionsverhältnis pro Band",
      band_thresh  = "Threshold pro Band",
      dist_amount  = "Distortion-Intensität",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Codec (Lese) – Modern Degrader (Codec-Style)
  --------------------------------------------------------------------
  codec = {
    id      = "codec",
    display = "Codec (Lese)",
    match   = {"codec %(lese%)","lese codec"},
    vendor  = "Lese",
    type    = "codec_degrader",
    roles   = {"LoFi","Degrade","IDM","Sounddesign"},

    sections = {
      "CODEC TYPE",
      "BITRATE / QUALITY",
      "PACKET DROP / GLITCH",
      "MIX / OUTPUT",
    },

    key_params = {
      codec_type   = "Art des Codecs (z.B. MP3/Opus, je nach Version)",
      bitrate      = "Bitrate/Qualität",
      packet_drop  = "Anteil von Paketverlust/Glitch",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ChowMultiTool (chowdsp) – Swiss-Army-Tool
  --------------------------------------------------------------------
  chow_multitool = {
    id      = "chow_multitool",
    display = "ChowMultiTool (chowdsp)",
    match   = {"chowmultitool","chow multi tool"},
    vendor  = "chowdsp",
    type    = "multi_fx_utility",
    roles   = {"EQ","Waveshaper","Band-Splitter","Utility","IDM"},

    sections = {
      "EQ",
      "WAVESHAPER",
      "BAND SPLITTER",
      "SVF / FILTER",
    },

    key_params = {
      eq_curve     = "EQ-Kurve",
      shaper_curve = "Waveshaper-Kennlinie",
      bands        = "Band-Split-Konfiguration",
      filter_freq  = "Filter-Cutoff",
    },
  },

  --------------------------------------------------------------------
  -- ChowMatrix (chowdsp) – Tree Multitap Delay
  --------------------------------------------------------------------
  chow_matrix = {
    id      = "chow_matrix",
    display = "ChowMatrix (chowdsp)",
    match   = {"chowmatrix","chow matrix"},
    vendor  = "chowdsp",
    type    = "delay_multitap_tree",
    roles   = {"Delay","Multitap","IDM","Ambient","FSU"},

    sections = {
      "NODE TREE (Delay-Linien)",
      "FEEDBACK / DISTORTION",
      "PANNING",
      "MIX / OUTPUT",
    },

    key_params = {
      node_times   = "Delay-Zeiten der Nodes",
      node_fb      = "Feedback pro Node",
      node_pan     = "Panorama pro Node",
      distortion   = "Distortion in den Feedback-Pfaden",
      mix          = "Dry/Wet",
    },
  },

  --------------------------------------------------------------------
  -- ChowCentaur (chowdsp) – Klon-Style Overdrive
  --------------------------------------------------------------------
  chow_centaur = {
    id      = "chow_centaur",
    display = "ChowCentaur (chowdsp)",
    match   = {"chow centaur","chowcentaur"},
    vendor  = "chowdsp",
    type    = "overdrive_klon_style",
    roles   = {"Overdrive","Guitar","Color","IDM"},

    sections = {
      "GAIN",
      "TONE",
      "OUTPUT",
      "TRADITIONAL / NEURAL MODES",
    },

    key_params = {
      gain         = "Gain/Drive",
      tone         = "Tone-Regler (Höhen)",
      output_gain  = "Output Level",
      mode         = "Traditional vs Neural Modus",
    },
  },

  --------------------------------------------------------------------
  -- BYOD (chowdsp) – Build-Your-Own Distortion
  --------------------------------------------------------------------
  byod = {
    id      = "byod",
    display = "BYOD (chowdsp)",
    match   = {"byod %(chowdsp%)","build%-your%-own%-distortion"},
    vendor  = "chowdsp",
    type    = "multi_fx_distortion_chain",
    roles   = {"Distortion","FX Chain","IDM","Sounddesign"},

    sections = {
      "MODULE CHAIN (Blocks)",
      "DISTORTION MODULES",
      "FILTER / EQ MODULES",
      "UTILITY MODULES",
    },

    key_params = {
      chain_layout = "Reihenfolge der Module",
      dist_amount  = "Sättigungs-/Distortion-Intensität",
      eq_settings  = "EQ/Tone-Shaping pro Modul",
      mix          = "Gesamt-Dry/Wet falls verwendet",
    },
  },

  --------------------------------------------------------------------
  -- ReCenter (BOOM Interactive) – Stereo Center Fix
  --------------------------------------------------------------------
  recenter = {
    id      = "recenter",
    display = "ReCenter (BOOM Interactive)",
    match   = {"recenter","boom recenter"},
    vendor  = "BOOM Library / BOOM Interactive",
    type    = "stereo_centering",
    roles   = {"Stereo","Center Fix","Post","Mix"},

    sections = {
      "CENTERING (ANGLE)",
      "STEREO WIDTH",
      "LOW MONO",
      "MULTIBAND OPTIONS",
    },

    key_params = {
      center_angle = "Zielwinkel der Zentrierung",
      width        = "Stereo-Breite nach Zentrierung",
      low_mono     = "Mono-Frequenzgrenze im Bass",
      bands        = "Multiband-Centering-Konfiguration",
    },
  },

  --------------------------------------------------------------------
  -- PTEq-X (Ignite Amps) – Passive Program EQ
  --------------------------------------------------------------------
  pteq_x = {
    id      = "pteq_x",
    display = "PTEq-X (Ignite Amps)",
    match   = {"pteq%-x","ignite pteq%-x"},
    vendor  = "Ignite Amps",
    type    = "eq_passive_tube_style",
    roles   = {"EQ","Tone","Master","Bus"},

    sections = {
      "LOW BAND (Pultec-Style)",
      "MID BAND",
      "HIGH BAND",
      "ANALOG DRIVE",
      "OUTPUT",
    },

    key_params = {
      low_freq     = "Low-Band Frequenz",
      low_boost    = "Low-Boost",
      low_cut      = "Low-Cut",
      mid_freq     = "Mid-Band Frequenz",
      mid_gain     = "Mid-Gain",
      high_freq    = "High-Band Frequenz",
      high_boost   = "High-Boost",
      output_gain  = "Output Level",
    },
  },

  --------------------------------------------------------------------
  -- Rare (AnalogObsession) – Pultec Tube EQ
  --------------------------------------------------------------------
  rare_eq = {
    id      = "rare_eq",
    display = "Rare (Analog Obsession)",
    match   = {"rare %(analog obsession%)","analog obsession rare"},
    vendor  = "Analog Obsession",
    type    = "eq_pultec_style",
    roles   = {"EQ","Tone","Low-End","Master","Bus"},

    sections = {
      "LOW BAND (Boost/Cut)",
      "HIGH BAND (Boost)",
      "HIGH SHELF (Attenuation)",
      "M/S oder L/R MODES (je nach Version)",
    },

    key_params = {
      low_freq     = "Low-Frequenz",
      low_boost    = "Low-Boost",
      low_cut      = "Low-Cut",
      high_freq    = "High-Boost-Frequenz",
      high_boost   = "High-Boost",
      high_att     = "High-Attenuation",
    },
  },

  --------------------------------------------------------------------
  -- MERICA (AnalogObsession) – Vintage Console EQ
  --------------------------------------------------------------------
  merica_eq = {
    id      = "merica_eq",
    display = "MERICA (Analog Obsession)",
    match   = {"merica %(analog obsession%)","analog obsession merica"},
    vendor  = "Analog Obsession",
    type    = "eq_console_american",
    roles   = {"EQ","Tone","Color","Mix"},

    sections = {
      "3-BAND EQ (Proportional-Q)",
      "FIXED FILTER (FL)",
      "OUTPUT / OVERSAMPLING",
    },

    key_params = {
      low_band     = "Low-Band Gain/Frequenz",
      mid_band     = "Mid-Band Gain/Frequenz",
      high_band    = "High-Band Gain/Frequenz",
      fixed_filter = "Fixed Low/High Filter",
      output_gain  = "Output",
    },
  },

  --------------------------------------------------------------------
  -- COMBOX (AnalogObsession) – Mod/FX (Multi)
  --------------------------------------------------------------------
  combox = {
    id      = "combox",
    display = "COMBOX (Analog Obsession)",
    match   = {"combox %(analog obsession%)","analog obsession combox"},
    vendor  = "Analog Obsession",
    type    = "multi_fx_colour",
    roles   = {"Color","Modulation","Saturation","IDM"},

    sections = {
      "PREAMP / DRIVE",
      "FILTER / TONE",
      "MOD / SPECIAL FX",
      "OUTPUT",
    },

    key_params = {
      drive        = "Drive/Sättigung",
      tone         = "Tonale Färbung",
      special_fx   = "Interne Mod-/Special-Parameter",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- CHANNEV (AnalogObsession) – Channel Strip
  --------------------------------------------------------------------
  channev = {
    id      = "channev",
    display = "CHANNEV (Analog Obsession)",
    match   = {"channev %(analog obsession%)","analog obsession channev","channev"},
    vendor  = "Analog Obsession",
    type    = "channel_strip",
    roles   = {"Channel","Vocal","Bus","Mix"},

    sections = {
      "MIC PRE / TRIM / HPF/LPF",
      "DE-ESSER",
      "4-BAND EQ",
      "COMPRESSOR",
      "LIMITER",
      "TAPE SATURATiON",
    },

    key_params = {
      pre_gain     = "Mic/Line Gain",
      hpf_freq     = "Hochpass-Frequenz",
      lpf_freq     = "Tiefpass-Frequenz",
      deess_amount = "De-Esser Intensität",
      eq_bands     = "EQ-Band-Gains/Frequenzen",
      comp_thresh  = "Kompressor-Threshold",
      comp_ratio   = "Kompressor-Ratio",
      limiter      = "Limiter-Level",
      tape_sat     = "Bandsättigung",
    },
  },

  --------------------------------------------------------------------
  -- Shadow Hills Class A Mastering Compressor (Plugin Alliance)
  --------------------------------------------------------------------
  shadow_hills_class_a = {
    id      = "shadow_hills_class_a",
    display = "Shadow Hills Class A Mastering Comp (Plugin Alliance)",
    match   = {"shadow hills mastering compressor class a","shadow hills class a","shadow hills mast. comp. cl. a"},
    vendor  = "Shadow Hills / Plugin Alliance",
    type    = "compressor_mastering_dual_stage",
    roles   = {"Master","Bus","Glue","Color"},

    sections = {
      "OPTICAL COMP",
      "DISCRETE COMP",
      "TRANSFORMER SELECTION (Nickel/Iron/Steel)",
      "STEREO / DUAL MONO / M/S",
      "OUTPUT / HEADROOM",
    },

    key_params = {
      opt_thresh   = "Threshold des optischen Kompressors",
      opt_gain     = "Makeup des optischen Teils",
      disc_thresh  = "Threshold des diskreten Kompressors",
      disc_ratio   = "Ratio des diskreten Kompressors",
      transformer  = "Wahl des Ausgangstransformators (Klangfarbe)",
      headroom     = "Headroom/Gain-Staging-Anpassung",
      output_gain  = "Output Level",
    },
  },



  --------------------------------------------------------------------
  -- Blue Cat's Phaser 3 (Mono)
  --------------------------------------------------------------------
  bluecat_phaser3_mono = {
    id      = "bluecat_phaser3_mono",
    display = "Blue Cat's Phaser 3 (Mono)",
    match   = {"blue cat phaser 3","phaser 3 %(blue cat%)","blue cats phaser 3"},
    vendor  = "Blue Cat Audio",
    type    = "phaser_modulation",
    roles   = {"Phaser","Modulation","IDM","Texture"},

    sections = {
      "STAGES",
      "LFO (RATE/DEPTH)",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      stages       = "Anzahl der Phasenschritte",
      rate         = "LFO-Geschwindigkeit",
      depth        = "LFO-Tiefe",
      feedback     = "Feedback/Resonanz",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blue Cat's Phaser 3 (Stereo)
  --------------------------------------------------------------------
  bluecat_phaser3_stereo = {
    id      = "bluecat_phaser3_stereo",
    display = "Blue Cat's Phaser 3 (Stereo)",
    match   = {"blue cat phaser 3 stereo","phaser 3 stereo %(blue cat%)"},
    vendor  = "Blue Cat Audio",
    type    = "phaser_modulation_stereo",
    roles   = {"Phaser","Stereo","Modulation","IDM","Texture"},

    sections = {
      "STAGES",
      "LFO (RATE/DEPTH)",
      "FEEDBACK",
      "STEREO PHASE / SPREAD",
      "MIX / OUTPUT",
    },

    key_params = {
      stages       = "Anzahl der Phasenschritte",
      rate         = "LFO-Geschwindigkeit",
      depth        = "LFO-Tiefe",
      feedback     = "Feedback/Resonanz",
      stereo_phase = "Phasenversatz zwischen L/R",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blue Cat's Flanger 3 (Mono)
  --------------------------------------------------------------------
  bluecat_flanger3_mono = {
    id      = "bluecat_flanger3_mono",
    display = "Blue Cat's Flanger 3 (Mono)",
    match   = {"blue cat flanger 3","flanger 3 %(blue cat%)"},
    vendor  = "Blue Cat Audio",
    type    = "flanger_modulation",
    roles   = {"Flanger","Modulation","IDM","Texture"},

    sections = {
      "DELAY TIME",
      "LFO (RATE/DEPTH)",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Verzögerungszeit des Flangers",
      rate         = "LFO-Geschwindigkeit",
      depth        = "LFO-Tiefe",
      feedback     = "Feedback-Menge",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blue Cat's Flanger 3 (Stereo)
  --------------------------------------------------------------------
  bluecat_flanger3_stereo = {
    id      = "bluecat_flanger3_stereo",
    display = "Blue Cat's Flanger 3 (Stereo)",
    match   = {"blue cat flanger 3 stereo","flanger 3 stereo %(blue cat%)"},
    vendor  = "Blue Cat Audio",
    type    = "flanger_modulation_stereo",
    roles   = {"Flanger","Stereo","Modulation","IDM","Texture"},

    sections = {
      "DELAY TIME",
      "LFO (RATE/DEPTH)",
      "FEEDBACK",
      "STEREO PHASE / SPREAD",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Verzögerungszeit des Flangers",
      rate         = "LFO-Geschwindigkeit",
      depth        = "LFO-Tiefe",
      feedback     = "Feedback-Menge",
      stereo_phase = "Phasenversatz zwischen L/R",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blue Cat's Chorus 4 (Mono)
  --------------------------------------------------------------------
  bluecat_chorus4_mono = {
    id      = "bluecat_chorus4_mono",
    display = "Blue Cat's Chorus 4 (Mono)",
    match   = {"blue cat chorus 4","chorus 4 %(blue cat%)"},
    vendor  = "Blue Cat Audio",
    type    = "chorus_modulation",
    roles   = {"Chorus","Modulation","IDM","Ambient"},

    sections = {
      "VOICES / DEPTH",
      "LFO (RATE)",
      "DELAY OFFSET",
      "MIX / OUTPUT",
    },

    key_params = {
      voices       = "Anzahl/Intensität der Chor-Stimmen",
      rate         = "LFO-Geschwindigkeit",
      depth        = "Modulationstiefe",
      delay_offset = "Basisdelay des Chorus",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blue Cat's Chorus 4 (Stereo)
  --------------------------------------------------------------------
  bluecat_chorus4_stereo = {
    id      = "bluecat_chorus4_stereo",
    display = "Blue Cat's Chorus 4 (Stereo)",
    match   = {"blue cat chorus 4 stereo","chorus 4 stereo %(blue cat%)"},
    vendor  = "Blue Cat Audio",
    type    = "chorus_modulation_stereo",
    roles   = {"Chorus","Stereo","Modulation","IDM","Ambient"},

    sections = {
      "VOICES / DEPTH",
      "LFO (RATE)",
      "STEREO SPREAD",
      "DELAY OFFSET",
      "MIX / OUTPUT",
    },

    key_params = {
      voices       = "Anzahl/Intensität der Chor-Stimmen",
      rate         = "LFO-Geschwindigkeit",
      depth        = "Modulationstiefe",
      stereo_spread= "Stereo-Verteilung der Stimmen",
      delay_offset = "Basisdelay des Chorus",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Ring Mod
  --------------------------------------------------------------------
  khs_ringmod = {
    id      = "khs_ringmod",
    display = "kHs Ring Mod (Kilohearts)",
    match   = {"khs ring mod","ring mod %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "ringmod_fx",
    roles   = {"Ringmod","Metallic","IDM","Experimental"},

    sections = {
      "CARRIER (TYPE/FREQ)",
      "DEPTH",
      "STEREO SPREAD",
      "MIX / OUTPUT",
    },

    key_params = {
      carrier_type = "Carrier-Typ (Sine/Noise/External)",
      carrier_freq = "Carrier-Frequenz",
      depth        = "Modulationstiefe",
      stereo_spread= "Stereo-Verteilung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Phaser
  --------------------------------------------------------------------
  khs_phaser = {
    id      = "khs_phaser",
    display = "kHs Phaser (Kilohearts)",
    match   = {"khs phaser","phaser %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "phaser_modulation",
    roles   = {"Phaser","Modulation","IDM","Texture"},

    sections = {
      "STAGES",
      "RATE / DEPTH",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      stages       = "Anzahl der Phasenschritte",
      rate         = "LFO-Geschwindigkeit",
      depth        = "LFO-Tiefe",
      feedback     = "Feedback/Resonanz",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Phase Distortion
  --------------------------------------------------------------------
  khs_phase_distortion = {
    id      = "khs_phase_distortion",
    display = "kHs Phase Distortion (Kilohearts)",
    match   = {"khs phase distortion","phase distortion %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "phase_distortion_fx",
    roles   = {"Distortion","Phase","IDM","Sounddesign"},

    sections = {
      "AMOUNT",
      "OFFSET",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      amount       = "Intensität der Phasenverzerrung",
      offset       = "Phasenoffset",
      feedback     = "Feedback-Menge",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Transient Shaper
  --------------------------------------------------------------------
  khs_transient_shaper = {
    id      = "khs_transient_shaper",
    display = "kHs Transient Shaper (Kilohearts)",
    match   = {"khs transient shaper","transient shaper %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "transient_shaper",
    roles   = {"Dynamics","Drums","IDM","Transient"},

    sections = {
      "ATTACK",
      "SUSTAIN",
      "SHAPE / SPEED",
      "MIX / OUTPUT",
    },

    key_params = {
      attack       = "Verstärkung/Absenkung des Attack-Anteils",
      sustain      = "Verstärkung/Absenkung des Sustain-Anteils",
      shape        = "Form/Geschwindigkeit der Hüllkurve",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Tape Stop
  --------------------------------------------------------------------
  khs_tapestop = {
    id      = "khs_tapestop",
    display = "kHs Tape Stop (Kilohearts)",
    match   = {"khs tape stop","tape stop %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "tapestop_fx",
    roles   = {"TapeStop","FX","IDM","Fill"},

    sections = {
      "STOP TIME",
      "START TIME",
      "CURVE",
      "TRIGGER MODE",
    },

    key_params = {
      stop_time    = "Zeit bis zum Stopp",
      start_time   = "Zeit bis zur Normalgeschwindigkeit",
      curve        = "Verlaufskurve (linear/exp/etc.)",
      trigger_mode = "Ablauf-/Trigger-Modus",
    },
  },

  --------------------------------------------------------------------
  -- kHs Shaper
  --------------------------------------------------------------------
  khs_shaper = {
    id      = "khs_shaper",
    display = "kHs Shaper (Kilohearts)",
    match   = {"khs shaper","shaper %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "waveshaper_distortion",
    roles   = {"Distortion","Waveshaper","IDM","Sounddesign"},

    sections = {
      "CURVE EDITOR",
      "DRIVE / INPUT",
      "FILTER / DC BLOCK",
      "MIX / OUTPUT",
    },

    key_params = {
      curve        = "Gestalt der Waveshaper-Kurve",
      drive        = "Input-Drive in den Shaper",
      dc_block     = "DC-Offset-Filter",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Reverb
  --------------------------------------------------------------------
  khs_reverb = {
    id      = "khs_reverb",
    display = "kHs Reverb (Kilohearts)",
    match   = {"khs reverb","reverb %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "reverb_algo",
    roles   = {"Reverb","Space","IDM","Ambient"},

    sections = {
      "SIZE",
      "DECAY",
      "PREDELAY",
      "DAMPING / FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      size         = "Größe des Raums",
      decay        = "Abklingzeit",
      predelay     = "Vorverzögerung",
      damping      = "Höhenbedämpfung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Flanger
  --------------------------------------------------------------------
  khs_flanger = {
    id      = "khs_flanger",
    display = "kHs Flanger (Kilohearts)",
    match   = {"khs flanger","flanger %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "flanger_modulation",
    roles   = {"Flanger","Modulation","IDM","Texture"},

    sections = {
      "DELAY TIME",
      "RATE / DEPTH",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Verzögerungszeit des Flangers",
      rate         = "LFO-Geschwindigkeit",
      depth        = "LFO-Tiefe",
      feedback     = "Feedback-Menge",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Dual Delay
  --------------------------------------------------------------------
  khs_dual_delay = {
    id      = "khs_dual_delay",
    display = "kHs Dual Delay (Kilohearts)",
    match   = {"khs dual delay","dual delay %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "delay_dual",
    roles   = {"Delay","PingPong","IDM","Ambient"},

    sections = {
      "DELAY A (TIME/FEEDBACK)",
      "DELAY B (TIME/FEEDBACK)",
      "CROSSTALK / LINK",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      time_a       = "Delay-Zeit A",
      time_b       = "Delay-Zeit B",
      feedback_a   = "Feedback A",
      feedback_b   = "Feedback B",
      crosstalk    = "Übersprechen zwischen A/B",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Distortion
  --------------------------------------------------------------------
  khs_distortion = {
    id      = "khs_distortion",
    display = "kHs Distortion (Kilohearts)",
    match   = {"khs distortion","distortion %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "distortion_simple",
    roles   = {"Distortion","Drums","Bass","IDM"},

    sections = {
      "MODE",
      "DRIVE",
      "TONE / FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      mode         = "Ausgewählter Distortion-Typ",
      drive        = "Drive/Sättigung",
      tone         = "Tonalität/Filter",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Delay
  --------------------------------------------------------------------
  khs_delay = {
    id      = "khs_delay",
    display = "kHs Delay (Kilohearts)",
    match   = {"khs delay","delay %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "delay_simple",
    roles   = {"Delay","Echo","IDM","Ambient"},

    sections = {
      "TIME (SYNC/FREE)",
      "FEEDBACK",
      "FILTER / TONE",
      "PING-PONG (falls vorhanden)",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Delay-Zeit bzw. synchronisierte Note",
      feedback     = "Feedback-Menge",
      tone         = "Helligkeit/Dunkelheit des Echos",
      pingpong     = "Ping-Pong-Schaltung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Chorus
  --------------------------------------------------------------------
  khs_chorus = {
    id      = "khs_chorus",
    display = "kHs Chorus (Kilohearts)",
    match   = {"khs chorus","chorus %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "chorus_modulation",
    roles   = {"Chorus","Modulation","IDM","Ambient"},

    sections = {
      "RATE / DEPTH",
      "DELAY OFFSET",
      "STEREO SPREAD",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "LFO-Geschwindigkeit",
      depth        = "Modulationstiefe",
      delay_offset = "Basisdelay des Chorus",
      stereo_spread= "Stereo-Verteilung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_delay 2500 (Brainworx)
  --------------------------------------------------------------------
  bx_delay2500 = {
    id      = "bx_delay2500",
    display = "bx_delay 2500 (Brainworx / Plugin Alliance)",
    match   = {"bx_delay 2500","delay 2500 %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "delay_advanced_ms",
    roles   = {"Delay","Ducking","IDM","Drums","FX"},

    sections = {
      "DELAY CORE (TIME/FEEDBACK)",
      "MODULATION / CHORUS",
      "DUCKING",
      "TRANSIENT SHAPER",
      "M/S PROCESSING",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Delay-Zeit (L/R)",
      feedback     = "Feedback-Menge",
      ducking      = "Ducking-Intensität (Sidechain)",
      trans_attack = "Attack-Shaping im Feedbackweg",
      trans_sustain= "Sustain-Shaping im Feedbackweg",
      width        = "Stereo-Breite/M/S-Width",
      mono_maker   = "Mono-Maker für Tiefen",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_boom V3
  --------------------------------------------------------------------
  bx_boom_v3 = {
    id      = "bx_boom_v3",
    display = "bx_boom V3 (Plugin Alliance)",
    match   = {"bx_boom v3","bx boom v3"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "lowend_shaper_kick",
    roles   = {"Kick","Low-End","Mix","IDM"},

    sections = {
      "BOOM AMOUNT",
      "BOOM FREQUENCY",
      "TIGHT PUNCH",
      "MIX / OUTPUT",
    },

    key_params = {
      boom_amount  = "Intensität der Bassanhebung/absenkung",
      boom_freq    = "Ziel-Frequenz des Boom-Filters",
      tight_punch  = "Kontrolle über Punch/Transient der Kick",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_boom (Legacy)
  --------------------------------------------------------------------
  bx_boom = {
    id      = "bx_boom",
    display = "bx_boom (Plugin Alliance)",
    match   = {"bx_boom","bx boom %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "lowend_shaper_kick",
    roles   = {"Kick","Low-End","Mix","IDM"},

    sections = {
      "BOOM AMOUNT",
      "BOOM FREQUENCY",
      "MIX / OUTPUT",
    },

    key_params = {
      boom_amount  = "Intensität der Bassanhebung/absenkung",
      boom_freq    = "Ziel-Frequenz des Boom-Filters",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_bluechorus2
  --------------------------------------------------------------------
  bx_bluechorus2 = {
    id      = "bx_bluechorus2",
    display = "bx_bluechorus2 (Plugin Alliance)",
    match   = {"bx_bluechorus2","bluechorus2 %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "chorus_vintage",
    roles   = {"Chorus","Guitar","Keys","IDM"},

    sections = {
      "RATE / DEPTH",
      "TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Modulationsrate",
      depth        = "Modulationstiefe",
      tone         = "Tonale Färbung (Höhen)",
      mix          = "Blend Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Shadow Hills Mastering Compressor (Standard Version)
  --------------------------------------------------------------------
  shadow_hills_std = {
    id      = "shadow_hills_std",
    display = "Shadow Hills Mastering Compressor (Plugin Alliance)",
    match   = {"shadow hills mastering compressor","shadow hills %(plugin alliance%)"},
    vendor  = "Shadow Hills / Plugin Alliance",
    type    = "compressor_mastering_dual_stage",
    roles   = {"Master","Bus","Glue","Color"},

    sections = {
      "OPTICAL COMP",
      "DISCRETE COMP",
      "TRANSFORMER SELECTION (Nickel/Iron/Steel)",
      "STEREO / DUAL MONO / M/S",
      "OUTPUT / HEADROOM",
    },

    key_params = {
      opt_thresh   = "Threshold des optischen Kompressors",
      opt_gain     = "Makeup des optischen Teils",
      disc_thresh  = "Threshold des diskreten Kompressors",
      disc_ratio   = "Ratio des diskreten Kompressors",
      transformer  = "Wahl des Ausgangstransformators (Klangfarbe)",
      headroom     = "Headroom/Gain-Staging-Anpassung",
      output_gain  = "Output Level",
    },
  },

  --------------------------------------------------------------------
  -- bx_yellowdrive
  --------------------------------------------------------------------
  bx_yellowdrive = {
    id      = "bx_yellowdrive",
    display = "bx_yellowdrive (Plugin Alliance)",
    match   = {"bx_yellowdrive","yellowdrive %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "overdrive_pedal",
    roles   = {"Overdrive","Guitar","Bass","IDM"},

    sections = {
      "GAIN",
      "TONE",
      "FILTER",
      "OUTPUT",
    },

    key_params = {
      gain         = "Overdrive-Gain",
      tone         = "Tonale Balance (Höhen)",
      hp_filter    = "Hochpass zur Basskontrolle",
      lp_filter    = "Lowpass zur Höhenbegrenzung",
      output_gain  = "Output Level",
    },
  },

  --------------------------------------------------------------------
  -- bx_tuner
  --------------------------------------------------------------------
  bx_tuner = {
    id      = "bx_tuner",
    display = "bx_tuner (Plugin Alliance)",
    match   = {"bx_tuner","bx tuner"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "tuner_utility",
    roles   = {"Utility","Tuner"},

    sections = {
      "TUNER DISPLAY",
      "REFERENCE PITCH",
    },

    key_params = {
      ref_pitch    = "Referenzton (z.B. 440 Hz)",
    },
  },

  --------------------------------------------------------------------
  -- bx_townhouse Buss Compressor
  --------------------------------------------------------------------
  bx_townhouse = {
    id      = "bx_townhouse",
    display = "bx_townhouse Buss Compressor (Plugin Alliance)",
    match   = {"bx_townhouse","townhouse buss compressor"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "compressor_bus",
    roles   = {"Bus","Drums","Mix","Glue"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "HP SIDECHAIN",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Threshold",
      ratio        = "Kompressionsverhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      hp_sc        = "Hochpass im Sidechain",
      mix          = "Dry/Wet (Parallelkompression)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- SC BitCrusher (Stagecraft)
  --------------------------------------------------------------------
  sc_bitcrusher = {
    id      = "sc_bitcrusher",
    display = "SC BitCrusher (Stagecraft)",
    match   = {"sc bitcrusher","stagecraft bitcrusher"},
    vendor  = "Stagecraft",
    type    = "bitcrusher_lofi",
    roles   = {"LoFi","Bitcrusher","IDM","Noise"},

    sections = {
      "BIT DEPTH",
      "SAMPLE RATE",
      "STEREO SPREAD",
      "NOISE FILTER / LFO",
      "MIX / OUTPUT",
    },

    key_params = {
      bit_depth    = "Bitreduzierung",
      sample_rate  = "Sample-Rate-Reduktion",
      stereo_spread= "Stereo-Verteilung",
      noise_filter = "Filter auf das Noise-Signal",
      noise_lfo    = "LFO-Steuerung des Noise-Anteils",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- IO/Phaser (benoit serrano)
  --------------------------------------------------------------------
  io_phaser = {
    id      = "io_phaser",
    display = "IO/Phaser (benoit serrano)",
    match   = {"io/phaser","io phaser","phaser %(benoit serrano%)"},
    vendor  = "benoit serrano",
    type    = "phaser_advanced",
    roles   = {"Phaser","Modulation","IDM","Experimental"},

    sections = {
      "STAGES",
      "RATE / DEPTH",
      "FEEDBACK",
      "STEP/ENV SEQUENCER",
      "MIX / OUTPUT",
    },

    key_params = {
      stages       = "Anzahl der Phaser-Stufen",
      rate         = "LFO-Geschwindigkeit",
      depth        = "Modulationstiefe",
      feedback     = "Feedback/Resonanz",
      step_env     = "Step-Hüllkurve/Sequencer-Einstellungen",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- dblue TapeStop
  --------------------------------------------------------------------
  dblue_tapestop = {
    id      = "dblue_tapestop",
    display = "dblue TapeStop (illformed)",
    match   = {"dblue tapestop","tapestop %(illformed%)"},
    vendor  = "illformed",
    type    = "tapestop_fx",
    roles   = {"TapeStop","Glitch","IDM","FX"},

    sections = {
      "DOWN TIME",
      "UP TIME",
      "CURVE",
      "TRIGGER MODE",
    },

    key_params = {
      down_time    = "Zeit bis zum Stillstand",
      up_time      = "Zeit zurück zur Normalgeschwindigkeit",
      curve        = "Verlaufskurve (linear/exp)",
      trigger_mode = "Trigger-/Play-Mode",
    },
  },

  --------------------------------------------------------------------
  -- dblue Glitch v1.3
  --------------------------------------------------------------------
  dblue_glitch = {
    id      = "dblue_glitch",
    display = "dblue Glitch v1.3 (illformed)",
    match   = {"dblue glitch","glitch v1.3 %(illformed%)","glitch 1.3"},
    vendor  = "illformed",
    type    = "glitch_multifx_sequencer",
    roles   = {"Glitch","FSU","IDM","Breakcore"},

    sections = {
      "EFFECT MODULES (TapeStop, Retrigger, Shuffler, Reverse, Crusher, Gater, Delay, Stretch, Filter)",
      "STEP SEQUENCER",
      "RANDOMIZER",
      "MIX / OUTPUT",
    },

    key_params = {
      module_enable= "Aktive Module im Glitch-Rack",
      step_pattern = "Schrittmuster pro Effektmodul",
      random_amt   = "Randomisierungsgrad der Steps",
      mix          = "Globaler Dry/Wet",
      output_gain  = "Output Gain",
    },
  },



  --------------------------------------------------------------------
  -- CHOW Tape Model (Chowdhury DSP)
  --------------------------------------------------------------------
  chow_tapemodel = {
    id      = "chow_tapemodel",
    display = "CHOW Tape Model (Chowdhury DSP)",
    match   = {"chow tape model","chowtapemodel","chow tape"},
    vendor  = "Chowdhury DSP",
    type    = "tape_emulation_advanced",
    roles   = {"Tape","Saturation","LoFi","IDM","Master","Bus"},

    sections = {
      "INPUT FILTERS (LOW/HIGH CUT)",
      "SATURATION / DRIVE",
      "WOW & FLUTTER / TIME VARIATION",
      "NOISE / HISS",
      "MECHANICAL / DAMAGE CONTROLS",
      "OUTPUT / MIX",
    },

    key_params = {
      low_cut      = "Lowcut-Frequenz des Input-Filters",
      high_cut     = "Highcut-Frequenz des Input-Filters",
      drive        = "Bandsättigung/Drive",
      wow_flutter  = "Zeitvarianz (Wow/Flutter)",
      damage       = "Grad der Degradation/Instabilität",
      noise_level  = "Pegel von Bandrauschen/Hiss",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ReaDelay (Cockos)
  --------------------------------------------------------------------
  readelay = {
    id      = "readelay",
    display = "ReaDelay (Cockos)",
    match   = {"readelay","rea delay %(cockos%)"},
    vendor  = "Cockos",
    type    = "delay_multi_tap",
    roles   = {"Delay","Echo","Utility","IDM"},

    sections = {
      "TAPS (TIME/GAIN/PAN)",
      "FILTERS (LOW/HIGH CUT)",
      "MODULATION",
      "WET/DRY / OUTPUT",
    },

    key_params = {
      tap_time     = "Zeit pro Tap (ms oder sync)",
      tap_gain     = "Pegel pro Tap",
      tap_pan      = "Panorama pro Tap",
      feedback     = "Globales Feedback",
      low_cut      = "Lowcut-Filter",
      high_cut     = "Highcut-Filter",
      modulation   = "Modulation der Delay-Zeit",
      wet          = "Wet-Level",
      dry          = "Dry-Level",
    },
  },

  --------------------------------------------------------------------
  -- GlitchShaper (Cableguys ShaperBox)
  --------------------------------------------------------------------
  glitchshaper = {
    id      = "glitchshaper",
    display = "GlitchShaper (Cableguys / ShaperBox)",
    match   = {"glitchshaper","glitch shaper","shaperbox glitchshaper"},
    vendor  = "Cableguys",
    type    = "time_glitch_shaper",
    roles   = {"Glitch","Stutter","FSU","IDM"},

    sections = {
      "WAVE/GRID EDITOR",
      "TIME SLICE / REPEAT",
      "DIRECTION (REVERSE/FORWARD)",
      "FILTER / DISTORTION (falls aktiv)",
      "MIX / OUTPUT",
    },

    key_params = {
      pattern      = "Zeichen- oder Grid-Muster für Glitch",
      slice_len    = "Länge der Zeitsegmente",
      repeat_amt   = "Anzahl Wiederholungen/Stutters",
      reverse_prob = "Wahrscheinlichkeit für Reverse-Slices",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- FoldShaper (Uhhyou / FoldShaper Pack)
  --------------------------------------------------------------------
  foldshaper = {
    id      = "foldshaper",
    display = "FoldShaper (Uhhyou)",
    match   = {"foldshaper","fold shaper"},
    vendor  = "Uhhyou",
    type    = "waveshaper_fold",
    roles   = {"Waveshaper","Fold","Distortion","IDM"},

    sections = {
      "SHAPE / CURVE",
      "DRIVE / INPUT",
      "OVERSAMPLING",
      "MIX / OUTPUT",
    },

    key_params = {
      fold_amount  = "Intensität der Faltungsverzerrung",
      curve        = "Verlaufsform der Waveshaper-Kurve",
      drive        = "Eingangspegel/Drive",
      oversampling = "Oversampling-Faktor",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Flux Reverse (Generic Reverse FX)
  --------------------------------------------------------------------
  flux_reverse = {
    id      = "flux_reverse",
    display = "Flux Reverse (Reverse Buffer FX)",
    match   = {"flux reverse","reverse fx"},
    vendor  = "Unknown/Generic",
    type    = "reverse_buffer_fx",
    roles   = {"Reverse","Glitch","IDM","FX"},

    sections = {
      "BUFFER LENGTH",
      "SYNC / FREE",
      "FADE IN/OUT",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_len   = "Länge des Audiobuffers für den Reverse-Effekt",
      sync_mode    = "Host-Tempo-Sync oder freie Zeit",
      fade         = "Ein-/Ausblendzeit zur Artefaktreduzierung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- FireFly Flanger (Generic Mod FX)
  --------------------------------------------------------------------
  firefly_flanger = {
    id      = "firefly_flanger",
    display = "FireFly Flanger",
    match   = {"firefly flanger","firefly_flanger"},
    vendor  = "Unknown/Generic",
    type    = "flanger_modulation",
    roles   = {"Flanger","Modulation","IDM","Texture"},

    sections = {
      "DELAY TIME",
      "RATE / DEPTH",
      "FEEDBACK",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Basis-Delayzeit des Flangers",
      rate         = "Modulationsrate",
      depth        = "Modulationstiefe",
      feedback     = "Feedback-Menge",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Cymatics Space (Reverb)
  --------------------------------------------------------------------
  cymatics_space = {
    id      = "cymatics_space",
    display = "Cymatics Space (Reverb)",
    match   = {"cymatics space","space reverb %(cymatics%)"},
    vendor  = "Cymatics",
    type    = "reverb_modulated",
    roles   = {"Reverb","Space","IDM","Ambient"},

    sections = {
      "REVERB CORE (SIZE/DECAY)",
      "MOD FX (Pitch/Chorus/Flanger/Phaser)",
      "PREDELAY",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      size         = "Größe des virtuellen Raums",
      decay        = "Abklingzeit",
      predelay     = "Vorverzögerung",
      mod_mode     = "Ausgewählter Mod-Effekt (Pitch/Chorus/Flanger/Phaser)",
      mod_depth    = "Intensität der Modulation",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Cymatics Origin (Vintage FX)
  --------------------------------------------------------------------
  cymatics_origin = {
    id      = "cymatics_origin",
    display = "Cymatics Origin (Vintage FX)",
    match   = {"cymatics origin","origin %(cymatics%)"},
    vendor  = "Cymatics",
    type    = "vintage_multifx",
    roles   = {"LoFi","Vintage","Texture","IDM"},

    sections = {
      "RESAMPLER (SAMPLE RATE)",
      "FILTER",
      "SATURATION",
      "MOVEMENT (MOD)",
      "NOISE / CHORUS",
      "MIX / OUTPUT",
    },

    key_params = {
      resampler    = "Sample-Rate-Reduktion / Downsampling",
      filter       = "Filter-Cutoff/Resonanz",
      saturation   = "Sättigungsanteil",
      movement     = "Bewegungs-/Modulationsparameter",
      noise_level  = "Noise-Pegel",
      chorus_amt   = "Chorus-Anteil",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Cymatics Diabolo (Drum Enhancer / Distortion)
  --------------------------------------------------------------------
  cymatics_diabolo = {
    id      = "cymatics_diabolo",
    display = "Cymatics Diablo/Diabolo (Drum Enhancer)",
    match   = {"cymatics diabolo","cymatics diablo","diablo drum enhancer"},
    vendor  = "Cymatics",
    type    = "drum_enhancer_distortion",
    roles   = {"Drums","808","Punch","IDM"},

    sections = {
      "PUNCH / TRANSIENT",
      "BODY / WEIGHT",
      "CLIP / HARD CLIPPER",
      "WIDTH",
      "FILTER / EQ",
      "OUTPUT",
    },

    key_params = {
      punch        = "Transienten-/Punch-Regler",
      body         = "Körper/Low-Mid-Fülle",
      clip         = "Clip-/Ceiling-Intensität",
      width        = "Stereo-Breite",
      filter_eq    = "Filter-/EQ-Formung vor dem Clipper",
      output_gain  = "Output Level",
    },
  },

  --------------------------------------------------------------------
  -- Cassette Transport (Wavesfactory)
  --------------------------------------------------------------------
  cassette_transport = {
    id      = "cassette_transport",
    display = "Cassette Transport (Wavesfactory)",
    match   = {"cassette transport","wavesfactory cassette transport"},
    vendor  = "Wavesfactory",
    type    = "tapestop_transport_fx",
    roles   = {"TapeStop","LoFi","IDM","FX"},

    sections = {
      "PLAY/STOP TIME",
      "SYNC / FREE",
      "BUTTON/MECHANICAL NOISE",
      "MIX / OUTPUT",
    },

    key_params = {
      play_time    = "Zeit bis zur Nenngeschwindigkeit",
      stop_time    = "Zeit bis zum Stillstand",
      sync_mode    = "Host-Tempo-Sync oder freie Zeit",
      mech_noise   = "Lautstärke der mechanischen Geräusche",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Caelum Audio Tape Pro
  --------------------------------------------------------------------
  caelum_tape_pro = {
    id      = "caelum_tape_pro",
    display = "Tape Pro (Caelum Audio)",
    match   = {"tape pro %(caelum audio%)","caelum audio tape pro"},
    vendor  = "Caelum Audio",
    type    = "tape_multifx",
    roles   = {"Tape","Saturation","Delay","LoFi","IDM"},

    sections = {
      "SATURATION MODULE",
      "RESPONSE / EQ",
      "NOISE MODULE",
      "WOW & FLUTTER",
      "DELAY ENGINE",
      "MIX / OUTPUT",
    },

    key_params = {
      sat_amount   = "Bandsättigungsintensität",
      response     = "Frequenzgang/Tonbalance",
      noise_level  = "Bandrauschen/Noise-Anteil",
      wow_flutter  = "Wow/Flutter (Tonhöhen-/Zeitmodulation)",
      delay_time   = "Delay-Zeit im Tape-Delay-Modul",
      feedback     = "Feedback im Delay",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ToneBoosters BitJuggler
  --------------------------------------------------------------------
  bitjuggler = {
    id      = "bitjuggler",
    display = "BitJuggler (ToneBoosters)",
    match   = {"bitjuggler","tb bitjuggler","toneboosters bitjuggler"},
    vendor  = "ToneBoosters",
    type    = "digital_degrade_bitcrusher",
    roles   = {"Bitcrusher","Digital","LoFi","IDM"},

    sections = {
      "DIGITAL FORMAT (BIT DEPTH/SR)",
      "ALIASING / JITTER",
      "NOISE / DITHER",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      bit_depth    = "Effektive Bit-Tiefe",
      sample_rate  = "Effektive Sample-Rate",
      alias        = "Aliasing-/Imperfektionsparameter",
      jitter       = "Clock-Jitter/Timingfehler",
      noise        = "Digitales Rauschen/Dither",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Baby Audio Spaced Out
  --------------------------------------------------------------------
  spaced_out = {
    id      = "spaced_out",
    display = "Spaced Out (Baby Audio)",
    match   = {"spaced out","baby audio spaced out"},
    vendor  = "Baby Audio",
    type    = "reverb_delay_mod_wetfx",
    roles   = {"Reverb","Delay","Modulation","IDM","Ambient"},

    sections = {
      "SPACE (REVERB PROGRAMS)",
      "ECHO GRID (DELAY)",
      "MODULATION",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      space_prog   = "Ausgewähltes Reverb-Programm/Layout",
      reverb_time  = "Reverb-Zeit/Size",
      echo_pattern = "Verteilung der Delays im Grid",
      feedback     = "Feedback-Menge",
      mod_depth    = "Modulationstiefe",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- TAL-Chorus-LX
  --------------------------------------------------------------------
  tal_chorus_lx = {
    id      = "tal_chorus_lx",
    display = "TAL-Chorus-LX (Togu Audio Line)",
    match   = {"tal-chorus-lx","tal chorus lx"},
    vendor  = "TAL (Togu Audio Line)",
    type    = "chorus_vintage_juno",
    roles   = {"Chorus","Vintage","Synth","IDM","Ambient"},

    sections = {
      "MODE I / MODE II",
      "STEREO WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      mode_i       = "Chorus-Modus I (subtil)",
      mode_ii      = "Chorus-Modus II (stärker)",
      stereo_width = "Stereo-Breite des Chorus",
      mix          = "Dry/Wet (falls vorhanden)",
      output_gain  = "Output Gain",
    },
  },

--------------------------------------------------------------------
-- Beat Slammer – Drum / Bus Compressor
--------------------------------------------------------------------
beat_slammer = {
  id      = "beat_slammer",
  display = "Beat Slammer",
  match   = {"Beat Slammer","BeatSlammer"},
  vendor  = "Various",
  type    = "compressor",
  roles   = {"Drums","Bus","Parallel","IDM","Glue"},
},

--------------------------------------------------------------------
-- Transperc – Transient Shaper for Percussion
--------------------------------------------------------------------
transperc = {
  id      = "transperc",
  display = "Transperc",
  match   = {"Transperc","transperc"},
  vendor  = "Apisonic Labs",
  type    = "transient_shaper",
  roles   = {"Drums","Percussion","Transient","Snap","Free"},
},

--------------------------------------------------------------------
-- Digital Drum Compressor (JSFX)
--------------------------------------------------------------------
js_digital_drum_comp = {
  id      = "js_digital_drum_comp",
  display = "JS: Digital Drum Compressor",
  match   = {"Digital Drum Compressor","digital_drum_comp"},
  vendor  = "Cockos",
  type    = "compressor",
  roles   = {"JSFX","Drums","Bus","Smash"},
},

--------------------------------------------------------------------
-- 50 Hz Kicker (JSFX)
--------------------------------------------------------------------
js_50hz_kicker = {
  id      = "js_50hz_kicker",
  display = "JS: 50 Hz Kicker",
  match   = {"50 Hz Kicker","50Hz Kicker","50hz_kicker"},
  vendor  = "Cockos",
  type    = "lowend_enhancer",
  roles   = {"JSFX","Kick","Sub","LowEnd"},
},

--------------------------------------------------------------------
-- Major Tom / Master Tom Compressors (JSFX)
--------------------------------------------------------------------
js_major_tom = {
  id      = "js_major_tom",
  display = "JS: Major Tom Compressor",
  match   = {"Major Tom Compressor","major_tom"},
  vendor  = "Cockos",
  type    = "compressor",
  roles   = {"JSFX","Drums","Bus"},
},

js_master_tom = {
  id      = "js_master_tom",
  display = "JS: Master Tom Compressor",
  match   = {"Master Tom Compressor","master_tom"},
  vendor  = "Cockos",
  type    = "compressor",
  roles   = {"JSFX","Drums","Bus"},
},

--------------------------------------------------------------------
-- Thunderkick (JSFX) – Kick Enhancer
--------------------------------------------------------------------
js_thunderkick = {
  id      = "js_thunderkick",
  display = "JS: Thunderkick",
  match   = {"Thunderkick","thunderkick"},
  vendor  = "Cockos",
  type    = "kick_enhancer",
  roles   = {"JSFX","Kick","Drums","Sub"},
},

--------------------------------------------------------------------
-- Audio To MIDI Drum Trigger (JSFX)
--------------------------------------------------------------------
js_audio_to_midi_drum = {
  id      = "js_audio_to_midi_drum",
  display = "JS: Audio To MIDI Drum Trigger",
  match   = {"Audio To MIDI Drum Trigger","audio_to_midi_drum"},
  vendor  = "Cockos",
  type    = "drum_trigger",
  roles   = {"JSFX","Drums","Utility","Trigger"},
},

--------------------------------------------------------------------
-- DrumSlam / Overheads / OrbitKick (airwindows)
--------------------------------------------------------------------
airwindows_drums_slam = {
  id      = "airwindows_drums_slam",
  display = "DrumSlam (airwindows)",
  match   = {"DrumSlam","drumslam"},
  vendor  = "airwindows",
  type    = "compressor",
  roles   = {"Drums","Bus","Smash","Free"},
},

airwindows_overheads = {
  id      = "airwindows_overheads",
  display = "Overheads (airwindows)",
  match   = {"Overheads %(airwindows%)","Overheads","overheads"},
  vendor  = "airwindows",
  type    = "drum_room",
  roles   = {"Drums","Room","Overheads","Free"},
},

airwindows_orbitkick = {
  id      = "airwindows_orbitkick",
  display = "OrbitKick (airwindows)",
  match   = {"OrbitKick","orbitkick"},
  vendor  = "airwindows",
  type    = "kick_tool",
  roles   = {"Kick","Drums","LowEnd","Free"},
},

}

return M
