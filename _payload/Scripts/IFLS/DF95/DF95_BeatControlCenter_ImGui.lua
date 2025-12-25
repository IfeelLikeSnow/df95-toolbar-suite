-- DF95_BeatControlCenter_ImGui.lua
-- Unified DF95 Beat Control Center (ImGui)
-- Requires: ReaImGui (via ReaPack), SWS recommended

------------------------------------------------------------
-- CONFIG: ACTIONS / MACROS ANBINDEN
------------------------------------------------------------

-- OPTION A: direkte Command-IDs der vorhandenen DF95-Macros
-- Tipp: Im Action List: Rechtsklick auf Action -> "Copy selected action command ID"
-- und hier als Zahl eintragen.
local CMD_BEAT_ENGINE          = 0    -- z.B. V198 Main Engine Macro
local CMD_SAMPLER_SETUP        = 0    -- z.B. V195 Sampler Routing / RS5k/TX16Wx
local CMD_SAMPLEDB_BROWSER     = 0    -- z.B. SampleDB Browser / Loader
local CMD_EXPORT_MACRO         = 0    -- z.B. Render/Export Macro

-- OPTION B (falls du keine Command-IDs nutzen willst):
-- Du kannst alternativ NamedCommandStrings verwenden, z.B. "_RS123456789abcdef"
-- Lass einfach die CMD_* = 0 und deine anderen DF95-Scripts lesen Trigger-Flags
-- aus den ExtStates (TRIGGER_*), siehe unten.

------------------------------------------------------------
-- EXTSTATE-NAMESPACES & HELFER
------------------------------------------------------------

local NS_BEAT   = "DF95_AI_BEAT"   -- bereits bei dir im Einsatz (BPM, TS, Bars, etc.)
local NS_CC     = "DF95_BEAT_CC"   -- neues Control-Center-Namespace

local function GetExt(ns, key, default)
  local v = reaper.GetExtState(ns, key)
  if v == nil or v == "" then return default end
  return v
end

local function SetExt(ns, key, value, persist)
  reaper.SetExtState(ns, key, tostring(value or ""), persist ~= false)
end

local function GetExtBool(ns, key, default)
  local v = reaper.GetExtState(ns, key)
  if v == nil or v == "" then return default end
  return v == "1"
end

local function SetExtBool(ns, key, value, persist)
  reaper.SetExtState(ns, key, value and "1" or "0", persist ~= false)
end

------------------------------------------------------------
-- STATE-STRUKTUR
------------------------------------------------------------

local state = {
  bpm              = 120.0,
  ts_num           = 4,
  ts_den           = 4,
  bars             = 8,

  engine_list      = { "NONE", "V195", "V196", "V197", "V198" },
  engine_idx       = 1,   -- Index in engine_list

  use_midi_layers        = true,
  use_loop_layers        = true,
  use_speech_layers      = false,
  use_sampler_setup      = true,
  sampler_modes          = { "RS5K", "TX16WX" },
  sampler_mode_idx       = 1,   -- RS5K

  artist_profile         = "",
  humanize_amount        = 30.0,  -- 0–100 (%)
  randomize_seed         = 0,

  sampledb_filter        = "",
  sampledb_category      = "",

  -- Trigger-Flags für Scripts, falls du OPTION B nutzen willst
  trigger_beat_engine    = false,
  trigger_sampler_setup  = false,
  trigger_sampledb       = false,
  trigger_export         = false,
}

------------------------------------------------------------
-- STATE INITIALISIEREN AUS EXTSTATES
------------------------------------------------------------

local function InitStateFromExt()
  -- BPM / TS / Bars aus Beat-Namespace
  local bpm_ext = tonumber(GetExt(NS_BEAT, "BPM", "0"))
  if not bpm_ext or bpm_ext <= 0 then
    bpm_ext = reaper.Master_GetTempo() or 120.0
  end
  state.bpm = bpm_ext

  state.ts_num = tonumber(GetExt(NS_BEAT, "TS_NUM", "4")) or 4
  state.ts_den = tonumber(GetExt(NS_BEAT, "TS_DEN", "4")) or 4
  state.bars   = tonumber(GetExt(NS_BEAT, "BARS",   "8")) or 8

  -- Engine
  local engine_name = GetExt(NS_CC, "ENGINE", "NONE")
  state.engine_idx = 1
  for i, name in ipairs(state.engine_list) do
    if name == engine_name then
      state.engine_idx = i
      break
    end
  end

  -- Layer-Toggles
  state.use_midi_layers   = GetExtBool(NS_CC, "USE_MIDI_LAYERS",  true)
  state.use_loop_layers   = GetExtBool(NS_CC, "USE_LOOP_LAYERS",  true)
  state.use_speech_layers = GetExtBool(NS_CC, "USE_SPEECH_LAYERS",false)
  state.use_sampler_setup = GetExtBool(NS_CC, "USE_SAMPLER_SETUP",true)

  -- Sampler Mode
  local sampler_mode = GetExt(NS_CC, "SAMPLER_MODE", "RS5K")
  state.sampler_mode_idx = 1
  for i, mode in ipairs(state.sampler_modes) do
    if mode == sampler_mode then
      state.sampler_mode_idx = i
      break
    end
  end

  -- Artist / Humanize
  state.artist_profile  = GetExt(NS_CC, "ARTIST_PROFILE", "")
  state.humanize_amount = tonumber(GetExt(NS_CC, "HUMANIZE", "30")) or 30.0
  state.randomize_seed  = tonumber(GetExt(NS_CC, "RND_SEED", "0")) or 0

  -- SampleDB
  state.sampledb_filter   = GetExt(NS_CC, "SAMPLEDB_FILTER", "")
  state.sampledb_category = GetExt(NS_CC, "SAMPLEDB_CATEGORY", "")

  -- Trigger Flags (werden beim Setzen jeweils sofort in ExtState geschrieben)
  state.trigger_beat_engine   = false
  state.trigger_sampler_setup = false
  state.trigger_sampledb      = false
  state.trigger_export        = false

  -- Schreibe initial zurück (damit alle Keys konsistent existieren)
  SetExt(NS_BEAT, "BPM",    state.bpm)
  SetExt(NS_BEAT, "TS_NUM", state.ts_num)
  SetExt(NS_BEAT, "TS_DEN", state.ts_den)
  SetExt(NS_BEAT, "BARS",   state.bars)

  SetExt(NS_CC, "ENGINE",            state.engine_list[state.engine_idx])
  SetExtBool(NS_CC, "USE_MIDI_LAYERS",   state.use_midi_layers)
  SetExtBool(NS_CC, "USE_LOOP_LAYERS",   state.use_loop_layers)
  SetExtBool(NS_CC, "USE_SPEECH_LAYERS", state.use_speech_layers)
  SetExtBool(NS_CC, "USE_SAMPLER_SETUP", state.use_sampler_setup)
  SetExt(NS_CC, "SAMPLER_MODE",      state.sampler_modes[state.sampler_mode_idx])
  SetExt(NS_CC, "ARTIST_PROFILE",    state.artist_profile)
  SetExt(NS_CC, "HUMANIZE",          state.humanize_amount)
  SetExt(NS_CC, "RND_SEED",          state.randomize_seed)
  SetExt(NS_CC, "SAMPLEDB_FILTER",   state.sampledb_filter)
  SetExt(NS_CC, "SAMPLEDB_CATEGORY", state.sampledb_category)
end

------------------------------------------------------------
-- HELFER: ENGINE / MACRO STARTEN
------------------------------------------------------------

local function RunCommandIfSet(cmd_id)
  if cmd_id and cmd_id > 0 then
    reaper.Main_OnCommand(cmd_id, 0)
    return true
  end
  return false
end

local function TriggerBeatEngine()
  if not RunCommandIfSet(CMD_BEAT_ENGINE) then
    -- Fallback: Trigger-ExtState setzen, andere DF95-Scripts poll’en das
    SetExtBool(NS_CC, "TRIGGER_BEAT_ENGINE", true)
  end
end

local function TriggerSamplerSetup()
  if not RunCommandIfSet(CMD_SAMPLER_SETUP) then
    SetExtBool(NS_CC, "TRIGGER_SAMPLER_SETUP", true)
  end
end

local function TriggerSampleDB()
  if not RunCommandIfSet(CMD_SAMPLEDB_BROWSER) then
    SetExtBool(NS_CC, "TRIGGER_SAMPLEDB", true)
  end
end

local function TriggerExport()
  if not RunCommandIfSet(CMD_EXPORT_MACRO) then
    SetExtBool(NS_CC, "TRIGGER_EXPORT", true)
  end
end

------------------------------------------------------------
-- IMGUI SETUP
------------------------------------------------------------

local ctx = reaper.ImGui_CreateContext("DF95 Beat Control Center")
local initialized = false
local open = true

------------------------------------------------------------
-- IMGUI DRAW-FUNKTIONEN
------------------------------------------------------------

local function DrawBeatSection()
  reaper.ImGui_Text(ctx, "Global Beat")
  reaper.ImGui_Separator(ctx)

  -- BPM
  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, "BPM:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 120)
  local changed, new_bpm = reaper.ImGui_DragDouble(ctx, "##bpm", state.bpm, 0.1, 40.0, 300.0, "%.1f")
  reaper.ImGui_PopItemWidth(ctx)
  if changed then
    state.bpm = new_bpm
    SetExt(NS_BEAT, "BPM", new_bpm)
    reaper.SetCurrentBPM(0, new_bpm, true)
  end

  -- Time Signature
  reaper.ImGui_Text(ctx, "Taktart:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 50)
  local ts_changed_num, ts_num = reaper.ImGui_InputInt(ctx, "##tsnum", state.ts_num, 1, 4)
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_Text(ctx, "/")
  reaper.ImGui_SameLine(ctx)
  local ts_changed_den, ts_den = reaper.ImGui_InputInt(ctx, "##tsden", state.ts_den, 1, 4)
  reaper.ImGui_PopItemWidth(ctx)

  if ts_changed_num or ts_changed_den then
    state.ts_num = math.max(1, ts_num)
    state.ts_den = math.max(1, ts_den)
    SetExt(NS_BEAT, "TS_NUM", state.ts_num)
    SetExt(NS_BEAT, "TS_DEN", state.ts_den)
  end

  -- Bars
  reaper.ImGui_Text(ctx, "Bars:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 80)
  local bars_changed, bars = reaper.ImGui_InputInt(ctx, "##bars", state.bars, 1, 4)
  reaper.ImGui_PopItemWidth(ctx)
  if bars_changed then
    state.bars = math.max(1, bars)
    SetExt(NS_BEAT, "BARS", state.bars)
  end
end

local function DrawEngineSection()
  reaper.ImGui_Text(ctx, "Engine & Layers")
  reaper.ImGui_Separator(ctx)

  -- Engine Auswahl
  reaper.ImGui_Text(ctx, "Beat Engine:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 150)
  local preview = state.engine_list[state.engine_idx] or "NONE"
  if reaper.ImGui_BeginCombo(ctx, "##engine", preview) then
    for i, name in ipairs(state.engine_list) do
      local is_selected = (i == state.engine_idx)
      if reaper.ImGui_Selectable(ctx, name, is_selected) then
        state.engine_idx = i
        SetExt(NS_CC, "ENGINE", name)
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopItemWidth(ctx)

  -- Layer Toggles
  local changed_midi, midi_val = reaper.ImGui_Checkbox(ctx, "MIDI Layers (V196)", state.use_midi_layers)
  if changed_midi then
    state.use_midi_layers = midi_val
    SetExtBool(NS_CC, "USE_MIDI_LAYERS", midi_val)
  end

  local changed_loop, loop_val = reaper.ImGui_Checkbox(ctx, "Loop Layers (V198)", state.use_loop_layers)
  if changed_loop then
    state.use_loop_layers = loop_val
    SetExtBool(NS_CC, "USE_LOOP_LAYERS", loop_val)
  end

  local changed_speech, speech_val = reaper.ImGui_Checkbox(ctx, "Speech Layers (V198 Speech)", state.use_speech_layers)
  if changed_speech then
    state.use_speech_layers = speech_val
    SetExtBool(NS_CC, "USE_SPEECH_LAYERS", speech_val)
  end

  local changed_sampler_use, sampler_use_val = reaper.ImGui_Checkbox(ctx, "Sampler Setup aktiv (V195)", state.use_sampler_setup)
  if changed_sampler_use then
    state.use_sampler_setup = sampler_use_val
    SetExtBool(NS_CC, "USE_SAMPLER_SETUP", sampler_use_val)
  end

  -- Sampler Mode
  reaper.ImGui_Text(ctx, "Sampler Mode:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 120)
  local sm_preview = state.sampler_modes[state.sampler_mode_idx] or "RS5K"
  if reaper.ImGui_BeginCombo(ctx, "##sampler_mode", sm_preview) then
    for i, mode in ipairs(state.sampler_modes) do
      local is_selected = (i == state.sampler_mode_idx)
      if reaper.ImGui_Selectable(ctx, mode, is_selected) then
        state.sampler_mode_idx = i
        SetExt(NS_CC, "SAMPLER_MODE", mode)
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopItemWidth(ctx)

  reaper.ImGui_Separator(ctx)

  if reaper.ImGui_Button(ctx, "Beat Engine starten", reaper.ImGui_GetFontSize(ctx) * 10, 0) then
    TriggerBeatEngine()
  end
end

local function DrawArtistSection()
  reaper.ImGui_Text(ctx, "Artist & Humanize")
  reaper.ImGui_Separator(ctx)

  reaper.ImGui_Text(ctx, "Artist Profil:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 200)
  local changed_profile, new_profile = reaper.ImGui_InputText(ctx, "##artist_profile", state.artist_profile, 256)
  reaper.ImGui_PopItemWidth(ctx)
  if changed_profile then
    state.artist_profile = new_profile
    SetExt(NS_CC, "ARTIST_PROFILE", new_profile)
  end

  reaper.ImGui_Text(ctx, "Humanize (%):")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 150)
  local changed_hum, new_hum = reaper.ImGui_SliderDouble(ctx, "##humanize", state.humanize_amount, 0.0, 100.0, "%.0f")
  reaper.ImGui_PopItemWidth(ctx)
  if changed_hum then
    state.humanize_amount = new_hum
    SetExt(NS_CC, "HUMANIZE", new_hum)
  end

  reaper.ImGui_Text(ctx, "Random Seed:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 120)
  local changed_seed, new_seed = reaper.ImGui_InputInt(ctx, "##rnd_seed", state.randomize_seed, 1, 10)
  reaper.ImGui_PopItemWidth(ctx)
  if changed_seed then
    state.randomize_seed = new_seed
    SetExt(NS_CC, "RND_SEED", new_seed)
  end

  reaper.ImGui_Separator(ctx)

  if reaper.ImGui_Button(ctx, "Re-Roll / New Variation", reaper.ImGui_GetFontSize(ctx) * 10, 0) then
    state.randomize_seed = state.randomize_seed + 1
    SetExt(NS_CC, "RND_SEED", state.randomize_seed)
    TriggerBeatEngine()
  end
end

local function DrawSampleDBSection()
  reaper.ImGui_Text(ctx, "SampleDB")
  reaper.ImGui_Separator(ctx)

  reaper.ImGui_Text(ctx, "Filter:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 200)
  local changed_filter, new_filter = reaper.ImGui_InputText(ctx, "##sdb_filter", state.sampledb_filter, 256)
  reaper.ImGui_PopItemWidth(ctx)
  if changed_filter then
    state.sampledb_filter = new_filter
    SetExt(NS_CC, "SAMPLEDB_FILTER", new_filter)
  end

  reaper.ImGui_Text(ctx, "Kategorie:")
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 150)
  local changed_cat, new_cat = reaper.ImGui_InputText(ctx, "##sdb_cat", state.sampledb_category, 256)
  reaper.ImGui_PopItemWidth(ctx)
  if changed_cat then
    state.sampledb_category = new_cat
    SetExt(NS_CC, "SAMPLEDB_CATEGORY", new_cat)
  end

  reaper.ImGui_Separator(ctx)

  if reaper.ImGui_Button(ctx, "SampleDB Browser öffnen", reaper.ImGui_GetFontSize(ctx) * 12, 0) then
    TriggerSampleDB()
  end
end

local function DrawUtilitySection()
  reaper.ImGui_Text(ctx, "Sampler & Export")
  reaper.ImGui_Separator(ctx)

  if reaper.ImGui_Button(ctx, "Sampler Setup (RS5k / TX16Wx)", reaper.ImGui_GetFontSize(ctx) * 12, 0) then
    TriggerSamplerSetup()
  end

  if reaper.ImGui_Button(ctx, "Export / Render Macro", reaper.ImGui_GetFontSize(ctx) * 12, 0) then
    TriggerExport()
  end
end

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------

local function MainLoop()
  if not initialized then
    InitStateFromExt()
    initialized = true
  end

  if not open then
    reaper.ImGui_DestroyContext(ctx)
    return
  end

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 6.0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 4.0)

  reaper.ImGui_NewFrame(ctx)

  local visible
  visible, open = reaper.ImGui_Begin(ctx, "DF95 BEAT CONTROL CENTER", true,
    reaper.ImGui_WindowFlags_NoCollapse())

  if visible then
    if reaper.ImGui_BeginTabBar(ctx, "MainTabs") then
      if reaper.ImGui_BeginTabItem(ctx, "Beat") then
        DrawBeatSection()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "Engine / Layers") then
        DrawEngineSection()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "Artist") then
        DrawArtistSection()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "SampleDB") then
        DrawSampleDBSection()
        reaper.ImGui_EndTabItem(ctx)
      end

      if reaper.ImGui_BeginTabItem(ctx, "Utility") then
        DrawUtilitySection()
        reaper.ImGui_EndTabItem(ctx)
      end

      reaper.ImGui_EndTabBar(ctx)
    end

    reaper.ImGui_End(ctx)
  end

  reaper.ImGui_PopStyleVar(ctx, 2)

  reaper.ImGui_Render(ctx)
  reaper.defer(MainLoop)
end

reaper.defer(MainLoop)
