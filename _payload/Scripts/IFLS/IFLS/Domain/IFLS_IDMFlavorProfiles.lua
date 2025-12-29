-- IFLS_IDMFlavorProfiles.lua
-- Vordefinierte Flavor-basierte IDM-Profile für FX-Auswahl.

local M = {}

-- Microglitch: sehr percussive, klickige Glitch-Sounds
M.microglitch = {
  id   = "microglitch",
  name = "IDM Microglitch",
  include = { "glitch", "stutter", "bitcrush", "transient", "click" },
  exclude = { "space", "reverb", "drone" },
  prefer  = { "glitch", "stutter" },
}

-- Klassischer IDM-Glitch (Aphex / Squarepusher)
M.idm_glitch = {
  id   = "idm_glitch",
  name = "IDM Glitch Core",
  include = { "glitch", "granular", "spectral", "bitcrush" },
  exclude = {},
  prefer  = { "granular", "glitch" },
}

-- Ambient IDM / Space Texturen
M.ambient_space = {
  id   = "ambient_space",
  name = "IDM Ambient Space",
  include = { "space", "granular", "drone", "freeze", "spectral" },
  exclude = { "bitcrush", "stutter" },
  prefer  = { "granular", "space" },
}

-- Drum FX allgemein (parallel / insert)
M.idm_drumfx = {
  id   = "idm_drumfx",
  name = "IDM Drum FX",
  include = { "filter", "saturation", "distortion", "glitch", "transient" },
  exclude = { "space" },
  prefer  = { "saturation", "filter" },
}

-- Microbeats / Clicks & Pops
M.microbeats = {
  id   = "microbeats",
  name = "IDM Microbeats",
  include = { "click", "bitcrush", "transient", "filter" },
  exclude = { "reverb", "space", "drone" },
  prefer  = { "click", "filter" },
}

return M
