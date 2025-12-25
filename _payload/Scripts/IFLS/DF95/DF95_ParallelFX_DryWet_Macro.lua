-- @description Parallel FX – Dry/Wet Macro
-- @version 1.0
-- @author DF95
-- @about Adds a controllable Dry/Wet macro (JS Smoother) to the selected bus track(s).
local r = reaper
local function add_macro(tr)
  local idx = r.TrackFX_AddByName(tr, "JS: Utility/volume_pan_smoother", false, -1000)
  if idx < 0 then idx = r.TrackFX_AddByName(tr, "JS: Volume/Pan Smoother", false, -1000) end
  if idx >= 0 then
    r.TrackFX_SetOpen(tr, idx, true)
    r.ShowMessageBox("Dry/Wet Macro added to: "..(select(2,r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)) or "track"), "DF95", 0)
  end
end
local sel = r.CountSelectedTracks(0)
if sel==0 then r.ShowMessageBox("Bitte Parallel-FX-Bus auswählen.", "DF95", 0) return end
r.Undo_BeginBlock()
for i=0, sel-1 do add_macro(r.GetSelectedTrack(0,i)) end
r.Undo_EndBlock("DF95 Dry/Wet Macro added", -1)