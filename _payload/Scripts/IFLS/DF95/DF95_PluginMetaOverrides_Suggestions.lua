-- DF95_PluginMetaOverrides_Suggestions.lua
-- 
-- Vorschlags-Overrides für einige wichtige IDM-relevante Plugins,
-- basierend auf Web-Recherche (Stand 2025-12).
--
-- Du kannst diese Datei z.B. in DF95_PluginMetaOverrides.lua kopieren
-- oder mit bestehenden Overrides mergen.

local M = {}
M.OVERRIDES = {
  -- A1StereoControl: Stereo width tool / widener
  ["VST3: A1StereoControl (A1AUDIO.de)"]                 = { category = "modulation",           idm_group = "IDM_STEREO" },

  -- Acon Digital Multiply: Chorus / voice doubler
  ["VST3: Acon Digital Multiply (Acon Digital)"]         = { category = "modulation",           idm_group = "IDM_STEREO" },
  ["VST: Acon Digital Multiply (Acon Digital) (8ch)"]    = { category = "modulation",           idm_group = "IDM_STEREO" },

  -- Danaides: sequenced sound mangler, glitch / modulation multi-fx
  ["VST: Danaides (x86) (Inear_Display)"]                = { category = "texture_experimental", idm_group = "IDM_TEXTURE" },

  -- Baby Audio Magic Dice: random wet-FX (delay/reverb/mod textures)
  ["VST3: Magic Dice (BABY Audio)"]                      = { category = "texture_experimental", idm_group = "IDM_TEXTURE" },
  ["VST: Magic Dice (x86) (BABY Audio) (64ch)"]          = { category = "texture_experimental", idm_group = "IDM_TEXTURE" },

  -- Baby Audio Magic Switch: Juno-style chorus
  ["VST3: Magic Switch (BABY Audio)"]                    = { category = "modulation",           idm_group = "IDM_STEREO" },
  ["VST: Magic Switch (x86) (BABY Audio) (64ch)"]        = { category = "modulation",           idm_group = "IDM_STEREO" },

  -- VZtec Malibu: reverb + tremolo pedal emu
  ["VST3: Malibu (VZtec)"]                               = { category = "reverb",               idm_group = "IDM_SPACE" },

  -- Airwindows MatrixVerb: swiss-army reverb
  ["VST: MatrixVerb (airwindows)"]                       = { category = "reverb",               idm_group = "IDM_SPACE" },

  -- Airwindows Mackity: Mackie 1202 console input / preamp-saturation
  ["VST: Mackity (airwindows)"]                          = { category = "console_tape",         idm_group = "IDM_BUSS" },
}

return M
