-- DF95_Signature_Apply_JSON.lua
-- Applies JSON-based DF95 signature presets for multiple DF95 synths.
--
-- Supported (via synth_id in JSON and MetaCore id):
--   - vital
--   - surge_xt
--   - dexed
--   - exaktlite
--   - tal_noisemaker
--   - tyrelln6
--   - triplecheese
--   - grainbow
--   - chowkick
--   - adc_clap
--   - bucketpops
--   - thump_one
--
-- Preset files live in:
--   <ResourcePath>/Scripts/IFLS/DF95/presets/<SynthFolder>/
--
-- SynthFolder mapping:
--   vital        -> Vital
--   surge_xt     -> SurgeXT
--   dexed        -> Dexed
--   exaktlite    -> ExaktLite
--   tal_noisemaker -> TAL_NoiseMaker
--   tyrelln6     -> TyrellN6
--   triplecheese -> TripleCheese
--   grainbow     -> gRainbow
--   chowkick     -> ChowKick
--   adc_clap     -> adc_Clap
--   bucketpops   -> BucketPops
--   thump_one    -> ThumpOne
--
-- Filenames:
--   <role>_<variant>.json
--   e.g.
--     bass_idm_sub_soft.json
--     lead_idm_lead_soft.json
--     pad_wash_motion.json
--     fx_idm_glitch_hard.json
--     keys_ep_soft.json
--     pluck_idm_pluck_sharp.json
--     drum_tight.json
--
-- JSON structure:
-- {
--   "version": 1,
--   "synth_id": "vital" | "surge_xt" | "dexed" | ...,
--   "role": "bass" | "lead" | "pad" | "fx" | "keys" | "pluck" | "drum",
--   "variant": "idm_sub_soft",
--   "description": "...",
--   "params": {
--     "amp_env.attack": 0.0,
--     "filter.cutoff": 0.3,
--     "macros.1": 0.4,
--     "sceneA.amp_env.attack": 0.0,
--     "sceneA.filter1.cutoff": 0.3,
--     "operators.1.output_level": 0.8,
--     "operators.A.output_level": 0.8,
--     "master.grain_rate": 0.25,
--     "drum.kick.freq": 0.3,
--     "global.tempo": 0.4,
--     "master.pitch": 0.45
--   }
-- }
--
-- This script:
--   1. Detects current FX via MetaCore.get_fxinfo.
--   2. Reads MetaCore id (synth_id).
--   3. Asks for role + variant.
--   4. Loads JSON preset and maps to ParamMap fields, then applies values.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function load_metacore()
  local resource_path = r.GetResourcePath()
  local mc_path = resource_path .. "/Scripts/IFLS/DF95/DF95_MetaCore_VST_All_vsti.lua"
  local ok, mod = pcall(dofile, mc_path)
  if not ok then
    msg("Could not load MetaCore module:\n" .. tostring(mod))
    return nil
  end
  return mod
end

local function get_target_fx()
  local rv, track_idx, item_idx, fx_idx = r.GetFocusedFX()
  if rv == 1 then
    local track = r.GetTrack(0, track_idx - 1)
    return track, fx_idx
  end

  local track = r.GetSelectedTrack(0, 0)
  if track then
    local fx_count = r.TrackFX_GetCount(track)
    if fx_count > 0 then
      return track, 0
    end
  end
  return nil, nil
end

local function ask_role_and_variant()
  local role_ok, role = r.GetUserInputs(
    "DF95 JSON Signature - Role",
    1,
    "Role (bass/lead/pad/fx/keys/pluck/drum):",
    "bass"
  )
  if not role_ok or not role or role == "" then return nil, nil end
  role = role:match("^%s*(.-)%s*$")
  role = role:lower()

  local var_ok, variant = r.GetUserInputs(
    "DF95 JSON Signature - Variant",
    1,
    "Variant (e.g. deep_idm_sub_soft, idm_lead_soft, wash_soft, idm_glitch_hard, ep_soft, fm_pluck_soft, tight):",
    "idm_sub_soft"
  )
  if not var_ok or not variant or variant == "" then return nil, nil end
  variant = variant:match("^%s*(.-)%s*$")
  variant = variant:lower()

  return role, variant
end

local function set_param(track, fx, idx, val)
  if not idx or idx < 0 then return end
  r.TrackFX_SetParam(track, fx, idx, val)
end

----------------------------------------------------------------------
-- Minimal JSON reading
----------------------------------------------------------------------

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local c = f:read("*a")
  f:close()
  return c
end

local function parse_simple_json_preset(txt)
  if not txt then return nil end
  local t = {}

  t.synth_id = txt:match('"synth_id"%s*:%s*"(.-)"')
  t.role     = txt:match('"role"%s*:%s*"(.-)"')
  t.variant  = txt:match('"variant"%s*:%s*"(.-)"')
  t.description = txt:match('"description"%s*:%s*"(.-)"')

  local params_block = txt:match('"params"%s*:%s*{(.-)}')
  local params = {}
  if params_block then
    for key, num in params_block:gmatch('"(.-)"%s*:%s*([%-%d%.]+)') do
      params[key] = tonumber(num)
    end
  end
  t.params = params
  return t
end

----------------------------------------------------------------------
-- Mapping JSON param keys -> ParamMap indices
----------------------------------------------------------------------

local function apply_params_from_preset(track, fx, pmap, params)
  if not pmap or not params then return end

  for key, val in pairs(params) do
    local section1, rest = key:match("^([^%.]+)%.(.+)$")
    if section1 and rest then
      if section1 == "amp_env" then
        local env = pmap.amp_env
        if env then
          local idx = env[rest]
          set_param(track, fx, idx, val)
        end

      elseif section1 == "filter" then
        local f = pmap.filter
        if f then
          local idx = f[rest]
          set_param(track, fx, idx, val)
        end

      elseif section1 == "macros" then
        local macros = pmap.macros
        if macros then
          local num = tonumber(rest)
          if num then
            local idx = macros[num]
            set_param(track, fx, idx, val)
          end
        end

      elseif section1 == "sceneA" then
        -- Surge XT Scene A
        local section2, field = rest:match("^([^%.]+)%.(.+)$")
        if section2 and field then
          local sa = pmap.sceneA
          if sa then
            if section2 == "amp_env" and sa.amp_env then
              local idx = sa.amp_env[field]
              set_param(track, fx, idx, val)
            elseif section2 == "filter_env" and sa.filter_env then
              local idx = sa.filter_env[field]
              set_param(track, fx, idx, val)
            elseif section2 == "filter1" and sa.filter1 then
              local idx = sa.filter1[field]
              set_param(track, fx, idx, val)
            end
          end
        end

      elseif section1 == "operators" then
        -- Dexed / ExaktLite style operators
        local op_id, field = rest:match("^([^%.]+)%.(.+)$")
        if op_id and field and pmap.operators then
          local op_key = tonumber(op_id) or op_id
          local op = pmap.operators[op_key]
          if op then
            local idx = op[field]
            set_param(track, fx, idx, val)
          end
        end

      elseif section1 == "master" then
        -- gRainbow / ThumpOne master
        local m = pmap.master
        if m then
          local idx = m[rest]
          set_param(track, fx, idx, val)
        end

      elseif section1 == "drum" then
        -- Drum synth helpers: ChowKick, adc Clap, BucketPops, ThumpOne
        local sub, field = rest:match("^([^%.]+)%.(.+)$")
        if sub and field and pmap.drum then
          local d = pmap.drum[sub]
          if d then
            local idx = d[field]
            set_param(track, fx, idx, val)
          end
        end

      elseif section1 == "global" then
        -- e.g. BucketPops global.*
        local g = pmap.global
        if g then
          local idx = g[rest]
          set_param(track, fx, idx, val)
        end

      end
    end
  end
end

----------------------------------------------------------------------
-- MAIN
----------------------------------------------------------------------

r.ClearConsole()

local mc = load_metacore()
if not mc then return end

local track, fx = get_target_fx()
if not track then
  msg("No focused FX or FX on selected track.")
  return
end

local info = mc.get_fxinfo and mc.get_fxinfo(track, fx)
if not info then
  msg("MetaCore: no info for this FX.")
  return
end

local fx_name = info.fx_name or "?"
local meta = info.meta or {}
local pmap = info.params
local id   = meta.id or "?"

msg("DF95 JSON Signature for FX: " .. tostring(fx_name))
msg("id = " .. tostring(id) .. ", kind = " .. tostring(meta.kind))

-- Map MetaCore id -> preset folder
local folder_map = {
  vital           = "Vital",
  surge_xt        = "SurgeXT",
  dexed           = "Dexed",
  exaktlite       = "ExaktLite",
  tal_noisemaker  = "TAL_NoiseMaker",
  tyrelln6        = "TyrellN6",
  triplecheese    = "TripleCheese",
  grainbow        = "gRainbow",
  chowkick        = "ChowKick",
  adc_clap        = "adc_Clap",
  bucketpops      = "BucketPops",
  thump_one       = "ThumpOne",

  reasynth        = "ReaSynth",
  sqkone          = "SQKone",
  leems           = "Leems",
  expanse         = "Expanse",
  verv            = "Verv",
  pendulate       = "Pendulate",
  bong            = "Bong",
  drum_boxx       = "DrumBoxx",
  drumatic3       = "Drumatic3",
  stoooner        = "Stoooner",

  attracktive     = "Attracktive",
  halion_sonic    = "HALionSonic",
  helm            = "Helm",
  podolski        = "Podolski",
  reasamplomatic5000 = "ReaSamplOmatic5000",
  sinc_vereor     = "SincVereor",
  t_force_zenith  = "TForceZenith",
  tactic          = "Tactic",
  virt_vereor     = "VirtVereor",
  voltage_modular = "VoltageModular",
  zyklop          = "Zyklop",
  mndala2         = "MNDALA2",
  reasyn_dr       = "ReaSynDr",
  ua_battalion    = "UnfilteredAudioBattalion",}

local folder_name = folder_map[id]
if not folder_name then
  msg("This FX id (" .. tostring(id) .. ") has no JSON preset folder mapping yet.")
  return
end

local role, variant = ask_role_and_variant()
if not role or not variant then
  msg("DF95 JSON Signature: cancelled.")
  return
end

local resource_path = r.GetResourcePath()
local base = resource_path .. "/Scripts/IFLS/DF95/presets/"
local folder = base .. folder_name .. "/"

local fname = string.format("%s_%s.json", role, variant)
local full_path = folder .. fname

msg("Trying preset file: " .. full_path)

local txt, err = read_file(full_path)
if not txt then
  msg("Could not read preset file: " .. tostring(err))
  return
end

local preset = parse_simple_json_preset(txt)
if not preset then
  msg("Failed to parse JSON preset.")
  return
end

if preset.synth_id and preset.synth_id ~= id then
  msg("Preset synth_id (" .. tostring(preset.synth_id) .. ") does not match FX id (" .. tostring(id) .. ").")
  return
end

if preset.role and preset.role ~= role then
  msg("Warning: preset role (" .. tostring(preset.role) .. ") differs from requested role (" .. tostring(role) .. ").")
end

apply_params_from_preset(track, fx, pmap, preset.params)

msg("DF95 JSON Signature applied: " .. tostring(preset.description or (id .. " " .. role .. " " .. variant)))
