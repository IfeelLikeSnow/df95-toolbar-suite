\
-- @description DF95_V89_ReampSuite_AnalyzerBridge
-- @version 1.0
-- @author DF95
-- @about
--   Kleines Utility-Script:
--   - Fügt auf selektierten Tracks das JSFX "DF95_ReampSuite_Analyzer_FFT"
--     als Insert ein, falls noch nicht vorhanden.

local r = reaper

local function ensure_analyzer_on_track(tr)
  local fx_name = "DF95_ReampSuite_Analyzer_FFT"
  local fx_index = r.TrackFX_AddByName(tr, fx_name, false, 0)
  if fx_index >= 0 then
    return true
  end
  return false
end

local function main()
  local sel_cnt = r.CountSelectedTracks(0)
  if sel_cnt == 0 then
    r.ShowMessageBox("Bitte zuerst ReampReturn-Tracks selektieren.", "DF95 AnalyzerBridge", 0)
    return
  end
  local added = 0
  for i = 0, sel_cnt-1 do
    local tr = r.GetSelectedTrack(0, i)
    if ensure_analyzer_on_track(tr) then
      added = added + 1
    end
  end
  r.ShowMessageBox("Analyzer auf " .. tostring(added) .. " Track(s) sichergestellt.", "DF95 AnalyzerBridge", 0)
end

main()
