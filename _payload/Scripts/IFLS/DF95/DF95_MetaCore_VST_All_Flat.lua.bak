-- @description MetaCore VST All (Standalone Full Definition)
-- @version 2.0
-- @author DF95
-- @about
--   Vollständige, eigenständige MetaCore-Datei mit allen bekannten
--   DF95 VST/FX-Definitionen (Ext v3–v6) und allen VSTi/Synthesizer-
--   Metadaten aus SynthMetaCore_VSTi_v1. Es werden keine weiteren
--   Module mehr per require() benötigt.
--
--   Rückgabestruktur:
--     local MetaCore = require("IfeelLikeSnow.DF95.DF95_MetaCore_VST_All_Flat")
--     MetaCore.vst  – FX/VST-Plugins
--     MetaCore.vsti – Instrumente/Synths
--
--   Hinweis:
--     Diese Datei wurde automatisch aus den Einzelmodulen erzeugt
--     (inkl. einer rekonstruierten Ext_v3-Definition).
--
-- V2 migration: avoid legacy namespace require("IfeelLikeSnow.*")
-- Load modules directly from IFLS/DF95 path (portable, no package.path dependency)
local __df95_base = reaper.GetResourcePath():gsub("\\","/")
local function __df95_dofile(rel)
  local full = __df95_base .. rel
  local ok, res = pcall(dofile, full)
  if not ok then
    reaper.ShowMessageBox("Konnte Modul nicht laden:\n" .. tostring(full) .. "\n\nFehler:\n" .. tostring(res),
                          "DF95 MetaCore Loader", 0)
    return nil
  end
  return res
end

__df95_dofile("/Scripts/IFLS/DF95/DF95_MetaCore_VST_All_vst.lua")
__df95_dofile("/Scripts/IFLS/DF95/DF95_MetaCore_VST_All_vsti.lua")
local MetaCore = {



  --------------------------------------------------------------------
  -- MERGED EXT ENTRIES
  --------------------------------------------------------------------
--------------------------------------------------------------------
  -- kHs Trance Gate
  --------------------------------------------------------------------
  khs_trance_gate = {
    id      = "khs_trance_gate",
    display = "kHs Trance Gate (Kilohearts)",
    match   = {"khs trance gate","trance gate %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "gate_step_sequencer",
    roles   = {"Gate","Rhythm","IDM","Stutter"},

    sections = {
      "STEP GRID",
      "GATE LENGTH",
      "SWING / GROOVE",
      "SMOOTHING",
      "MIX / OUTPUT",
    },

    key_params = {
      step_length  = "Raster der Steps (z.B. 1/8, 1/16, 1/32)",
      gate_length  = "Gate-Länge pro Step",
      swing        = "Timing-Verschiebung/Swing",
      smoothing    = "Weichzeichnen der Gates (um Klicks zu reduzieren)",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Stereo
  --------------------------------------------------------------------
  khs_stereo = {
    id      = "khs_stereo",
    display = "kHs Stereo (Kilohearts)",
    match   = {"khs stereo","stereo %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "stereo_tool",
    roles   = {"Stereo","Width","MS","Utility"},

    sections = {
      "WIDTH",
      "MID/SIDE BALANCE",
      "L/R SWAP / PHASE",
      "OUTPUT",
    },

    key_params = {
      width        = "Stereo-Breite",
      mid_gain     = "Pegel des Mid-Signals",
      side_gain    = "Pegel des Side-Signals",
      lr_swap      = "Links/Rechts vertauschen",
      phase_flip   = "Phaseninvertierung für L/R",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Resonator
  --------------------------------------------------------------------
  khs_resonator = {
    id      = "khs_resonator",
    display = "kHs Resonator (Kilohearts)",
    match   = {"khs resonator","resonator %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "resonator_tonal",
    roles   = {"Resonator","Tonal","IDM","Texture"},

    sections = {
      "TUNE / PITCH",
      "RESONANCE / DECAY",
      "FILTER MODE",
      "STEREO SPREAD",
      "MIX / OUTPUT",
    },

    key_params = {
      tune         = "Stimmung/Tonhöhe des Resonators",
      decay        = "Abklingzeit/Resonanz",
      mode         = "Filter-/Resonanzmodus",
      stereo_spread= "Stereo-Verteilung der Resonanzen",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Pitch Shifter
  --------------------------------------------------------------------
  khs_pitch_shifter = {
    id      = "khs_pitch_shifter",
    display = "kHs Pitch Shifter (Kilohearts)",
    match   = {"khs pitch shifter","pitch shifter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "pitch_shifter",
    roles   = {"Pitch","FX","IDM","Vocal FX"},

    sections = {
      "SEMITONES",
      "CENTS / FINE",
      "GRAIN / QUALITY",
      "DELAY / LATENCY",
      "MIX / OUTPUT",
    },

    key_params = {
      semitones    = "Grobe Tonhöhenverschiebung in Halbtönen",
      cents        = "Feinabstimmung in Cents",
      grain_size   = "Größe der Time-Grains",
      delay        = "Latenz/Lookahead",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Nonlinear Filter
  --------------------------------------------------------------------
  khs_nonlinear_filter = {
    id      = "khs_nonlinear_filter",
    display = "kHs Nonlinear Filter (Kilohearts)",
    match   = {"khs nonlinear filter","nonlinear filter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "filter_nonlinear",
    roles   = {"Filter","Distortion","IDM","FSU"},

    sections = {
      "FILTER MODE",
      "CUTOFF / RESONANCE",
      "DRIVE / CHARACTER",
      "MIX / OUTPUT",
    },

    key_params = {
      mode         = "Filter- und Nichtlinearitätsmodus",
      cutoff       = "Grenzfrequenz des Filters",
      resonance    = "Resonanzintensität",
      drive        = "Drive/Sättigung in der Filterstufe",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Limiter
  --------------------------------------------------------------------
  khs_limiter = {
    id      = "khs_limiter",
    display = "kHs Limiter (Kilohearts)",
    match   = {"khs limiter","limiter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "limiter_simple",
    roles   = {"Limiter","Safety","Utility","IDM"},

    sections = {
      "THRESHOLD / CEILING",
      "RELEASE",
      "LOOKAHEAD",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Einsatzschwelle des Limiters",
      ceiling      = "Maximaler Ausgangspegel",
      release      = "Release-Zeit",
      lookahead    = "Lookahead-Zeit",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Ladder Filter
  --------------------------------------------------------------------
  khs_ladder_filter = {
    id      = "khs_ladder_filter",
    display = "kHs Ladder Filter (Kilohearts)",
    match   = {"khs ladder filter","ladder filter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "filter_ladder",
    roles   = {"Filter","Analog","IDM","Synth"},

    sections = {
      "CUTOFF / RESONANCE",
      "DRIVE",
      "KEYTRACK",
      "MIX / OUTPUT",
    },

    key_params = {
      cutoff       = "Grenzfrequenz",
      resonance    = "Resonanzintensität",
      drive        = "Drive durch die Ladder-Stufe",
      keytrack     = "Tonhöhenabhängige Cutoff-Verschiebung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Haas
  --------------------------------------------------------------------
  khs_haas = {
    id      = "khs_haas",
    display = "kHs Haas (Kilohearts)",
    match   = {"khs haas","haas %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "stereo_haas",
    roles   = {"Stereo","Width","Psychoacoustic","IDM"},

    sections = {
      "DELAY OFFSET",
      "STEREO BALANCE",
      "MONO COMPAT",
      "MIX / OUTPUT",
    },

    key_params = {
      delay        = "L/R-Verzögerungsunterschied (Haas-Effekt)",
      balance      = "Balance der Seiten",
      mono_compat  = "Mono-Kompatibilitätsanpassungen",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Gate
  --------------------------------------------------------------------
  khs_gate = {
    id      = "khs_gate",
    display = "kHs Gate (Kilohearts)",
    match   = {"khs gate","gate %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "gate_noise",
    roles   = {"Gate","Dynamics","Utility","IDM"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / HOLD / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Einsatzschwelle des Gates",
      ratio        = "Gate-Verhältnis",
      attack       = "Attack-Zeit",
      hold         = "Hold-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Gain
  --------------------------------------------------------------------
  khs_gain = {
    id      = "khs_gain",
    display = "kHs Gain (Kilohearts)",
    match   = {"khs gain","gain %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "gain_utility",
    roles   = {"Gain","Utility","CV","Routing"},

    sections = {
      "GAIN",
      "INVERT / MUTE",
      "OUTPUT",
    },

    key_params = {
      gain         = "Verstärkung/Abschwächung",
      invert       = "Phasenumkehr",
      mute         = "Stummschaltung",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Frequency Shifter
  --------------------------------------------------------------------
  khs_frequency_shifter = {
    id      = "khs_frequency_shifter",
    display = "kHs Frequency Shifter (Kilohearts)",
    match   = {"khs frequency shifter","frequency shifter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "frequency_shifter",
    roles   = {"Freq-Shift","Metallic","IDM","Experimental"},

    sections = {
      "SHIFT AMOUNT",
      "FINE / OFFSET",
      "STEREO SHIFT",
      "MIX / OUTPUT",
    },

    key_params = {
      shift        = "Frequenzverschiebung in Hz",
      fine         = "Feineinstellung des Shifts",
      stereo_shift = "Unterschiedliche Shifts für L/R",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Formant Filter
  --------------------------------------------------------------------
  khs_formant_filter = {
    id      = "khs_formant_filter",
    display = "kHs Formant Filter (Kilohearts)",
    match   = {"khs formant filter","formant filter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "filter_formant",
    roles   = {"Formant","Vocal","IDM","Texture"},

    sections = {
      "VOWEL MORPH",
      "FORMANT SHIFT",
      "RESONANCE",
      "MIX / OUTPUT",
    },

    key_params = {
      vowel        = "Vokal-Morphing (A/E/I/O/U)",
      shift        = "Formant-Verschiebung",
      resonance    = "Resonanzintensität",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Filter
  --------------------------------------------------------------------
  khs_filter = {
    id      = "khs_filter",
    display = "kHs Filter (Kilohearts)",
    match   = {"khs filter","filter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "filter_basic",
    roles   = {"Filter","Tone","Utility","IDM"},

    sections = {
      "MODE (LP/BP/HP)",
      "CUTOFF / RESONANCE",
      "DRIVE",
      "MIX / OUTPUT",
    },

    key_params = {
      mode         = "Filtermodus (Low/High/Band)",
      cutoff       = "Grenzfrequenz",
      resonance    = "Resonanzintensität",
      drive        = "Drive/Sättigung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Ensemble
  --------------------------------------------------------------------
  khs_ensemble = {
    id      = "khs_ensemble",
    display = "kHs Ensemble (Kilohearts)",
    match   = {"khs ensemble","ensemble %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "ensemble_modulation",
    roles   = {"Chorus","Ensemble","IDM","Ambient"},

    sections = {
      "VOICES",
      "RATE / DEPTH",
      "STEREO WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      voices       = "Anzahl/Intensität der Stimmen",
      rate         = "Modulationsrate",
      depth        = "Modulationstiefe",
      stereo_width = "Stereo-Breite",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Dynamics
  --------------------------------------------------------------------
  khs_dynamics = {
    id      = "khs_dynamics",
    display = "kHs Dynamics (Kilohearts)",
    match   = {"khs dynamics","dynamics %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "dynamics_multiband_light",
    roles   = {"Dynamics","Bus","Drums","IDM"},

    sections = {
      "BAND SPLIT",
      "THRESHOLD / RATIO pro Band",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      crossover    = "Trennfrequenzen der Bänder",
      threshold    = "Schwellwert der Dynamikbearbeitung",
      ratio        = "Verhältnis (Kompression/Expansion)",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Compressor
  --------------------------------------------------------------------
  khs_compressor = {
    id      = "khs_compressor",
    display = "kHs Compressor (Kilohearts)",
    match   = {"khs compressor","compressor %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "compressor_basic",
    roles   = {"Compressor","Drums","Bus","IDM"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "KNEE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Threshold",
      ratio        = "Kompressionsverhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      knee         = "Knee-Weichheit",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Comb Filter
  --------------------------------------------------------------------
  khs_comb_filter = {
    id      = "khs_comb_filter",
    display = "kHs Comb Filter (Kilohearts)",
    match   = {"khs comb filter","comb filter %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "filter_comb",
    roles   = {"Comb","Resonator","IDM","Texture"},

    sections = {
      "FREQUENCY",
      "FEEDBACK",
      "DAMPING",
      "MIX / OUTPUT",
    },

    key_params = {
      freq         = "Grundfrequenz des Comb-Filters",
      feedback     = "Feedback/Resonanz",
      damping      = "Dämpfung der hohen Frequenzen",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Clipper
  --------------------------------------------------------------------
  khs_clipper = {
    id      = "khs_clipper",
    display = "kHs Clipper (Kilohearts)",
    match   = {"khs clipper","clipper %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "clipper",
    roles   = {"Clipper","Limiter","IDM","Drums"},

    sections = {
      "CEILING",
      "SHAPE / HARD/SOFT",
      "MIX / OUTPUT",
    },

    key_params = {
      ceiling      = "Maximaler Pegel vor Clipping",
      shape        = "Charakter (hart/weich)",
      mix          = "Dry/Wet (Parallel-Clipping)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs Channel Mixer
  --------------------------------------------------------------------
  khs_channel_mixer = {
    id      = "khs_channel_mixer",
    display = "kHs Channel Mixer (Kilohearts)",
    match   = {"khs channel mixer","channel mixer %(kilohearts%)"},
    vendor  = "Kilohearts",
    type    = "channel_utility",
    roles   = {"Routing","Stereo","Utility","IDM"},

    sections = {
      "CHANNEL ROUTING",
      "GAIN / BALANCE",
      "PHASE",
      "OUTPUT",
    },

    key_params = {
      routing      = "Routing-Modus für Kanäle",
      gain         = "Gesamtpegel",
      balance      = "L/R-Balance",
      phase_flip   = "Phaseninvertierung einzelner Kanäle",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- kHs 3-Band EQ
  --------------------------------------------------------------------
  khs_eq3band = {
    id      = "khs_eq3band",
    display = "kHs 3-Band EQ (Kilohearts)",
    match   = {"khs 3-band eq","3 band eq %(kilohearts%)","khs 3 band eq"},
    vendor  = "Kilohearts",
    type    = "eq_3band",
    roles   = {"EQ","Tone","Utility","IDM"},

    sections = {
      "LOW GAIN",
      "MID GAIN",
      "HIGH GAIN",
      "OUTPUT",
    },

    key_params = {
      low_gain     = "Anhebung/Absenkung des Tiefenbereichs",
      mid_gain     = "Anhebung/Absenkung des Mittenbereichs",
      high_gain    = "Anhebung/Absenkung des Höhenbereichs",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_subsynth
  --------------------------------------------------------------------
  bx_subsynth = {
    id      = "bx_subsynth",
    display = "bx_subsynth (Plugin Alliance)",
    match   = {"bx_subsynth","bx subsynth","subsynth %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "subharmonic_synth",
    roles   = {"Sub","Bass","Kick","IDM"},

    sections = {
      "SUB GENERATOR",
      "FOCUS FREQ",
      "DRIVE / SATURATION",
      "FILTER / HP",
      "MIX / OUTPUT",
    },

    key_params = {
      sub_level    = "Pegel der erzeugten Subharmonischen",
      focus_freq   = "Frequenzbereich, aus dem Sub gewonnen wird",
      drive        = "Drive/Sättigung",
      hp_filter    = "Hochpass zur Aufräumung des Subbereichs",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_subfilter
  --------------------------------------------------------------------
  bx_subfilter = {
    id      = "bx_subfilter",
    display = "bx_subfilter (Plugin Alliance)",
    match   = {"bx_subfilter","bx subfilter","subfilter %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "lowend_filter_shaper",
    roles   = {"Sub","Filter","Kick","IDM"},

    sections = {
      "FOCUS FREQ",
      "RESONANCE",
      "TIGHT/LOOSE",
      "OUTPUT",
    },

    key_params = {
      focus_freq   = "Frequenz um die der Bass fokussiert wird",
      resonance    = "Resonanz/Betonung um die Fokusfrequenz",
      tight_loose  = "Charakter/Tightness-Regler",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_stereomaker
  --------------------------------------------------------------------
  bx_stereomaker = {
    id      = "bx_stereomaker",
    display = "bx_stereomaker (Plugin Alliance)",
    match   = {"bx_stereomaker","bx stereomaker","stereomaker %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "stereo_maker",
    roles   = {"Stereo","Width","Mono->Stereo","IDM"},

    sections = {
      "WIDTH / BALANCE",
      "DELAY / SPREAD",
      "MONO MAKER",
      "OUTPUT",
    },

    key_params = {
      width        = "Stereo-Breite des generierten Signals",
      delay        = "Zeitversatz für Stereo-Effekt",
      mono_maker   = "Mono-Filter für tiefe Frequenzen",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_saturator V2
  --------------------------------------------------------------------
  bx_saturator_v2 = {
    id      = "bx_saturator_v2",
    display = "bx_saturator V2 (Plugin Alliance)",
    match   = {"bx_saturator v2","bx saturator v2","saturator v2 %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "saturator_multiband_style",
    roles   = {"Saturation","Color","Bus","IDM"},

    sections = {
      "XL / SATURATION",
      "MID/SIDE CONTROL",
      "TONE / FOUNDATION",
      "OUTPUT",
    },

    key_params = {
      xl_amount    = "Intensität der Sättigung",
      ms_balance   = "M/S-Verteilung der Sättigung",
      foundation   = "Frequenzgewichtung (Low vs High)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_rooMS
  --------------------------------------------------------------------
  bx_rooms = {
    id      = "bx_rooms",
    display = "bx_rooMS (Plugin Alliance)",
    match   = {"bx_rooms","bx rooms","bx_rooms reverb","rooms %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "reverb_room",
    roles   = {"Reverb","Room","Space","IDM"},

    sections = {
      "ROOM MODEL / SIZE",
      "PREDELAY",
      "WIDTH / M/S",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      room_size    = "Größe/Typ des Raums",
      predelay     = "Vorverzögerung",
      width        = "Stereo-Breite/M/S",
      damping      = "Bedämpfung hoher Frequenzen",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_rockrack V3
  --------------------------------------------------------------------
  bx_rockrack_v3 = {
    id      = "bx_rockrack_v3",
    display = "bx_rockrack V3 (Plugin Alliance)",
    match   = {"bx_rockrack v3","bx rockrack v3","rockrack v3 %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "amp_sim_guitar",
    roles   = {"Amp","Guitar","Distortion","IDM"},

    sections = {
      "AMP MODEL / CHANNEL",
      "GAIN / MASTER",
      "EQ SECTION",
      "CAB / MIC",
      "OUTPUT",
    },

    key_params = {
      amp_model    = "Ausgewählter Amp-Typ/Kanal",
      gain         = "Vorstufen-Gain",
      master       = "Endstufen-Lautstärke",
      eq_settings  = "EQ (Bass/Mid/Treble/Presence)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_rockergain100
  --------------------------------------------------------------------
  bx_rockergain100 = {
    id      = "bx_rockergain100",
    display = "bx_rockergain100 (Plugin Alliance)",
    match   = {"bx_rockergain100","bx rockergain100","rockergain 100 %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "amp_sim_highgain",
    roles   = {"Amp","High-Gain","Distortion","IDM"},

    sections = {
      "GAIN / PREAMP",
      "EQ SECTION",
      "MASTER / POWER",
      "NOISE GATE",
      "OUTPUT",
    },

    key_params = {
      gain         = "Verzerrungsgrad",
      eq_settings  = "EQ (Bass/Mid/Treble/etc.)",
      master       = "Gesamtlautstärke",
      gate         = "Noise-Gate-Einstellungen",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_refinement
  --------------------------------------------------------------------
  bx_refinement = {
    id      = "bx_refinement",
    display = "bx_refinement (Plugin Alliance)",
    match   = {"bx_refinement","bx refinement","refinement %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "harshness_tamer",
    roles   = {"Tone","Harsh Control","Master","IDM"},

    sections = {
      "HARSH FILTER",
      "RESONANCE",
      "SATURATION / COLOR",
      "MIX / OUTPUT",
    },

    key_params = {
      harsh_amount = "Stärke der harschen Frequenzreduktion",
      resonance    = "Resonanz der Filterkurve",
      saturation   = "Sättigungsanteil",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_refinement V3 (Alias)
  --------------------------------------------------------------------
  bx_refinement_v3 = {
    id      = "bx_refinement_v3",
    display = "bx_refinement V3 (Plugin Alliance)",
    match   = {"bx_refinement v3","bx refinement v3","refinement v3 %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "harshness_tamer",
    roles   = {"Tone","Harsh Control","Master","IDM"},

    sections = {
      "HARSH FILTER",
      "RESONANCE",
      "SATURATION / COLOR",
      "MIX / OUTPUT",
    },

    key_params = {
      harsh_amount = "Stärke der harschen Frequenzreduktion",
      resonance    = "Resonanz der Filterkurve",
      saturation   = "Sättigungsanteil",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- bx_panEQ
  --------------------------------------------------------------------
  bx_paneq = {
    id      = "bx_paneq",
    display = "bx_panEQ (Plugin Alliance)",
    match   = {"bx_paneq","bx paneq","paneq %(plugin alliance%)"},
    vendor  = "Brainworx / Plugin Alliance",
    type    = "eq_paning",
    roles   = {"EQ","Panning","Stereo","IDM"},

    sections = {
      "BAND FREQ/Gain",
      "PAN PER BAND",
      "WIDTH / Q",
      "OUTPUT",
    },

    key_params = {
      band_freq    = "Frequenz der EQ-Bänder",
      band_gain    = "Anhebung/Absenkung pro Band",
      band_pan     = "Panorama zugeordneter Frequenzbereiche",
      band_q       = "Güte (Q) der Bänder",
      output_gain  = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- MERGED EXT ENTRIES
  --------------------------------------------------------------------
--------------------------------------------------------------------
  -- ValhallaSpaceModulator
  --------------------------------------------------------------------
  valhalla_spacemodulator = {
    id      = "valhalla_spacemodulator",
    display = "ValhallaSpaceModulator (Valhalla DSP)",
    match   = {"valhallaspace", "space modulator", "valhalla space"},
    vendor  = "Valhalla DSP",
    type    = "modulation_fx",
    roles   = {"Flanger","Chorus","Barberpole","IDM","Texture"},

    sections = {
      "ALGORITHM",
      "MODULATION",
      "FEEDBACK",
      "TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      algorithm   = "Auswahl der Modulations-Algorithmen (z.B. Barberpole, TZF etc.)",
      rate        = "Modulationsrate",
      depth       = "Modulationstiefe",
      feedback    = "Feedback-Anteil",
      tone        = "Tonformung/Balance",
      mix         = "Dry/Wet",
      output_gain = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Sinc Vereor
  --------------------------------------------------------------------
  sinc_vereor = {
    id      = "sinc_vereor",
    display = "Sinc Vereor (Noise Engineering)",
    match   = {"sinc vereor","vereor sinc","noise engineering sinc"},
    vendor  = "Noise Engineering",
    type    = "synth_digital",
    roles   = {"Experimental","Digital","Glitch","IDM"},

    sections = {
      "OSCILLATOR",
      "DYNAMICS",
      "MODULATION",
      "TONE / SHAPE",
      "OUTPUT",
    },

    key_params = {
      osc_mode    = "Oszillator-Modus (Sinc Iter abgeleitet)",
      tone        = "Klangformung/Timbre",
      dynamics    = "Dynamik-/Lautstärke-Sektion",
      pitch       = "Grundtonhöhe",
      fine        = "Feinabstimmung",
      mod_amount  = "Modulationsintensität",
    },
  },

  --------------------------------------------------------------------
  -- Virt Vereor
  --------------------------------------------------------------------
  virt_vereor = {
    id      = "virt_vereor",
    display = "Virt Vereor (Noise Engineering)",
    match   = {"virt vereor","noise engineering virt"},
    vendor  = "Noise Engineering",
    type    = "synth_digital_mpe",
    roles   = {"MPE","Expressive","Glitch","IDM"},

    sections = {
      "OSCILLATOR MODES",
      "DYNAMICS",
      "MODULATION",
      "MPE CONTROL",
      "OUTPUT",
    },

    key_params = {
      osc_mode     = "Oszillator-Modus (Virt Iter/MicroFreak inspiriert)",
      timbre       = "Klangfarbe/Timbre",
      shape        = "Wellenform/Shape",
      dynamics     = "Dynamik-Hüllkurve",
      mpe_pressure = "MPE-Pressure-Zuweisungen",
      mpe_slide    = "MPE-Slide/Glide Zuweisungen",
    },
  },

  --------------------------------------------------------------------
  -- Ruina
  --------------------------------------------------------------------
  ruina = {
    id      = "ruina",
    display = "Ruina (Noise Engineering)",
    match   = {"ruina","ruina ne","noise engineering ruina"},
    vendor  = "Noise Engineering",
    type    = "distortion_multi",
    roles   = {"Distortion","FSU","IDM","Industrial"},

    sections = {
      "DRIVE",
      "FOLD / SHAPE",
      "FILTER",
      "DYNAMICS",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Distortion Drive/Intensity",
      fold         = "Waveshaper-/Folding-Anteil",
      shape        = "Charakter/Art der Verzerrung",
      filter       = "Filter-Cutoff/Resonanz",
      dynamics     = "Dynamik-/Kompres­sionsanteil",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- IO RingMod (B. Serrano)
  --------------------------------------------------------------------
  io_ringmod = {
    id      = "io_ringmod",
    display = "IO RingMod (B. Serrano)",
    match   = {"io ring","ringmod io","serrano ring"},
    vendor  = "B. Serrano",
    type    = "ringmod_fx",
    roles   = {"RingMod","AM","Metallic","IDM","Rhythmic"},

    sections = {
      "CARRIER",
      "MODULATION",
      "32-STEP ENVELOPE",
      "FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      carrier_freq   = "Carrier-Frequenz",
      depth          = "Modulationsintensität",
      env_shape      = "32-Step Envelope-Shape",
      lp_filter      = "Lowpass-Filter im Ausgang",
      mix            = "Dry/Wet",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- IO Phaser (B. Serrano)
  --------------------------------------------------------------------
  io_phaser_ext = {
    id      = "io_phaser_ext",
    display = "IO Phaser (B. Serrano)",
    match   = {"io phaser","phaser serrano"},
    vendor  = "B. Serrano",
    type    = "phaser_fx",
    roles   = {"Phaser","Rhythmic","Modulated","IDM"},

    sections = {
      "STAGES (4/8/12)",
      "FEEDBACK",
      "32-STEP ENVELOPE",
      "MODULATION",
      "MIX / OUTPUT",
    },

    key_params = {
      stages        = "Anzahl der Phaser-Stufen",
      feedback      = "Feedback-Menge",
      env_shape     = "Step-Hüllkurve",
      rate          = "Modulationsrate (wenn genutzt)",
      mix           = "Dry/Wet",
      output_gain   = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- gRainbow (StrangeLoops)
  --------------------------------------------------------------------
  grainbow = {
    id      = "grainbow",
    display = "gRainbow (StrangeLoops)",
    match   = {"grainbow","g rainbow","strangeloops grainbow"},
    vendor  = "StrangeLoops",
    type    = "granular_synth",
    roles   = {"Granular","Texture","IDM","Pads","FX"},

    sections = {
      "GRAIN ENGINE",
      "PITCH DETECTION",
      "BUFFER / INPUT",
      "MODULATION",
      "OUTPUT",
    },

    key_params = {
      grain_size     = "Größe der Grains",
      grain_rate     = "Erzeugungsrate der Grains",
      pitch_track    = "Pitch-Tracking-Anteil",
      density        = "Dichte der Grains",
      stereo_spread  = "Stereo-Verteilung",
      output_gain    = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- adc Ring 2 (Audec)
  --------------------------------------------------------------------
  audec_ring2 = {
    id      = "audec_ring2",
    display = "adc Ring 2 (Audec)",
    match   = {"adc ring 2","audec ring 2","adc ring2"},
    vendor  = "Audec",
    type    = "ringmod_fx",
    roles   = {"RingMod","AM","Metallic","IDM"},

    sections = {
      "CARRIER",
      "MOD AMOUNT",
      "STEREO / PHASE",
      "FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      carrier_freq  = "Carrier-Frequenz",
      amount        = "Modulationsstärke",
      phase         = "Phasenoffset",
      filter        = "Filter (Low/Highpass)",
      mix           = "Dry/Wet",
      output_gain   = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Voltage Modular (Synth)
  --------------------------------------------------------------------
  voltage_modular = {
    id      = "voltage_modular",
    display = "Voltage Modular (Cherry Audio)",
    match   = {"voltage modular","cherry modular"},
    vendor  = "Cherry Audio",
    type    = "modular_synth",
    roles   = {"Modular","Experimental","IDM","Hybrid Synth"},

    sections = {
      "MODULE RACK",
      "PATCH CABLES",
      "OSCILLATORS",
      "FILTERS",
      "ENVELOPES / LFOs",
      "SEQUENCERS / RANDOM",
      "OUTPUT",
    },

    key_params = {
      patch_points  = "Audio/CV-Patchpunkte",
      osc_freq      = "Oszillatorfrequenzen",
      filter_cutoff = "Filter-Cutoff",
      lfo_rate      = "LFO-Geschwindigkeit",
      seq_pattern   = "Sequencer-Pattern",
    },
  },

  --------------------------------------------------------------------
  -- Voltage Modular FX
  --------------------------------------------------------------------
  voltage_modular_fx = {
    id      = "voltage_modular_fx",
    display = "Voltage Modular FX (Cherry Audio)",
    match   = {"voltage modular fx","voltage fx","cherry modular fx"},
    vendor  = "Cherry Audio",
    type    = "modular_fx",
    roles   = {"Modular FX","Glitch","IDM","Routing"},

    sections = {
      "INSERT/FX MODULES",
      "PATCH ROUTING",
      "MODULATION SOURCES",
      "FILTER / DISTORTION",
      "OUTPUT",
    },

    key_params = {
      patch_points  = "Audio/CV-Routing innerhalb des FX-Racks",
      fx_chain      = "Aufbau der Effektkette",
      mod_sources   = "LFO/Env/Random-Quellen",
      mix           = "Dry/Wet",
      output_gain   = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- TremODeath
  --------------------------------------------------------------------
  tremodeath = {
    id      = "tremodeath",
    display = "TremODeath (EvilTurtleProductions)",
    match   = {"tremodeath","tremo death"},
    vendor  = "EvilTurtleProductions",
    type    = "tremolo_autopan",
    roles   = {"Tremolo","AutoPan","Rhythmic","IDM"},

    sections = {
      "RATE",
      "DEPTH",
      "WAVEFORM",
      "STEREO / PAN MODE",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Modulationsrate des Tremolos",
      depth        = "Modulationstiefe",
      waveform     = "LFO-Wellenform",
      stereo_mode  = "Tremolo oder AutoPan Stereo-Modus",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Tactic (Glitchmachines)
  --------------------------------------------------------------------
  tactic = {
    id      = "tactic",
    display = "Tactic (Glitchmachines)",
    match   = {"tactic","glitchmachines tactic"},
    vendor  = "Glitchmachines",
    type    = "phrase_sequencer_fx",
    roles   = {"Glitch","FSU","IDM","Drums"},

    sections = {
      "SAMPLE SLOTS",
      "MASTER SEQUENCER",
      "MOD SEQUENCERS",
      "RANDOMIZATION",
      "FX / OUTPUT",
    },

    key_params = {
      sample_slots = "Zuordnung der Samples zu Slots",
      master_seq   = "Haupt-Trigger-Sequencer",
      mod_seq      = "Modulations-Sequencer",
      random_amt   = "Randomization/Probability",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- TAL-NoiseMaker
  --------------------------------------------------------------------
  tal_noisemaker = {
    id      = "tal_noisemaker",
    display = "TAL-NoiseMaker (TAL)",
    match   = {"tal-noisemaker","tal noisemaker"},
    vendor  = "Togu Audio Line",
    type    = "synth_va_hybrid",
    roles   = {"Bass","Lead","Pad","IDM"},

    sections = {
      "OSCILLATORS",
      "FILTER",
      "ENVELOPES",
      "LFOs / MOD",
      "FX / OUTPUT",
    },

    key_params = {
      osc_mix      = "Oszillatormischung",
      filter_cutoff= "Filter-Cutoff",
      filter_reso  = "Filter-Resonanz",
      env_amp      = "Lautstärke-Hüllkurve",
      env_filter   = "Filter-Hüllkurve",
      lfo_rate     = "LFO-Rate",
    },
  },

  --------------------------------------------------------------------
  -- TAL-Chorus-LX
  --------------------------------------------------------------------
  tal_chorus_lx_ext = {
    id      = "tal_chorus_lx_ext",
    display = "TAL-Chorus-LX (TAL)",
    match   = {"tal-chorus-lx","tal chorus lx"},
    vendor  = "Togu Audio Line",
    type    = "chorus_vintage",
    roles   = {"Chorus","Vintage","Synth","IDM","Ambient"},

    sections = {
      "MODE I / MODE II",
      "STEREO WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      mode_i       = "Chorus-Modus I",
      mode_ii      = "Chorus-Modus II",
      stereo_width = "Stereo-Breite (falls verfügbar)",
      mix          = "Dry/Wet (oder Level)",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Subvert 2 (Glitchmachines)
  --------------------------------------------------------------------
  subvert2 = {
    id      = "subvert2",
    display = "Subvert 2 (Glitchmachines)",
    match   = {"subvert2","subvert 2","glitchmachines subvert"},
    vendor  = "Glitchmachines",
    type    = "fsu_multifx_modular",
    roles   = {"Distortion","FSU","IDM","Drums","Sounddesign"},

    sections = {
      "MULTI-CHANNEL DISTORTION",
      "FILTER MODULES",
      "FM/RINGMOD MODULES",
      "MODULATION (LFO/ENV/STEP)",
      "ROUTING / OUTPUT",
    },

    key_params = {
      drive        = "Drive/Sättigung pro Kanal",
      filter       = "Filter-Modus/Cutoff",
      fm_amount    = "FM-/Ringmod-Intensität",
      mod_matrix   = "Modulationszuweisungen",
      mix          = "Globaler Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Quadrant (Glitchmachines)
  --------------------------------------------------------------------
  quadrant = {
    id      = "quadrant",
    display = "Quadrant (Glitchmachines)",
    match   = {"quadrant","glitchmachines quadrant"},
    vendor  = "Glitchmachines",
    type    = "modular_fx",
    roles   = {"Modular FX","Glitch","IDM","Experimental"},

    sections = {
      "MODULE SLOTS",
      "PATCH MATRIX",
      "MODULATION (LFO/ENV/RANDOM)",
      "FILTER / DELAY / PITCH",
      "OUTPUT",
    },

    key_params = {
      module_assign = "Zuordnung der Module zu Slots",
      patch_routes  = "Patch-Kabel/Verbindungen",
      lfo_rate      = "LFO-Geschwindigkeit",
      env_follow    = "Envelope-Follower-Anteil",
      output_gain   = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Panflow (Audiomodern)
  --------------------------------------------------------------------
  panflow = {
    id      = "panflow",
    display = "Panflow (Audiomodern)",
    match   = {"panflow","audio­modern panflow"},
    vendor  = "Audiomodern",
    type    = "panning_sequencer",
    roles   = {"Panning","Stereo","Rhythmic","IDM"},

    sections = {
      "PATTERN EDITOR",
      "SYNC / RATE",
      "RANDOMIZATION",
      "MIX / OUTPUT",
    },

    key_params = {
      pattern      = "Panning-Pattern/Curve",
      rate         = "Syncrate (z.B. 1/4, 1/8 etc.)",
      random_amt   = "Randomisierung der Steps",
      depth        = "Intensität der Panning-Bewegung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- PSP stepDelay
  --------------------------------------------------------------------
  psp_stepdelay = {
    id      = "psp_stepdelay",
    display = "PSP stepDelay",
    match   = {"psp stepdelay","stepdelay psp"},
    vendor  = "PSP Audioware",
    type    = "delay_tape_style",
    roles   = {"Delay","Tape","IDM","FX"},

    sections = {
      "DELAY TIME (L/R)",
      "FEEDBACK",
      "TAPE/HEAD SATURATION",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Delay-Zeit (links/rechts)",
      feedback     = "Feedback-Anteil",
      tape_sat     = "Sättigung/Bandverhalten",
      tone         = "Helligkeit/Färbung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- LatticeReverb (Uhhyou)
  --------------------------------------------------------------------
  lattice_reverb = {
    id      = "lattice_reverb",
    display = "LatticeReverb (Uhhyou)",
    match   = {"latticereverb","lattice reverb","uhhyou reverb"},
    vendor  = "Uhhyou",
    type    = "reverb_experimental",
    roles   = {"Reverb","Ambient","IDM","Experimental"},

    sections = {
      "TIME / DECAY",
      "SIZE / DENSITY",
      "DIFFUSION / LATTICE",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      decay        = "Halllänge/Decay",
      size         = "Raumgröße/Struktur",
      density      = "Dichte der Reflexionen",
      tone         = "Filter/Tonbalance",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Lagrange (UrsaDSP)
  --------------------------------------------------------------------
  lagrange_delay = {
    id      = "lagrange_delay",
    display = "Lagrange (UrsaDSP)",
    match   = {"lagrange","ursadsp lagrange"},
    vendor  = "UrsaDSP",
    type    = "granular_delay",
    roles   = {"Delay","Granular","IDM","Texture"},

    sections = {
      "DELAY / TIME",
      "GRAIN / INTERPOLATION",
      "FEEDBACK",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Basisdelay / Zeit",
      grain_spread = "Zeitliche Verteilung/Spread der Grains",
      feedback     = "Feedback-Anteil",
      tone         = "Helligkeit/Dunkelheit",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Hysteresis (Glitchmachines)
  --------------------------------------------------------------------
  hysteresis = {
    id      = "hysteresis",
    display = "Hysteresis (Glitchmachines)",
    match   = {"hysteresis","glitchmachines hysteresis"},
    vendor  = "Glitchmachines",
    type    = "glitch_delay",
    roles   = {"Glitch","Delay","IDM","FSU"},

    sections = {
      "DELAY",
      "STUTTER / BUFFER",
      "FILTER",
      "MODULATION",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Delay-Zeit",
      stutter      = "Stutter-/Freeze-Anteil",
      filter       = "Filter-Cutoff/Resonanz",
      mod_depth    = "Modulationstiefe",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Free Delay (Venn Audio / Free Suite)
  --------------------------------------------------------------------
  free_delay = {
    id      = "free_delay",
    display = "Free Delay (Venn Audio / Free Suite)",
    match   = {"free delay","venn delay","free suite delay"},
    vendor  = "Venn Audio",
    type    = "delay_basic",
    roles   = {"Delay","Echo","Utility","IDM"},

    sections = {
      "TIME (SYNC/FREE)",
      "FEEDBACK",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Delay-Zeit oder Notenwert",
      feedback     = "Feedback-Anteil",
      tone         = "Tonformung/Filter",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- FractureXT (Glitchmachines)
  --------------------------------------------------------------------
  fracturext = {
    id      = "fracturext",
    display = "FractureXT (Glitchmachines)",
    match   = {"fracturext","fracture xt","glitchmachines fracturext"},
    vendor  = "Glitchmachines",
    type    = "buffer_fx_advanced",
    roles   = {"Glitch","Granular","IDM","FSU"},

    sections = {
      "BUFFER / BUFFER SIZE",
      "GRAIN / SLICE",
      "FILTER / DELAY",
      "MODULATION",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_size  = "Größe des Audiobuffers",
      slice_len    = "Länge der Slices/Grains",
      delay_time   = "Delay-Komponente",
      filter       = "Filter-Cutoff/Modus",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Fracture (Glitchmachines)
  --------------------------------------------------------------------
  fracture = {
    id      = "fracture",
    display = "Fracture (Glitchmachines)",
    match   = {"fracture","glitchmachines fracture"},
    vendor  = "Glitchmachines",
    type    = "buffer_fx",
    roles   = {"Glitch","Buffer","IDM","FSU"},

    sections = {
      "BUFFER",
      "FILTER",
      "DELAY",
      "LFOs / MOD",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_size  = "Größe des Buffers",
      filter       = "Filter-Parameter",
      delay_time   = "Delay-Zeit",
      lfo_rate     = "Modulationsrate der LFOs",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Filterstep (Audiomodern)
  --------------------------------------------------------------------
  filterstep = {
    id      = "filterstep",
    display = "Filterstep (Audiomodern)",
    match   = {"filterstep","audio­modern filterstep"},
    vendor  = "Audiomodern",
    type    = "filter_sequencer",
    roles   = {"Filter","StepSeq","IDM","Rhythmic"},

    sections = {
      "STEP SEQUENCER",
      "FILTER TYPE (LP/HP/BP)",
      "CUTOFF / RESONANCE",
      "RANDOMIZATION",
      "MIX / OUTPUT",
    },

    key_params = {
      pattern      = "Step-Pattern des Filters",
      filter_type  = "Filtertyp",
      cutoff       = "Grenzfrequenz",
      resonance    = "Resonanz",
      random_amt   = "Randomisierung/Variation",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Filterstep 64 (Audiomodern)
  --------------------------------------------------------------------
  filterstep_64 = {
    id      = "filterstep_64",
    display = "Filterstep_64 (Audiomodern)",
    match   = {"filterstep_64","filterstep 64"},
    vendor  = "Audiomodern",
    type    = "filter_sequencer",
    roles   = {"Filter","StepSeq","IDM","Rhythmic"},

    sections = {
      "STEP SEQUENCER (64 STEPS)",
      "FILTER TYPE (LP/HP/BP)",
      "CUTOFF / RESONANCE",
      "RANDOMIZATION",
      "MIX / OUTPUT",
    },

    key_params = {
      pattern      = "64-Step Filterpattern",
      filter_type  = "Filtertyp",
      cutoff       = "Grenzfrequenz",
      resonance    = "Resonanz",
      random_amt   = "Randomisierung/Variation",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Cryogen (Glitchmachines)
  --------------------------------------------------------------------
  cryogen = {
    id      = "cryogen",
    display = "Cryogen (Glitchmachines)",
    match   = {"cryogen","glitchmachines cryogen"},
    vendor  = "Glitchmachines",
    type    = "buffer_multifx_modular",
    roles   = {"Glitch","Buffer","FSU","IDM"},

    sections = {
      "DUAL BUFFER",
      "MULTIMODE FILTERS",
      "BITCRUSHERS",
      "MODULATION MATRIX",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_a     = "Buffer A Einstellungen",
      buffer_b     = "Buffer B Einstellungen",
      filter_mode  = "Filter-Modus",
      crush_amount = "Bitcrush-/Degrade-Menge",
      mod_matrix   = "Zuordnung LFO/Env zu Parametern",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Convex (Glitchmachines)
  --------------------------------------------------------------------
  convex = {
    id      = "convex",
    display = "Convex (Glitchmachines)",
    match   = {"convex","glitchmachines convex"},
    vendor  = "Glitchmachines",
    type    = "multifx_pitch_delay_filter",
    roles   = {"Glitch","Delay","Pitch","IDM"},

    sections = {
      "PITCH SHIFTERS",
      "DELAYS",
      "FILTERS",
      "LFOs / ENV FOLLOWERS",
      "MIX / OUTPUT",
    },

    key_params = {
      pitch_a      = "Pitch Shift A",
      pitch_b      = "Pitch Shift B",
      delay_time   = "Delay-Zeiten",
      filter       = "Filter-Parameter",
      lfo_rate     = "LFO-Geschwindigkeit",
      env_follow   = "Envelope-Follower-Empfindlichkeit",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Blindfold EQ (AudioThing)
  --------------------------------------------------------------------
  blindfold_eq = {
    id      = "blindfold_eq",
    display = "Blindfold EQ (AudioThing)",
    match   = {"blindfold eq","audiothing blindfold"},
    vendor  = "AudioThing",
    type    = "eq_minimal_blind",
    roles   = {"EQ","Tone","Training","IDM"},

    sections = {
      "LOW SHELF",
      "LOW MID",
      "HIGH MID",
      "HIGH SHELF",
      "OUTPUT",
    },

    key_params = {
      low_gain     = "Anhebung/Absenkung Tiefen",
      lowmid_gain  = "Anhebung/Absenkung Low-Mids",
      highmid_gain = "Anhebung/Absenkung High-Mids",
      high_gain    = "Anhebung/Absenkung Höhen",
      output_gain  = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- MERGED EXT ENTRIES
  --------------------------------------------------------------------
--------------------------------------------------------------------
  -- Audec Spread Delay Lite
  --------------------------------------------------------------------
  adc_spread_delay_lite = {
    id      = "adc_spread_delay_lite",
    display = "adc Spread Delay Lite (Audec)",
    match   = {"adc spread delay lite","spread delay lite %(audec%)"},
    vendor  = "Audec",
    type    = "delay_stereo_pingpong",
    roles   = {"Delay","Stereo","PingPong","IDM"},

    sections = {
      "DELAY TIME (L/R)",
      "FEEDBACK",
      "SPREAD / WIDTH",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time_l = "Delay-Zeit links",
      delay_time_r = "Delay-Zeit rechts",
      feedback     = "Feedback-Anteil",
      spread       = "Stereo-Spread/Verteilung der Echos",
      tone         = "Filter/Tonformung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Audec Spread Delay (voll)
  --------------------------------------------------------------------
  adc_spread_delay = {
    id      = "adc_spread_delay",
    display = "adc Spread Delay (Audec)",
    match   = {"adc spread delay","spread delay %(audec%)"},
    vendor  = "Audec",
    type    = "delay_stereo_pingpong",
    roles   = {"Delay","Stereo","PingPong","IDM"},

    sections = {
      "DELAY TIME (L/R)",
      "FEEDBACK",
      "SPREAD / WIDTH",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time_l = "Delay-Zeit links",
      delay_time_r = "Delay-Zeit rechts",
      feedback     = "Feedback-Anteil",
      spread       = "Stereo-Spread/Verteilung der Echos",
      tone         = "Filter/Tonformung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Verv (Puremagnetik)
  --------------------------------------------------------------------
  verv = {
    id      = "verv",
    display = "Verv (Puremagnetik)",
    match   = {"verv %(puremagnetik%)","puremagnetik verv"},
    vendor  = "Puremagnetik",
    type    = "synth_tapeloop",
    roles   = {"LoFi","Tape","Pads","Texture","IDM"},

    sections = {
      "LOOP / SAMPLE ENGINE",
      "TONE / LOFI",
      "MODULATION",
      "FILTER",
      "OUTPUT",
    },

    key_params = {
      loop_sel     = "Auswahl/Position der Tape-Loops",
      wow_flutter  = "Wow & Flutter/Modulation",
      noise        = "Rauschen/Artefaktpegel",
      filter       = "Filter-Cutoff/Resonanz",
      mix          = "Dry/Wet oder Signalanteil",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ValhallaSupermassive
  --------------------------------------------------------------------
  valhalla_supermassive = {
    id      = "valhalla_supermassive",
    display = "ValhallaSupermassive (Valhalla DSP)",
    match   = {"valhallasupermassive","supermassive %(valhalla%)"},
    vendor  = "Valhalla DSP",
    type    = "reverb_delay_space",
    roles   = {"Reverb","Delay","Ambient","IDM","Space"},

    sections = {
      "MODE / ALGORITHM",
      "DELAY / WARP",
      "FEEDBACK / DENSITY",
      "MODULATION",
      "EQ / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      mode         = "Algorithmus/Programmwahl",
      delay        = "Basis-Delay-Länge",
      warp         = "Warp/Stretch des Delays",
      feedback     = "Feedback-Intensität",
      density      = "Dichte der Repeats/Reverb-Struktur",
      mod_depth    = "Modulationstiefe",
      eq_tone      = "Tonformung/EQ",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- ValhallaFreqEcho
  --------------------------------------------------------------------
  valhalla_freqecho = {
    id      = "valhalla_freqecho",
    display = "ValhallaFreqEcho (Valhalla DSP)",
    match   = {"valhallafreqecho","freqecho %(valhalla%)"},
    vendor  = "Valhalla DSP",
    type    = "frequency_shifter_delay",
    roles   = {"Freq-Shift","Delay","Dub","IDM","FSU"},

    sections = {
      "FREQUENCY SHIFT",
      "DELAY TIME",
      "FEEDBACK",
      "FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      shift        = "Frequenzverschiebung in Hz",
      delay_time   = "Delay-Zeit (frei oder tempo-synchron)",
      feedback     = "Feedback-Anteil",
      filter       = "Low/Highcut im Feedbackpfad",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Tape Cassette 2 (Caelum Audio)
  --------------------------------------------------------------------
  tape_cassette2 = {
    id      = "tape_cassette2",
    display = "Tape Cassette 2 (Caelum Audio)",
    match   = {"tape cassette 2","caelum audio tape cassette"},
    vendor  = "Caelum Audio",
    type    = "tape_lofi",
    roles   = {"LoFi","Tape","Saturation","IDM"},

    sections = {
      "SATURATION",
      "WOW & FLUTTER",
      "NOISE",
      "MECHANICAL / HISS",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      saturation   = "Sättigungsgrad/Drive",
      wow_flutter  = "Wow & Flutter / Tonhöhenmodulation",
      noise        = "Bandrauschen/Noise",
      mech_noise   = "Mechanische Geräusche/Clicks",
      tone         = "Tonformung/Filter",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- TAL Reverb 4
  --------------------------------------------------------------------
  tal_reverb4 = {
    id      = "tal_reverb4",
    display = "TAL Reverb 4 (TAL)",
    match   = {"tal reverb 4","tal reverb4"},
    vendor  = "Togu Audio Line",
    type    = "reverb_plate_vintage",
    roles   = {"Reverb","Plate","Vintage","IDM","Ambient"},

    sections = {
      "DECAY",
      "SIZE / PREDELAY",
      "DIFFUSION",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      decay        = "Halllänge/Decay",
      size         = "Raumgröße/Charakter",
      predelay     = "Vorverzögerung",
      diffusion    = "Diffusionsgrad",
      tone         = "Helligkeit/Filter",
      mix          = "Reverb Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- SpectralAutopan (Anarchy Sound Software)
  --------------------------------------------------------------------
  spectral_autopan = {
    id      = "spectral_autopan",
    display = "SpectralAutopan v1.5 (Anarchy Sound Software)",
    match   = {"spectralautopan","spectral autopan","anarchysound spectral autopan"},
    vendor  = "Anarchy Sound Software",
    type    = "panning_spectral",
    roles   = {"Panning","Spectral","Stereo","IDM"},

    sections = {
      "FREQUENCY BANDS",
      "PAN CURVE",
      "RATE / SYNC",
      "DEPTH",
      "OUTPUT",
    },

    key_params = {
      bands        = "Anzahl/Aufteilung der Frequenzbänder",
      pan_curve    = "Panorama-Curve über Frequenz",
      rate         = "Modulationsrate/Sync",
      depth        = "Intensität der Panorama-Modulation",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- PSP PianoVerb
  --------------------------------------------------------------------
  psp_pianoverb = {
    id      = "psp_pianoverb",
    display = "PSP PianoVerb",
    match   = {"psp pianoverb","piano verb psp"},
    vendor  = "PSP Audioware",
    type    = "reverb_resonant_strings",
    roles   = {"Reverb","Resonant","IDM","FX"},

    sections = {
      "STRINGS (12 TUNED RESONATORS)",
      "TUNE / TRANSPOSE",
      "DAMPING / DECAY",
      "MIX / OUTPUT",
    },

    key_params = {
      string_level = "Pegel der einzelnen 'Saiten' / Resonatoren",
      tune         = "Gesamtstimmung/Transpose",
      damping      = "Dämpfung/Bedämpfung",
      decay        = "Hall-/Resonanzlänge",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- PSP Chamber
  --------------------------------------------------------------------
  psp_chamber = {
    id      = "psp_chamber",
    display = "PSP Chamber",
    match   = {"psp chamber","chamber reverb psp"},
    vendor  = "PSP Audioware",
    type    = "reverb_chamber",
    roles   = {"Reverb","Chamber","IDM","Ambient"},

    sections = {
      "DECAY / ROOM",
      "PREDELAY",
      "WIDTH / SPACE",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      decay        = "Abklingzeit",
      room_size    = "Raumgröße/Charakter",
      predelay     = "Vorverzögerung",
      width        = "Stereo-Breite",
      tone         = "Filter/Tonformung",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Moon Echo (AudioThing)
  --------------------------------------------------------------------
  moon_echo = {
    id      = "moon_echo",
    display = "Moon Echo (AudioThing)",
    match   = {"moon echo","audiothing moon echo"},
    vendor  = "AudioThing",
    type    = "delay_experimental",
    roles   = {"Delay","Space","Experimental","IDM"},

    sections = {
      "DELAY TIME",
      "FEEDBACK",
      "CHARACTER / TEXTURE",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time   = "Echo-/Delayzeit",
      feedback     = "Feedback-Anteil",
      character    = "Charakterparameter (Moon Bounce / Artefakte)",
      tone         = "Tonformung/Filter",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- LengthSeparator (Anarchy)
  --------------------------------------------------------------------
  length_separator = {
    id      = "length_separator",
    display = "LengthSeparator v1.5 (Anarchy Sound Software)",
    match   = {"lengthseparator","length separator","anarchysound length"},
    vendor  = "Anarchy Sound Software",
    type    = "dynamics_length_split",
    roles   = {"Transient","FX Split","IDM","Experimental"},

    sections = {
      "LENGTH DETECTION",
      "SHORT PATH PROCESSING",
      "LONG PATH PROCESSING",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle der Längenunterscheidung",
      short_proc   = "Bearbeitungsgrad des kurzen Signals",
      long_proc    = "Bearbeitungsgrad des langen Signals",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Leems (Puremagnetik)
  --------------------------------------------------------------------
  leems = {
    id      = "leems",
    display = "Leems (Puremagnetik)",
    match   = {"leems %(puremagnetik%)","puremagnetik leems"},
    vendor  = "Puremagnetik",
    type    = "synth_lofi_chip",
    roles   = {"Chiptune","LoFi","Lead","IDM"},

    sections = {
      "OSCILLATORS (3-VOICE)",
      "WAVE MODDING",
      "BITCRUSHER",
      "REVERB",
      "OUTPUT",
    },

    key_params = {
      osc_mix      = "Mischung der drei Oszillatoren",
      wave_mod     = "Wave-Modding/Verbiegen der Wellenformen",
      bitcrush     = "Bitcrusher-Intensität",
      reverb       = "Reverb-Menge",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- HarmonicAdder (Anarchy)
  --------------------------------------------------------------------
  harmonic_adder = {
    id      = "harmonic_adder",
    display = "HarmonicAdder v1.5 (Anarchy Sound Software)",
    match   = {"harmonicadder","harmonic adder","anarchysound harmonic"},
    vendor  = "Anarchy Sound Software",
    type    = "harmonic_enhancer",
    roles   = {"Harmonics","Timbre","IDM","FX"},

    sections = {
      "HARMONIC GENERATION",
      "FREQUENCY / ORDER",
      "MIX / BLEND",
      "OUTPUT",
    },

    key_params = {
      amount       = "Intensität der hinzugefügten Harmonischen",
      order        = "Ordnung/Frequenzlage der Harmonischen",
      blend        = "Blend-Anteil Original vs. Harmonics",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Tone
  --------------------------------------------------------------------
  free_tone = {
    id      = "free_tone",
    display = "Free Tone (Venn Audio)",
    match   = {"free tone %(venn audio%)","venn free tone"},
    vendor  = "Venn Audio",
    type    = "tone_saturation",
    roles   = {"Tone","Saturation","Utility","IDM"},

    sections = {
      "TONE SHAPING",
      "SATURATION",
      "OUTPUT",
    },

    key_params = {
      tone         = "Frequenzbetonte Formung",
      saturation   = "Sättigungs-/Drive-Anteil",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Pan
  --------------------------------------------------------------------
  free_pan = {
    id      = "free_pan",
    display = "Free Pan (Venn Audio)",
    match   = {"free pan %(venn audio%)","venn free pan"},
    vendor  = "Venn Audio",
    type    = "panning_utility",
    roles   = {"Panning","Stereo","Utility","IDM"},

    sections = {
      "PAN / BALANCE",
      "LAW/ SHAPE",
      "OUTPUT",
    },

    key_params = {
      pan          = "Panorama-Position",
      balance      = "Balance zwischen L/R",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Meter
  --------------------------------------------------------------------
  free_meter = {
    id      = "free_meter",
    display = "Free Meter (Venn Audio)",
    match   = {"free meter %(venn audio%)","venn free meter"},
    vendor  = "Venn Audio",
    type    = "metering",
    roles   = {"Meter","Utility","Level"},

    sections = {
      "LEVEL METER",
      "PEAK / RMS",
      "LOUDNESS (falls vorhanden)",
    },

    key_params = {
      peak         = "Peak-Level-Anzeige",
      rms          = "RMS/Lautheitsanzeige",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Gain
  --------------------------------------------------------------------
  free_gain = {
    id      = "free_gain",
    display = "Free Gain (Venn Audio)",
    match   = {"free gain %(venn audio%)","venn free gain"},
    vendor  = "Venn Audio",
    type    = "gain_utility",
    roles   = {"Gain","Utility","Trim"},

    sections = {
      "GAIN",
      "OUTPUT",
    },

    key_params = {
      gain         = "Verstärkung/Abschwächung",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free EQ
  --------------------------------------------------------------------
  free_eq = {
    id      = "free_eq",
    display = "Free EQ (Venn Audio)",
    match   = {"free eq %(venn audio%)","venn free eq"},
    vendor  = "Venn Audio",
    type    = "eq_parametric",
    roles   = {"EQ","Tone","Utility","IDM"},

    sections = {
      "BANDS",
      "FREQUENCY / GAIN",
      "Q / SLOPE",
      "OUTPUT",
    },

    key_params = {
      band_freq    = "Frequenz pro Band",
      band_gain    = "Gain pro Band",
      band_q       = "Güte/Q pro Band",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Convolve
  --------------------------------------------------------------------
  free_convolve = {
    id      = "free_convolve",
    display = "Free Convolve (Venn Audio)",
    match   = {"free convolve %(venn audio%)","venn free convolve"},
    vendor  = "Venn Audio",
    type    = "convolution_fx",
    roles   = {"Convolution","Reverb","FX","IDM"},

    sections = {
      "IMPULSE RESPONSE",
      "TIME / LENGTH",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      ir_select    = "Auswahl der Impulsantwort",
      length       = "Länge/Stretch der IR",
      tone         = "Tonformung/Filter",
      mix          = "Dry/Wet",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Comp
  --------------------------------------------------------------------
  free_comp = {
    id      = "free_comp",
    display = "Free Comp (Venn Audio)",
    match   = {"free comp %(venn audio%)","venn free comp"},
    vendor  = "Venn Audio",
    type    = "compressor_basic",
    roles   = {"Compressor","Dynamics","IDM","Bus"},

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "KNEE",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Schwellwert",
      ratio        = "Kompressionsverhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      knee         = "Knee-Weichheit",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Venn Audio – Free Clip 2
  --------------------------------------------------------------------
  free_clip2 = {
    id      = "free_clip2",
    display = "Free Clip 2 (Venn Audio)",
    match   = {"free clip 2 %(venn audio%)","venn free clip 2","freeclip2"},
    vendor  = "Venn Audio",
    type    = "clipper",
    roles   = {"Clipper","Limiter","IDM","Drums"},

    sections = {
      "THRESHOLD / CEILING",
      "CLIP SHAPE",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Einsatzschwelle des Clippers",
      shape        = "Charakter der Clipping-Kurve",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Filterjam (AudioThing)
  --------------------------------------------------------------------
  filterjam = {
    id      = "filterjam",
    display = "Filterjam (AudioThing)",
    match   = {"filterjam","audiothing filterjam"},
    vendor  = "AudioThing",
    type    = "filter_multiband_resonant",
    roles   = {"Filter","Resonance","LoFi","IDM"},

    sections = {
      "BAND SPLIT",
      "MODE / MIX",
      "GAIN / RESONANCE",
      "OUTPUT",
    },

    key_params = {
      mode         = "Verknüpfung der Bänder (Add, Sub, etc.)",
      band_gain    = "Verstärkung der Bänder",
      resonance    = "Resonanz/Schärfe",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Expanse (Puremagnetik)
  --------------------------------------------------------------------
  expanse = {
    id      = "expanse",
    display = "Expanse (Puremagnetik)",
    match   = {"expanse %(puremagnetik%)","puremagnetik expanse"},
    vendor  = "Puremagnetik",
    type    = "noise_drone_generator",
    roles   = {"Noise","Drone","Texture","IDM"},

    sections = {
      "SOURCE / NOISE",
      "BLUR / SMOOTH",
      "PITCH / TRANSPOSE",
      "FILTER",
      "OUTPUT",
    },

    key_params = {
      noise_level  = "Noise-/Signalpegel",
      blur         = "Spektrales Blur/Smear",
      pitch        = "Grundstimmung/Transpose",
      filter       = "Filter/Tonformung",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Driftmaker (Puremagnetik)
  --------------------------------------------------------------------
  driftmaker = {
    id      = "driftmaker",
    display = "Driftmaker (Puremagnetik)",
    match   = {"driftmaker %(puremagnetik%)","puremagnetik driftmaker","driftmaker"},
    vendor  = "Puremagnetik",
    type    = "delay_degrade_fx",
    roles   = {"Delay","Degrade","LoFi","IDM","FSU"},

    sections = {
      "PARSE / CHOP",
      "TIME / DRIFT",
      "DEGRADE / TEXTURE",
      "MIX / OUTPUT",
    },

    key_params = {
      parse        = "Analyse/Segmentierung des Inputs",
      chop         = "Zerhackungs-/Slice-Intensität",
      time         = "Zeit-Dehnung/Verzögerung",
      drift        = "Zeitliches/Vintages Drift/Unschärfe",
      blend        = "Blend mit Originalsignal",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Corkscrew (Anarchy)
  --------------------------------------------------------------------
  corkscrew = {
    id      = "corkscrew",
    display = "Corkscrew v1.5 (Anarchy Sound Software)",
    match   = {"corkscrew","anarchysound corkscrew"},
    vendor  = "Anarchy Sound Software",
    type    = "spectral_pitch_fx",
    roles   = {"Pitch","Spectral","IDM","Experimental"},

    sections = {
      "PITCH / SHIFT",
      "SPECTRAL WARP",
      "RATE / MODULATION",
      "OUTPUT",
    },

    key_params = {
      shift        = "Pitch-/Frequenzverschiebung",
      warp         = "Spektrale Verbiegung/Warpen",
      rate         = "Modulationsrate",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- Convoluter (Anarchy)
  --------------------------------------------------------------------
  convoluter = {
    id      = "convoluter",
    display = "Convoluter v1.5 (Anarchy Sound Software)",
    match   = {"convoluter","anarchysound convoluter"},
    vendor  = "Anarchy Sound Software",
    type    = "convolution_spectral_fx",
    roles   = {"Convolution","Spectral","IDM","Experimental"},

    sections = {
      "INPUT A / INPUT B",
      "SPECTRAL COMBINE",
      "FILTER / TONE",
      "OUTPUT",
    },

    key_params = {
      mix_ab       = "Mischung der beiden Eingangssignale",
      spectral_amt = "Stärke der spektralen Kombination",
      tone         = "Filter/Tonformung",
      output_gain  = "Output Gain",
    },
  },

  --------------------------------------------------------------------
  -- AnarchyRhythms
  --------------------------------------------------------------------
  anarchy_rhythms = {
    id      = "anarchy_rhythms",
    display = "AnarchyRhythms (Anarchy Sound Software)",
    match   = {"anarchyrhythms","anarchy rhythms"},
    vendor  = "Anarchy Sound Software",
    type    = "rhythmic_fx_synth",
    roles   = {"Rhythmic","Glitch","FSU","IDM"},

    sections = {
      "INPUT / OSCILLATORS",
      "PATTERN / GRID",
      "FILTERS / BANDS",
      "FEEDBACK / DISTORTION",
      "OUTPUT",
    },

    key_params = {
      pattern      = "Rhythmisches Pattern/Matrix",
      band_filters = "Bandpass-/Filterparameter",
      feedback     = "Feedback-/Loop-Anteil",
      drive        = "Verzerrungsgrad",
      output_gain  = "Output Gain",
    },
  },

--------------------------------------------------------------------
-- ADVANCED / MIX & CHARACTER PLUGINS – Batch
--------------------------------------------------------------------

lens_auburn = {
  id      = "lens_auburn",
  display = "Lens (Auburn Sounds)",
  match   = {"lens %(auburn sounds%)","auburn lens"},
  vendor  = "Auburn Sounds",
  type    = "spectral_dynamics",
  roles   = {"Spectral","Multiband","Master","IDM"},

  sections = {
    "SPECTRAL COMPANDER",
    "EQ / TONE",
    "DISTORTION / COLOR",
    "STEREO / OUTPUT",
  },

  key_params = {
    compander    = "Spektrale Kompression/Expansion",
    eq_shape     = "Tonformung/EQ-Kurve",
    distortion   = "Sättigung/Verzerrung",
    stereo_width = "Stereo-Breite",
    output_gain  = "Output Gain",
  },
},

bluecat_free_amp = {
  id      = "bluecat_free_amp",
  display = "Blue Cat's Free Amp (Blue Cat Audio)",
  match   = {"blue cat's free amp","blue cat free amp"},
  vendor  = "Blue Cat Audio",
  type    = "amp_sim",
  roles   = {"Amp","Guitar","LoFi","IDM"},

  sections = {
    "AMP MODEL",
    "GAIN / DRIVE",
    "TONE",
    "OUTPUT",
  },

  key_params = {
    amp_model    = "Auswahl des Amp-Typs",
    gain         = "Verzerrungsgrad",
    tone         = "Tonblende/EQ",
    output_gain  = "Output Gain",
  },
},

bt_clipper = {
  id      = "bt_clipper",
  display = "BT-Clipper (Viator DSP)",
  match   = {"bt-clipper","bt clipper","viator dsp bt clipper"},
  vendor  = "Viator DSP",
  type    = "clipper",
  roles   = {"Clipper","Limiter","Drums","IDM"},

  sections = {
    "CLIP MODE",
    "THRESHOLD",
    "MID TONE",
    "OUTPUT",
  },

  key_params = {
    mode         = "Clipping-Charakter (Hard/Soft/Analog)",
    threshold    = "Einsatzschwelle",
    mid_tone     = "Tonalsteuerung im Mittenbereich",
    output_gain  = "Output Gain",
  },
},

protoverb = {
  id      = "protoverb",
  display = "Protoverb (u-he)",
  match   = {"protoverb","uhe protoverb","u-he protoverb"},
  vendor  = "u-he",
  type    = "reverb_resonant_experimental",
  roles   = {"Reverb","Resonant","Experimental","IDM"},

  sections = {
    "ROOM STRUCTURE",
    "DECAY / ABSORPTION",
    "RANDOM SEED / CODE",
    "MIX / OUTPUT",
  },

  key_params = {
    room_size    = "Größe/Charakter des Raums",
    decay        = "Abklingzeit",
    absorption   = "Dämpfung des Raums",
    seed_code    = "Preset-Code/Seed für die Raumstruktur",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

surge_xt = {
  id      = "surge_xt",
  display = "Surge XT (Surge Synth Team)",
  match   = {"surge xt","surge xt %(surge synth team%)"},
  vendor  = "Surge Synth Team",
  type    = "synth_hybrid_modular",
  roles   = {"Synth","Hybrid","Modular","IDM"},

  sections = {
    "OSCILLATORS",
    "FILTERS",
    "ENVELOPES / LFOs",
    "MOD MATRIX",
    "FX / OUTPUT",
  },

  key_params = {
    osc_config   = "Oszillator-Setup und Wellenformen",
    filter       = "Filter-Cutoff/Resonanz",
    env          = "Hüllkurven-Zeiten",
    lfo_rate     = "LFO-Geschwindigkeit",
    mod_matrix   = "Modulationszuweisungen",
    output_gain  = "Output Gain",
  },
},

smooth_operator = {
  id      = "smooth_operator",
  display = "Smooth Operator (BABY Audio)",
  match   = {"smooth operator","baby audio smooth operator"},
  vendor  = "BABY Audio",
  type    = "spectral_suppressor",
  roles   = {"Spectral","Tame","Master","IDM"},

  sections = {
    "SPECTRAL SHAPING CURVE",
    "FOCUS / THRESHOLD",
    "TIME / RELEASE",
    "MIX / OUTPUT",
  },

  key_params = {
    curve        = "Spektrale Formungskurve",
    focus        = "Fokusbereich/Empfindlichkeit",
    threshold    = "Einsatzschwelle der Glättung",
    release      = "Release-Zeit",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

pitch_drift = {
  id      = "pitch_drift",
  display = "Pitch Drift (BABY Audio)",
  match   = {"pitch drift","baby audio pitch drift"},
  vendor  = "BABY Audio",
  type    = "pitch_modulation",
  roles   = {"WowFlutter","Pitch","LoFi","IDM"},

  sections = {
    "DEPTH",
    "SPEED",
    "MIX / OUTPUT",
  },

  key_params = {
    depth        = "Intensität der Pitch-Schwankungen",
    speed        = "Geschwindigkeit der Modulation",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

magic_switch = {
  id      = "magic_switch",
  display = "Magic Switch (BABY Audio)",
  match   = {"magic switch","baby audio magic switch"},
  vendor  = "BABY Audio",
  type    = "chorus_oneknob",
  roles   = {"Chorus","Vintage","Width","IDM"},

  sections = {
    "ON/OFF",
    "MIX / OUTPUT",
  },

  key_params = {
    amount       = "Gesamte Chorus-Intensität",
    mix          = "Dry/Wet (falls vorhanden)",
    output_gain  = "Output Gain",
  },
},

magic_dice = {
  id      = "magic_dice",
  display = "Magic Dice (BABY Audio)",
  match   = {"magic dice","baby audio magic dice"},
  vendor  = "BABY Audio",
  type    = "fx_random_space",
  roles   = {"Random","Space","Delay","Reverb","IDM"},

  sections = {
    "RANDOMIZER",
    "MIX / OUTPUT",
  },

  key_params = {
    dice         = "Neues Zufalls-Preset",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

krush_tritik = {
  id      = "krush_tritik",
  display = "Krush (Tritik)",
  match   = {"krush %(tritik%)","tritik krush"},
  vendor  = "Tritik",
  type    = "bitcrusher_downsampler",
  roles   = {"Bitcrush","LoFi","IDM","FSU"},

  sections = {
    "CRUSH (BITS)",
    "DOWN SAMPLE",
    "FILTER",
    "MODULATION",
    "MIX / OUTPUT",
  },

  key_params = {
    bit_depth    = "Reduzierung der Bittiefe",
    downsample   = "Reduzierung der Samplerate",
    filter       = "Filter-Cutoff/Resonanz",
    mod_depth    = "Modulationstiefe",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

snap_heap = {
  id      = "snap_heap",
  display = "Snap Heap (Kilohearts)",
  match   = {"snap heap","kilohearts snap heap"},
  vendor  = "Kilohearts",
  type    = "modular_fx_container",
  roles   = {"Modular FX","Routing","IDM","Macro"},

  sections = {
    "EFFECT SLOTS",
    "MODULATORS",
    "MACROS",
    "OUTPUT",
  },

  key_params = {
    chain        = "Aufbau der Effektkette",
    modulators   = "LFO/Envelope/Random-Quellen",
    macros       = "Zuweisung von Macro-Reglern",
    output_gain  = "Output Gain",
  },
},

kclip_zero = {
  id      = "kclip_zero",
  display = "KClip Zero (Kazrog)",
  match   = {"kclip zero","kazrog kclip zero"},
  vendor  = "Kazrog",
  type    = "clipper_master",
  roles   = {"Clipper","Loudness","IDM","Master"},

  sections = {
    "THRESHOLD",
    "CLIP CURVE",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle",
    curve        = "Charakter der Clipping-Kurve",
    output_gain  = "Output Gain",
  },
},

frohmager = {
  id      = "frohmager",
  display = "Frohmager (Ohm Force)",
  match   = {"frohmager","ohm force frohmager"},
  vendor  = "Ohm Force",
  type    = "filter_nonlinear",
  roles   = {"Filter","Resonant","LoFi","IDM"},

  sections = {
    "FILTER TYPE",
    "CUTOFF / RESONANCE",
    "DRIVE / CHARACTER",
    "MODULATION",
    "OUTPUT",
  },

  key_params = {
    filter_type  = "Filtermodus/Charakter",
    cutoff       = "Grenzfrequenz",
    resonance    = "Resonanzintensität",
    drive        = "Drive/Sättigung",
    mod_amount   = "Modulationsintensität",
    output_gain  = "Output Gain",
  },
},

mh_thump = {
  id      = "mh_thump",
  display = "MH Thump (Metric Halo)",
  match   = {"mh thump","metric halo thump"},
  vendor  = "Metric Halo",
  type    = "subharmonic_enhancer",
  roles   = {"Sub","Kick","Bass","IDM"},

  sections = {
    "FUNDAMENTAL FREQ",
    "SUB LEVEL",
    "SHAPE / DECAY",
    "OUTPUT",
  },

  key_params = {
    freq         = "Frequenz des erzeugten Thumps",
    sub_level    = "Pegel der Sub-Komponente",
    decay        = "Abklingzeit des Thumps",
    output_gain  = "Output Gain",
  },
},

tforce_zenith = {
  id      = "tforce_zenith",
  display = "T-Force Zenith (Mastrcode Music)",
  match   = {"t-force zenith","t force zenith"},
  vendor  = "Mastrcode Music",
  type    = "synth_edm",
  roles   = {"Synth","Lead","Trance","IDM"},

  sections = {
    "OSCILLATORS",
    "FILTER",
    "ENVELOPES",
    "MODULATION",
    "FX / OUTPUT",
  },

  key_params = {
    osc_mix      = "Oszillatormischung",
    filter       = "Filter-Cutoff/Resonanz",
    env_amp      = "Amp-Hüllkurve",
    env_mod      = "Mod-Hüllkurve",
    lfo_rate     = "LFO-Geschwindigkeit",
    output_gain  = "Output Gain",
  },
},

neutone_fx = {
  id      = "neutone_fx",
  display = "Neutone FX (Neutone)",
  match   = {"neutone fx","neural tone fx","neutone"},
  vendor  = "Neutone",
  type    = "ai_model_host",
  roles   = {"AI","Neural","Experimental","IDM"},

  sections = {
    "MODEL SELECTION",
    "INPUT ROUTING",
    "MODEL PARAMETERS",
    "OUTPUT",
  },

  key_params = {
    model        = "Gewähltes KI-/Neural-Modell",
    model_param1 = "Modellabhängiger Hauptparameter",
    model_param2 = "Weitere modellabhängige Steuerung",
    output_gain  = "Output Gain",
  },
},

prebox = {
  id      = "prebox",
  display = "PreBOX (AnalogObsession)",
  match   = {"prebox","analogobsession prebox","analog obsession prebox"},
  vendor  = "AnalogObsession",
  type    = "preamp_saturation",
  roles   = {"Preamp","Saturation","IDM","Tone"},

  sections = {
    "GAIN / DRIVE",
    "TONE",
    "OUTPUT",
  },

  key_params = {
    drive        = "Preamp-Gain/Sättigung",
    tone         = "Klangblende/Tonformung",
    output_gain  = "Output Gain",
  },
},

lala_comp = {
  id      = "lala_comp",
  display = "LALA (AnalogObsession)",
  match   = {"lala","analogobsession lala","analog obsession lala"},
  vendor  = "AnalogObsession",
  type    = "compressor_opto",
  roles   = {"Compressor","Opto","Glue","IDM"},

  sections = {
    "PEAK REDUCTION",
    "GAIN",
    "HF/LF EMPHASIS",
    "OUTPUT",
  },

  key_params = {
    peak_reduc   = "Kompressionsstärke",
    gain         = "Make-Up Gain",
    emphasis     = "Hoch-/Tiefbetonung für Sidechain",
    output_gain  = "Output Gain",
  },
},

kolin_comp = {
  id      = "kolin_comp",
  display = "Kolin (AnalogObsession)",
  match   = {"kolin","analogobsession kolin","analog obsession kolin"},
  vendor  = "AnalogObsession",
  type    = "compressor_vari_mu",
  roles   = {"Compressor","Vari-Mu","Bus","IDM"},

  sections = {
    "THRESHOLD",
    "RATIO / TIME CONST",
    "DRIVE / COLOR",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle",
    time_const   = "Timing/Attack/Release-Kombination",
    drive        = "Sättigung/Färbung",
    output_gain  = "Output Gain",
  },
},

bx_aura = {
  id      = "bx_aura",
  display = "bx_aura (Plugin Alliance)",
  match   = {"bx_aura","bx aura","aura %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "spectral_enhancer",
  roles   = {"Enhancer","Spectral","Master","IDM"},

  sections = {
    "FOCUS BANDS",
    "INTENSITY",
    "TONE / COLOR",
    "OUTPUT",
  },

  key_params = {
    focus        = "Schwerpunkt der spektralen Bearbeitung",
    intensity    = "Intensität der Aura-Bearbeitung",
    tone         = "Tonbalance/Färbung",
    output_gain  = "Output Gain",
  },
},

bx_blackdist2 = {
  id      = "bx_blackdist2",
  display = "bx_blackdist2 (Plugin Alliance)",
  match   = {"bx_blackdist2","bx blackdist2","blackdist2 %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "distortion_pedal",
  roles   = {"Distortion","Guitar","Drums","IDM"},

  sections = {
    "DRIVE",
    "TONE",
    "LEVEL",
  },

  key_params = {
    drive        = "Verzerrungsgrad",
    tone         = "Klangblende/Tonformung",
    level        = "Ausgangspegel",
  },
},

bx_bassdude = {
  id      = "bx_bassdude",
  display = "bx_bassdude (Plugin Alliance)",
  match   = {"bx_bassdude","bx bassdude","bassdude %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "amp_sim_bass",
  roles   = {"Amp","Bass","LoFi","IDM"},

  sections = {
    "GAIN",
    "EQ SECTION",
    "MASTER",
    "OUTPUT",
  },

  key_params = {
    gain         = "Vorstufen-Gain",
    eq_settings  = "EQ-Einstellungen (Bass/Mid/Treble)",
    master       = "Masterlautstärke",
    output_gain  = "Output Gain",
  },
},

bx_clipper_pa = {
  id      = "bx_clipper_pa",
  display = "bx_clipper (Plugin Alliance)",
  match   = {"bx_clipper","bx clipper","clipper %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "clipper_master",
  roles   = {"Clipper","Limiter","Master","IDM"},

  sections = {
    "THRESHOLD / CEILING",
    "SHAPE / SOFTNESS",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle des Clippers",
    shape        = "Härte/Weichheit der Kurve",
    output_gain  = "Output Gain",
  },
},

bx_2098_eq = {
  id      = "bx_2098_eq",
  display = "bx_2098 EQ (Plugin Alliance)",
  match   = {"bx_2098 eq","bx 2098 eq","2098 eq %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "eq_console",
  roles   = {"EQ","Tone","Bus","IDM"},

  sections = {
    "LOW / LOW-MID BANDS",
    "HIGH-MID / HIGH BANDS",
    "HP/LP FILTERS",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Bandfrequenzen",
    band_gain    = "Gain der Bänder",
    q_width      = "Bandbreite/Q",
    output_gain  = "Output Gain",
  },
},

bx_digital_v3 = {
  id      = "bx_digital_v3",
  display = "bx_digital V3 (Plugin Alliance)",
  match   = {"bx_digital v3","bx digital v3","digital v3 %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "eq_ms_master",
  roles   = {"EQ","M/S","Master","IDM"},

  sections = {
    "M/S EQ BANDS",
    "MONO MAKER",
    "STEREO WIDTH",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz der M/S-Bänder",
    band_gain    = "Gain der Bänder",
    mono_maker   = "Mono-Frequenzgrenze",
    width        = "Stereo-Breite",
    output_gain  = "Output Gain",
  },
},

lindell_254e = {
  id      = "lindell_254e",
  display = "Lindell 254E (Plugin Alliance)",
  match   = {"lindell 254e","lindell_254e"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "compressor_vintage",
  roles   = {"Compressor","Bus","Drums","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "LIMIT / COMP MODE",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Kompressor-Schwelle",
    ratio        = "Verhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    output_gain  = "Output Gain",
  },
},

lindell_mbc = {
  id      = "lindell_mbc",
  display = "Lindell MBC (Plugin Alliance)",
  match   = {"lindell mbc"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "multiband_compressor",
  roles   = {"Multiband","Bus","Master","IDM"},

  sections = {
    "BAND SPLITS",
    "THRESHOLD / RATIO PER BAND",
    "ATTACK / RELEASE PER BAND",
    "OUTPUT",
  },

  key_params = {
    crossover    = "Übergangsfrequenzen der Bänder",
    threshold    = "Schwelle pro Band",
    ratio        = "Verhältnis pro Band",
    output_gain  = "Output Gain",
  },
},

lindell_902 = {
  id      = "lindell_902",
  display = "Lindell 902 De-esser (Plugin Alliance)",
  match   = {"lindell 902","lindell 902 de-esser"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "deesser",
  roles   = {"De-esser","HF Control","IDM"},

  sections = {
    "FREQUENCY",
    "RANGE",
    "MODE",
    "OUTPUT",
  },

  key_params = {
    freq         = "Ziel-Frequenzbereich der S-Laute",
    range        = "Maximale Absenkung",
    mode         = "Betriebsmodus (Wide/Narrow etc.)",
    output_gain  = "Output Gain",
  },
},

lindell_80bus = {
  id      = "lindell_80bus",
  display = "Lindell 80 Bus (Plugin Alliance)",
  match   = {"lindell 80 bus","lindell 80bus"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "bus_channel_strip",
  roles   = {"Bus","Glue","Tone","IDM"},

  sections = {
    "INPUT / DRIVE",
    "EQ SECTION",
    "COMP SECTION",
    "OUTPUT",
  },

  key_params = {
    drive        = "Eingangslevel/Sättigung",
    eq_settings  = "EQ-Parameter",
    comp_settings= "Kompressor-Einstellungen",
    output_gain  = "Output Gain",
  },
},

lindell_channelx = {
  id      = "lindell_channelx",
  display = "Lindell ChannelX (Plugin Alliance)",
  match   = {"lindell channelx","channelx lindell"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "channel_strip",
  roles   = {"Channelstrip","EQ","Comp","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "COMPRESSOR",
    "EQ",
    "DE-ESSER",
    "OUTPUT",
  },

  key_params = {
    preamp       = "Vorstufen-Gain/Sättigung",
    comp         = "Kompressor-Parameter",
    eq           = "EQ-Parameter",
    deesser      = "De-Esser-Einstellungen",
    output_gain  = "Output Gain",
  },
},

--------------------------------------------------------------------
-- BATCH: CREATIVE / MIX PLUGINS – dblue, BABY Audio, NI, PA, TDR, Voxengo
--------------------------------------------------------------------

dblue_tapestop = {
  id      = "dblue_tapestop",
  display = "dblue.TapeStop (dblue)",
  match   = {"dblue.tapestop","tapestop %(dblue%)"},
  vendor  = "dblue",
  type    = "tapestop_fx",
  roles   = {"Glitch","TapeStop","FSU","IDM"},

  sections = {
    "TRIGGER / MODE",
    "STOP TIME / SPEED",
    "CURVE / SHAPE",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    trigger_mode = "Trigger-Modus (Manual/Host/Audio)",
    stop_time    = "Länge der Abbremsbewegung",
    curve        = "Kurvenform der Pitch-Absenkung",
    filter       = "Tonformung/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

dblue_stretch = {
  id      = "dblue_stretch",
  display = "dblue Stretch v1.1 (dblue)",
  match   = {"dblue stretch","stretch v1.1 %(dblue%)"},
  vendor  = "dblue",
  type    = "time_stretch_fsufx",
  roles   = {"Stretch","FSU","Granular","IDM"},

  sections = {
    "STRETCH RATIO",
    "GRAIN / WINDOW",
    "JITTER / RANDOM",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    ratio        = "Verhältnis der Zeitstreckung",
    grain_size   = "Größe des Zeitfensters/Grains",
    jitter       = "Zeitliche Unschärfe/Jitter",
    filter       = "Filter/Tonformung",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

warp_babyaudio = {
  id      = "warp_babyaudio",
  display = "Warp (BABY Audio)",
  match   = {"warp %(baby audio%)","baby audio warp"},
  vendor  = "BABY Audio",
  type    = "delay_warp_fx",
  roles   = {"Delay","Warp","Texture","IDM"},

  sections = {
    "TIME / SYNC",
    "WARP / SHIFT",
    "TEXTURE / MOVEMENT",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    time         = "Delay-Zeit / Tempo-Sync",
    warp         = "Zeit-/Pitch-Verzerrung",
    texture      = "Textur/Bewegung des Effekts",
    tone         = "Filter/Tonformung",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ni_replika = {
  id      = "ni_replika",
  display = "Replika (Native Instruments)",
  match   = {"replika %(native instruments%)","ni replika"},
  vendor  = "Native Instruments",
  type    = "delay_multi_mode",
  roles   = {"Delay","Mod","Space","IDM"},

  sections = {
    "DELAY TIME",
    "FEEDBACK",
    "STYLE / MODE",
    "MODULATION",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    delay_time   = "Delay-Zeit (frei/tempo-synchron)",
    feedback     = "Feedback-Anteil",
    style_mode   = "Delay-Modus/Charakter",
    modulation   = "Modulationstiefe/-geschwindigkeit",
    filter       = "Filter/Tonformung im Feedbackpfad",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ni_raum = {
  id      = "ni_raum",
  display = "Raum (Native Instruments)",
  match   = {"raum %(native instruments%)","ni raum"},
  vendor  = "Native Instruments",
  type    = "reverb_mod_space",
  roles   = {"Reverb","Space","Mod","IDM"},

  sections = {
    "SIZE / PREDELAY",
    "DECAY",
    "MODULATION / SHIMMER",
    "FILTER / DAMPING",
    "CRUNCH / CHARACTER",
    "MIX / OUTPUT",
  },

  key_params = {
    size         = "Raumgröße",
    predelay     = "Vorverzögerung",
    decay        = "Abklingzeit",
    modulation   = "Modulationstiefe/-rate",
    tone         = "Helligkeit/Dämpfung",
    crunch       = "Charakter/Drive-Anteil",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

buffer_override = {
  id      = "buffer_override",
  display = "Buffer Override (Destroy FX)",
  match   = {"buffer override","destroy fx buffer override"},
  vendor  = "Destroy FX",
  type    = "buffer_fsufx",
  roles   = {"Glitch","FSU","Buffer","IDM"},

  sections = {
    "BUFFER SIZE",
    "READ POSITION / SPEED",
    "DIRECTION / REVERSE",
    "RANDOM / CHAOS",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    buffer_size  = "Länge des Audio-Buffers",
    read_speed   = "Lesegeschwindigkeit durch den Buffer",
    direction    = "Abspielrichtung (vorwärts/rückwärts)",
    random       = "Zufalls-/Chaos-Anteil",
    filter       = "Tonformung/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

io_filter_serrano = {
  id      = "io_filter_serrano",
  display = "IO/Filter (benoit serrano)",
  match   = {"io/filter","io filter %(benoit serrano%)"},
  vendor  = "benoit serrano",
  type    = "filter_multimode",
  roles   = {"Filter","Tone","Mod","IDM"},

  sections = {
    "FILTER TYPE / MODE",
    "CUTOFF / RESONANCE",
    "ENVELOPE / MOD",
    "DRIVE / SATURATION",
    "OUTPUT",
  },

  key_params = {
    filter_type  = "Filtermodus (LP/BP/HP etc.)",
    cutoff       = "Grenzfrequenz",
    resonance    = "Resonanzhöhe",
    env_mod      = "Hüllkurven-/Modulationsanteil",
    drive        = "Drive/Sättigung",
    output_gain  = "Output Gain",
  },
},

tal_filter2 = {
  id      = "tal_filter2",
  display = "TAL-Filter-2 (TAL-Togu Audio Line)",
  match   = {"tal-filter-2","tal filter 2"},
  vendor  = "Togu Audio Line",
  type    = "filter_mod_seq",
  roles   = {"Filter","Sequencer","Mod","IDM"},

  sections = {
    "FILTER CORE",
    "ENVELOPE / LFOs",
    "STEP SEQUENCER",
    "MIX / OUTPUT",
  },

  key_params = {
    cutoff       = "Filter-Cutoff",
    resonance    = "Filter-Resonanz",
    env_amount   = "Envelope-Menge",
    lfo_rate     = "LFO-Geschwindigkeit",
    seq_depth    = "Sequencer-Modulationsstärke",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

tal_vocoder2 = {
  id      = "tal_vocoder2",
  display = "TAL-Vocoder-2 (TAL-Togu Audio Line)",
  match   = {"tal-vocoder-2","tal vocoder 2"},
  vendor  = "Togu Audio Line",
  type    = "vocoder_fx",
  roles   = {"Vocoder","Formant","IDM","FX"},

  sections = {
    "BAND STRUCTURE",
    "CARRIER / MODULATOR",
    "FORMANT / SHIFT",
    "NOISE / SIBILANCE",
    "MIX / OUTPUT",
  },

  key_params = {
    band_levels  = "Pegel der Vocoder-Bänder",
    formant      = "Formant-/Timbre-Verschiebung",
    shift        = "Tonhöhen-/Bandverschiebung",
    noise_mix    = "Rausch-/Sibilance-Anteil",
    mix          = "Vocoder Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ni_supercharger = {
  id      = "ni_supercharger",
  display = "Supercharger (Native Instruments)",
  match   = {"supercharger %(native instruments%)","ni supercharger"},
  vendor  = "Native Instruments",
  type    = "compressor_saturation",
  roles   = {"Compressor","Saturation","IDM","Bus"},

  sections = {
    "INPUT / DRIVE",
    "PUNCH / CHARACTER",
    "MIX",
    "OUTPUT",
  },

  key_params = {
    input        = "Eingangslevel/Drive",
    punch        = "Punch/Transientenbetonung",
    character    = "Charakter/Helligkeit",
    mix          = "Dry/Wet (Parallel-Kompression)",
    output_gain  = "Output Gain",
  },
},

vox_teote = {
  id      = "vox_teote",
  display = "TEOTE (Voxengo)",
  match   = {"teote %(voxengo%)","voxengo teote"},
  vendor  = "Voxengo",
  type    = "dynamic_eq_auto",
  roles   = {"DynamicEQ","Master","Bus","IDM"},

  sections = {
    "TARGET CURVE",
    "BAND PROCESSING",
    "REACTION / TIME",
    "OUTPUT",
  },

  key_params = {
    target_curve = "Ziel-Frequenzkurve",
    range        = "Maximale Korrektur pro Band",
    speed        = "Reaktionsgeschwindigkeit",
    output_gain  = "Output Gain",
  },
},

tdr_molotok = {
  id      = "tdr_molotok",
  display = "TDR Molotok (Tokyo Dawn Labs)",
  match   = {"tdr molotok","molotok %(tokyo dawn labs%)"},
  vendor  = "Tokyo Dawn Labs",
  type    = "compressor_character",
  roles   = {"Compressor","Color","Bus","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "MODE / CHARACTER",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Kompressionsschwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    mode         = "Charakter/Modus",
    output_gain  = "Output Gain",
  },
},

tdr_slickeq = {
  id      = "tdr_slickeq",
  display = "TDR VOS SlickEQ (Tokyo Dawn Labs)",
  match   = {"tdr vos slickeq","slickeq %(tokyo dawn labs%)"},
  vendor  = "Tokyo Dawn Labs",
  type    = "eq_color",
  roles   = {"EQ","Tone","Bus","IDM"},

  sections = {
    "LOW / MID / HIGH BANDS",
    "EQ CURVES / MODE",
    "OUTPUT / SATURATION",
  },

  key_params = {
    low_band     = "Low-Band Gain/Frequenz",
    mid_band     = "Mid-Band Gain/Frequenz",
    high_band    = "High-Band Gain/Frequenz",
    mode         = "EQ-Modus/Kurvensatz",
    sat_amount   = "Sättigungsanteil (falls verfügbar)",
    output_gain  = "Output Gain",
  },
},

bx_masterdesk_pro = {
  id      = "bx_masterdesk_pro",
  display = "bx_masterdesk Pro (Plugin Alliance)",
  match   = {"bx_masterdesk pro","masterdesk pro %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "master_channel",
  roles   = {"Master","Channel","Tone","IDM"},

  sections = {
    "INPUT / FOUNDATION",
    "COMP / LIMIT",
    "TONE / CHARACTER",
    "M/S / WIDTH",
    "OUTPUT",
  },

  key_params = {
    foundation   = "Grundton-/Frequenzbalance",
    comp         = "Master-Kompressor",
    limiter      = "Limiter-/Ceiling-Level",
    tone         = "Charakter/Tonformung",
    width        = "Stereo-Breite",
    output_gain  = "Output Gain",
  },
},

bx_limiter_truepeak = {
  id      = "bx_limiter_truepeak",
  display = "bx_limiter True Peak (Plugin Alliance)",
  match   = {"bx_limiter true peak","bx limiter true peak"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "limiter_truepeak",
  roles   = {"Limiter","TruePeak","Master","IDM"},

  sections = {
    "THRESHOLD",
    "CEILING",
    "CHARACTER / LOOKAHEAD",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle",
    ceiling      = "Maximum-Level (True Peak Ceiling)",
    lookahead    = "Lookahead-Zeit",
    character    = "Limiter-Charakter",
    output_gain  = "Output Gain",
  },
},

bx_enhancer_pa = {
  id      = "bx_enhancer_pa",
  display = "bx_enhancer (Plugin Alliance)",
  match   = {"bx_enhancer","bx enhancer"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "enhancer_harmonic",
  roles   = {"Enhancer","Harmonics","Tone","IDM"},

  sections = {
    "LOW ENHANCE",
    "MID ENHANCE",
    "HIGH ENHANCE",
    "OUTPUT",
  },

  key_params = {
    low_enh      = "Low-Frequenz-Enhance",
    mid_enh      = "Mid-Frequenz-Enhance",
    high_enh     = "High-Frequenz-Enhance",
    output_gain  = "Output Gain",
  },
},

bx_glue_pa = {
  id      = "bx_glue_pa",
  display = "bx_glue (Plugin Alliance)",
  match   = {"bx_glue","bx glue"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "compressor_bus_glue",
  roles   = {"Compressor","Glue","Bus","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "MIX (PARALLEL)",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Kompressionsschwelle",
    ratio        = "Verhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    mix          = "Parallel-Mix",
    output_gain  = "Output Gain",
  },
},

bx_dyneq_v2 = {
  id      = "bx_dyneq_v2",
  display = "bx_dynEQ V2 (Plugin Alliance)",
  match   = {"bx_dyneq v2","bx dyneq v2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "dynamic_eq",
  roles   = {"DynamicEQ","Bus","Master","IDM"},

  sections = {
    "BANDS / FREQUENCIES",
    "THRESHOLD / RANGE",
    "ATTACK / RELEASE",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz pro Band",
    band_range   = "Maximale Absenkung/Anhebung",
    threshold    = "Einsatzschwelle",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    output_gain  = "Output Gain",
  },
},

bx_opto_pa = {
  id      = "bx_opto_pa",
  display = "bx_opto (Plugin Alliance)",
  match   = {"bx_opto","bx opto"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "compressor_opto",
  roles   = {"Compressor","Opto","Bus","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "MIX",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Kompressionsschwelle",
    ratio        = "Verhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    mix          = "Parallel-Kompression",
    output_gain  = "Output Gain",
  },
},

bx_megadual = {
  id      = "bx_megadual",
  display = "bx_megadual (Plugin Alliance)",
  match   = {"bx_megadual","bx megadual"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "amp_sim_dual",
  roles   = {"Amp","Guitar","LoFi","IDM"},

  sections = {
    "CHANNEL A / B",
    "GAIN / DRIVE",
    "EQ SECTION",
    "MASTER / OUTPUT",
  },

  key_params = {
    gain_a       = "Gain Kanal A",
    gain_b       = "Gain Kanal B",
    eq_settings  = "EQ-Parameter",
    master       = "Master-Level",
    output_gain  = "Output Gain",
  },
},

bx_hybrid_v2 = {
  id      = "bx_hybrid_v2",
  display = "bx_hybrid V2 (Plugin Alliance)",
  match   = {"bx_hybrid v2","bx hybrid v2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "eq_advanced",
  roles   = {"EQ","Tone","Master","IDM"},

  sections = {
    "LOW / LOW-MID",
    "MID / HIGH",
    "FILTERS",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz pro Band",
    band_gain    = "Gain pro Band",
    q_width      = "Bandbreite/Q",
    output_gain  = "Output Gain",
  },
},

bx_crispytuner = {
  id      = "bx_crispytuner",
  display = "bx_crispytuner (Plugin Alliance)",
  match   = {"bx_crispytuner","bx crispytuner"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "pitch_tuner",
  roles   = {"Pitch","Tuning","Vocal","IDM"},

  sections = {
    "SCALE / KEY",
    "SPEED / TRANSITION",
    "HUMANIZE / CORRECTION",
    "OUTPUT",
  },

  key_params = {
    scale        = "Tonleiter",
    key          = "Tonart",
    speed        = "Korrekturgeschwindigkeit",
    humanize     = "Natürlichkeitsgrad",
    output_gain  = "Output Gain",
  },
},

bx_crispyscale = {
  id      = "bx_crispyscale",
  display = "bx_crispyscale (Plugin Alliance)",
  match   = {"bx_crispyscale","bx crispyscale"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "scale_mapping_tool",
  roles   = {"Scale","Pitch","Utility","IDM"},

  sections = {
    "SCALE MAPPING",
    "INPUT / OUTPUT BEHAVIOR",
    "OUTPUT",
  },

  key_params = {
    scale        = "Ziel-Tonleiter",
    mapping      = "Skalen-Mapping-Regeln",
    output_gain  = "Output Gain",
  },
},

bx_control_v2 = {
  id      = "bx_control_v2",
  display = "bx_control V2 (Plugin Alliance)",
  match   = {"bx_control v2","bx control v2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "utility_ms_control",
  roles   = {"Utility","M/S","Monitor","IDM"},

  sections = {
    "GAIN / BALANCE",
    "M/S CONTROL",
    "MONO MAKER / WIDTH",
    "OUTPUT",
  },

  key_params = {
    gain         = "Gesamtgain",
    balance      = "Rechts/Links-Balance",
    mono_maker   = "Mono-Frequenzgrenze",
    width        = "Stereo-Breite",
    output_gain  = "Output Gain",
  },
},

bx_xl_v3 = {
  id      = "bx_xl_v3",
  display = "bx_XL V3 (Plugin Alliance)",
  match   = {"bx_xl v3","bx xl v3"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "multiband_limiter",
  roles   = {"Limiter","Multiband","Master","IDM"},

  sections = {
    "BAND SPLITS",
    "LIMITER PER BAND",
    "XL / LOUDNESS",
    "OUTPUT",
  },

  key_params = {
    crossover    = "Übergangsfrequenzen",
    band_limit   = "Limiter-Level pro Band",
    xl_amount    = "XL/Loudness-Intensität",
    output_gain  = "Output Gain",
  },
},

pa_the_oven = {
  id      = "pa_the_oven",
  display = "THE OVEN (Plugin Alliance)",
  match   = {"the oven","oven %(plugin alliance%)"},
  vendor  = "Plugin Alliance",
  type    = "tone_shaper_saturation",
  roles   = {"Saturation","Tone","Color","IDM"},

  sections = {
    "TEMP / HEAT",
    "CHARACTER / FLAVOR",
    "EQ CURVE",
    "OUTPUT",
  },

  key_params = {
    temp         = "Intensität der Bearbeitung",
    heat         = "Sättigungsgrad",
    flavor       = "Charakter/Flavor-Einstellung",
    eq_curve     = "Tonkurve",
    output_gain  = "Output Gain",
  },
},

neold_wunderlich = {
  id      = "neold_wunderlich",
  display = "NEOLD WUNDERLICH (Plugin Alliance)",
  match   = {"neold wunderlich"},
  vendor  = "NEOLD / Plugin Alliance",
  type    = "channelstrip_vintage",
  roles   = {"Channelstrip","Color","Bus","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "EQ SECTION",
    "COMPRESSOR",
    "OUTPUT",
  },

  key_params = {
    drive        = "Vorstufen-Sättigung",
    eq_settings  = "EQ-Parameter",
    comp         = "Kompressor-Parameter",
    output_gain  = "Output Gain",
  },
},

neold_u2a = {
  id      = "neold_u2a",
  display = "NEOLD U2A (Plugin Alliance)",
  match   = {"neold u2a"},
  vendor  = "NEOLD / Plugin Alliance",
  type    = "compressor_opto_vintage",
  roles   = {"Compressor","Opto","Color","IDM"},

  sections = {
    "GAIN / PEAK REDUCTION",
    "TIME CONSTANTS",
    "TONE / HF EMPHASIS",
    "OUTPUT",
  },

  key_params = {
    gain         = "Input-/Makeup-Gain",
    peak_reduc   = "Peak-Reduktionsstärke",
    time_const   = "Timing/Zeitcharakteristik",
    hf_emphasis  = "Höhenbetonung im Steuerpfad",
    output_gain  = "Output Gain",
  },
},

neold_u17 = {
  id      = "neold_u17",
  display = "NEOLD U17 (Plugin Alliance)",
  match   = {"neold u17"},
  vendor  = "NEOLD / Plugin Alliance",
  type    = "compressor_vari_mu_vintage",
  roles   = {"Compressor","Vari-Mu","Bus","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "TONE / COLOR",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    tone         = "Toncharakter/Färbung",
    output_gain  = "Output Gain",
  },
},

neold_oldtimer = {
  id      = "neold_oldtimer",
  display = "NEOLD OLDTIMER (Plugin Alliance)",
  match   = {"neold oldtimer"},
  vendor  = "NEOLD / Plugin Alliance",
  type    = "compressor_vintage",
  roles   = {"Compressor","Color","Bus","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "TONE / COLOR",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    tone         = "Toncharakter/Färbung",
    output_gain  = "Output Gain",
  },
},

--------------------------------------------------------------------
-- BATCH: STEREO / MASTER / DRIVE / UTILITY PLUGINS v1
--------------------------------------------------------------------

ozone_imager2 = {
  id      = "ozone_imager2",
  display = "Ozone Imager 2 (iZotope)",
  match   = {"ozone imager 2","ozone imager","izotope ozone imager"},
  vendor  = "iZotope",
  type    = "stereo_imager",
  roles   = {"Stereo","Imager","Utility","IDM"},

  sections = {
    "WIDTH CONTROL",
    "STEREOIZE I/II",
    "INPUT / OUTPUT",
    "METERING",
  },

  key_params = {
    width        = "Stereo-Breite (Verbreitern/Verengen des Signals)",
    stereoize    = "Stereoize-Modus (virtuelle Stereobreite aus Mono)",
    input_gain   = "Eingangspegel",
    output_gain  = "Ausgangspegel",
  },
},

a1_stereocontrol = {
  id      = "a1_stereocontrol",
  display = "A1StereoControl (A1AUDIO.de)",
  match   = {"a1stereocontrol","a1 stereo control","a1 stereo"}, 
  vendor  = "A1AUDIO.de",
  type    = "stereo_tool",
  roles   = {"Stereo","Imager","Utility","IDM"},

  sections = {
    "EASY MODE (PAN / WIDTH)",
    "SAFE BASS",
    "EXPERT MODE (PAN LAW / CURVE)",
    "OUTPUT",
  },

  key_params = {
    pan          = "Panorama-Position",
    width        = "Stereo-Breite (Expand/Collapse des Stereobilds)",
    safe_bass    = "Frequenzgrenze, unterhalb derer das Signal mono zentriert wird",
    pan_law      = "Pan-Law (0/-3/-6 dB)",
    pan_curve    = "Pankennlinie (linear/log/sin-cos)",
    output_gain  = "Output Gain",
  },
},

a1_triggergate = {
  id      = "a1_triggergate",
  display = "A1TriggerGate (A1AUDIO.de)",
  match   = {"a1triggergate","a1 triggergate","a1 trigger gate"},
  vendor  = "A1AUDIO.de",
  type    = "rhythmic_gate",
  roles   = {"Gate","Rhythmic","Stutter","IDM"},

  sections = {
    "STEP SEQUENCER",
    "GATE ENVELOPE",
    "FILTER / DELAY FX",
    "MIX / OUTPUT",
  },

  key_params = {
    step_length  = "Länge der Steps im Pattern",
    step_levels  = "Lautstärke pro Step",
    gate_attack  = "Attack des Gates",
    gate_release = "Release des Gates",
    filter       = "Filter-Frequenz für FX-Sektion",
    delay_mix    = "Delay-Anteil",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ozone12_eq = {
  id      = "ozone12_eq",
  display = "Ozone 12 Equalizer (iZotope)",
  match   = {"ozone 12 equalizer","ozone equalizer","ozone eq"},
  vendor  = "iZotope",
  type    = "eq_digital",
  roles   = {"EQ","Master","Bus","IDM"},

  sections = {
    "EQ BANDS",
    "FILTER SLOPES / TYPES",
    "MID/SIDE / L/R ROUTING",
    "GAIN / OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz der EQ-Bänder",
    band_gain    = "Gain pro Band",
    band_q       = "Q/Bandbreite pro Band",
    mode_ms      = "Betrieb im Mid/Side- oder L/R-Modus",
    output_gain  = "Output Gain",
  },
},

bluecat_triple_eq = {
  id      = "bluecat_triple_eq",
  display = "Blue Cat's Triple EQ 4 (Stereo) (Blue Cat Audio)",
  match   = {"blue cat's triple eq","blue cat triple eq"},
  vendor  = "Blue Cat Audio",
  type    = "eq_3band",
  roles   = {"EQ","Tone","Utility","IDM"},

  sections = {
    "LOW SHELF",
    "MID PEAK",
    "HIGH SHELF",
    "OUTPUT",
  },

  key_params = {
    low_freq     = "Frequenz Low-Shelf",
    low_gain     = "Gain Low-Shelf",
    mid_freq     = "Frequenz Peak-Band",
    mid_gain     = "Gain Peak-Band",
    mid_q        = "Q/Breite Peak-Band",
    high_freq    = "Frequenz High-Shelf",
    high_gain    = "Gain High-Shelf",
    output_gain  = "Output Gain",
  },
},

bluecat_gain3 = {
  id      = "bluecat_gain3",
  display = "Blue Cat's Gain 3 (Stereo) (Blue Cat Audio)",
  match   = {"blue cat's gain 3","blue cat gain 3"},
  vendor  = "Blue Cat Audio",
  type    = "gain_utility",
  roles   = {"Gain","Utility","Automation","IDM"},

  sections = {
    "GAIN",
    "PAN / L-R BALANCE",
    "LINK / GROUP",
    "OUTPUT",
  },

  key_params = {
    gain         = "Verstärkung/Abschwächung",
    pan          = "Panorama-Position",
    link_group   = "Verlinkung mit anderen Instanzen",
    output_gain  = "Output Gain",
  },
},

bluecat_freqanalyst2 = {
  id      = "bluecat_freqanalyst2",
  display = "Blue Cat's FreqAnalyst 2 (Stereo) (Blue Cat Audio)",
  match   = {"blue cat's freqanalyst 2","blue cat freqanalyst 2"},
  vendor  = "Blue Cat Audio",
  type    = "spectrum_analyzer",
  roles   = {"Analyzer","Spectrum","Utility"},

  sections = {
    "DISPLAY RANGE",
    "TIME RESPONSE",
    "SMOOTH / RESOLUTION",
    "OUTPUT",
  },

  key_params = {
    min_freq     = "Untere Anzeigefrequenz",
    max_freq     = "Obere Anzeigefrequenz",
    response     = "Zeitliche Glättung",
    resolution   = "Spektrale Auflösung",
  },
},

bx_solo = {
  id      = "bx_solo",
  display = "bx_solo (Plugin Alliance)",
  match   = {"bx_solo","bx solo"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "monitor_ms",
  roles   = {"Monitor","Utility","M/S","IDM"},

  sections = {
    "L/R SOLO",
    "M/S SOLO",
    "GAIN",
  },

  key_params = {
    solo_mode    = "Solo-Modus (L/R/M/S)",
    gain         = "Gesamtgain",
  },
},

bx_shredspread = {
  id      = "bx_shredspread",
  display = "bx_shredspread (Plugin Alliance)",
  match   = {"bx_shredspread","bx shredspread"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "stereo_spreader",
  roles   = {"Stereo","Width","Guitar","IDM"},

  sections = {
    "SPREAD",
    "TONE / COLOR",
    "INPUT / OUTPUT",
  },

  key_params = {
    spread       = "Verbreiterung des Gitarren-/Stereo-Signals",
    tone         = "Tonformung/Helligkeit",
    input_gain   = "Input-Level",
    output_gain  = "Output Gain",
  },
},

bx_meter = {
  id      = "bx_meter",
  display = "bx_meter (Plugin Alliance)",
  match   = {"bx_meter","bx meter"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "metering_loudness",
  roles   = {"Meter","Loudness","Utility"},

  sections = {
    "PEAK / RMS / LUFS",
    "SCALE / RANGE",
    "BALANCE / CORRELATION",
  },

  key_params = {
    scale        = "Pegel-Skala",
    integration  = "Lautheits-Integrationszeit",
    balance      = "Links/Rechts-Balance-Anzeige",
  },
},

bx_metal2 = {
  id      = "bx_metal2",
  display = "bx_metal2 (Plugin Alliance)",
  match   = {"bx_metal2","bx metal2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "distortion_pedal",
  roles   = {"Distortion","Guitar","Drums","IDM"},

  sections = {
    "DRIVE",
    "TONE",
    "LEVEL",
  },

  key_params = {
    drive        = "Verzerrungsgrad",
    tone         = "Klangblende/Helligkeit",
    level        = "Ausgangspegel",
  },
},

bx_megasingle = {
  id      = "bx_megasingle",
  display = "bx_megasingle (Plugin Alliance)",
  match   = {"bx_megasingle","bx megasingle"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "amp_sim",
  roles   = {"Amp","Guitar","LoFi","IDM"},

  sections = {
    "CHANNEL / GAIN",
    "EQ SECTION",
    "PRESENCE / RESONANCE",
    "MASTER / OUTPUT",
  },

  key_params = {
    gain         = "Vorstufen-Gain",
    bass         = "Bass-EQ",
    mid          = "Mitten-EQ",
    treble       = "Höhen-EQ",
    presence     = "Höhen-Präsenz",
    resonance    = "Tiefen-Resonanz",
    master       = "Master-Level",
    output_gain  = "Output Gain",
  },
},

bx_masterdesk_tp = {
  id      = "bx_masterdesk_tp",
  display = "bx_masterdesk True Peak (Plugin Alliance)",
  match   = {"bx_masterdesk true peak","masterdesk true peak"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "master_channel_truepeak",
  roles   = {"Master","Channel","TruePeak","IDM"},

  sections = {
    "INPUT / FOUNDATION",
    "COMP / LIMIT",
    "TONE / CHARACTER",
    "TRUE PEAK / OUTPUT",
  },

  key_params = {
    foundation   = "Grundbalance/Tonalität",
    compressor   = "Kompressor-Intensität",
    limiter      = "Limiter-Level",
    truepeak     = "True-Peak Ceiling",
    tone         = "Tonal-Charakter",
    output_gain  = "Output Gain",
  },
},

bx_masterdesk_classic = {
  id      = "bx_masterdesk_classic",
  display = "bx_masterdesk Classic (Plugin Alliance)",
  match   = {"bx_masterdesk classic","masterdesk classic"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "master_channel",
  roles   = {"Master","Channel","Tone","IDM"},

  sections = {
    "INPUT / FOUNDATION",
    "COMP / LIMIT",
    "TONE / CHARACTER",
    "OUTPUT",
  },

  key_params = {
    foundation   = "Grundbalance/Tonalität",
    compressor   = "Kompressor-Intensität",
    limiter      = "Limiter-Level",
    tone         = "Tonal-Charakter",
    output_gain  = "Output Gain",
  },
},

bx_masterdesk = {
  id      = "bx_masterdesk",
  display = "bx_masterdesk (Plugin Alliance)",
  match   = {"bx_masterdesk","masterdesk %(plugin alliance%)"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "master_channel",
  roles   = {"Master","Channel","Tone","IDM"},

  sections = {
    "INPUT / FOUNDATION",
    "COMP / LIMIT",
    "TONE / CHARACTER",
    "OUTPUT",
  },

  key_params = {
    foundation   = "Grundbalance/Tonalität",
    compressor   = "Kompressor-Intensität",
    limiter      = "Limiter-Level",
    tone         = "Tonal-Charakter",
    output_gain  = "Output Gain",
  },
},

bx_limiter_std = {
  id      = "bx_limiter_std",
  display = "bx_limiter (Plugin Alliance)",
  match   = {"bx_limiter","bx limiter"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "limiter",
  roles   = {"Limiter","Master","Bus","IDM"},

  sections = {
    "THRESHOLD",
    "CEILING",
    "CHARACTER / LOOKAHEAD",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Einsatzschwelle des Limiters",
    ceiling      = "Maximale Ausgangslautstärke",
    lookahead    = "Lookahead-Zeit",
    character    = "Limiter-Charakter",
    output_gain  = "Output Gain",
  },
},

fetish_comp = {
  id      = "fetish_comp",
  display = "FETish (AnalogObsession)",
  match   = {"fetish","analogobsession fetish","analog obsession fetish"},
  vendor  = "AnalogObsession",
  type    = "compressor_fet",
  roles   = {"Compressor","FET","Drums","IDM"},

  sections = {
    "INPUT / THRESHOLD",
    "RATIO",
    "ATTACK / RELEASE",
    "HPF / SIDECHAIN",
    "OUTPUT",
  },

  key_params = {
    input        = "Eingangslevel/Schwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    hpf_sidechain= "Hochpass im Sidechain",
    output_gain  = "Output Gain",
  },
},

fetdrive = {
  id      = "fetdrive",
  display = "FetDrive (AnalogObsession)",
  match   = {"fetdrive","fet drive","analogobsession fetdrive"},
  vendor  = "AnalogObsession",
  type    = "saturation_drive",
  roles   = {"Saturation","Drive","IDM","Drums"},

  sections = {
    "INPUT / DRIVE",
    "TONE",
    "OUTPUT",
  },

  key_params = {
    drive        = "Grad der Verzerrung/Sättigung",
    tone         = "Tonblende/Helligkeit",
    output_gain  = "Output Gain",
  },
},

fetsnap = {
  id      = "fetsnap",
  display = "FetSnap (AnalogObsession)",
  match   = {"fetsnap","fet snap","analogobsession fetsnap"},
  vendor  = "AnalogObsession",
  type    = "transient_shaper",
  roles   = {"Transient","Drums","Punch","IDM"},

  sections = {
    "ATTACK",
    "SUSTAIN",
    "FILTER / FOCUS",
    "OUTPUT",
  },

  key_params = {
    attack       = "Anhebung/Absenkung der Attack-Phase",
    sustain      = "Anhebung/Absenkung der Sustain-Phase",
    focus        = "Frequenzfokus für die Bearbeitung",
    output_gain  = "Output Gain",
  },
},

britchannel = {
  id      = "britchannel",
  display = "BritChannel (AnalogObsession)",
  match   = {"britchannel","brit channel","analogobsession britchannel"},
  vendor  = "AnalogObsession",
  type    = "channelstrip_brit",
  roles   = {"Channelstrip","EQ","Comp","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "EQ SECTION",
    "DYNAMICS",
    "OUTPUT",
  },

  key_params = {
    preamp       = "Vorstufen-Sättigung",
    eq_settings  = "EQ-Einstellungen (Low/Mid/High)",
    dynamics     = "Kompressor-/Gate-Parameter",
    output_gain  = "Output Gain",
  },
},

britpre = {
  id      = "britpre",
  display = "BritPre (AnalogObsession)",
  match   = {"britpre","brit pre","analogobsession britpre"},
  vendor  = "AnalogObsession",
  type    = "preamp_color",
  roles   = {"Preamp","Color","IDM"},

  sections = {
    "INPUT",
    "TONE",
    "OUTPUT",
  },

  key_params = {
    input        = "Eingangslevel/Sättigung",
    tone         = "Klangblende/Tonformung",
    output_gain  = "Output Gain",
  },
},

britpressor = {
  id      = "britpressor",
  display = "Britpressor (AnalogObsession)",
  match   = {"britpressor","brit pressor","analogobsession britpressor"},
  vendor  = "AnalogObsession",
  type    = "compressor_brit",
  roles   = {"Compressor","Bus","Drums","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "HPF / SIDECHAIN",
    "OUTPUT",
  },

  key_params = {
    threshold    = "Kompressionsschwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    hpf_sidechain= "Hochpass im Sidechain",
    output_gain  = "Output Gain",
  },
},

overheat = {
  id      = "overheat",
  display = "OverHeat (Sampleson)",
  match   = {"overheat %(sampleson%)","sampleson overheat"},
  vendor  = "Sampleson",
  type    = "saturation_lofi",
  roles   = {"Saturation","LoFi","IDM","Color"},

  sections = {
    "DRIVE",
    "TONE / COLOR",
    "MIX",
    "OUTPUT",
  },

  key_params = {
    drive        = "Sättigungsgrad/Verzerrung",
    tone         = "Klangfarbe",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

bark_of_dog3 = {
  id      = "bark_of_dog3",
  display = "Bark of Dog 3 (Boz Digital Labs)",
  match   = {"bark of dog 3","bark of dog","boz digital bark of dog"},
  vendor  = "Boz Digital Labs",
  type    = "lowend_enhancer",
  roles   = {"Bass","Sub","Kick","IDM"},

  sections = {
    "FREQUENCY",
    "BOOST / ATTEN",
    "MODE (SUB/THIN etc.)",
    "OUTPUT",
  },

  key_params = {
    freq         = "Ziel-Frequenz des Low-End-Focus",
    boost        = "Anhebung im Tiefenbereich",
    atten        = "Absenkung benachbarter Bereiche",
    mode         = "Verhaltensmodus (z.B. SUB/BARK/??? je nach Version)",
    output_gain  = "Output Gain",
  },
},

beat_slammer = {
  id      = "beat_slammer",
  display = "Beat Slammer (BABY Audio)",
  match   = {"beat slammer","baby audio beat slammer"},
  vendor  = "BABY Audio",
  type    = "compressor_oneknob",
  roles   = {"Compressor","Drums","IDM","Punch"},

  sections = {
    "AMOUNT / INTENSITY",
    "TONE / COLOR",
    "MIX",
    "OUTPUT",
  },

  key_params = {
    amount       = "Stärke der Kompression/Verzerrung",
    tone         = "Helligkeit/Klangfärbung",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

acon_multiply = {
  id      = "acon_multiply",
  display = "Acon Digital Multiply (Acon Digital)",
  match   = {"multiply %(acon digital%)","acon digital multiply"},
  vendor  = "Acon Digital",
  type    = "chorus_multivoice",
  roles   = {"Chorus","Width","Texture","IDM"},

  sections = {
    "VOICE COUNT",
    "RATE / DEPTH",
    "SPREAD / WIDTH",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    voices       = "Anzahl der Modulationsstimmen",
    rate         = "Modulationsgeschwindigkeit",
    depth        = "Modulationstiefe",
    spread       = "Stereo-Breite",
    tone         = "Tonblende/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

gsatplus = {
  id      = "gsatplus",
  display = "GSatPlus (TBProAudio)",
  match   = {"gsatplus","g-sat plus","tbproaudio gsatplus"},
  vendor  = "TBProAudio",
  type    = "saturation_multimode",
  roles   = {"Saturation","Drive","Master","IDM"},

  sections = {
    "INPUT / TRIM",
    "SATURATION (EVEN/ODD)",
    "CLIP / PROTECTION",
    "MIX / MONITOR",
    "OUTPUT",
  },

  key_params = {
    input_trim   = "Eingangs-Trim",
    odd_harm     = "Anteil ungerader Harmonischer",
    even_harm    = "Anteil gerader Harmonischer",
    clip_protect = "Clip-Schutz/Soft-Clip",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

flux_mini2 = {
  id      = "flux_mini2",
  display = "Flux Mini 2 (Caelum Audio)",
  match   = {"flux mini 2","flux mini2","caelum audio flux mini 2"},
  vendor  = "Caelum Audio",
  type    = "modulation_shaper",
  roles   = {"Modulation","Rhythmic","Filter","IDM"},

  sections = {
    "CUSTOM GRAPH SHAPER",
    "AMP / FILTER / RESO / MIX AMOUNT",
    "SYNC / RATE",
    "MIDI TRIGGER / CC OUT",
  },

  key_params = {
    graph_shape  = "Kurve für Modulationsverlauf",
    amp_amount   = "Modulationsstärke Lautstärke",
    filter_amount= "Modulationsstärke Filter-Cutoff",
    reso_amount  = "Modulationsstärke Resonanz",
    mix_amount   = "Modulationsstärke Mix",
    rate         = "Tempo/Rate",
    sync_mode    = "Sync-/One-Shot-/Free-Modus",
  },
},

clipshifter = {
  id      = "clipshifter",
  display = "ClipShifter (LVC-Audio)",
  match   = {"clipshifter","lvc-audio clipshifter","lvc audio clipshifter"},
  vendor  = "LVC-Audio",
  type    = "clipper_dynamic",
  roles   = {"Clipper","Saturation","Drums","IDM"},

  sections = {
    "THRESHOLD / CLIP LEVEL",
    "CLIP SHAPE",
    "HARMONICS (EVEN/ODD)",
    "IN / OUT / MIX",
  },

  key_params = {
    threshold    = "Schwelle des Clippings",
    clip_shape   = "Form der Clipping-Kurve (hart/weich)",
    harmonics    = "Verhältnis gerader/ungerader Harmonischer",
    input_gain   = "Input-Level",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

--------------------------------------------------------------------
-- BATCH: CONSOLE / BUS / ANALOG / SPECIAL FX v1
--------------------------------------------------------------------

tube_saturator_vintage = {
  id      = "tube_saturator_vintage",
  display = "Tube Saturator Vintage (Wave Arts)",
  match   = {"tube saturator vintage","wave arts tube saturator"},
  vendor  = "Wave Arts",
  type    = "saturation_tube",
  roles   = {"Saturation","Tube","Color","IDM"},

  sections = {
    "INPUT / DRIVE",
    "TONE / EQ",
    "POWER AMP / SATURATION",
    "OUTPUT",
  },

  key_params = {
    input_gain   = "Eingangspegel/Drive in die Röhrensättigung",
    drive        = "Zusätzliche Ansteuerung der Röhrensektion",
    tone         = "Klangblende/EQ für Grundcharakter",
    power_amp    = "Intensität der Endstufen-Simulation",
    output_gain  = "Output Gain",
  },
},

bx_console_ssl_9000j = {
  id      = "bx_console_ssl_9000j",
  display = "bx_console SSL 9000 J (Plugin Alliance)",
  match   = {"bx_console ssl 9000 j","ssl 9000 j console"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

bx_console_ssl_4000g = {
  id      = "bx_console_ssl_4000g",
  display = "bx_console SSL 4000 G (Plugin Alliance)",
  match   = {"bx_console ssl 4000 g","ssl 4000 g console"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION (G-Style)",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

bx_console_ssl_4000e = {
  id      = "bx_console_ssl_4000e",
  display = "bx_console SSL 4000 E (Plugin Alliance)",
  match   = {"bx_console ssl 4000 e","ssl 4000 e console"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION (E-Style)",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

bx_console_n = {
  id      = "bx_console_n",
  display = "bx_console N (Plugin Alliance)",
  match   = {"bx_console n","neve console n"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel_neve",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION (Neve)",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

bx_console_focusrite = {
  id      = "bx_console_focusrite",
  display = "bx_console Focusrite SC (Plugin Alliance)",
  match   = {"bx_console focusrite sc","focusrite sc console"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel_focusrite",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION (Focusrite)",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

bx_console_amek_9099 = {
  id      = "bx_console_amek_9099",
  display = "bx_console AMEK 9099 (Plugin Alliance)",
  match   = {"bx_console amek 9099","amek 9099 console"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel_amek",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION (AMEK)",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

bx_console_amek_200 = {
  id      = "bx_console_amek_200",
  display = "bx_console AMEK 200 (Plugin Alliance)",
  match   = {"bx_console amek 200","amek 200 console"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "console_channel_amek",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / GAIN",
    "FILTERS (HP/LP)",
    "EQ SECTION (AMEK 200)",
    "DYNAMICS (COMP/GATE)",
    "V-GAIN / TMT / OUTPUT",
  },

  key_params = {
    input_gain   = "Vorstufenpegel",
    hp_filter    = "Hochpass-Kap",
    lp_filter    = "Tiefpass-Kap",
    eq_bands     = "EQ-Band-Gains/Frequenzen",
    comp_thresh  = "Kompressor-Schwelle",
    comp_ratio   = "Kompressionsverhältnis",
    gate_thresh  = "Gate-Schwelle",
    v_gain       = "Virtuelle Konsolensättigung (Analog/TMT)",
    output_gain  = "Output Gain",
  },
},

zl_equalizer = {
  id      = "zl_equalizer",
  display = "ZL Equalizer (ZL)",
  match   = {"zl equalizer","zl eq"},
  vendor  = "ZL",
  type    = "eq_coloring",
  roles   = {"EQ","Tone","Bus","IDM"},

  sections = {
    "LOW / LOW-MID",
    "MID / HIGH",
    "FILTERS",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz pro Band",
    band_gain    = "Gain pro Band",
    q_width      = "Bandbreite/Q",
    output_gain  = "Output Gain",
  },
},

lindell_69_buss = {
  id      = "lindell_69_buss",
  display = "Lindell 69 Buss (Plugin Alliance)",
  match   = {"lindell 69 buss"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "bus_channel_strip",
  roles   = {"Bus","Channelstrip","Tone","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "EQ SECTION (69)",
    "COMP / LIMIT",
    "OUTPUT",
  },

  key_params = {
    drive        = "Vorstufen-Sättigung",
    eq_settings  = "EQ-Parameter des 69er-Designs",
    comp         = "Kompressor-/Limiter-Parameter",
    output_gain  = "Output Gain",
  },
},

lindell_50_buss = {
  id      = "lindell_50_buss",
  display = "Lindell 50 Buss (Plugin Alliance)",
  match   = {"lindell 50 buss"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "bus_channel_strip",
  roles   = {"Bus","Channelstrip","Tone","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "EQ SECTION (API-Style)",
    "COMP / LIMIT",
    "OUTPUT",
  },

  key_params = {
    drive        = "Vorstufen-Sättigung",
    eq_settings  = "API-Style EQ-Parameter",
    comp         = "Kompressor-/Limiter-Parameter",
    output_gain  = "Output Gain",
  },
},

jetzl = {
  id      = "jetzl",
  display = "JETZL (Acqua)",
  match   = {"jetzl","acqua jetzl"},
  vendor  = "Acqua",
  type    = "channel_strip_acqua",
  roles   = {"Channelstrip","Tone","Bus","IDM"},

  sections = {
    "PREAMP / INPUT",
    "EQ SECTION",
    "DYNAMICS",
    "OUTPUT",
  },

  key_params = {
    input_gain   = "Eingangspegel/Sättigung",
    eq_settings  = "EQ-Parameter",
    dynamics     = "Kompressor-/Gate-Parameter",
    output_gain  = "Output Gain",
  },
},

jetmixzl = {
  id      = "jetmixzl",
  display = "JETMIXZL (Acqua)",
  match   = {"jetmixzl","acqua jetmixzl"},
  vendor  = "Acqua",
  type    = "bus_processor_acqua",
  roles   = {"Bus","Tone","Glue","IDM"},

  sections = {
    "INPUT / DRIVE",
    "TONE / EQ",
    "DYNAMICS / GLUE",
    "OUTPUT",
  },

  key_params = {
    input_gain   = "Input-/Drive-Level",
    tone         = "Tonalformung/EQ",
    glue         = "Bus-Kompression/Glue",
    output_gain  = "Output Gain",
  },
},

io_panner = {
  id      = "io_panner",
  display = "IO/Panner (benoit serrano)",
  match   = {"io/panner","io panner %(benoit serrano%)"},
  vendor  = "benoit serrano",
  type    = "panner_advanced",
  roles   = {"Panner","Stereo","Utility","IDM"},

  sections = {
    "PAN / BALANCE",
    "PAN LAW / CURVE",
    "DYNAMIC / MOD",
    "OUTPUT",
  },

  key_params = {
    pan          = "Panorama-Position",
    balance      = "L/R-Balance",
    pan_law      = "Pan-Gesetz",
    pan_curve    = "Form des Pan-Fade",
    output_gain  = "Output Gain",
  },
},

bx_xl_v2 = {
  id      = "bx_xl_v2",
  display = "bx_XL V2 (Plugin Alliance)",
  match   = {"bx_xl v2","bx xl v2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "multiband_limiter",
  roles   = {"Limiter","Multiband","Master","IDM"},

  sections = {
    "BAND SPLITS",
    "LIMITER PER BAND",
    "XL / LOUDNESS",
    "OUTPUT",
  },

  key_params = {
    crossover    = "Übergangsfrequenzen",
    band_limit   = "Limiter-Level pro Band",
    xl_amount    = "XL/Loudness-Intensität",
    output_gain  = "Output Gain",
  },
},

wave_outobugi = {
  id      = "wave_outobugi",
  display = "Wave (Outobugi)",
  match   = {"wave %(outobugi%)","outobugi wave"},
  vendor  = "Outobugi",
  type    = "fx_special_wave",
  roles   = {"FX","Modulation","Experimental","IDM"},

  sections = {
    "WAVE SHAPE",
    "RATE / DEPTH",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    wave_shape   = "Form der Wellenmodulation",
    rate         = "Modulationsgeschwindigkeit",
    depth        = "Modulationstiefe",
    tone         = "Tonformung/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

vision4x = {
  id      = "vision4x",
  display = "VISION 4X (Excite Audio)",
  match   = {"vision 4x","excite audio vision 4x"},
  vendor  = "Excite Audio",
  type    = "multi_analyzer",
  roles   = {"Analyzer","Spectrum","Stereo","Utility"},

  sections = {
    "SPECTRUM",
    "WAVEFORM",
    "STEREO FIELD",
    "LOUDNESS / DYNAMICS",
  },

  key_params = {
    spectrum_range = "Frequenzbereich der Spektrumanzeige",
    time_window    = "Zeitfenster/Glättung",
    stereo_view    = "Stereo-Darstellung/Modus",
    dynamics_view  = "Anzeige der Dynamik/Lautheit",
  },
},

tupre = {
  id      = "tupre",
  display = "TuPRE (AnalogObsession)",
  match   = {"tupre","analogobsession tupre","analog obsession tupre"},
  vendor  = "AnalogObsession",
  type    = "preamp_tube",
  roles   = {"Preamp","Tube","Color","IDM"},

  sections = {
    "INPUT / DRIVE",
    "TONE / COLOR",
    "OUTPUT",
  },

  key_params = {
    input        = "Vorstufen-Gain/Drive",
    tone         = "Tonblende/Tonalcharakter",
    output_gain  = "Output Gain",
  },
},

stereo_touch = {
  id      = "stereo_touch",
  display = "Stereo Touch (Voxengo)",
  match   = {"stereo touch","voxengo stereo touch"},
  vendor  = "Voxengo",
  type    = "stereo_enhancer",
  roles   = {"Stereo","Width","Delay","IDM"},

  sections = {
    "DELAY LINES",
    "PAN / WIDTH",
    "TONE / FILTER",
    "OUTPUT",
  },

  key_params = {
    delay_time   = "Delayzeit der Stereokanäle",
    pan          = "Stereoverteilung",
    width        = "Stereo-Breite",
    tone         = "Tonformung/Filter",
    output_gain  = "Output Gain",
  },
},

span_plus = {
  id      = "span_plus",
  display = "SPAN Plus (Voxengo)",
  match   = {"span plus","voxengo span plus"},
  vendor  = "Voxengo",
  type    = "spectrum_analyzer_advanced",
  roles   = {"Analyzer","Spectrum","Utility"},

  sections = {
    "SPECTRUM CONFIG",
    "AVERAGING / SMOOTH",
    "CHANNEL ROUTING",
    "OUTPUT",
  },

  key_params = {
    range        = "Frequenzbereich/Skalierung",
    avg_time     = "Zeitliche Mittelung",
    smoothing    = "Spektrale Glättung",
    routing      = "Kanalzuweisung/Sidechain",
  },
},

rezzoeq = {
  id      = "rezzoeq",
  display = "RezzoEQ (EvilTurtleProductions)",
  match   = {"rezzoeq","rezzo eq"},
  vendor  = "EvilTurtleProductions",
  type    = "eq_resonant",
  roles   = {"EQ","Resonance","SoundDesign","IDM"},

  sections = {
    "BANDS",
    "RESONANCE CONTROL",
    "FILTER / SHAPE",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz der Bänder",
    band_gain    = "Gain/Boost pro Band",
    resonance    = "Resonanzintensität",
    output_gain  = "Output Gain",
  },
},

refire_outobugi = {
  id      = "refire_outobugi",
  display = "Refire (Outobugi)",
  match   = {"refire %(outobugi%)","outobugi refire"},
  vendor  = "Outobugi",
  type    = "fx_dynamic_fire",
  roles   = {"FX","Dynamic","Distortion","IDM"},

  sections = {
    "INPUT / DRIVE",
    "CHARACTER / COLOR",
    "FILTER",
    "MIX / OUTPUT",
  },

  key_params = {
    drive        = "Verzerrungs-/Sättigungsgrad",
    character    = "Charakter des Effekts",
    filter       = "Filter/Tonformung",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

alton_limiter = {
  id      = "alton_limiter",
  display = "Platone Studio Alton Limiter (Platone Studio Ltd.)",
  match   = {"alton limiter","platone studio alton limiter"},
  vendor  = "Platone Studio",
  type    = "limiter_modern",
  roles   = {"Limiter","Master","Bus","IDM"},

  sections = {
    "THRESHOLD",
    "CEILING",
    "CHARACTER / RELEASE",
    "OUTPUT / METERING",
  },

  key_params = {
    threshold    = "Einsatzschwelle des Limiters",
    ceiling      = "Maximalpegel",
    release      = "Release-Zeit",
    character    = "Verhalten/Charakter des Limiters",
    output_gain  = "Output Gain",
  },
},

lindell_te100 = {
  id      = "lindell_te100",
  display = "Lindell TE-100 (Plugin Alliance)",
  match   = {"lindell te-100","lindell te100"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "eq_passive",
  roles   = {"EQ","Tone","Bus","IDM"},

  sections = {
    "LOW / LOW-MID",
    "MID / HIGH",
    "BANDWIDTH / CURVE",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz der Bänder",
    band_gain    = "Gain pro Band",
    bandwidth    = "Bandbreite/Curve",
    output_gain  = "Output Gain",
  },
},

lindell_sbc = {
  id      = "lindell_sbc",
  display = "Lindell SBC (Plugin Alliance)",
  match   = {"lindell sbc"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "compressor_bus_vca",
  roles   = {"Compressor","Bus","Glue","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "HPF SIDECHAIN",
    "MIX / OUTPUT",
  },

  key_params = {
    threshold    = "Kompressionsschwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    hpf_sidechain= "Hochpass im Sidechain",
    mix          = "Parallel-Mix",
    output_gain  = "Output Gain",
  },
},

lindell_pex500 = {
  id      = "lindell_pex500",
  display = "Lindell PEX-500 (Plugin Alliance)",
  match   = {"lindell pex-500","lindell pex 500"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "eq_pultec_style",
  roles   = {"EQ","Tone","Bus","IDM"},

  sections = {
    "LOW BAND (BOOST/ATTEN)",
    "HIGH BAND (BOOST/ATTEN)",
    "BANDWIDTH",
    "OUTPUT",
  },

  key_params = {
    low_freq     = "Low-Frequenz",
    low_boost    = "Low-Boost",
    low_atten    = "Low-Attenuation",
    high_freq    = "High-Frequenz",
    high_boost   = "High-Boost",
    high_atten   = "High-Attenuation",
    bandwidth    = "Bandbreite",
    output_gain  = "Output Gain",
  },
},

lindell_mu66 = {
  id      = "lindell_mu66",
  display = "Lindell MU-66 (Plugin Alliance)",
  match   = {"lindell mu-66","lindell mu66"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "compressor_vari_mu",
  roles   = {"Compressor","Vari-Mu","Bus","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "SIDECHAIN / HPF",
    "MIX / OUTPUT",
  },

  key_params = {
    threshold    = "Kompressionsschwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    sidechain    = "Sidechain/HPF-Parameter",
    mix          = "Parallel-Mix",
    output_gain  = "Output Gain",
  },
},

lindell_7x500 = {
  id      = "lindell_7x500",
  display = "Lindell 7X-500 (Plugin Alliance)",
  match   = {"lindell 7x-500","lindell 7x 500"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "compressor_fet",
  roles   = {"Compressor","FET","Drums","IDM"},

  sections = {
    "INPUT / THRESHOLD",
    "RATIO",
    "ATTACK / RELEASE",
    "HPF / SIDECHAIN",
    "OUTPUT",
  },

  key_params = {
    input        = "Eingangspegel/Schwelle",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    hpf_sidechain= "Hochpass im Sidechain",
    output_gain  = "Output Gain",
  },
},

lindell_6x500 = {
  id      = "lindell_6x500",
  display = "Lindell 6X-500 (Plugin Alliance)",
  match   = {"lindell 6x-500","lindell 6x 500"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "preamp_eq",
  roles   = {"Preamp","EQ","Tone","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "EQ LOW / HIGH",
    "OUTPUT",
  },

  key_params = {
    drive        = "Vorstufen-Sättigung",
    low_gain     = "Low-Gain",
    low_freq     = "Low-Frequenz",
    high_gain    = "High-Gain",
    high_freq    = "High-Frequenz",
    output_gain  = "Output Gain",
  },
},

lindell_69_channel = {
  id      = "lindell_69_channel",
  display = "Lindell 69 Channel (Plugin Alliance)",
  match   = {"lindell 69 channel"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "channelstrip",
  roles   = {"Channelstrip","Tone","Bus","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "EQ SECTION (69)",
    "DYNAMICS",
    "OUTPUT",
  },

  key_params = {
    drive        = "Vorstufen-Sättigung",
    eq_settings  = "EQ-Parameter",
    dynamics     = "Kompressor-/Gate-Parameter",
    output_gain  = "Output Gain",
  },
},

--------------------------------------------------------------------
-- BATCH: IDM / SPECTRAL / UNFILTERED / VALHALLA v1
--------------------------------------------------------------------

spectralautopan = {
  id      = "spectralautopan",
  display = "SpectralAutopan v1.5 (AnarchySoundSoftware)",
  match   = {"spectralautopan","spectral autopan"},
  vendor  = "Anarchy Sound Software",
  type    = "spectral_panner",
  roles   = {"Stereo","Spectral","Modulation","IDM"},

  sections = {
    "SPECTRAL BANDS / PITCH MAP",
    "PAN CONTROL POINTS",
    "LFO / MODULATION",
    "INPUT / OUTPUT",
  },

  key_params = {
    band_range   = "Frequenzbereich der analysierten Spektralkomponenten",
    pan_points   = "Pan-Punkte, die Tonhöhe auf Stereoposition abbilden",
    lfo_rate     = "Geschwindigkeit der Pan-LFOs",
    lfo_depth    = "Tiefe der Pan-LFOs",
    input_gain   = "Eingangspegel",
    output_gain  = "Ausgangspegel",
  },
},

bx_townhouse = {
  id      = "bx_townhouse",
  display = "bx_townhouse Buss Compressor (Plugin Alliance)",
  match   = {"bx_townhouse","townhouse buss compressor"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "compressor_bus_vca",
  roles   = {"Compressor","Bus","Glue","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "HPF SIDECHAIN",
    "MIX / OUTPUT",
  },

  key_params = {
    threshold    = "Schwelle der Buskompression",
    ratio        = "Kompressionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    hpf_sidechain= "Sidechain-Hochpass für Bassdurchlass",
    mix          = "Parallel-Mix (Dry/Wet)",
    output_gain  = "Output Gain",
  },
},

bx_paneq = {
  id      = "bx_paneq",
  display = "bx_panEQ (Plugin Alliance)",
  match   = {"bx_paneq","bx paneq","pan eq"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "eq_panning",
  roles   = {"EQ","Pan","Stereo","IDM"},

  sections = {
    "BANDS (FREQ/GAIN/Q)",
    "PAN PER BAND",
    "FILTER / GLOBAL",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz der EQ-Bänder",
    band_gain    = "Gain pro Band",
    band_q       = "Bandbreite/Q",
    band_pan     = "Panorama-Position je Band",
    output_gain  = "Output Gain",
  },
},

bx_bluechorus2 = {
  id      = "bx_bluechorus2",
  display = "bx_bluechorus2 (Plugin Alliance)",
  match   = {"bx_bluechorus2","bluechorus2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "chorus_pedal",
  roles   = {"Chorus","Modulation","Guitar","IDM"},

  sections = {
    "RATE / DEPTH",
    "MIX",
    "TONE",
    "OUTPUT",
  },

  key_params = {
    rate         = "Modulationsgeschwindigkeit",
    depth        = "Modulationstiefe",
    tone         = "Tonblende/Helligkeit",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

adc_spread_delay_lite = {
  id      = "adc_spread_delay_lite",
  display = "adc Spread Delay Lite (Audec)",
  match   = {"adc spread delay lite","spread delay lite"},
  vendor  = "Audec",
  type    = "stereo_delay",
  roles   = {"Delay","Stereo","Space","IDM"},

  sections = {
    "DELAY TIME / FEEDBACK",
    "STEREO SPREAD",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    time         = "Delayzeit",
    feedback     = "Rückkopplung",
    spread       = "Stereobreite / Links-Rechts-Verteilung",
    tone         = "Klangblende/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

adc_spread_delay = {
  id      = "adc_spread_delay",
  display = "adc Spread Delay (Audec)",
  match   = {"adc spread delay","spread delay %(audec%)"},
  vendor  = "Audec",
  type    = "stereo_delay",
  roles   = {"Delay","Stereo","Space","IDM"},

  sections = {
    "DELAY TIME / FEEDBACK",
    "STEREO SPREAD / PAN",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    time         = "Delayzeit (L/R ggf. getrennt)",
    feedback     = "Rückkopplung",
    spread       = "Stereobreite",
    pan          = "Panorama-Steuerung der Echos",
    tone         = "Klangblende/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

valhalla_freqecho = {
  id      = "valhalla_freqecho",
  display = "ValhallaFreqEcho (Valhalla DSP)",
  match   = {"valhallafreqecho","valhalla freq echo"},
  vendor  = "Valhalla DSP",
  type    = "freqshift_delay",
  roles   = {"Delay","FreqShift","Dub","IDM"},

  sections = {
    "FREQ SHIFT",
    "DELAY TIME",
    "FEEDBACK / FILTERS",
    "MIX / OUTPUT",
  },

  key_params = {
    shift        = "Frequenzverschiebung (Frequency Shifter)",
    delay_time   = "Delayzeit",
    feedback     = "Feedback-Menge",
    low_cut      = "Tiefenfilter im Feedback-Pfad",
    high_cut     = "Höhenfilter im Feedback-Pfad",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

shadow_hills_mc = {
  id      = "shadow_hills_mc",
  display = "Shadow Hills Mastering Compressor (Plugin Alliance)",
  match   = {"shadow hills mastering compressor","shadow hills mc"},
  vendor  = "Shadow Hills / Plugin Alliance",
  type    = "compressor_master_dual",
  roles   = {"Master","Bus","Compressor","IDM"},

  sections = {
    "OPTICAL COMPRESSOR",
    "DISCRETE COMPRESSOR",
    "SIDECHAIN / FILTER",
    "TRANSFORMERS (STEEL/NICKEL/IRON)",
    "OUTPUT",
  },

  key_params = {
    opt_thresh   = "Schwelle des Opto-Kompressors",
    opt_gain     = "Makeup-Gain Opto",
    disc_thresh  = "Schwelle des Diskreten Kompressors",
    disc_ratio   = "Kompressionsverhältnis Diskret",
    sidechain_hpf= "Sidechain-Hochpassfilter",
    transformer  = "Transformer-Typ (Steel/Nickel/Iron)",
    output_gain  = "Output Gain",
  },
},

anarchy_rhythms = {
  id      = "anarchy_rhythms",
  display = "AnarchyRhythms (AnarchySoundSoftware)",
  match   = {"anarchyrhythms","anarchy rhythms"},
  vendor  = "Anarchy Sound Software",
  type    = "rhythm_fx",
  roles   = {"Rhythm","FSU","IDM","Glitch"},

  sections = {
    "PATTERN / SEQUENCER",
    "FILTER / DISTORTION",
    "LFO / MOD",
    "MIX / OUTPUT",
  },

  key_params = {
    pattern      = "Rhythmus- / Triggerpattern",
    cutoff       = "Filter-Cutoff",
    resonance    = "Filter-Resonanz",
    drive        = "Sättigung/Distortion",
    lfo_rate     = "LFO-Geschwindigkeit",
    lfo_depth    = "LFO-Tiefe",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

khs_bitcrush = {
  id      = "khs_bitcrush",
  display = "kHs Bitcrush (Kilohearts)",
  match   = {"khs bitcrush","khs bit crush"},
  vendor  = "Kilohearts",
  type    = "bitcrusher",
  roles   = {"Bitcrush","LoFi","IDM"},

  sections = {
    "RATE (DOWNSAMPLE)",
    "BITS",
    "DITHER",
    "ADC/DAC QUALITY",
  },

  key_params = {
    rate         = "Downsampling-Frequenz (Sample Rate Reduktion)",
    bits         = "Bit-Tiefe (Amplitude-Quantisierung)",
    dither       = "Dither-Anteil zur Quantisierungsglättung",
    adc_q        = "Qualität der A/D-Wandlung (aliasing low freq)",
    dac_q        = "Qualität der D/A-Wandlung (aliasing high freq)",
  },
},

bx_yellowdrive = {
  id      = "bx_yellowdrive",
  display = "bx_yellowdrive (Plugin Alliance)",
  match   = {"bx_yellowdrive","yellowdrive"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "overdrive_pedal",
  roles   = {"Drive","Guitar","Drums","IDM"},

  sections = {
    "DRIVE",
    "TONE",
    "LEVEL",
  },

  key_params = {
    drive        = "Verzerrungsgrad",
    tone         = "Tonblende/Helligkeit",
    level        = "Ausgangspegel",
  },
},

bx_subfilter = {
  id      = "bx_subfilter",
  display = "bx_subfilter (Plugin Alliance)",
  match   = {"bx_subfilter","bx subfilter"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "lowend_filter",
  roles   = {"Bass","Sub","Kick","IDM"},

  sections = {
    "FREQUENCY / MODE",
    "RESONANCE / SHAPE",
    "OUTPUT",
  },

  key_params = {
    freq         = "Ziel-Frequenz im Bassbereich",
    resonance    = "Resonanz/Anhebung um die Ziel-Frequenz",
    mode         = "Filtermodus (Tight/Loose/…)",
    output_gain  = "Output Gain",
  },
},

bx_stereomaker = {
  id      = "bx_stereomaker",
  display = "bx_stereomaker (Plugin Alliance)",
  match   = {"bx_stereomaker","stereomaker"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "stereo_widener",
  roles   = {"Stereo","Width","Mono2Stereo","IDM"},

  sections = {
    "WIDTH",
    "TONE / FILTER",
    "MONO COMPATIBILITY",
    "OUTPUT",
  },

  key_params = {
    width        = "Stereobreite (Mono → Stereo)",
    tone         = "Tonformung/Filter",
    mono_compat  = "Einstellung für Mono-Kompatibilität",
    output_gain  = "Output Gain",
  },
},

bx_saturator_v2 = {
  id      = "bx_saturator_v2",
  display = "bx_saturator V2 (Plugin Alliance)",
  match   = {"bx_saturator v2","bx saturator v2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "saturation_multiband",
  roles   = {"Saturation","Multiband","IDM"},

  sections = {
    "CROSSOVER",
    "LOW/MID/HIGH DRIVE",
    "XL / LOUDNESS",
    "OUTPUT",
  },

  key_params = {
    crossover_lo = "Low/Mid Übergangsfrequenz",
    crossover_hi = "Mid/High Übergangsfrequenz",
    drive_lo     = "Drive im Bassband",
    drive_mid    = "Drive im Mittenband",
    drive_hi     = "Drive im Höhenband",
    xl_amount    = "XL/Loudness-Intensität",
    output_gain  = "Output Gain",
  },
},

bx_distorange = {
  id      = "bx_distorange",
  display = "bx_distorange (Plugin Alliance)",
  match   = {"bx_distorange","distorange"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "distortion_pedal",
  roles   = {"Distortion","Guitar","Drums","IDM"},

  sections = {
    "GAIN",
    "TONE",
    "LEVEL",
  },

  key_params = {
    gain         = "Verzerrungsgrad",
    tone         = "Klangblende/Helligkeit",
    level        = "Ausgangspegel",
  },
},

bx_delay2500 = {
  id      = "bx_delay2500",
  display = "bx_delay2500 (Plugin Alliance)",
  match   = {"bx_delay2500","delay2500"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "creative_delay",
  roles   = {"Delay","Modulation","Dub","IDM"},

  sections = {
    "TIME / FEEDBACK",
    "FILTER / DRIVE",
    "MODULATION / DUCKING",
    "MIX / OUTPUT",
  },

  key_params = {
    time         = "Delayzeit (ggf. Tempo-sync)",
    feedback     = "Rückkopplung",
    filter       = "Filter im Feedbackpfad",
    drive        = "Sättigung/Drive im Delay",
    ducking      = "Ducking-Intensität (komprimiert Delay gegen Dry)",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

bx_clipper_std = {
  id      = "bx_clipper_std",
  display = "bx_clipper (Plugin Alliance)",
  match   = {"bx_clipper","bx clipper"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "clipper",
  roles   = {"Clipper","Master","Drums","IDM"},

  sections = {
    "THRESHOLD / CEILING",
    "SHAPE",
    "MIX / OUTPUT",
  },

  key_params = {
    threshold    = "Schwelle, ab der geclippt wird",
    ceiling      = "Maximalpegel",
    shape        = "Form des Clippings (soft/hard)",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

bx_blackdist2 = {
  id      = "bx_blackdist2",
  display = "bx_blackdist2 (Plugin Alliance)",
  match   = {"bx_blackdist2","blackdist2"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "distortion_pedal",
  roles   = {"Distortion","FSU","IDM"},

  sections = {
    "DRIVE",
    "TONE",
    "LEVEL",
  },

  key_params = {
    drive        = "Verzerrungsgrad",
    tone         = "Tonformung",
    level        = "Ausgangspegel",
  },
},

bx_2098_eq = {
  id      = "bx_2098_eq",
  display = "bx_2098 EQ (Plugin Alliance)",
  match   = {"bx_2098 eq","2098 eq"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "eq_analog",
  roles   = {"EQ","Tone","Bus","IDM"},

  sections = {
    "LOW / LOW-MID",
    "MID / HIGH",
    "FILTERS",
    "OUTPUT",
  },

  key_params = {
    band_freq    = "Frequenz pro Band",
    band_gain    = "Gain pro Band",
    q_width      = "Bandbreite/Q",
    output_gain  = "Output Gain",
  },
},

adc_ring2 = {
  id      = "adc_ring2",
  display = "adc Ring 2 (Audec)",
  match   = {"adc ring 2","ring 2 %(audec%)"},
  vendor  = "Audec",
  type    = "ring_mod",
  roles   = {"Ringmod","AM","IDM"},

  sections = {
    "FREQUENCY",
    "MIX",
    "TONE",
    "OUTPUT",
  },

  key_params = {
    freq         = "Modulationsfrequenz der Ringmodulation",
    mix          = "Dry/Wet",
    tone         = "Klangblende",
    output_gain  = "Output Gain",
  },
},

adc_haas2 = {
  id      = "adc_haas2",
  display = "adc Haas 2 (Audec)",
  match   = {"adc haas 2","haas 2 %(audec%)"},
  vendor  = "Audec",
  type    = "haas_stereo",
  roles   = {"Stereo","Haas","IDM"},

  sections = {
    "DELAY OFFSET",
    "PAN / BALANCE",
    "FILTER / TONE",
    "OUTPUT",
  },

  key_params = {
    offset_ms    = "Zeitversatz zwischen L/R (Haas-Effekt)",
    pan          = "Panorama-Position",
    tone         = "Tonformung/Filter",
    output_gain  = "Output Gain",
  },
},

adc_extra_pan = {
  id      = "adc_extra_pan",
  display = "adc Extra Pan (Audec)",
  match   = {"adc extra pan","extra pan %(audec%)"},
  vendor  = "Audec",
  type    = "panner",
  roles   = {"Panner","Stereo","IDM"},

  sections = {
    "PAN / BALANCE",
    "MODULATION",
    "OUTPUT",
  },

  key_params = {
    pan          = "Panorama-Position",
    mod_rate     = "Modulationsgeschwindigkeit (Auto-Pan)",
    mod_depth    = "Modulationstiefe",
    output_gain  = "Output Gain",
  },
},

adc_crush2 = {
  id      = "adc_crush2",
  display = "adc Crush 2 (Audec)",
  match   = {"adc crush 2","crush 2 %(audec%)"},
  vendor  = "Audec",
  type    = "distortion_crush",
  roles   = {"Distortion","Bitcrush","LoFi","IDM"},

  sections = {
    "DRIVE / CRUSH",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },

  key_params = {
    drive        = "Verzerrungsgrad/Crush",
    tone         = "Tonformung/Filter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

valhalla_spacemod = {
  id      = "valhalla_spacemod",
  display = "ValhallaSpaceModulator (Valhalla DSP)",
  match   = {"valhallaspaceModulator","valhalla space modulator"},
  vendor  = "Valhalla DSP",
  type    = "flanger_multi",
  roles   = {"Flanger","Modulation","Reverbish","IDM"},

  sections = {
    "ALGORITHM",
    "RATE / DEPTH",
    "DELAY / FEEDBACK",
    "MIX / OUTPUT",
  },

  key_params = {
    algo         = "Flanger-/Modulationsalgorithmus (Through-zero, Barberpole, etc.)",
    rate         = "Modulationsgeschwindigkeit",
    depth        = "Modulationstiefe",
    delay        = "Basis-Delayzeit",
    feedback     = "Rückkopplung",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ua_lofi_af = {
  id      = "ua_lofi_af",
  display = "Unfiltered Audio lo-fi-af (Plugin Alliance)",
  match   = {"lo-fi-af","lo fi af"},
  vendor  = "Unfiltered Audio / Plugin Alliance",
  type    = "lofi_multi",
  roles   = {"LoFi","Degrade","IDM","Texture"},

  sections = {
    "MEDIA / IMPULSE (VINYL/TAPE/MP3/CD)",
    "NOISE / ARTEFACTS",
    "DRIFT / RANDOMIZE",
    "MIX / OUTPUT",
  },

  key_params = {
    media_type   = "Art des simulierten Mediums (Vinyl, Tape, MP3, etc.)",
    noise_level  = "Staub/Noise/Artefakt-Pegel",
    drift_amount = "Drift/Instabilität der Parameter",
    random_amt   = "Stärke der Randomization",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ua_zip = {
  id      = "ua_zip",
  display = "Unfiltered Audio Zip (Plugin Alliance)",
  match   = {"unfiltered audio zip","zip %(plugin alliance%)"},
  vendor  = "Unfiltered Audio / Plugin Alliance",
  type    = "compressor_modular",
  roles   = {"Compressor","Expander","Modulation","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "ANALYSIS MODE",
    "MOD MATRIX",
    "MIX / OUTPUT",
  },

  key_params = {
    threshold    = "Schwelle für Kompression/Expansion",
    ratio        = "Kompressions-/Expansionsverhältnis",
    attack       = "Attack-Zeit",
    release      = "Release-Zeit",
    analysis_mode= "Analysemodus (Amplitude, Quietness, Brightness, Darkness, Noisiness, Tonalness)",
    mod_amount   = "Modulationsintensität auf Zielparameter",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ua_silo = {
  id      = "ua_silo",
  display = "Unfiltered Audio Silo (Plugin Alliance)",
  match   = {"unfiltered audio silo","silo %(plugin alliance%)"},
  vendor  = "Unfiltered Audio / Plugin Alliance",
  type    = "granular_reverb",
  roles   = {"Reverb","Granular","Space","IDM"},

  sections = {
    "GRAIN (SIZE / SHAPE / SPEED / PITCH)",
    "MOVEMENT (COMETS/MOONS/METEORS/SHIMMER)",
    "FILTER / SPATIAL",
    "COMP / MAXIMIZE",
    "MIX / OUTPUT",
  },

  key_params = {
    grain_size   = "Größe der Körner",
    grain_speed  = "Abspielgeschwindigkeit der Körner",
    grain_pitch  = "Tonhöhe der Körner",
    movement     = "Bewegungstyp (Comets, Moons, Meteors, Stars, Shimmer)",
    filter       = "Filter-/Tonsektion",
    spatial      = "Räumliche Verteilung der Körner",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ua_sandman_pro = {
  id      = "ua_sandman_pro",
  display = "Unfiltered Audio Sandman Pro (Plugin Alliance)",
  match   = {"sandman pro","unfiltered audio sandman pro"},
  vendor  = "Unfiltered Audio / Plugin Alliance",
  type    = "delay_advanced",
  roles   = {"Delay","Loop","Glitch","Granular","IDM"},

  sections = {
    "DELAY MODES (TAPE/INSTANT/GLITCH/PITCH/REVERSE/MULTITAP)",
    "TIME / FEEDBACK / X-FEEDBACK",
    "SLEEP BUFFER / FREEZE",
    "FILTER / DIFFUSION",
    "MIX / OUTPUT",
  },

  key_params = {
    mode         = "Delay-Modus",
    time         = "Delayzeit (inkl. sehr langer Times)",
    feedback     = "Feedback-Menge",
    x_feedback   = "Cross-Feedback zwischen Kanälen",
    sleep        = "Sleep-/Freeze-Buffer Steuerung",
    filter       = "Filter im Delaypfad",
    diffusion    = "Diffusion (Reverb-ähnelnde Dichte)",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

ua_g8 = {
  id      = "ua_g8",
  display = "Unfiltered Audio G8 (Plugin Alliance)",
  match   = {"unfiltered audio g8","g8 dynamic gate"},
  vendor  = "Unfiltered Audio / Plugin Alliance",
  type    = "gate_dynamic",
  roles   = {"Gate","Transient","AM","Rhythmic","IDM"},

  sections = {
    "THRESHOLD / REDUCTION",
    "ATTACK / HOLD / RELEASE / LOOKAHEAD",
    "MODES (NORMAL / CYCLE / ONE-SHOT)",
    "SIDECHAIN / EXPERT",
    "WET/DRY / FLIP / REJECT",
  },

  key_params = {
    threshold    = "Schwelle des Gates",
    reduction    = "Grad der Pegelabsenkung",
    attack       = "Attack-Zeit",
    hold         = "Haltezeit",
    release      = "Release-Zeit",
    lookahead    = "Lookahead-Zeit",
    mode         = "Gate-Modus (Normal, Cycle, One-shot)",
    sidechain    = "Sidechain-/Analysis-Konfiguration",
    mix          = "Dry/Wet (Parallel Gating)",
    flip         = "Flip-Mode (Reject↔Main Ausgang tauschen)",
  },
},

ua_fault = {
  id      = "ua_fault",
  display = "Unfiltered Audio Fault (Plugin Alliance)",
  match   = {"unfiltered audio fault","fault %(plugin alliance%)"},
  vendor  = "Unfiltered Audio / Plugin Alliance",
  type    = "spectral_pitch_phase_fx",
  roles   = {"Pitch","Phase","FSU","IDM"},

  sections = {
    "PITCH / FREQUENCY SHIFT",
    "PHASE / FEEDBACK",
    "FILTER / TONE",
    "MODULATION / ROUTING",
    "MIX / OUTPUT",
  },

  key_params = {
    pitch_shift  = "Pitch-Shifting-Menge",
    freq_shift   = "Frequency-Shifting-Menge",
    phase        = "Phase-Manipulation",
    feedback     = "Feedback-Menge",
    filter       = "Filter-/Tonsektion",
    mod_amount   = "Modulationsintensität",
    mix          = "Dry/Wet",
    output_gain  = "Output Gain",
  },
},

--------------------------------------------------------------------
-- BATCH: CHARACTER / UTIL / STAGECRAFT / WINGS v1
--------------------------------------------------------------------

ds_tantra2 = {
  id      = "ds_tantra2",
  display = "DS Tantra 2 (Plugin Alliance)",
  match   = {"ds tantra 2","tantra 2","dmitry sches tantra 2"},
  vendor  = "DS Audio / Plugin Alliance",
  type    = "rhythmic_multi_fx",
  roles   = {"Rhythmic","MultiFX","Modulation","IDM","Glitch"},

  sections = {
    "EFFECT BLOCKS (FILTER/DIST/DELAY/LOFI/FLANGER/GLITCH)",
    "LAYERS A/B",
    "MODULATORS (8x MULTI-STAGE)",
    "MASTER REVERB / EQ-EXCITER",
    "RANDOMIZER / PRESETS",
  },

  key_params = {
    effect_order   = "Reihenfolge der Effektblöcke",
    layer_mode     = "Routing von Layer A/B (seriell/parallel)",
    mod_steps      = "Anzahl/Shape der Steps pro Modulator",
    mod_depth      = "Modulationstiefe",
    reverb_amount  = "Master-Reverb auf dem Ausgang",
    exciter_amount = "EQ/Exciter-Anteil im Master",
    mix            = "Gesamt-Dry/Wet",
    output_gain    = "Output Gain",
  },
},

fire_wings = {
  id      = "fire_wings",
  display = "Fire (Wings)",
  match   = {"fire %(wings%)","wings fire","firechroma","fire luminance"},
  vendor  = "Wings",
  type    = "color_multi",
  roles   = {"Color","Tone","LoFi","Saturation","IDM"},

  sections = {
    "INPUT / DRIVE",
    "TONE / COLOR",
    "DYNAMICS / TRANSIENTS",
    "STEREO / SPACE",
    "OUTPUT",
  },

  key_params = {
    input_gain     = "Eingangspegel / Ansteuerung",
    drive          = "Sättigungs-/Distortionsgrad",
    color          = "Farbcharakter (Warm/Bright/etc.)",
    dynamics       = "Dynamik-/Transientensteuerung",
    stereo         = "Stereo-Breite / Imaging",
    mix            = "Dry/Wet",
    output_gain    = "Output Gain",
  },
},

free87_frequa = {
  id      = "free87_frequa",
  display = "FREE87 FR-EQUA (eaReckon)",
  match   = {"free87 fr-equa","free87 eq","fr-equa"},
  vendor  = "eaReckon",
  type    = "eq_channel",
  roles   = {"EQ","Utility","Channel","IDM"},

  sections = {
    "LOW / LOW-MID",
    "MID / HIGH",
    "FILTERS",
    "OUTPUT",
  },

  key_params = {
    band_freq      = "Frequenz pro Band",
    band_gain      = "Gain pro Band",
    band_q         = "Q/Bandbreite",
    hp_filter      = "Hochpassfilter",
    lp_filter      = "Tiefpassfilter",
    output_gain    = "Output Gain",
  },
},

free87_frgate = {
  id      = "free87_frgate",
  display = "FREE87 FR-GATE (eaReckon)",
  match   = {"free87 fr-gate","fr-gate"},
  vendor  = "eaReckon",
  type    = "gate_channel",
  roles   = {"Gate","Dynamics","Utility","IDM"},

  sections = {
    "THRESHOLD / RANGE",
    "ATTACK / HOLD / RELEASE",
    "SIDECHAIN / FILTER",
    "OUTPUT",
  },

  key_params = {
    threshold      = "Schwelle des Gates",
    range          = "Maximale Pegelreduktion",
    attack         = "Attack-Zeit",
    hold           = "Haltezeit",
    release        = "Release-Zeit",
    sidechain_hpf  = "Sidechain-Hochpass",
    output_gain    = "Output Gain",
  },
},

free87_frlimit = {
  id      = "free87_frlimit",
  display = "FREE87 FR-LIMIT (eaReckon)",
  match   = {"free87 fr-limit","fr-limit"},
  vendor  = "eaReckon",
  type    = "limiter_channel",
  roles   = {"Limiter","Dynamics","Utility","IDM"},

  sections = {
    "THRESHOLD",
    "RELEASE / CHARACTER",
    "CEILING",
    "METERING / OUTPUT",
  },

  key_params = {
    threshold      = "Schwelle des Limiters",
    release        = "Release-Zeit",
    character      = "Charakter/Härte des Limiters",
    ceiling        = "Maximalpegel",
    output_gain    = "Output Gain",
  },
},

hornet_magnus_lite = {
  id      = "hornet_magnus_lite",
  display = "HoRNetMagnusLite (HoRNet)",
  match   = {"hornetmagnuslite","hornet magnus lite","magnus lite"},
  vendor  = "HoRNet",
  type    = "limiter_maximizer",
  roles   = {"Limiter","Maximizer","Master","IDM"},

  sections = {
    "INPUT / THRESHOLD",
    "LOOKAHEAD / RELEASE",
    "STYLE / CHARACTER",
    "OUTPUT",
  },

  key_params = {
    input_gain     = "Input-Level vor der Begrenzung",
    threshold      = "Begrenzerschwelle",
    lookahead      = "Lookahead-Zeit",
    release        = "Release-Zeit",
    style          = "Charakter des Limiters",
    output_gain    = "Output Gain",
  },
},

lindell_354e = {
  id      = "lindell_354e",
  display = "Lindell 354E (Plugin Alliance)",
  match   = {"lindell 354e","354e multiband"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "compressor_multiband",
  roles   = {"Compressor","Multiband","Master","Bus","IDM"},

  sections = {
    "CROSSOVER (LOW/MID/HIGH)",
    "COMP BANDS (LOW/MID/HIGH)",
    "MODE (Nuke / Stereo / M/S)",
    "SIDECHAIN / HPF",
    "MIX / OUTPUT",
  },

  key_params = {
    crossover_lo   = "Übergangsfrequenz Low→Mid",
    crossover_hi   = "Übergangsfrequenz Mid→High",
    ratio_low      = "Kompressionsverhältnis Low-Band",
    ratio_mid      = "Kompressionsverhältnis Mid-Band",
    ratio_high     = "Kompressionsverhältnis High-Band",
    nuke_mode      = "Nuke-Modus für extreme Kompression",
    ms_mode        = "Mid/Side-Modus",
    hpf_sidechain  = "Sidechain-Hochpass",
    mix            = "Parallel-Mix (Dry/Wet)",
    output_gain    = "Output Gain",
  },
},

lindell_50_channel = {
  id      = "lindell_50_channel",
  display = "Lindell 50 Channel (Plugin Alliance)",
  match   = {"lindell 50 channel","lindell 50 series"},
  vendor  = "Lindell / Plugin Alliance",
  type    = "channelstrip_api",
  roles   = {"Channelstrip","Console","Bus","IDM"},

  sections = {
    "PREAMP / DRIVE",
    "FILTERS (HP/LP)",
    "EQ SECTION (API STYLE)",
    "COMPRESSOR (VCA)",
    "OUTPUT / TMT",
  },

  key_params = {
    input_gain     = "Vorstufenpegel / Drive",
    hp_filter      = "Hochpassfilter",
    lp_filter      = "Tiefpassfilter",
    eq_bands       = "EQ-Bandparameter (Freq/Gain/Q)",
    comp_thresh    = "Kompressor-Schwelle",
    comp_ratio     = "Kompressionsverhältnis",
    comp_attack    = "Attack-Zeit",
    comp_release   = "Release-Zeit",
    tmt_channel    = "Auswahl der TMT-Kanal-Variante",
    output_gain    = "Output Gain",
  },
},

lkjb_seesaw = {
  id      = "lkjb_seesaw",
  display = "lkjb_seesaw (lkjb)",
  match   = {"lkjb_seesaw","seesaw tilt eq","lkjb seesaw"},
  vendor  = "lkjb",
  type    = "tilt_eq",
  roles   = {"EQ","Tilt","Tone","IDM"},

  sections = {
    "TILT / CENTER FREQ",
    "GAIN",
    "MID/SIDE MODE",
    "ANALYZER",
  },

  key_params = {
    center_freq   = "Center-/Pivot-Frequenz des Tilt-EQs",
    tilt_gain     = "Maximaler Tilt-Gain (+/-)",
    mode          = "Bearbeitungsmodus (Stereo/Mid/Side)",
    analyzer      = "Einstellungen der Spektrumanzeige (falls vorhanden)",
  },
},

okair2r = {
  id      = "okair2r",
  display = "OkaiR2R (EvilTurtleProductions)",
  match   = {"okair2r","okai r2r"},
  vendor  = "EvilTurtleProductions",
  type    = "tape_saturation",
  roles   = {"Tape","LoFi","Saturation","IDM"},

  sections = {
    "INPUT / DRIVE",
    "TAPE MODE / SPEED",
    "NOISE / WOW-FLUTTER",
    "OUTPUT",
  },

  key_params = {
    input_gain     = "Eingangspegel / Tape-Drive",
    tape_speed     = "Bandgeschwindigkeit (z.B. 15/30 ips)",
    noise          = "Bandsimulation: Noise/Hiss",
    wow_flutter    = "Wow & Flutter / Pitch-Instabilität",
    output_gain    = "Output Gain",
  },
},

oldcomms = {
  id      = "oldcomms",
  display = "OldComms (EvilTurtleProductions)",
  match   = {"oldcomms","old comms"},
  vendor  = "EvilTurtleProductions",
  type    = "lofi_comms",
  roles   = {"LoFi","Tone","FSU","IDM"},

  sections = {
    "BANDWIDTH / EQ",
    "NOISE / DISTORTION",
    "COMMS CHARACTER",
    "OUTPUT",
  },

  key_params = {
    bandwidth      = "Bandbegrenzung (Telefon/Radio etc.)",
    noise          = "Rauschen/Artefakte",
    distortion     = "Verzerrungsgrad",
    character      = "Modus/Charakter der Comms-Emulation",
    output_gain    = "Output Gain",
  },
},

ott_xfer = {
  id      = "ott_xfer",
  display = "OTT (Xfer Records)",
  match   = {"ott %(xfer records%)","xfer ott","ott compressor"},
  vendor  = "Xfer Records",
  type    = "compressor_multiband_updown",
  roles   = {"Multiband","Up/Down","FSU","IDM"},

  sections = {
    "DEPTH / TIME",
    "IN / OUT",
    "LOW / MID / HIGH",
    "GAIN / MIX",
  },

  key_params = {
    depth         = "Gesamtintensität der Multibandkompression",
    time          = "Zeitkonstante (Attack/Release global)",
    in_gain       = "Eingangspegel",
    out_gain      = "Ausgangspegel",
    low_level     = "Level Low-Band",
    mid_level     = "Level Mid-Band",
    high_level    = "Level High-Band",
    mix           = "Dry/Wet",
  },
},

roughrider3 = {
  id      = "roughrider3",
  display = "RoughRider3 (Audio Damage)",
  match   = {"roughrider3","rough rider 3"},
  vendor  = "Audio Damage",
  type    = "compressor_colored",
  roles   = {"Compressor","Color","Drums","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "SENSITIVITY / MAKEUP",
    "FILTER / SIDECHAIN",
  },

  key_params = {
    threshold      = "Kompressionsschwelle",
    ratio          = "Kompressionsverhältnis",
    attack         = "Attack-Zeit",
    release        = "Release-Zeit",
    sensitivity    = "Empfindlichkeit / Input-Trim",
    sc_filter      = "Sidechain-Filter (HP/LP)",
    makeup_gain    = "Makeup-Gain",
  },
},

stimulate_viator = {
  id      = "stimulate_viator",
  display = "Stimulate (Viator DSP)",
  match   = {"stimulate %(viator dsp%)","viator stimulate"},
  vendor  = "Viator DSP",
  type    = "saturation_transient",
  roles   = {"Saturation","Transient","Exciter","IDM"},

  sections = {
    "INPUT / DRIVE",
    "TRANSIENT / SHAPE",
    "TONE / FILTER",
    "MIX / OUTPUT",
  },

  key_params = {
    input_gain     = "Eingangspegel / Drive",
    transient      = "Transientenbetonung",
    tone           = "Tonformung/Filter",
    mix            = "Dry/Wet",
    output_gain    = "Output Gain",
  },
},

tdr_prism = {
  id      = "tdr_prism",
  display = "TDR Prism (Tokyo Dawn Labs)",
  match   = {"tdr prism","tokyo dawn prism"},
  vendor  = "Tokyo Dawn Labs",
  type    = "transient_shaper",
  roles   = {"Transient","Dynamics","Master","IDM"},

  sections = {
    "TRANSIENT (ATTACK/SUSTAIN)",
    "FREQUENCY FOCUS",
    "MIX / PARALLEL",
    "OUTPUT",
  },

  key_params = {
    attack         = "Verstärkung/Abschwächung der Attack-Anteile",
    sustain        = "Verstärkung/Abschwächung der Sustain-Anteile",
    focus_freq     = "Frequenzfokus der Bearbeitung",
    mix            = "Parallel-Mix (Dry/Wet)",
    output_gain    = "Output Gain",
  },
},

wider_polyverse = {
  id      = "wider_polyverse",
  display = "Wider (Polyverse Music)",
  match   = {"wider %(polyverse%)","polyverse wider"},
  vendor  = "Polyverse Music",
  type    = "stereo_widener_safe",
  roles   = {"Stereo","Width","Utility","IDM"},

  sections = {
    "WIDTH",
    "MODE / SAFE MONO",
    "OUTPUT",
  },

  key_params = {
    width         = "Stereobreite (0–200%+)",
    safe_mono     = "Mono-Kompatibilitätsmodus",
    output_gain   = "Output Gain",
  },
},

danaides_inear = {
  id      = "danaides_inear",
  display = "Danaides (Inear_Display)",
  match   = {"danaides","inear display danaides"},
  vendor  = "Inear_Display",
  type    = "step_filter_fx",
  roles   = {"Filter","Rhythmic","FSU","IDM"},

  sections = {
    "STEP SEQUENCER",
    "FILTER (CUTOFF/RES)",
    "MODULATION / RANDOM",
    "MIX / OUTPUT",
  },

  key_params = {
    steps         = "Anzahl / Inhalt der Step-Sequenz",
    cutoff        = "Filter-Cutoff",
    resonance     = "Filter-Resonanz",
    random        = "Randomization / Chance",
    mix           = "Dry/Wet",
    output_gain   = "Output Gain",
  },
},

nibiru3_bserrano = {
  id      = "nibiru3_bserrano",
  display = "Nibiru 3 (benoit serrano)",
  match   = {"nibiru 3","bserrano nibiru"},
  vendor  = "benoit serrano",
  type    = "synth_fx_multi",
  roles   = {"Filter","Modulation","Space","IDM"},

  sections = {
    "OSC / INPUT",
    "FILTER BANK",
    "LFO / MOD",
    "SPACE / FX",
    "OUTPUT",
  },

  key_params = {
    filter_mode   = "Filtertyp/-struktur",
    cutoff        = "Filter-Cutoff",
    resonance     = "Filter-Resonanz",
    lfo_rate      = "LFO-Geschwindigkeit",
    lfo_depth     = "LFO-Tiefe",
    space         = "Raum-/Ambience-Anteil",
    output_gain   = "Output Gain",
  },
},

bx_greenscreamer = {
  id      = "bx_greenscreamer",
  display = "bx_greenscreamer (Plugin Alliance)",
  match   = {"bx_greenscreamer","green screamer"},
  vendor  = "Brainworx / Plugin Alliance",
  type    = "overdrive_pedal",
  roles   = {"Drive","Guitar","Drums","IDM"},

  sections = {
    "DRIVE",
    "TONE",
    "LEVEL",
  },

  key_params = {
    drive         = "Verzerrungsgrad",
    tone          = "Tonblende/Helligkeit",
    level         = "Ausgangspegel",
  },
},

airmusic_soundparticles = {
  id      = "airmusic_soundparticles",
  display = "AirMusic (Sound Particles)",
  match   = {"airmusic %(sound particles%)","sound particles air"},
  vendor  = "Sound Particles",
  type    = "air_enhancer",
  roles   = {"HighEnd","Air","Master","IDM"},

  sections = {
    "AIR / AMOUNT",
    "FREQ / RANGE",
    "CHARACTER",
    "OUTPUT",
  },

  key_params = {
    amount        = "Intensität der Air-Anhebung",
    freq          = "Startfrequenz des Air-Bandes",
    character     = "Charakter/Härte der Höhenanhebung",
    output_gain   = "Output Gain",
  },
},

coderedfree = {
  id      = "coderedfree",
  display = "CodeRedFree (Shattered Glass Audio)",
  match   = {"coderedfree","code red free"},
  vendor  = "Shattered Glass Audio",
  type    = "eq_console_neve",
  roles   = {"EQ","Tone","Console","IDM"},

  sections = {
    "LOW / MID / HIGH EQ",
    "HP FILTER",
    "INPUT / OUTPUT",
  },

  key_params = {
    low_freq      = "Low-Frequenz",
    low_gain      = "Low-Gain",
    mid_freq      = "Mid-Frequenz",
    mid_gain      = "Mid-Gain",
    high_freq     = "High-Frequenz",
    high_gain     = "High-Gain",
    hp_filter     = "Hochpassfilter",
    input_gain    = "Input-Gain",
    output_gain   = "Output Gain",
  },
},

malibu_vztec = {
  id      = "malibu_vztec",
  display = "Malibu (VZtec)",
  match   = {"malibu %(vztec%)","vztec malibu"},
  vendor  = "VZtec",
  type    = "reverb_mod",
  roles   = {"Reverb","Space","Modulation","IDM"},

  sections = {
    "PRE-DELAY / TIME",
    "SIZE / DIFFUSION",
    "MODULATION",
    "TONE / FILTER",
    "MIX / OUTPUT",
  },

  key_params = {
    predelay      = "Pre-Delay vor dem Hall",
    time          = "Hall-Länge",
    size          = "Raumgröße",
    diffusion     = "Diffusion/Dichte",
    mod_rate      = "Modulationsgeschwindigkeit im Hall",
    mod_depth     = "Modulationstiefe",
    tone          = "Tonformung/Filter",
    mix           = "Dry/Wet",
    output_gain   = "Output Gain",
  },
},

molot_vladg = {
  id      = "molot_vladg",
  display = "Molot (Vladislav Goncharov)",
  match   = {"molot %(vladislav goncharov%)","vladg molot"},
  vendor  = "VladG",
  type    = "compressor_character",
  roles   = {"Compressor","Color","Master","Drums","IDM"},

  sections = {
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "KNEE / MODE",
    "SATURATION / TONE",
    "OUTPUT",
  },

  key_params = {
    threshold      = "Kompressionsschwelle",
    ratio          = "Kompressionsverhältnis",
    attack         = "Attack-Zeit",
    release        = "Release-Zeit",
    mode           = "Kompressormodus (z.B. Feedback/Feedforward)",
    saturation     = "Sättigungs-/Nichtlinearitätsanteil",
    tone           = "Tonformung",
    output_gain    = "Output Gain",
  },
},

transperc_apisonic = {
  id      = "transperc_apisonic",
  display = "Transperc (Apisonic Labs)",
  match   = {"transperc","apisonic transperc"},
  vendor  = "Apisonic Labs",
  type    = "transient_shaper_drum",
  roles   = {"Transient","Drums","Percussion","IDM"},

  sections = {
    "ATTACK",
    "SUSTAIN",
    "FREQ FOCUS",
    "MIX / OUTPUT",
  },

  key_params = {
    attack         = "Anhebung/Absenkung der Attack-Anteile",
    sustain        = "Anhebung/Absenkung der Sustain-Anteile",
    focus_freq     = "Frequenzbereich, auf den die Bearbeitung wirkt",
    mix            = "Dry/Wet",
    output_gain    = "Output Gain",
  },
},

warmy_ep1a_v2 = {
  id      = "warmy_ep1a_v2",
  display = "Warmy EP1A V2 (Kiive Audio)",
  match   = {"warmy ep1a v2","warmy ep1a","kiive warmy"},
  vendor  = "Kiive Audio",
  type    = "eq_pultec_style",
  roles   = {"EQ","Tone","Tube","IDM"},

  sections = {
    "LOW BAND (BOOST/ATTEN)",
    "HIGH BAND (BOOST/ATTEN)",
    "HIGH-CUT / SHELF",
    "OUTPUT",
  },

  key_params = {
    low_freq      = "Low-Frequenz",
    low_boost     = "Low-Boost",
    low_atten     = "Low-Attenuation",
    high_freq     = "High-Frequenz",
    high_boost    = "High-Boost",
    high_atten    = "High-Attenuation",
    output_gain   = "Output Gain",
  },
},

sc_autofilter = {
  id      = "sc_autofilter",
  display = "SC AutoFilter (Stagecraft Software)",
  match   = {"sc autofilter","stagecraft autofilter","auto filter stagecraft"},
  vendor  = "Stagecraft Software",
  type    = "auto_filter",
  roles   = {"Filter","Modulation","DJ","IDM"},

  sections = {
    "FILTER (CUTOFF/RESO)",
    "LFO (FREQ/RANGE/SHAPE)",
    "DUTY CYCLE WARP",
    "MIX / OUTPUT",
  },

  key_params = {
    cutoff        = "Filter-Cutoff",
    resonance     = "Filter-Resonanz",
    lfo_freq      = "LFO-Frequenz",
    lfo_range     = "LFO-Bereich / Sweep-Range",
    duty_warp     = "Duty-Cycle-Warping (Kurvenform)",
    mix           = "Dry/Wet",
    output_gain   = "Output Gain",
  },
},


-- Paste these entries into the MetaCore.vst table (before the closing '

  --------------------------------------------------------------------
  -- bx_cleansweep Pro (Plugin Alliance)
  --------------------------------------------------------------------
  bx_cleansweep_pro = {
    id      = "bx_cleansweep_pro",
    display = "bx_cleansweep Pro (Plugin Alliance)",
    match   = {"bx cleansweep pro"},
    vendor  = "Plugin Alliance",
    type    = "filter",
    roles   = {"Filter","Cleanup","Tone"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_clipper (Plugin Alliance)
  --------------------------------------------------------------------
  bx_clipper = {
    id      = "bx_clipper",
    display = "bx_clipper (Plugin Alliance)",
    match   = {"bx clipper"},
    vendor  = "Plugin Alliance",
    type    = "limiter",
    roles   = {"Clipper","Limiter","Loudness"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "METERING / OUTPUT",
    },

    key_params = {
      threshold    = "Limiting-Schwelle / Input",
      ceiling      = "Output Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Transientenschutz",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_dynEQ V2 Mono (Plugin Alliance)
  --------------------------------------------------------------------
  bx_dyneq_v2_mono = {
    id      = "bx_dyneq_v2_mono",
    display = "bx_dynEQ V2 Mono (Plugin Alliance)",
    match   = {"bx dyneq v2 mono"},
    vendor  = "Plugin Alliance",
    type    = "dynamic_eq",
    roles   = {"Dynamic EQ","DeEss","Tone"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_hybrid V2 mix (Plugin Alliance)
  --------------------------------------------------------------------
  bx_hybrid_v2_mix = {
    id      = "bx_hybrid_v2_mix",
    display = "bx_hybrid V2 mix (Plugin Alliance)",
    match   = {"bx hybrid v2 mix"},
    vendor  = "Plugin Alliance",
    type    = "eq",
    roles   = {"Tone","Master","Surgical"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_limiter True Peak (Plugin Alliance)
  --------------------------------------------------------------------
  bx_limiter_true_peak = {
    id      = "bx_limiter_true_peak",
    display = "bx_limiter True Peak (Plugin Alliance)",
    match   = {"bx limiter true peak"},
    vendor  = "Plugin Alliance",
    type    = "limiter",
    roles   = {"Limiter","Master","Safety"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "METERING / OUTPUT",
    },

    key_params = {
      threshold    = "Limiting-Schwelle / Input",
      ceiling      = "Output Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Transientenschutz",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_limiter (Plugin Alliance)
  --------------------------------------------------------------------
  bx_limiter = {
    id      = "bx_limiter",
    display = "bx_limiter (Plugin Alliance)",
    match   = {"bx limiter"},
    vendor  = "Plugin Alliance",
    type    = "limiter",
    roles   = {"Clipper","Limiter","Loudness"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "METERING / OUTPUT",
    },

    key_params = {
      threshold    = "Limiting-Schwelle / Input",
      ceiling      = "Output Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Transientenschutz",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_masterdesk True Peak (Plugin Alliance)
  --------------------------------------------------------------------
  bx_masterdesk_true_peak = {
    id      = "bx_masterdesk_true_peak",
    display = "bx_masterdesk True Peak (Plugin Alliance)",
    match   = {"bx masterdesk true peak"},
    vendor  = "Plugin Alliance",
    type    = "mastering_chain",
    roles   = {"Mastering","Limiter","EQ","Stereo"},

    sections = {
      "INPUT / HEADROOM",
      "TONE / FOUNDATION",
      "COMP / GLUE",
      "LIMIT / LOUDNESS",
      "METERING",
    },

    key_params = {
      input        = "Eingangspegel / Headroom",
      tone         = "Tonal-Balance / Foundation",
      comp         = "Master-Kompressor / Glue",
      limit        = "True-Peak-Limiter / Loudness",
      width        = "Stereo-Breite / M/S",
    },
  },


  --------------------------------------------------------------------
  -- bx_opto (Plugin Alliance)
  --------------------------------------------------------------------
  bx_opto = {
    id      = "bx_opto",
    display = "bx_opto (Plugin Alliance)",
    match   = {"bx opto"},
    vendor  = "Plugin Alliance",
    type    = "compressor",
    roles   = {"Opto","Smooth","Vocals"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_townhouse Buss Compressor (Plugin Alliance)
  --------------------------------------------------------------------
  bx_townhouse_buss_compressor = {
    id      = "bx_townhouse_buss_compressor",
    display = "bx_townhouse Buss Compressor (Plugin Alliance)",
    match   = {"bx townhouse buss compressor"},
    vendor  = "Plugin Alliance",
    type    = "bus_compressor",
    roles   = {"Bus","Glue","Punch"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Lindell 6X-500 (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_6x_500 = {
    id      = "lindell_6x_500",
    display = "Lindell 6X-500 (Plugin Alliance)",
    match   = {"lindell 6x 500"},
    vendor  = "Plugin Alliance",
    type    = "preamp_eq",
    roles   = {"Tone","Preamp","EQ"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Lindell 7X-500 (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_7x_500 = {
    id      = "lindell_7x_500",
    display = "Lindell 7X-500 (Plugin Alliance)",
    match   = {"lindell 7x 500"},
    vendor  = "Plugin Alliance",
    type    = "compressor",
    roles   = {"DrumBus","FET","Punch"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Shadow Hills Class A Mastering Comp (Plugin Alliance)
  --------------------------------------------------------------------
  shadow_hills_class_a_mastering_comp = {
    id      = "shadow_hills_class_a_mastering_comp",
    display = "Shadow Hills Class A Mastering Comp (Plugin Alliance)",
    match   = {"shadow hills class a mastering comp"},
    vendor  = "Plugin Alliance",
    type    = "master_bus_comp",
    roles   = {"Mastering","Bus","Glue"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Rare (AnalogObsession)
  --------------------------------------------------------------------
  rare = {
    id      = "rare",
    display = "Rare (AnalogObsession)",
    match   = {"rare"},
    vendor  = "AnalogObsession",
    type    = "eq",
    roles   = {"Pultec","Tone","Low/High"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- LALA (AnalogObsession)
  --------------------------------------------------------------------
  lala = {
    id      = "lala",
    display = "LALA (AnalogObsession)",
    match   = {"lala"},
    vendor  = "AnalogObsession",
    type    = "compressor",
    roles   = {"Opto","Smooth","Vocals"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Kolin (AnalogObsession)
  --------------------------------------------------------------------
  kolin = {
    id      = "kolin",
    display = "Kolin (AnalogObsession)",
    match   = {"kolin"},
    vendor  = "AnalogObsession",
    type    = "compressor",
    roles   = {"VariMu","Bus","Glue"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- FETish (AnalogObsession)
  --------------------------------------------------------------------
  fetish = {
    id      = "fetish",
    display = "FETish (AnalogObsession)",
    match   = {"fetish"},
    vendor  = "AnalogObsession",
    type    = "compressor",
    roles   = {"FET","Drums","Punch"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet oder Mix-Regler",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- ChowMultiTool (chowdsp) (2->12ch)
  --------------------------------------------------------------------
  chowmultitool_chowdsp = {
    id      = "chowmultitool_chowdsp",
    display = "ChowMultiTool (chowdsp) (2->12ch)",
    match   = {"chowmultitool chowdsp"},
    vendor  = "chowdsp",
    type    = "multi_fx",
    roles   = {"Utility","Dynamics","Filter"},

    sections = {
      "MAIN CONTROLS",
      "MOD / MOVEMENT",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter des Effekts",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Klangformung / Filter",
      mix          = "Dry/Wet / Output",
    },
  },


  --------------------------------------------------------------------
  -- ChowMatrix (chowdsp)
  --------------------------------------------------------------------
  chowmatrix = {
    id      = "chowmatrix",
    display = "ChowMatrix (chowdsp)",
    match   = {"chowmatrix"},
    vendor  = "chowdsp",
    type    = "delay",
    roles   = {"Delay","Ambient","Experimental"},

    sections = {
      "TIME / FEEDBACK",
      "FILTER / TONE",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Delay-Time / Tempo-Sync",
      feedback     = "Feedback-Menge",
      tone         = "Filter / Tonformung im Feedbackweg",
      mod          = "Modulation / Spread / Width",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- ChowCentaur (chowdsp)
  --------------------------------------------------------------------
  chowcentaur = {
    id      = "chowcentaur",
    display = "ChowCentaur (chowdsp)",
    match   = {"chowcentaur"},
    vendor  = "chowdsp",
    type    = "saturation",
    roles   = {"Drive","Guitar","Color"},

    sections = {
      "INPUT / DRIVE",
      "COLOR / TONE",
      "NOISE / MOD",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Sättigungs-/Drive-Menge",
      tone         = "Tonformung / EQ / Tilt",
      noise        = "Noise / Wow & Flutter / Artefakte",
      mix          = "Dry/Wet",
      output       = "Output / Level",
    },
  },


  --------------------------------------------------------------------
  -- TAL-Filter-2 (TAL-Togu Audio Line)
  --------------------------------------------------------------------
  tal_filter_2 = {
    id      = "tal_filter_2",
    display = "TAL-Filter-2 (TAL-Togu Audio Line)",
    match   = {"tal filter 2"},
    vendor  = "TAL-Togu Audio Line",
    type    = "filter",
    roles   = {"Filter","Modulation","Rhythm"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- TAL Reverb 4 Plugin (TAL-Togu Audio Line)
  --------------------------------------------------------------------
  tal_reverb_4_plugin = {
    id      = "tal_reverb_4_plugin",
    display = "TAL Reverb 4 Plugin (TAL-Togu Audio Line)",
    match   = {"tal reverb 4 plugin"},
    vendor  = "TAL-Togu Audio Line",
    type    = "reverb",
    roles   = {"Space","Ambience","FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      extra        = "Zusatzfunktionen / Charakter",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- TAL-Vocoder-2 (TAL-Togu Audio Line)
  --------------------------------------------------------------------
  tal_vocoder_2 = {
    id      = "tal_vocoder_2",
    display = "TAL-Vocoder-2 (TAL-Togu Audio Line)",
    match   = {"tal vocoder 2"},
    vendor  = "TAL-Togu Audio Line",
    type    = "vocoder",
    roles   = {"Vocoder","Voice FX","Synth FX"},

    sections = {
      "CARRIER",
      "MODULATOR",
      "FILTERBANK",
      "MIX / OUTPUT",
    },

    key_params = {
      carrier      = "Carrier-Level / Synth-Anteil",
      modulator    = "Modulator-Level / Voice-Anteil",
      filter       = "Filterbank / Bands",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Free Amp (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_free_amp = {
    id      = "blue_cat_s_free_amp",
    display = "Blue Cat's Free Amp (Blue Cat Audio)",
    match   = {"blue cat s free amp"},
    vendor  = "Blue Cat Audio",
    type    = "amp_sim",
    roles   = {"Amp","Guitar","Cab"},

    sections = {
      "INPUT / DRIVE",
      "COLOR / TONE",
      "NOISE / MOD",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Sättigungs-/Drive-Menge",
      tone         = "Tonformung / EQ / Tilt",
      noise        = "Noise / Wow & Flutter / Artefakte",
      mix          = "Dry/Wet",
      output       = "Output / Level",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Gain 3 (Stereo) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_gain_3_stereo = {
    id      = "blue_cat_s_gain_3_stereo",
    display = "Blue Cat's Gain 3 (Stereo) (Blue Cat Audio)",
    match   = {"blue cat s gain 3 stereo"},
    vendor  = "Blue Cat Audio",
    type    = "utility",
    roles   = {"Gain","Trim","Utility"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      extra        = "Zusatzfunktionen / Charakter",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Chorus 4 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_chorus_4_mono = {
    id      = "blue_cat_s_chorus_4_mono",
    display = "Blue Cat's Chorus 4 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s chorus 4 mono"},
    vendor  = "Blue Cat Audio",
    type    = "modulation",
    roles   = {"Chorus","Width","Movement"},

    sections = {
      "RATE / SPEED",
      "DEPTH / AMOUNT",
      "TONE / MIX",
      "OUTPUT",
    },

    key_params = {
      rate         = "Modulationsgeschwindigkeit",
      depth        = "Modulationstiefe",
      tone         = "Tonformung / Filter",
      mix          = "Dry/Wet",
      output       = "Output Pegel",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Phaser 3 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_phaser_3_mono = {
    id      = "blue_cat_s_phaser_3_mono",
    display = "Blue Cat's Phaser 3 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s phaser 3 mono"},
    vendor  = "Blue Cat Audio",
    type    = "modulation",
    roles   = {"Phaser","Movement","FX"},

    sections = {
      "RATE / SPEED",
      "DEPTH / AMOUNT",
      "TONE / MIX",
      "OUTPUT",
    },

    key_params = {
      rate         = "Modulationsgeschwindigkeit",
      depth        = "Modulationstiefe",
      tone         = "Tonformung / Filter",
      mix          = "Dry/Wet",
      output       = "Output Pegel",
    },
  },


  --------------------------------------------------------------------
  -- FREE87 FR-EQUA (eaReckon)
  --------------------------------------------------------------------
  free87_fr_equa = {
    id      = "free87_fr_equa",
    display = "FREE87 FR-EQUA (eaReckon)",
    match   = {"free87 fr equa"},
    vendor  = "eaReckon",
    type    = "eq",
    roles   = {"Tone","Basic","Utility"},

    sections = {
      "INPUT",
      "FILTER / BANDS",
      "SPECIAL FEATURES",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Drive",
      low          = "Low-/Bass-Band oder HPF",
      mid          = "Mittenbearbeitung / Fokus",
      high         = "Höhen-/Air-Band oder LPF",
      special      = "Spezielle Filter-/Dyn-EQ-Funktionen",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- FREE87 FR-GATE (eaReckon)
  --------------------------------------------------------------------
  free87_fr_gate = {
    id      = "free87_fr_gate",
    display = "FREE87 FR-GATE (eaReckon)",
    match   = {"free87 fr gate"},
    vendor  = "eaReckon",
    type    = "gate",
    roles   = {"Gate","Dynamics","Utility"},

    sections = {
      "THRESHOLD",
      "ATTACK / RELEASE",
      "RANGE",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Gate-Schwelle",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      range        = "Gate-Reduktionsbereich",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- FREE87 FR-LIMIT (eaReckon)
  --------------------------------------------------------------------
  free87_fr_limit = {
    id      = "free87_fr_limit",
    display = "FREE87 FR-LIMIT (eaReckon)",
    match   = {"free87 fr limit"},
    vendor  = "eaReckon",
    type    = "limiter",
    roles   = {"Limiter","Safety","Master"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "METERING / OUTPUT",
    },

    key_params = {
      threshold    = "Limiting-Schwelle / Input",
      ceiling      = "Output Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Transientenschutz",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- Tape Cassette 2 (Caelum Audio)
  --------------------------------------------------------------------
  tape_cassette_2 = {
    id      = "tape_cassette_2",
    display = "Tape Cassette 2 (Caelum Audio)",
    match   = {"tape cassette 2"},
    vendor  = "Caelum Audio",
    type    = "tape",
    roles   = {"Tape","LoFi","Saturation"},

    sections = {
      "INPUT / DRIVE",
      "COLOR / TONE",
      "NOISE / MOD",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Sättigungs-/Drive-Menge",
      tone         = "Tonformung / EQ / Tilt",
      noise        = "Noise / Wow & Flutter / Artefakte",
      mix          = "Dry/Wet",
      output       = "Output / Level",
    },
  },



  --------------------------------------------------------------------
  -- Ozone 12 Equalizer (iZotope)
  --------------------------------------------------------------------
  ozone_12_equalizer = {
    id      = "ozone_12_equalizer",
    display = "Ozone 12 Equalizer (iZotope)",
    match   = {"ozone 12 equalizer"},
    vendor  = "iZotope",
    type    = "eq",
    roles   = {"Mastering","Tone","Surgical"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "DYNAMIC / SPECIAL",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-Band / Bass",
      mid          = "Mitten-Band / Presence",
      high         = "High-Band / Air",
      dynamic      = "Dynamische EQ-Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- Trash (iZotope)
  --------------------------------------------------------------------
  trash = {
    id      = "trash",
    display = "Trash (iZotope)",
    match   = {"trash"},
    vendor  = "iZotope",
    type    = "distortion",
    roles   = {"Distortion","Multi-Band","Sound Design"},

    sections = {
      "INPUT / DRIVE",
      "TONE / FILTER",
      "CHARACTER / MODE",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Verzerrungsmenge",
      tone         = "Tonformung / Filter / Tilt",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Vinyl (iZotope)
  --------------------------------------------------------------------
  vinyl = {
    id      = "vinyl",
    display = "Vinyl (iZotope)",
    match   = {"vinyl"},
    vendor  = "iZotope",
    type    = "lofi",
    roles   = {"LoFi","Noise","Character"},

    sections = {
      "INPUT / DRIVE",
      "TONE / FILTER",
      "CHARACTER / MODE",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Verzerrungsmenge",
      tone         = "Tonformung / Filter / Tilt",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Raum (Native Instruments)
  --------------------------------------------------------------------
  raum = {
    id      = "raum",
    display = "Raum (Native Instruments)",
    match   = {"raum"},
    vendor  = "Native Instruments",
    type    = "reverb",
    roles   = {"Space","Ambient","FX"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Raumgröße / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Replika (Native Instruments)
  --------------------------------------------------------------------
  replika = {
    id      = "replika",
    display = "Replika (Native Instruments)",
    match   = {"replika"},
    vendor  = "Native Instruments",
    type    = "delay",
    roles   = {"Delay","Modulation","FX"},

    sections = {
      "TIME / SYNC",
      "FEEDBACK",
      "FILTER / TONE",
      "MOD / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Delay-Time / Tempo-Sync",
      feedback     = "Feedback-Menge",
      tone         = "Filter / Tonformung",
      mod          = "Modulation / Stereo",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Supercharger (Native Instruments)
  --------------------------------------------------------------------
  supercharger = {
    id      = "supercharger",
    display = "Supercharger (Native Instruments)",
    match   = {"supercharger"},
    vendor  = "Native Instruments",
    type    = "compressor",
    roles   = {"Saturation","Bus","Glue"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressions-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Love (Dawesome)
  --------------------------------------------------------------------
  love = {
    id      = "love",
    display = "Love (Dawesome)",
    match   = {"love"},
    vendor  = "Dawesome",
    type    = "modulation",
    roles   = {"Chorus","Phaser","Movement"},

    sections = {
      "RATE / SPEED",
      "DEPTH / AMOUNT",
      "TONE / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Modulationsgeschwindigkeit",
      depth        = "Modulationstiefe / Stärke",
      tone         = "Klangfärbung / Filter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Zyklop (Dawesome)!!!VSTi
  --------------------------------------------------------------------
  zyklop = {
    id      = "zyklop",
    display = "Zyklop (Dawesome)!!!VSTi",
    match   = {"zyklop","zyklop dawesome vsti"},
    vendor  = "Dawesome",
    type    = "synth",
    roles   = {"Bass","Seq","Synth"},

    sections = {
      "OSCILLATORS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillator-Level / Wellenformen",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amplitude-/Filter-Hüllkurven",
      mod          = "LFO/Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Surge XT (Surge Synth Team) (2->6ch)!!!VSTi
  --------------------------------------------------------------------
  surge_xt_surge_synth_team = {
    id      = "surge_xt_surge_synth_team",
    display = "Surge XT (Surge Synth Team) (2->6ch)!!!VSTi",
    match   = {"surge xt surge synth team","surge xt surge synth team 2 6ch vsti"},
    vendor  = "Surge Synth Team",
    type    = "synth",
    roles   = {"Synth","Hybrid","Modular"},

    sections = {
      "OSCILLATORS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillator-Level / Wellenformen",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amplitude-/Filter-Hüllkurven",
      mod          = "LFO/Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Surge XT Effects (Surge Synth Team)
  --------------------------------------------------------------------
  surge_xt_effects = {
    id      = "surge_xt_effects",
    display = "Surge XT Effects (Surge Synth Team)",
    match   = {"surge xt effects"},
    vendor  = "Surge Synth Team",
    type    = "multi_fx",
    roles   = {"FX","Filter","Modulation"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- VISION 4X (Excite Audio)
  --------------------------------------------------------------------
  vision_4x = {
    id      = "vision_4x",
    display = "VISION 4X (Excite Audio)",
    match   = {"vision 4x"},
    vendor  = "Excite Audio",
    type    = "analyzer",
    roles   = {"Analyzer","Sidechain","Visual"},

    sections = {
      "DISPLAY / RANGE",
      "SCALE / SPEED",
      "FOCUS / BANDS",
      "EXTRA",
    },

    key_params = {
      range        = "Anzeigebereich / dB-Range",
      speed        = "Update-Geschwindigkeit / Reaktionszeit",
      focus        = "Frequenz-Fokus / Zoom",
    },
  },


  --------------------------------------------------------------------
  -- VISION 4X (x86) (Excite Audio)
  --------------------------------------------------------------------
  vision_4x_x86 = {
    id      = "vision_4x_x86",
    display = "VISION 4X (x86) (Excite Audio)",
    match   = {"vision 4x x86"},
    vendor  = "Excite Audio",
    type    = "analyzer",
    roles   = {"Analyzer","Sidechain","Visual"},

    sections = {
      "DISPLAY / RANGE",
      "SCALE / SPEED",
      "FOCUS / BANDS",
      "EXTRA",
    },

    key_params = {
      range        = "Anzeigebereich / dB-Range",
      speed        = "Update-Geschwindigkeit / Reaktionszeit",
      focus        = "Frequenz-Fokus / Zoom",
    },
  },


  --------------------------------------------------------------------
  -- Clamp (Outobugi)
  --------------------------------------------------------------------
  clamp = {
    id      = "clamp",
    display = "Clamp (Outobugi)",
    match   = {"clamp"},
    vendor  = "Outobugi",
    type    = "compressor",
    roles   = {"Drums","Bus","Glue"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressions-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Refire (Outobugi)
  --------------------------------------------------------------------
  refire = {
    id      = "refire",
    display = "Refire (Outobugi)",
    match   = {"refire"},
    vendor  = "Outobugi",
    type    = "saturation",
    roles   = {"Drive","Color","Master"},

    sections = {
      "INPUT / DRIVE",
      "TONE / FILTER",
      "CHARACTER / MODE",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Verzerrungsmenge",
      tone         = "Tonformung / Filter / Tilt",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Wave (Outobugi)
  --------------------------------------------------------------------
  wave = {
    id      = "wave",
    display = "Wave (Outobugi)",
    match   = {"wave"},
    vendor  = "Outobugi",
    type    = "saturation",
    roles   = {"Waveshaper","Distortion","FX"},

    sections = {
      "INPUT / DRIVE",
      "TONE / FILTER",
      "CHARACTER / MODE",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Verzerrungsmenge",
      tone         = "Tonformung / Filter / Tilt",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- IO/Filter (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_filter_x86 = {
    id      = "io_filter_x86",
    display = "IO/Filter (x86) (benoit serrano)",
    match   = {"io filter x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- IO/Panner (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_panner_x86 = {
    id      = "io_panner_x86",
    display = "IO/Panner (x86) (benoit serrano)",
    match   = {"io panner x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- IO/Phaser (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_phaser_x86 = {
    id      = "io_phaser_x86",
    display = "IO/Phaser (x86) (benoit serrano)",
    match   = {"io phaser x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- IO/PitchShift (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_pitchshift_x86 = {
    id      = "io_pitchshift_x86",
    display = "IO/PitchShift (x86) (benoit serrano)",
    match   = {"io pitchshift x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- IO/RingMod (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_ringmod_x86 = {
    id      = "io_ringmod_x86",
    display = "IO/RingMod (x86) (benoit serrano)",
    match   = {"io ringmod x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- IO/Volume (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_volume_x86 = {
    id      = "io_volume_x86",
    display = "IO/Volume (x86) (benoit serrano)",
    match   = {"io volume x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- Nibiru 3 (x86) (benoit serrano)
  --------------------------------------------------------------------
  nibiru_3_x86 = {
    id      = "nibiru_3_x86",
    display = "Nibiru 3 (x86) (benoit serrano)",
    match   = {"nibiru 3 x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- kHs 3-Band EQ (Kilohearts)
  --------------------------------------------------------------------
  khs_3_band_eq = {
    id      = "khs_3_band_eq",
    display = "kHs 3-Band EQ (Kilohearts)",
    match   = {"khs 3 band eq"},
    vendor  = "Kilohearts",
    type    = "eq",
    roles   = {"Basic","Utility","Tone"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "DYNAMIC / SPECIAL",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-Band / Bass",
      mid          = "Mitten-Band / Presence",
      high         = "High-Band / Air",
      dynamic      = "Dynamische EQ-Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- kHs Ring Mod (Kilohearts)
  --------------------------------------------------------------------
  khs_ring_mod = {
    id      = "khs_ring_mod",
    display = "kHs Ring Mod (Kilohearts)",
    match   = {"khs ring mod"},
    vendor  = "Kilohearts",
    type    = "ringmod",
    roles   = {"Ring Mod","Metallic","FX"},

    sections = {
      "INPUT / DRIVE",
      "TONE / FILTER",
      "CHARACTER / MODE",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Verzerrungsmenge",
      tone         = "Tonformung / Filter / Tilt",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- kHs Tape Stop (Kilohearts)
  --------------------------------------------------------------------
  khs_tape_stop = {
    id      = "khs_tape_stop",
    display = "kHs Tape Stop (Kilohearts)",
    match   = {"khs tape stop"},
    vendor  = "Kilohearts",
    type    = "stutter",
    roles   = {"Tape Stop","FX","Transition"},

    sections = {
      "RATE / SPEED",
      "DEPTH / AMOUNT",
      "TONE / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Modulationsgeschwindigkeit",
      depth        = "Modulationstiefe / Stärke",
      tone         = "Klangfärbung / Filter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Beat Slammer (x86) (BABY Audio)
  --------------------------------------------------------------------
  beat_slammer_x86 = {
    id      = "beat_slammer_x86",
    display = "Beat Slammer (x86) (BABY Audio)",
    match   = {"beat slammer x86"},
    vendor  = "BABY Audio",
    type    = "compressor",
    roles   = {"Drums","Punch","Limiter"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Kompressions-Schwelle",
      ratio        = "Kompressions-Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Magic Dice (x86) (BABY Audio) (64ch)
  --------------------------------------------------------------------
  magic_dice_x86_baby_audio = {
    id      = "magic_dice_x86_baby_audio",
    display = "Magic Dice (x86) (BABY Audio) (64ch)",
    match   = {"magic dice x86 baby audio"},
    vendor  = "BABY Audio",
    type    = "reverb",
    roles   = {"Random","Ambient","FX"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Raumgröße / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Magic Switch (x86) (BABY Audio) (64ch)
  --------------------------------------------------------------------
  magic_switch_x86_baby_audio = {
    id      = "magic_switch_x86_baby_audio",
    display = "Magic Switch (x86) (BABY Audio) (64ch)",
    match   = {"magic switch x86 baby audio"},
    vendor  = "BABY Audio",
    type    = "chorus",
    roles   = {"Chorus","Vintage","Simple"},

    sections = {
      "RATE / SPEED",
      "DEPTH / AMOUNT",
      "TONE / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Modulationsgeschwindigkeit",
      depth        = "Modulationstiefe / Stärke",
      tone         = "Klangfärbung / Filter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Warp (x86) (BABY Audio)
  --------------------------------------------------------------------
  warp_x86 = {
    id      = "warp_x86",
    display = "Warp (x86) (BABY Audio)",
    match   = {"warp x86"},
    vendor  = "BABY Audio",
    type    = "multi_fx",
    roles   = {"Texture","Delay","Pitch"},

    sections = {
      "MAIN CONTROLS",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Hauptparameter",
      mod          = "Bewegung / Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet / Blend",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Flanger 3 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_flanger_3_mono = {
    id      = "blue_cat_s_flanger_3_mono",
    display = "Blue Cat's Flanger 3 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s flanger 3 mono"},
    vendor  = "Blue Cat Audio",
    type    = "modulation",
    roles   = {"Flanger","Movement","FX"},

    sections = {
      "RATE / SPEED",
      "DEPTH / AMOUNT",
      "TONE / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      rate         = "Modulationsgeschwindigkeit",
      depth        = "Modulationstiefe / Stärke",
      tone         = "Klangfärbung / Filter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },



  --------------------------------------------------------------------
  -- Ozone 12 Equalizer (iZotope)
  --------------------------------------------------------------------
  ozone_12_equalizer = {
    id      = "ozone_12_equalizer",
    display = "Ozone 12 Equalizer (iZotope)",
    match   = {"ozone 12 equalizer"},
    vendor  = "iZotope",
    type    = "eq",
    roles   = {"Tone","Shaping"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      extra        = "Zusatzfunktionen / Charakter",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Trash (iZotope)
  --------------------------------------------------------------------
  trash = {
    id      = "trash",
    display = "Trash (iZotope)",
    match   = {"trash"},
    vendor  = "iZotope",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Vinyl (iZotope)
  --------------------------------------------------------------------
  vinyl = {
    id      = "vinyl",
    display = "Vinyl (iZotope)",
    match   = {"vinyl"},
    vendor  = "iZotope",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Raum (Native Instruments)
  --------------------------------------------------------------------
  raum = {
    id      = "raum",
    display = "Raum (Native Instruments)",
    match   = {"raum"},
    vendor  = "Native Instruments",
    type    = "reverb",
    roles   = {"Space","Ambience","FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Replika (Native Instruments)
  --------------------------------------------------------------------
  replika = {
    id      = "replika",
    display = "Replika (Native Instruments)",
    match   = {"replika"},
    vendor  = "Native Instruments",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Supercharger (Native Instruments)
  --------------------------------------------------------------------
  supercharger = {
    id      = "supercharger",
    display = "Supercharger (Native Instruments)",
    match   = {"supercharger"},
    vendor  = "Native Instruments",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Love (Dawesome)
  --------------------------------------------------------------------
  love = {
    id      = "love",
    display = "Love (Dawesome)",
    match   = {"love"},
    vendor  = "Dawesome",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Zyklop (Dawesome)!!!VSTi
  --------------------------------------------------------------------
  zyklop = {
    id      = "zyklop",
    display = "Zyklop (Dawesome)!!!VSTi",
    match   = {"zyklop","zyklop dawesome vsti"},
    vendor  = "Dawesome",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Surge XT (Surge Synth Team) (2->6ch)!!!VSTi
  --------------------------------------------------------------------
  surge_xt_surge_synth_team = {
    id      = "surge_xt_surge_synth_team",
    display = "Surge XT (Surge Synth Team) (2->6ch)!!!VSTi",
    match   = {"surge xt surge synth team","surge xt surge synth team 2 6ch vsti"},
    vendor  = "Surge Synth Team",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Surge XT Effects (Surge Synth Team)
  --------------------------------------------------------------------
  surge_xt_effects = {
    id      = "surge_xt_effects",
    display = "Surge XT Effects (Surge Synth Team)",
    match   = {"surge xt effects"},
    vendor  = "Surge Synth Team",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- VISION 4X (Excite Audio)
  --------------------------------------------------------------------
  vision_4x = {
    id      = "vision_4x",
    display = "VISION 4X (Excite Audio)",
    match   = {"vision 4x"},
    vendor  = "Excite Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- VISION 4X (x86) (Excite Audio)
  --------------------------------------------------------------------
  vision_4x_x86 = {
    id      = "vision_4x_x86",
    display = "VISION 4X (x86) (Excite Audio)",
    match   = {"vision 4x x86"},
    vendor  = "Excite Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Clamp (Outobugi)
  --------------------------------------------------------------------
  clamp = {
    id      = "clamp",
    display = "Clamp (Outobugi)",
    match   = {"clamp"},
    vendor  = "Outobugi",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Refire (Outobugi)
  --------------------------------------------------------------------
  refire = {
    id      = "refire",
    display = "Refire (Outobugi)",
    match   = {"refire"},
    vendor  = "Outobugi",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Wave (Outobugi)
  --------------------------------------------------------------------
  wave = {
    id      = "wave",
    display = "Wave (Outobugi)",
    match   = {"wave"},
    vendor  = "Outobugi",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- IO/Filter (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_filter_x86 = {
    id      = "io_filter_x86",
    display = "IO/Filter (x86) (benoit serrano)",
    match   = {"io filter x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- IO/Panner (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_panner_x86 = {
    id      = "io_panner_x86",
    display = "IO/Panner (x86) (benoit serrano)",
    match   = {"io panner x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- IO/Phaser (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_phaser_x86 = {
    id      = "io_phaser_x86",
    display = "IO/Phaser (x86) (benoit serrano)",
    match   = {"io phaser x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- IO/PitchShift (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_pitchshift_x86 = {
    id      = "io_pitchshift_x86",
    display = "IO/PitchShift (x86) (benoit serrano)",
    match   = {"io pitchshift x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- IO/RingMod (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_ringmod_x86 = {
    id      = "io_ringmod_x86",
    display = "IO/RingMod (x86) (benoit serrano)",
    match   = {"io ringmod x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- IO/Volume (x86) (benoit serrano)
  --------------------------------------------------------------------
  io_volume_x86 = {
    id      = "io_volume_x86",
    display = "IO/Volume (x86) (benoit serrano)",
    match   = {"io volume x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Nibiru 3 (x86) (benoit serrano)
  --------------------------------------------------------------------
  nibiru_3_x86 = {
    id      = "nibiru_3_x86",
    display = "Nibiru 3 (x86) (benoit serrano)",
    match   = {"nibiru 3 x86"},
    vendor  = "benoit serrano",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- kHs 3-Band EQ (Kilohearts)
  --------------------------------------------------------------------
  khs_3_band_eq = {
    id      = "khs_3_band_eq",
    display = "kHs 3-Band EQ (Kilohearts)",
    match   = {"khs 3 band eq"},
    vendor  = "Kilohearts",
    type    = "eq",
    roles   = {"Tone","Shaping"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      extra        = "Zusatzfunktionen / Charakter",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- kHs Ring Mod (Kilohearts)
  --------------------------------------------------------------------
  khs_ring_mod = {
    id      = "khs_ring_mod",
    display = "kHs Ring Mod (Kilohearts)",
    match   = {"khs ring mod"},
    vendor  = "Kilohearts",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- kHs Tape Stop (Kilohearts)
  --------------------------------------------------------------------
  khs_tape_stop = {
    id      = "khs_tape_stop",
    display = "kHs Tape Stop (Kilohearts)",
    match   = {"khs tape stop"},
    vendor  = "Kilohearts",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Beat Slammer (x86) (BABY Audio)
  --------------------------------------------------------------------
  beat_slammer_x86 = {
    id      = "beat_slammer_x86",
    display = "Beat Slammer (x86) (BABY Audio)",
    match   = {"beat slammer x86"},
    vendor  = "BABY Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Magic Dice (x86) (BABY Audio) (64ch)
  --------------------------------------------------------------------
  magic_dice_x86_baby_audio = {
    id      = "magic_dice_x86_baby_audio",
    display = "Magic Dice (x86) (BABY Audio) (64ch)",
    match   = {"magic dice x86 baby audio"},
    vendor  = "BABY Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Magic Switch (x86) (BABY Audio) (64ch)
  --------------------------------------------------------------------
  magic_switch_x86_baby_audio = {
    id      = "magic_switch_x86_baby_audio",
    display = "Magic Switch (x86) (BABY Audio) (64ch)",
    match   = {"magic switch x86 baby audio"},
    vendor  = "BABY Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Warp (x86) (BABY Audio)
  --------------------------------------------------------------------
  warp_x86 = {
    id      = "warp_x86",
    display = "Warp (x86) (BABY Audio)",
    match   = {"warp x86"},
    vendor  = "BABY Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Flanger 3 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_flanger_3_mono = {
    id      = "blue_cat_s_flanger_3_mono",
    display = "Blue Cat's Flanger 3 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s flanger 3 mono"},
    vendor  = "Blue Cat Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "TONE / FILTER",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter (Time / Size / Rate)",
      tone         = "Tonformung / Dämpfung / Filter",
      mod          = "Bewegung / Modulation / Spread",
      mix          = "Dry/Wet",
    },
  },



  --------------------------------------------------------------------
  -- ReaEQ (Cockos)
  --------------------------------------------------------------------
  reaeq = {
    id      = "reaeq",
    display = "ReaEQ (Cockos)",
    match   = {"reaeq"},
    vendor  = "Cockos",
    type    = "eq",
    roles   = {"Tone","Surgical","Utility"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- ReaComp (Cockos)
  --------------------------------------------------------------------
  reacomp = {
    id      = "reacomp",
    display = "ReaComp (Cockos)",
    match   = {"reacomp"},
    vendor  = "Cockos",
    type    = "compressor",
    roles   = {"Dynamics","Utility","MixBus"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- ReaFir (FFT EQ+Dynamics Processor) (Cockos)
  --------------------------------------------------------------------
  reafir_fft_eq_dynamics_processor = {
    id      = "reafir_fft_eq_dynamics_processor",
    display = "ReaFir (FFT EQ+Dynamics Processor) (Cockos)",
    match   = {"reafir fft eq dynamics processor"},
    vendor  = "Cockos",
    type    = "dynamic_eq",
    roles   = {"EQ","DeNoiser","Utility"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- ReaGate (Cockos)
  --------------------------------------------------------------------
  reagate = {
    id      = "reagate",
    display = "ReaGate (Cockos)",
    match   = {"reagate"},
    vendor  = "Cockos",
    type    = "gate",
    roles   = {"Gate","Drums","Utility"},

    sections = {
      "THRESHOLD",
      "ATTACK / RELEASE",
      "RANGE / HOLD",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Gate-Schwelle",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      range        = "Reduktionsbereich",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- ReaXcomp (Cockos)
  --------------------------------------------------------------------
  reaxcomp = {
    id      = "reaxcomp",
    display = "ReaXcomp (Cockos)",
    match   = {"reaxcomp"},
    vendor  = "Cockos",
    type    = "multiband_comp",
    roles   = {"Multiband","Mastering","Drums"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- ReaLimit (Cockos)
  --------------------------------------------------------------------
  realimit = {
    id      = "realimit",
    display = "ReaLimit (Cockos)",
    match   = {"realimit"},
    vendor  = "Cockos",
    type    = "limiter",
    roles   = {"Limiter","TruePeak","Safety"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Threshold / Input",
      ceiling      = "Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Transientenschutz",
      output       = "Output / Level",
    },
  },


  --------------------------------------------------------------------
  -- ReaPitch (Cockos)
  --------------------------------------------------------------------
  reapitch = {
    id      = "reapitch",
    display = "ReaPitch (Cockos)",
    match   = {"reapitch"},
    vendor  = "Cockos",
    type    = "pitch_fx",
    roles   = {"Pitch","Sound Design","Utility"},

    sections = {
      "INPUT",
      "PITCH / MODE",
      "FORMANT / QUALITY",
      "MIX / OUTPUT",
    },

    key_params = {
      pitch        = "Pitch-Shift / Zielton",
      mode         = "Algorithmus / Modus",
      formant      = "Formant / Formant-Korrektur",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- ReaTune (Cockos)
  --------------------------------------------------------------------
  reatune = {
    id      = "reatune",
    display = "ReaTune (Cockos)",
    match   = {"reatune"},
    vendor  = "Cockos",
    type    = "pitch_correct",
    roles   = {"Tuning","Vocal","Pitch"},

    sections = {
      "INPUT",
      "PITCH / MODE",
      "FORMANT / QUALITY",
      "MIX / OUTPUT",
    },

    key_params = {
      pitch        = "Pitch-Shift / Zielton",
      mode         = "Algorithmus / Modus",
      formant      = "Formant / Formant-Korrektur",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- ReaVerb (Cockos)
  --------------------------------------------------------------------
  reaverb = {
    id      = "reaverb",
    display = "ReaVerb (Cockos)",
    match   = {"reaverb"},
    vendor  = "Cockos",
    type    = "reverb",
    roles   = {"Reverb","Space","FX"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Größe / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- ReaVerbate (Cockos)
  --------------------------------------------------------------------
  reaverbate = {
    id      = "reaverbate",
    display = "ReaVerbate (Cockos)",
    match   = {"reaverbate"},
    vendor  = "Cockos",
    type    = "reverb",
    roles   = {"Reverb","Space","FX"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Größe / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- ReaStream (Cockos) (8ch)
  --------------------------------------------------------------------
  reastream_cockos = {
    id      = "reastream_cockos",
    display = "ReaStream (Cockos) (8ch)",
    match   = {"reastream cockos"},
    vendor  = "Cockos",
    type    = "network",
    roles   = {"Network","Routing","Utility"},

    sections = {
      "ROUTING",
      "SYNC / LATENCY",
      "MONITORING",
    },

    key_params = {
      routing      = "Routing-Quelle/Ziel",
      latency      = "Latenzausgleich",
      monitor      = "Monitoring / Rückweg",
    },
  },


  --------------------------------------------------------------------
  -- ReaInsert (Cockos)
  --------------------------------------------------------------------
  reainsert = {
    id      = "reainsert",
    display = "ReaInsert (Cockos)",
    match   = {"reainsert"},
    vendor  = "Cockos",
    type    = "hardware_insert",
    roles   = {"External HW","Routing","Utility"},

    sections = {
      "ROUTING",
      "SYNC / LATENCY",
      "MONITORING",
    },

    key_params = {
      routing      = "Routing-Quelle/Ziel",
      latency      = "Latenzausgleich",
      monitor      = "Monitoring / Rückweg",
    },
  },


  --------------------------------------------------------------------
  -- DS Tantra 2 (Plugin Alliance)
  --------------------------------------------------------------------
  ds_tantra_2 = {
    id      = "ds_tantra_2",
    display = "DS Tantra 2 (Plugin Alliance)",
    match   = {"ds tantra 2"},
    vendor  = "Plugin Alliance",
    type    = "multi_fx",
    roles   = {"Rhythmic","MultiFX","Sound Design"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- THE OVEN (Plugin Alliance)
  --------------------------------------------------------------------
  the_oven = {
    id      = "the_oven",
    display = "THE OVEN (Plugin Alliance)",
    match   = {"the oven"},
    vendor  = "Plugin Alliance",
    type    = "saturation",
    roles   = {"Mastering","Color","Saturation"},

    sections = {
      "INPUT / DRIVE",
      "COLOR / TONE",
      "MODE / CHARACTER",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Sättigung",
      tone         = "Tonformung / Filter",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Lindell 80 Bus (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_80_bus = {
    id      = "lindell_80_bus",
    display = "Lindell 80 Bus (Plugin Alliance)",
    match   = {"lindell 80 bus"},
    vendor  = "Plugin Alliance",
    type    = "bus_channelstrip",
    roles   = {"Bus","Console","Saturation"},

    sections = {
      "INPUT / DRIVE",
      "EQ / TONE",
      "COMP / GLUE",
      "OUTPUT",
    },

    key_params = {
      drive        = "Drive / Input",
      tone         = "EQ / Tonformung",
      comp         = "Kompression / Glue",
      output       = "Output / Fader",
    },
  },


  --------------------------------------------------------------------
  -- Lindell 902 De-esser (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_902_de_esser = {
    id      = "lindell_902_de_esser",
    display = "Lindell 902 De-esser (Plugin Alliance)",
    match   = {"lindell 902 de esser"},
    vendor  = "Plugin Alliance",
    type    = "deesser",
    roles   = {"DeEss","Vocal","Utility"},

    sections = {
      "FREQ / BAND",
      "SENSITIVITY",
      "BANDWIDTH",
      "OUTPUT",
    },

    key_params = {
      freq         = "Ziel-Frequenz / S-Bereich",
      sensitivity  = "Empfindlichkeit / Stärke",
      bandwidth    = "Bandbreite",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Lindell MU-66 (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_mu_66 = {
    id      = "lindell_mu_66",
    display = "Lindell MU-66 (Plugin Alliance)",
    match   = {"lindell mu 66"},
    vendor  = "Plugin Alliance",
    type    = "compressor",
    roles   = {"Vari-Mu","Bus","Master"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Lindell PEX-500 (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_pex_500 = {
    id      = "lindell_pex_500",
    display = "Lindell PEX-500 (Plugin Alliance)",
    match   = {"lindell pex 500"},
    vendor  = "Plugin Alliance",
    type    = "eq",
    roles   = {"Tone","Analog","Color"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- Lindell TE-100 (Plugin Alliance)
  --------------------------------------------------------------------
  lindell_te_100 = {
    id      = "lindell_te_100",
    display = "Lindell TE-100 (Plugin Alliance)",
    match   = {"lindell te 100"},
    vendor  = "Plugin Alliance",
    type    = "eq",
    roles   = {"Tone","Analog","Color"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio Sandman Pro (Plugin Alliance)
  --------------------------------------------------------------------
  unfiltered_audio_sandman_pro = {
    id      = "unfiltered_audio_sandman_pro",
    display = "Unfiltered Audio Sandman Pro (Plugin Alliance)",
    match   = {"unfiltered audio sandman pro"},
    vendor  = "Plugin Alliance",
    type    = "delay",
    roles   = {"Delay","Ambient","Granular"},

    sections = {
      "TIME / SYNC",
      "FEEDBACK",
      "FILTER / TONE",
      "MOD / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Delay-Time / Sync",
      feedback     = "Feedback",
      tone         = "Filter / Tonformung",
      mod          = "Modulation / Stereo",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio Silo (Plugin Alliance)
  --------------------------------------------------------------------
  unfiltered_audio_silo = {
    id      = "unfiltered_audio_silo",
    display = "Unfiltered Audio Silo (Plugin Alliance)",
    match   = {"unfiltered audio silo"},
    vendor  = "Plugin Alliance",
    type    = "reverb",
    roles   = {"Reverb","Spatial","Granular"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Größe / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio lo-fi-af (Plugin Alliance)
  --------------------------------------------------------------------
  unfiltered_audio_lo_fi_af = {
    id      = "unfiltered_audio_lo_fi_af",
    display = "Unfiltered Audio lo-fi-af (Plugin Alliance)",
    match   = {"unfiltered audio lo fi af"},
    vendor  = "Plugin Alliance",
    type    = "lofi",
    roles   = {"LoFi","Texture","Saturation"},

    sections = {
      "INPUT / DRIVE",
      "COLOR / TONE",
      "MODE / CHARACTER",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Sättigung",
      tone         = "Tonformung / Filter",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio Fault (Plugin Alliance)
  --------------------------------------------------------------------
  unfiltered_audio_fault = {
    id      = "unfiltered_audio_fault",
    display = "Unfiltered Audio Fault (Plugin Alliance)",
    match   = {"unfiltered audio fault"},
    vendor  = "Plugin Alliance",
    type    = "pitch_fx",
    roles   = {"Pitch","FreqShift","Weird"},

    sections = {
      "INPUT",
      "PITCH / MODE",
      "FORMANT / QUALITY",
      "MIX / OUTPUT",
    },

    key_params = {
      pitch        = "Pitch-Shift / Zielton",
      mode         = "Algorithmus / Modus",
      formant      = "Formant / Formant-Korrektur",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio G8 (Plugin Alliance) (4ch)
  --------------------------------------------------------------------
  unfiltered_audio_g8_plugin_alliance = {
    id      = "unfiltered_audio_g8_plugin_alliance",
    display = "Unfiltered Audio G8 (Plugin Alliance) (4ch)",
    match   = {"unfiltered audio g8 plugin alliance"},
    vendor  = "Plugin Alliance",
    type    = "gate",
    roles   = {"Gate","Rhythmic","Sidechain"},

    sections = {
      "THRESHOLD",
      "ATTACK / RELEASE",
      "RANGE / HOLD",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Gate-Schwelle",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      range        = "Reduktionsbereich",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio Bass Mint (Plugin Alliance)
  --------------------------------------------------------------------
  unfiltered_audio_bass_mint = {
    id      = "unfiltered_audio_bass_mint",
    display = "Unfiltered Audio Bass Mint (Plugin Alliance)",
    match   = {"unfiltered audio bass mint"},
    vendor  = "Plugin Alliance",
    type    = "bass_enhancer",
    roles   = {"LowEnd","Enhancer","Mastering"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_cleansweep V2 (Plugin Alliance)
  --------------------------------------------------------------------
  bx_cleansweep_v2 = {
    id      = "bx_cleansweep_v2",
    display = "bx_cleansweep V2 (Plugin Alliance)",
    match   = {"bx cleansweep v2"},
    vendor  = "Plugin Alliance",
    type    = "filter",
    roles   = {"Filter","Cleanup","Tone"},

    sections = {
      "INPUT",
      "HPF / LPF",
      "SHAPE / RESO",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel",
      hpf          = "Hochpass",
      lpf          = "Tiefpass",
      reso         = "Resonanz / Steilheit",
      output       = "Output",
    },
  },


  --------------------------------------------------------------------
  -- bx_opto Pedal (Plugin Alliance)
  --------------------------------------------------------------------
  bx_opto_pedal = {
    id      = "bx_opto_pedal",
    display = "bx_opto Pedal (Plugin Alliance)",
    match   = {"bx opto pedal"},
    vendor  = "Plugin Alliance",
    type    = "compressor",
    roles   = {"Guitar","Opto","Smooth"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- bx_rockrack V3 Player (Plugin Alliance)
  --------------------------------------------------------------------
  bx_rockrack_v3_player = {
    id      = "bx_rockrack_v3_player",
    display = "bx_rockrack V3 Player (Plugin Alliance)",
    match   = {"bx rockrack v3 player"},
    vendor  = "Plugin Alliance",
    type    = "amp_sim",
    roles   = {"Guitar","Amp","Cab"},

    sections = {
      "INPUT / GAIN",
      "AMP / TONE",
      "CAB / MIC",
      "FX / OUTPUT",
    },

    key_params = {
      gain         = "Amp-Gain / Drive",
      tone         = "Tone / EQ-Sektion",
      cab          = "Cabinet / Mikrofonwahl",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Protoverb (x86) (u-he)
  --------------------------------------------------------------------
  protoverb_x86 = {
    id      = "protoverb_x86",
    display = "Protoverb (x86) (u-he)",
    match   = {"protoverb x86"},
    vendor  = "u-he",
    type    = "reverb",
    roles   = {"Experimental","Reverb","Ambient"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Größe / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Podolski (x86) (u-he)!!!VSTi
  --------------------------------------------------------------------
  podolski_x86 = {
    id      = "podolski_x86",
    display = "Podolski (x86) (u-he)!!!VSTi",
    match   = {"podolski x86","podolski x86 u he vsti"},
    vendor  = "u-he",
    type    = "synth",
    roles   = {"Synth","Instrument","Pads"},

    sections = {
      "OSCILLATORS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Waves",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },



  --------------------------------------------------------------------
  -- ReaCast (Cockos)
  --------------------------------------------------------------------
  reacast = {
    id      = "reacast",
    display = "ReaCast (Cockos)",
    match   = {"reacast"},
    vendor  = "Cockos",
    type    = "network",
    roles   = {"Streaming","Broadcast","Utility"},

    sections = {
      "ROUTING",
      "SPATIAL / POSITION",
      "SYNC / LATENCY",
      "MONITORING",
    },

    key_params = {
      routing      = "Routing-Quelle/Ziel",
      position     = "Surround-/Pan-Position",
      latency      = "Latenzausgleich",
      monitor      = "Monitoring / Solo",
    },
  },


  --------------------------------------------------------------------
  -- ReaControlMIDI (Cockos)
  --------------------------------------------------------------------
  reacontrolmidi = {
    id      = "reacontrolmidi",
    display = "ReaControlMIDI (Cockos)",
    match   = {"reacontrolmidi"},
    vendor  = "Cockos",
    type    = "midi_tool",
    roles   = {"MIDI","Control","Automation"},

    sections = {
      "ROUTING",
      "FILTER / MAP",
      "LFO / MOD",
      "EXTRA",
    },

    key_params = {
      routing      = "MIDI-Ein/Ausgänge / Channel",
      filter       = "Filter / Mapping / CC",
      mod          = "LFO / Automation",
    },
  },


  --------------------------------------------------------------------
  -- ReaNINJAM (Cockos)
  --------------------------------------------------------------------
  reaninjam = {
    id      = "reaninjam",
    display = "ReaNINJAM (Cockos)",
    match   = {"reaninjam"},
    vendor  = "Cockos",
    type    = "network",
    roles   = {"Online Jam","Network","Utility"},

    sections = {
      "ROUTING",
      "SPATIAL / POSITION",
      "SYNC / LATENCY",
      "MONITORING",
    },

    key_params = {
      routing      = "Routing-Quelle/Ziel",
      position     = "Surround-/Pan-Position",
      latency      = "Latenzausgleich",
      monitor      = "Monitoring / Solo",
    },
  },


  --------------------------------------------------------------------
  -- ReaSurround (Cockos)
  --------------------------------------------------------------------
  reasurround = {
    id      = "reasurround",
    display = "ReaSurround (Cockos)",
    match   = {"reasurround"},
    vendor  = "Cockos",
    type    = "surround_panner",
    roles   = {"Surround","Panning","3D Audio"},

    sections = {
      "ROUTING",
      "SPATIAL / POSITION",
      "SYNC / LATENCY",
      "MONITORING",
    },

    key_params = {
      routing      = "Routing-Quelle/Ziel",
      position     = "Surround-/Pan-Position",
      latency      = "Latenzausgleich",
      monitor      = "Monitoring / Solo",
    },
  },


  --------------------------------------------------------------------
  -- ReaSurroundPan (Cockos)
  --------------------------------------------------------------------
  reasurroundpan = {
    id      = "reasurroundpan",
    display = "ReaSurroundPan (Cockos)",
    match   = {"reasurroundpan"},
    vendor  = "Cockos",
    type    = "surround_panner",
    roles   = {"Surround","Panning","3D Audio"},

    sections = {
      "ROUTING",
      "SPATIAL / POSITION",
      "SYNC / LATENCY",
      "MONITORING",
    },

    key_params = {
      routing      = "Routing-Quelle/Ziel",
      position     = "Surround-/Pan-Position",
      latency      = "Latenzausgleich",
      monitor      = "Monitoring / Solo",
    },
  },


  --------------------------------------------------------------------
  -- ReaSynDr (Cockos) (4 out)!!!VSTi
  --------------------------------------------------------------------
  reasyndr_cockos = {
    id      = "reasyndr_cockos",
    display = "ReaSynDr (Cockos) (4 out)!!!VSTi",
    match   = {"reasyndr cockos","reasyndr cockos 4 out vsti"},
    vendor  = "Cockos",
    type    = "drum_synth",
    roles   = {"Drums","Synth","Percussion"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- ReaVocode (Cockos)
  --------------------------------------------------------------------
  reavocode = {
    id      = "reavocode",
    display = "ReaVocode (Cockos)",
    match   = {"reavocode"},
    vendor  = "Cockos",
    type    = "vocoder",
    roles   = {"Vocoder","Voice FX","Synth FX"},

    sections = {
      "CARRIER",
      "MODULATOR",
      "FILTERBANK",
      "MIX / OUTPUT",
    },

    key_params = {
      carrier      = "Carrier-Level / Synth",
      modulator    = "Modulator-Level / Voice",
      filter       = "Filterbank / Bands",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- ReaVoice (Cockos)
  --------------------------------------------------------------------
  reavoice = {
    id      = "reavoice",
    display = "ReaVoice (Cockos)",
    match   = {"reavoice"},
    vendor  = "Cockos",
    type    = "pitch_fx",
    roles   = {"Harmony","Pitch","Vocal FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Convoluter v1.5 (AnarchySoundSoftware)
  --------------------------------------------------------------------
  convoluter_v1_5 = {
    id      = "convoluter_v1_5",
    display = "Convoluter v1.5 (AnarchySoundSoftware)",
    match   = {"convoluter v1 5"},
    vendor  = "AnarchySoundSoftware",
    type    = "spectral_fx",
    roles   = {"Spectral","Glitch","Design"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Corkscrew v1.5 (AnarchySoundSoftware)
  --------------------------------------------------------------------
  corkscrew_v1_5 = {
    id      = "corkscrew_v1_5",
    display = "Corkscrew v1.5 (AnarchySoundSoftware)",
    match   = {"corkscrew v1 5"},
    vendor  = "AnarchySoundSoftware",
    type    = "pitch_fx",
    roles   = {"Shepard","Rising/Falling","Weird"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- HarmonicAdder v1.5 (AnarchySoundSoftware)
  --------------------------------------------------------------------
  harmonicadder_v1_5 = {
    id      = "harmonicadder_v1_5",
    display = "HarmonicAdder v1.5 (AnarchySoundSoftware)",
    match   = {"harmonicadder v1 5"},
    vendor  = "AnarchySoundSoftware",
    type    = "harmonic_fx",
    roles   = {"Harmonics","Shimmer","Sound Design"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- LengthSeparator v1.5 (AnarchySoundSoftware)
  --------------------------------------------------------------------
  lengthseparator_v1_5 = {
    id      = "lengthseparator_v1_5",
    display = "LengthSeparator v1.5 (AnarchySoundSoftware)",
    match   = {"lengthseparator v1 5"},
    vendor  = "AnarchySoundSoftware",
    type    = "transient_shaper",
    roles   = {"Transient","Sustain","Stereo"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- SpectralAutopan v1.5 (AnarchySoundSoftware)
  --------------------------------------------------------------------
  spectralautopan_v1_5 = {
    id      = "spectralautopan_v1_5",
    display = "SpectralAutopan v1.5 (AnarchySoundSoftware)",
    match   = {"spectralautopan v1 5"},
    vendor  = "AnarchySoundSoftware",
    type    = "modulation",
    roles   = {"Autopan","Spectral","Stereo"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- adc Shape Lite 2 (Audec)
  --------------------------------------------------------------------
  adc_shape_lite_2 = {
    id      = "adc_shape_lite_2",
    display = "adc Shape Lite 2 (Audec)",
    match   = {"adc shape lite 2"},
    vendor  = "Audec",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's FreqAnalyst 2 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_freqanalyst_2_mono = {
    id      = "blue_cat_s_freqanalyst_2_mono",
    display = "Blue Cat's FreqAnalyst 2 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s freqanalyst 2 mono"},
    vendor  = "Blue Cat Audio",
    type    = "analyzer",
    roles   = {"Spectrum","Analyzer","Meter"},

    sections = {
      "DISPLAY",
      "RANGE / SCALE",
      "FOCUS / MODE",
      "EXTRA",
    },

    key_params = {
      display      = "Anzeige / Visualisierung",
      range        = "dB-Range / Skala",
      focus        = "Fokus (Frequenz / Stereo / Ziel)",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Gain 3 (Dual) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_gain_3_dual = {
    id      = "blue_cat_s_gain_3_dual",
    display = "Blue Cat's Gain 3 (Dual) (Blue Cat Audio)",
    match   = {"blue cat s gain 3 dual"},
    vendor  = "Blue Cat Audio",
    type    = "utility",
    roles   = {"Gain","Trim","Utility"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Gain 3 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_gain_3_mono = {
    id      = "blue_cat_s_gain_3_mono",
    display = "Blue Cat's Gain 3 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s gain 3 mono"},
    vendor  = "Blue Cat Audio",
    type    = "utility",
    roles   = {"Gain","Trim","Utility"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Triple EQ 4 (Dual) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_triple_eq_4_dual = {
    id      = "blue_cat_s_triple_eq_4_dual",
    display = "Blue Cat's Triple EQ 4 (Dual) (Blue Cat Audio)",
    match   = {"blue cat s triple eq 4 dual"},
    vendor  = "Blue Cat Audio",
    type    = "eq",
    roles   = {"Tone","3-Band EQ","Utility"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Triple EQ 4 (Mono) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_triple_eq_4_mono = {
    id      = "blue_cat_s_triple_eq_4_mono",
    display = "Blue Cat's Triple EQ 4 (Mono) (Blue Cat Audio)",
    match   = {"blue cat s triple eq 4 mono"},
    vendor  = "Blue Cat Audio",
    type    = "eq",
    roles   = {"Tone","3-Band EQ","Utility"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- BucketPops (Full Bucket Music) (16 out)!!!VSTi
  --------------------------------------------------------------------
  bucketpops_full_bucket_music = {
    id      = "bucketpops_full_bucket_music",
    display = "BucketPops (Full Bucket Music) (16 out)!!!VSTi",
    match   = {"bucketpops full bucket music","bucketpops full bucket music 16 out vsti"},
    vendor  = "Full Bucket Music",
    type    = "synth",
    roles   = {"Synth","Vintage","Instrument"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Fire (Wings)
  --------------------------------------------------------------------
  fire = {
    id      = "fire",
    display = "Fire (Wings)",
    match   = {"fire"},
    vendor  = "Wings",
    type    = "distortion",
    roles   = {"Multiband","Distortion","Downsampler"},

    sections = {
      "INPUT / DRIVE",
      "COLOR / TONE",
      "MODE / CHARACTER",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Drive / Sättigung",
      tone         = "Tonformung / Filter",
      mode         = "Modus / Charakter",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- Free Clip 2 (Venn Audio)
  --------------------------------------------------------------------
  free_clip_2 = {
    id      = "free_clip_2",
    display = "Free Clip 2 (Venn Audio)",
    match   = {"free clip 2"},
    vendor  = "Venn Audio",
    type    = "limiter",
    roles   = {"Limiter","Safety","Master"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Threshold / Input",
      ceiling      = "Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Schutz",
      output       = "Output / Level",
    },
  },


  --------------------------------------------------------------------
  -- HoRNetMagnusLite (HoRNet)
  --------------------------------------------------------------------
  hornetmagnuslite = {
    id      = "hornetmagnuslite",
    display = "HoRNetMagnusLite (HoRNet)",
    match   = {"hornetmagnuslite"},
    vendor  = "HoRNet",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Karanyi Sounds Wavesurfer (Plugin Alliance)
  --------------------------------------------------------------------
  karanyi_sounds_wavesurfer = {
    id      = "karanyi_sounds_wavesurfer",
    display = "Karanyi Sounds Wavesurfer (Plugin Alliance)",
    match   = {"karanyi sounds wavesurfer"},
    vendor  = "Plugin Alliance",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- LatticeReverb (Uhhyou)
  --------------------------------------------------------------------
  latticereverb = {
    id      = "latticereverb",
    display = "LatticeReverb (Uhhyou)",
    match   = {"latticereverb"},
    vendor  = "Uhhyou",
    type    = "reverb",
    roles   = {"Space","Ambience","FX"},

    sections = {
      "PRE-DELAY / TIME",
      "SIZE / SHAPE",
      "TONE / DIFFUSION",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Reverb-/Decay-Zeit",
      predelay     = "Pre-Delay",
      size         = "Größe / Shape",
      tone         = "Tonformung / Dämpfung",
      mix          = "Dry/Wet",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- MJUCjr (Klanghelm)
  --------------------------------------------------------------------
  mjucjr = {
    id      = "mjucjr",
    display = "MJUCjr (Klanghelm)",
    match   = {"mjucjr"},
    vendor  = "Klanghelm",
    type    = "compressor",
    roles   = {"Saturation","Compression","Character"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- MNDALA 2 (MNTRA)!!!VSTi
  --------------------------------------------------------------------
  mndala_2 = {
    id      = "mndala_2",
    display = "MNDALA 2 (MNTRA)!!!VSTi",
    match   = {"mndala 2","mndala 2 mntra vsti"},
    vendor  = "MNTRA",
    type    = "synth",
    roles   = {"Hybrid","Textural","Instrument"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- OTT (Xfer Records)
  --------------------------------------------------------------------
  ott = {
    id      = "ott",
    display = "OTT (Xfer Records)",
    match   = {"ott"},
    vendor  = "Xfer Records",
    type    = "multiband_comp",
    roles   = {"EDM","Up/Down Compression","Aggressive"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Platone Studio Alton Limiter (Platone Studio Ltd.)
  --------------------------------------------------------------------
  platone_studio_alton_limiter = {
    id      = "platone_studio_alton_limiter",
    display = "Platone Studio Alton Limiter (Platone Studio Ltd.)",
    match   = {"platone studio alton limiter"},
    vendor  = "Platone Studio Ltd.",
    type    = "limiter",
    roles   = {"Limiter","Safety","Master"},

    sections = {
      "INPUT",
      "THRESHOLD / CEILING",
      "TIMING",
      "OUTPUT",
    },

    key_params = {
      threshold    = "Threshold / Input",
      ceiling      = "Ceiling / Zielpegel",
      release      = "Release / Timing",
      lookahead    = "Lookahead / Schutz",
      output       = "Output / Level",
    },
  },


  --------------------------------------------------------------------
  -- Shadow Hills Mastering Compressor (Plugin Alliance)
  --------------------------------------------------------------------
  shadow_hills_mastering_compressor = {
    id      = "shadow_hills_mastering_compressor",
    display = "Shadow Hills Mastering Compressor (Plugin Alliance)",
    match   = {"shadow hills mastering compressor"},
    vendor  = "Plugin Alliance",
    type    = "compressor",
    roles   = {"Dynamics","Glue"},

    sections = {
      "INPUT",
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MIX / OUTPUT",
    },

    key_params = {
      threshold    = "Schwelle",
      ratio        = "Verhältnis",
      attack       = "Attack-Zeit",
      release      = "Release-Zeit",
      mix          = "Dry/Wet / Parallel",
      output       = "Output / Make-Up Gain",
    },
  },


  --------------------------------------------------------------------
  -- Stimulate (Viator DSP)
  --------------------------------------------------------------------
  stimulate = {
    id      = "stimulate",
    display = "Stimulate (Viator DSP)",
    match   = {"stimulate"},
    vendor  = "Viator DSP",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- TDR VOS SlickEQ (Tokyo Dawn Labs)
  --------------------------------------------------------------------
  tdr_vos_slickeq = {
    id      = "tdr_vos_slickeq",
    display = "TDR VOS SlickEQ (Tokyo Dawn Labs)",
    match   = {"tdr vos slickeq"},
    vendor  = "Tokyo Dawn Labs",
    type    = "eq",
    roles   = {"Tone","Shaping"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- TEOTE (Voxengo)
  --------------------------------------------------------------------
  teote = {
    id      = "teote",
    display = "TEOTE (Voxengo)",
    match   = {"teote"},
    vendor  = "Voxengo",
    type    = "dynamic_eq",
    roles   = {"Spectral Balance","Mastering","MixBus"},

    sections = {
      "INPUT",
      "BANDS / FILTERS",
      "SPECIAL / DYNAMIC",
      "OUTPUT",
    },

    key_params = {
      input        = "Eingangspegel / Trim",
      low          = "Low-/Bass-Band",
      mid          = "Mitten-Bearbeitung",
      high         = "High-/Air-Band",
      dynamic      = "Dynamische Funktionen / Specials",
      output       = "Output / Gain",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio Battalion (Plugin Alliance) (18 out)!!!VSTi
  --------------------------------------------------------------------
  unfiltered_audio_battalion_plugin_alliance = {
    id      = "unfiltered_audio_battalion_plugin_alliance",
    display = "Unfiltered Audio Battalion (Plugin Alliance) (18 out)!!!VSTi",
    match   = {"unfiltered audio battalion plugin alliance","unfiltered audio battalion plugin alliance 18 out vsti"},
    vendor  = "Plugin Alliance",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Wider (Polyverse Music)
  --------------------------------------------------------------------
  wider = {
    id      = "wider",
    display = "Wider (Polyverse Music)",
    match   = {"wider"},
    vendor  = "Polyverse Music",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Youlean Loudness Meter 2 (Youlean) (24ch)
  --------------------------------------------------------------------
  youlean_loudness_meter_2_youlean = {
    id      = "youlean_loudness_meter_2_youlean",
    display = "Youlean Loudness Meter 2 (Youlean) (24ch)",
    match   = {"youlean loudness meter 2 youlean"},
    vendor  = "Youlean",
    type    = "meter",
    roles   = {"Loudness","Metering","Mastering"},

    sections = {
      "DISPLAY",
      "RANGE / SCALE",
      "FOCUS / MODE",
      "EXTRA",
    },

    key_params = {
      display      = "Anzeige / Visualisierung",
      range        = "dB-Range / Skala",
      focus        = "Fokus (Frequenz / Stereo / Ziel)",
    },
  },


  --------------------------------------------------------------------
  -- Voltage Modular FX (Cherry Audio) (4->8ch)
  --------------------------------------------------------------------
  voltage_modular_fx_cherry_audio = {
    id      = "voltage_modular_fx_cherry_audio",
    display = "Voltage Modular FX (Cherry Audio) (4->8ch)",
    match   = {"voltage modular fx cherry audio"},
    vendor  = "Cherry Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Voltage Modular (Cherry Audio) (4->8ch)!!!VSTi
  --------------------------------------------------------------------
  voltage_modular_cherry_audio = {
    id      = "voltage_modular_cherry_audio",
    display = "Voltage Modular (Cherry Audio) (4->8ch)!!!VSTi",
    match   = {"voltage modular cherry audio","voltage modular cherry audio 4 8ch vsti"},
    vendor  = "Cherry Audio",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- RareSE (AnalogObsession)
  --------------------------------------------------------------------
  rarese = {
    id      = "rarese",
    display = "RareSE (AnalogObsession)",
    match   = {"rarese"},
    vendor  = "AnalogObsession",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- PaulXStretch (Sonosaurus) (18ch)
  --------------------------------------------------------------------
  paulxstretch_sonosaurus = {
    id      = "paulxstretch_sonosaurus",
    display = "PaulXStretch (Sonosaurus) (18ch)",
    match   = {"paulxstretch sonosaurus"},
    vendor  = "Sonosaurus",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- MERICA (AnalogObsession)
  --------------------------------------------------------------------
  merica = {
    id      = "merica",
    display = "MERICA (AnalogObsession)",
    match   = {"merica"},
    vendor  = "AnalogObsession",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- T-Force Zenith (Mastrcode Music)!!!VSTi
  --------------------------------------------------------------------
  t_force_zenith = {
    id      = "t_force_zenith",
    display = "T-Force Zenith (Mastrcode Music)!!!VSTi",
    match   = {"t force zenith","t force zenith mastrcode music vsti"},
    vendor  = "Mastrcode Music",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Krush (Tritik)
  --------------------------------------------------------------------
  krush = {
    id      = "krush",
    display = "Krush (Tritik)",
    match   = {"krush"},
    vendor  = "Tritik",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- JETMIX (Acqua)
  --------------------------------------------------------------------
  jetmix = {
    id      = "jetmix",
    display = "JETMIX (Acqua)",
    match   = {"jetmix"},
    vendor  = "Acqua",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- JET (Acqua)
  --------------------------------------------------------------------
  jet = {
    id      = "jet",
    display = "JET (Acqua)",
    match   = {"jet"},
    vendor  = "Acqua",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Ozone Imager 2 (iZotope, Inc.)
  --------------------------------------------------------------------
  ozone_imager_2 = {
    id      = "ozone_imager_2",
    display = "Ozone Imager 2 (iZotope, Inc.)",
    match   = {"ozone imager 2"},
    vendor  = "iZotope, Inc.",
    type    = "stereo_imager",
    roles   = {"Stereo","Width","Imaging"},

    sections = {
      "DISPLAY",
      "RANGE / SCALE",
      "FOCUS / MODE",
      "EXTRA",
    },

    key_params = {
      display      = "Anzeige / Visualisierung",
      range        = "dB-Range / Skala",
      focus        = "Fokus (Frequenz / Stereo / Ziel)",
    },
  },


  --------------------------------------------------------------------
  -- ChowPhaserStereo (chowdsp)
  --------------------------------------------------------------------
  chowphaserstereo = {
    id      = "chowphaserstereo",
    display = "ChowPhaserStereo (chowdsp)",
    match   = {"chowphaserstereo"},
    vendor  = "chowdsp",
    type    = "modulation",
    roles   = {"Chorus/Phase","Movement","FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- ChowPhaserMono (chowdsp)
  --------------------------------------------------------------------
  chowphasermono = {
    id      = "chowphasermono",
    display = "ChowPhaserMono (chowdsp)",
    match   = {"chowphasermono"},
    vendor  = "chowdsp",
    type    = "modulation",
    roles   = {"Chorus/Phase","Movement","FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Parameter",
      extra        = "Zusatzfunktionen",
      output       = "Output-Level",
    },
  },


  --------------------------------------------------------------------
  -- BreadSlicer (Audioblast)
  --------------------------------------------------------------------
  breadslicer = {
    id      = "breadslicer",
    display = "BreadSlicer (Audioblast)",
    match   = {"breadslicer"},
    vendor  = "Audioblast",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Bark of Dog 3 (Boz Digital Labs) (mono)
  --------------------------------------------------------------------
  bark_of_dog_3_boz_digital_labs = {
    id      = "bark_of_dog_3_boz_digital_labs",
    display = "Bark of Dog 3 (Boz Digital Labs) (mono)",
    match   = {"bark of dog 3 boz digital labs"},
    vendor  = "Boz Digital Labs",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Acon Digital Multiply (Acon Digital) (8ch)
  --------------------------------------------------------------------
  acon_digital_multiply_acon_digital = {
    id      = "acon_digital_multiply_acon_digital",
    display = "Acon Digital Multiply (Acon Digital) (8ch)",
    match   = {"acon digital multiply acon digital"},
    vendor  = "Acon Digital",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- bong (x86) (rurik leffanta) (12 out)!!!VSTi
  --------------------------------------------------------------------
  bong_x86_rurik_leffanta = {
    id      = "bong_x86_rurik_leffanta",
    display = "bong (x86) (rurik leffanta) (12 out)!!!VSTi",
    match   = {"bong x86 rurik leffanta","bong x86 rurik leffanta 12 out vsti"},
    vendor  = "rurik leffanta",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Danaides (x86) (Inear_Display)
  --------------------------------------------------------------------
  danaides_x86 = {
    id      = "danaides_x86",
    display = "Danaides (x86) (Inear_Display)",
    match   = {"danaides x86"},
    vendor  = "Inear_Display",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- dblue Crusher (x86) (dblue)
  --------------------------------------------------------------------
  dblue_crusher_x86 = {
    id      = "dblue_crusher_x86",
    display = "dblue Crusher (x86) (dblue)",
    match   = {"dblue crusher x86"},
    vendor  = "dblue",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- dblue Glitch v1.3 (x86) (dblue)
  --------------------------------------------------------------------
  dblue_glitch_v1_3_x86 = {
    id      = "dblue_glitch_v1_3_x86",
    display = "dblue Glitch v1.3 (x86) (dblue)",
    match   = {"dblue glitch v1 3 x86"},
    vendor  = "dblue",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- dblue Stretch v1.1 (x86) (dblue)
  --------------------------------------------------------------------
  dblue_stretch_v1_1_x86 = {
    id      = "dblue_stretch_v1_1_x86",
    display = "dblue Stretch v1.1 (x86) (dblue)",
    match   = {"dblue stretch v1 1 x86"},
    vendor  = "dblue",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- dblue.TapeStop (x86) (dblue)
  --------------------------------------------------------------------
  dblue_tapestop_x86 = {
    id      = "dblue_tapestop_x86",
    display = "dblue.TapeStop (x86) (dblue)",
    match   = {"dblue tapestop x86"},
    vendor  = "dblue",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Drum Boxx Synth Free (x86) (SonicXTC)!!!VSTi
  --------------------------------------------------------------------
  drum_boxx_synth_free_x86 = {
    id      = "drum_boxx_synth_free_x86",
    display = "Drum Boxx Synth Free (x86) (SonicXTC)!!!VSTi",
    match   = {"drum boxx synth free x86","drum boxx synth free x86 sonicxtc vsti"},
    vendor  = "SonicXTC",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- stoooner (x86) (rurik leffanta)!!!VSTi
  --------------------------------------------------------------------
  stoooner_x86 = {
    id      = "stoooner_x86",
    display = "stoooner (x86) (rurik leffanta)!!!VSTi",
    match   = {"stoooner x86","stoooner x86 rurik leffanta vsti"},
    vendor  = "rurik leffanta",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- TripleCheese (x86) (u-he)!!!VSTi
  --------------------------------------------------------------------
  triplecheese_x86 = {
    id      = "triplecheese_x86",
    display = "TripleCheese (x86) (u-he)!!!VSTi",
    match   = {"triplecheese x86","triplecheese x86 u he vsti"},
    vendor  = "u-he",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- TyrellN6 (x86) (u-he)!!!VSTi
  --------------------------------------------------------------------
  tyrelln6_x86 = {
    id      = "tyrelln6_x86",
    display = "TyrellN6 (x86) (u-he)!!!VSTi",
    match   = {"tyrelln6 x86","tyrelln6 x86 u he vsti"},
    vendor  = "u-he",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- ZebraHZ (x86) (u-he)!!!VSTi
  --------------------------------------------------------------------
  zebrahz_x86 = {
    id      = "zebrahz_x86",
    display = "ZebraHZ (x86) (u-he)!!!VSTi",
    match   = {"zebrahz x86","zebrahz x86 u he vsti"},
    vendor  = "u-he",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- Drumatic 3 (x86) (Pieter-Jan Arts) (12 out)!!!VSTi
  --------------------------------------------------------------------
  drumatic_3_x86_pieter_jan_arts = {
    id      = "drumatic_3_x86_pieter_jan_arts",
    display = "Drumatic 3 (x86) (Pieter-Jan Arts) (12 out)!!!VSTi",
    match   = {"drumatic 3 x86 pieter jan arts","drumatic 3 x86 pieter jan arts 12 out vsti"},
    vendor  = "Pieter-Jan Arts",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- AirMusic (Sound Particles)
  --------------------------------------------------------------------
  airmusic = {
    id      = "airmusic",
    display = "AirMusic (Sound Particles)",
    match   = {"airmusic"},
    vendor  = "Sound Particles",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Flux Mini 2 (Caelum Audio)
  --------------------------------------------------------------------
  flux_mini_2 = {
    id      = "flux_mini_2",
    display = "Flux Mini 2 (Caelum Audio)",
    match   = {"flux mini 2"},
    vendor  = "Caelum Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Malibu (VZtec)
  --------------------------------------------------------------------
  malibu = {
    id      = "malibu",
    display = "Malibu (VZtec)",
    match   = {"malibu"},
    vendor  = "VZtec",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Molot (Vladislav Goncharov)
  --------------------------------------------------------------------
  molot = {
    id      = "molot",
    display = "Molot (Vladislav Goncharov)",
    match   = {"molot"},
    vendor  = "Vladislav Goncharov",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- Transperc (Apisonic Labs)
  --------------------------------------------------------------------
  transperc = {
    id      = "transperc",
    display = "Transperc (Apisonic Labs)",
    match   = {"transperc"},
    vendor  = "Apisonic Labs",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


  --------------------------------------------------------------------
  -- HALion Sonic (Steinberg Media Technologies) (32 out)!!!VSTi
  --------------------------------------------------------------------
  halion_sonic_steinberg_media_technologies = {
    id      = "halion_sonic_steinberg_media_technologies",
    display = "HALion Sonic (Steinberg Media Technologies) (32 out)!!!VSTi",
    match   = {"halion sonic steinberg media technologies","halion sonic steinberg media technologies 32 out vsti"},
    vendor  = "Steinberg Media Technologies",
    type    = "synth",
    roles   = {"Instrument","Synth","Melodic"},

    sections = {
      "OSCILLATORS / DRUMS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX / OUTPUT",
    },

    key_params = {
      osc          = "Oszillatoren / Drum-Engines",
      filter       = "Filter-Cutoff / Resonanz",
      env          = "Amp-/Filter-Hüllkurven",
      mod          = "LFOs / Mod-Matrix",
    },
  },


  --------------------------------------------------------------------
  -- VPRE-72 (Fuse Audio Labs)
  --------------------------------------------------------------------
  vpre_72 = {
    id      = "vpre_72",
    display = "VPRE-72 (Fuse Audio Labs)",
    match   = {"vpre 72"},
    vendor  = "Fuse Audio Labs",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN",
      "MOVEMENT / MOD",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Hauptparameter / Engines",
      mod          = "Modulation / Rhythmik",
      tone         = "Filter / Tonformung",
      mix          = "Dry/Wet",
    },
  },


}' of MetaCore.vst)

  --------------------------------------------------------------------
  -- bx_console Focusrite SC (Plugin Alliance)
  --------------------------------------------------------------------
  bx_console_focusrite_sc = {
    id      = "bx_console_focusrite_sc",
    display = "bx_console Focusrite SC (Plugin Alliance)",
    match   = {"bx console focusrite sc"},
    vendor  = "Plugin Alliance",
    type    = "channelstrip",
    roles   = {"Channelstrip","MixBus","Console"},

    sections = {
      "INPUT / GAIN",
      "FILTERS",
      "DYNAMICS (COMP/GATE)",
      "EQ",
      "OUTPUT",
    },

    key_params = {
      input_gain   = "Eingangspegel",
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressor-Verhältnis",
      eq_gain      = "EQ Gain",
      output       = "Ausgangspegel/Make-Up",
    },
  },


  --------------------------------------------------------------------
  -- bx_console SSL 4000 E (Plugin Alliance)
  --------------------------------------------------------------------
  bx_console_ssl_4000_e = {
    id      = "bx_console_ssl_4000_e",
    display = "bx_console SSL 4000 E (Plugin Alliance)",
    match   = {"bx console ssl 4000 e"},
    vendor  = "Plugin Alliance",
    type    = "channelstrip",
    roles   = {"Channelstrip","MixBus","Console"},

    sections = {
      "INPUT / GAIN",
      "FILTERS",
      "DYNAMICS (COMP/GATE)",
      "EQ",
      "OUTPUT",
    },

    key_params = {
      input_gain   = "Eingangspegel",
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressor-Verhältnis",
      eq_gain      = "EQ Gain",
      output       = "Ausgangspegel/Make-Up",
    },
  },


  --------------------------------------------------------------------
  -- bx_console SSL 4000 G (Plugin Alliance)
  --------------------------------------------------------------------
  bx_console_ssl_4000_g = {
    id      = "bx_console_ssl_4000_g",
    display = "bx_console SSL 4000 G (Plugin Alliance)",
    match   = {"bx console ssl 4000 g"},
    vendor  = "Plugin Alliance",
    type    = "channelstrip",
    roles   = {"Channelstrip","MixBus","Console"},

    sections = {
      "INPUT / GAIN",
      "FILTERS",
      "DYNAMICS (COMP/GATE)",
      "EQ",
      "OUTPUT",
    },

    key_params = {
      input_gain   = "Eingangspegel",
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressor-Verhältnis",
      eq_gain      = "EQ Gain",
      output       = "Ausgangspegel/Make-Up",
    },
  },


  --------------------------------------------------------------------
  -- bx_console SSL 9000 J (Plugin Alliance)
  --------------------------------------------------------------------
  bx_console_ssl_9000_j = {
    id      = "bx_console_ssl_9000_j",
    display = "bx_console SSL 9000 J (Plugin Alliance)",
    match   = {"bx console ssl 9000 j"},
    vendor  = "Plugin Alliance",
    type    = "channelstrip",
    roles   = {"Channelstrip","MixBus","Console"},

    sections = {
      "INPUT / GAIN",
      "FILTERS",
      "DYNAMICS (COMP/GATE)",
      "EQ",
      "OUTPUT",
    },

    key_params = {
      input_gain   = "Eingangspegel",
      threshold    = "Kompressor-Schwelle",
      ratio        = "Kompressor-Verhältnis",
      eq_gain      = "EQ Gain",
      output       = "Ausgangspegel/Make-Up",
    },
  },


  --------------------------------------------------------------------
  -- bx_digital V3 mix (Plugin Alliance)
  --------------------------------------------------------------------
  bx_digital_v3_mix = {
    id      = "bx_digital_v3_mix",
    display = "bx_digital V3 mix (Plugin Alliance)",
    match   = {"bx digital v3 mix"},
    vendor  = "Plugin Alliance",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- bx_enhancer (Plugin Alliance)
  --------------------------------------------------------------------
  bx_enhancer = {
    id      = "bx_enhancer",
    display = "bx_enhancer (Plugin Alliance)",
    match   = {"bx enhancer"},
    vendor  = "Plugin Alliance",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- bx_glue (Plugin Alliance)
  --------------------------------------------------------------------
  bx_glue = {
    id      = "bx_glue",
    display = "bx_glue (Plugin Alliance)",
    match   = {"bx glue"},
    vendor  = "Plugin Alliance",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Unfiltered Audio Zip (Plugin Alliance)
  --------------------------------------------------------------------
  unfiltered_audio_zip = {
    id      = "unfiltered_audio_zip",
    display = "Unfiltered Audio Zip (Plugin Alliance)",
    match   = {"unfiltered audio zip"},
    vendor  = "Plugin Alliance",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Chorus 4 (Stereo) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_chorus_4_stereo = {
    id      = "blue_cat_s_chorus_4_stereo",
    display = "Blue Cat's Chorus 4 (Stereo) (Blue Cat Audio)",
    match   = {"blue cat s chorus 4 stereo"},
    vendor  = "Blue Cat Audio",
    type    = "modulation",
    roles   = {"Modulation","FX"},

    sections = {
      "TIME / SIZE",
      "TONE / SHAPE",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Zeit / Pre-Delay / Rate",
      size         = "Größe / Feedback / Depth",
      tone         = "Tonformung / Dämpfung",
      mod          = "Modulationsstärke",
      mix          = "Dry/Wet",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Flanger 3 (Stereo) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_flanger_3_stereo = {
    id      = "blue_cat_s_flanger_3_stereo",
    display = "Blue Cat's Flanger 3 (Stereo) (Blue Cat Audio)",
    match   = {"blue cat s flanger 3 stereo"},
    vendor  = "Blue Cat Audio",
    type    = "modulation",
    roles   = {"Modulation","FX"},

    sections = {
      "TIME / SIZE",
      "TONE / SHAPE",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Zeit / Pre-Delay / Rate",
      size         = "Größe / Feedback / Depth",
      tone         = "Tonformung / Dämpfung",
      mod          = "Modulationsstärke",
      mix          = "Dry/Wet",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Phaser 3 (Stereo) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_phaser_3_stereo = {
    id      = "blue_cat_s_phaser_3_stereo",
    display = "Blue Cat's Phaser 3 (Stereo) (Blue Cat Audio)",
    match   = {"blue cat s phaser 3 stereo"},
    vendor  = "Blue Cat Audio",
    type    = "modulation",
    roles   = {"Modulation","FX"},

    sections = {
      "TIME / SIZE",
      "TONE / SHAPE",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Zeit / Pre-Delay / Rate",
      size         = "Größe / Feedback / Depth",
      tone         = "Tonformung / Dämpfung",
      mod          = "Modulationsstärke",
      mix          = "Dry/Wet",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's Triple EQ 4 (Stereo) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_triple_eq_4_stereo = {
    id      = "blue_cat_s_triple_eq_4_stereo",
    display = "Blue Cat's Triple EQ 4 (Stereo) (Blue Cat Audio)",
    match   = {"blue cat s triple eq 4 stereo"},
    vendor  = "Blue Cat Audio",
    type    = "eq",
    roles   = {"Tone","Shaping"},

    sections = {
      "FILTERS / BANDS",
      "OUTPUT",
    },

    key_params = {
      low_band     = "Low-Shelf/Low-Band Gain",
      mid_band     = "Mittenband",
      high_band    = "High-Shelf/High-Band Gain",
      output       = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- Blue Cat's FreqAnalyst 2 (Stereo) (Blue Cat Audio)
  --------------------------------------------------------------------
  blue_cat_s_freqanalyst_2_stereo = {
    id      = "blue_cat_s_freqanalyst_2_stereo",
    display = "Blue Cat's FreqAnalyst 2 (Stereo) (Blue Cat Audio)",
    match   = {"blue cat s freqanalyst 2 stereo"},
    vendor  = "Blue Cat Audio",
    type    = "eq",
    roles   = {"Tone","Shaping"},

    sections = {
      "FILTERS / BANDS",
      "OUTPUT",
    },

    key_params = {
      low_band     = "Low-Shelf/Low-Band Gain",
      mid_band     = "Mittenband",
      high_band    = "High-Shelf/High-Band Gain",
      output       = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- ValhallaFreqEcho (Valhalla DSP, LLC)
  --------------------------------------------------------------------
  valhallafreqecho = {
    id      = "valhallafreqecho",
    display = "ValhallaFreqEcho (Valhalla DSP, LLC)",
    match   = {"valhallafreqecho"},
    vendor  = "Valhalla DSP, LLC",
    type    = "eq",
    roles   = {"Tone","Shaping"},

    sections = {
      "FILTERS / BANDS",
      "OUTPUT",
    },

    key_params = {
      low_band     = "Low-Shelf/Low-Band Gain",
      mid_band     = "Mittenband",
      high_band    = "High-Shelf/High-Band Gain",
      output       = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- ValhallaSpaceModulator (Valhalla DSP, LLC)
  --------------------------------------------------------------------
  valhallaspacemodulator = {
    id      = "valhallaspacemodulator",
    display = "ValhallaSpaceModulator (Valhalla DSP, LLC)",
    match   = {"valhallaspacemodulator"},
    vendor  = "Valhalla DSP, LLC",
    type    = "modulation",
    roles   = {"Modulation","FX"},

    sections = {
      "TIME / SIZE",
      "TONE / SHAPE",
      "MOD / MOVEMENT",
      "MIX / OUTPUT",
    },

    key_params = {
      time         = "Zeit / Pre-Delay / Rate",
      size         = "Größe / Feedback / Depth",
      tone         = "Tonformung / Dämpfung",
      mod          = "Modulationsstärke",
      mix          = "Dry/Wet",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- ValhallaSupermassive (Valhalla DSP, LLC)
  --------------------------------------------------------------------
  valhallasupermassive = {
    id      = "valhallasupermassive",
    display = "ValhallaSupermassive (Valhalla DSP, LLC)",
    match   = {"valhallasupermassive"},
    vendor  = "Valhalla DSP, LLC",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Lens (Auburn Sounds)
  --------------------------------------------------------------------
  lens = {
    id      = "lens",
    display = "Lens (Auburn Sounds)",
    match   = {"lens"},
    vendor  = "Auburn Sounds",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Panagement 2 (Auburn Sounds)
  --------------------------------------------------------------------
  panagement_2 = {
    id      = "panagement_2",
    display = "Panagement 2 (Auburn Sounds)",
    match   = {"panagement 2"},
    vendor  = "Auburn Sounds",
    type    = "stereo_tool",
    roles   = {"Stereo","Width","Pan"},

    sections = {
      "WIDTH / PAN",
      "MID/SIDE",
      "OUTPUT",
    },

    key_params = {
      width        = "Stereo-Breite",
      pan          = "Panorama",
      mid_side     = "Mid/Side-Balance",
      output       = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- Inner Pitch 2 (Auburn Sounds)
  --------------------------------------------------------------------
  inner_pitch_2 = {
    id      = "inner_pitch_2",
    display = "Inner Pitch 2 (Auburn Sounds)",
    match   = {"inner pitch 2"},
    vendor  = "Auburn Sounds",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- adc Crush 2 (Audec)
  --------------------------------------------------------------------
  adc_crush_2 = {
    id      = "adc_crush_2",
    display = "adc Crush 2 (Audec)",
    match   = {"adc crush 2"},
    vendor  = "Audec",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- adc Haas 2 (Audec)
  --------------------------------------------------------------------
  adc_haas_2 = {
    id      = "adc_haas_2",
    display = "adc Haas 2 (Audec)",
    match   = {"adc haas 2"},
    vendor  = "Audec",
    type    = "stereo_tool",
    roles   = {"Stereo","Width","Pan"},

    sections = {
      "WIDTH / PAN",
      "MID/SIDE",
      "OUTPUT",
    },

    key_params = {
      width        = "Stereo-Breite",
      pan          = "Panorama",
      mid_side     = "Mid/Side-Balance",
      output       = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- adc Ring 2 (Audec)
  --------------------------------------------------------------------
  adc_ring_2 = {
    id      = "adc_ring_2",
    display = "adc Ring 2 (Audec)",
    match   = {"adc ring 2"},
    vendor  = "Audec",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- adc Vectorscope 2 (Audec)
  --------------------------------------------------------------------
  adc_vectorscope_2 = {
    id      = "adc_vectorscope_2",
    display = "adc Vectorscope 2 (Audec)",
    match   = {"adc vectorscope 2"},
    vendor  = "Audec",
    type    = "meter",
    roles   = {"Meter","Analyzer"},

    sections = {
      "DISPLAY / RANGE",
      "SCALE / SLOPE",
      "HOLD / PEAK",
      "EXTRA",
    },

    key_params = {
      range        = "Anzeigebereich",
      scale        = "Skalierung/Kurve",
      hold         = "Peak-Hold / Fallzeit",
    },
  },


  --------------------------------------------------------------------
  -- Warp (BABY Audio)
  --------------------------------------------------------------------
  warp = {
    id      = "warp",
    display = "Warp (BABY Audio)",
    match   = {"warp"},
    vendor  = "BABY Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Pitch Drift (x86) (BABY Audio)
  --------------------------------------------------------------------
  pitch_drift_x86 = {
    id      = "pitch_drift_x86",
    display = "Pitch Drift (x86) (BABY Audio)",
    match   = {"pitch drift x86"},
    vendor  = "BABY Audio",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- A1StereoControl (A1AUDIO.de)
  --------------------------------------------------------------------
  a1stereocontrol = {
    id      = "a1stereocontrol",
    display = "A1StereoControl (A1AUDIO.de)",
    match   = {"a1stereocontrol"},
    vendor  = "A1AUDIO.de",
    type    = "stereo_tool",
    roles   = {"Stereo","Width","Pan"},

    sections = {
      "WIDTH / PAN",
      "MID/SIDE",
      "OUTPUT",
    },

    key_params = {
      width        = "Stereo-Breite",
      pan          = "Panorama",
      mid_side     = "Mid/Side-Balance",
      output       = "Output Gain",
    },
  },


  --------------------------------------------------------------------
  -- A1TriggerGate (A1AUDIO.de)
  --------------------------------------------------------------------
  a1triggergate = {
    id      = "a1triggergate",
    display = "A1TriggerGate (A1AUDIO.de)",
    match   = {"a1triggergate"},
    vendor  = "A1AUDIO.de",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- Acon Digital Multiply (Acon Digital)
  --------------------------------------------------------------------
  acon_digital_multiply = {
    id      = "acon_digital_multiply",
    display = "Acon Digital Multiply (Acon Digital)",
    match   = {"acon digital multiply"},
    vendor  = "Acon Digital",
    type    = "fx_misc",
    roles   = {"FX"},

    sections = {
      "MAIN CONTROLS",
      "EXTRA",
      "MIX / OUTPUT",
    },

    key_params = {
      main         = "Wichtigste Klangparameter",
      mix          = "Dry/Wet oder Mix",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- CHOWTapeModel (chowdsp)
  --------------------------------------------------------------------
  chowtapemodel = {
    id      = "chowtapemodel",
    display = "CHOWTapeModel (chowdsp)",
    match   = {"chowtapemodel"},
    vendor  = "chowdsp",
    type    = "saturation",
    roles   = {"Saturation","Color"},

    sections = {
      "DRIVE",
      "TONE / FILTER",
      "DYNAMICS",
      "MIX / OUTPUT",
    },

    key_params = {
      drive        = "Sättigungs-/Drive-Menge",
      tone         = "Tonformung / Tilt",
      mix          = "Dry/Wet",
      output       = "Ausgangspegel",
    },
  },


  --------------------------------------------------------------------
  -- ZebraHZ (u-he)!!!VSTi
  --------------------------------------------------------------------
  zebrahz = {
    id      = "zebrahz",
    display = "ZebraHZ (u-he)!!!VSTi",
    match   = {"zebrahz","zebrahz u he vsti"},
    vendor  = "u-he",
    type    = "synth",
    roles   = {"Synth","Instrument"},

    sections = {
      "OSCILLATORS",
      "FILTER",
      "ENVELOPES",
      "MODULATION",
      "FX",
    },

    key_params = {
      osc_mix      = "Oszillator-Mix",
      filter_cutoff = "Filter-Cutoff",
      env_attack   = "Amp-Envelope Attack",
      env_release  = "Amp-Envelope Release",
    },
  },



MetaCore.vst = -- legacy require removed (see V2 loader below)



--------------------------------------------------------------------
  -- LOVE (Dawesome) – Ambient Multi-FX (Granular + Shimmer + Reverb)
  --------------------------------------------------------------------
  love_dawesome = {
    id      = "love_dawesome",
    display = "LOVE (Dawesome)",
    match   = {"love %(dawesome%)","dawesome love","love %(tracktion%)"},
    vendor  = "Dawesome / Tracktion",
    type    = "multi_fx_ambient",
    roles   = {"Reverb","Shimmer","Granular","Space","IDM","Ambient"},

    url     = "https://www.dawesomemusic.com/plugins/love/",

    sections = {
      "INPUT / DRIVE",
      "SHIMMER (Pitch + Feedback)",
      "GRANULAR ENGINE (Grains)",
      "SPACE / CLOUD REVERB",
      "FILTER / TONE",
      "RANDOMIZE / LOCK",
      "GLOBAL MIX / OUTPUT",
    },

    key_params = {
      input_gain      = "Input Gain – Pegel des eingehenden Signals",
      shimmer_amount  = "Shimmer Amount – Intensität der oktavierten/gepichten Anteile",
      shimmer_pitch   = "Shimmer Pitch – Intervall (z.B. +12, +7, etc.)",
      grain_density   = "Grain Density – Dichte der Granular-Grains",
      grain_size      = "Grain Size – Länge der Grains",
      grain_spread    = "Grain Spread – Stereo- und Zeitstreuung",
      reverb_size     = "Reverb Size / Space – Größe des Cloud-Reverbs",
      reverb_decay    = "Reverb Decay / Time",
      tone_filter     = "Tone / Filter – Helligkeit/Färbung der FX-Wolke",
      random_amount   = "Randomize Amount – Stärke der Zufallsveränderungen",
      lock_flags      = "Lock Flags – welche Sektionen von Randomize ausgeschlossen sind",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain – Gesamtpegel nach der FX-Kette",
    },

    sweetspots = {
      instant_pad = {
        description = "Dröge Synth-Flächen in Sekunden in große Ambient-Wolken verwandeln",
        hints = {
          "Shimmer Amount moderat, Pitch auf +12 oder +7",
          "Grain Density eher hoch, Size mittel",
          "Reverb Size groß, Decay lang, Tone etwas dunkler drehen",
          "Mix bei 40–60% für Pads, 100% für FX-Sends",
        },
      },
      idm_drums_cloud = {
        description = "Percussion/IDM-Drums in granulierte, schimmernde Texturen verwandeln",
        hints = {
          "Input Gain eher niedrig, damit Transienten nicht komplett zerfallen",
          "Grain Size kurz, Spread hoch für Glitch",
          "Randomize leicht nutzen, aber Shimmer/Size locken, um Konsistenz zu halten",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Lindell 80 Channel – 80-Series Channel Strip (Neve-inspiriert)
  --------------------------------------------------------------------
  lindell_80_channel = {
    id      = "lindell_80_channel",
    display = "Lindell 80 Channel",
    match   = {"lindell 80 channel","lindell 80 series","80 channel %(plugin alliance%)"},
    vendor  = "Lindell Audio / Plugin Alliance",
    type    = "channel_strip_80series",
    roles   = {"Channel Strip","EQ","Preamp","Compressor","Gate","Analog","Mix","Bus"},

    url     = "https://www.plugin-alliance.com/en/products/lindell_80_series.html",

    sections = {
      "PREAMP (MIC/LINE, GAIN, DRIVE)",
      "HPF / LPF",
      "4-BAND EQ (High/HighMid/LowMid/Low)",
      "DYNAMICS (Kompressor/Gate/Expander)",
      "OUTPUT / TRIM",
      "ANALOG / NOISE / OVERSAMPLING",
    },

    key_params = {
      pre_gain        = "Preamp Gain – Eingangsgain (Mic/Line) inkl. Sättigung",
      line_mic_switch = "Line/Mic Umschalter",
      hpf_freq        = "Highpass Frequency – Low-Cut des Channels",
      lpf_freq        = "Lowpass Frequency – High-Cut des Channels",
      eq_hi_gain      = "High-Shelf Gain",
      eq_himid_gain   = "High-Mid Band Gain",
      eq_lomid_gain   = "Low-Mid Band Gain",
      eq_lo_gain      = "Low-Shelf Gain",
      comp_threshold  = "Channel Compressor Threshold",
      comp_ratio      = "Channel Compressor Ratio",
      comp_attack     = "Channel Compressor Attack",
      comp_release    = "Channel Compressor Release",
      gate_threshold  = "Gate/Expander Threshold",
      output_trim     = "Output Trim / Fader",
      analog_noise    = "Analog/Noise – analoger Rausch-/Klang-Charakter",
      oversampling    = "Oversampling – Anti-Aliasing/CPU-Balance",
    },

    sweetspots = {
      drum_channel = {
        description = "Drum-Channel-Sound: Punch + EQ in einem Strip",
        hints = {
          "Preamp etwas heiß fahren für leichtes Sättigen",
          "HPF zwischen 40–80 Hz zum Aufräumen einzelner Drums",
          "EQ Lo-Mid gezielt für Mud Entfernen, High-Shelf für Crisp",
          "Channel-Kompressor mit mittlerem Attack/Release für Snap",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- NEOLD WARBLE – Tape/LoFi/Modulation
  --------------------------------------------------------------------
  neold_warble = {
    id      = "neold_warble",
    display = "NEOLD WARBLE",
    match   = {"neold warble","warble %(plugin alliance%)"},
    vendor  = "NEOLD / Plugin Alliance",
    type    = "tape_lofi_mod",
    roles   = {"Tape","Wow/Flutter","LoFi","Modulation","Color","IDM"},

    url     = "https://www.plugin-alliance.com/en/products/warble.html",

    sections = {
      "TAPE CORE (Sättigung, Bias, Level)",
      "WOW / FLUTTER / DRIFT",
      "NOISE / DIRT / DROP-OUT",
      "FILTER (High/Low Cut + Resonanz)",
      "STEREO / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      tape_drive      = "Tape Drive / Input",
      wow_amount      = "Wow Amount – langsame Tonhöhenschwankungen",
      flutter_amount  = "Flutter Amount – schnellere Tonhöhenschwankungen",
      drift           = "Drift / Instabilität über Zeit",
      noise_level     = "Tape Noise / Hiss Level",
      dropouts        = "Dropout Intensity – kurze Aussetzer",
      hc_freq         = "High Cut Frequency",
      lc_freq         = "Low Cut Frequency",
      hc_res          = "High Cut Resonance",
      lc_res          = "Low Cut Resonance",
      stereo_width    = "Stereo Width / Imaging",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },

    sweetspots = {
      loFi_bus = {
        description = "LoFi-Wärme auf Drums/Bus ohne alles zu zerstören",
        hints = {
          "Tape Drive moderat, Wow/Flutter klein, Drift leicht",
          "High Cut ~8–12 kHz für soften Top-End, etwas Noise für „Band“-Illusion",
          "Dropouts sehr subtil oder aus für Bus",
        },
      },
      warbly_keys = {
        description = "Keys/Pad in vibrierende, instabile Texturen verwandeln",
        hints = {
          "Wow und Drift höher, Flutter moderat",
          "Stereo Width aufdrehen, High Cut tiefer setzen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- NEOLD BIG AL – Dual-Stage Tube Saturator
  --------------------------------------------------------------------
  neold_big_al = {
    id      = "neold_big_al",
    display = "NEOLD BIG AL",
    match   = {"big al","neold big al"},
    vendor  = "NEOLD / Plugin Alliance",
    type    = "saturation_tube_dual",
    roles   = {"Saturation","Tube","Color","Bus","Master","IDM"},

    url     = "https://www.plugin-alliance.com/en/products/big-al.html",

    sections = {
      "INPUT / OUTPUT",
      "PREAMP STAGE (EF9)",
      "POWER STAGE (AL4, AZ1)",
      "LOW / HIGH TONE (Baxandall)",
      "JUMPER MATRIX (Emphasis, Bass Comp, Voltage Sag)",
    },

    key_params = {
      input_gain      = "Input Drive – steuert Sättigungsmenge beider Stufen",
      output_gain     = "Output Level",
      low_tone        = "Low Tone – Baxandall-Style Bass um 100 Hz",
      high_tone       = "High Tone – Treble/Präsenz",
      emphasis_shift  = "Emphasis Shift – ändert interne Sättigungs-Charakteristik",
      bass_comp       = "Bass Compensator – kompensiert Bass bei stärkerer Sättigung",
      voltage_sag     = "Voltage Sag – simuliert Versorgungsspannungs-Einbruch",
    },

    sweetspots = {
      drum_bus_color = {
        description = "Bus-Sättigung mit Gewicht ohne Matsch",
        hints = {
          "Input moderat, Output auf Unity trimmen",
          "Low Tone leicht anheben, High Tone minimal",
          "Voltage Sag klein, Emphasis Shift anpassen, bis Kick/Snare „klebt“",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- LoudMax – Look-Ahead Brickwall Limiter
  --------------------------------------------------------------------
  loudmax = {
    id      = "loudmax",
    display = "LoudMax",
    match   = {"loudmax","loudmax64"},
    vendor  = "Thomas Mundt",
    type    = "limiter_brickwall",
    roles   = {"Limiter","Maximizer","Master","Web","Streaming","Free"},

    url     = "https://loudmax.blogspot.com/",

    sections = {
      "INPUT / OUTPUT METERING",
      "THRESHOLD / OUTPUT (CEILING)",
      "RELEASE / LOOK-AHEAD (intern)",
    },

    key_params = {
      threshold      = "Threshold – Pegel, ab dem Limiting einsetzt",
      output_ceiling = "Output / Ceiling – maximaler Ausgangspegel",
      link_in_out    = "Input/Output Link – auto Gain-Compensation",
      release        = "Release (ggf. automatisch, je nach Version)",
    },

    sweetspots = {
      fast_master = {
        description = "Schnelles, transparentes Lautness-Matching",
        hints = {
          "Output Ceiling auf -1 dBFS für Streaming",
          "Threshold so einstellen, dass 1–3 dB GR im Durchschnitt erreicht werden",
          "Bei stärkerer GR auf Pumpeffekte achten, eher parallel oder auf Subgruppen nutzen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- MJUCjr – Vari-Mu Kompressor (Free)
  --------------------------------------------------------------------
  mjuc_jr = {
    id      = "mjuc_jr",
    display = "MJUCjr",
    match   = {"mjucjr","mjuc jr","mjuc_jr"},
    vendor  = "Klanghelm",
    type    = "compressor_vari_mu",
    roles   = {"Compressor","Vari-Mu","Bus","Vibe","Vintage","Free"},

    url     = "https://klanghelm.com/contents/products/MJUCjr",

    sections = {
      "INPUT / OUTPUT",
      "COMPRESSOR CORE (Vari-Mu)",
      "TIMING SWITCH (3 Modi)",
      "GR METERING",
    },

    key_params = {
      drive          = "Drive / Input – bestimmt Kompressionsstärke + Sättigung",
      makeup_gain    = "Output / Makeup Gain",
      timing_mode    = "Timing Switch – 3 Kompressions-Charaktere",
      mix            = "Parallel Mix (falls Version es anbietet, sonst Null)",
    },

    sweetspots = {
      vocal_glue = {
        description = "Weiche, „klebrige“ Vocal-Kompression",
        hints = {
          "Drive so einstellen, dass ca. 2–5 dB GR",
          "Timing auf mittleren oder langsamen Modus",
          "Makeup so, dass Pegel etwa gleich laut erscheint",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- MNDALA 2 – Hybrid-Sounddesign-Engine von MNTRA
  --------------------------------------------------------------------
  mndala2 = {
    id      = "mndala2",
    display = "MNDALA 2",
    match   = {"mndala 2","mndala2","mandala 2"},
    vendor  = "MNTRA Instruments",
    type    = "engine_multilayer",
    roles   = {"Engine","Sampler","Granular","Hybrid","Textur","IDM"},

    url     = "https://www.mntra.io/mndala/",

    sections = {
      "INSTRUMENT SLOTS / LAYERS",
      "MIXER (Volume / Pan / Sends)",
      "MOD MATRIX (AniMod Operatoren)",
      "SEQUENCER (mit Randomize)",
      "FX (Multi-FX: Delays, Filter, Reverb, Saturation, etc.)",
      "GLOBAL / PERFORMANCE",
    },

    key_params = {
      layer_volumes  = "Layer Volume – Lautstärke pro Instrument-Layer",
      layer_pan      = "Layer Pan – Panorama je Layer",
      animod_amount  = "AniMod – Modulationsstärke (multi-Operator System)",
      seq_rate       = "Sequencer Rate / Speed",
      seq_random     = "Sequencer Randomize / Probability",
      fx_reverb      = "Global Reverb Amount",
      fx_delay       = "Global Delay Amount",
      fx_filter      = "Filter-Cutoff/Resonance auf Master oder Layern",
    },

    sweetspots = {
      textur_idm = {
        description = "Organische, düstere IDM-Texturen aus MNDALA-Instrumenten",
        hints = {
          "Mindestens 2 Layer mit unterschiedlichen Klangquellen stacken",
          "AniMod langsam modulieren lassen, Reverb und Delay moderat",
          "Sequencer im Random-Mode als stetigen Bewegungsgeber nutzen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Moon Echo – Moon-Bounce & Experimental Delay
  --------------------------------------------------------------------
  moon_echo = {
    id      = "moon_echo",
    display = "Moon Echo",
    match   = {"moon echo","moon echo %(audiothing%)"},
    vendor  = "AudioThing / Hainbach",
    type    = "delay_experimental",
    roles   = {"Delay","Experimental","LoFi","Space","Free"},

    url     = "https://www.audiothing.net/effects/moon-echo/",

    sections = {
      "DELAY TIME / BOUNCE",
      "FEEDBACK",
      "FILTER / TONE",
      "MODULATION (Movement durch Erde/Mond)",
      "NOISE / DIRT",
      "MIX / OUTPUT",
    },

    key_params = {
      delay_time     = "Delay Time – Basis-Laufzeit (abhängig von ‚moon bounce‘)",
      feedback       = "Feedback – Anzahl/Intensität der Echos",
      lowpass        = "Lowpass Filter – dämpft hohe Frequenzen",
      highpass       = "Highpass Filter – entfernt Subanteile",
      modulation     = "Modulation Depth/Rate – imitiert Bewegung Erde/Mond",
      noise_amount   = "Noise / Artifacts – Grad der Imperfektion",
      mix            = "Dry/Wet Mix",
    },

    sweetspots = {
      spaced_glitch = {
        description = "Glitchige, schmutzige, aber räumliche Echos",
        hints = {
          "Feedback moderat, Noise/Artifacts etwas anheben",
          "Filter so setzen, dass nur mittlere Frequenzen deutlich bleiben",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- lkjb SeeSaw – Tilt EQ
  --------------------------------------------------------------------
  seesaw_lkjb = {
    id      = "seesaw_lkjb",
    display = "lkjb SeeSaw",
    match   = {"lkjb_seesaw","seesaw %(lkjb%)","lkjb seesaw"},
    vendor  = "lkjb",
    type    = "tilt_eq",
    roles   = {"EQ","Tilt","Tone","Balance","Free"},

    url     = "https://www.kvraudio.com/product/seesaw-by-lkjb",

    sections = {
      "PIVOT FREQUENCY",
      "GAIN / TILT AMOUNT",
      "STEREO MODE (Full/Mid/Side)",
    },

    key_params = {
      pivot_freq     = "Pivot Frequency – Drehpunkt der Tilt-Kurve",
      tilt_gain      = "Tilt Amount – wie stark Höhen vs. Tiefen gekippt werden",
      stereo_mode    = "Stereo Mode – Full, Mid only oder Side only",
    },

    sweetspots = {
      quick_balance = {
        description = "Schnelles Hell/Dunkel-Balancing von Spuren oder Mix",
        hints = {
          "Pivot bei ~1–2 kHz für Mixbus, leicht nach oben/unten drehen",
          "Für Vocals Pivot etwas höher, für Drums tiefer",
          "Mid- oder Side-Only-Modus nutzen, um z.B. nur die Sides heller zu machen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- NEOLD V76U73 – V76 Röhrenpreamp + U73 Kompressor
  --------------------------------------------------------------------
  neold_v76u73 = {
    id      = "neold_v76u73",
    display = "NEOLD V76U73",
    match   = {"v76u73","neold v76","neold v76u73"},
    vendor  = "NEOLD / Plugin Alliance",
    type    = "preamp_compressor_tube",
    roles   = {"Preamp","Compressor","Tube","Vintage","Bus","Vocal"},

    url     = "https://www.plugin-alliance.com/en/products/v76u73.html",

    sections = {
      "V76 PREAMP (Gain, Character)",
      "U73 COMPRESSOR / LIMITER",
      "HIGHPASS / LOWCUT & HIGH CUT FILTERS",
      "LINEAR MODE (Full Range)",
      "OUTPUT / MIX",
    },

    key_params = {
      pre_gain       = "Preamp Gain – V76 Vorverstärkung inkl. Röhrensättigung",
      comp_threshold = "U73 Threshold – Kompressor/Limiter Einsatzpunkt",
      comp_ratio     = "U73 Kompressionsverhältnis (modell-typisch)",
      comp_time      = "U73 Zeitkonstanten (Attack/Release, Mode)",
      hp_filter      = "Lowcut/Highpass (Flat / 80 Hz / 300 Hz / kombiniert)",
      hc_filter      = "Highcut (Flat / 3 kHz)",
      linear_mode    = "Linear Mode – deaktiviert analoge Bandbegrenzung",
      output_gain    = "Output Level",
      mix            = "Dry/Wet Mix (falls Version es bietet, sonst Null)",
    },

    sweetspots = {
      vocal_v76 = {
        description = "V76 „Radiovibe“ auf Vocals mit U73-Kompression",
        hints = {
          "Pre-Gain so wählen, dass leichte Röhrenfärbung, nicht knallig",
          "HP-Filter bei 80 Hz, HC ggf. Flat lassen für moderne Sounds",
          "Kompression moderat, auf 2–4 dB GR zielen",
        },
      },
    },
  },

--------------------------------------------------------------------
  -- Emergence – Granular Delay (Daniel Gergely)
  --------------------------------------------------------------------
  emergence = {
    id      = "emergence",
    display = "Emergence (Daniel Gergely)",
    match   = {"emergence %(daniel gergely%)","emergence granul","emergence"},
    vendor  = "Daniel Gergely",
    type    = "granular_delay",
    roles   = {"Delay","Granular","Texture","IDM","Glitch","Free"},

    url     = "https://www.danielgergely.com/emergence",

    sections = {
      "INPUT / PRE-FILTER",
      "GRAIN ENGINE (Density/Duration/Spread)",
      "PITCH / RANDOM",
      "FEEDBACK / REVERB",
      "OUTPUT / MIX",
    },

    key_params = {
      input_gain      = "Input Gain",
      density         = "Grain Density – Anzahl der Grains pro Zeit",
      duration        = "Grain Duration – Länge der einzelnen Grains",
      position        = "Grain Position – Aufnahmefenster im Buffer",
      pitch           = "Pitch Shift – Grundton der Grains",
      random_pitch    = "Random Pitch – Zufallsverstimmung",
      spread          = "Stereo Spread – Panorama-Breite der Grains",
      feedback        = "Feedback – wie viele Wiederholungen erzeugt werden",
      reverb_amount   = "Reverb Amount – Nachhall im Wet-Signal",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      shimmer_cloud = {
        description = "Schwebende Granular-Wolken aus Pads/Keys",
        hints = {
          "Density mittel, Duration eher lang, Spread hoch",
          "Pitch leicht nach oben (+3 bis +7), Random Pitch moderat",
          "Reverb dazu, Mix bei 40–60%",
        },
      },
      glitch_drums = {
        description = "IDM-Drums als zerschnittene Glitch-Textur",
        hints = {
          "Kurze Duration, hohe Density, Position modulieren",
          "Random Pitch höher, Feedback klein, Mix eher parallel (20–40%)",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Ribs – Drawn Granular Sampler/FX (Inear Display)
  --------------------------------------------------------------------
  ribs = {
    id      = "ribs",
    display = "Ribs (Inear Display)",
    match   = {"ribs %(inear display%)","inear ribs","ribs vsti","ribs fx"},
    vendor  = "Inear Display",
    type    = "granular_fm_fx",
    roles   = {"Granular","FM","Resynthesis","IDM","Glitch","Experimental","Free"},

    url     = "https://www.ineardisplay.com/plugins/ribs/",

    sections = {
      "BUFFER / CAPTURE",
      "GRAIN DRAWING (Envelopes/Shapes)",
      "PITCH / FM / SPEED",
      "FILTER / EQ",
      "OUTPUT / MIX",
    },

    key_params = {
      freeze          = "Freeze/Record – hält aktuellen Buffer fest",
      grain_env       = "Grain Envelope Shape – gezeichnete Hüllkurve",
      pitch_offset    = "Global Pitch Offset",
      fm_amount       = "FM Amount – interne Modulation",
      speed           = "Play Speed – Vorwärts/Rückwärts/Dehnung",
      filter_cutoff   = "Filter Cutoff",
      filter_res      = "Filter Resonance",
      spread          = "Stereo Spread",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      draw_idm = {
        description = "Per Hand gezeichnete Grain-Hüllkurven für lebendige IDM-Percussion",
        hints = {
          "Kurze Buffers von Drums aufnehmen, Freeze aktivieren",
          "Grain Envelopes per Hand zeichnen (unregelmäßig!)",
          "Pitch und Speed modulieren, Mix parallel fahren",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Convex – Dual-Filter + Modulation Multi-FX (Glitchmachines)
  --------------------------------------------------------------------
  convex = {
    id      = "convex",
    display = "Convex (Glitchmachines)",
    match   = {"convex %(glitchmachines%)","glitchmachines convex"},
    vendor  = "Glitchmachines",
    type    = "multi_fx_mod",
    roles   = {"Glitch","Filter","Delay","Modulation","IDM","Sounddesign"},

    url     = "https://glitchmachines.com/products/convex/",

    sections = {
      "DUAL FILTERS",
      "PITCHSHIFT / DELAY",
      "LFOs / ENVELOPES",
      "ROUTING / MIX",
    },

    key_params = {
      filter1_freq    = "Filter 1 Frequency",
      filter2_freq    = "Filter 2 Frequency",
      delay_time      = "Delay Time",
      delay_fb        = "Delay Feedback",
      pitch_shift     = "Pitch Shift Amount",
      lfo_rate        = "LFO Rate",
      lfo_depth       = "LFO Depth",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      morph_beats = {
        description = "Beats morphend zwischen zwei Filterzuständen",
        hints = {
          "Filter 1/2 unterschiedlich einstellen, LFO auf Morph/Balance",
          "Delay Feedback moderat, Mix parallel nutzen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Cryogen – Mod-Matrix Glitch Multi-FX (Glitchmachines)
  --------------------------------------------------------------------
  cryogen = {
    id      = "cryogen",
    display = "Cryogen (Glitchmachines)",
    match   = {"cryogen %(glitchmachines%)","glitchmachines cryogen"},
    vendor  = "Glitchmachines",
    type    = "multi_fx_mod_matrix",
    roles   = {"Glitch","Stutter","Delay","Bitcrush","IDM","Sounddesign"},

    url     = "https://glitchmachines.com/products/cryogen/",

    sections = {
      "DELAY / BITCRUSH / FILTER",
      "DUAL FEEDBACK PATHS",
      "MOD MATRIX (LFO, Step Seq, Env Follower)",
      "ROUTING / MIX",
    },

    key_params = {
      delay_time      = "Delay Time",
      delay_fb        = "Delay Feedback",
      crush_amount    = "Bitcrush/Reduction Amount",
      filter_cutoff   = "Filter Cutoff",
      lfo_rate        = "Mod LFO Rate",
      seq_rate        = "Step Sequencer Rate",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      stutter_fx = {
        description = "Stotternde, modulierte FX auf Drums / Loops",
        hints = {
          "Step Seq auf Delay Time/Feedback routen",
          "Crush Amount dezent bis mittel, Mix parallel halten",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Fracture – Buffer-Delay/Granular Lite (Glitchmachines)
  --------------------------------------------------------------------
  fracture = {
    id      = "fracture",
    display = "Fracture (Glitchmachines)",
    match   = {"fracture %(glitchmachines%)","glitchmachines fracture"},
    vendor  = "Glitchmachines",
    type    = "buffer_fx_glitch",
    roles   = {"Glitch","Buffer","Delay","IDM","Free"},

    url     = "https://glitchmachines.com/products/fracture/",

    sections = {
      "BUFFER / DELAY",
      "FILTER",
      "LFO / MOD",
      "MIX / OUTPUT",
    },

    key_params = {
      buffer_size     = "Buffer Size",
      delay_time      = "Delay Time",
      feedback        = "Feedback",
      filter_cutoff   = "Filter Cutoff",
      lfo_rate        = "LFO Rate",
      lfo_depth       = "LFO Depth",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      micro_glitch = {
        description = "Feine Micro-Glitches auf Percussion/Loops",
        hints = {
          "Kleine Buffer Size, Delay Time in ms-Bereich",
          "LFO dezent, Mix 10–30% für subtilen Effekt",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- FractureXT – erweiterte Version mit mehr Engines (Glitchmachines)
  --------------------------------------------------------------------
  fracture_xt = {
    id      = "fracture_xt",
    display = "FractureXT (Glitchmachines)",
    match   = {"fracturext","fracture xt","fracturext %(glitchmachines%)"},
    vendor  = "Glitchmachines",
    type    = "buffer_fx_multi",
    roles   = {"Glitch","Granular","Multi-FX","IDM","Sounddesign"},

    url     = "https://glitchmachines.com/products/fracture-xt/",

    sections = {
      "BUFFER ENGINES (mehrere)",
      "MULTI-DELAY / ECHO",
      "FILTER / DISTORTION",
      "MODULATION (LFO/Env/Random)",
      "ROUTING / MIX",
    },

    key_params = {
      engine_mix      = "Engine Mix – Balance der Buffer-Engines",
      delay_time      = "Delay Time (multi-tap)",
      distortion      = "Distortion Amount",
      filter_cutoff   = "Filter Cutoff",
      random_amount   = "Random Modulation Amount",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      total_deconstruct = {
        description = "Loops komplett auseinanderbrechen und neu zusammensetzen",
        hints = {
          "Mehrere Engines aktivieren, Random hochdrehen",
          "Distortion/Filter nach Geschmack, Mix zunächst parallel fahren",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- FogPad – Reverb / Granular Texture (igorski.nl)
  --------------------------------------------------------------------
  fogpad = {
    id      = "fogpad",
    display = "FogPad (igorski.nl)",
    match   = {"fogpad","fog pad"},
    vendor  = "igorski.nl",
    type    = "reverb_granular",
    roles   = {"Reverb","Ambient","Texture","IDM","Free"},

    url     = "https://www.igorski.nl/download/reverbs/fogpad",

    sections = {
      "PRE-FILTER",
      "REVERB CORE",
      "GRAIN / TEXTURE",
      "MODULATION",
      "MIX / OUTPUT",
    },

    key_params = {
      pre_lowcut      = "Pre Lowcut",
      pre_highcut     = "Pre Highcut",
      size            = "Reverb Size",
      decay           = "Decay Time",
      grain_amount    = "Grain / Texture Amount",
      mod_rate        = "Modulation Rate",
      mod_depth       = "Modulation Depth",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      pad_cloud = {
        description = "Pad-Sounds in dichte, modulierte Texturen verwandeln",
        hints = {
          "Size groß, Decay hoch, Grain Amount moderat",
          "Pre-Filter für Sound-Shaping nutzen, Mix 40–70%",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Filterstep – Step-Filter/Gate (Audiomodern)
  --------------------------------------------------------------------
  filterstep = {
    id      = "filterstep",
    display = "Filterstep (Audiomodern)",
    match   = {"filterstep","filterstep_64","audiomodern filterstep"},
    vendor  = "Audiomodern",
    type    = "step_filter",
    roles   = {"Filter","Gate","Rhythm","IDM","Free"},

    url     = "https://audiomodern.com/shop/plugins/filterstep/",

    sections = {
      "STEP SEQUENCER",
      "FILTER (Cutoff/Res)",
      "RANDOMIZE / PROBABILITY",
      "MIX / OUTPUT",
    },

    key_params = {
      step_values     = "Step Values – pro Step Cutoff/Level",
      cutoff_base     = "Base Filter Cutoff",
      res             = "Filter Resonance",
      random_amount   = "Randomization Amount",
      probability     = "Step Probability",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      rhythmic_filter = {
        description = "Stotternde, rhythmische Filterbewegungen auf Pads/Drums",
        hints = {
          "Steps im 16tel-Raster einzeichnen, Probability variieren",
          "Cutoff Base mittig, Res moderat, Mix 30–60%",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Filterjam – Multi-Band Resonant Filter (AudioThing)
  --------------------------------------------------------------------
  filterjam = {
    id      = "filterjam",
    display = "Filterjam (AudioThing)",
    match   = {"filterjam","audiothing filterjam"},
    vendor  = "AudioThing",
    type    = "filter_multiband",
    roles   = {"Filter","Color","Harmonics","IDM","Free"},

    url     = "https://www.audiothing.net/effects/filterjam/",

    sections = {
      "MODE (Band, High, Low, etc.)",
      "FREQUENCY",
      "RESONANCE",
      "MIX / OUTPUT",
    },

    key_params = {
      mode            = "Filter Mode",
      freq            = "Frequency",
      resonance       = "Resonance",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },

    sweetspots = {
      metallic_res = {
        description = "Metallische Resonanzen auf Drums/Percussion",
        hints = {
          "Resonance relativ hoch, Frequency auf Snare/Hat-Frequenzen suchen",
          "Mix parallel fahren, um Punch zu halten",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Filtron – Envelope Filter / Auto-Wah (Polyverse)
  --------------------------------------------------------------------
  filtron = {
    id      = "filtron",
    display = "Filtron (Polyverse)",
    match   = {"filtron %(polyverse%)","polyverse filtron","filtron"},
    vendor  = "Polyverse Music",
    type    = "envelope_filter",
    roles   = {"Filter","Auto-Wah","Movement","IDM"},

    url     = "https://polyversemusic.com/products/filtron/",

    sections = {
      "FILTER TYPE (LP/BP/HP)",
      "CUTOFF / RESONANCE",
      "ENVELOPE FOLLOWER",
      "LFO / MOD",
      "MIX / OUTPUT",
    },

    key_params = {
      filter_type     = "Filter Type",
      cutoff          = "Cutoff Frequency",
      resonance       = "Resonance",
      env_amount      = "Envelope Amount",
      lfo_rate        = "LFO Rate",
      lfo_depth       = "LFO Depth",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      funk_idm = {
        description = "Perkussive Auto-Wah-Bewegungen für Bass/Keys",
        hints = {
          "Env Amount hoch, LFO dezent mischen",
          "Mix 40–70%, je nach gewünschter Intensität",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- FeenstaubHDR – Saturation/Enhancer (Variety Of Sound)
  --------------------------------------------------------------------
  feenstaubhdr = {
    id      = "feenstaubhdr",
    display = "FeenstaubHDR (Variety Of Sound)",
    match   = {"feenstaubhdr","feenstaub hdr","variety of sound feenstaub"},
    vendor  = "Variety Of Sound",
    type    = "enhancer_saturation",
    roles   = {"Enhancer","Saturation","Exciter","Master","Bus","Free"},

    url     = "https://varietyofsound.wordpress.com/feenstaubhdr/",

    sections = {
      "INPUT / OUTPUT",
      "CHARACTER (Color Modes)",
      "HARMONICS / DETAIL",
      "STEREO WIDTH / FOCUS",
    },

    key_params = {
      input_gain      = "Input Level / Drive",
      detail_amount   = "Detail / Harmonics Amount",
      color_mode      = "Color / Character Mode",
      stereo_width    = "Stereo Width",
      output_gain     = "Output Level",
    },

    sweetspots = {
      air_bus = {
        description = "High-End-Air & Präsenz auf dem Mixbus",
        hints = {
          "Detail moderat, Color auf hellen Modus, Stereo Width dezent",
          "Output trimmen, um kein Lautheits-Bias zu erzeugen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- DC1A3 – Simple, but effective compressor (Klanghelm)
  --------------------------------------------------------------------
  dc1a3 = {
    id      = "dc1a3",
    display = "DC1A3 (Klanghelm)",
    match   = {"dc1a3","dc1a 3","dc1a %(klanghelm%)"},
    vendor  = "Klanghelm",
    type    = "compressor_simple",
    roles   = {"Compressor","Color","Bus","Track","Free"},

    url     = "https://klanghelm.com/contents/products/DC1A3/",

    sections = {
      "INPUT / OUTPUT",
      "COMP CORE (2-Knopf Konzept)",
      "MODE SWITCHES (Deep, Relaxed, Dual Mono, etc.)",
    },

    key_params = {
      input_gain      = "Input / Drive – steuert Kompressionsstärke",
      output_gain     = "Output / Makeup Gain",
      deep_mode       = "Deep – mehr Low-End Kontrolle",
      relaxed_mode    = "Relaxed – weichere Kennlinie",
      dual_mono       = "Dual Mono – L/R unabhängig",
    },

    sweetspots = {
      drum_crunch = {
        description = "Drums leicht andicken mit minimalem Setup",
        hints = {
          "Input anheben, bis 3–6 dB GR, Deep einschalten",
          "Relaxed aus für mehr Punch, in für weicher",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Deft Compressor – Full-Featured Comp (Voxengo)
  --------------------------------------------------------------------
  deft_compressor = {
    id      = "deft_compressor",
    display = "Deft Compressor (Voxengo)",
    match   = {"deft compressor","voxengo deft"},
    vendor  = "Voxengo",
    type    = "compressor_flexible",
    roles   = {"Compressor","Bus","Master","Track"},

    url     = "https://www.voxengo.com/product/deftcomp/",

    sections = {
      "THRESHOLD / RATIO / KNEE",
      "ATTACK / RELEASE",
      "AUTO MAKEUP / KNEE SHAPE",
      "SIDECHAIN FILTER",
      "OUTPUT / MIX",
    },

    key_params = {
      threshold      = "Threshold",
      ratio          = "Ratio",
      attack         = "Attack",
      release        = "Release",
      knee           = "Knee Shape",
      sc_hpf         = "Sidechain Highpass",
      mix            = "Dry/Wet Mix",
      output_gain    = "Output Gain",
    },

    sweetspots = {
      bus_control = {
        description = "Klassische Bus-Kompression mit flexibler Kontrolle",
        hints = {
          "Ratio 2:1, Attack mittel, Release musikalisch (Auto)",
          "Sidechain-HPF aktivieren, um Pumpen durch Kick zu verhindern",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Elephant – Mastering Limiter (Voxengo)
  --------------------------------------------------------------------
  elephant = {
    id      = "elephant",
    display = "Elephant (Voxengo)",
    match   = {"elephant %(voxengo%)","voxengo elephant","elephant"},
    vendor  = "Voxengo",
    type    = "limiter_master",
    roles   = {"Limiter","Mastering","Bus","Transparent"},

    url     = "https://www.voxengo.com/product/elephant/",

    sections = {
      "INPUT / OUTPUT",
      "LIMITING MODES (EL-1/2/3, etc.)",
      "THRESHOLD / OUT CEILING",
      "TIMING / SHAPE",
      "OVERSAMPLING",
    },

    key_params = {
      threshold      = "Threshold",
      out_ceiling    = "Output Ceiling",
      mode           = "Limiter Mode (EL-x)",
      timing         = "Timing/Transient-Handling",
      oversampling   = "Oversampling Factor",
    },

    sweetspots = {
      clean_loud = {
        description = "Laute, aber transparente Masters",
        hints = {
          "Mode auf transparenten Algorithmus stellen",
          "Oversampling aktivieren, Ceiling -1 dBFS",
          "GR im Schnitt bei 1–3 dB halten",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Free Clip 2 – Clip-Limiter (Venn Audio)
  --------------------------------------------------------------------
  free_clip2 = {
    id      = "free_clip2",
    display = "Free Clip 2 (Venn Audio)",
    match   = {"free clip 2","free clip2","free clip %(venn audio%)"},
    vendor  = "Venn Audio",
    type    = "clipper",
    roles   = {"Clipper","Limiter","Bus","Master","Free"},

    url     = "https://vennaudio.com/free-clip/",

    sections = {
      "CLIP SHAPE (Hard, Soft, etc.)",
      "THRESHOLD",
      "OUTPUT GAIN",
      "MIX",
    },

    key_params = {
      shape           = "Clip Shape",
      threshold       = "Clip Threshold",
      output_gain     = "Output Gain",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      transient_tame = {
        description = "Transiente Spitzen vor dem Limiter abfangen",
        hints = {
          "Threshold knapp unter 0 dBFS, Shape eher soft",
          "Nur 1–3 dB Clip, danach in Limiter fahren",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Free Comp – basic compressor (Venn Audio)
  --------------------------------------------------------------------
  free_comp = {
    id      = "free_comp",
    display = "Free Comp (Venn Audio)",
    match   = {"free comp","freecomp %(venn%)"},
    vendor  = "Venn Audio",
    type    = "compressor_basic",
    roles   = {"Compressor","Utility","Track","Free"},

    url     = "https://vennaudio.com/free-comp/",

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "OUTPUT / MIX",
    },

    key_params = {
      threshold       = "Threshold",
      ratio           = "Ratio",
      attack          = "Attack",
      release         = "Release",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },

    sweetspots = {
      utility_comp = {
        description = "Schneller Utility-Kompressor für einfache Dynamik-Kontrolle",
        hints = {
          "Moderate Ratio, Attack nicht zu kurz",
          "Mix als Parallel-Kompression nutzen, falls nötig",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Free EQ – parametric EQ (Venn Audio)
  --------------------------------------------------------------------
  free_eq = {
    id      = "free_eq",
    display = "Free EQ (Venn Audio)",
    match   = {"free eq","freeeq %(venn%)"},
    vendor  = "Venn Audio",
    type    = "eq_parametric",
    roles   = {"EQ","Utility","Track","Bus","Free"},

    url     = "https://vennaudio.com/free-eq/",

    sections = {
      "BANDS (Shelves/Peaks)",
      "INPUT / OUTPUT",
    },

    key_params = {
      band_freqs      = "Band Frequencies",
      band_gain       = "Band Gain",
      band_q          = "Band Q",
      output_gain     = "Output Gain",
    },

    sweetspots = {
      quick_fix = {
        description = "Schnelle Korrektur von Problemfrequenzen",
        hints = {
          "Schmale Qs für Resonanzen, breite für Tonalität",
          "Output immer auf Lautheit prüfen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Free Convolve – Faltungshall (Venn Audio)
  --------------------------------------------------------------------
  free_convolve = {
    id      = "free_convolve",
    display = "Free Convolve (Venn Audio)",
    match   = {"free convolve","freeconvolve %(venn%)"},
    vendor  = "Venn Audio",
    type    = "reverb_convolution",
    roles   = {"Reverb","IR","Space","Creative","Free"},

    url     = "https://vennaudio.com/free-convolver/",

    sections = {
      "IMPULSE LOADER",
      "TIME / LENGTH",
      "TONE / FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      ir_file         = "Impulse Response File",
      length          = "Length / Trim",
      pre_delay       = "Pre-Delay",
      lowcut          = "Lowcut",
      highcut         = "Highcut",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      texture_ir = {
        description = "Nicht nur Räume: Textur-IRs für Sounddesign nutzen",
        hints = {
          "IRs von Geräuschen, Foley, Gerätschaften laden",
          "Length kürzen und Pre-Delay nutzen, Mix als Parallel-FX",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Free Delay – Delay (Venn Audio)
  --------------------------------------------------------------------
  free_delay = {
    id      = "free_delay",
    display = "Free Delay (Venn Audio)",
    match   = {"free delay","freedelay %(venn%)"},
    vendor  = "Venn Audio",
    type    = "delay_basic",
    roles   = {"Delay","Utility","Creative","Free"},

    url     = "https://vennaudio.com/free-delay/",

    sections = {
      "TIME / SYNC",
      "FEEDBACK",
      "FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      time            = "Delay Time (ms oder sync)",
      feedback        = "Feedback Amount",
      lowcut          = "Lowcut im Feedbackweg",
      highcut         = "Highcut im Feedbackweg",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      tempo_echo = {
        description = "Klassische tempo-synced Delays als Bread-and-Butter-FX",
        hints = {
          "Auf 1/4 oder 1/8 syncen, Feedback moderat",
          "Highcut, um Platz für Vocals/Leads zu lassen",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- FREE87 FR-COMP – Channel Compressor (eaReckon)
  --------------------------------------------------------------------
  free87_fr_comp = {
    id      = "free87_fr_comp",
    display = "FREE87 FR-COMP (eaReckon)",
    match   = {"free87 fr%-comp","fr%-comp %(eareckon%)","free87 compressor"},
    vendor  = "eaReckon",
    type    = "compressor_channel",
    roles   = {"Compressor","Channel","Track","Free"},

    url     = "https://eareckon.com/en/products/free87-series.html",

    sections = {
      "THRESHOLD / RATIO",
      "ATTACK / RELEASE",
      "MAKEUP GAIN",
      "METERING",
    },

    key_params = {
      threshold       = "Threshold",
      ratio           = "Ratio",
      attack          = "Attack",
      release         = "Release",
      makeup_gain     = "Makeup Gain",
    },

    sweetspots = {
      general_track = {
        description = "Allround-Channel-Kompressor für viele Quellen",
        hints = {
          "Moderate Ratios, Attack nicht zu schnell für Drums",
          "Makup Gain vorsichtig dosieren",
        },
      },
    },
  },

--------------------------------------------------------------------
  -- AnarchyRhythms – Hybrid aus Effekt & Drummachine
  --------------------------------------------------------------------
  anarchyrhythms = {
    id      = "anarchyrhythms",
    display = "AnarchyRhythms (AnarchySoundSoftware)",
    match   = {"anarchyrhythms","anarchy rhythms"},
    vendor  = "Anarchy Sound Software",
    type    = "fx_rhythmic_matrix",
    roles   = {"Filter","Modulation","Looper","Slicer","Glitch","IDM","Free"},

    url     = "https://anarchysoundsoftware.co.uk/anarchyrhythms",

    sections = {
      "MATRIX (Amplitude/Filter/Feedback)",
      "FILTER BANK (Bandpass pro Zeile)",
      "OSCILLATORS / FEEDBACK LOOPS",
      "COMPRESSOR",
      "PATTERN / STEPS",
      "GLOBAL (Tempo Sync, Mix)",
    },

    key_params = {
      matrix_cells    = "Matrix Cells – bestimmen für jede Zeit/Frequenz den Effekt (AM, Filter, Feedback, etc.)",
      band_freqs      = "Bandpass-Frequenzen je Zeile",
      feedback_amount = "Feedback-Matrix-Level",
      osc_level       = "Internal Osc Level – Eigenoszillator-Anteil",
      comp_amount     = "Compressor Amount auf das intern bearbeitete Signal",
      tempo_sync      = "Tempo Sync / Grid für die Matrix",
      mix             = "Global Dry/Wet Mix",
    },

    sweetspots = {
      idm_pattern = {
        description = "Eingehende Loops zu neuen, matrixten IDM-Rhythmen verbiegen",
        hints = {
          "Bandpass-Bänder auf Drumbus fokussieren (Kick/Snare/Hats)",
          "In der Matrix Endlos-Patterns aus AM + Feedback basteln",
          "Mix zunächst auf 20–40% parallel fahren",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Anarchy Effects Bundle – Convoluter, Corkscrew, HarmonicAdder,
  -- LengthSeparator, SpectralAutopan (alles Frequency-Domain-Experimente)
  --------------------------------------------------------------------

  convoluter = {
    id      = "convoluter_anarchy",
    display = "Convoluter v1.5 (AnarchySoundSoftware)",
    match   = {"convoluter v1.5 %(anarchysoundsoftware%)","convoluter %(anarchy sound%)"},
    vendor  = "Anarchy Sound Software",
    type    = "spectral_convolution",
    roles   = {"Glitch","Spectral","FSU","Texture","Free"},

    url     = "http://anarchysoundsoftware.co.uk",

    sections = {
      "SPECTRAL MATRIX",
      "CONVOLUTION / MORPH",
      "INPUT / OUTPUT",
    },

    key_params = {
      conv_amount     = "Convolution Amount – wie stark das Spektrum verbogen wird",
      bias_sine_noise = "Bias zwischen reinen Sinusanteilen und Rauschanteilen",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      sine_noise_morph = {
        description = "Material zwischen klaren Tönen und Noise morphen",
        hints = {
          "Bias in der Mitte lassen, Convolution moderat",
          "Parallel einsetzen für kontrollierte Zerstörung",
        },
      },
    },
  },

  corkscrew = {
    id      = "corkscrew_anarchy",
    display = "Corkscrew v1.5 (AnarchySoundSoftware)",
    match   = {"corkscrew v1.5 %(anarchysoundsoftware%)","corkscrew %(anarchy sound%)"},
    vendor  = "Anarchy Sound Software",
    type    = "pitch_shepard",
    roles   = {"Pitch","Time","Shepard","FX","Glitch","Free"},

    url     = "http://anarchysoundsoftware.co.uk",

    sections = {
      "PITCH SPIRAL",
      "RANGE / SPEED",
      "MIX",
    },

    key_params = {
      spiral_speed    = "Spiral Speed – Geschwindigkeit des scheinbar endlosen Steigens/Fallens",
      range_up        = "Pitch Range Up",
      range_down      = "Pitch Range Down",
      voices          = "Anzahl der gleichzeitig aktiven Shifts",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      shepard_rise = {
        description = "Endlos steigende oder fallende Texturen (Shepard-Riser)",
        hints = {
          "Spiral Speed an Songtempo anpassen",
          "Range begrenzen, Mix parallel nutzen",
        },
      },
    },
  },

  harmonicadder = {
    id      = "harmonicadder_anarchy",
    display = "HarmonicAdder v1.5 (AnarchySoundSoftware)",
    match   = {"harmonicadder v1.5 %(anarchysoundsoftware%)","harmonicadder %(anarchy sound%)"},
    vendor  = "Anarchy Sound Software",
    type    = "pitchshift_time",
    roles   = {"Pitch","Time-Stretch","Harmonics","FSU","Free"},

    url     = "http://anarchysoundsoftware.co.uk",

    sections = {
      "PITCH / TIME CORE",
      "HARMONIC BLEND",
      "OUTPUT / MIX",
    },

    key_params = {
      pitch_shift     = "Pitch Shift Amount",
      stretch_ratio   = "Time Stretch Ratio",
      harmonic_blend  = "Blend zusätzlicher harmonischer Komponenten",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      shimmerish = {
        description = "Tonales Material andicken, ohne nur zu doublen",
        hints = {
          "Pitch leicht nach oben, Harmonic Blend moderat",
          "Mix 20–40% als Exciter-ähnlicher Effekt",
        },
      },
    },
  },

  lengthseparator = {
    id      = "lengthseparator_anarchy",
    display = "LengthSeparator v1.5 (AnarchySoundSoftware)",
    match   = {"lengthseparator v1.5 %(anarchysoundsoftware%)","length separator %(anarchy sound%)"},
    vendor  = "Anarchy Sound Software",
    type    = "spectral_gate",
    roles   = {"Gate","Spectral","FSU","Free"},

    url     = "http://anarchysoundsoftware.co.uk",

    sections = {
      "SPECTRAL GATE",
      "LENGTH THRESHOLDS",
      "MIX",
    },

    key_params = {
      min_length      = "Minimum Event Length – kürzere Ereignisse werden ausgeblendet",
      max_length      = "Maximum Event Length – längere Events werden reduziert",
      smooth          = "Smoothing / Übergang zwischen gehalten/verworfen",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      percussive_focus = {
        description = "Lang anhaltende Inhalte aus perkussiven Loops entfernen",
        hints = {
          "Max Length relativ klein setzen, Min Length auf sehr kurze Transienten",
          "Mix parallel, um Vitalität zu behalten",
        },
      },
    },
  },

  spectralautopan = {
    id      = "spectralautopan_anarchy",
    display = "SpectralAutopan v1.5 (AnarchySoundSoftware)",
    match   = {"spectralautopan v1.5 %(anarchysoundsoftware%)","spectral autopan %(anarchy sound%)"},
    vendor  = "Anarchy Sound Software",
    type    = "spectral_panner",
    roles   = {"Imaging","Autopan","Spectral","Motion","Free"},

    url     = "http://anarchysoundsoftware.co.uk",

    sections = {
      "FREQUENCY-PAN CONTROL POINTS",
      "LFOs / MOTION",
      "GLOBAL MIX",
    },

    key_params = {
      control_points  = "Bis zu 5 Control Points – je Punkt Frequenz + Pan-Position",
      lfo_rate        = "LFO Rate – Bewegung der Control Points",
      lfo_depth       = "LFO Depth – Auslenkung der Punkte",
      mix             = "Dry/Wet Mix",
    },

    sweetspots = {
      spectral_widen = {
        description = "Breite, sich bewegende Stereoabbildung ohne Mono völlig zu zerstören",
        hints = {
          "Control Points auf verschiedene Frequenzbänder legen",
          "LFO sehr langsam, Mix 20–40%",
        },
      },
    },
  },

  --------------------------------------------------------------------
  -- Audec adc-Serie
  --------------------------------------------------------------------

  adc_clap = {
    id      = "adc_clap",
    display = "adc Clap (Audec)",
    match   = {"adc clap","adc_clap"},
    vendor  = "Audec",
    type    = "drum_clap",
    roles   = {"Drum","Clap","Layer","IDM"},

    url     = "https://audec-music.com",

    sections = {
      "SOURCE / SAMPLE",
      "TRANSIENT / DECAY",
      "TONE / FILTER",
      "MIX / OUTPUT",
    },

    key_params = {
      attack_shape    = "Attack Shape / Snap des Clap",
      decay           = "Decay / Tail Länge",
      tone            = "Tone / Filter – Helligkeit des Clap",
      width           = "Stereo Width für Clap-Layer",
      mix             = "Dry/Wet (falls als Insert genutzt)",
    },
  },

  adc_crush2 = {
    id      = "adc_crush2",
    display = "adc Crush 2 (Audec)",
    match   = {"adc crush 2","crush 2 %(audec%)"},
    vendor  = "Audec",
    type    = "bitcrush_distortion",
    roles   = {"Bitcrush","Distortion","LoFi","IDM"},

    url     = "https://audec-music.com",

    sections = {
      "BIT DEPTH / RESOLUTION",
      "SAMPLE RATE",
      "FILTER / TONE",
      "MIX / OUTPUT",
    },

    key_params = {
      bit_depth       = "Bit Depth Reduktion",
      sample_rate     = "Sample Rate / Downsampling",
      tone            = "Tone / Filter",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },
  },

  adc_extra_pan = {
    id      = "adc_extra_pan",
    display = "adc Extra Pan (Audec)",
    match   = {"adc extra pan","extra pan %(audec%)"},
    vendor  = "Audec",
    type    = "panner_stereo",
    roles   = {"Panning","Stereo","Imaging","Utility"},

    url     = "https://audec-music.com",

    sections = {
      "PAN / BALANCE",
      "WIDTH / MID-SIDE",
      "MODULATION (falls vorhanden)",
      "OUTPUT",
    },

    key_params = {
      pan             = "Panorama",
      width           = "Stereo Width / Mid-Side Balance",
      auto_pan_rate   = "Auto-Pan Rate (falls Mod vorhanden)",
      mix             = "Wet Level (bei Insert)",
    },
  },

  adc_haas2 = {
    id      = "adc_haas2",
    display = "adc Haas 2 (Audec)",
    match   = {"adc haas 2","haas 2 %(audec%)"},
    vendor  = "Audec",
    type    = "haas_stereo",
    roles   = {"Stereo","Haas","Delay","Imaging"},

    url     = "https://audec-music.com",

    sections = {
      "DELAY LEFT/RIGHT",
      "BALANCE / WIDTH",
      "FILTER (optional)",
      "MIX",
    },

    key_params = {
      haas_ms         = "Haas Delay (ms) – Laufzeitunterschied",
      balance         = "Left/Right Balance",
      highcut         = "Highcut im Wet-Signal (falls angeboten)",
      mix             = "Dry/Wet Mix",
    },
  },

  adc_mono = {
    id      = "adc_mono",
    display = "adc Mono (Audec)",
    match   = {"adc mono","mono %(audec%)"},
    vendor  = "Audec",
    type    = "utility_mono",
    roles   = {"Utility","Mono","Imaging","Gain"},

    url     = "https://audec-music.com",

    sections = {
      "MONO SUM",
      "PAN / BALANCE",
      "OUTPUT",
    },

    key_params = {
      mono_mode       = "Mono Mode (Full / Low-only / High-only, falls vorhanden)",
      output_gain     = "Output Gain",
    },
  },

  adc_ring2 = {
    id      = "adc_ring2",
    display = "adc Ring 2 (Audec)",
    match   = {"adc ring 2","ring 2 %(audec%)"},
    vendor  = "Audec",
    type    = "ring_mod",
    roles   = {"Ringmod","AM","FX","IDM"},

    url     = "https://audec-music.com",

    sections = {
      "CARRIER (Freq/Shape)",
      "MIX (Ring vs Dry)",
      "OUTPUT",
    },

    key_params = {
      carrier_freq    = "Carrier Frequency",
      depth           = "Modulation Depth",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },
  },

  adc_shape_lite2 = {
    id      = "adc_shape_lite2",
    display = "adc Shape Lite 2 (Audec)",
    match   = {"adc shape lite 2","shape lite 2 %(audec%)"},
    vendor  = "Audec",
    type    = "waveshaper_lite",
    roles   = {"Saturation","Waveshaper","Clip","Free"},

    url     = "https://audec-music.com",

    sections = {
      "SHAPER CURVE",
      "INPUT / OUTPUT",
      "MIX",
    },

    key_params = {
      drive           = "Drive / Input",
      curve           = "Shape Curve Type",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },
  },

  adc_spread_delay_lite = {
    id      = "adc_spread_delay_lite",
    display = "adc Spread Delay Lite (Audec)",
    match   = {"adc spread delay lite","spread delay lite %(audec%)"},
    vendor  = "Audec",
    type    = "delay_stereo_spread",
    roles   = {"Delay","Stereo","Spread","IDM"},

    url     = "https://audec-music.com",

    sections = {
      "TIME L/R",
      "FEEDBACK",
      "FILTER",
      "SPREAD / WIDTH",
      "MIX",
    },

    key_params = {
      time_left       = "Delay Time Left",
      time_right      = "Delay Time Right",
      feedback        = "Feedback",
      spread          = "Stereo Spread",
      mix             = "Dry/Wet Mix",
    },
  },

  adc_spread_delay = {
    id      = "adc_spread_delay",
    display = "adc Spread Delay (Audec)",
    match   = {"adc spread delay ","adc spread delay(", "spread delay %(audec%)"},
    vendor  = "Audec",
    type    = "delay_stereo_spread_full",
    roles   = {"Delay","Stereo","Spread","IDM"},

    url     = "https://audec-music.com",

    sections = {
      "TIME L/R (erweitert)",
      "FEEDBACK",
      "FILTER (HP/LP)",
      "SPREAD / WIDTH",
      "MIX / OUTPUT",
    },

    key_params = {
      time_left       = "Delay Time Left",
      time_right      = "Delay Time Right",
      feedback        = "Feedback",
      hp_filter       = "Highpass im Feedbackweg",
      lp_filter       = "Lowpass im Feedbackweg",
      spread          = "Stereo Spread",
      mix             = "Dry/Wet Mix",
    },
  },

  adc_transient_lite = {
    id      = "adc_transient_lite",
    display = "adc Transient Lite (Audec)",
    match   = {"adc transient lite","transient lite %(audec%)"},
    vendor  = "Audec",
    type    = "transient_shaper_lite",
    roles   = {"Transient","Dynamics","Drums","Free"},

    url     = "https://audec-music.com",

    sections = {
      "ATTACK",
      "SUSTAIN",
      "GLOBAL OUTPUT",
    },

    key_params = {
      attack          = "Attack Boost/Reduce",
      sustain         = "Sustain Boost/Reduce",
      output_gain     = "Output Gain",
    },
  },

  adc_transient = {
    id      = "adc_transient",
    display = "adc Transient (Audec)",
    match   = {"adc transient","adc transient shaper"},
    vendor  = "Audec",
    type    = "transient_shaper",
    roles   = {"Transient","Dynamics","Drums","Bus","Free"},

    url     = "https://audec-music.com/transient/",

    sections = {
      "ATTACK",
      "SUSTAIN",
      "STYLE / CURVE",
      "MIX / OUTPUT",
    },

    key_params = {
      attack          = "Attack – Transienten verstärken oder abschwächen",
      sustain         = "Sustain – Ausklang verlängern oder verkürzen",
      style_mode      = "Different Style/Curve Modes (Soft/Hard etc.)",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },
  },

  adc_vectorscope2 = {
    id      = "adc_vectorscope2",
    display = "adc Vectorscope 2 (Audec)",
    match   = {"adc vectorscope 2","vectorscope 2 %(audec%)"},
    vendor  = "Audec",
    type    = "meter_vectorscope",
    roles   = {"Meter","Stereo","Phase","Utility","Free"},

    url     = "https://audec-music.com/adc-vectorscope/",

    sections = {
      "VECTOR DISPLAY",
      "CORRELATION METER",
      "ZOOM / SCALE",
      "INPUT CONFIG",
    },

    key_params = {
      display_mode    = "Display Mode (Lissajous, Polar, etc.)",
      zoom            = "Zoom / Scale",
      hold_time       = "Peak Hold/Trail Time",
    },
  },

  --------------------------------------------------------------------
  -- ADSR Sample Manager – Sample-Browser/Organisation
  --------------------------------------------------------------------
  adsr_sample_manager = {
    id      = "adsr_sample_manager",
    display = "ADSR Sample Manager (ADSR)",
    match   = {"adsr sample manager"},
    vendor  = "ADSR",
    type    = "sample_manager",
    roles   = {"Browser","Sample Manager","Tagging","Utility","Free"},

    url     = "https://www.adsrsounds.com/product/software/adsr-sample-manager/",

    sections = {
      "LIBRARY SCAN",
      "TAGGING (Smart + Custom Tags)",
      "SEARCH / FILTER",
      "PLAYBACK (MIDI-Trigger, Sync, Key-Match)",
      "DRAG & DROP INTO DAW",
    },

    key_params = {
      library_paths   = "Library Paths – Ordner, die gescannt werden",
      bpm_sync        = "Sync to Host BPM",
      key_match       = "Key Detection / Tuning",
      tag_filters     = "Tag Filter / Smart Tags",
    },
  },

  --------------------------------------------------------------------
  -- Couture – Transient Shaper + Saturation (Auburn Sounds)
  --------------------------------------------------------------------
  couture = {
    id      = "couture",
    display = "Couture (Auburn Sounds)",
    match   = {"couture %(auburn sounds%)","auburn couture","couture free"},
    vendor  = "Auburn Sounds",
    type    = "transient_shaper_plus_sat",
    roles   = {"Transient","Saturation","Drums","Bus","Master","Free/Freemium"},

    url     = "https://www.auburnsounds.com/products/Couture.html",

    sections = {
      "TRANSIENT SECTION (Attack/Sustain)",
      "DETECTOR (2-Band / RMS / Program-Dependent)",
      "SATURATION (Vollversion)",
      "OUTPUT / MIX",
    },

    key_params = {
      attack          = "Attack – Attack-Transienten verstärken oder abschwächen",
      sustain         = "Sustain – Ausklingverhalten formen",
      sharpness       = "Detector Sharpness / Reaktionskurve",
      saturation      = "Saturation Drive (nur Vollversion)",
      mix             = "Dry/Wet Mix",
      output_gain     = "Output Gain",
    },

    sweetspots = {
      drum_punch = {
        description = "Sehr präziser Punch auf Kicks/Snares ohne Lautheitstricks",
        hints = {
          "Attack deutlich hoch, Sustain leicht runter",
          "Auf Pegel und evtl. nachfolgende Kompression achten",
        },
      },
      transient_taming = {
        description = "Zu harte Transienten glätten (z.B. HiHats/Vocals)",
        hints = {
          "Attack zurücknehmen (negativ), Sustain leicht erhöhen",
          "Mix nicht auf 100% stellen, sonst wird alles zu flach",
        },
      },
    },
  },
MetaCore.vsti = -- legacy require removed (see V2 loader below)




--------------------------------------------------------------------
-- DF95 MetaCore v15 - Optimizations & Helper APIs (modular build)
-- Added by Reaper DAW Ultimate Assistant (ChatGPT)
--
-- A: Indizes / Sichten:
--    - MetaCore._build_indices()
--    - MetaCore.all       : Liste aller Plugin-Definitionen
--    - MetaCore.by_type   : type    -> { defs... }
--    - MetaCore.by_vendor : vendor  -> { defs... }
--    - MetaCore.by_role   : role    -> { defs... }
--
-- B: Smart Sections:
--    - MetaCore.section_presets
--    - MetaCore.get_sections(def)
--
-- C: Inspire-Mode:
--    - MetaCore.inspire(context)
--
-- D: Auto-Chain:
--    - MetaCore.build_chain(context)
--
-- E: Profiling:
--    - MetaCore._last_build_time
--
-- F: Version-Tag:
--    - MetaCore.version = "2.1-meta-v15-modular"
--------------------------------------------------------------------

MetaCore.version = "2.1-meta-v15-modular"

--------------------------------------------------------------------
-- Internal: iterate all plugin defs from vst + vsti
--------------------------------------------------------------------
local function _iter_all_defs()
  local list = {}

  if MetaCore.vst and type(MetaCore.vst)=="table" then
    for id, def in pairs(MetaCore.vst) do
      if type(def)=="table" and def.id and def.type then
        list[#list+1] = def
      end
    end
  end

  if MetaCore.vsti and type(MetaCore.vsti)=="table" then
    for id, def in pairs(MetaCore.vsti) do
      if type(def)=="table" and def.id and def.type then
        list[#list+1] = def
      end
    end
  end

  return list
end

--------------------------------------------------------------------
-- Internal: build indices once
--------------------------------------------------------------------
function MetaCore._build_indices()
  if MetaCore._indices_built then return end

  local all       = {}
  local by_type   = {}
  local by_vendor = {}
  local by_role   = {}

  local t0 = os.clock and os.clock() or nil

  for _, def in ipairs(_iter_all_defs()) do
    all[#all+1] = def

    local t = def.type
    if t then
      by_type[t] = by_type[t] or {}
      by_type[t][#by_type[t]+1] = def
    end

    if def.vendor then
      by_vendor[def.vendor] = by_vendor[def.vendor] or {}
      by_vendor[def.vendor][#by_vendor[def.vendor]+1] = def
    end

    if def.roles and type(def.roles) == "table" then
      for _, r in ipairs(def.roles) do
        by_role[r] = by_role[r] or {}
        by_role[r][#by_role[r]+1] = def
      end
    end
  end

  MetaCore.all       = all
  MetaCore.by_type   = by_type
  MetaCore.by_vendor = by_vendor
  MetaCore.by_role   = by_role
  MetaCore._indices_built = true

  if t0 then
    MetaCore._last_build_time = os.clock() - t0
  end
end

local function ensure_indices()
  if not MetaCore._indices_built then
    MetaCore._build_indices()
  end
end

--------------------------------------------------------------------
-- Smart Sections: Presets per type (used as Fallback)
--------------------------------------------------------------------
MetaCore.section_presets = {
  eq = {
    "INPUT",
    "BANDS / FILTERS",
    "SPECIAL / DYNAMIC",
    "OUTPUT",
  },
  dynamic_eq = {
    "INPUT",
    "BANDS / FILTERS",
    "DYNAMIC / RANGE",
    "OUTPUT",
  },
  compressor = {
    "INPUT",
    "THRESHOLD / RATIO",
    "ATTACK / RELEASE",
    "MIX / OUTPUT",
  },
  multiband_comp = {
    "INPUT",
    "BANDS / X-OVER",
    "COMP / SHAPE",
    "MIX / OUTPUT",
  },
  limiter = {
    "INPUT",
    "THRESHOLD / CEILING",
    "TIMING",
    "OUTPUT",
  },
  gate = {
    "THRESHOLD",
    "ATTACK / RELEASE",
    "RANGE / HOLD",
    "OUTPUT",
  },
  saturation = {
    "INPUT / DRIVE",
    "TONE / COLOR",
    "MODE / CHARACTER",
    "MIX / OUTPUT",
  },
  tape = {
    "INPUT / DRIVE",
    "TONE / HF ROLLOFF",
    "GLUE / DYNAMICS",
    "MIX / OUTPUT",
  },
  reverb = {
    "PRE-DELAY / TIME",
    "SIZE / SHAPE",
    "TONE / DIFFUSION",
    "MIX / OUTPUT",
  },
  delay = {
    "TIME / SYNC",
    "FEEDBACK",
    "FILTER / TONE",
    "MOD / WIDTH",
    "MIX / OUTPUT",
  },
  modulation = {
    "RATE / SPEED",
    "DEPTH / AMOUNT",
    "TONE / WIDTH",
    "MIX / OUTPUT",
  },
  ["lofi"] = {
    "INPUT / DRIVE",
    "DEGRADE / NOISE",
    "FILTER / TONE",
    "MIX / OUTPUT",
  },
  analyzer = {
    "DISPLAY",
    "RANGE / SCALE",
    "FOCUS / MODE",
    "EXTRA",
  },
  meter = {
    "DISPLAY",
    "RANGE / SCALE",
    "TARGET / MODE",
    "EXTRA",
  },
  stereo_imager = {
    "INPUT",
    "WIDTH / SPREAD",
    "MID / SIDE",
    "OUTPUT",
  },
  synth = {
    "OSCILLATORS",
    "FILTER",
    "ENVELOPES",
    "MODULATION",
    "FX / OUTPUT",
  },
  vocoder = {
    "CARRIER",
    "MODULATOR",
    "FILTERBANK",
    "MIX / OUTPUT",
  },
  network = {
    "ROUTING",
    "SYNC / LATENCY",
    "MONITORING",
  },
  hardware_insert = {
    "ROUTING",
    "LATENCY",
    "MONITORING",
  },
  surround_panner = {
    "ROUTING",
    "SPATIAL / POSITION",
    "MONITORING",
  },
  default = {
    "MAIN CONTROLS",
    "EXTRA",
    "OUTPUT",
  },
}

--- Get sections for a plugin definition, falling back to presets
function MetaCore.get_sections(def)
  if def.sections and type(def.sections) == "table" and #def.sections > 0 then
    return def.sections
  end
  if def.type and MetaCore.section_presets[def.type] then
    return MetaCore.section_presets[def.type]
  end
  return MetaCore.section_presets.default
end

--------------------------------------------------------------------
-- Scoring-Search (Multi-Level Matching)
--------------------------------------------------------------------
local function lc(s)
  return (s and string.lower(tostring(s))) or ""
end

local function score_plugin(def, query, want_type, want_roles)
  local name  = lc(def.display or def.id)
  local vend  = lc(def.vendor)
  local q     = lc(query or "")
  if q == "" and not want_type and (not want_roles or #want_roles == 0) then
    return 1
  end

  local score = 0

  if q ~= "" then
    if string.find(name, q, 1, true) then
      score = score + 10
    end
    if def.match and type(def.match)=="table" then
      for _, m in ipairs(def.match) do
        if string.find(lc(m), q, 1, true) then
          score = score + 6
          break
        end
      end
    end
    if string.find(vend, q, 1, true) then
      score = score + 3
    end
  end

  if want_type and def.type == want_type then
    score = score + 4
  end

  if want_roles and def.roles then
    for _, wr in ipairs(want_roles) do
      local wrl = lc(wr)
      for _, r in ipairs(def.roles) do
        if lc(r) == wrl then
          score = score + 2
          break
        end
      end
    end
  end

  return score
end

--- General search API:
--    results = MetaCore.search{ query="tape", type="tape", roles={"Mastering"} }
function MetaCore.search(opts)
  ensure_indices()
  opts = opts or {}
  local q         = opts.query or ""
  local want_type = opts.type
  local want_roles= opts.roles

  local results = {}
  for _, def in ipairs(MetaCore.all or {}) do
    local sc = score_plugin(def, q, want_type, want_roles)
    if sc > 0 then
      results[#results+1] = { def = def, score = sc }
    end
  end

  table.sort(results, function(a,b) return a.score > b.score end)
  return results
end

--------------------------------------------------------------------
-- Inspire Mode: Vorschläge generieren
--------------------------------------------------------------------
-- context kann enthalten:
--   source      = "vocals" | "drums" | "bass" | "mixbus" | "master" | ...
--   goal        = "clean" | "color" | "loud" | "space" | "movement" | ...
--   limit_type  = optionaler type-Filter (z.B. "compressor")
--   max_results = Anzahl Vorschläge (default 5)
function MetaCore.inspire(context)
  ensure_indices()
  context = context or {}
  local src   = lc(context.source or "")
  local goal  = lc(context.goal or "")
  local t_lim = context.limit_type
  local max_n = context.max_results or 5

  local wanted_roles = {}

  if src == "vocals" then
    table.insert(wanted_roles,"Vocal")
    table.insert(wanted_roles,"DeEss")
    table.insert(wanted_roles,"Pitch")
  elseif src == "drums" then
    table.insert(wanted_roles,"Drums")
    table.insert(wanted_roles,"Transient")
    table.insert(wanted_roles,"Punch")
  elseif src == "bass" then
    table.insert(wanted_roles,"Bass")
    table.insert(wanted_roles,"LowEnd")
  elseif src == "mixbus" or src == "bus" then
    table.insert(wanted_roles,"Bus")
    table.insert(wanted_roles,"Glue")
  elseif src == "master" then
    table.insert(wanted_roles,"Mastering")
  end

  if goal == "clean" then
    table.insert(wanted_roles,"Utility")
  elseif goal == "color" then
    table.insert(wanted_roles,"Color")
    table.insert(wanted_roles,"Saturation")
  elseif goal == "loud" then
    table.insert(wanted_roles,"Limiter")
    table.insert(wanted_roles,"Loud")
  elseif goal == "space" then
    table.insert(wanted_roles,"Space")
    table.insert(wanted_roles,"Reverb")
  elseif goal == "movement" then
    table.insert(wanted_roles,"Modulation")
    table.insert(wanted_roles,"Rhythmic")
  end

  local candidates = {}
  for _, def in ipairs(MetaCore.all or {}) do
    if (not t_lim) or def.type == t_lim then
      local sc = score_plugin(def, context.query or "", t_lim, wanted_roles)
      if sc > 0 then
        if src == "vocals" and def.roles then
          for _, r in ipairs(def.roles) do
            local rl = lc(r)
            if rl == "deess" or rl == "vocal" then
              sc = sc + 3
            end
          end
        end
        candidates[#candidates+1] = { def = def, score = sc }
      end
    end
  end

  table.sort(candidates, function(a,b) return a.score > b.score end)

  local out = {}
  for i = 1, math.min(max_n, #candidates) do
    out[#out+1] = candidates[i].def
  end
  return out
end

--------------------------------------------------------------------
-- Auto-Chain: simple Chain-Vorschläge bauen
--------------------------------------------------------------------
-- context:
--   source  = "vocals" | "drums" | "bass" | "mixbus" | "master"
--   flavor  = "clean" | "color" | "aggressive"
function MetaCore.build_chain(context)
  ensure_indices()
  context = context or {}
  local src    = lc(context.source or "")
  local flavor = lc(context.flavor or "")

  local chain = {}

  local function pick_first_by_role(role)
    local lst = MetaCore.by_role and MetaCore.by_role[role]
    if lst and lst[1] then return lst[1] end
    return nil
  end

  local function add_if(def)
    if def then chain[#chain+1] = def end
  end

  if src == "vocals" then
    add_if(pick_first_by_role("CleanEQ") or pick_first_by_role("Tone") or pick_first_by_role("Surgical"))
    add_if(pick_first_by_role("DeEss"))
    add_if(pick_first_by_role("Opto") or pick_first_by_role("Smooth"))
    if flavor == "color" or flavor == "aggressive" then
      add_if(pick_first_by_role("Saturation") or pick_first_by_role("Color"))
    end
    add_if(pick_first_by_role("Limiter") or pick_first_by_role("Safety"))
  elseif src == "drums" then
    add_if(pick_first_by_role("Transient") or pick_first_by_role("Drums"))
    add_if(pick_first_by_role("FET") or pick_first_by_role("Punch"))
    if flavor ~= "clean" then
      add_if(pick_first_by_role("Drive") or pick_first_by_role("Distortion"))
    end
    add_if(pick_first_by_role("Bus") or pick_first_by_role("Glue"))
    add_if(pick_first_by_role("Limiter") or pick_first_by_role("Clipper"))
  elseif src == "bass" then
    add_if(pick_first_by_role("EQ") or pick_first_by_role("Tone"))
    add_if(pick_first_by_role("Bass") or pick_first_by_role("LowEnd"))
    if flavor ~= "clean" then
      add_if(pick_first_by_role("Saturation"))
    end
    add_if(pick_first_by_role("Limiter"))
  elseif src == "mixbus" or src == "bus" then
    add_if(pick_first_by_role("Bus") or pick_first_by_role("Console"))
    add_if(pick_first_by_role("BusCompressor") or pick_first_by_role("Glue"))
    if flavor == "color" or flavor == "aggressive" then
      add_if(pick_first_by_role("Saturation") or pick_first_by_role("Tape"))
    end
    add_if(pick_first_by_role("Limiter"))
  elseif src == "master" then
    add_if(pick_first_by_role("Mastering") or pick_first_by_role("Console"))
    add_if(pick_first_by_role("MasterComp") or pick_first_by_role("Glue"))
    add_if(pick_first_by_role("Tape") or pick_first_by_role("Saturation"))
    add_if(pick_first_by_role("Limiter") or pick_first_by_role("TruePeak"))
    add_if(pick_first_by_role("Meter") or pick_first_by_role("Loudness"))
  end

  return chain
end


return MetaCore


----------------------------------------------------------------------
-- DF95 PluginCatalog Integration (auto-added)
----------------------------------------------------------------------
DF95_MetaCore = DF95_MetaCore or {}

if not DF95_MetaCore._plugin_catalog_loaded then
  local ok_catalog = false
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  local script_dir = script_path and script_path:match("^(.*[\\/])") or ""
  if script_dir ~= "" then
    local catalog_path = script_dir .. "DF95_PluginCatalog.lua"
    local ok, err = pcall(dofile, catalog_path)
    if not ok then
      if reaper and reaper.ShowMessageBox then
        reaper.ShowMessageBox("DF95_PluginCatalog konnte nicht geladen werden:\n" .. tostring(err), "DF95 MetaCore", 0)
      end
    else
      ok_catalog = true
    end
  end
  DF95_MetaCore._plugin_catalog_loaded = ok_catalog
end

function DF95_MetaCore.get_plugins_by_family(family)
  if DF95_GetPluginsByFamily then
    return DF95_GetPluginsByFamily(family)
  end
  return {}
end

function DF95_MetaCore.get_plugins_by_role(role)
  if DF95_GetPluginsByRole then
    return DF95_GetPluginsByRole(role)
  end
  return {}
end

function DF95_MetaCore.get_plugins_by_tag(tag)
  if DF95_GetPluginsByTag then
    return DF95_GetPluginsByTag(tag)
  end
  return {}
end

function DF95_MetaCore.get_plugin_by_id(id)
  if DF95_GetPluginInfoByID then
    local info, fx_name = DF95_GetPluginInfoByID(id)
    return info, fx_name
  end
  return nil
end
