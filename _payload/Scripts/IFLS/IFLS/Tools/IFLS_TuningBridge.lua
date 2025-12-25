-- IFLS_TuningBridge.lua
-- Phase 11: Unified Tuning Engine Bridge
-- --------------------------------------
-- Sync IFLS_TuningDomain -> IFLS_MIDIProcessor.jsfx sliders.

local r = reaper
local M = {}

local resource_path = r.GetResourcePath()
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_tuning, tuning = pcall(dofile, domain_path .. "IFLS_TuningDomain.lua")
if not ok_tuning or type(tuning) ~= "table" then
  return {
    sync_track    = function() return 0 end,
    sync_selected = function() return 0 end,
    sync_all      = function() return 0 end,
  }
end

local function find_ifls_midi_processor_on_track(tr)
  local count = r.GetTrackNumFX(tr)
  local idxs = {}
  for i=0,count-1 do
    local retval, name = r.TrackFX_GetFXName(tr, i, "")
    if retval and name:lower():find("ifls midi processor") then
      idxs[#idxs+1] = i
    end
  end
  return idxs
end

local function slider_norm(val, minv, maxv)
  if maxv == minv then return 0.0 end
  local n = (val - minv) / (maxv - minv)
  if n < 0 then n = 0 end
  if n > 1 then n = 1 end
  return n
end

local function apply_state_to_fx(tr, fx_idx, st)
  local profile = st.profile or "Equal12"
  local pb_range = st.pitch_bend_semi or 2
  local master = st.master_offset or 0

  local profile_val = 0
  if profile == "QuarterTone" then profile_val = 1
  elseif profile == "FifthShift" then profile_val = 2 end

  local p1 = slider_norm(profile_val, 0, 2)
  local p2 = slider_norm(pb_range, 1, 48)
  local p3 = slider_norm(master, -200, 200)

  r.TrackFX_SetParam(tr, fx_idx, 0, p1)
  r.TrackFX_SetParam(tr, fx_idx, 1, p2)
  r.TrackFX_SetParam(tr, fx_idx, 2, p3)
end

local function sync_track(tr)
  if not tr then return 0 end
  local st = tuning.get_state()
  if not st.enabled then
    st.profile       = "Equal12"
    st.master_offset = 0
  end
  local idxs = find_ifls_midi_processor_on_track(tr)
  for _,fx in ipairs(idxs) do
    apply_state_to_fx(tr, fx, st)
  end
  return #idxs
end

function M.sync_track(tr)
  return sync_track(tr)
end

function M.sync_selected()
  local sel_count = r.CountSelectedTracks(0)
  local total = 0
  for i=0,sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    total = total + sync_track(tr)
  end
  return total
end

function M.sync_all()
  local proj = 0
  local total = 0
  local track_count = r.CountTracks(proj)
  for i=0,track_count-1 do
    local tr = r.GetTrack(proj, i)
    total = total + sync_track(tr)
  end
  return total
end

return M
