-- @description Apply IDM Bus Recommended Settings (Bus_IDM, Bus_IDM_Drums, FXBus)
-- @version 1.0
-- @author DF95

local r = reaper

------------------------------------------------------------
-- Helper: Messaging
------------------------------------------------------------
local function msg(s)
  -- r.ShowConsoleMsg(tostring(s) .. "\n")
end

------------------------------------------------------------
-- Helper: FX finden und Parameter setzen
------------------------------------------------------------

local function find_fx_by_name(track, search)
  if not track then return nil end
  local fx_count = r.TrackFX_GetCount(track)
  for i = 0, fx_count-1 do
    local _, name = r.TrackFX_GetFXName(track, i, "")
    if name:lower():find(search:lower(), 1, true) then
      return i, name
    end
  end
  return nil
end

local function set_param_by_name_substring(track, fx_idx, label_sub, target_norm)
  if not track or not fx_idx then return end
  local param_count = r.TrackFX_GetNumParams(track, fx_idx)
  for p = 0, param_count - 1 do
    local retval, pname = r.TrackFX_GetParamName(track, fx_idx, p, "")
    if retval and pname:lower():find(label_sub:lower(), 1, true) then
      r.TrackFX_SetParamNormalized(track, fx_idx, p, target_norm)
      msg(("Set %s param '%s' to %.3f"):format(tostring(fx_idx), pname, target_norm))
    end
  end
end

local function set_plugin_param_by_name(track, plugin_search, param_label, target_norm)
  local fx_idx = select(1, find_fx_by_name(track, plugin_search))
  if not fx_idx then
    msg("FX not found: " .. plugin_search)
    return
  end
  set_param_by_name_substring(track, fx_idx, param_label, target_norm)
end

------------------------------------------------------------
-- Helper: JS Volume In/Out
------------------------------------------------------------

local function find_first_last_js_volume(track)
  if not track then return nil, nil end
  local fx_count = r.TrackFX_GetCount(track)
  local first_idx, last_idx = nil, nil
  for i = 0, fx_count - 1 do
    local _, name = r.TrackFX_GetFXName(track, i, "")
    if name:find("JS: Volume Adjustment", 1, true) then
      if not first_idx then first_idx = i end
      last_idx = i
    end
  end
  return first_idx, last_idx
end

local function set_js_volume_norm(track, fx_idx, target_norm)
  if not track or not fx_idx then return end
  r.TrackFX_SetParamNormalized(track, fx_idx, 0, target_norm)
end

------------------------------------------------------------
-- PROFILE-Funktionen
------------------------------------------------------------

local PROFILES = {}

-- A) Bus_IDM – Clicks, Pops, MicroPerc, Tonal/Granular

PROFILES["Bus_IDM_ClicksPops_Clean_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.35) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end
end

PROFILES["Bus_IDM_ClicksPops_Trash_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.4) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "Fracture", "Mix", 0.25)
  set_plugin_param_by_name(track, "Fracture", "Delay", 0.2)
  set_plugin_param_by_name(track, "Fracture", "Feedback", 0.15)
  set_plugin_param_by_name(track, "Fracture", "Filter", 0.5)

  set_plugin_param_by_name(track, "Ring Mod", "Frequency", 0.7)
  set_plugin_param_by_name(track, "Ring Mod", "Mix", 0.2)
end

PROFILES["Bus_IDM_MicroPerc_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.4) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end
end

PROFILES["Bus_IDM_TonalPerc_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.45) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "ToTape7", "Drive", 0.4)
  set_plugin_param_by_name(track, "ToTape7", "Output", 0.5)

  set_plugin_param_by_name(track, "Decimort", "Resampler", 0.7)
  set_plugin_param_by_name(track, "Decimort", "Bits", 0.8)
  set_plugin_param_by_name(track, "Decimort", "Jitter", 0.3)
  set_plugin_param_by_name(track, "Decimort", "Mix", 0.3)
end

PROFILES["Bus_IDM_GranularCrunch_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.4) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "Hysteresis", "Mix", 0.3)
  set_plugin_param_by_name(track, "Hysteresis", "Delay", 0.25)
  set_plugin_param_by_name(track, "Hysteresis", "Feedback", 0.2)

  set_plugin_param_by_name(track, "Fracture", "Mix", 0.25)
  set_plugin_param_by_name(track, "Fracture", "Delay", 0.25)
  set_plugin_param_by_name(track, "Fracture", "Feedback", 0.2)
end

-- B) Bus_IDM_Drums – Kicks / Snares / Hats

PROFILES["Bus_IDM_Kicks_Punch_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "Transient Shaper", "Attack", 0.7)
  set_plugin_param_by_name(track, "Transient Shaper", "Sustain", 0.4)
  set_plugin_param_by_name(track, "Transient Shaper", "Speed", 0.6)

  set_plugin_param_by_name(track, "Beat Slammer", "Amount", 0.6)
  set_plugin_param_by_name(track, "Beat Slammer", "Mix", 0.5)

  local fx_idx = select(1, find_fx_by_name(track, "ReaLimit"))
  if fx_idx then
    set_param_by_name_substring(track, fx_idx, "Ceiling", 0.83)
    set_param_by_name_substring(track, fx_idx, "Attack", 0.2)
    set_param_by_name_substring(track, fx_idx, "Release", 0.2)
  end
end

PROFILES["Bus_IDM_Kicks_Safe_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "Transient Shaper", "Attack", 0.6)
  set_plugin_param_by_name(track, "Transient Shaper", "Sustain", 0.45)

  local fx_idx = select(1, find_fx_by_name(track, "ReaComp"))
  if fx_idx then
    set_param_by_name_substring(track, fx_idx, "Ratio", 0.6)
    set_param_by_name_substring(track, fx_idx, "Attack", 0.2)
    set_param_by_name_substring(track, fx_idx, "Release", 0.3)
  end

  local lim_idx = select(1, find_fx_by_name(track, "ReaLimit"))
  if lim_idx then
    set_param_by_name_substring(track, lim_idx, "Ceiling", 0.83)
  end
end

PROFILES["Bus_IDM_Kicks_Extreme_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.55) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.45) end

  set_plugin_param_by_name(track, "Beat Slammer", "Amount", 0.8)
  set_plugin_param_by_name(track, "Beat Slammer", "Mix", 0.7)

  set_plugin_param_by_name(track, "Ruina", "Drive", 0.4)
  set_plugin_param_by_name(track, "Ruina", "Doom", 0.25)
  set_plugin_param_by_name(track, "Ruina", "Mix", 0.5)
end

PROFILES["Bus_IDM_Snares_Snap_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "Transient Shaper", "Attack", 0.8)
  set_plugin_param_by_name(track, "Transient Shaper", "Sustain", 0.3)
end

PROFILES["Bus_IDM_Snares_Soft_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  local fx_idx = select(1, find_fx_by_name(track, "ReaFIR"))
  if fx_idx then
    set_param_by_name_substring(track, fx_idx, "Mode", 0.25)
  end

  local comp_idx = select(1, find_fx_by_name(track, "ReaComp"))
  if comp_idx then
    set_param_by_name_substring(track, comp_idx, "Ratio", 0.5)
    set_param_by_name_substring(track, comp_idx, "Attack", 0.25)
    set_param_by_name_substring(track, comp_idx, "Release", 0.35)
  end
end

PROFILES["Bus_IDM_Snares_Extreme_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.55) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.45) end

  set_plugin_param_by_name(track, "Beat Slammer", "Amount", 0.8)
  set_plugin_param_by_name(track, "Beat Slammer", "Mix", 0.7)

  set_plugin_param_by_name(track, "Ruina", "Drive", 0.5)
  set_plugin_param_by_name(track, "Ruina", "Doom", 0.3)
  set_plugin_param_by_name(track, "Ruina", "Mix", 0.6)
end

PROFILES["Bus_IDM_Hats_Air_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "ToTape8", "Drive", 0.3)
  set_plugin_param_by_name(track, "ToTape8", "Output", 0.5)

  set_plugin_param_by_name(track, "Transient Shaper", "Attack", 0.6)
  set_plugin_param_by_name(track, "Transient Shaper", "Sustain", 0.4)
end

PROFILES["Bus_IDM_Hats_Safe_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  local lim_idx = select(1, find_fx_by_name(track, "ReaLimit"))
  if lim_idx then
    set_param_by_name_substring(track, lim_idx, "Ceiling", 0.8)
  end
end

PROFILES["Bus_IDM_Hats_Extreme_01"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.55) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.45) end

  set_plugin_param_by_name(track, "Fracture", "Mix", 0.2)
  set_plugin_param_by_name(track, "Hysteresis", "Mix", 0.2)
end

-- FXBus

PROFILES["FXBus_Reverb_01"] = function(track)
  local verb_idx = select(1, find_fx_by_name(track, "ReaVerbate")) or select(1, find_fx_by_name(track, "ReaVerb"))
  if verb_idx then
    set_param_by_name_substring(track, verb_idx, "Pre", 0.3)
    set_param_by_name_substring(track, verb_idx, "Decay", 0.4)
    set_param_by_name_substring(track, verb_idx, "HF", 0.6)
  end

  local eq_idx = select(1, find_fx_by_name(track, "ReaEQ"))
  if eq_idx then
    -- optional Filters
  end
end

PROFILES["FXBus_Delay_PingPong_01"] = function(track)
  local dly_idx = select(1, find_fx_by_name(track, "ReaDelay"))
  if dly_idx then
    set_param_by_name_substring(track, dly_idx, "Feedback", 0.3)
    set_param_by_name_substring(track, dly_idx, "LPF", 0.6)
    set_param_by_name_substring(track, dly_idx, "HPF", 0.3)
  end
end

PROFILES["FXBus_Granular_Light"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "DF95_Granular_Hold", "Grain", 0.3)
  set_plugin_param_by_name(track, "DF95_Granular_Hold", "Jitter", 0.2)
  set_plugin_param_by_name(track, "DF95_Granular_Hold", "Mix", 0.2)
end

PROFILES["FXBus_Granular_Heavy"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.45) end

  set_plugin_param_by_name(track, "Fracture", "Mix", 0.4)
  set_plugin_param_by_name(track, "Fracture", "Delay", 0.3)
  set_plugin_param_by_name(track, "Fracture", "Feedback", 0.25)

  set_plugin_param_by_name(track, "DF95_Granular_Hold", "Grain", 0.6)
  set_plugin_param_by_name(track, "DF95_Granular_Hold", "Jitter", 0.5)
  set_plugin_param_by_name(track, "DF95_Granular_Hold", "Mix", 0.5)
end

PROFILES["FXBus_PitchWobble_ModSync"] = function(track)
  local in_fx, out_fx = find_first_last_js_volume(track)
  if in_fx then set_js_volume_norm(track, in_fx, 0.5) end
  if out_fx then set_js_volume_norm(track, out_fx, 0.5) end

  set_plugin_param_by_name(track, "Frequency Shifter", "Shift", 0.55)
  set_plugin_param_by_name(track, "Frequency Shifter", "Mix", 0.35)

  set_plugin_param_by_name(track, "Formant Filter", "Mix", 0.3)

  set_plugin_param_by_name(track, "Stereo_Alternator", "Rate", 0.4)
  set_plugin_param_by_name(track, "Stereo_Alternator", "Depth", 0.6)
end

------------------------------------------------------------
-- GUI: Profil-Auswahl
------------------------------------------------------------

local function choose_profile()
  local keys = {}
  for name in pairs(PROFILES) do keys[#keys+1] = name end
  table.sort(keys)

  local items = {"DF95 IDM Bus Recommended:"}
  for _, k in ipairs(keys) do
    items[#items+1] = k
  end
  local menu_str = table.concat(items, "|")

  gfx.init("DF95 IDM Bus Profiles", 0, 0)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local idx = gfx.showmenu(menu_str)
  gfx.quit()

  if idx <= 1 then return nil end
  return keys[idx-1]
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local profile_name = choose_profile()
  if not profile_name then return end

  local fn = PROFILES[profile_name]
  if not fn then
    r.ShowMessageBox("Profil nicht gefunden: " .. tostring(profile_name), "DF95 IDM Bus", 0)
    return
  end

  local num_sel = r.CountSelectedTracks(0)
  if num_sel == 0 then
    r.ShowMessageBox("Bitte einen oder mehrere Tracks auswählen.", "DF95 IDM Bus", 0)
    return
  end

  r.Undo_BeginBlock()
  for i = 0, num_sel-1 do
    local tr = r.GetSelectedTrack(0, i)
    fn(tr)
  end
  r.Undo_EndBlock("DF95 Apply IDM Bus Profile: " .. profile_name, -1)
end

main()
