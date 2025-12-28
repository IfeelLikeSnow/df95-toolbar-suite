-- IFLS_BeatControlCenter_ImGui.lua
local r = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_contracts, contracts = pcall(dofile, core_path .. "IFLS_Contracts.lua")
local ok_ext,       ext       = pcall(dofile, core_path .. "IFLS_ExtState.lua")
local ok_ui,        ui_core   = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
local ok_beat,      beat      = pcall(dofile, domain_path .. "IFLS_BeatDomain.lua")
local ok_human,  humanize  = pcall(dofile, domain_path .. "IFLS_HumanizeDomain.lua")
local ok_txstyle, txstyle  = pcall(dofile, domain_path .. "IFLS_TX16WxStyleDomain.lua")
local ok_rev,    rev_eq    = pcall(dofile, domain_path .. "IFLS_ReverbEQDomain.lua")
local ok_afx,    artistfx  = pcall(dofile, domain_path .. "IFLS_ArtistFXChainDomain.lua")
local ok_pmeta, pmeta_bridge = pcall(dofile, domain_path .. "IFLS_PluginMetaBridgeDomain.lua")



if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox(
    "IFLS Beat Control Center: ReaImGui or IFLS_ImGui_Core.lua not available.",
    "IFLS Beat Control Center",
    0
  )
  return
end

if not ok_beat or type(beat) ~= "table" then
  r.ShowMessageBox(
    "IFLS Beat Control Center: IFLS_BeatDomain.lua could not be loaded.",
    "IFLS Beat Control Center",
    0
  )
  return
end

local state = beat.get_state()
local initialized = false

local engine_labels = { "V196 (MIDI)", "V198 (Loops+Speech)", "AIBeat V133", "AIBeat V134" }
local engine_values = { "V196",        "V198",                "V133",        "V134"         }

local function find_engine_index(engine_name)
  for i, v in ipairs(engine_values) do
    if v == engine_name then return i end
  end
  return 2
end

local engine_idx = find_engine_index(state.engine or "V198")

local function clamp(v, minv, maxv)
  if v < minv then return minv end
  if v > maxv then return maxv end
  return v
end

local function sync_to_reaper_tempo()
  if state.bpm and type(state.bpm) == "number" then
    r.Undo_BeginBlock()
    r.SetCurrentBPM(0, state.bpm, true)
    r.Undo_EndBlock("IFLS Beat Control: Set project tempo", -1)
  end
end

local function save_state_to_ext()
  beat.set_state(state)
end

local function reload_state_from_ext()
  state = beat.get_state()
  engine_idx = find_engine_index(state.engine or "V198")
end

local function trigger_run_engine()
  save_state_to_ext()
  beat.run_engine(state)
end


-- Phase 77: helper to build & save IDM FX chain RfxChain for current state

-- Phase 78: apply IDM chain directly onto project tracks
-- Heuristiken für Drum-/FX-/Ambient-Busse + optional "Selected Tracks" Modus.

local function detect_idm_busses()
  local drum_idx, fx_idx, amb_idx = nil, nil, nil
  local proj = 0
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    local ln = (name or ""):lower()
    -- Drum-Bus: "drum", "kit", "beat"
    if not drum_idx and (ln:find("drum") or ln:find("kit") or ln:find("beat")) then
      drum_idx = i
    end
    -- FX-Bus: "fx", "sfx", "bus fx"
    if not fx_idx and (ln:find(" fx") or ln:find("fx ") or ln:find("sfx") or ln:find("fx bus")) then
      fx_idx = i
    end
    -- Ambient-Bus: "amb", "ambient", "atmos", "reverb", "space"
    if not amb_idx and (ln:find("amb") or ln:find("ambient") or ln:find("atmos") or ln:find("reverb") or ln:find("space")) then
      amb_idx = i
    end
  end
  return drum_idx, fx_idx, amb_idx
end

local function apply_bus_to_track(bus, tr)
  if not tr or not bus or #bus == 0 then return end
  for _, slot in ipairs(bus) do
    local fx = slot[1]
    if fx and fx.fx_name then
      -- append FX by name; reaper will choose the best match in plugin list
      r.TrackFX_AddByName(tr, fx.fx_name, false, -1)
    end
  end
end

local function apply_idm_chain_to_tracks(chain, mode)
  if not chain then return end
  mode = mode or "auto"

  local cs = chain[1] or chain
  local drum_bus    = cs.drum_bus or {}
  local fx_bus      = cs.fx_bus or {}
  local ambient_bus = cs.ambient_bus or {}

  local proj = 0

  if mode == "selected" then
    local sel_count = r.CountSelectedTracks(proj)
    if sel_count == 0 then return end
    if sel_count == 1 then
      local tr = r.GetSelectedTrack(proj, 0)
      -- alle Busses auf einen Track
      apply_bus_to_track(drum_bus, tr)
      apply_bus_to_track(fx_bus, tr)
      apply_bus_to_track(ambient_bus, tr)
    else
      local tr_drum = r.GetSelectedTrack(proj, 0)
      local tr_fx   = r.GetSelectedTrack(proj, math.min(1, sel_count-1))
      local tr_amb  = r.GetSelectedTrack(proj, math.min(2, sel_count-1))
      apply_bus_to_track(drum_bus, tr_drum)
      apply_bus_to_track(fx_bus, tr_fx)
      apply_bus_to_track(ambient_bus, tr_amb)
    end
  else
    -- auto-detect busses by track name
    local drum_idx, fx_idx, amb_idx = detect_idm_busses()
    if drum_idx then
      local tr = r.GetTrack(proj, drum_idx)
      apply_bus_to_track(drum_bus, tr)
    end
    if fx_idx then
      local tr = r.GetTrack(proj, fx_idx)
      apply_bus_to_track(fx_bus, tr)
    end
    if amb_idx then
      local tr = r.GetTrack(proj, amb_idx)
      apply_bus_to_track(ambient_bus, tr)
    end
  end
end

local function build_idm_chain_and_save()
  if not (ok_afx and type(artistfx) == "table" and artistfx.build_chain_for_idm_profile and artistfx.save_rfxchain) then
    return
  end
  local profile_id = state.idm_chain_profile
  if not profile_id or profile_id == "" then
    -- Fallback: nimm erstes Profil, falls vorhanden
    if artistfx.IDM_CHAIN_PROFILES then
      for pid, _ in pairs(artistfx.IDM_CHAIN_PROFILES) do
        profile_id = pid
        break
      end
    end
  end
  if not profile_id or profile_id == "" then return end

  local seed = os.time() % 100000
  local chain, err = artistfx.build_chain_for_idm_profile(profile_id, seed, {})
  if not chain then return end

  local proj_artist = state.artist_profile or "default"
  local artist_safe = tostring(proj_artist):gsub("[^%w_%-%+]+", "_")
  local prof_safe   = tostring(profile_id):gsub("[^%w_%-%+]+", "_")

  local fxchain_dir = resource_path .. "/FXChains/IFLS_IDM"
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(fxchain_dir, 0)
  end
  local fxchain_path = fxchain_dir .. "/IFLS_IDM_" .. artist_safe .. "_" .. prof_safe .. ".RfxChain"

  artistfx.save_rfxchain(chain, fxchain_path)
end


local function trigger_build_layers()
  save_state_to_ext()
  beat.build_layers(state)
  if state.idm_chain_autofx then
    build_idm_chain_and_save()
  end
end

local function draw(ctx)
  if not initialized then
    ui_core.set_default_window_size(ctx, 720, 430)
    initialized = true
  end

  if ig.Button(ctx, "Reload from project state") then
    reload_state_from_ext()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Write to project state") then
    save_state_to_ext()
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Beat Basics")
  ig.Separator(ctx)

  local changed
  local bpm = state.bpm or 120
  changed, bpm = ig.SliderDouble(ctx, "BPM", bpm, 40, 220, "%.1f")
  if changed then state.bpm = bpm end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Use as project tempo") then
    sync_to_reaper_tempo()
  end

  local ts_num = state.ts_num or 4
  local ts_den = state.ts_den or 4

  ig.PushItemWidth(ctx, 80)
  changed, ts_num = ig.InputInt(ctx, "TS Numerator", ts_num)
  if changed then state.ts_num = clamp(ts_num, 1, 16) end
  changed, ts_den = ig.InputInt(ctx, "TS Denominator", ts_den)
  if changed then state.ts_den = clamp(ts_den, 1, 32) end
  ig.PopItemWidth(ctx)

  local bars = state.bars or 8
  changed, bars = ig.InputInt(ctx, "Bars", bars)
  if changed then state.bars = clamp(bars, 1, 512) end

  ig.Separator(ctx)
  ig.Text(ctx, "Engine & Layers")
  ig.Separator(ctx)

  engine_idx = engine_idx or 2
  ig.PushItemWidth(ctx, 220)
  if ig.BeginCombo(ctx, "Beat Engine", engine_labels[engine_idx] or "select") then
    for i, label in ipairs(engine_labels) do
      local is_selected = (i == engine_idx)
      if ig.Selectable(ctx, label, is_selected) then
        engine_idx = i
        state.engine = engine_values[i]
      end
      if is_selected then ig.SetItemDefaultFocus(ctx) end
    end
    ig.EndCombo(ctx)
  end
  ig.PopItemWidth(ctx)

  local use_midi   = state.use_midi_layers or false
  local use_loop   = state.use_loop_layers or false
  local use_speech = state.use_speech_layers or false

  changed, use_midi = ig.Checkbox(ctx, "Use MIDI Layers (V196)", use_midi)
  if changed then state.use_midi_layers = use_midi end
  changed, use_loop = ig.Checkbox(ctx, "Use Loop Layers (V198)", use_loop)
  if changed then state.use_loop_layers = use_loop end
  changed, use_speech = ig.Checkbox(ctx, "Use Speech Layers (V198)", use_speech)
  if changed then state.use_speech_layers = use_speech end

  local use_sampler = state.use_sampler_setup or false
  changed, use_sampler = ig.Checkbox(ctx, "Use Sampler Setup (RS5k/TX16Wx)", use_sampler)
  if changed then state.use_sampler_setup = use_sampler end

  ig.Separator(ctx)
  ig.Text(ctx, "Sampler / Artist / SampleDB")
  ig.Separator(ctx)

  ig.PushItemWidth(ctx, 160)
  local sampler_modes = { "RS5K", "TX16WX" }
  local sampler_mode = state.sampler_mode or "RS5K"
  local sampler_idx = 1
  for i, m in ipairs(sampler_modes) do
    if m == sampler_mode then sampler_idx = i break end
  end

  if ig.BeginCombo(ctx, "Sampler Mode", sampler_modes[sampler_idx]) then
    for i, label in ipairs(sampler_modes) do
      local selected = sampler_idx == i
      if ig.Selectable(ctx, label, selected) then
        sampler_idx = i
        state.sampler_mode = sampler_modes[i]
      end
      if selected then ig.SetItemDefaultFocus(ctx) end
    end
    ig.EndCombo(ctx)
  end
  ig.PopItemWidth(ctx)

  ig.PushItemWidth(ctx, 220)
  local artist = state.artist_profile or ""
  changed, artist = ig.InputText(ctx, "Artist Profile", artist)
  if changed then
    state.artist_profile = artist
    -- Wenn ArtistDomain & HumanizeDomain vorhanden sind,
    -- wende automatisch ein Humanize-Preset und TX16Wx-Style an.
    local ok_art, artist_dom = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")
    local ok_hum, hum_dom    = pcall(dofile, domain_path .. "IFLS_HumanizeDomain.lua")
    if ok_art and type(artist_dom) == "table"
       and artist_dom.get_humanize_preset_for_artist
       and ok_hum and type(hum_dom) == "table"
       and hum_dom.apply_preset then
      local preset_id = artist_dom.get_humanize_preset_for_artist(artist)
      hum_dom.apply_preset(0, preset_id)
    end
    -- TX16Wx Style pro Artist (falls verfügbar)
    local ok_tx, txstyle = pcall(dofile, domain_path .. "IFLS_TX16WxStyleDomain.lua")
    if ok_art and ok_tx and type(txstyle) == "table" and txstyle.apply_style
       and artist_dom.get_tx16_style_for_artist then
      local style_id = artist_dom.get_tx16_style_for_artist(artist)
      if style_id and style_id ~= "" then
        txstyle.apply_style(style_id)
      end
    end
  end

  -- Kleiner Artist-Browser (DF95-Artistkatalog)
  local ok_art, artist_dom = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")
  if ok_art and type(artist_dom) == "table" and artist_dom.list_artists then
    local catalog = artist_dom.list_artists()
    if #catalog > 0 then
      local current_label = artist_dom.get_label_for_artist(artist)
      if current_label == "" then current_label = "<Artist wählen>" end
      if ig.BeginCombo(ctx, "Artist Browser", current_label) then
        for _, a in ipairs(catalog) do
          local is_sel = (a.id == artist)
          if ig.Selectable(ctx, a.label, is_sel) then
            state.artist_profile = a.id
            artist = a.id
            -- Humanize-Preset für ausgewählten Artist anwenden
            local ok_hum2, hum_dom2 = pcall(dofile, domain_path .. "IFLS_HumanizeDomain.lua")
            if ok_hum2 and type(hum_dom2) == "table" and hum_dom2.apply_preset then
              local preset_id = artist_dom.get_humanize_preset_for_artist(a.id)
              hum_dom2.apply_preset(0, preset_id)
            end
            -- TX16Wx-Style passend zum Artist anwenden
            local ok_tx2, txstyle2 = pcall(dofile, domain_path .. "IFLS_TX16WxStyleDomain.lua")
            if ok_tx2 and type(txstyle2) == "table" and txstyle2.apply_style
               and artist_dom.get_tx16_style_for_artist then
              local style_id = artist_dom.get_tx16_style_for_artist(a.id)
              if style_id and style_id ~= "" then
                txstyle2.apply_style(style_id)
              end
            end
          end
          if is_sel then ig.SetItemDefaultFocus(ctx) end
        end
        ig.EndCombo(ctx)
      end

  -- Info: automatische Reverb/EQ-Empfehlung pro Artist
  if ok_rev and type(rev_eq) == "table" and rev_eq.build_chain_for_artist then
    local ok_art2, artist_dom2 = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")
    if ok_art2 and type(artist_dom2) == "table" then
      local chain = rev_eq.build_chain_for_artist(artist, artist_dom2)
      if chain and chain[1] then
        local rv = chain[1].reverb
        local eq = chain[1].eq
        local info = ""
        if rv and rv.name then
          info = info .. "RV: " .. rv.name
        end
        if eq and eq.name then
          if info ~= "" then info = info .. "  |  " end
          info = info .. "EQ: " .. eq.name
        end
        if info ~= "" then
          ig.Text(ctx, "Reverb/EQ (Artist Chain):")
          ig.SameLine(ctx)
          ig.Text(ctx, info)
        end
      end
    end
  end

    end
  end


  -- Artist-FX-Chain Vorschau (Threepo/ArtistFX)
  if ok_afx and type(artistfx) == "table" and artistfx.build_chain_for_artist then
    local ok_art3, artist_dom3 = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")
    local chain_spec = nil
    if ok_art3 and type(artist_dom3) == "table" then
      chain_spec = artistfx.build_chain_for_artist(artist, artist_dom3, rev_eq)
    end
    if chain_spec and chain_spec[1] then
      local cs = chain_spec[1]
      ig.Separator(ctx)
      ig.Text(ctx, "Artist FX Chain (Preview):")
      if cs.drum_bus and #cs.drum_bus > 0 then
        ig.Text(ctx, "  Drum Bus:")
        for _, slot in ipairs(cs.drum_bus) do
          local fx = slot[1]
          if fx and fx.fx_name then
            ig.BulletText(ctx, fx.fx_name)
          end
        end
      end
      if cs.fx_bus and #cs.fx_bus > 0 then
        ig.Text(ctx, "  FX Bus:")
        for _, slot in ipairs(cs.fx_bus) do
          local fx = slot[1]
          if fx and fx.fx_name then
            ig.BulletText(ctx, fx.fx_name)
          end
        end
      end
      if cs.ambient_bus and #cs.ambient_bus > 0 then
        ig.Text(ctx, "  Ambient Bus:")
        for _, slot in ipairs(cs.ambient_bus) do
          local fx = slot[1]
          if fx and fx.fx_name then
            ig.BulletText(ctx, fx.fx_name)
          end
        end
      end
    end
  end


  -- Info: DF95 PluginMetaBridge availability / IDM groups
  if ok_pmeta and pmeta_bridge and pmeta_bridge.is_available and pmeta_bridge.is_available() then
    ig.Separator(ctx)
    ig.Text(ctx, "PluginMetaBridge: DF95 IDM groups available")
  else
    ig.Separator(ctx)
    ig.Text(ctx, "PluginMetaBridge: DF95 IDM groups NOT found")
  end

  -- Phase 77: IDM FX chain profile selection / auto FX
  if ok_afx and type(artistfx) == "table" and artistfx.IDM_CHAIN_PROFILES then
    ig.Separator(ctx)
    ig.Text(ctx, "IDM FX Chain Profile")

    local current_profile = state.idm_chain_profile or ""
    local current_label = current_profile
    if current_label == "" then current_label = "(auto/first profile)" end

    if ig.BeginCombo(ctx, "IDM Profile", current_label) then
      for pid, prof in pairs(artistfx.IDM_CHAIN_PROFILES) do
        local label = pid
        if type(prof) == "table" and prof.description then
          label = pid .. "  -  " .. prof.description
        end
        local is_sel = (pid == current_profile)
        if ig.Selectable(ctx, label, is_sel) then
          state.idm_chain_profile = pid
        end
        if is_sel then ig.SetItemDefaultFocus(ctx) end
      end
      ig.EndCombo(ctx)
    end

    local autofx = state.idm_chain_autofx or false
    local changed_autofx
    changed_autofx, autofx = ig.Checkbox(ctx, "Auto: Build IDM FX RfxChain when building layers", autofx)
    if changed_autofx then
      state.idm_chain_autofx = autofx
    end

    if ig.Button(ctx, "Generate IDM FX Chain now") then
      build_idm_chain_and_save()
    end
    ig.SameLine(ctx)
    ig.Text(ctx, "(saved to REAPER/FXChains/IFLS_IDM/...)")
  end

  -- Phase 78: Apply IDM FX Chain onto tracks
  if ok_afx and type(artistfx) == "table" and artistfx.IDM_CHAIN_PROFILES then
    ig.Separator(ctx)
    ig.Text(ctx, "Apply IDM FX Chain to tracks")

    -- Apply mode: Selected vs Auto-detect
    local mode_label = "Auto-detect drum/fx/ambient busses"
    if state.idm_apply_mode == "selected" then
      mode_label = "Selected tracks (1=all, 2-3=drum/fx/ambient)"
    end

    if ig.BeginCombo(ctx, "Apply Mode", mode_label) then
      local auto_sel = (state.idm_apply_mode ~= "selected")
      if ig.Selectable(ctx, "Auto-detect drum/fx/ambient busses", auto_sel) then
        state.idm_apply_mode = "auto"
      end
      local sel_sel = (state.idm_apply_mode == "selected")
      if ig.Selectable(ctx, "Selected tracks: 1=all; 2-3=drum/fx/ambient", sel_sel) then
        state.idm_apply_mode = "selected"
      end
      ig.EndCombo(ctx)
    end

    if ig.Button(ctx, "Apply IDM Chain (current profile)") then
      local profile_id = state.idm_chain_profile
      if (not profile_id or profile_id == "") and artistfx.IDM_CHAIN_PROFILES then
        for pid, _ in pairs(artistfx.IDM_CHAIN_PROFILES) do
          profile_id = pid
          break
        end
      end
      if profile_id and profile_id ~= "" then
        local seed = os.time() % 100000
        local chain, err = artistfx.build_chain_for_idm_profile(profile_id, seed, {})
        if chain then
          local mode = state.idm_apply_mode or "auto"
          apply_idm_chain_to_tracks(chain, mode)
        end
      end
    end

    ig.SameLine(ctx)
    ig.Text(ctx, "Hint: combine with Auto-FX for RfxChain export.")
  end

  local sfilter = state.sampledb_filter or ""
  changed, sfilter = ig.InputText(ctx, "SampleDB Filter", sfilter)
  if changed then state.sampledb_filter = sfilter end

  local scat = state.sampledb_category or ""
  changed, scat = ig.InputText(ctx, "SampleDB Category", scat)
  if changed then state.sampledb_category = scat end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "Humanize / Reroll")
  ig.Separator(ctx)

  local proj = 0
  local human_cfg = nil
  if ok_human and type(humanize) == "table" and humanize.load then
    human_cfg = humanize.load(proj)
  end

  if human_cfg then
    ig.PushItemWidth(ctx, 200)

    local preset_labels = {
      STRAIGHT     = "Straight",
      IDM          = "IDM / Glitch",
      IDM_DENSE    = "IDM Dense",
      IDM_SPARSE   = "IDM Sparse",
      CLICKS_POP   = "Clicks & Pops",
      MICROBEAT    = "Microbeats",
      MICROSTUTTER = "Microstutter / Granular",
    }
    local preset_order = { "STRAIGHT", "IDM", "IDM_DENSE", "IDM_SPARSE", "CLICKS_POP", "MICROBEAT", "MICROSTUTTER" }
    local current_id   = human_cfg.preset_id or "STRAIGHT"
    local current_label = preset_labels[current_id] or current_id

    if ig.BeginCombo(ctx, "Beat Style", current_label) then
      for _, pid in ipairs(preset_order) do
        local is_sel = (pid == current_id)
        if ig.Selectable(ctx, preset_labels[pid] or pid, is_sel) then
          current_id = pid
          if humanize.apply_preset then
            human_cfg = humanize.apply_preset(proj, pid)
          end
        end
        if is_sel then ig.SetItemDefaultFocus(ctx) end
      end
      ig.EndCombo(ctx)
    end

    local changed
    changed, human_cfg.timing_jitter_ms = ig.SliderDouble(ctx, "Timing jitter (ms)", human_cfg.timing_jitter_ms or 0.0, 0.0, 25.0, "%.1f")
    changed, human_cfg.swing_pct        = ig.SliderDouble(ctx, "Swing (%)",          human_cfg.swing_pct or 0.0,        0.0, 30.0, "%.1f")
    changed, human_cfg.vel_spread       = ig.SliderDouble(ctx, "Velocity spread",    human_cfg.vel_spread or 0.0,       0.0, 24.0, "%.1f")
    changed, human_cfg.ghost_prob       = ig.SliderDouble(ctx, "Ghost prob",         human_cfg.ghost_prob or 0.0,       0.0, 1.0,  "%.2f")
    changed, human_cfg.roll_prob        = ig.SliderDouble(ctx, "Roll prob",          human_cfg.roll_prob or 0.0,        0.0, 1.0,  "%.2f")
    changed, human_cfg.glitch_prob      = ig.SliderDouble(ctx, "Glitch prob",        human_cfg.glitch_prob or 0.0,      0.0, 1.0,  "%.2f")

    ig.PopItemWidth(ctx)

    if ig.Button(ctx, "Save Humanize Settings") then
      if humanize.save then
        humanize.save(proj, human_cfg)
      end
    end

    ig.SameLine(ctx)
    if ig.Button(ctx, "Apply Style to TX16Wx") then
      if ok_txstyle and type(txstyle) == "table" and txstyle.apply_style then
        txstyle.apply_style(current_id)
      end
    end
  else
    ig.PushItemWidth(ctx, 200)
    local hmode = state.humanize_mode or ""
    local changed
    changed, hmode = ig.InputText(ctx, "Humanize Mode", hmode)
    if changed then state.humanize_mode = hmode end
    ig.PopItemWidth(ctx)
  end

  local reroll = state.reroll_request or false
  local changed
  changed, reroll = ig.Checkbox(ctx, "Request Reroll on next run", reroll)
  if changed then state.reroll_request = reroll end


  ig.Separator(ctx)

  if ig.Button(ctx, "Run Engine") then
    trigger_run_engine()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Build Layers") then
    trigger_build_layers()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Save State") then
    save_state_to_ext()
  end
end

local ctx = ui_core.create_context("IFLS_BeatControlCenter")
if ctx then
  ui_core.run_mainloop(ctx, "IFLS Beat Control Center", draw)
end
