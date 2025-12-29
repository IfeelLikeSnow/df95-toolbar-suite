-- IFLS_MasterHub_ImGui.lua
-- Phase 12: IFLS Master Hub (Multi-Tab Dashboard)
-- -----------------------------------------------
-- Ziel:
--   * Ein einziges ImGui-Fenster als zentrales IFLS-Dashboard:
--       - Artist Overview
--       - Beat / Pattern
--       - Sample / Loops / Speech (Summary)
--       - Tuning / Unified Tuning
--       - Performance / Pipeline
--       - Quick Launch für alle Sub-Hubs
--
--   * Kein Ersatz für die spezialisierten Hubs (ArtistHub, BeatHub, PatternHub,
--     TuningHub, SampleHub, PerformanceHub), sondern ein Top-Level Entry-Point,
--     der dir auf einen Blick zeigt, was IFLS gerade "denkt".

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"
local hubs_path     = resource_path .. "/Scripts/IFLS/IFLS/Hubs/"
local tools_path    = resource_path .. "/Scripts/IFLS/IFLS/Tools/"

local ok_ui, ui_core = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox("IFLS Master Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.", "IFLS Master Hub", 0)
  return
end

local function load_domain(name)
  local ok, mod = pcall(dofile, domain_path .. name .. ".lua")
  if not ok or type(mod) ~= "table" then
    return nil
  end
  return mod
end

local beatdom    = load_domain("IFLS_BeatDomain")
local artistdom  = load_domain("IFLS_ArtistDomain")
local sampledom  = load_domain("IFLS_SampleDBDomain")
local patternd   = load_domain("IFLS_PatternDomain")
local tuningdom  = load_domain("IFLS_TuningDomain")

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
  }
end

local NS_PATTERN = "DF95_PATTERN"


local function normalize_pattern_mode(str)
  if not str or str == "" then return nil end
  local s = string.lower(str)
  if s:find("euclidpro") or s:find("euclid_pro") or s:find("euclid pro") then
    return "EUCLIDPRO"
  end
  if s:find("idm") then return "IDM" end
  if s:find("euclid") or s:find("euklid") then return "EUCLID" end
  if s:find("micro") then return "MICROBEAT" end
  if s:find("grain") or s:find("granular") then return "GRANULAR" end
  return nil
end

local function resolve_pattern_mode(artist_state, beat_state, cfg)
  cfg = cfg or {}
  if cfg.mode_hint and cfg.mode_hint ~= "" then
    return normalize_pattern_mode(cfg.mode_hint) or string.upper(cfg.mode_hint)
  end

  local mode
  if artist_state then
    mode = normalize_pattern_mode(artist_state.pattern_mode)
    if not mode then mode = normalize_pattern_mode(artist_state.style_preset) end
  end

  if (not mode) and beat_state and beat_state.mode and beat_state.mode ~= "" then
    mode = normalize_pattern_mode(beat_state.mode)
  end

  if not mode then mode = "IDM" end
  return mode
end

local ctx = ui_core.create_context("IFLS_MasterHub")
if not ctx then return end

local function read_pattern_cfg()
  local function num(key, def)
    local s = ext.get_proj(NS_PATTERN, key, tostring(def))
    local v = tonumber(s)
    if not v then return def end
    return v
  end
  return {
    mode_hint    = ext.get_proj(NS_PATTERN, "MODE_HINT", ""),
    chaos        = num("CHAOS", 0.7),
    density      = num("DENSITY", 0.4),
    cluster_prob = num("CLUSTER_PROB", 0.35),
    euclid_k     = num("EUCLID_K", 3),
    euclid_n     = num("EUCLID_N", 8),
    euclid_rot   = num("EUCLID_ROT", 0),
  }
end

local function open_hub_script(fname)
  local path = hubs_path .. fname
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("IFLS Master Hub: Konnte Hub nicht starten:\n" .. tostring(err), "IFLS Master Hub", 0)
  end
end

local function draw_overview_tab(ctx)
  ig.Text(ctx, "IFLS Overview")
  ig.Separator(ctx)

  local artist_name, style_preset = "<none>", "<none>"
  local use_midi, use_loop, use_speech, use_hybrid = false, false, false, false
  if artistdom and artistdom.get_artist_state then
    local st = artistdom.get_artist_state()
    artist_name  = st.name or artist_name
    style_preset = st.style_preset or style_preset
    use_midi     = st.use_midi_layers and true or false
    use_loop     = st.use_loop_layers and true or false
    use_speech   = st.use_speech_layers and true or false
    use_hybrid   = st.use_hybridai and true or false
  end

  local bs = {}
  if beatdom and beatdom.get_state then
    bs = beatdom.get_state()
  end

  local cfg = read_pattern_cfg()
  local ts = tuningdom and tuningdom.get_state and tuningdom.get_state() or nil

  ig.Text(ctx, "Artist")
  ig.Separator(ctx)
  ig.Text(ctx, ("Name:           %s"):format(artist_name))
  ig.Text(ctx, ("Style Preset:   %s"):format(style_preset))

  ig.Separator(ctx)
  ig.Text(ctx, "Beat")
  ig.Separator(ctx)
  ig.Text(ctx, ("BPM:            %d"):format(bs.bpm or 0))
  ig.Text(ctx, ("Time Sig:       %d/%d"):format(bs.ts_num or 4, bs.ts_den or 4))
  ig.Text(ctx, ("Bars:           %d"):format(bs.bars or 4))

  ig.Separator(ctx)
  ig.Text(ctx, "Pattern")
  ig.Separator(ctx)

  local resolved_mode = resolve_pattern_mode(
    artistdom and artistdom.get_artist_state and artistdom.get_artist_state() or nil,
    bs,
    cfg
  )

  -- Farbliche Hervorhebung für EUCLIDPRO
  if resolved_mode == "EUCLIDPRO" then
    ig.PushStyleColor(ctx, ig.Col_Text, 0xFF00FFFF) -- cyan-ish
    ig.Text(ctx, ("Resolved Mode:  %s"):format(resolved_mode))
    ig.PopStyleColor(ctx)
  else
    ig.Text(ctx, ("Resolved Mode:  %s"):format(resolved_mode or "<unknown>"))
  end

  ig.Text(ctx, ("Mode Hint:      %s"):format(cfg.mode_hint ~= "" and cfg.mode_hint or "<auto>"))
  ig.Text(ctx, ("Chaos (IDM):    %.3f"):format(cfg.chaos))
  ig.Text(ctx, ("Density (Micro):%.3f"):format(cfg.density))
  ig.Text(ctx, ("Cluster (Gran): %.3f"):format(cfg.cluster_prob))
  ig.Text(ctx, ("Euclid k/n/rot: %d / %d / %d"):format(cfg.euclid_k, cfg.euclid_n, cfg.euclid_rot))

  ig.Separator(ctx)
  ig.Text(ctx, "Layers / HybridAI")
  ig.Separator(ctx)
  ig.Text(ctx, ("Use MIDI Layers (V196):   %s"):format(use_midi and "Yes" or "No"))
  ig.Text(ctx, ("Use Loop Layers (V198):   %s"):format(use_loop and "Yes" or "No"))
  ig.Text(ctx, ("Use Speech Layers:        %s"):format(use_speech and "Yes" or "No"))
  ig.Text(ctx, ("Use HybridAI Slicing:     %s"):format(use_hybrid and "Yes" or "No"))

  ig.Separator(ctx)
  ig.Text(ctx, "Tuning")
  ig.Separator(ctx)
  if ts then
    ig.Text(ctx, ("Enabled:        %s"):format(ts.enabled and "Yes" or "No"))
    ig.Text(ctx, ("Profile:        %s"):format(ts.profile or "Equal12"))
    ig.Text(ctx, ("PB Range:       ±%d semitones"):format(ts.pitch_bend_semi or 2))
    ig.Text(ctx, ("Master Offset:  %.2f cents"):format(ts.master_offset or 0))
  else
    ig.Text(ctx, "TuningDomain nicht verfügbar.")
  end
end

local function draw_artist_tab(ctx)
  ig.Text(ctx, "Artist Domain")
  ig.Separator(ctx)

  if not (artistdom and artistdom.get_artist_state) then
    ig.Text(ctx, "IFLS_ArtistDomain nicht verfügbar.")
    return
  end

  local st = artistdom.get_artist_state()
  ig.Text(ctx, ("Name:        %s"):format(st.name or "<none>"))
  ig.Text(ctx, ("Profile:     %s"):format(st.profile or "<none>"))
  ig.Text(ctx, ("Style:       %s"):format(st.style_preset or "<none>"))
  ig.Text(ctx, ("PatternMode: %s"):format(st.pattern_mode or "<none>"))

  ig.Separator(ctx)
  ig.Text(ctx, "Layer Flags")
  ig.Separator(ctx)
  ig.Text(ctx, ("MIDI Layers:   %s"):format(st.use_midi_layers and "Yes" or "No"))
  ig.Text(ctx, ("Loop Layers:   %s"):format(st.use_loop_layers and "Yes" or "No"))
  ig.Text(ctx, ("Speech Layers: %s"):format(st.use_speech_layers and "Yes" or "No"))
  ig.Text(ctx, ("HybridAI:      %s"):format(st.use_hybridai and "Yes" or "No"))

  ig.Separator(ctx)
  if ig.Button(ctx, "Open Artist Hub") then
    open_hub_script("IFLS_ArtistHub_ImGui.lua")
  end
end

local function draw_beat_pattern_tab(ctx)
  ig.Text(ctx, "Beat / Pattern")
  ig.Separator(ctx)

  if beatdom and beatdom.get_state then
    local bs = beatdom.get_state()
    ig.Text(ctx, ("BPM:      %d"):format(bs.bpm or 0))
    ig.Text(ctx, ("TimeSig:  %d/%d"):format(bs.ts_num or 4, bs.ts_den or 4))
    ig.Text(ctx, ("Bars:     %d"):format(bs.bars or 4))
  else
    ig.Text(ctx, "IFLS_BeatDomain nicht verfügbar.")
  end

  ig.Separator(ctx)
  local cfg = read_pattern_cfg()
  ig.Text(ctx, "Pattern Config (from ExtState)")
  ig.Separator(ctx)
  ig.Text(ctx, ("Mode Hint:      %s"):format(cfg.mode_hint ~= "" and cfg.mode_hint or "<auto>"))
  ig.Text(ctx, ("Chaos (IDM):    %.3f"):format(cfg.chaos))
  ig.Text(ctx, ("Density:        %.3f"):format(cfg.density))
  ig.Text(ctx, ("Cluster Prob:   %.3f"):format(cfg.cluster_prob))
  ig.Text(ctx, ("Euclid k/n/rot: %d / %d / %d"):format(cfg.euclid_k, cfg.euclid_n, cfg.euclid_rot))

  ig.Separator(ctx)
  if ig.Button(ctx, "Generate Pattern (Artist/Beat)") then
    if artistdom and beatdom and patternd then
      local bs = beatdom.get_state()
      local as = artistdom.get_artist_state()
      local explicit = cfg.mode_hint ~= "" and cfg.mode_hint or nil
      patternd.generate(as, bs, explicit, cfg)
    end
  end

  ig.Separator(ctx)
  if ig.Button(ctx, "Open Beat Control Center") then
    open_hub_script("IFLS_BeatControlCenter_ImGui.lua")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open Pattern Hub") then
    open_hub_script("IFLS_PatternHub_ImGui.lua")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open EuclidPro Hub") then
    open_hub_script("IFLS_EuclidProHub_ImGui.lua")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open PolyRhythm Hub") then
    open_hub_script("IFLS_PolyRhythmHub_ImGui.lua")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open Markov Rhythm Hub") then
    open_hub_script("IFLS_MarkovRhythmHub_ImGui.lua")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open Performance Hub") then
    open_hub_script("IFLS_PerformanceHub_ImGui.lua")
  end
end

local function draw_sample_tab(ctx)
  ig.Text(ctx, "Sample / Loops / Speech")
  ig.Separator(ctx)

  if not (sampledom and sampledom.get_state) then
    ig.Text(ctx, "IFLS_SampleDBDomain nicht verfügbar.")
  else
    local st = sampledom.get_state()
    -- Wir kennen die genaue Struktur nicht; daher generisch:
    ig.TextWrapped(ctx, "SampleDBDomain-Status (generisch angezeigt):")
    for k,v in pairs(st) do
      ig.Text(ctx, tostring(k) .. ": " .. tostring(v))
    end
  end

  ig.Separator(ctx)
  if ig.Button(ctx, "Open Sample Hub") then
    open_hub_script("IFLS_SampleHub_ImGui.lua")
  end
end

local function draw_tuning_tab(ctx)
  ig.Text(ctx, "Tuning / Microtonal / Unified")
  ig.Separator(ctx)

  local ts = tuningdom and tuningdom.get_state and tuningdom.get_state() or nil
  if ts then
    ig.Text(ctx, ("Enabled:         %s"):format(ts.enabled and "Yes" or "No"))
    ig.Text(ctx, ("Profile:         %s"):format(ts.profile or "Equal12"))
    ig.Text(ctx, ("Pitchbend Range: ±%d semitones"):format(ts.pitch_bend_semi or 2))
    ig.Text(ctx, ("Master Offset:   %.2f cents"):format(ts.master_offset or 0))
  else
    ig.Text(ctx, "IFLS_TuningDomain nicht verfügbar.")
  end

  ig.Separator(ctx)
  ig.TextWrapped(ctx,
    "Nutze 'IFLS_TuningHub_ImGui' zum Einstellen des Tunings und " ..
    "'IFLS_TuningSync_ImGui' um alle IFLS_MIDIProcessor-Instanzen mit " ..
    "diesem Tuning zu synchronisieren.")

  ig.Separator(ctx)
  if ig.Button(ctx, "Open Tuning Hub") then
    open_hub_script("IFLS_TuningHub_ImGui.lua")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open Tuning Sync Hub") then
    open_hub_script("IFLS_TuningSync_ImGui.lua")
  end
end

local function draw_performance_tab(ctx)
  ig.Text(ctx, "Performance / Pipeline")
  ig.Separator(ctx)

  ig.TextWrapped(ctx,
    "Dies ist eine High-Level-Sicht auf Pattern- und Output-Pipeline. " ..
    "Für mehr Details nutze den IFLS Performance Hub.")

  ig.Separator(ctx)
  if ig.Button(ctx, "Run Full Output Pipeline (OutputRouter)") then
    local ok = pcall(dofile, tools_path .. "IFLS_OutputRouter.lua")
    if not ok then
      r.ShowMessageBox("Master Hub: IFLS_OutputRouter.lua konnte nicht ausgeführt werden.", "IFLS Master Hub", 0)
    end
  end

  ig.SameLine(ctx)
  if ig.Button(ctx, "Generate Pattern Only") then
    if beatdom and artistdom and patternd then
      local bs = beatdom.get_state()
      local as = artistdom.get_artist_state()
      local cfg = read_pattern_cfg()
      local explicit = cfg.mode_hint ~= "" and cfg.mode_hint or nil
      patternd.generate(as, bs, explicit, cfg)
    end
  end

  ig.Separator(ctx)
  if ig.Button(ctx, "Open Performance Hub") then
    open_hub_script("IFLS_PerformanceHub_ImGui.lua")
  end
end

local function draw_hubs_tab(ctx)
  ig.Text(ctx, "Sub-Hubs Quick Launch")
  ig.Separator(ctx)

  if ig.Button(ctx, "Artist Hub") then
    open_hub_script("IFLS_ArtistHub_ImGui.lua")
  end

  if ig.Button(ctx, "Beat Control Center") then
    open_hub_script("IFLS_BeatControlCenter_ImGui.lua")
  end

  if ig.Button(ctx, "Sample Hub") then
    open_hub_script("IFLS_SampleHub_ImGui.lua")
  end

  if ig.Button(ctx, "Pattern Hub") then
    open_hub_script("IFLS_PatternHub_ImGui.lua")
  end

  if ig.Button(ctx, "Tuning Hub") then
    open_hub_script("IFLS_TuningHub_ImGui.lua")
  end

  if ig.Button(ctx, "Tuning Sync Hub") then
    open_hub_script("IFLS_TuningSync_ImGui.lua")
  end

  if ig.Button(ctx, "Performance Hub") then
    open_hub_script("IFLS_PerformanceHub_ImGui.lua")
  end

  if ig.Button(ctx, "Scene Arranger Hub") then
    open_hub_script("IFLS_SceneArrangerHub_ImGui.lua")
  end

  if ig.Button(ctx, "Audio Import Hub") then
    open_hub_script("IFLS_AudioImportHub_ImGui.lua")
  end

  if ig.Button(ctx, "Slice Hub") then
    open_hub_script("IFLS_SliceHub_ImGui.lua")
  end

  if ig.Button(ctx, "Sample Library Hub (UCS)") then
    open_hub_script("IFLS_SampleLibraryHub_ImGui.lua")
  end

  if ig.Button(ctx, "Kit Builder Hub") then
    open_hub_script("IFLS_KitBuilderHub_ImGui.lua")
  end

  if ig.Button(ctx, "Audio Pattern Bridge Hub") then
    open_hub_script("IFLS_AudioPatternBridgeHub_ImGui.lua")
  end
end

local function draw(ctx)
  if ig.BeginTabBar(ctx, "IFLS_MasterHub_Tabs") then
    if ig.BeginTabItem(ctx, "Overview") then
      draw_overview_tab(ctx)
      ig.EndTabItem(ctx)
    end
    if ig.BeginTabItem(ctx, "Artist") then
      draw_artist_tab(ctx)
      ig.EndTabItem(ctx)
    end
    if ig.BeginTabItem(ctx, "Beat / Pattern") then
      draw_beat_pattern_tab(ctx)
      ig.EndTabItem(ctx)
    end
    if ig.BeginTabItem(ctx, "Sample") then
      draw_sample_tab(ctx)
      ig.EndTabItem(ctx)
    end
    if ig.BeginTabItem(ctx, "Tuning") then
      draw_tuning_tab(ctx)
      ig.EndTabItem(ctx)
    end
    if ig.BeginTabItem(ctx, "Performance") then
      draw_performance_tab(ctx)
      ig.EndTabItem(ctx)
    end
    if ig.BeginTabItem(ctx, "Hubs") then
      draw_hubs_tab(ctx)
      ig.EndTabItem(ctx)
    end
    ig.EndTabBar(ctx)
  end
end

ui_core.run_mainloop(ctx, "IFLS Master Hub", draw)
