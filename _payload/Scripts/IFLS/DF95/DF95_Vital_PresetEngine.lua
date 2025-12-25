-- @description Vital Preset Engine (Role + Flavor Based)
-- @author You
-- @version 1.0
-- @about
--   Einfache Preset-Engine für Vital:
--     • erkennt Vital über FX-Namen
--     • setzt Filter, Env1, Unison, Drive, Macros
--     • pro Synth-Rolle (bass/lead/pad/keys/pluck/fx/drone)
--     • Variante = Flavor: "clean", "color", "aggressive", "weird"

local r = reaper
local M = {}

local function set_param_like(tr, fx_idx, substrs, value)
  if not tr or not substrs then return end
  local cnt = r.TrackFX_GetNumParams(tr, fx_idx) or 0
  if cnt <= 0 then return end
  local list = type(substrs) == "table" and substrs or {substrs}
  local val = math.max(0, math.min(1, value or 0))
  for p = 0, cnt-1 do
    local ok, pname = r.TrackFX_GetParamName(tr, fx_idx, p, "")
    if ok and pname and pname ~= "" then
      local ln = pname:lower()
      for _, s in ipairs(list) do
        local ls = s:lower()
        if ln:find(ls, 1, true) then
          r.TrackFX_SetParam(tr, fx_idx, p, val)
        end
      end
    end
  end
end

function M.IsVitalFXName(fxname)
  if not fxname then return false end
  local l = fxname:lower()
  return l:find("vital", 1, true) ~= nil
end

local function set_filter1(tr, fx_idx, cutoff, res)
  set_param_like(tr, fx_idx, { "filter 1 cutoff", "cutoff", "flt1 cutoff" }, cutoff)
  set_param_like(tr, fx_idx, { "filter 1 resonance", "resonance", "res" }, res)
end

local function set_env1_adsr(tr, fx_idx, a, d, s, rls)
  set_param_like(tr, fx_idx, { "env 1 attack", "env1 attack", "attack" }, a)
  set_param_like(tr, fx_idx, { "env 1 decay",  "env1 decay",  "decay" },  d)
  set_param_like(tr, fx_idx, { "env 1 sustain","env1 sustain","sustain"}, s)
  set_param_like(tr, fx_idx, { "env 1 release","env1 release","release"}, rls)
end

local function set_unison(tr, fx_idx, amount)
  set_param_like(tr, fx_idx, { "unison detune", "detune", "spread" }, amount)
end

local function set_drive(tr, fx_idx, amount)
  set_param_like(tr, fx_idx, { "drive", "distortion", "dist", "saturation" }, amount)
end

local function set_osc_mix(tr, fx_idx, osc1, osc2)
  set_param_like(tr, fx_idx, { "osc 1 level", "osc1 level", "osc1 volume" }, osc1)
  set_param_like(tr, fx_idx, { "osc 2 level", "osc2 level", "osc2 volume" }, osc2)
end

local function set_macro(tr, fx_idx, macro_idx, amount)
  amount = math.max(0, math.min(1, amount or 0))
  if macro_idx == 1 then
    set_param_like(tr, fx_idx, { "macro 1", "macro1" }, amount)
  elseif macro_idx == 2 then
    set_param_like(tr, fx_idx, { "macro 2", "macro2" }, amount)
  elseif macro_idx == 3 then
    set_param_like(tr, fx_idx, { "macro 3", "macro3" }, amount)
  elseif macro_idx == 4 then
    set_param_like(tr, fx_idx, { "macro 4", "macro4" }, amount)
  end
end

local function apply_for_role_and_flavor(tr, fx_idx, role, flavor)
  flavor = (flavor or "color"):lower()
  role   = (role   or "bass"):lower()

  if role == "bass" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 1.0, 0.0)
      set_filter1(tr, fx_idx, 0.2, 0.2)
      set_env1_adsr(tr, fx_idx, 0.005, 0.15, 0.85, 0.10)
      set_unison(tr, fx_idx, 0.1)
      set_drive(tr, fx_idx, 0.05)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.9, 0.3)
      set_filter1(tr, fx_idx, 0.3, 0.25)
      set_env1_adsr(tr, fx_idx, 0.004, 0.18, 0.8, 0.12)
      set_unison(tr, fx_idx, 0.2)
      set_drive(tr, fx_idx, 0.2)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 0.9, 0.6)
      set_filter1(tr, fx_idx, 0.4, 0.4)
      set_env1_adsr(tr, fx_idx, 0.003, 0.16, 0.7, 0.12)
      set_unison(tr, fx_idx, 0.35)
      set_drive(tr, fx_idx, 0.6)
      set_macro(tr, fx_idx, 1, 0.7)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.8, 0.8)
      set_filter1(tr, fx_idx, 0.45, 0.6)
      set_env1_adsr(tr, fx_idx, 0.01, 0.25, 0.7, 0.2)
      set_unison(tr, fx_idx, 0.5)
      set_drive(tr, fx_idx, 0.5)
      set_macro(tr, fx_idx, 2, 0.8)
    end

  elseif role == "lead" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 0.8, 0.3)
      set_filter1(tr, fx_idx, 0.55, 0.2)
      set_env1_adsr(tr, fx_idx, 0.01, 0.18, 0.85, 0.2)
      set_unison(tr, fx_idx, 0.2)
      set_drive(tr, fx_idx, 0.1)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.9, 0.5)
      set_filter1(tr, fx_idx, 0.65, 0.25)
      set_env1_adsr(tr, fx_idx, 0.005, 0.18, 0.8, 0.18)
      set_unison(tr, fx_idx, 0.3)
      set_drive(tr, fx_idx, 0.25)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 0.9, 0.7)
      set_filter1(tr, fx_idx, 0.7, 0.45)
      set_env1_adsr(tr, fx_idx, 0.003, 0.16, 0.75, 0.18)
      set_unison(tr, fx_idx, 0.4)
      set_drive(tr, fx_idx, 0.5)
      set_macro(tr, fx_idx, 2, 0.8)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.8, 0.8)
      set_filter1(tr, fx_idx, 0.6, 0.5)
      set_env1_adsr(tr, fx_idx, 0.02, 0.3, 0.7, 0.25)
      set_unison(tr, fx_idx, 0.45)
      set_drive(tr, fx_idx, 0.4)
      set_macro(tr, fx_idx, 3, 0.8)
    end

  elseif role == "pad" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 0.8, 0.4)
      set_filter1(tr, fx_idx, 0.4, 0.3)
      set_env1_adsr(tr, fx_idx, 0.12, 0.6, 0.9, 0.85)
      set_unison(tr, fx_idx, 0.4)
      set_drive(tr, fx_idx, 0.1)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.85, 0.6)
      set_filter1(tr, fx_idx, 0.5, 0.35)
      set_env1_adsr(tr, fx_idx, 0.15, 0.7, 0.9, 0.9)
      set_unison(tr, fx_idx, 0.5)
      set_drive(tr, fx_idx, 0.15)
      set_macro(tr, fx_idx, 1, 0.5)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 0.9, 0.8)
      set_filter1(tr, fx_idx, 0.55, 0.45)
      set_env1_adsr(tr, fx_idx, 0.18, 0.8, 0.9, 0.9)
      set_unison(tr, fx_idx, 0.6)
      set_drive(tr, fx_idx, 0.25)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.7, 0.8)
      set_filter1(tr, fx_idx, 0.6, 0.5)
      set_env1_adsr(tr, fx_idx, 0.2, 0.9, 0.9, 1.0)
      set_unison(tr, fx_idx, 0.65)
      set_drive(tr, fx_idx, 0.3)
      set_macro(tr, fx_idx, 2, 0.7)
    end

  elseif role == "keys" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 0.8, 0.2)
      set_filter1(tr, fx_idx, 0.55, 0.25)
      set_env1_adsr(tr, fx_idx, 0.01, 0.25, 0.7, 0.2)
      set_unison(tr, fx_idx, 0.2)
      set_drive(tr, fx_idx, 0.1)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.85, 0.4)
      set_filter1(tr, fx_idx, 0.6, 0.3)
      set_env1_adsr(tr, fx_idx, 0.008, 0.22, 0.7, 0.2)
      set_unison(tr, fx_idx, 0.25)
      set_drive(tr, fx_idx, 0.2)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 0.9, 0.6)
      set_filter1(tr, fx_idx, 0.65, 0.35)
      set_env1_adsr(tr, fx_idx, 0.005, 0.2, 0.65, 0.18)
      set_unison(tr, fx_idx, 0.3)
      set_drive(tr, fx_idx, 0.35)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.8, 0.8)
      set_filter1(tr, fx_idx, 0.6, 0.5)
      set_env1_adsr(tr, fx_idx, 0.008, 0.25, 0.6, 0.2)
      set_unison(tr, fx_idx, 0.35)
      set_drive(tr, fx_idx, 0.4)
      set_macro(tr, fx_idx, 3, 0.7)
    end

  elseif role == "pluck" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 0.8, 0.3)
      set_filter1(tr, fx_idx, 0.6, 0.25)
      set_env1_adsr(tr, fx_idx, 0.002, 0.12, 0.35, 0.12)
      set_unison(tr, fx_idx, 0.25)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.85, 0.4)
      set_filter1(tr, fx_idx, 0.65, 0.3)
      set_env1_adsr(tr, fx_idx, 0.002, 0.14, 0.4, 0.14)
      set_unison(tr, fx_idx, 0.3)
      set_drive(tr, fx_idx, 0.25)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 0.9, 0.5)
      set_filter1(tr, fx_idx, 0.7, 0.35)
      set_env1_adsr(tr, fx_idx, 0.001, 0.12, 0.3, 0.12)
      set_unison(tr, fx_idx, 0.35)
      set_drive(tr, fx_idx, 0.35)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.8, 0.7)
      set_filter1(tr, fx_idx, 0.7, 0.4)
      set_env1_adsr(tr, fx_idx, 0.002, 0.15, 0.4, 0.16)
      set_unison(tr, fx_idx, 0.4)
      set_drive(tr, fx_idx, 0.4)
      set_macro(tr, fx_idx, 4, 0.7)
    end

  elseif role == "fx" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 0.7, 0.7)
      set_filter1(tr, fx_idx, 0.65, 0.4)
      set_env1_adsr(tr, fx_idx, 0.02, 0.5, 0.7, 0.6)
      set_unison(tr, fx_idx, 0.5)
      set_drive(tr, fx_idx, 0.3)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.8, 0.8)
      set_filter1(tr, fx_idx, 0.6, 0.5)
      set_env1_adsr(tr, fx_idx, 0.03, 0.6, 0.75, 0.65)
      set_unison(tr, fx_idx, 0.55)
      set_drive(tr, fx_idx, 0.35)
      set_macro(tr, fx_idx, 1, 0.6)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 0.9, 0.9)
      set_filter1(tr, fx_idx, 0.55, 0.6)
      set_env1_adsr(tr, fx_idx, 0.04, 0.7, 0.8, 0.7)
      set_unison(tr, fx_idx, 0.6)
      set_drive(tr, fx_idx, 0.5)
      set_macro(tr, fx_idx, 2, 0.8)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.9, 0.9)
      set_filter1(tr, fx_idx, 0.5, 0.7)
      set_env1_adsr(tr, fx_idx, 0.05, 0.8, 0.8, 0.8)
      set_unison(tr, fx_idx, 0.7)
      set_drive(tr, fx_idx, 0.6)
      set_macro(tr, fx_idx, 3, 0.9)
    end

  elseif role == "drone" then
    if flavor == "clean" then
      set_osc_mix(tr, fx_idx, 0.8, 0.5)
      set_filter1(tr, fx_idx, 0.35, 0.4)
      set_env1_adsr(tr, fx_idx, 0.3, 1.0, 1.0, 1.0)
      set_unison(tr, fx_idx, 0.5)
      set_drive(tr, fx_idx, 0.15)
    elseif flavor == "color" then
      set_osc_mix(tr, fx_idx, 0.9, 0.6)
      set_filter1(tr, fx_idx, 0.4, 0.45)
      set_env1_adsr(tr, fx_idx, 0.35, 1.0, 1.0, 1.0)
      set_unison(tr, fx_idx, 0.6)
      set_drive(tr, fx_idx, 0.2)
      set_macro(tr, fx_idx, 1, 0.5)
    elseif flavor == "aggressive" then
      set_osc_mix(tr, fx_idx, 1.0, 0.8)
      set_filter1(tr, fx_idx, 0.45, 0.5)
      set_env1_adsr(tr, fx_idx, 0.4, 1.0, 1.0, 1.0)
      set_unison(tr, fx_idx, 0.7)
      set_drive(tr, fx_idx, 0.3)
    elseif flavor == "weird" then
      set_osc_mix(tr, fx_idx, 0.9, 0.9)
      set_filter1(tr, fx_idx, 0.5, 0.6)
      set_env1_adsr(tr, fx_idx, 0.45, 1.0, 1.0, 1.0)
      set_unison(tr, fx_idx, 0.75)
      set_drive(tr, fx_idx, 0.4)
      set_macro(tr, fx_idx, 2, 0.8)
      set_macro(tr, fx_idx, 3, 0.7)
    end
  end
end

function M.ApplyPresetForType(tr, fx_idx, synth_type, flavor)
  if not tr or not fx_idx or fx_idx < 0 then return end
  apply_for_role_and_flavor(tr, fx_idx, synth_type, flavor)
end

return M
