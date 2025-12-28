-- @description ArtistProfile Loader (Slicing/Humanize/Rearrange/Loop/Sampler/Warp/Coloring)
-- @version 1.0
-- @author DF95

local r = reaper
local M = {}

local function normalize_key(name)
  if not name or name == "" then return "" end
  local s = name:lower()
  if s:find("µ%-ziq") or s:find("mu%-ziq") then
    return "mu_ziq"
  end
  if s:find("future sound of london") then
    return "fsold"
  end
  s = s:gsub("[^%w]+", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_", ""):gsub("_$", "")
  return s
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local d = f:read("*all")
  f:close()
  return d
end

local function json_decode_safe(txt)
  if not txt or txt == "" then return nil end
  if not r.JSONDecode then return nil end
  local ok, obj = pcall(function() return r.JSONDecode(txt) end)
  if ok and type(obj) == "table" then
    return obj
  end
  return nil
end

local function merge_defaults(obj, key)
  if not obj then return nil end
  local defaults = obj.defaults or {}
  local artists = obj.artists or {}
  local specific = artists[key] or {}
  local out = {}
  for k, v in pairs(defaults) do
    out[k] = v
  end
  for k, v in pairs(specific) do
    out[k] = v
  end
  return out
end

local function load_json_profile(relpath, key, with_merge)
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local full = (res .. sep .. "Data" .. sep .. "DF95" .. sep .. relpath):gsub("\\","/")
  local txt = read_file(full)
  if not txt then return nil end
  local obj = json_decode_safe(txt)
  if not obj then return nil end
  if with_merge then
    return merge_defaults(obj, key), obj
  else
    return obj, obj
  end
end

function M.load(artist_name_or_key)
  local rv, cur_name = r.GetProjExtState(0, "DF95", "CurrentArtist")
  local rv2, cur_key = r.GetProjExtState(0, "DF95", "CurrentArtistKey")

  local inp = artist_name_or_key
  local name = nil
  local key = nil

  if inp and inp ~= "" then
    name = inp
    key = normalize_key(inp)
  else
    if rv > 0 and cur_name ~= "" then
      name = cur_name
    end
    if rv2 > 0 and cur_key ~= "" then
      key = cur_key
    end
  end

  if (not name or name == "") and (not key or key == "") then
    return nil, "no_artist"
  end

  if not key or key == "" then
    key = normalize_key(name)
  end
  if not name or name == "" then
    name = key
  end

  local profile = { name = name, key = key }

  local slicing, _ = load_json_profile("DF95_Artist_SlicingProfiles_v1.json", key, true)
  profile.slicing = slicing or {}

  local humanize, _ = load_json_profile("DF95_Artist_HumanizeProfiles_v1.json", key, true)
  profile.humanize = humanize or {}

  local rearrange, _ = load_json_profile("DF95_Artist_RearrangeProfiles_v1.json", key, true)
  profile.rearrange = rearrange or {}

  local loop, _ = load_json_profile("DF95_Artist_LoopProfiles_v1.json", key, true)
  profile.loop = loop or {}

  local sampler, _ = load_json_profile("DF95_Artist_SamplerProfiles_v1.json", key, true)
  profile.sampler = sampler or {}

  local warp, _ = load_json_profile("DF95_Artist_WarpProfiles_v1.json", key, true)
  profile.warp = warp or {}

  local filter, _ = load_json_profile("DF95_Artist_FilterProfiles_v1.json", key, true)
  profile.filter = filter or {}


  local color_bias_obj, _ = load_json_profile("Coloring_ArtistBias_v1.json", key, false)
  if color_bias_obj and color_bias_obj.artists and color_bias_obj.artists[key] then
    profile.coloring_bias = color_bias_obj.artists[key]
  else
    profile.coloring_bias = nil
  end

  local color_chain_obj, _ = load_json_profile("Coloring_ArtistChains_curated.json", key, false)
  if color_chain_obj and color_chain_obj.chains and color_chain_obj.chains[key] then
    profile.coloring_chains = color_chain_obj.chains[key]
  else
    profile.coloring_chains = nil
  end

  local core_bias_obj, _ = load_json_profile("DF95_ArtistBias.json", key, false)
  if core_bias_obj and core_bias_obj.artists and core_bias_obj.artists[key] then
    profile.bias_core = core_bias_obj.artists[key]
  else
    profile.bias_core = nil
  end

  return profile, "ok"
end

_G.DF95_ArtistProfileLoader = M
_G.DF95_LoadArtistProfiles = M.load

return M
