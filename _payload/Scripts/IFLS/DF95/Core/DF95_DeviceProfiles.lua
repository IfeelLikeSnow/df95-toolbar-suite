-- DF95_DeviceProfiles.lua
-- Zentrales Device-Profile-System für DF95
-- Version: 1.0

local M = {}

-- Basis-Tabelle aller Profile
M.profiles = {
  ZOOM_F6 = {
    id = "ZOOM_F6",
    label = "Zoom F6",
    channels = 6,
    filename_hint   = { "Z6_", "F6_" },
    track_name_hint = { "F6", "ZOOMF6" },

    default_homezone = "HOME_FIELD_GENERIC",
    default_micfx = {
      [1] = "DF95_MicFX_Dynamic_Close_V1",
      [2] = "DF95_MicFX_Dynamic_Close_V1",
      [3] = "DF95_MicFX_Shotgun_VO_V1",
      [4] = "DF95_MicFX_Shotgun_Ambi_V1",
      [5] = "DF95_MicFX_Ambient_OMNI_V1",
      [6] = "DF95_MicFX_Ambient_OMNI_V1",
    },

    ai_hints = {
      WATER = "WATER",
      EMF   = "ELECTRICITY",
    }
  },

  ZOOM_H5 = {
    id = "ZOOM_H5",
    label = "Zoom H5 / H4n",
    channels = 4,
    filename_hint   = { "H5_", "H4N_", "ZOOMH" },
    track_name_hint = { "H5", "H4N" },

    default_homezone = "HOME_FIELD_PORTABLE",
    default_micfx = {
      [1] = "DF95_MicFX_Portable_XY_V1",
      [2] = "DF95_MicFX_Portable_XY_V1",
      [3] = "DF95_MicFX_Lav_V1",
      [4] = "DF95_MicFX_Lav_V1",
    },
  },

  FIELDREC_ANDROID = {
    id = "FIELDREC_ANDROID",
    label = "Fieldrec App (Android)",
    channels = 2,
    filename_hint   = { "FR_", "FIELDREC_", "ANDROIDREC_" },
    track_name_hint = { "Android", "Fieldrec" },

    default_homezone = "HOME_MOBILE_GENERIC",
    default_micfx = {
      [1] = "DF95_MicFX_Phone_Lofi_V1",
      [2] = "DF95_MicFX_Phone_Lofi_V1",
    },
  },

  EMF_MCM36010 = {
    id = "EMF_MCM36010",
    label = "EMF Recorder MCM 36-010",
    channels = 1,
    filename_hint   = { "EMF_", "MCM_", "EMREC_" },
    track_name_hint = { "EMF", "MCM36010" },

    default_homezone = "HOME_EMF_GENERIC",
    default_micfx = {
      [1] = "DF95_MicFX_EMF_Enhancer_V1",
    },
  },
}

-- Helper: lowercase contains
local function str_contains(str, needle)
  if not str or not needle then return false end
  str = tostring(str):lower()
  needle = tostring(needle):lower()
  return str:find(needle, 1, true) ~= nil
end

-- Profil per ID holen
function M.get_profile(device_id)
  if not device_id then return nil end
  return M.profiles[device_id]
end

-- Profil heuristisch aus Dateiname / Pfad / Tracknamen erkennen
function M.detect_from_name(name)
  if not name or name == "" then return nil end
  for _, p in pairs(M.profiles) do
    if p.filename_hint then
      for _, hint in ipairs(p.filename_hint) do
        if str_contains(name, hint) then
          return p
        end
      end
    end
    if p.track_name_hint then
      for _, hint in ipairs(p.track_name_hint) do
        if str_contains(name, hint) then
          return p
        end
      end
    end
  end
  return nil
end

-- Default MicFX für ein bestimmtes Device + Kanal
function M.get_default_micfx(device_id, ch)
  local p = M.get_profile(device_id)
  if not p or not p.default_micfx then return nil end
  return p.default_micfx[ch]
end

-- Default HomeZone für ein Device
function M.get_default_homezone(device_id)
  local p = M.get_profile(device_id)
  if not p then return nil end
  return p.default_homezone
end

return M
