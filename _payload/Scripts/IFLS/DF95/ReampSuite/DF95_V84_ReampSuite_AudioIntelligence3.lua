-- @description DF95_V84_ReampSuite_AudioIntelligence3
-- @version 1.0
-- @author DF95
local r = reaper
local M = {}
local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end
local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end
local ai2_path = df95_root() .. "ReampSuite/DF95_ReampSuite_PedalChains_Intelligence.lua"
local ai2_mod, ai2_err = safe_require(ai2_path)
function M.analyze_tracks(tracks)
  local result = { tracks = {}, spectral_available = false }
  if not ai2_mod then
    result.error = "AI2-Modul konnte nicht geladen werden: " .. tostring(ai2_err or "?")
  end
  for _, tr in ipairs(tracks or {}) do
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    result.tracks[#result.tracks+1] = {
      track = tr,
      name  = name or "",
      peak_db = nil,
      rms_db  = nil,
      dyn_db  = nil,
      spectral_brightness = nil,
      spectral_noisiness  = nil,
      spectral_centroid   = nil,
    }
  end
  return result
end
return M