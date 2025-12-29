-- DF95_Signature_Export_JSON.lua
-- "Preset Recorder" for DF95 JSON signature system.
--
-- Behavior:
--   - Detects current FX via DF95 MetaCore (id, params, kind).
--   - Asks for role, variant, (optional) description.
--   - Walks the ParamMap (amp_env, filter, macros, sceneA, operators, master, drum, global)
--     and reads current parameter values.
--   - Writes a JSON preset into the appropriate folder:
--       <ResourcePath>/Scripts/IFLS/DF95/presets/<SynthFolder>/<role>_<variant>.json
--
-- This lets you "capture" a sound you dialed in, in the same JSON format that
-- DF95_Signature_Apply_JSON.lua and DF95_Signature_GUI_ImGui.lua can apply later.

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

local function ask_meta(role_default, variant_default, desc_default)
  local ok, csv = r.GetUserInputs(
    "DF95 JSON Preset Export",
    3,
    "Role (bass/lead/pad/fx/keys/pluck/drum):,Variant (idm_sub_soft / analog_bass_solid / etc):,Description:",
    (role_default or "bass") .. "," .. (variant_default or "idm_sub_soft") .. "," .. (desc_default or "")
  )
  if not ok then return nil end

  local role, variant, desc = csv:match("([^,]*),([^,]*),?(.*)")
  if not role or role == "" then return nil end

  role = role:match("^%s*(.-)%s*$")
  variant = (variant or ""):match("^%s*(.-)%s*$")
  desc = (desc or ""):match("^%s*(.-)%s*$")

  return {
    role = role:lower(),
    variant = variant,
    description = desc,
  }
end

local function get_param(track, fx, idx)
  if not idx or idx < 0 then return nil end
  local ok, val = r.TrackFX_GetParam(track, fx, idx)
  if not ok then return nil end
  return val
end

-- folder mapping must match the Apply + GUI scripts
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

----------------------------------------------------------------------
-- Collect params from ParamMap
----------------------------------------------------------------------

local function collect_params(track, fx, pmap)
  local params = {}

  -- Helper to read a table of key -> param_index into section.key -> value
  local function collect_section(section_table, prefix)
    if not section_table then return end
    for k, idx in pairs(section_table) do
      if type(idx) == "number" then
        local v = get_param(track, fx, idx)
        if v then
          params[prefix .. k] = v
        end
      end
    end
  end

  -- Amp env / filter / macros
  if pmap.amp_env then
    collect_section(pmap.amp_env, "amp_env.")
  end
  if pmap.filter then
    collect_section(pmap.filter, "filter.")
  end
  if pmap.macros then
    for num, idx in pairs(pmap.macros) do
      if type(idx) == "number" then
        local v = get_param(track, fx, idx)
        if v then
          params[string.format("macros.%s", tostring(num))] = v
        end
      end
    end
  end

  -- Surge Scene A
  if pmap.sceneA then
    local sa = pmap.sceneA
    if sa.amp_env then
      collect_section(sa.amp_env, "sceneA.amp_env.")
    end
    if sa.filter_env then
      collect_section(sa.filter_env, "sceneA.filter_env.")
    end
    if sa.filter1 then
      collect_section(sa.filter1, "sceneA.filter1.")
    end
  end

  -- Operators (Dexed / ExaktLite)
  if pmap.operators then
    for op_id, op_tbl in pairs(pmap.operators) do
      if type(op_tbl) == "table" then
        for field, idx in pairs(op_tbl) do
          if type(idx) == "number" then
            local v = get_param(track, fx, idx)
            if v then
              local key = string.format("operators.%s.%s", tostring(op_id), tostring(field))
              params[key] = v
            end
          end
        end
      end
    end
  end

  -- Master (gRainbow, ThumpOne, etc.)
  if pmap.master then
    collect_section(pmap.master, "master.")
  end

  -- Drum (ChowKick, adc Clap, BucketPops, etc.)
  if pmap.drum then
    for sub, tbl in pairs(pmap.drum) do
      if type(tbl) == "table" then
        for field, idx in pairs(tbl) do
          if type(idx) == "number" then
            local v = get_param(track, fx, idx)
            if v then
              local key = string.format("drum.%s.%s", tostring(sub), tostring(field))
              params[key] = v
            end
          end
        end
      end
    end
  end

  -- Global section (BucketPops)
  if pmap.global then
    collect_section(pmap.global, "global.")
  end

  return params
end

----------------------------------------------------------------------
-- JSON writing (simple)
----------------------------------------------------------------------

local function encode_params_table(params)
  local parts = {}
  table.insert(parts, "{")
  local first = true
  for k, v in pairs(params) do
    if not first then
      table.insert(parts, ",")
    end
    first = false
    table.insert(parts, string.format('\n  "%s": %.6f', tostring(k), v))
  end
  if not first then
    table.insert(parts, "\n")
  end
  table.insert(parts, "}")
  return table.concat(parts, "")
end

local function write_preset_json(path, preset)
  local f, err = io.open(path, "w")
  if not f then
    return false, err
  end

  f:write("{\n")
  f:write(string.format('  "version": %d,\n', preset.version or 1))
  f:write(string.format('  "synth_id": "%s",\n', preset.synth_id or "unknown"))
  f:write(string.format('  "role": "%s",\n', preset.role or ""))
  f:write(string.format('  "variant": "%s",\n', preset.variant or ""))
  f:write(string.format('  "description": "%s",\n', preset.description or ""))
  f:write('  "params": ')
  f:write(encode_params_table(preset.params or {}))
  f:write("\n}\n")

  f:close()
  return true
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

msg("DF95 JSON Preset Export for FX: " .. tostring(fx_name))
msg("id = " .. tostring(id) .. ", kind = " .. tostring(meta.kind))

local folder_name = folder_map[id]
if not folder_name then
  msg("This FX id (" .. tostring(id) .. ") has no preset folder mapping yet.")
  return
end

local defaults = {
  role = "bass",
  variant = "idm_sub_soft",
  description = fx_name,
}

local user = ask_meta(defaults.role, defaults.variant, defaults.description)
if not user then
  msg("Export cancelled.")
  return
end

local resource_path = r.GetResourcePath()
local base = resource_path .. "/Scripts/IFLS/DF95/presets/"
local folder = base .. folder_name .. "/"

-- ensure folder exists
reaper.RecursiveCreateDirectory(folder, 0)

local file_name = string.format("%s_%s.json", user.role, user.variant)
local full_path = folder .. file_name

local params = collect_params(track, fx, pmap or {})
local preset = {
  version = 1,
  synth_id = id,
  role = user.role,
  variant = user.variant,
  description = user.description,
  params = params,
}

local ok, err = write_preset_json(full_path, preset)
if not ok then
  msg("Error writing preset file: " .. tostring(err))
  return
end

msg("DF95 JSON Preset exported to:\n" .. full_path)
msg("Stored keys: " .. tostring(#(function() local c=0 for _ in pairs(params) do c=c+1 end return {c} end)()[1]))
