-- @description Export Presets
-- @version 1.0
-- @author DF95
-- @about
--   Zentrale Sammlung von Export-Presets für typische Workflows:
--     - IDM MicroPerc / ClicksPops
--     - Drum Packs
--     - Synth OneShots
--     - Mobile Field Recorder / Foley
--   Die Presets liefern nur Vorschlagswerte für core.run(opts).
--   Role/Source/FXFlavor können weiterhin durch Tag-Panel, FXBus etc.
--   überschrieben werden.

local M = {}

-- Preset-Liste:
--   id    : interne Kennung
--   label : UI-Name
--   opts  : Tabelle, die an DF95_Export_Core.run(opts) übergeben wird
--
-- Wichtige Felder in opts:
--   mode      = "ALL_SLICES" | "SELECTED_SLICES" | "SELECTED_SLICES_SUM" | "LOOP_TIMESEL"
--   target    = "ORIGINAL" | "ZOOM96_32F" | "SPLICE_44_24" | "LOOPMASTERS_44_24" | "ADSR_44_24"
--   category  = z.B. "Slices_Master" | "Loops_Master"
--   subtype   = z.B. "MicroPerc" | "ClicksPops" | "DrumPack"
--   role      = Kick/Snare/Hat/Perc/... (kann leer bleiben -> Auto/Tags)
--   source    = MobileFR/ZoomF6/Synth/Sampler/... (kann leer bleiben -> Auto/Tags)
--   fxflavor  = Clean/Safe/BusIDM/IDMGlitch/LoFiTape/Extreme/... (kann leer)
--   dest_root = optional: eigener Basis-Pfad
--
-- Hinweis:
--   Wenn role/source/fxflavor nil oder "Any"/"Generic" sind,
--   nutzt DF95_Export_Core weiterhin Auto-Detection + Tags.

M.list = {
  {
    id    = "IDM_MICROPERC",
    label = "IDM MicroPerc Pack",
    opts  = {
      mode      = "SELECTED_SLICES_SUM",
      target    = "SPLICE_44_24",
      category  = "Slices_Master",
      subtype   = "MicroPerc",
      role      = "MicroPerc",
      source    = nil,          -- aus Tags / Auto
      fxflavor  = "IDMGlitch",
    },
  },
  {
    id    = "IDM_CLICKPOPS",
    label = "IDM Clicks & Pops",
    opts  = {
      mode      = "SELECTED_SLICES_SUM",
      target    = "SPLICE_44_24",
      category  = "Slices_Master",
      subtype   = "ClicksPops",
      role      = "ClicksPops",
      source    = nil,
      fxflavor  = "IDMGlitch",
    },
  },
  {
    id    = "IDM_DRUM_PACK",
    label = "IDM Drum Pack (FullKit)",
    opts  = {
      mode      = "SELECTED_SLICES_SUM",
      target    = "SPLICE_44_24",
      category  = "Slices_Master",
      subtype   = "DrumPack",
      role      = "FullKit",
      source    = nil,
      fxflavor  = "BusIDM",
    },
  },
  {
    id    = "SYNTH_ONESHOTS",
    label = "Synth OneShots",
    opts  = {
      mode      = "SELECTED_SLICES_SUM",
      target    = "SPLICE_44_24",
      category  = "Slices_Master",
      subtype   = "SynthOneShots",
      role      = "Synth",
      source    = "Synth",
      fxflavor  = "Clean",
    },
  },
  {
    id    = "MOBILE_FOLEY",
    label = "Mobile FR Foley Pack",
    opts  = {
      mode      = "SELECTED_SLICES_SUM",
      target    = "SPLICE_44_24",
      category  = "Slices_Master",
      subtype   = "MobileFR",
      role      = "Atmos",
      source    = "MobileFR",
      fxflavor  = "Clean",
    },
  },
  {
    id    = "ARTIST_BASED",
    label = "Artist-Based (Auto)",
    opts  = {
      mode      = "SELECTED_SLICES_SUM",
      target    = "SPLICE_44_24",
      category  = "Slices_Master",
      subtype   = "",
      role      = nil,      -- alles Auto/Tags
      source    = nil,
      fxflavor  = nil,
    },
  },

  {
    id    = "DRONE_HOME_ATMOS_LOOP",
    label = "Home Drone Atmos (Loop)",
    opts  = {
      mode      = "LOOP_TIMESEL",
      target    = "ZOOM96_32F",
      category  = "HOME_ATMOS",
      subtype   = "ROOMTONE",
      role      = "Drone",
      source    = "Fieldrec",
      fxflavor  = "DroneFXV1",
    },
  },
  {
    id    = "DRONE_EMF_DRONE_LONG",
    label = "EMF Drone Longform",
    opts  = {
      mode      = "LOOP_TIMESEL",
      target    = "ZOOM96_32F",
      category  = "EMF_DRONE",
      subtype   = "LONG",
      role      = "Drone",
      source    = "EMFRecorder",
      fxflavor  = "DroneFXV1",
    },
  },
  {
    id    = "DRONE_IDM_TEXTURE_LONG",
    label = "IDM Drone Texture (Loop)",
    opts  = {
      mode      = "LOOP_TIMESEL",
      target    = "SPLICE_44_24",
      category  = "IDM_TEXTURE",
      subtype   = "AMBIENT",
      role      = "Drone",
      source    = "ArtistIDM",
      fxflavor  = "DroneFXV1",
    },
  },
}

function M.get_list()
  return M.list
end

function M.get_by_id(id)
  for _, p in ipairs(M.list) do
    if p.id == id then return p end
  end
  return nil
end

function M.get_by_label(label)
  for _, p in ipairs(M.list) do
    if p.label == label then return p end
  end
  return nil
end

return M
