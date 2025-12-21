-- @description GainMatch (LUFS) – Manual Helper
-- @version 1.0
-- @author DF95
-- @about Asks for current integrated LUFS (A & B) and adjusts post-gain to match target.
-- Steps: toggle A/B, run a short playback through your LUFS meter, enter the two values; script sets gain delta.
local r = reaper

local function db_to_mul(db) return 10^(db/20) end
local function set_post_gain(tr, delta_db)
  -- find last gain stage or create JS: Volume at end-1
  local cnt = r.TrackFX_GetCount(tr)
  local pos = math.max(cnt-1, 0)
  local fx = r.TrackFX_AddByName(tr, "JS: Volume adjustment", false, -1000)
  if fx >= 0 and pos >= 0 then r.TrackFX_CopyToTrack(tr, fx, tr, pos, true) end
  -- try set gain param (usually param 0 for JS: Volume)
  local last = r.TrackFX_GetCount(tr)-1
  if last >= 0 then
    local mul = db_to_mul(delta_db)
    -- JS: Volume expects dB slider (varies). We set normalized by mapping -90..+12 dB range.
    local min_db, max_db = -90.0, 12.0
    local norm = (delta_db - min_db) / (max_db - min_db)
    if norm < 0 then norm = 0 elseif norm > 1 then norm = 1 end
    r.TrackFX_SetParamNormalized(tr, last, 0, norm)
  end
end

-- UI
local ok, vals = r.GetUserInputs("DF95 GainMatch (LUFS)", 3, "A (LUFS-I),B (LUFS-I),Target (LUFS-I)", "-12.0,-12.0,-12.0")
if not ok then return end
local A, B, T = vals:match("([^,]+),([^,]+),([^,]+)")
A, B, T = tonumber(A or "-12"), tonumber(B or "-12"), tonumber(T or "-12")
if not (A and B and T) then return end

-- We adjust current state (assume B active) to Target; compute delta relative to B
-- delta_db = (T - B) in LUFS ~ dB
local delta_db = (T - B)
r.Undo_BeginBlock()
local sel = r.CountSelectedTracks(0)
if sel == 0 then
  local mst = r.GetMasterTrack(0)
  set_post_gain(mst, delta_db)
else
  for i=0, sel-1 do set_post_gain(r.GetSelectedTrack(0,i), delta_db) end
end
r.Undo_EndBlock(string.format("DF95 LUFS GainMatch: B %.1f → Target %.1f (Δ %.1f dB)", B, T, delta_db), -1)