-- @description In-Session Fix – GainStage (Pre/Post Gain ergänzen)
-- @version 1.0
-- @author DF95
-- @about Fügt am Kettenanfang und vor letztem FX je eine Gain-Stufe ein (JS: Volume).
local r = reaper
local sep = package.config:sub(1,1)
local utils = dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")").."DF95_RuntimeUtils.lua")

local function ensure_pre_post_gain(tr)
  local cnt = r.TrackFX_GetCount(tr)
  -- PRE
  local pre_ok = false
  if cnt > 0 then
    local _, n0 = r.TrackFX_GetFXName(tr, 0, "")
    pre_ok = n0:lower():find("gain") or n0:lower():find("volume")
  end
  if not pre_ok then utils.insert_js_volume(tr, 0) end
  -- POST (before last FX if >1; else at end)
  cnt = r.TrackFX_GetCount(tr)
  local insert_pos = math.max(cnt-1, 1)
  utils.insert_js_volume(tr, insert_pos)
end

r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
for i=0, sel-1 do
  ensure_pre_post_gain(r.GetSelectedTrack(0,i))
end
r.Undo_EndBlock("DF95: GainStage – Insert pre/post gain", -1)