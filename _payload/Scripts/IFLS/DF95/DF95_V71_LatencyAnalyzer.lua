
-- @description DF95 V71 Latency Analyzer – Testimpuls Helper
-- @version 1.0
-- @author DF95
--
-- Ziel:
--  - Einen einfachen Worklfow bereitstellen, um die Reamp-Latenz manuell zu messen:
--    1. Generiert einen kurzen Klick/Testimpuls auf einem neuen Track.
--    2. User startet Reamp-Aufnahme über den Return-Track.
--    3. Script zeigt Hinweise, wie man anhand der Wellenformen die Latenz (Samples/ms) abliest
--       und ggf. in ein DF95_REAMP/OFFSET_SAMPLES ExtState einträgt.
--
-- Dies ist bewusst als "guided manual" Tool implementiert, da DSP/FFT hier
-- nicht zuverlässig verfügbar ist.

local r = reaper

local function create_impulse_track()
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95_Reamp_TestImpulse", true)
  return tr
end

local function add_impulse_item(tr)
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr <= 0 then sr = 48000 end
  local length = 0.1 -- 100 ms
  local item = r.AddMediaItemToTrack(tr)
  r.SetMediaItemInfo_Value(item, "D_POSITION", 0.0)
  r.SetMediaItemInfo_Value(item, "D_LENGTH", length)
  -- Wir nutzen ein extrem simples Midi/Click-Konstrukt nicht; stattdessen
  -- lassen wir den User z. B. einen JSFX "Click" oder Tone-Generator einsetzen.
  return item
end

local function main()
  r.Undo_BeginBlock()

  local tr = create_impulse_track()
  local item = add_impulse_item(tr)

  r.Undo_EndBlock("DF95 V71 Latency Analyzer – Testimpuls vorbereitet", -1)

  r.ShowMessageBox(
    "Ein Testimpuls-Track 'DF95_Reamp_TestImpulse' wurde erstellt.\n\n" ..
    "Vorschlag:\n" ..
    "1. Füge auf diesem Track einen kurzen Click/Tone (z.B. JS: Tone Generator + Gate) ein,\n" ..
    "   sodass ein klarer Peak zu sehen ist.\n" ..
    "2. Route diesen Track wie dein typischer Reamp-Source-Track (z.B. über DF95 Reamp Router).\n" ..
    "3. Starte Aufnahme auf dem Reamp-Return-Track.\n" ..
    "4. Vergleiche die Position des Peaks (Original vs. Return):\n" ..
    "   - Differenz in Samples oder ms bestimmen (per Item-Properties/Peak-Zoom).\n" ..
    "5. Trage diesen Wert in einen ExtState ein:\n" ..
    "   DF95_REAMP / OFFSET_SAMPLES\n" ..
    "   Dieser kann später in Reamp-Tools genutzt werden, um Items automatisch zu verschieben.",
    "DF95 V71 Latency Analyzer – Anleitung", 0)
end

main()
