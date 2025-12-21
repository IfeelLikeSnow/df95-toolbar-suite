
-- DF95_ReampSuite_PedalChains.lua
-- Preset-System für Pedal-Ketten (Hardware-Pedale), IDM-optimiert
--
-- Fokus:
--   - Glitch / Bitcrush / stotternde Delays
--   - modulierte Räume
--   - Pitch-Shifting / Formant-artige Bewegungen
--   - geeignet für IDM-Drums, Percussion, FX, Texturen

local M = {}

local EXT_NS = "DF95_REAMP"
local KEY_PC_KEY  = "PEDAL_CHAIN_KEY"
local KEY_PC_NAME = "PEDAL_CHAIN_NAME"
local KEY_PC_DESC = "PEDAL_CHAIN_DESC"

-- WICHTIG:
--   Die Pedalnamen sind rein dokumentarisch – sie ändern keine Hardware-Settings.
--   Ziel: Du weißt später, welche Kette du verwendet hast, und kannst sie reproduzieren.

M.chains = {
  IDM_GlitchPerc = {
    name = "IDM Glitch Perc",
    use_case = "Drums/Perkussion zerhacken: Bitcrush, kurze Delays, metallisch-digital.",
    pedals = {
      "Aroma Mario Bit Crusher (AMO-3) – starkes Downsampling/Bitcrush",
      "Behringer DD400 Digital Delay – sehr kurze, harte Repeats (Slap/Flam)",
      "Optional: Behringer DR100 Room-Reverb sehr klein für Metall-Charakter",
    },
  },

  IDM_ChipNoise = {
    name = "IDM Chip Noise",
    use_case = "8-Bit, Retro-Computersound, Clicks/Glitches für FX & One-Shots.",
    pedals = {
      "Aroma Mario Bit Crusher – extremer 8-Bit/4-Bit-Mode",
      "Behringer DR100 Spring-Reverb – kurzer, trashiger Raum",
    },
  },

  IDM_PitchWarp = {
    name = "IDM Pitch Warp Leads",
    use_case = "Pitch-wobbelnde Leads, Vocal-Formant-artige FX, tonale Glitches.",
    pedals = {
      "DigiTech Whammy 5 – langsame Sweeps, Harmonizer-Intervalle",
      "ENO T-Cube Reverb – Plate/Hall für schwebende Höhen",
      "Optional: Deluxe Memory Boy – leicht moduliertes Delay",
    },
  },

  IDM_ModWash = {
    name = "IDM Modulation Wash",
    use_case = "Washed-out Pads, Drone-Layers, granulare Anmutung aus statischem Material.",
    pedals = {
      "ISET Analog Flanger – langsame, tiefe Modulation (fast Chorus)",
      "Behringer DR100 Mod-Reverb / Hall – lange Decay-Zeiten",
      "Deluxe Memory Boy – Medium-Delay mit leichter Modulation",
    },
  },

  IDM_GranularEcho = {
    name = "IDM Granular Echo",
    use_case = "Zerfaserte Echo-Texturen, zerschnittene Vocals/FX, pseudo-granulare Wiederholungen.",
    pedals = {
      "Electro-Harmonix Deluxe Memory Boy – modulierter Analog-Delay (30–700 ms)",
      "Behringer DD400 – zusätzlich kurze digitale Repeats seriell oder parallel",
    },
  },

  Clean_Ambient = {
    name = "Clean Ambient (Neutral)",
    use_case = "Neutraler, eher cleaner Raum für Fälle, in denen du weniger Zerstörung willst.",
    pedals = {
      "Behringer DR100 Digital Reverb – Hall/Plate",
      "Electro-Harmonix Deluxe Memory Boy – dezentes Echo",
    },
  },
}

function M.get_active_key()
  local r = reaper
  local k = r.GetExtState(EXT_NS, KEY_PC_KEY)
  if k and k ~= "" and M.chains[k] then
    return k
  end
  return "IDM_GlitchPerc"
end

function M.set_active_key(key)
  local r = reaper
  if not key or not M.chains[key] then return end
  local ch = M.chains[key]
  r.SetExtState(EXT_NS, KEY_PC_KEY,  key, true)
  r.SetExtState(EXT_NS, KEY_PC_NAME, ch.name or key, true)
  r.SetExtState(EXT_NS, KEY_PC_DESC, ch.use_case or "", true)
end

function M.get_active_chain()
  return M.chains[M.get_active_key()]
end

local function tag_track_name(tr, tag)
  local r = reaper
  if not tr then return end
  local _, name = r.GetTrackName(tr)
  name = name or ""
  if not name:match("%[PC:") then
    name = name .. " [PC:" .. tag .. "]"
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  end
end

function M.apply_to_selected_tracks()
  local r = reaper
  local key = M.get_active_key()
  local ch  = M.chains[key]
  if not ch then return end

  local sel = r.CountSelectedTracks(0)
  if sel == 0 then return end

  r.Undo_BeginBlock()
  for i = 0, sel-1 do
    local tr = r.GetSelectedTrack(0, i)
    tag_track_name(tr, key)
  end
  r.Undo_EndBlock("DF95 ReampSuite – PedalChain Tag (IDM): " .. (ch.name or key), -1)
end

return M
