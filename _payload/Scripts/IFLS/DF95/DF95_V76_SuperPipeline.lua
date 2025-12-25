
-- @description DF95_V76_SuperPipeline
-- @version 1.1
-- @author DF95
-- @about
--   Integrations-Layer zwischen:
--     - DF95_V72_SuperPipeline (Fieldrec / AutoMic / Export)
--     - DF95 ReampSuite (V71 ReampRouter + Profile + PedalChains)
--
--   V76.1 Erweiterung:
--     - nutzt optional DF95_ReampSuite_PedalChains_Intelligence.lua,
--       um automatisch eine passende PedalChain basierend auf Tracknamen
--       vorzuschlagen (IDM-optimiert).
--
--   Idee:
--     - Selektierte Tracks werden in zwei Gruppen geteilt:
--         * Fieldrec/Dialog/FX-Tracks  -> gehen an DF95_V72_SuperPipeline.lua
--         * Reamp-/DI-/Pedal-Tracks    -> gehen an DF95_ReampSuite_Router.lua
--     - Kommunikation ausschließlich über ExtStates:
--         * DF95_SUPERPIPELINE/*   (wie V72)
--         * DF95_REAMP/*           (Profile, Routing, PedalChains)
--
--   WICHTIG:
--     - Dieses Script überschreibt keine bestehenden Dateien.
--     - DF95_V72_SuperPipeline.lua und DF95_ReampSuite_Router.lua
--       müssen im selben DF95-Ordner liegen.
--     - DF95_ReampSuite_PedalChains_Intelligence.lua ist optional.
--

local r = reaper

---------------------------------------------------------
-- Helpers
---------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end

local function get_track_name(tr)
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  return name or ""
end

local function is_reamp_candidate(tr)
  -- Angelehnt an DF95_ReampSuite_MainGUI.is_reamp_candidate
  local name = get_track_name(tr)
  if not name or name == "" then return false end
  local u = name:upper()
  if u:match("REAMP") then return true end
  if u:match("RE%-AMP") then return true end
  if u:match(" DI ") then return true end
  if u:match("_DI") then return true end
  if u:match("DI_") then return true end
  if u:match("PEDAL") then return true end
  return false
end

local function collect_selected_tracks()
  local t = {}
  local cnt = r.CountSelectedTracks(0)
  for i = 0, cnt - 1 do
    t[#t+1] = r.GetSelectedTrack(0, i)
  end
  return t
end

local function split_tracks(tracks)
  local fieldrec = {}
  local reamp = {}
  for _, tr in ipairs(tracks) do
    if is_reamp_candidate(tr) then
      reamp[#reamp+1] = tr
    else
      fieldrec[#fieldrec+1] = tr
    end
  end
  return fieldrec, reamp
end

local function tracks_to_tracknumbers(tracks)
  local nums = {}
  for _, tr in ipairs(tracks) do
    local num = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    nums[#nums+1] = tostring(num)
  end
  return table.concat(nums, ",")
end

---------------------------------------------------------
-- Optional: PedalChain-Intelligenz (V76.1)
---------------------------------------------------------

local pc_int_mod = nil
do
  local path = df95_root() .. "ReampSuite/DF95_ReampSuite_PedalChains_Intelligence.lua"
  local mod, err = safe_require(path)
  if mod and type(mod) == "table" and type(mod.auto_assign_for_tracks) == "function" then
    pc_int_mod = mod
  end
end

-- Fallback-Heuristik, falls keine Intelligenz verfügbar ist
local function simple_guess_pedal_chain_key_for_tracks(tracks)
  local has_idm = false
  for _, tr in ipairs(tracks) do
    local name = get_track_name(tr):lower()
    if name:find("idm") then
      has_idm = true
      break
    end
  end
  if has_idm then
    return "IDM_GlitchPerc" -- Beispiel-Key aus DF95_ReampSuite_PedalChains.lua
  end
  return nil
end

local function guess_pedal_chain_key_for_tracks(reampTracks)
  if pc_int_mod then
    -- nutzt die "echte" Intelligenz, setzt ExtStates aber NICHT tag_tracks
    local key = pc_int_mod.auto_assign_for_tracks(reampTracks, {
      tag_tracks = false,           -- V76 ändert keine Namen automatisch
      set_extstate = true,          -- aber ExtStates werden gesetzt
      verbose = false,
    })
    if key then return key end
  end
  -- Fallback auf alte, einfache Heuristik
  return simple_guess_pedal_chain_key_for_tracks(reampTracks)
end

---------------------------------------------------------
-- V72 SuperPipeline (Fieldrec-Flow)
---------------------------------------------------------

local function run_v72_superpipeline_for_fieldrec(fieldrecTracks)
  if #fieldrecTracks == 0 then return end

  local csv_ids = tracks_to_tracknumbers(fieldrecTracks)
  r.SetExtState("DF95_SUPERPIPELINE", "TRACK_IDS", csv_ids, false)

  local v72_path = df95_root() .. "DF95_V72_SuperPipeline.lua"

  local ok, err = pcall(dofile, v72_path)
  if not ok then
    r.ShowMessageBox(
      "DF95_V72_SuperPipeline.lua konnte nicht ausgeführt werden:\n" .. tostring(err or "?") ..
      "\n\nBitte prüfen, ob die Datei existiert und lauffähig ist.\nPfad: " .. v72_path,
      "DF95 V76 SuperPipeline – Fieldrec",
      0
    )
    return
  end
end

---------------------------------------------------------
-- ReampSuite-Integration (Reamp-Flow)
---------------------------------------------------------

local function run_reampsuite_for_reamp_tracks(reampTracks)
  if #reampTracks == 0 then return end

  local csv_ids = tracks_to_tracknumbers(reampTracks)

  -- ExtStates für ReampSuite / V71 ReampRouter setzen
  local EXT_NS = "DF95_REAMP"
  r.SetExtState(EXT_NS, "TRACK_IDS", csv_ids, false)

  local chain_key = guess_pedal_chain_key_for_tracks(reampTracks)
  if chain_key then
    -- Nur Key setzen – Name/Beschreibung werden von PedalChains-GUI oder
    -- Intelligence-Modul gesetzt, wenn gewünscht.
    r.SetExtState(EXT_NS, "PEDAL_CHAIN_KEY", chain_key, false)
  end

  -- ReampSuite-Router ausführen (wählt Profil, setzt OUT_CH/IN_CH, ruft V71 ReampRouter)
  local router_path = df95_root() .. "ReampSuite/DF95_ReampSuite_Router.lua"

  local ok, err = pcall(dofile, router_path)
  if not ok then
    r.ShowMessageBox(
      "DF95_ReampSuite_Router.lua konnte nicht ausgeführt werden:\n" .. tostring(err or "?") ..
      "\n\nBitte prüfen, ob die Datei existiert und lauffähig ist.\nPfad: " .. router_path,
      "DF95 V76 SuperPipeline – ReampSuite",
      0
    )
    return
  end
end

---------------------------------------------------------
-- Main
---------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  local tracks = collect_selected_tracks()
  if #tracks == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\nBitte Fieldrec- und/oder Reamp-/DI-/Pedal-Tracks auswählen.",
      "DF95 V76 SuperPipeline",
      0
    )
    r.Undo_EndBlock("DF95 V76 SuperPipeline – keine Tracks", -1)
    return
  end

  local fieldrecTracks, reampTracks = split_tracks(tracks)

  -- 1) Fieldrec / Dialog / FX -> V72-Flow
  if #fieldrecTracks > 0 then
    run_v72_superpipeline_for_fieldrec(fieldrecTracks)
  end

  -- 2) Reamp-Kandidaten -> ReampSuite
  if #reampTracks > 0 then
    run_reampsuite_for_reamp_tracks(reampTracks)
  end

  r.Undo_EndBlock("DF95 V76.1 SuperPipeline (Fieldrec + ReampSuite + PedalChains Intelligence)", -1)
end

main()
