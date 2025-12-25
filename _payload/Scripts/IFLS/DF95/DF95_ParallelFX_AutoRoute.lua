-- @description Parallel FX – Auto Route (create/send/scope/polarity)
-- @version 1.0
-- @author DF95
-- @about Creates a parallel FX bus for selected tracks, sets 100% post-fader sends, inserts Phase Scope and a polarity flip tool.
local r = reaper

local function create_parallel_bus(name)
  r.Main_OnCommand(40001, 0) -- Track: Insert new track
  local tr = r.GetSelectedTrack(0, 0)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function insert_tools(tr)
  r.TrackFX_AddByName(tr, "JS: Phase Meter/Scope", false, -1000)
  r.TrackFX_AddByName(tr, "JS: Utility/phase_adjust", false, -1000)
end

local function add_send(src, dst)
  local sid = r.CreateTrackSend(src, dst)
  -- Post-fader (send mode 0=post-fader)
  r.SetTrackSendInfo_Value(src, 0, sid, "I_SENDMODE", 0)
  -- Send volume unity
  r.SetTrackSendInfo_Value(src, 0, sid, "D_VOL", 1.0)
end

r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
if sel == 0 then r.ShowMessageBox("Bitte Quell-Tracks auswählen.", "DF95 Parallel FX", 0) return end
local bus = create_parallel_bus("[DF95 Parallel FX]")
insert_tools(bus)
for i=0, sel-1 do add_send(r.GetSelectedTrack(0,i), bus) end
r.Undo_EndBlock("DF95: Parallel FX Auto-Route", -1)