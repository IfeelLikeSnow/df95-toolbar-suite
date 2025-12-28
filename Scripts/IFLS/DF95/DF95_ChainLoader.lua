-- @description Chain Loader (by relpath)
-- @version 1.2
-- @author IfeelLikeSnow
-- @changelog +secondary search path under Data/DF95/Chains; safer chain load
local r = reaper
local function load_chain_on_track(chain_relpath, track)
  if not chain_relpath or chain_relpath == "" or not track then return false end
  local sep = package.config:sub(1,1)
  local bases = {
    r.GetResourcePath() .. sep .. "FXChains" .. sep,
    r.GetResourcePath() .. sep .. "Data" .. sep .. "DF95" .. sep .. "Chains" .. sep
  }
  local path = nil
  for _,b in ipairs(bases) do
    local p = b .. chain_relpath
    local f = io.open(p,"rb")
    if f then f:close(); path = p; break end
  end
  if not path then
    r.ShowMessageBox("FX-Chain nicht gefunden:\n"..tostring(chain_relpath)..
      "\n(Erwarte unter FXChains/… oder Data/DF95/Chains/…)", "DF95 Loader", 0)
    return false
  end
  local ok = r.TrackFX_AddByName(track, "Chain: " .. path, false, -1000) >= 0
  return ok
end
local function get_selected_tracks()
  local t = {}
  local n = reaper.CountSelectedTracks(0)
  for i=0,n-1 do t[#t+1] = reaper.GetSelectedTrack(0,i) end
  return t
end
return { load_chain_on_track = load_chain_on_track, get_selected_tracks = get_selected_tracks }