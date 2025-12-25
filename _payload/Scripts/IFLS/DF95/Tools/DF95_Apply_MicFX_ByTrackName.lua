-- DF95_Apply_MicFX_ByTrackName.lua
-- Einfache Variante: Nur JS:Gain + ReaEQ + ReaComp pro Mic-Track,
-- ohne spezifische EQ-Kurven (Neutral-Channelstrip)

local r = reaper

local ONLY_SELECTED = true

local MIC_NAME_MAP = {
  xm8500          = "XM8500",
  tgv35s          = "TG_V35S",
  tgv35           = "TG_V35S",
  md400           = "MD400",
  sennheisermd400 = "MD400",
  b1              = "B1",
  behringerb1     = "B1",
  ntg4            = "NTG4P",
  ntg4plus        = "NTG4P",
  ntg4p           = "NTG4P",
  c2              = "C2_MONO",
  c2mono          = "C2_MONO",
  c2stereo        = "C2_STEREO",
  geofon          = "GEOFON",
  lomgeofon       = "GEOFON",
  ether           = "ETHER",
  somaether       = "ETHER",
  cm300           = "CM300_MONO",
  cm300stereo     = "CM300_STEREO",
  cortado         = "CORTADO_MONO",
  cortadomkiii    = "CORTADO_MONO",
  cortadostereo   = "CORTADO_STEREO",
  mcm             = "MCM_TELECOIL_MONO",
  mcmtelecoil     = "MCM_TELECOIL_MONO",
}

local function normalize_name(s)
  s = (s or ""):lower()
  s = s:gsub("ä","ae"):gsub("ö","oe"):gsub("ü","ue"):gsub("ß","ss")
  s = s:gsub("[^a-z0-9]+","")
  return s
end

local function add_neutral_chain(track)
  if not track then return end
  r.TrackFX_AddByName(track, "VST: JS: Utility/gain", false, -1000)
  r.TrackFX_AddByName(track, "VST: ReaEQ (Cockos)", false, -1000)
  r.TrackFX_AddByName(track, "VST: ReaComp (Cockos)", false, -1000)
end

local function should_process_track(tr)
  if not ONLY_SELECTED then return true end
  return r.IsTrackSelected(tr)
end

local function main()
  local proj = 0
  local track_count = r.CountTracks(proj)
  if track_count == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local processed = 0

  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    if should_process_track(tr) then
      local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      local key = normalize_name(name)
      local mic_key = MIC_NAME_MAP[key]
      if mic_key then
        add_neutral_chain(tr)
        local new_name = (name or "") .. " [Mic:" .. mic_key .. "]"
        r.GetSetMediaTrackInfo_String(tr, "P_NAME", new_name, true)
        processed = processed + 1
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Apply MicFX By TrackName (neutral)", -1)

  if processed == 0 then
    r.ShowMessageBox(
      "Keine passenden Mic-Namen auf selektierten Tracks gefunden.",
      "DF95 MicFX (neutral)",
      0
    )
  end
end

main()
