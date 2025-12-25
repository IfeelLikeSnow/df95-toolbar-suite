-- DF95_Insert_Drum_RR_Velocity_Mapper_OnSelectedTrack.lua
-- Phase 112: Helper Script, um den JSFX "IFLS Drum RR & Velocity Mapper" schnell
-- auf den ausgewählten Track zu legen.

local r = reaper

local function main()
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox(
      "Kein Track ausgewählt.\nBitte wähle den Drum-MIDI-Track aus und starte das Script erneut.",
      "DF95 Insert Drum RR & Velocity Mapper",
      0
    )
    return
  end

  local fx_name = "IFLS Drum RR & Velocity Mapper (Phase 112)"
  local fx_index = r.TrackFX_AddByName(tr, fx_name, false, -1)
  if fx_index < 0 then
    r.ShowMessageBox(
      "Konnte JSFX nicht finden:\n" .. fx_name ..
      "\nStelle sicher, dass die Datei\n" ..
      "  Effects/IFLS/IFLS_Drum_RR_Velocity_Mapper_Phase112.jsfx\n" ..
      "im REAPER-Resource-Ordner liegt.",
      "DF95 Insert Drum RR & Velocity Mapper",
      0
    )
    return
  end

  r.ShowMessageBox(
    "JSFX \"" .. fx_name .. "\" wurde dem ausgewählten Track hinzugefügt.\n\n" ..
    "Lege diesen Track VOR dein RS5k-Kit / Drum-Sampler,\n" ..
    "um RR- & Velocity-Mappings im MIDI zu steuern.",
    "DF95 Insert Drum RR & Velocity Mapper",
    0
  )
end

main()
