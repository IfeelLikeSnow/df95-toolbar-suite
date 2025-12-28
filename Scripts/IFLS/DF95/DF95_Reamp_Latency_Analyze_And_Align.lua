-- @description DF95: Reamp Latency – Analyze & Align (Dry vs Wet Items)
-- @version 1.0
-- @author DF95
-- @about
--   Analysiert die zeitliche Differenz zwischen einem Dry-Item und einem Reamp-Return-Item
--   anhand ihrer Item-Startpositionen und bietet Korrektur an:
--     - A) Wet-Item physisch verschieben
--     - B) Track-Delay am Return-Track setzen
--     - C) Nur anzeigen (keine Änderung)

local r = reaper

local function main()
  local cnt = r.CountSelectedMediaItems(0)
  if cnt ~= 2 then
    r.ShowMessageBox("Bitte genau ZWEI Items selektieren:\n1) Dry-Impuls\n2) Wet-Impuls (Reamp-Return)", "DF95 Reamp Latency", 0)
    return
  end

  local item_dry  = r.GetSelectedMediaItem(0, 0)
  local item_wet  = r.GetSelectedMediaItem(0, 1)

  local pos_dry = r.GetMediaItemInfo_Value(item_dry, "D_POSITION")
  local pos_wet = r.GetMediaItemInfo_Value(item_wet, "D_POSITION")

  local diff = pos_wet - pos_dry -- seconds (wet laggt gegenüber dry)
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr <= 0 then sr = 48000 end
  local samples = diff * sr
  local ms = diff * 1000.0

  local msg = string.format("Gemessene Latenz:\n\n  %.3f ms\n  %.1f Samples (bei %.0f Hz)\n\nWet-Item startet später als Dry-Item.\n\nKorrektur-Optionen:\nA) Wet-Item physisch um diese Zeit nach vorne verschieben.\nB) Track-Delay am Return-Track setzen (DLY= -%.3f ms).\nC) Nur anzeigen, keine Änderung.", ms, samples, sr, ms)

  local ok, ret = r.GetUserInputs("DF95 Reamp Latency – Aktion wählen", 1, "Aktion (A/B/C):", "")
  if not ok then return end
  ret = (ret or ""):upper()

  local tr_wet = r.GetMediaItem_Track(item_wet)

  r.Undo_BeginBlock()

  if ret == "A" then
    local new_pos = pos_wet - diff
    r.SetMediaItemInfo_Value(item_wet, "D_POSITION", new_pos)
    r.UpdateItemInProject(item_wet)
    r.ShowMessageBox(string.format("Wet-Item um %.3f ms (%.1f Samples) nach vorne verschoben.", ms, samples), "DF95 Reamp Latency", 0)
  elseif ret == "B" then
    local cur_dly = r.GetMediaTrackInfo_Value(tr_wet, "D_DLY") or 0.0
    local new_dly = cur_dly - diff
    r.SetMediaTrackInfo_Value(tr_wet, "D_DLY", new_dly)
    r.TrackList_AdjustWindows(false)
    r.ShowMessageBox(string.format("Track-Delay auf %.3f ms gesetzt (bisher %.3f ms).", new_dly*1000.0, cur_dly*1000.0), "DF95 Reamp Latency", 0)
  else
    r.ShowMessageBox(msg, "DF95 Reamp Latency – Info", 0)
  end

  r.Undo_EndBlock("DF95 Reamp Latency – Analyze & Align", -1)
end

main()
