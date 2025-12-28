
-- @description DF95_V80_ReampSuite_AutoSession
-- @version 1.0
-- @author DF95
-- @about
--   Vollautomatisierter Reamp-Session-Flow auf Basis von V76–V79:
--   - Selektierte DI-/Reamp-Quellen analysieren (Länge bestimmen)
--   - V79 OneClickReamp aufrufen (Routing + PedalChain Intelligence)
--   - ReampReturn-Tracks finden
--   - Transport: Record starten, bis das DI-Fenster abgespielt ist
--   - Danach optional:
--       * Latenz-Offset automatisch anwenden (V76.2)
--       * AutoGain (V78) zur Kalibrierung ausführen
--   - Cursor/Time-Selection wiederherstellen
--
--   Ziel: "Reamp diese Quellen einmal komplett" als eine einzige Action.
--
--   Hinweis:
--     - Die Aufnahme erfolgt im normalen REAPER-Transport.
--     - Es wird eine Time Selection über die DI-Region gelegt und bei Erreichen
--       des Endes automatisch gestoppt.
--     - Das Script nutzt reaper.defer(), läuft also während der Aufnahme weiter.

local r = reaper

---------------------------------------------------------
-- User Settings
---------------------------------------------------------

-- Wie viel "Tail" nach Ende der DI-Region noch mit aufgenommen werden soll (Sekunden)
local TAIL_SECONDS = 0.5

-- Soll nach der Aufnahme automatisch der Latenz-Offset angewendet werden?
local RUN_LATENCY_AUTOAPPLY = true

-- Soll nach der Aufnahme automatisch AutoGain ausgeführt werden?
-- Hinweis: AutoGain ist primär zur Profil-Kalibrierung gedacht.
local RUN_AUTOGAIN_AFTER = false


---------------------------------------------------------
-- Helpers
---------------------------------------------------------

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

local function collect_selected_tracks()
  local t = {}
  local cnt = r.CountSelectedTracks(0)
  for i = 0, cnt - 1 do
    t[#t+1] = r.GetSelectedTrack(0, i)
  end
  return t
end

local function is_reamp_candidate_name(name)
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

local function filter_reamp_candidates(tracks)
  local out = {}
  for _, tr in ipairs(tracks) do
    if is_reamp_candidate_name(get_track_name(tr)) then
      out[#out+1] = tr
    end
  end
  return out
end

local function compute_items_bounds_for_tracks(tracks)
  local min_pos, max_end = nil, nil

  for _, tr in ipairs(tracks) do
    local item_cnt = r.CountTrackMediaItems(tr)
    for i = 0, item_cnt - 1 do
      local it = r.GetTrackMediaItem(tr, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
      local fin = pos + len
      if not min_pos or pos < min_pos then min_pos = pos end
      if not max_end or fin > max_end then max_end = fin end
    end
  end

  return min_pos, max_end
end

local function find_reampreturn_tracks()
  local t = {}
  local cnt = r.CountTracks(0)
  for i = 0, cnt - 1 do
    local tr = r.GetTrack(0, i)
    local name = get_track_name(tr)
    if name:match("^ReampReturn_") or name:match("ReampReturn") then
      t[#t+1] = tr
    end
  end
  return t
end

local function save_time_selection()
  local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  return start, fin
end

local function restore_time_selection(start, fin)
  if start and fin then
    r.GetSet_LoopTimeRange(true, false, start, fin, false)
  end
end

local function save_cursor_position()
  return r.GetCursorPosition()
end

local function restore_cursor_position(pos)
  if pos then r.SetEditCurPos(pos, false, false) end
end

local function select_only_tracks(tracks)
  r.Main_OnCommand(40297, 0) -- Unselect all tracks
  for _, tr in ipairs(tracks) do
    r.SetTrackSelected(tr, true)
  end
end

local function array_clone(t)
  local n = {}
  for i, v in ipairs(t) do n[i] = v end
  return n
end

---------------------------------------------------------
-- State für defer-Loop
---------------------------------------------------------

local SessionState = {
  is_running = false,
  record_started = false,
  record_stopped = false,
  ts_start = nil,
  ts_end = nil,
  old_ts_start = nil,
  old_ts_end = nil,
  old_cursor = nil,
  reamp_tracks = nil,
}

local function end_session_cleanup()
  -- Optionale Post-Processing-Schritte
  if RUN_LATENCY_AUTOAPPLY then
    local apply_path = df95_root() .. "ReampSuite/DF95_ReampSuite_ApplyLatencyOffset.lua"
    local ok, err = pcall(dofile, apply_path)
    if not ok then
      r.ShowMessageBox("Fehler beim Ausführen von DF95_ReampSuite_ApplyLatencyOffset.lua:\n" .. tostring(err or "?"),
        "DF95 V80 AutoSession – LatencyApply Fehler", 0)
    end
  end

  if RUN_AUTOGAIN_AFTER then
    local ag_path = df95_root() .. "ReampSuite/DF95_ReampSuite_AutoGain.lua"
    local ok, err = pcall(dofile, ag_path)
    if not ok then
      r.ShowMessageBox("Fehler beim Ausführen von DF95_ReampSuite_AutoGain.lua:\n" .. tostring(err or "?"),
        "DF95 V80 AutoSession – AutoGain Fehler", 0)
    end
  end

  -- Time Selection & Cursor wiederherstellen
  restore_time_selection(SessionState.old_ts_start, SessionState.old_ts_end)
  restore_cursor_position(SessionState.old_cursor)

  SessionState.is_running = false
end

local function session_loop()
  if not SessionState.is_running then return end

  local play_state = r.GetPlayState()
  local pos = r.GetPlayPosition()

  if not SessionState.record_started then
    -- Record starten
    r.Main_OnCommand(1013, 0) -- Transport: Record
    SessionState.record_started = true
  else
    -- Wenn nicht mehr aufnimmt (User hat z. B. manuell abgebrochen), beenden
    if (play_state & 4) ~= 4 then
      SessionState.record_stopped = true
    end

    -- Aufnahme läuft: prüfen, ob wir über das Ende hinaus sind
    if (play_state & 4) == 4 and SessionState.ts_end and pos >= SessionState.ts_end then
      r.Main_OnCommand(1013, 0) -- Record stoppen
      SessionState.record_stopped = true
    end
  end

  if SessionState.record_stopped then
    end_session_cleanup()
    return
  end

  r.defer(session_loop)
end

---------------------------------------------------------
-- Main
---------------------------------------------------------

local function main()
  if SessionState.is_running then
    r.ShowMessageBox("Eine DF95 AutoSession läuft bereits.", "DF95 V80 ReampSuite AutoSession", 0)
    return
  end

  -- 1) Selektierte Tracks einsammeln
  local sel_tracks = collect_selected_tracks()
  if #sel_tracks == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\n\nBitte zuerst die DI-/Reamp-Quellen-Tracks auswählen.",
      "DF95 V80 ReampSuite AutoSession",
      0
    )
    return
  end

  local reamp_sources = filter_reamp_candidates(sel_tracks)
  if #reamp_sources == 0 then
    r.ShowMessageBox(
      "Unter den selektierten Tracks wurden keine Reamp-Kandidaten gefunden.\n\n" ..
      "Erwartet: Namen mit REAMP, RE-AMP, DI oder PEDAL.",
      "DF95 V80 ReampSuite AutoSession",
      0
    )
    return
  end

  -- 2) Bounds der DI-Region bestimmen
  local di_start, di_end = compute_items_bounds_for_tracks(reamp_sources)
  if not di_start or not di_end or di_start == di_end then
    r.ShowMessageBox(
      "Konnte keine sinnvolle Item-Länge auf den Reamp-Quellen ermitteln.\n\n" ..
      "Bitte sicherstellen, dass auf den Tracks Items mit Audio vorhanden sind.",
      "DF95 V80 ReampSuite AutoSession",
      0
    )
    return
  end

  local ts_start = di_start
  local ts_end = di_end + TAIL_SECONDS

  -- 3) Alte Time Selection & Cursor sichern
  local old_ts_start, old_ts_end = save_time_selection()
  local old_cursor = save_cursor_position()

  -- 4) OneClickReamp ausführen (richtet Routing + ReampReturn ein)
  local v79_path = df95_root() .. "ReampSuite/DF95_V79_ReampSuite_OneClickReamp.lua"
  local ok79, err79 = pcall(dofile, v79_path)
  if not ok79 then
    r.ShowMessageBox(
      "DF95_V79_ReampSuite_OneClickReamp.lua konnte nicht ausgeführt werden:\n" .. tostring(err79 or "?") ..
      "\n\nBitte prüfen, ob die Datei existiert und lauffähig ist.\nPfad: " .. v79_path,
      "DF95 V80 ReampSuite AutoSession – Fehler in V79",
      0
    )
    return
  end

  -- 5) ReampReturn-Tracks einsammeln (für AutoOffset/AutoGain relevant)
  local reamp_returns = find_reampreturn_tracks()
  if #reamp_returns == 0 then
    r.ShowMessageBox(
      "Es wurden keine ReampReturn-Tracks gefunden.\n\n" ..
      "Bitte prüfen, ob der ReampSuite Router korrekt ausgeführt wurde.",
      "DF95 V80 ReampSuite AutoSession",
      0
    )
    return
  end

  -- 6) Time Selection setzen & Cursor an den Start
  r.GetSet_LoopTimeRange(true, false, ts_start, ts_end, false)
  r.SetEditCurPos(ts_start, true, false)

  -- 7) ReampReturn-Tracks für die Nachbearbeitung vormerken
  SessionState.is_running      = true
  SessionState.record_started  = false
  SessionState.record_stopped  = false
  SessionState.ts_start        = ts_start
  SessionState.ts_end          = ts_end
  SessionState.old_ts_start    = old_ts_start
  SessionState.old_ts_end      = old_ts_end
  SessionState.old_cursor      = old_cursor
  SessionState.reamp_tracks    = array_clone(reamp_returns)

  -- 8) Für AutoOffset/AutoGain die ReampReturn-Tracks selektieren
  select_only_tracks(reamp_returns)

  -- 9) Record + Loop starten
  session_loop()
end

main()
