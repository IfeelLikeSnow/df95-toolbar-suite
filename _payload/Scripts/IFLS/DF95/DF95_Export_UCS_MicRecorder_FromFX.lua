-- @description Export – UCS Mic/Recorder From FX
-- @version 1.0
-- @author DF95

-- Versucht, aus den FX-Namen der selektierten Tracks Mikrofon-Profile
-- abzuleiten (basierend auf MicFX_Profiles_v3.json) und setzt
-- entsprechende Export-Tags (MicModel, RecMedium).
--
-- Hinweis: UCS sieht "Microphone" und "Rec Medium" typischerweise
-- als Metadatenfelder vor (nicht zwingend im Dateinamen eingebettet).
-- Dieses Script bereitet diese Infos vor, so dass spätere
-- Metadaten-Embedding-Tools sie nutzen können.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function data_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Data" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function load_micfx_profiles()
  local path = data_root() .. "MicFX_Profiles_v3.json"
  local f = io.open(path, "rb")
  if not f then return {} end
  local txt = f:read("*a")
  f:close()
  if not txt or txt == "" or not r.JSONDecode then return {} end
  local ok, obj = pcall(function() return r.JSONDecode(txt) end)
  if not ok or type(obj) ~= "table" then return {} end
  return obj
end

local function get_export_core()
  local ok, mod_or_err = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  if not ok then return nil end
  if type(mod_or_err) ~= "table" then return nil end
  return mod_or_err
end

local function prettify_mic_name(key)
  -- z.B. "Rode_NTG4_plus" -> "Rode NTG4 plus"
  key = key:gsub("_"," ")
  key = key:gsub("%s+"," ")
  -- einfach erste Buchstaben groß
  key = key:gsub("(%a)([%w']*)", function(a,b) return a:upper()..b:lower() end)
  return key
end

local function detect_mic_from_track(track, mic_profiles)
  if not track then return nil end
  local fx_count = r.TrackFX_GetCount(track)
  if fx_count == 0 then return nil end

  -- Baue Lookup aus MicFX-Keys
  local keys = {}
  for mic_name, _ in pairs(mic_profiles) do
    keys[#keys+1] = mic_name
  end

  for fx = 0, fx_count-1 do
    local _, fxname = r.TrackFX_GetFXName(track, fx, "")
    local lname = (fxname or ""):lower()
    for _, mic_key in ipairs(keys) do
      local lk = mic_key:lower()
      local lk_space = lk:gsub("_"," ")
      if lname:find(lk, 1, true) or lname:find(lk_space, 1, true) then
        return mic_key
      end
    end
  end

  return nil
end

local function main()
  local proj = 0
  local num_sel_tracks = r.CountSelectedTracks(proj)
  if num_sel_tracks == 0 then
    r.ShowMessageBox("Bitte mindestens einen Track selektieren, dessen FX als Mic-Hinweis dienen sollen.", "DF95 UCS Mic/Recorder", 0)
    return
  end

  local mic_profiles = load_micfx_profiles()
  local core = get_export_core()

  local detected_mics = {}
  for i = 0, num_sel_tracks-1 do
    local tr = r.GetSelectedTrack(proj, i)
    local mic_key = detect_mic_from_track(tr, mic_profiles)
    if mic_key then
      detected_mics[mic_key] = true
    end
  end

  local mic_model = ""
  for mk, _ in pairs(detected_mics) do
    if mic_model == "" then
      mic_model = prettify_mic_name(mk)
    else
      mic_model = mic_model .. " / " .. prettify_mic_name(mk)
    end
  end

  -- Recorder via Dialog erfragen (kann später als Default gespeichert werden)
  local prev_rec = core and core.GetExportTag and core.GetExportTag("RecMedium", "") or ""
  local cap = "MicModel(auto, leer=ignorieren),RecMedium(Recorder Name/Model)"
  local def = string.format("%s,%s", mic_model or "", prev_rec or "")
  local ok, ret = r.GetUserInputs("DF95 UCS Mic/Recorder", 2, cap..",extrawidth=260", def)
  if not ok or not ret or ret == "" then return end

  local mic_in, rec_in = ret:match("^(.-),(.-)$")
  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end
  mic_in = trim(mic_in or mic_model or "")
  rec_in = trim(rec_in or prev_rec or "")

  if core and core.SetExportTag then
    if mic_in ~= "" then core.SetExportTag("MicModel", mic_in) end
    if rec_in ~= "" then core.SetExportTag("RecMedium", rec_in) end
  end

  -- Info
  r.ShowMessageBox(
    string.format("UCS-Metadaten vorbereitet:\nMicModel: %s\nRecMedium: %s\n\nDiese Werte werden als DF95_EXPORT_TAGS gespeichert und können\nvon Metadaten-Tools oder zukünftigen Export-Erweiterungen genutzt werden.",
      mic_in ~= "" and mic_in or "(leer)", rec_in ~= "" and rec_in or "(leer)"),
    "DF95 UCS Mic/Recorder", 0)
end

main()
