-- @description DF95: Reamp Test & Align Wizard (One-Button Workflow)
-- @version 1.0
-- @author DF95
-- @about
--   Einfache Ein-Knopf-Hilfe für Reamp-Latenz:
--   - Wenn noch kein Wet-Impuls gefunden wurde:
--       * erzeugt einen Testimpuls (Click-Source) auf dem selektierten REAMP_SEND-Track
--         oder der aktuellen Dry-Quelle
--       * zeigt eine kurze Anleitung zum Aufnehmen des Returns
--   - Wenn bereits ein Dry- und ein Wet-Impuls im Projekt vorhanden sind:
--       * findet automatisch das zuletzt erzeugte Dry-Impuls-Item
--       * findet das passende Wet-Item auf dem REAMP_RETURN-Track
--       * berechnet die Latenz und bietet A/B/C (Verschieben / Track-Delay / Nur anzeigen) an.

local r = reaper

local function find_last_click_item()
  local found_item = nil
  local found_pos = -1
  local num_tracks = r.CountTracks(0)
  for ti=0,num_tracks-1 do
    local tr = r.GetTrack(0,ti)
    local item_cnt = r.CountTrackMediaItems(tr)
    for ii=0,item_cnt-1 do
      local it = r.GetTrackMediaItem(tr, ii)
      local take = r.GetActiveTake(it)
      if take then
        local src = r.GetMediaItemTake_Source(take)
        local src_type = r.GetMediaSourceType(src, "")
        if src_type == "CLICK" then
          local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
          if pos > found_pos then
            found_pos = pos
            found_item = it
          end
        end
      end
    end
  end
  return found_item, found_pos
end

local function find_last_item_on_reamp_return(after_pos)
  local best_item = nil
  local best_pos = -1
  local num_tracks = r.CountTracks(0)
  for ti=0,num_tracks-1 do
    local tr = r.GetTrack(0,ti)
    local ok, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if ok and name:match("^REAMP_RETURN") then
      local item_cnt = r.CountTrackMediaItems(tr)
      for ii=0,item_cnt-1 do
        local it = r.GetTrackMediaItem(tr, ii)
        local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
        if pos >= after_pos and pos > best_pos then
          best_pos = pos
          best_item = it
        end
      end
    end
  end
  return best_item, best_pos
end

local function analyze_and_align(dry_item, wet_item)
  local pos_dry = r.GetMediaItemInfo_Value(dry_item, "D_POSITION")
  local pos_wet = r.GetMediaItemInfo_Value(wet_item, "D_POSITION")

  local diff = pos_wet - pos_dry
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr <= 0 then sr = 48000 end
  local samples = diff * sr
  local ms = diff * 1000.0

  local msg = string.format("Gemessene Latenz:\n\n  %.3f ms\n  %.1f Samples (bei %.0f Hz)\n\nWet-Item startet später als Dry-Item.\n\nKorrektur-Optionen:\nA) Wet-Item physisch um diese Zeit nach vorne verschieben.\nB) Track-Delay am Return-Track setzen (DLY= -%.3f ms).\nC) Nur anzeigen, keine Änderung.", ms, samples, sr, ms)

  local ok, ret = r.GetUserInputs("DF95 Reamp Test & Align – Aktion wählen", 1, "Aktion (A/B/C):", "")
  if not ok then return end
  ret = (ret or ""):upper()

  local tr_wet = r.GetMediaItem_Track(wet_item)

  r.Undo_BeginBlock()

  if ret == "A" then
    local new_pos = pos_wet - diff
    r.SetMediaItemInfo_Value(wet_item, "D_POSITION", new_pos)
    r.UpdateItemInProject(wet_item)
    r.ShowMessageBox(string.format("Wet-Item um %.3f ms (%.1f Samples) nach vorne verschoben.", ms, samples), "DF95 Reamp Test & Align", 0)
  elseif ret == "B" then
    local cur_dly = r.GetMediaTrackInfo_Value(tr_wet, "D_DLY") or 0.0
    local new_dly = cur_dly - diff
    r.SetMediaTrackInfo_Value(tr_wet, "D_DLY", new_dly)
    r.TrackList_AdjustWindows(false)
    r.ShowMessageBox(string.format("Track-Delay auf %.3f ms gesetzt (bisher %.3f ms).", new_dly*1000.0, cur_dly*1000.0), "DF95 Reamp Test & Align", 0)
  else
    r.ShowMessageBox(msg, "DF95 Reamp Test & Align – Info", 0)
  end

  r.Undo_EndBlock("DF95 Reamp Test & Align", -1)
end

local function main()
  -- Versuche, Dry- und Wet-Item zu finden
  local dry_item, dry_pos = find_last_click_item()
  if dry_item then
    local wet_item, wet_pos = find_last_item_on_reamp_return(dry_pos)
    if wet_item then
      analyze_and_align(dry_item, wet_item)
      return
    end
  end

  -- Falls kein Wet-Impuls gefunden wurde: Testimpuls erzeugen
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox("Kein Wet-Impuls gefunden und kein Track selektiert.\n\nBitte:\n1) Einen Dry-/Send-Track selektieren.\n2) Dieses Script erneut starten, um einen Testimpuls zu erzeugen.\n3) Danach Reamp-Return aufnehmen und das Script ein drittes Mal ausführen, um auszuwerten.", "DF95 Reamp Test & Align", 0)
    return
  end

  local cur_pos = r.GetCursorPosition()
  r.Main_OnCommand(40297, 0) -- alle Tracks deselektieren
  r.SetTrackSelected(tr, true)
  r.SetEditCurPos(cur_pos, false, false)
  r.Main_OnCommand(40013, 0) -- Click-Quelle einfügen

  r.ShowMessageBox("Testimpuls wurde auf dem selektierten Track eingefügt.\n\nNächste Schritte:\n1) Spiele das Projekt ab und zeichne den Reamp-Return auf einem REAMP_RETURN-Track auf.\n2) Starte dieses Script erneut: Dry/Wet werden automatisch gefunden und können ausgerichtet werden.", "DF95 Reamp Test & Align", 0)
end

main()
