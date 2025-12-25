-- @description Export Tag Profiles (Role/Source/FXFlavor helper)
-- @version 1.0
-- @author DF95
-- @about
--   Zentrale Heuristiken & Profile, um aus FXChain-Namen, Bus-Namen
--   oder frei gewählten Labels sinnvolle Export-Tags ableiten zu können.
--
--   Idee:
--     - Anstatt in jedem Script Tags hart zu verdrahten, können DF95-Module
--       diese Datei nutzen, um:
--         * aus einem FXChain-/Bus-Namen eine "Role" (Kick/Snare/...)
--           und "FXFlavor" (BusIDM/LoFiTape/Extreme/...) zu raten.
--         * bei Synth-/Instrument-Szenarien eine konsistente Tag-Logik
--           zu nutzen.
--
--   Nutzung:
--     local TagProfiles = dofile(df95_root .. "DF95_Export_TagProfiles.lua")
--     local role, fxflavor = TagProfiles.guess_from_name("Bus_IDM_Kicks_Punch_01")
--
--     -- Tags dann in Export-Core/mittels DF95_SetExportTag(...) setzen.

local M = {}

----------------------------------------------------------------
-- Primitive Pattern-Heuristik
----------------------------------------------------------------

-- Achtung:
--   * bewusst defensiv & generisch gehalten
--   * du kannst diese Tabelle jederzeit mit genaueren Profilen
--     erweitern (z.B. pro Artist oder pro FXBus-Cluster)
--
-- Reihenfolge ist wichtig: erste Übereinstimmung gewinnt.

M.patterns = {
  -- Drums / Bus-IDM
  { pat = "Kick",       role = "Kick",       fxflavor = "BusIDM" },
  { pat = "Kicks",      role = "Kick",       fxflavor = "BusIDM" },
  { pat = "Snare",      role = "Snare",      fxflavor = "BusIDM" },
  { pat = "Snares",     role = "Snare",      fxflavor = "BusIDM" },
  { pat = "Hat",        role = "Hat",        fxflavor = "BusIDM" },
  { pat = "Hats",       role = "Hat",        fxflavor = "BusIDM" },
  { pat = "Ride",       role = "Cymbal",     fxflavor = "BusIDM" },
  { pat = "Cymbal",     role = "Cymbal",     fxflavor = "BusIDM" },
  { pat = "Perc",       role = "Perc",       fxflavor = "BusIDM" },
  { pat = "Toms",       role = "Toms",       fxflavor = "BusIDM" },
  { pat = "DrumBus",    role = "FullKit",    fxflavor = "BusIDM" },
  { pat = "Drums",      role = "FullKit",    fxflavor = "BusIDM" },

  -- Clicks / Pops / MicroPerc
  { pat = "ClicksPops", role = "ClicksPops", fxflavor = "IDMGlitch" },
  { pat = "Clicks",     role = "ClicksPops", fxflavor = "IDMGlitch" },
  { pat = "Pops",       role = "ClicksPops", fxflavor = "IDMGlitch" },
  { pat = "MicroPerc",  role = "MicroPerc",  fxflavor = "IDMGlitch" },

  -- Synth / Bass / Tonal
  { pat = "Bass",       role = "Bass",       fxflavor = "Clean" },
  { pat = "Sub",        role = "Bass",       fxflavor = "Clean" },
  { pat = "Synth",      role = "Synth",      fxflavor = "Clean" },
  { pat = "Pad",        role = "Synth",      fxflavor = "Clean" },
  { pat = "Keys",       role = "Synth",      fxflavor = "Clean" },

  -- Atmos / Foley / Field Recording
  { pat = "Atmos",      role = "Atmos",      fxflavor = "Clean" },
  { pat = "Foley",      role = "Foley",      fxflavor = "Clean" },
  { pat = "Field",      role = "Atmos",      fxflavor = "Clean" },
  { pat = "Ambience",   role = "Atmos",      fxflavor = "Clean" },

  -- LoFi / Tape
  { pat = "Tape",       role = "Any",        fxflavor = "LoFiTape" },
  { pat = "LoFi",       role = "Any",        fxflavor = "LoFiTape" },

  -- Extreme / Trash
  { pat = "Trash",      role = "Any",        fxflavor = "Extreme" },
  { pat = "Doom",       role = "Any",        fxflavor = "Extreme" },
}

----------------------------------------------------------------
-- Helper: pattern-basiertes Guessing
----------------------------------------------------------------

local function contains_ci(haystack, needle)
  haystack = haystack or ""
  needle   = needle or ""
  if haystack == "" or needle == "" then return false end
  return haystack:lower():find(needle:lower(), 1, true) ~= nil
end

function M.guess_from_name(name)
  if not name or name == "" then
    return "Any", "Generic"
  end

  for _, p in ipairs(M.patterns) do
    if contains_ci(name, p.pat) then
      return p.role or "Any", p.fxflavor or "Generic"
    end
  end

  return "Any", "Generic"
end

return M
