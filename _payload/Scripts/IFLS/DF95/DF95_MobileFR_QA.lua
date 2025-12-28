-- @description MobileFR QA Analyzer (Field Recorder App, S24 Ultra)
-- @version 1.0
-- @author DF95
-- @about
--   Analysiert die aktuell selektierten Items bzw. Items auf selektierten Tracks
--   für einen schnellen Qualitäts-Check:
--     * Peak-Level (Clipping-Gefahr)
--     * Grobe Lautheits-Einschätzung (sehr leise / sehr laut)
--   Optional wird SWS verwendet (BR_GetMediaItemMaxPeakAndMaxPeakPos), wenn vorhanden.
--
--   Dies ist kein Ersatz für ein vollständiges Mastering-Metering, sondern ein
--   praxisnaher „Ampel-Check“, ob MobileFR-Aufnahmen roh tauglich sind, um in
--   DF95 weiterverarbeitet / gesliced / exportiert zu werden.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function dB(v)
  if not v or v <= 0 then return -math.huge end
  return 20 * math.log(v, 10)
end

local function analyze_item_peak(item)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then
    return nil
  end

  local peak = nil

  if r.APIExists("BR_GetMediaItemMaxPeakAndMaxPeakPos") then
    local ok, max_peak, _, _, _, _ = r.BR_GetMediaItemMaxPeakAndMaxPeakPos(item, 0)
    if ok and max_peak then
      peak = max_peak
    end
  end

  -- Falls kein SWS vorhanden oder Peak nicht ermittelt:
  if not peak then
    -- Fallback: wir schätzen nichts und geben nil zurück
    return nil
  end

  return peak
end

local function analyze_items_for_track(tr)
  local item_count = r.CountTrackMediaItems(tr)
  for i = 0, item_count-1 do
    local item = r.GetTrackMediaItem(tr, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local src = r.GetMediaItemTake_Source(take)
      local sr = r.GetMediaSourceSampleRate(src) or 0
      local ch = r.GetMediaSourceNumChannels(src) or 0

      local _, tr_name = r.GetTrackName(tr, "")
      local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

      local peak = analyze_item_peak(item)
      local peak_db = peak and dB(peak) or nil

      msg(string.format("\n[DF95 MobileFR QA] Track='%s' Pos=%.2fs Len=%.2fs SR=%.0fHz Ch=%d",
                        tr_name, pos or 0, len or 0, sr, ch))

      if peak_db then
        msg(string.format("  Peak: %.1f dBFS", peak_db))
        if peak_db > -0.3 then
          msg("    WARNUNG: Peak sehr nah an 0 dBFS -> mögliche digitale Verzerrung.")
        elseif peak_db > -3.0 then
          msg("    Hinweis: Peak recht hoch, aber i. d. R. noch OK.")
        elseif peak_db < -18.0 then
          msg("    Hinweis: Aufnahme relativ leise -> evtl. Gain anheben.")
        end
      else
        msg("  Peak: (keine Peak-Analyse verfügbar, SWS nicht gefunden)")
      end

      -- Grobe Längenbewertung
      if len and len > 60 then
        msg("  Info: Lange Aufnahme (>60s) -> vermutlich Atmos/Room/LongTake.")
      elseif len and len < 0.25 then
        msg("  Info: Sehr kurzer Hit (<250ms) -> eher Perc/OneShot.")
      end

      -- Hinweis zu typischen MobileFR-Problemen
      msg("  Reminder: Prüfe bei MobileFR-Aufnahmen besonders:")
      msg("    * Rumpeln / Wind unter 80 Hz (HPF 70-90 Hz sinnvoll)")
      msg("    * Harschheit in 8-12 kHz (HF-Glättung / De-Harsh)")
      msg("    * Plosive / Pops (De-Pop / Low-Shelf-Korrektur)")
    end
  end
end

local function main()
  r.ShowConsoleMsg("") -- Console leeren
  msg("[DF95 MobileFR QA] Starte Analyse...")

  local num_sel_tr = r.CountSelectedTracks(0)
  local num_sel_items = r.CountSelectedMediaItems(0)

  if num_sel_tr == 0 and num_sel_items == 0 then
    msg("Keine Tracks oder Items selektiert. Bitte MobileFR-Items oder deren Tracks auswählen.")
    return
  end

  if num_sel_tr > 0 then
    for i = 0, num_sel_tr-1 do
      local tr = r.GetSelectedTrack(0, i)
      analyze_items_for_track(tr)
    end
  else
    -- nur selektierte Items
    for i = 0, num_sel_items-1 do
      local item = r.GetSelectedMediaItem(0, i)
      local tr = r.GetMediaItem_Track(item)
      analyze_items_for_track(tr)
    end
  end

  msg("\n[DF95 MobileFR QA] Analyse abgeschlossen.")
end

main()
