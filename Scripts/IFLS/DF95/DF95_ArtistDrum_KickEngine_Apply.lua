-- @description Artist Drum KickEngine Apply (Chooses Kick Synth per Artist SamplerProfile)
-- @version 1.0
-- @author DF95

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function load_artist_profile()
  local ok, M = pcall(dofile, df95_root() .. "DF95_ArtistProfile_Loader.lua")
  if not ok or not M or type(M.load) ~= "function" then
    return nil
  end
  local prof, status = M.load()
  if status ~= "ok" then
    return nil
  end
  return prof
end

local function find_kick_track()
  local proj = 0
  local track_count = r.CountTracks(proj)
  local best = nil
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetTrackName(tr, "")
    local lower = (name or ""):lower()
    if lower:find("kick") or lower:find("bd ") or lower:find("bassdrum") then
      best = tr
      break
    end
  end
  return best
end

local function add_fx(track, fxname)
  if not track or not fxname or fxname == "" then return -1 end
  local idx = r.TrackFX_AddByName(track, fxname, false, 1)
  return idx
end

local function main()
  local prof = load_artist_profile()
  if not prof or not prof.sampler then
    return
  end
  local kick_engine = (prof.sampler.kick_engine or "auto"):lower()

  local kick_tr = find_kick_track()
  if not kick_tr then
    -- Fallback: erste ausgewählte Spur
    if r.CountSelectedTracks(0) > 0 then
      kick_tr = r.GetSelectedTrack(0, 0)
    else
      return
    end
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  if kick_engine == "chowkick" then
    add_fx(kick_tr, "ChowKick")
  elseif kick_engine == "b2" or kick_engine == "b-2" then
    add_fx(kick_tr, "B-2")
  elseif kick_engine == "elsita" then
    add_fx(kick_tr, "Elsita")
  else
    -- auto: nichts erzwingen, Benutzer kann später manuell ergänzen
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Artist Drum KickEngine Apply (" .. tostring(kick_engine) .. ")", -1)
end

main()
