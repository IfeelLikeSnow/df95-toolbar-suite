
-- @description DF95_ReampSuite_ApplyLatencyOffset
-- @version 1.0
-- @author DF95
-- @about
--   Wendet die gemessene Reamp-Latenz (OFFSET_SAMPLES_<PROFILE>) automatisch
--   auf die Items der ReampReturn-Tracks an.
--
--   Voraussetzungen:
--     - Reamp-Profile sind über DF95_ReampSuite_Profiles.lua definiert.
--     - Du hast mit DF95_V71_LatencyAnalyzer.lua bzw. DF95_ReampSuite_LatencyHelper.lua
--       für dein aktives Profil einen OFFSET_SAMPLES_<PROFILE>-Wert im Namespace
--       DF95_REAMP gespeichert.
--
--   Funktionsweise (Standard-Workflow):
--     1. Aktives Profil wird aus DF95_ReampSuite_Profiles.lua gelesen.
--     2. Dazu passender OFFSET_SAMPLES_<PROFILE> wird aus DF95_REAMP gelesen.
--     3. Ziel-Tracks:
--          - Wenn Tracks selektiert sind: genau diese.
--          - Wenn keine Tracks selektiert sind: alle Tracks, deren Name mit
--            "ReampReturn_" beginnt.
--     4. Alle Items auf diesen Tracks werden um (OFFSET_SAMPLES / Samplerate) Sekunden
--        nach vorne verschoben (d. h. die Latenz wird kompensiert).
--
--   Hinweis:
--     - Positive OFFSET_SAMPLES-Werte werden als "Reamp-Signal kommt zu spät" interpretiert.
--       Entsprechend werden die Items nach vorne (Richtung Projekt-Beginn) verschoben.
--     - Wenn du negative Werte speicherst, werden die Items nach hinten verschoben.
--     - Positionswerte < 0 werden auf 0 geklemmt.

local r = reaper

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

local function collect_target_tracks()
  local targets = {}

  local sel_cnt = r.CountSelectedTracks(0)
  if sel_cnt > 0 then
    for i = 0, sel_cnt - 1 do
      targets[#targets+1] = r.GetSelectedTrack(0, i)
    end
    return targets, true
  end

  -- keine selektierten Tracks -> alle ReampReturn_*-Tracks
  local tr_cnt = r.CountTracks(0)
  for i = 0, tr_cnt - 1 do
    local tr = r.GetTrack(0, i)
    local name = get_track_name(tr)
    if name:match("^ReampReturn_") or name:match("ReampReturn") then
      targets[#targets+1] = tr
    end
  end

  return targets, false
end

local function get_project_samplerate()
  -- versucht, die Projekt-Samplerate zu lesen; wenn 0 -> Device SR
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr and sr > 0 then
    return sr
  end
  -- Fallback: aktuelle Audio-Device Samplerate
  local ok, s = r.GetAudioDeviceInfo("SRATE", "")
  if ok and s and s ~= "" then
    local num = tonumber(s)
    if num and num > 0 then return num end
  end
  return 44100 -- worst-case Fallback
end

local function apply_offset_to_items_on_tracks(tracks, offset_samples)
  if not tracks or #tracks == 0 then return 0 end

  local sr = get_project_samplerate()
  local offset_sec = offset_samples / sr

  local moved = 0

  for _, tr in ipairs(tracks) do
    local item_cnt = r.CountTrackMediaItems(tr)
    for i = 0, item_cnt - 1 do
      local it = r.GetTrackMediaItem(tr, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local new_pos = pos - offset_sec  -- positive Offset -> nach vorne schieben

      if new_pos < 0 then new_pos = 0 end

      if math.abs(new_pos - pos) > 0.0000001 then
        r.SetMediaItemInfo_Value(it, "D_POSITION", new_pos)
        moved = moved + 1
      end
    end
  end

  return moved
end

---------------------------------------------------------
-- Main
---------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  local profiles_path = df95_root() .. "ReampSuite/DF95_ReampSuite_Profiles.lua"
  local profiles_mod, err = safe_require(profiles_path)
  if not profiles_mod or type(profiles_mod) ~= "table" or type(profiles_mod.get_active_key) ~= "function" then
    r.ShowMessageBox(
      "Konnte DF95_ReampSuite_Profiles.lua nicht laden.\n\nFehler: " .. tostring(err or "?") ..
      "\nPfad: " .. profiles_path,
      "DF95 ReampSuite – ApplyLatencyOffset",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset (Fehler: Profiles)", -1)
    return
  end

  local active_key = profiles_mod.get_active_key()
  if not active_key or active_key == "" then
    r.ShowMessageBox(
      "Kein aktives Reamp-Profil gefunden.\n\nBitte zuerst im ReampSuite-Router ein Profil wählen.",
      "DF95 ReampSuite – ApplyLatencyOffset",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset (kein Profil)", -1)
    return
  end

  local ext_ns = "DF95_REAMP"
  local ext_key = "OFFSET_SAMPLES_" .. tostring(active_key)
  local offset_str = r.GetExtState(ext_ns, ext_key)

  if not offset_str or offset_str == "" then
    r.ShowMessageBox(
      string.format(
        "Für das aktive Profil '%s' ist kein OFFSET_SAMPLES-Wert gesetzt.\n\n" ..
        "Bitte einmal den DF95_V71_LatencyAnalyzer (oder den ReampSuite LatencyHelper) ausführen\n" ..
        "und anschließend einen Wert im Namespace DF95_REAMP speichern:\n\n" ..
        "Key: %s\nBeispiel: %s = 128",
        tostring(active_key), ext_key, ext_key
      ),
      "DF95 ReampSuite – ApplyLatencyOffset",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset (kein Offset)", -1)
    return
  end

  local offset_samples = tonumber(offset_str)
  if not offset_samples then
    r.ShowMessageBox(
      string.format(
        "OFFSET_SAMPLES-Wert für Profil '%s' ist keine gültige Zahl:\n\n%s = '%s'",
        tostring(active_key), ext_key, tostring(offset_str)
      ),
      "DF95 ReampSuite – ApplyLatencyOffset",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset (ungültiger Wert)", -1)
    return
  end

  if offset_samples == 0 then
    r.ShowMessageBox(
      string.format(
        "OFFSET_SAMPLES_%s ist 0.\n\nEs gibt nichts zu verschieben.",
        tostring(active_key)
      ),
      "DF95 ReampSuite – ApplyLatencyOffset",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset (Offset = 0)", -1)
    return
  end

  local tracks, from_selection = collect_target_tracks()
  if not tracks or #tracks == 0 then
    r.ShowMessageBox(
      "Keine Ziel-Tracks gefunden.\n\n" ..
      "Bitte entweder ReampReturn-Tracks selektieren oder sicherstellen,\n" ..
      "dass die ReampReturn-Tracks mit 'ReampReturn_' beginnen.",
      "DF95 ReampSuite – ApplyLatencyOffset",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset (keine Tracks)", -1)
    return
  end

  local moved = apply_offset_to_items_on_tracks(tracks, offset_samples)
  r.UpdateArrange()

  local msg
  if moved > 0 then
    msg = string.format(
      "Latency-Offset angewendet.\n\nProfil: %s\nOffset: %d Samples\n" ..
      "Betroffene Tracks: %d\nVerschobene Items: %d\n\n" ..
      "Hinweis: Positive Offset-Werte wurden nach vorne (Richtung Projekt-Start) verschoben.",
      tostring(active_key), offset_samples, #tracks, moved
    )
  else
    msg = string.format(
      "Keine Items verschoben.\n\nProfil: %s\nOffset: %d Samples\n" ..
      "Prüfe bitte, ob auf den Ziel-Tracks Items vorhanden sind.",
      tostring(active_key), offset_samples
    )
  end

  r.ShowMessageBox(msg, "DF95 ReampSuite – ApplyLatencyOffset", 0)
  r.Undo_EndBlock("DF95 ReampSuite – ApplyLatencyOffset", -1)
end

main()
