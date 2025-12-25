
-- @description DF95_ReampSuite_Router
-- @version 1.0
-- @author DF95
-- @about
--   Frontend für den DF95 V71 Reamp Router:
--   - wählt ein Reamp-Profil (UR22 / PreSonus / Zoom F6 / Generic)
--   - setzt DF95_REAMP/OUT_CH und DF95_REAMP/IN_CH gemäß Profil
--   - ruft anschließend (optional) den V71-ReampRouter auf

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_load(modpath)
  local ok, mod = pcall(dofile, modpath)
  if not ok then return nil, mod end
  return mod, nil
end

local function choose_profile_key(profiles, active_key)
  local keys = {}
  for k, _ in pairs(profiles) do keys[#keys+1] = k end
  table.sort(keys)

  local caption = ""
  for i, k in ipairs(keys) do
    local p = profiles[k]
    caption = caption .. string.format("%d: %s (%s)\\n", i, p.name or k, p.interface or "")
  end

  local default = ""
  for i, k in ipairs(keys) do
    if k == active_key then
      default = tostring(i)
      break
    end
  end
  if default == "" then default = "1" end

  local ok, ret = r.GetUserInputs("DF95 ReampSuite – Profil wählen", 1,
                                  "Index (1.." .. #keys .. ")", default)
  if not ok or not ret or ret == "" then return active_key end

  local idx = tonumber(ret)
  if not idx or idx < 1 or idx > #keys then return active_key end
  return keys[idx]
end

local function main()
  local profiles_mod, err = safe_load(df95_root() .. "ReampSuite/DF95_ReampSuite_Profiles.lua")
  if not profiles_mod then
    r.ShowMessageBox("DF95_ReampSuite_Profiles.lua konnte nicht geladen werden:\\n" .. tostring(err or "?"),
                     "DF95 ReampSuite Router", 0)
    return
  end

  local active_key = profiles_mod.get_active_key()
  local new_key = choose_profile_key(profiles_mod.profiles, active_key)
  profiles_mod.set_active_key(new_key)
  profiles_mod.apply_active_to_ext()

  local profile = profiles_mod.get_active_profile()
  local msg = string.format(
    "Aktives Reamp-Profil:\\n\\n%s\\nInterface: %s\\nOut-Ch: %d\\nIn-Ch: %d\\n\\n" ..
    "Diese Werte wurden in DF95_REAMP/OUT_CH und DF95_REAMP/IN_CH hinterlegt.",
    profile.name or new_key,
    profile.interface or "n/a",
    profile.out_ch or 3,
    profile.in_ch or 1
  )

  r.ShowMessageBox(msg, "DF95 ReampSuite Router", 0)
end

main()
