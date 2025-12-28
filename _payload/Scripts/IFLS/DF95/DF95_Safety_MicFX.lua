-- @description DF95 Safety MicFX Helper (Stufe 3)
-- @version 1.0
-- @author DF95
-- @about
--   Analysiert Tracks im Explode-Kontext und protokolliert, ob plausible MicFX-Ketten gesetzt sind.
--   Diese Version arbeitet konservativ: sie schreibt nur Warnungen ins Log,
--   verändert aber keine FX-Chain automatisch.

local r = reaper

local SafetyMicFX = {}

local function dbg(msg)
  if _G.DF95_DEBUG_SAFETY then
    r.ShowConsoleMsg("[DF95 MicFX Safety] " .. tostring(msg) .. "\n")
  end
end

local function get_track_name(tr)
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  name = name or ""
  return name:lower()
end

local function guess_mic_role_from_name(tr)
  local n = get_track_name(tr)
  if n:find("zoom") and n:find("f6") then
    return "zoom_f6"
  elseif n:find("zoom") and (n:find("h5") or n:find("h4")) then
    return "zoom_h_series"
  elseif n:find("emf") or n:find("coil") then
    return "emf_coil"
  elseif n:find("lav") or n:find("lavalier") then
    return "lav"
  elseif n:find("dyn") or n:find("md400") or n:find("xm8500") then
    return "dynamic"
  elseif n:find("cond") or n:find("mk4") or n:find("mic2") then
    return "condenser"
  elseif n:find("phone") or n:find("fieldrec") then
    return "phone"
  end
  return "unknown"
end

local function count_fx(tr)
  return r.TrackFX_GetCount(tr)
end

function SafetyMicFX.run_for_selected_tracks()
  local num_sel_tr = r.CountSelectedTracks(0)
  if num_sel_tr == 0 then
    dbg("Keine selektierten Tracks für MicFX-Analyse.")
    return
  end

  for ti = 0, num_sel_tr-1 do
    local tr = r.GetSelectedTrack(0, ti)
    local role = guess_mic_role_from_name(tr)
    local fx_count = count_fx(tr)

    if role ~= "unknown" and fx_count == 0 then
      dbg(string.format(
        "Track ohne FX, aber Mic-Rolle erkannt: %s (rolle=%s) – prüfe MicFX-Profil.",
        ({r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)})[2] or "unnamed",
        role
      ))
    end
  end
end

return SafetyMicFX
