-- @description Fix Chains – GainStage (insert pre/post gain)
-- @version 1.1
-- @author DF95
-- Fügt auf allen ausgewählten Spuren je eine Pre- und Post-Gain-Stufe (JS: Volume) ein.

local r = reaper

local function ensure_js_volume(tr, name, at_start)
  local idx = r.TrackFX_AddByName(tr, "JS: Volume", false, -1)
  if idx < 0 then return nil end

  if at_start and idx > 0 then
    r.TrackFX_CopyToTrack(tr, idx, tr, 0, true)
    idx = 0
  end

  if name and name ~= "" then
    r.TrackFX_SetFXName(tr, idx, name)
  end

  return idx
end

local function process_track(tr)
  if not tr then return end
  ensure_js_volume(tr, "DF95 PreGain (JS: Volume)", true)
  ensure_js_volume(tr, "DF95 PostGain (JS: Volume)", false)
end

local function main()
  local cnt = r.CountSelectedTracks(0)
  if cnt == 0 then
    r.ShowMessageBox("Keine Tracks ausgewählt.", "DF95 GainStage", 0)
    return
  end

  r.Undo_BeginBlock()
  for i = 0, cnt-1 do
    local tr = r.GetSelectedTrack(0, i)
    process_track(tr)
  end
  r.Undo_EndBlock("DF95: Fix Chains – GainStage", -1)
end

main()
