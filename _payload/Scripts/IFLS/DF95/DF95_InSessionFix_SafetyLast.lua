-- @description In-Session Fix – SafetyLast (Limiter ans Ende; Master absichern)
-- @version 1.0
-- @author DF95
-- @about Verschiebt vorhandene Limiter auf selektierten Tracks ans Kettenende.
--         Fügt auf dem Master ReaLimit hinzu (falls nicht vorhanden) und platziert ihn ganz am Ende.
local r = reaper
local sep = package.config:sub(1,1)
local utils = dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")").."DF95_RuntimeUtils.lua")

local LIM_KEYS = {"realimit", "limiter", "adclip", "cliponly", "maximizer", "loudmax"}

local function move_limiters_last_on_track(tr)
  local hits = utils.find_fx_indices(tr, LIM_KEYS)
  if #hits == 0 then return 0 end
  local moved = 0
  local last_pos = r.TrackFX_GetCount(tr)-1
  -- Process from tail to head to preserve indices
  for i=#hits,1,-1 do
    local fx = hits[i]
    r.TrackFX_CopyToTrack(tr, fx, tr, last_pos, true) -- move to end
    moved = moved + 1
  end
  return moved
end

local function ensure_master_limit()
  local master = r.GetMasterTrack(0)
  local hits = utils.find_fx_indices(master, LIM_KEYS)
  local realimit_idx = -1
  for _,i in ipairs(hits) do
    local _,nm = r.TrackFX_GetFXName(master, i, "")
    if nm:lower():find("realimit") then realimit_idx = i break end
  end
  if realimit_idx < 0 then
    realimit_idx = r.TrackFX_AddByName(master, "VST3: ReaLimit (Cockos)", false, -1000)
    if realimit_idx < 0 then realimit_idx = r.TrackFX_AddByName(master, "VST: ReaLimit (Cockos)", false, -1000) end
  end
  if realimit_idx >= 0 then
    local last = r.TrackFX_GetCount(master)-1
    r.TrackFX_CopyToTrack(master, realimit_idx, master, last, true)
  end
end

r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
for i=0, sel-1 do
  move_limiters_last_on_track(r.GetSelectedTrack(0,i))
end
ensure_master_limit()
r.Undo_EndBlock("DF95: SafetyLast – Move limiters last; ensure ReaLimit on Master", -1)