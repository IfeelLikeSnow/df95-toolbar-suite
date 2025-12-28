-- @description DF95_V99_Fieldrec_OneClick_KitBeat
-- @version 1.0
-- @author DF95
-- @about
--   OneClick-Pipeline:
--     Fieldrec-Items -> V95.2 SplitEngine -> V98 SliceKit (RS5k) -> V97 BeatEngine MIDI
--   Ablauf:
--     1. Erwartet selektierte Fieldrec-Items (ein oder mehrere Tracks).
--     2. Ruft DF95_V95_2_Fieldrec_OneClick_SplitEngine.lua auf:
--        - Single-Mic vs. Multi-Mic wird automatisch erkannt.
--        - V95/V95.1 erzeugen Klassentracks (LOW_PERC, SNARE_PERC, HAT_CYMBAL,...).
--     3. Ruft DF95_V98_Fieldrec_SliceKitBuilder_RS5k.lua auf:
--        - Erzeugt Track "V98_SliceKit_RS5k" mit Kick/Snare/Hat-RS5k-Instanzen (36/38/42).
--     4. Ruft DF95_V97_Fieldrec_BeatEngine_MIDI.lua auf:
--        - Erzeugt Track "V97_Beat_MIDI" mit MIDI-Beat.
--     5. Verknüpft den MIDI-Track automatisch als Send zum Kit-Track.
--
--   Hinweis:
--     - Dieses Script ruft andere DF95-Scripts via dofile() auf.
--       Sie müssen im selben Ordner wie dieses Script liegen:
--         Scripts/IFLS/DF95/ReampSuite/

local r = reaper

local function msg(s)
  r.ShowMessageBox(s, "DF95 V99 OneClick KitBeat", 0)
end

local function get_script_dir()
  local info = debug.getinfo(1, "S")
  local script_path = info.source:match("^@(.+)$")
  return script_path:match("^(.*[\\/])") or ""
end

local function count_selected_audio_items()
  local cnt = 0
  local total = r.CountSelectedMediaItems(0)
  for i = 0, total-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      cnt = cnt + 1
    end
  end
  return cnt
end

local function run_child_script(name)
  local base_dir = get_script_dir()
  local path = base_dir .. name
  local f = io.open(path, "r")
  if not f then
    msg("Konnte Child-Script nicht finden:\n" .. path)
    return false
  end
  f:close()
  dofile(path)
  return true
end

local function find_track_by_name_exact(want_name)
  local proj = 0
  local n_tr = r.CountTracks(proj)
  for i = 0, n_tr-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if name == want_name then
      return tr
    end
  end
  return nil
end

local function ensure_midi_send_to_kit()
  local midi_tr = find_track_by_name_exact("V97_Beat_MIDI")
  local kit_tr  = find_track_by_name_exact("V98_SliceKit_RS5k")
  if not midi_tr or not kit_tr then
    -- nichts zu verbinden
    return
  end

  local send_idx = r.CreateTrackSend(midi_tr, kit_tr)
  if send_idx >= 0 then
    -- Optional: Audio aus Send deaktivieren, nur MIDI senden
    -- I_SRCCHAN = 1024 bedeutet "no audio"
    r.SetTrackSendInfo_Value(midi_tr, 0, send_idx, "I_SRCCHAN", 1024)
    -- MIDI: Standard ist "alle Kanäle", das lassen wir so (I_MIDIFLAGS = 0).
  end
end

local function main()
  if count_selected_audio_items() == 0 then
    msg("Bitte mindestens ein Fieldrec-Audio-Item auswählen.")
    return
  end

  r.Undo_BeginBlock()

  -- 1) V95.2 OneClick SplitEngine
  run_child_script("DF95_V95_2_Fieldrec_OneClick_SplitEngine.lua")

  -- 2) V98 SliceKit Builder
  run_child_script("DF95_V98_Fieldrec_SliceKitBuilder_RS5k.lua")

  -- 3) V97 BeatEngine MIDI (fragt Stil/Anzahl Takte ab)
  run_child_script("DF95_V97_Fieldrec_BeatEngine_MIDI.lua")

  -- 4) MIDI-Send von V97_Beat_MIDI -> V98_SliceKit_RS5k
  ensure_midi_send_to_kit()

  r.Undo_EndBlock("DF95 V99 OneClick Fieldrec -> Kit -> Beat", -1)
end

main()
