-- IFLS_TX16WxStyleDomain.lua
-- Phase 47: TX16Wx Style Macros (Filter, LFO, Velocity)

local r = reaper
local M = {}

M.styles = {
  STRAIGHT = {
    name = "Straight",
    cutoff_factor   = 1.0,
    res_boost       = 0.0,
    lfo_cut_depth   = 0.0,
    lfo_pitch_depth = 0.0,
    vel_sensitivity = 0.5,
  },
  IDM = {
    name = "IDM / Glitch",
    cutoff_factor   = 0.8,
    res_boost       = 0.3,
    lfo_cut_depth   = 0.7,
    lfo_pitch_depth = 0.2,
    vel_sensitivity = 0.8,
  },
  IDM_DENSE = {
    name = "IDM Dense",
    cutoff_factor   = 0.7,  -- etwas dunkler, mehr Reso
    res_boost       = 0.4,
    lfo_cut_depth   = 0.8,
    lfo_pitch_depth = 0.25,
    vel_sensitivity = 0.9,
  },
  IDM_SPARSE = {
    name = "IDM Sparse",
    cutoff_factor   = 0.9,
    res_boost       = 0.2,
    lfo_cut_depth   = 0.4,
    lfo_pitch_depth = 0.15,
    vel_sensitivity = 0.7,
  },
  CLICKS_POP = {
    name = "Clicks & Pops",
    cutoff_factor   = 1.2,
    res_boost       = 0.1,
    lfo_cut_depth   = 0.2,
    lfo_pitch_depth = 0.3,
    vel_sensitivity = 0.7,
  },
  MICROBEAT = {
    name = "Microbeats",
    cutoff_factor   = 0.9,
    res_boost       = 0.2,
    lfo_cut_depth   = 0.5,
    lfo_pitch_depth = 0.4,
    vel_sensitivity = 0.9,
  },
  MICROSTUTTER = {
    name = "Microstutter / Granular",
    cutoff_factor   = 1.0,
    res_boost       = 0.25,
    lfo_cut_depth   = 0.9,
    lfo_pitch_depth = 0.5,
    vel_sensitivity = 0.85,
  },
}

local function is_tx16wx_fx(tr, fx_idx)
  local _, name = r.TrackFX_GetFXName(tr, fx_idx, "")
  name = name:lower()
  return name:find("tx16wx", 1, true) ~= nil
end

local function find_tx16wx_instances()
  local proj = 0
  local instances = {}
  local track_cnt = r.CountTracks(proj)
  for ti = 0, track_cnt-1 do
    local tr = r.GetTrack(proj, ti)
    local fx_cnt = r.TrackFX_GetCount(tr)
    for fi = 0, fx_cnt-1 do
      if is_tx16wx_fx(tr, fi) then
        instances[#instances+1] = { track = tr, fx = fi }
      end
    end
  end
  return instances
end

local function safe_set_param(tr, fx, idx, val01)
  if not tr then return end
  val01 = math.max(0, math.min(1, val01 or 0))
  r.TrackFX_SetParam(tr, fx, idx, val01)
end

function M.apply_style(style_id)
  local style = M.styles[style_id] or M.styles["STRAIGHT"]

  local instances = find_tx16wx_instances()
  if #instances == 0 then
    r.ShowMessageBox("Keine TX16Wx-Instanzen im Projekt gefunden.",
      "IFLS TX16Wx Style Domain", 0)
    return
  end

  for _, inst in ipairs(instances) do
    local tr, fx = inst.track, inst.fx
    local param_cnt = r.TrackFX_GetNumParams(tr, fx)

    for pi = 0, param_cnt-1 do
      local _, pname = r.TrackFX_GetParamName(tr, fx, pi, "")
      local pn = pname:lower()

      -- Cutoff
      if pn:find("cutoff", 1, true) or pn:find("filter freq", 1, true) then
        local val = r.TrackFX_GetParam(tr, fx, pi)
        safe_set_param(tr, fx, pi, math.max(0.0, math.min(1.0, val * style.cutoff_factor)))
      end

      -- Resonance
      if pn:find("resonance", 1, true) or pn:find("res", 1, true) then
        local val = r.TrackFX_GetParam(tr, fx, pi)
        safe_set_param(tr, fx, pi, math.max(0.0, math.min(1.0, val + style.res_boost)))
      end

      -- LFO -> Filter
      if pn:find("lfo", 1, true) and pn:find("cutoff", 1, true) then
        safe_set_param(tr, fx, pi, style.lfo_cut_depth)
      end

      -- LFO -> Pitch
      if pn:find("lfo", 1, true) and pn:find("pitch", 1, true) then
        safe_set_param(tr, fx, pi, style.lfo_pitch_depth)
      end

      -- Amp Velocity sensitivity
      if pn:find("vel", 1, true) and (pn:find("amp", 1, true) or pn:find("volume", 1, true)) then
        safe_set_param(tr, fx, pi, style.vel_sensitivity)
      end
    end
  end

  r.ShowMessageBox(
    string.format("TX16Wx Style '%s' auf %d Instanzen angewendet.",
      style.name, #instances),
    "IFLS TX16Wx Style Domain", 0)
end

return M
