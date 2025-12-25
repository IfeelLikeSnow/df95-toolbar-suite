-- @description Slicing Menu V2 (Artist-Profile)
-- @version 1.1
-- @author DF95
-- @about
--   Liest DF95_Artist_SlicingProfiles_v1.json und setzt:
--     DF95_SLICING / PROFILE_JSON   (kompletter JSON-Block als String)
--     DF95_SLICING / PROFILE_NAME   (Artist-Key oder "default")

local r = reaper

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

local function get_artist_key()
  local rv, key = r.GetProjExtState(0, "DF95", "CurrentArtistKey")
  if rv == 0 or key == "" then
    local rv2, name = r.GetProjExtState(0, "DF95", "CurrentArtist")
    if rv2 == 0 or name == "" then return "", "" end
    return normalize_key(name), name
  end
  local _, name = r.GetProjExtState(0, "DF95", "CurrentArtist")
  return key, (name or "")
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local txt = f:read("*a")
  f:close()
  return txt
end

local function json_decode(txt)
  if not txt or txt == "" then return nil end
  if not r.JSONDecode then return nil end
  local ok, obj = pcall(function() return r.JSONDecode(txt) end)
  if ok then return obj end
  return nil
end

local function main()
  local key, name = get_artist_key()
  local res = r.GetResourcePath()
  local cfg_path = res .. "/Data/DF95/DF95_Artist_SlicingProfiles_v1.json"
  local txt = read_file(cfg_path)
  local obj = json_decode(txt)

  if not obj then
    r.ShowMessageBox("Konnte Slicing-Profile nicht laden:\n"..cfg_path, "DF95 Slicing Menü V2", 0)
    return
  end

  local use_key = key ~= "" and key or "default"
  local profile = (obj.artists and obj.artists[use_key]) or obj.defaults or {}

  local blob = r.JSONEncode and r.JSONEncode(profile) or ""

  r.SetProjExtState(0, "DF95_SLICING", "PROFILE_JSON", blob)
  r.SetProjExtState(0, "DF95_SLICING", "PROFILE_NAME", use_key)

  local lines = {}
  lines[#lines+1] = "DF95 Slicing Menü V2"
  lines[#lines+1] = ""
  lines[#lines+1] = "Artist: " .. (name ~= "" and name or "<none>")
  lines[#lines+1] = "Key: " .. use_key
  lines[#lines+1] = ""
  lines[#lines+1] = "Slice Density: " .. tostring(profile.slice_density or obj.defaults.slice_density)
  lines[#lines+1] = "Crossfade (ms): " .. tostring(profile.crossfade_ms or obj.defaults.crossfade_ms)
  lines[#lines+1] = "Odd Meters: " .. tostring(profile.allow_odd_meters or obj.defaults.allow_odd_meters)

  r.ShowMessageBox(table.concat(lines, "\n"), "DF95 Slicing Menü V2", 0)
end

main()
