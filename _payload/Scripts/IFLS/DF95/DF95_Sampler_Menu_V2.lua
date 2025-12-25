-- @description Sampler Menu V2 (Artist-Profile)
-- @version 1.1
-- @author DF95

local r = reaper

local function get_artist_key()
  local rv, key = r.GetProjExtState(0, "DF95", "CurrentArtistKey")
  if rv == 0 or key == "" then return "default" end
  return key
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
  local key = get_artist_key()
  local res = r.GetResourcePath()
  local cfg_path = res .. "/Data/DF95/DF95_Artist_SamplerProfiles_v1.json"
  local txt = read_file(cfg_path)
  local obj = json_decode(txt)
  if not obj then
    r.ShowMessageBox("Konnte Sampler-Profile nicht laden:\n"..cfg_path, "DF95 Sampler Menü V2", 0)
    return
  end

  local profile = (obj.artists and obj.artists[key]) or obj.defaults or {}
  local blob = r.JSONEncode and r.JSONEncode(profile) or ""

  r.SetProjExtState(0, "DF95_SAMPLER", "PROFILE_JSON", blob)
  r.SetProjExtState(0, "DF95_SAMPLER", "PROFILE_NAME", key)

  local lines = {}
  lines[#lines+1] = "DF95 Sampler Menü V2"
  lines[#lines+1] = ""
  lines[#lines+1] = "Artist Key: " .. key
  lines[#lines+1] = ""
  lines[#lines+1] = "Kick Engine: " .. tostring(profile.kick_engine or obj.defaults.kick_engine)
  lines[#lines+1] = "Perc Density: " .. tostring(profile.perc_density or obj.defaults.perc_density)
  lines[#lines+1] = "Ghost Notes: " .. tostring(profile.ghost_notes or obj.defaults.ghost_notes)

  r.ShowMessageBox(table.concat(lines, "\n"), "DF95 Sampler Menü V2", 0)
end

main()
