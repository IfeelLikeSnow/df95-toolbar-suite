-- @description DF95: Reamp Test Impulse – Generate on selected track
-- @version 1.0
-- @author DF95
-- @about
--   Erzeugt einen kurzen Test-Impuls (Click Source) auf dem aktuell selektierten Track.
--   Workflow:
--   - Wähle den Track, der in deinen Reamp-Send-Flow geht.
--   - Positioniere den Edit-Cursor an die gewünschte Stelle.
--   - Starte dieses Script: Es wird ein Click-Source-Item eingefügt.
--   - Spiele das Projekt ab und zeichne den Rückweg auf dem REAMP_RETURN-Track auf.

local r = reaper

local function main()
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox("Bitte wähle zuerst einen Track aus, auf dem der Testimpuls eingefügt werden soll.", "DF95 Reamp Test Impulse", 0)
    return
  end

  local cur_pos = r.GetCursorPosition()
  r.Main_OnCommand(40297, 0) -- Unselect all tracks
  r.SetTrackSelected(tr, true)
  r.SetEditCurPos(cur_pos, false, false)
  r.Main_OnCommand(40013, 0) -- Insert click source
end

r.Undo_BeginBlock()
main()
r.Undo_EndBlock("DF95: Reamp Test Impulse – Generate", -1)
