-- @description Plugin Catalog
-- @version 1.0
-- @author DF95
-- @about
--   Zentrale Beschreibung wichtiger IDM-/Drum-/Master-Plugins
--   für MetaCore, Pipeline_Core, ArtistConsole, Apply-Scripts etc.
--
--   Pro Plugin:
--     key   = Reaper FX-Name (so wie TrackFX_GetFXName ihn liefert)
--     id    = stabile Kurz-ID (für Skripte)
--     dev   = Hersteller
--     type  = "fx" oder "instrument"
--     role  = Hauptrolle (z.B. "glitch_buffer", "drum_bus_comp", "idm_synth_core")
--     family= thematische Familie (z.B. "IDM_GLITCH", "DRUM_TOOLS", "LOFI_TAPE", ...)
--     tags  = Liste von Schlagworten
--     format= "VST2"/"VST3"/"JS"
--     is_x86= true/false (wenn bekannt)
--
--   Achtung:
--     - FX-Namen können je nach System minimal anders sein. Ggf. an deine
--       echten Reaper-Namen anpassen.
--     - Der Katalog ist als Startpunkt gedacht und kann jederzeit erweitert werden.

if not DF95_PLUGIN_CATALOG then
  DF95_PLUGIN_CATALOG = {}
end

local C = DF95_PLUGIN_CATALOG

----------------------------------------------------------------------
-- 🧨 IDM-GLITCH & BUFFER FX (Glitchmachines, dBlue, JS)
----------------------------------------------------------------------

C["VST3: Fracture (Glitchmachines)"] = {
  id      = "fracture",
  dev     = "Glitchmachines",
  type    = "fx",
  role    = "glitch_buffer",
  family  = "IDM_GLITCH",
  tags    = { "glitch", "buffer", "stutter", "idm", "experimental" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Buffer-Effekt für 'robotic artifacts' und 'musical malfunctions', ideal für Slices, Hats, MicroPerc.",
}

C["VST3: Hysteresis (Glitchmachines)"] = {
  id      = "hysteresis",
  dev     = "Glitchmachines",
  type    = "fx",
  role    = "glitch_delay",
  family  = "IDM_GLITCH",
  tags    = { "delay", "glitch", "stutter", "feedback", "idm" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Delay mit Stutter, LPF und Mod in der Feedback-Loop, perfekt für glitchy Echos und IDM-Delays.",
}

C["VST: dblue Glitch v1.3 (dblue)"] = {
  id      = "dblue_glitch",
  dev     = "dBlue / Illformed",
  type    = "fx",
  role    = "glitch_multifx",
  family  = "IDM_GLITCH",
  tags    = { "sequencer", "tapestop", "retrigger", "reverse", "crusher" },
  format  = "VST2",
  is_x86  = true,
  notes   = "Legacy-Glitch-Sequencer mit TapeStop, Retrigger, Shuffler u.a., ideal als eigener 'Legacy Glitch'-Bus.",
}

C["VST3: Convex (Glitchmachines)"] = {
  id      = "convex",
  dev     = "Glitchmachines",
  type    = "fx",
  role    = "mod_multifx",
  family  = "IDM_GLITCH",
  tags    = { "glitch", "modulation", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: Cryogen (Glitchmachines)"] = {
  id      = "cryogen",
  dev     = "Glitchmachines",
  type    = "fx",
  role    = "mod_multifx",
  family  = "IDM_GLITCH",
  tags    = { "bitcrush", "modulation", "idm" },
  format  = "VST3",
  is_x86  = false,
}

----------------------------------------------------------------------
-- ⚡ DRUM / TRANSIENT / DISTORTION (Kilohearts, Baby Audio, Noise Eng, Auburn, Audec, Chow)
----------------------------------------------------------------------

C["VST3: kHs Transient Shaper (Kilohearts)"] = {
  id      = "khs_transient",
  dev     = "Kilohearts",
  type    = "fx",
  role    = "transient_shaper",
  family  = "DRUM_TOOLS",
  tags    = { "transient", "drums", "attack", "sustain" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Schneller, moderner Transient-Shaper für Kicks, Snares, Hats und Perc.",
}

C["VST3: Beat Slammer (BABY Audio)"] = {
  id      = "beat_slammer",
  dev     = "BABY Audio",
  type    = "fx",
  role    = "drum_bus_comp",
  family  = "DRUM_TOOLS",
  tags    = { "compression", "parallel", "slam", "bus", "drums" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Aggressiver Kompressor für Drums/Busse, XY-Pad für Amount/Mix. Perfekt zum 'Smashen' von IDM-Drums.",
}

C["VST3: Smooth Operator (BABY Audio)"] = {
  id      = "smooth_operator",
  dev     = "BABY Audio",
  type    = "fx",
  role    = "spectral_tamer",
  family  = "MIX_HELPER",
  tags    = { "spectral", "de-harsh", "resonance", "bus" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Spektraler Resonanz-Shaper/De-Harshing, ideal auf Bussen und Master.",
}

C["VST3: Ruina (Noise Engineering)"] = {
  id      = "ruina",
  dev     = "Noise Engineering",
  type    = "fx",
  role    = "multi_distortion",
  family  = "IDM_DISTORTION",
  tags    = { "distortion", "wavefolding", "multiband", "phase", "doom", "idm" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Kreative digitale Multidistortion mit Wavefolding, Phase-Shifting, Multiband-Sat und DOOM. Von subtil bis total brutal.",
}

C["VST3: Couture (Auburn Sounds)"] = {
  id      = "couture",
  dev     = "Auburn Sounds",
  type    = "fx",
  role    = "transient_shaper_saturator",
  family  = "DRUM_TOOLS",
  tags    = { "transient", "saturation", "drums", "bus" },
  format  = "VST3",
  is_x86  = false,
  notes   = "Transient Shaper + Distortion/Saturation in einem, ideal für aggressive IDM-Drums.",
}

C["VST3: adc Transient (Audec)"] = {
  id      = "adc_transient",
  dev     = "Audec",
  type    = "fx",
  role    = "transient_shaper",
  family  = "DRUM_TOOLS",
  tags    = { "transient", "lightweight", "visual" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: adc Crush 2 (Audec)"] = {
  id      = "adc_crush2",
  dev     = "Audec",
  type    = "fx",
  role    = "bitcrusher",
  family  = "IDM_GLITCH",
  tags    = { "bitcrush", "lofi", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: adc Ring 2 (Audec)"] = {
  id      = "adc_ring2",
  dev     = "Audec",
  type    = "fx",
  role    = "ringmod",
  family  = "IDM_GLITCH",
  tags    = { "ringmod", "metallic", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: adc Spread Delay (Audec)"] = {
  id      = "adc_spread_delay",
  dev     = "Audec",
  type    = "fx",
  role    = "stereo_delay",
  family  = "IDM_SPACE",
  tags    = { "delay", "pingpong", "stereo", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: adc Extra Pan (Audec)"] = {
  id      = "adc_extra_pan",
  dev     = "Audec",
  type    = "fx",
  role    = "stereo_panner",
  family  = "IDM_SPACE",
  tags    = { "pan", "stereo", "movement" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: adc Haas 2 (Audec)"] = {
  id      = "adc_haas2",
  dev     = "Audec",
  type    = "fx",
  role    = "haas_stereo",
  family  = "IDM_SPACE",
  tags    = { "stereo", "haas", "ear_trick" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: ChowKick (chowdsp)"] = {
  id      = "chowkick",
  dev     = "chowdsp",
  type    = "instrument",
  role    = "drum_synth_kick",
  family  = "DRUM_SYNTHS",
  tags    = { "kick", "synth", "physical_model", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VSTi: Elsita (MODE MACHINES)"] = {
  id      = "elsita",
  dev     = "Mode Machines",
  type    = "instrument",
  role    = "drum_machine",
  family  = "DRUM_SYNTHS",
  tags    = { "drums", "analog_style", "idm", "electro" },
  format  = "VST2",
  is_x86  = false,
}

----------------------------------------------------------------------
-- 📼 LOFI / TAPE / AIRWINDOWS / CASSETTE
----------------------------------------------------------------------

C["VST3: Tape Cassette 2 (Caelum Audio)"] = {
  id      = "tape_cassette2",
  dev     = "Caelum Audio",
  type    = "fx",
  role    = "lofi_tape",
  family  = "LOFI_TAPE",
  tags    = { "tape", "wowflutter", "noise", "lofi" },
  format  = "VST3",
  is_x86  = false,
}

C["VST: ToTape7 (airwindows)"] = {
  id      = "totape7",
  dev     = "Airwindows",
  type    = "fx",
  role    = "tape_sat",
  family  = "LOFI_TAPE",
  tags    = { "saturation", "tape", "analog" },
  format  = "VST2",
  is_x86  = false,
}

C["VST: ToTape8 (airwindows)"] = {
  id      = "totape8",
  dev     = "Airwindows",
  type    = "fx",
  role    = "tape_sat",
  family  = "LOFI_TAPE",
  tags    = { "saturation", "tape", "analog" },
  format  = "VST2",
  is_x86  = false,
}

C["VST: FromTape (airwindows)"] = {
  id      = "from_tape",
  dev     = "Airwindows",
  type    = "fx",
  role    = "tape_color",
  family  = "LOFI_TAPE",
  tags    = { "tape", "color", "saturation" },
  format  = "VST2",
  is_x86  = false,
}

C["VST: Flutter2 (airwindows)"] = {
  id      = "flutter2",
  dev     = "Airwindows",
  type    = "fx",
  role    = "wow_flutter",
  family  = "LOFI_TAPE",
  tags    = { "wowflutter", "pitch_wobble", "tape" },
  format  = "VST2",
  is_x86  = false,
}

C["VST: GlitchShifter (airwindows)"] = {
  id      = "glitchshifter",
  dev     = "Airwindows",
  type    = "fx",
  role    = "pitch_glitch",
  family  = "IDM_GLITCH",
  tags    = { "pitch", "glitch", "weird" },
  format  = "VST2",
  is_x86  = false,
}

----------------------------------------------------------------------
-- ⏳ UNFILTERED AUDIO – TIME/SPACE/LOFI/CHAOS
----------------------------------------------------------------------

C["VST3: Sandman Pro (Unfiltered Audio)"] = {
  id      = "sandman_pro",
  dev     = "Unfiltered Audio",
  type    = "fx",
  role    = "time_warp_delay",
  family  = "IDM_TIME",
  tags    = { "delay", "sleep_buffer", "reverse", "glitch", "granular" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: Silo (Unfiltered Audio)"] = {
  id      = "silo",
  dev     = "Unfiltered Audio",
  type    = "fx",
  role    = "granular_reverb",
  family  = "IDM_SPACE",
  tags    = { "reverb", "granular", "spatial", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: Fault (Unfiltered Audio)"] = {
  id      = "fault",
  dev     = "Unfiltered Audio",
  type    = "fx",
  role    = "freq_shift_delay",
  family  = "IDM_TIME",
  tags    = { "frequency_shifter", "delay", "modulation", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: lo-fi-af (Unfiltered Audio)"] = {
  id      = "lofi_af",
  dev     = "Unfiltered Audio",
  type    = "fx",
  role    = "lofi_designer",
  family  = "LOFI_TAPE",
  tags    = { "lofi", "degrade", "phone", "radio" },
  format  = "VST3",
  is_x86  = false,
}

----------------------------------------------------------------------
-- 🧩 KILOHEARTS SNAPINS – FILTER / MOD / SPACE
----------------------------------------------------------------------

C["VST3: kHs Frequency Shifter (Kilohearts)"] = {
  id      = "khs_freq_shifter",
  dev     = "Kilohearts",
  type    = "fx",
  role    = "frequency_shifter",
  family  = "IDM_MOD",
  tags    = { "frequency_shift", "weird", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: kHs Formant Filter (Kilohearts)"] = {
  id      = "khs_formant",
  dev     = "Kilohearts",
  type    = "fx",
  role    = "formant_filter",
  family  = "IDM_MOD",
  tags    = { "formant", "vocal", "movement" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: kHs Nonlinear Filter (Kilohearts)"] = {
  id      = "khs_nonlinear_filter",
  dev     = "Kilohearts",
  type    = "fx",
  role    = "filter_distortion",
  family  = "IDM_MOD",
  tags    = { "filter", "drive", "resonance" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3: kHs Ring Mod (Kilohearts)"] = {
  id      = "khs_ringmod",
  dev     = "Kilohearts",
  type    = "fx",
  role    = "ringmod",
  family  = "IDM_GLITCH",
  tags    = { "ringmod", "metallic", "idm" },
  format  = "VST3",
  is_x86  = false,
}

----------------------------------------------------------------------
-- 🧬 IDM-SYNTH CORE (Surge, Vital, Noise Eng, u-he, etc.)
----------------------------------------------------------------------

C["VST3i: Surge XT (Surge Synth Team)"] = {
  id      = "surge_xt",
  dev     = "Surge Synth Team",
  type    = "instrument",
  role    = "idm_synth_core",
  family  = "IDM_SYNTH_CORE",
  tags    = { "hybrid", "wavetable", "fm", "mpe" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: Vital (Vital Audio)"] = {
  id      = "vital",
  dev     = "Vital Audio",
  type    = "instrument",
  role    = "idm_synth_core",
  family  = "IDM_SYNTH_CORE",
  tags    = { "wavetable", "modulation", "formant", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: Odin2 (TheWaveWarden)"] = {
  id      = "odin2",
  dev     = "TheWaveWarden",
  type    = "instrument",
  role    = "hybrid_synth",
  family  = "IDM_SYNTH_CORE",
  tags    = { "hybrid", "fm", "wavetable" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: Dexed (Digital Suburban)"] = {
  id      = "dexed",
  dev     = "Digital Suburban",
  type    = "instrument",
  role    = "fm_synth",
  family  = "IDM_FM",
  tags    = { "fm", "dx7", "metallic", "percussion" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: Helm (Matt Tytel)"] = {
  id      = "helm",
  dev     = "Matt Tytel",
  type    = "instrument",
  role    = "idm_synth",
  family  = "IDM_SYNTH_CORE",
  tags    = { "modular", "fm", "va" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: Sinc Vereor (Noise Engineering)"] = {
  id      = "sinc_vereor",
  dev     = "Noise Engineering",
  type    = "instrument",
  role    = "eurorack_style",
  family  = "IDM_SYNTH_EURO",
  tags    = { "additive", "wavefold", "chorus", "idm" },
  format  = "VST3",
  is_x86  = false,
}

C["VST3i: Virt Vereor (Noise Engineering)"] = {
  id      = "virt_vereor",
  dev     = "Noise Engineering",
  type    = "instrument",
  role    = "eurorack_style",
  family  = "IDM_SYNTH_EURO",
  tags    = { "supersaw", "wavefold", "idm" },
  format  = "VST3",
  is_x86  = false,
}

----------------------------------------------------------------------
-- 🔎 Helper-API für MetaCore / Pipeline / ArtistConsole
----------------------------------------------------------------------

function DF95_GetPluginInfoByFXName(fx_name)
  return DF95_PLUGIN_CATALOG[fx_name]
end

function DF95_GetPluginInfoByID(id)
  for fx_name, info in pairs(DF95_PLUGIN_CATALOG) do
    if info.id == id then return info, fx_name end
  end
  return nil
end

function DF95_GetPluginsByRole(role)
  local out = {}
  for fx_name, info in pairs(DF95_PLUGIN_CATALOG) do
    if info.role == role then
      out[#out+1] = { fx_name = fx_name, info = info }
    end
  end
  return out
end

function DF95_GetPluginsByFamily(family)
  local out = {}
  for fx_name, info in pairs(DF95_PLUGIN_CATALOG) do
    if info.family == family then
      out[#out+1] = { fx_name = fx_name, info = info }
    end
  end
  return out
end

function DF95_GetPluginsByTag(tag)
  local out = {}
  local tag_l = tag:lower()
  for fx_name, info in pairs(DF95_PLUGIN_CATALOG) do
    if info.tags then
      for _, t in ipairs(info.tags) do
        if t:lower() == tag_l then
          out[#out+1] = { fx_name = fx_name, info = info }
          break
        end
      end
    end
  end
  return out
end
