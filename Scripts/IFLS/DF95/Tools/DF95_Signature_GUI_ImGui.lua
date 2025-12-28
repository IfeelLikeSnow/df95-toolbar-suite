-- DF95_Signature_GUI_ImGui.lua
-- ReaImGui-based GUI for DF95 Signature JSON system.
--
-- Features:
--   - Shows current FX (focused or first on selected track) + MetaCore id/kind.
--   - Lets you choose Role (bass/lead/pad/fx/keys/pluck/drum).
--   - Scans JSON presets for that synth+role and shows available variants.
--   - Lets you apply the chosen JSON preset with one click.
--
-- Supports multiple synths via MetaCore id + preset folder mapping:
--   vital, surge_xt, dexed, exaktlite, tal_noisemaker, tyrelln6,
--   triplecheese, grainbow, chowkick, adc_clap, bucketpops, thump_one.
--
-- Requirements:
--   - ReaImGui extension installed
--   - DF95_MetaCore_VST_All_vsti.lua + DF95_MetaCore_ParamMaps.lua
--   - JSON presets under Scripts/IFLS/DF95/presets/<SynthFolder>/

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox(
    "ReaImGui extension is not installed.\nPlease install it to use DF95_Signature_GUI_ImGui.",
    "DF95 Signature GUI",
    0
  )
  return
end

----------------------------------------------------------------------
-- MetaCore + helper utilities
----------------------------------------------------------------------

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

local function set_param(track, fx, idx, val)
  if not idx or idx < 0 then return end
  r.TrackFX_SetParam(track, fx, idx, val)
end

----------------------------------------------------------------------
-- Minimal JSON parsing (same style as DF95_Signature_Apply_JSON)
----------------------------------------------------------------------

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function parse_simple_json_preset(txt)
  if not txt then return nil end
  local t = {}
  t.synth_id   = txt:match('"synth_id"%s*:%s*"(.-)"')
  t.role       = txt:match('"role"%s*:%s*"(.-)"')
  t.variant    = txt:match('"variant"%s*:%s*"(.-)"')
  t.description= txt:match('"description"%s*:%s*"(.-)"')
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
        local m = pmap.master
        if m then
          local idx = m[rest]
          set_param(track, fx, idx, val)
        end

      elseif section1 == "drum" then
        local sub, field = rest:match("^([^%.]+)%.(.+)$")
        if sub and field and pmap.drum then
          local d = pmap.drum[sub]
          if d then
            local idx = d[field]
            set_param(track, fx, idx, val)
          end
        end

      elseif section1 == "global" then
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
-- Preset discovery
----------------------------------------------------------------------

local function get_preset_folder_for_id(id)
  local map = {
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
  return map[id]
end

local function list_presets_for_synth_and_role(synth_id, role)
  local folder_name = get_preset_folder_for_id(synth_id)
  if not folder_name then return {} end

  local resource_path = r.GetResourcePath()
  local base = resource_path .. "/Scripts/IFLS/DF95/presets/"
  local folder = base .. folder_name .. "/"

  local out = {}
  if not r.EnumerateFiles then
    return out
  end

  local i = 0
  while true do
    local fname = r.EnumerateFiles(folder, i)
    if not fname then break end
    if fname:match("^" .. role .. "_") and fname:lower():match("%.json$") then
      local full_path = folder .. fname
      local txt = read_file(full_path)
      local preset = parse_simple_json_preset(txt or "")
      local variant = preset and preset.variant or fname:gsub("%.json$", "")
      out[#out+1] = {
        filename    = fname,
        full_path   = full_path,
        variant     = variant,
        description = preset and preset.description or fname,
      }
    end
    i = i + 1
  end

  table.sort(out, function(a,b)
    return a.filename < b.filename
  end)

  return out
end

----------------------------------------------------------------------
-- MAIN GUI
----------------------------------------------------------------------

local mc = load_metacore()
if not mc then return end

local ctx = r.ImGui_CreateContext("DF95 Signature GUI")
local FONT = r.ImGui_CreateFont("sans-serif", 14)
r.ImGui_Attach(ctx, FONT)

local current_role = "bass"
local variants = {}
local current_variant_index = 1
local last_synth_id = nil
local last_role = nil
local status_msg = ""

local roles = { "bass", "lead", "pad", "fx", "keys", "pluck", "drum" }

local function refresh_variants(synth_id, role)
  variants = list_presets_for_synth_and_role(synth_id, role)
  current_variant_index = (#variants > 0) and 1 or 0
end

local function update_target_info()
  local track, fx = get_target_fx()
  if not track then
    return nil
  end
  local info = mc.get_fxinfo and mc.get_fxinfo(track, fx)
  return track, fx, info
end

local function main_loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 Signature GUI", true)

  if visible then
    r.ImGui_PushFont(ctx, FONT)

    local track, fx, info = update_target_info()
    if not track or not info then
      r.ImGui_Text(ctx, "No focused FX or FX on selected track.")
      r.ImGui_Text(ctx, "Please focus a synth/drum FX that has DF95 presets.")
    else
      local fx_name = info.fx_name or "?"
      local meta = info.meta or {}
      local id   = meta.id or "?"
      local kind = meta.kind or "?"

      r.ImGui_Text(ctx, "Current FX:")
      r.ImGui_TextWrapped(ctx, fx_name)
      r.ImGui_Text(ctx, string.format("id = %s, kind = %s", tostring(id), tostring(kind)))

      local folder_name = get_preset_folder_for_id(id)
      if not folder_name then
        r.ImGui_Separator(ctx)
        r.ImGui_TextWrapped(ctx, "No JSON preset folder mapping for this FX id.")
      else
        r.ImGui_Separator(ctx)
        r.ImGui_Text(ctx, "Role:")
        r.ImGui_SameLine(ctx)

        local current_role_idx = 1
        for i, rname in ipairs(roles) do
          if rname == current_role then
            current_role_idx = i
            break
          end
        end
        local changed, new_idx = r.ImGui_Combo(ctx, "##rolecombo", current_role_idx-1, table.concat(roles, "\0") .. "\0")
        if changed then
          current_role = roles[new_idx+1]
          refresh_variants(id, current_role)
          last_synth_id = id
          last_role = current_role
        end

        if id ~= last_synth_id or current_role ~= last_role then
          refresh_variants(id, current_role)
          last_synth_id = id
          last_role = current_role
        end

        r.ImGui_Separator(ctx)
        r.ImGui_Text(ctx, "Variants for this synth & role:")
        if #variants == 0 then
          r.ImGui_Text(ctx, "(No JSON presets found for this combination.)")
        else
          local items = {}
          for _, v in ipairs(variants) do
            local label = v.variant or v.filename
            table.insert(items, label)
          end
          local combo_label = (#variants > 0 and variants[current_variant_index] and (variants[current_variant_index].variant or variants[current_variant_index].filename)) or ""
          local changed_var, new_idx = r.ImGui_Combo(ctx, "##variantcombo", current_variant_index-1, table.concat(items, "\0") .. "\0")
          if changed_var then
            current_variant_index = new_idx+1
          end

          if current_variant_index > 0 and variants[current_variant_index] then
            local v = variants[current_variant_index]
            if v.description and v.description ~= "" then
              r.ImGui_TextWrapped(ctx, v.description)
            end
          end

          if r.ImGui_Button(ctx, "Apply JSON Preset to Current FX") then
            local v = variants[current_variant_index]
            if v then
              local txt = read_file(v.full_path)
              local preset = parse_simple_json_preset(txt or "")
              if not preset then
                status_msg = "Error: could not parse preset."
              else
                if preset.synth_id and preset.synth_id ~= id then
                  status_msg = "Preset synth_id does not match current FX id."
                else
                  apply_params_from_preset(track, fx, info.params, preset.params)
                  status_msg = "Applied preset: " .. (preset.description or v.filename)
                end
              end
            end
          end
        end
      end
    end

    if status_msg ~= "" then
      r.ImGui_Separator(ctx)
      r.ImGui_TextWrapped(ctx, status_msg)
    end

    r.ImGui_PopFont(ctx)
    r.ImGui_End(ctx)
  end

  if open then
    r.defer(main_loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

main_loop()
