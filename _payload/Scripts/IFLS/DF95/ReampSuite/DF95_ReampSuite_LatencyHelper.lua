
-- @description DF95_ReampSuite_LatencyHelper
-- @version 1.0
-- @author DF95
-- @about
--   Wrapper um den DF95_V71_LatencyAnalyzer.lua:
--   - erstellt Testimpuls-Track
--   - erklärt, wie OFFSET_SAMPLES_<PROFILE> gesetzt werden kann

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function main()
  -- Analyzer ausführen
  local ok, err = pcall(dofile, df95_root() .. "DF95_V71_LatencyAnalyzer.lua")
  if not ok then
    r.ShowMessageBox("DF95_V71_LatencyAnalyzer.lua konnte nicht ausgeführt werden:\\n" .. tostring(err or "?"),
                     "DF95 ReampSuite LatencyHelper", 0)
    return
  end

  -- Optionale Info zu Profil-basierten Offsets
  local profiles_ok, profiles_mod = pcall(dofile, df95_root() .. "ReampSuite/DF95_ReampSuite_Profiles.lua")
  local active_key = "Generic_Reamp"
  if profiles_ok and type(profiles_mod) == "table" and profiles_mod.get_active_key then
    active_key = profiles_mod.get_active_key()
  end

  local msg = string.format(
    "Hinweis: Wenn du die Reamp-Latenz (Samples) bestimmt hast, kannst du sie profil-spezifisch speichern:\\n\\n" ..
    "Namespace: DF95_REAMP\\nKey: OFFSET_SAMPLES_%s\\n\\n" ..
    "Beispiel:\\nDF95_REAMP / OFFSET_SAMPLES_%s = 128",
    active_key, active_key
  )

  r.ShowMessageBox(msg, "DF95 ReampSuite LatencyHelper", 0)
end

main()
