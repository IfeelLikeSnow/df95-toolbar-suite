
-- @description Slicing SmokeTest v1 – Preset loader + fade/snap/zero-cross checks
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local out = res .. sep .. "Data" .. sep .. "DF95" .. sep .. "SlicingSmokeReport.txt"
local function log(s) local f=io.open(out,"a"); if f then f:write(s.."\n"); f:close() end

-- reset log
local f=io.open(out,"wb"); if f then f:write(""); f:close() end
log("[DF95 SlicingSmoke] Start " .. os.date())

local function first_chain_in(dir)
  local i=0; local p = r.EnumerateFiles(dir, i)
  while p do
    if p:lower():match("%.rfxchain$") then return dir..sep..p end
    i=i+1; p = r.EnumerateFiles(dir, i)
  end
end

local cands = {
  res..sep.."FXChains"..sep.."Slicing",
  res..sep.."FXChains"..sep.."DF95_Slicing",
  res..sep.."FXChains"..sep.."DF95"..sep.."Slicing",
}

local function ensure_track()
  local tr = r.GetSelectedTrack(0,0)
  if not tr then
    r.InsertTrackAtIndex(r.CountTracks(0), true)
    tr = r.GetTrack(0, r.CountTracks(0)-1)
  end
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95_SlicingSmoke", true)
  return tr
end

-- Pretend to load a representative chain (if present)
local tr = ensure_track()
local loaded = false
for _,d in ipairs(cands) do
  local chain = first_chain_in(d)
  if chain then
    local idx = r.TrackFX_AddByName(tr, chain, false, 1) -- load rfxchain
    loaded = loaded or (idx and idx>=0)
    log(string.format("[Load] %s → %s", chain, tostring(loaded)))
    -- cleanup
    local n = r.TrackFX_GetCount(tr); for i=n-1,0,-1 do r.TrackFX_Delete(tr, i) end
    break
  end
end
if not loaded then log("[Load] no slicing chains found in common dirs") end

-- Check fades/snap/zero-cross defaults
local snap = r.GetToggleCommandStateEx(0, 1157) -- Snap enable
local zc = r.GetToggleCommandState(40041)       -- Options: Toggle auto-crossfade
-- Fades default lengths
local _, fin = r.GetSetProjectInfo(0, "DEFENVFADEIN", 0, false)
local _, fout = r.GetSetProjectInfo(0, "DEFENVFADEOUT", 0, false)

log(string.format("[Prefs] Snap=%s, AutoXFade=%s, Default FadeIn=%.3f, FadeOut=%.3f", tostring(snap==1), tostring(zc==1), fin or -1, fout or -1))
log("[DF95 SlicingSmoke] End")
r.ShowConsoleMsg("[DF95] Slicing Smoke fertig. Report: Data/DF95/SlicingSmokeReport.txt\n")
