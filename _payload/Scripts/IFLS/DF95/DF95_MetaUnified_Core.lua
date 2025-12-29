
-- @description MetaUnified Core (MetaCore VST All + SynthMetaCore v2.7)
-- @version 1.0
-- @author DF95 + Reaper DAW Ultimate Assistant
-- @about
--   Vereinigt:
--     * DF95_MetaCore_VST_All_Flat.lua  (FX + VSTi MetaCore, inkl. v15-Optimierungen)
--     * DF95_SynthMetaCore_v2_7.lua     (Hardware-Synth + Patchbay/Bridges)
--
--   Rückgabe:
--     local Core = dofile("<resource>/Scripts/IFLS/DF95/DF95_MetaUnified_Core.lua")
--
--     Core.Meta         -> MetaCore (VST/FX/VSTi)
--     Core.Synth        -> SynthMetaCore (Hardware)
--     Core.get_drum_synths() -> Liste aller Drum-/Kick-/Percussion-Synths aus MetaCore.vsti
--
--   Hinweise:
--     * Wenn DF95_SynthMetaCore_v2_7.lua fehlt oder fehlschlägt, ist Core.Synth = nil,
--       Core.Meta funktioniert trotzdem.
--     * Dieses Modul benutzt reaper.GetResourcePath(), daher muss "reaper" verfügbar sein.
--

local r = reaper

local Core = {}

------------------------------------------------------------
-- MetaCore laden (VST All Flat)
------------------------------------------------------------
do
  local resource = r.GetResourcePath()
  local base = resource .. "/Scripts/IFLS/DF95/"
  local path = base .. "DF95_MetaCore_VST_All_Flat.lua"

  local ok, MetaCore = pcall(dofile, path)
  if not ok or type(MetaCore) ~= "table" then
    error("DF95_MetaUnified_Core: Konnte DF95_MetaCore_VST_All_Flat.lua nicht laden: " .. tostring(path))
  end

  -- Indizes aufbauen falls nötig
  if MetaCore._build_indices then
    MetaCore._build_indices()
  end

  -- Fallback: is_drum_synth definieren, falls noch nicht vorhanden
  if not MetaCore.is_drum_synth then
    function MetaCore.is_drum_synth(def)
      if not def or type(def) ~= "table" then return false end
      local t = (def.type or ""):lower()
      if t:find("drum") or t:find("kick") or t:find("clap") then
        return true
      end
      if def.roles and type(def.roles) == "table" then
        for _, r in ipairs(def.roles) do
          local rl = r:lower()
          if rl == "drums"
             or rl == "kick"
             or rl == "bass-drum"
             or rl == "percussion"
             or rl == "clap"
          then
            return true
          end
        end
      end
      return false
    end
  end

  Core.Meta = MetaCore
end

------------------------------------------------------------
-- SynthMetaCore (Hardware) laden – optional
------------------------------------------------------------
do
  local resource = r.GetResourcePath()
  local base = resource .. "/Scripts/IFLS/DF95/"
  local path = base .. "DF95_SynthMetaCore_v2_7.lua"

  local ok, SynthMetaCore = pcall(dofile, path)
  if ok and type(SynthMetaCore) == "table" then
    Core.Synth = SynthMetaCore
  else
    Core.Synth = nil
  end
end

------------------------------------------------------------
-- Helper: alle Drum-/Kick-/Percussion-Synths aus MetaCore.vsti
------------------------------------------------------------
function Core.get_drum_synths()
  local list = {}
  local MC = Core.Meta
  if not (MC and MC.vsti and MC.is_drum_synth) then
    return list
  end

  for id, def in pairs(MC.vsti) do
    if type(def) == "table" and def.id and MC.is_drum_synth(def) then
      list[#list+1] = def
    end
  end

  table.sort(list, function(a,b)
    local da = (a.display or a.id or ""):lower()
    local db = (b.display or b.id or ""):lower()
    return da < db
  end)

  return list
end

return Core
