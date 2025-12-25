--[[
DF95 - AI FXChain FullAuto Track-Selection Watcher (Lua/ReaScript)

Option 5: Auto-Trigger durch Track-Selektion.

Idee:
- Dieses Script läuft im Hintergrund (defer loop).
- Es beobachtet die Track-Selektion.
- Wenn sich die Selektion ändert, kann automatisch die FullAuto-AI-FXChain-Action gestartet werden,
  z.B. "DF95_AI_FXChain_FullAuto_From_AIResult.lua".

Voraussetzungen:
- "DF95_AI_FXChain_FullAuto_From_AIResult.lua" ist als Action registriert.
- In diesem Script ist die entsprechende Command-ID konfiguriert.
- Die FullAuto-Action arbeitet wie gewohnt auf der aktuellen Track-Selektion,
  liest Data/DF95/ai_fxchains_result.json und wendet die empfohlene FXChain an.

Typischer Einsatz:
- Du startest dieses Script einmal (z.B. über ein Toolbar-Button "AI Follow Selection").
- Danach: immer wenn du eine neue Spur oder andere Spuren selektierst,
  wird automatisch die KI-FXChain angewendet (abhängig von deinem AI-Result-JSON).
]]--

-- @description DF95 - AI FXChain FullAuto TrackSelection Watcher
-- @version 1.0
-- @author DF95 / Reaper DAW Ultimate Assistant
-- @about Watches track selection and triggers FullAuto AI FXChain action when selection changes.

local r = reaper

-------------------------------------------------------
-- KONFIGURATION
-------------------------------------------------------

-- Command-ID deiner "DF95_AI_FXChain_FullAuto_From_AIResult"-Action.
-- So bekommst du sie:
--   1. In der Actions-Liste "DF95_AI_FXChain_FullAuto_From_AIResult" suchen
--   2. Rechtsklick → "Copy selected action command ID"
--   3. Den String (z.B. "_RS1234567890abcdef") hier eintragen.
local FULLAUTO_ACTION_COMMAND_ID = ""  -- <-- HIER EINTRAGEN

-- Minimaler Abstand zwischen zwei Auto-Triggern in Sekunden
local MIN_TRIGGER_INTERVAL = 0.5

-- Optional: Nur triggern, wenn GENAU eine Spur selektiert ist?
local ONLY_SINGLE_TRACK = false

-- Optional: Nur triggern, wenn Track-Name einen bestimmten Marker enthält (z.B. "[AI]")
local REQUIRE_NAME_MARKER = ""   -- z.B. "[AI]" oder leer, um alles zuzulassen

-------------------------------------------------------
-- Utility
-------------------------------------------------------

local function log(msg)
  r.ShowConsoleMsg("[DF95 TrackSelect AI] " .. tostring(msg) .. "\n")
end

local function msgbox(msg)
  r.ShowMessageBox(tostring(msg), "DF95 TrackSelect AI", 0)
end

local function validate_fullauto_action()
  if not FULLAUTO_ACTION_COMMAND_ID or FULLAUTO_ACTION_COMMAND_ID == "" then
    msgbox("FULLAUTO_ACTION_COMMAND_ID ist nicht gesetzt.\n\nBitte in 'DF95_AI_FXChain_FullAuto_TrackSelect.lua' oben im Script bearbeiten und die Command-ID deiner 'DF95_AI_FXChain_FullAuto_From_AIResult'-Action eintragen.")
    return nil
  end
  local cmd = r.NamedCommandLookup(FULLAUTO_ACTION_COMMAND_ID)
  if cmd == 0 then
    msgbox("Konnte FullAuto-Action nicht auflösen.\n\nGeprüft wurde:\n" .. tostring(FULLAUTO_ACTION_COMMAND_ID) .. "\n\nBitte in der Actions-Liste nach 'DF95_AI_FXChain_FullAuto_From_AIResult' suchen und die Command-ID neu eintragen.")
    return nil
  end
  return cmd
end

local function get_track_guid(tr)
  local _, guid = r.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
  return guid or ""
end

local function track_name_contains_marker(tr, marker)
  if not marker or marker == "" then return true end
  local _, name = r.GetTrackName(tr, "")
  if not name then return false end
  return name:lower():find(marker:lower(), 1, true) ~= nil
end

local function get_selection_signature()
  local count = r.CountSelectedTracks(0)
  if ONLY_SINGLE_TRACK and count ~= 1 then
    return "NOSIG_SINGLE"
  end

  if count == 0 then
    return "NOSIG"
  end

  local guids = {}
  for i = 0, count-1 do
    local tr = r.GetSelectedTrack(0, i)
    if tr then
      if not track_name_contains_marker(tr, REQUIRE_NAME_MARKER) then
        -- Wenn ein Track nicht den Marker erfüllt, brechen wir ab (kein gültiges Ziel)
        return "NOSIG_MARKER"
      end
      guids[#guids+1] = get_track_guid(tr)
    end
  end

  table.sort(guids)
  return table.concat(guids, ";")
end

-------------------------------------------------------
-- Hauptlogik (defer loop)
-------------------------------------------------------

local last_sig = nil
local last_trigger_time = 0.0
local fullauto_cmd = validate_fullauto_action()
if not fullauto_cmd then
  return
end

local function loop()
  local now = r.time_precise()

  local sig = get_selection_signature()

  if sig ~= last_sig then
    -- Selektion hat sich geändert (oder ist jetzt gültig)
    last_sig = sig

    if sig ~= "NOSIG" and sig ~= "NOSIG_SINGLE" and sig ~= "NOSIG_MARKER" then
      if now - last_trigger_time >= MIN_TRIGGER_INTERVAL then
        -- Trigger FullAuto-Action
        log("Track-Selektion geändert, starte FullAuto-Action (Sig=" .. sig .. ")")
        r.Main_OnCommand(fullauto_cmd, 0)
        last_trigger_time = now
      else
        log("Track-Selektion geändert, aber innerhalb des MIN_TRIGGER_INTERVAL – kein Auto-Trigger.")
      end
    end
  end

  r.defer(loop)
end

log("DF95 TrackSelection AI Watcher gestartet. Warte auf Track-Selektion...")
r.Undo_BeginBlock()
loop()
r.Undo_EndBlock("DF95: AI FXChain FullAuto TrackSelection Watcher (start)", -1)
