-- @description Reset Track Colors (All Tracks)
-- @version 1.0
-- @author DF95
-- @about
--   Setzt die Trackfarben aller Tracks auf das Reaper-Standardgrau zurück.
--   Sinnvoll in Kombination mit "AutoColor – Tracks & Busses by Role",
--   um komplexe Sessions schnell neu einfärben zu können.

local r = reaper

local function main()
  local proj = 0
  local track_count = r.CountTracks(proj)
  if track_count == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    r.SetTrackColor(tr, 0) -- 0 = Default-Farbe verwenden
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("Reset Track Colors (All Tracks)", -1)
end

main()
