-- IFLS_BeatDomain.lua
-- Domain module for beat-related state and engine orchestration.
-- Diese Variante nutzt SYMBOLISCHE NamedCommand-Strings für deine
-- V196/V198/AIBeat-Engines und Layer-Skripte, damit du in REAPER
-- nur noch die echten Action-IDs an den passenden Stellen eintragen
-- (oder die Symbolnamen 1:1 ersetzen) musst.
--
-- Idee:
--   1. Du suchst in der Action List nach z.B.
--        DF95_V196_BeatEngine
--        DF95_V198_SpeechLoopLayers
--      kopierst die jeweilige Command ID (z.B. _RSa1b2c3d4e5f6)
--   2. Du ersetzt im COMMANDS/LAYERS-Block unten den symbolischen
--      Platzhalterstring durch diese echte ID.
--
-- Damit vermeidest du Copy&Paste-Fehler im restlichen Code.

local r = reaper
local core_path = r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Core/"

----------------------------------------------------------------
-- Core-Module laden
----------------------------------------------------------------
local ok_contracts, contracts = pcall(dofile, core_path .. "IFLS_Contracts.lua")
local ok_ext,       ext       = pcall(dofile, core_path .. "IFLS_ExtState.lua")

if not ok_contracts or type(contracts) ~= "table" then
  r.ShowConsoleMsg("IFLS_BeatDomain: Failed to load IFLS_Contracts.lua\n")
  contracts = {
    NS_BEAT     = "DF95_AI_BEAT",
    NS_BEAT_CC  = "DF95_BEAT_CC",
    BEAT_KEYS   = {},
    BEAT_CC_KEYS= {},
  }
end

if not ok_ext or type(ext) ~= "table" then
  r.ShowConsoleMsg("IFLS_BeatDomain: Failed to load IFLS_ExtState.lua\n")
  ext = {
    get_proj        = function(_,_,default) return default end,
    get_proj_number = function(_,_,default) return default end,
    set_proj        = function() end,
    set_proj_number = function() end,
  }
end

local domain_path = r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/"
local ok_human_bridge, human_bridge = pcall(dofile, domain_path .. "IFLS_HumanizeDomain.lua")

local M = {}


----------------------------------------------------------------
-- Symbolische NamedCommand-Strings
--
-- WICHTIG:
--   Diese Strings sind PLATZHALTER, du suchst dir dazu passende
--   Actions in deiner Action-Liste:
--
--   * DF95_V196_BeatEngine           → komplette V196-Engine
--   * DF95_V198_BeatEngine           → komplette V198-Engine
--   * DF95_AIBeat_V133_Engine        → AIBeat-Engine V133
--   * DF95_AIBeat_V134_Engine        → AIBeat-Engine V134
--
--   * DF95_V196_MIDILayers           → nur MIDI-Layer von V196
--   * DF95_V198_LoopLayers           → nur Loop-Layer von V198
--   * DF95_V198_SpeechLoopLayers     → Loop+Speech-Layer V198
--
-- Vorgehen:
--   - In REAPER Action List nach diesen Bezeichnern suchen
--   - Die echte Command ID kopieren (z.B. _RSa1b2c3d4e5f6)
--   - Hier unten den Symbolstring durch die echte ID ersetzen.
----------------------------------------------------------------

local COMMANDS = {
  -- Haupt-Engines (Run Engine)
  V196_ENGINE        = "_RS_DF95_V196_BeatEngine",
  V198_ENGINE        = "_RS_DF95_V198_BeatEngine",
  AIBEAT_V133_ENGINE = "_RS_DF95_AIBeat_V133_Engine",
  AIBEAT_V134_ENGINE = "_RS_DF95_AIBeat_V134_Engine",
}

local LAYERS = {
  -- Layer-Skripte (Build Layers)
  V196_MIDI_LAYERS     = "_RS_DF95_V196_MIDILayers",        -- nur MIDI
  V198_LOOP_LAYERS     = "_RS_DF95_V198_LoopLayers",        -- nur Loops
  V198_SPEECH_LAYERS   = "_RS_DF95_V198_SpeechLoopLayers",  -- Loops+Speech
}

----------------------------------------------------------------
-- Beat-State lesen/schreiben
----------------------------------------------------------------

function M.get_state()
  local ns_bea   = contracts.NS_BEAT
  local ns_cc    = contracts.NS_BEAT_CC
  local BK       = contracts.BEAT_KEYS     or {}
  local BCCK     = contracts.BEAT_CC_KEYS  or {}

  local state = {}

  state.bpm      = ext.get_proj_number(ns_bea, BK.BPM      or "BPM",      120)
  state.ts_num   = ext.get_proj_number(ns_bea, BK.TS_NUM   or "TS_NUM",   4)
  state.ts_den   = ext.get_proj_number(ns_bea, BK.TS_DEN   or "TS_DEN",   4)
  state.bars     = ext.get_proj_number(ns_bea, BK.BARS     or "BARS",     8)
  state.mode     = ext.get_proj       (ns_bea, BK.MODE     or "MODE",     "default")
  state.swing    = ext.get_proj_number(ns_bea, BK.SWING    or "SWING",    0)
  state.groove   = ext.get_proj       (ns_bea, BK.GROOVE   or "GROOVE",   "")

  state.engine   = ext.get_proj       (ns_cc, BCCK.ENGINE            or "ENGINE",            "V198")
  state.use_midi_layers   = ext.get_proj(ns_cc, BCCK.USE_MIDI_LAYERS   or "USE_MIDI_LAYERS",   "1") == "1"
  state.use_loop_layers   = ext.get_proj(ns_cc, BCCK.USE_LOOP_LAYERS   or "USE_LOOP_LAYERS",   "1") == "1"
  state.use_speech_layers = ext.get_proj(ns_cc, BCCK.USE_SPEECH_LAYERS or "USE_SPEECH_LAYERS", "0") == "1"
  state.use_sampler_setup = ext.get_proj(ns_cc, BCCK.USE_SAMPLER_SETUP or "USE_SAMPLER_SETUP", "0") == "1"
  state.sampler_mode      = ext.get_proj(ns_cc, BCCK.SAMPLER_MODE      or "SAMPLER_MODE",      "RS5K")
  state.artist_profile    = ext.get_proj(ns_cc, BCCK.ARTIST_PROFILE    or "ARTIST_PROFILE",    "")
  state.sampledb_filter   = ext.get_proj(ns_cc, BCCK.SAMPLEDB_FILTER   or "SAMPLEDB_FILTER",   "")
  state.sampledb_category = ext.get_proj(ns_cc, BCCK.SAMPLEDB_CATEGORY or "SAMPLEDB_CATEGORY", "")
  state.humanize_mode     = ext.get_proj(ns_cc, BCCK.HUMANIZE_MODE     or "HUMANIZE_MODE",     "")
  state.reroll_request    = ext.get_proj(ns_cc, BCCK.REROLL_REQUEST    or "REROLL_REQUEST",    "0") == "1"
  state.idm_chain_profile = ext.get_proj(ns_cc, BCCK.IDM_CHAIN_PROFILE  or "IDM_CHAIN_PROFILE",  "")
  state.idm_chain_autofx  = ext.get_proj(ns_cc, BCCK.IDM_CHAIN_AUTOFX   or "IDM_CHAIN_AUTOFX",   "0") == "1"


  return state
end

function M.set_state(state)
  local ns_bea   = contracts.NS_BEAT
  local ns_cc    = contracts.NS_BEAT_CC
  local BK       = contracts.BEAT_KEYS     or {}
  local BCCK     = contracts.BEAT_CC_KEYS  or {}

  if state.bpm      then ext.set_proj_number(ns_bea, BK.BPM    or "BPM",    state.bpm)  end
  if state.ts_num   then ext.set_proj_number(ns_bea, BK.TS_NUM or "TS_NUM", state.ts_num) end
  if state.ts_den   then ext.set_proj_number(ns_bea, BK.TS_DEN or "TS_DEN", state.ts_den) end
  if state.bars     then ext.set_proj_number(ns_bea, BK.BARS   or "BARS",   state.bars) end
  if state.mode     then ext.set_proj       (ns_bea, BK.MODE   or "MODE",   state.mode) end
  if state.swing    then ext.set_proj_number(ns_bea, BK.SWING  or "SWING",  state.swing) end
  if state.groove   then ext.set_proj       (ns_bea, BK.GROOVE or "GROOVE", state.groove) end

  if state.engine then
    ext.set_proj(ns_cc, BCCK.ENGINE or "ENGINE", state.engine)
  end
  if state.use_midi_layers ~= nil then
    ext.set_proj(ns_cc, BCCK.USE_MIDI_LAYERS or "USE_MIDI_LAYERS", state.use_midi_layers and "1" or "0")
  end
  if state.use_loop_layers ~= nil then
    ext.set_proj(ns_cc, BCCK.USE_LOOP_LAYERS or "USE_LOOP_LAYERS", state.use_loop_layers and "1" or "0")
  end
  if state.use_speech_layers ~= nil then
    ext.set_proj(ns_cc, BCCK.USE_SPEECH_LAYERS or "USE_SPEECH_LAYERS", state.use_speech_layers and "1" or "0")
  end
  if state.use_sampler_setup ~= nil then
    ext.set_proj(ns_cc, BCCK.USE_SAMPLER_SETUP or "USE_SAMPLER_SETUP", state.use_sampler_setup and "1" or "0")
  end
  if state.sampler_mode then
    ext.set_proj(ns_cc, BCCK.SAMPLER_MODE or "SAMPLER_MODE", state.sampler_mode)
  end
  if state.artist_profile then
    ext.set_proj(ns_cc, BCCK.ARTIST_PROFILE or "ARTIST_PROFILE", state.artist_profile)
  end
  if state.sampledb_filter then
    ext.set_proj(ns_cc, BCCK.SAMPLEDB_FILTER or "SAMPLEDB_FILTER", state.sampledb_filter)
  end
  if state.sampledb_category then
    ext.set_proj(ns_cc, BCCK.SAMPLEDB_CATEGORY or "SAMPLEDB_CATEGORY", state.sampledb_category)
  end
  if state.humanize_mode then
    ext.set_proj(ns_cc, BCCK.HUMANIZE_MODE or "HUMANIZE_MODE", state.humanize_mode)
  end
  if state.reroll_request ~= nil then
    ext.set_proj(ns_cc, BCCK.REROLL_REQUEST or "REROLL_REQUEST", state.reroll_request and "1" or "0")
  end
end

----------------------------------------------------------------
-- Action-Helfer
----------------------------------------------------------------

local function run_action_by_named_cmd(named_cmd)
  if not named_cmd or named_cmd == "" then return end
  local cmd_id = r.NamedCommandLookup(named_cmd)
  if cmd_id == 0 then
    r.ShowConsoleMsg("IFLS_BeatDomain: NamedCommandLookup failed for " .. tostring(named_cmd) .. "\n")
    return
  end
  r.Undo_BeginBlock()
  r.Main_OnCommand(cmd_id, 0)
  r.Undo_EndBlock("IFLS BeatDomain run " .. named_cmd, -1)
end


----------------------------------------------------------------
-- DF95 Humanize Bridge:
--   schreibt Humanize-Config aus IFLS_HumanizeDomain als
--   DF95_HUMANIZE PROFILE_JSON (wird von DF95_Humanize_Apply
--   und verwandten Tools gelesen).
----------------------------------------------------------------
local function apply_df95_humanize_from_ifls()
  if not ok_human_bridge or type(human_bridge) ~= "table" then return end
  if not human_bridge.load or not human_bridge.to_df95_profile then return end

  local cfg = human_bridge.load(0)
  local prof = human_bridge.to_df95_profile(cfg)
  if not prof then return end

  local function num(n) return tostring(tonumber(n) or 0) end

  local json = string.format(
    '{"timing_ms":%s,"velocity_percent":%s,"swing_percent":%s,"length_ms":%s}',
    num(prof.timing_ms),
    num(prof.velocity_percent),
    num(prof.swing_percent),
    num(prof.length_ms)
  )

  reaper.SetProjExtState(0, "DF95_HUMANIZE", "PROFILE_JSON", json)
end


----------------------------------------------------------------
-- Engines: Run Engine
----------------------------------------------------------------

M.engine_map = {
  V196 = function(state)
    if COMMANDS.V196_ENGINE and COMMANDS.V196_ENGINE ~= "" then
      run_action_by_named_cmd(COMMANDS.V196_ENGINE)
    end
  end,

  V198 = function(state)
    if COMMANDS.V198_ENGINE and COMMANDS.V198_ENGINE ~= "" then
      run_action_by_named_cmd(COMMANDS.V198_ENGINE)
    end
  end,

  V133 = function(state)
    if COMMANDS.AIBEAT_V133_ENGINE and COMMANDS.AIBEAT_V133_ENGINE ~= "" then
      run_action_by_named_cmd(COMMANDS.AIBEAT_V133_ENGINE)
    end
  end,

  V134 = function(state)
    if COMMANDS.AIBEAT_V134_ENGINE and COMMANDS.AIBEAT_V134_ENGINE ~= "" then
      run_action_by_named_cmd(COMMANDS.AIBEAT_V134_ENGINE)
    end
  end,
}

function M.run_engine(state)
  state = state or M.get_state()

  -- Humanize-Bridge: aktuelle IFLS-Humanize-Settings als
  -- DF95_HUMANIZE-Profil schreiben, bevor Engine/Layer laufen.
  apply_df95_humanize_from_ifls()

  local engine_name = state.engine or "V198"
  local handler = M.engine_map[engine_name]
  if type(handler) == "function" then
    handler(state)
  else
    r.ShowConsoleMsg(
      string.format("IFLS_BeatDomain: No engine handler registered for '%s'\n", tostring(engine_name))
    )
  end
end


----------------------------------------------------------------
-- Layer-Aufbau: Build Layers (konkret V196/V198)
----------------------------------------------------------------

function M.build_layers(state)
  state = state or M.get_state()

  -- MIDI-Layer (V196)
  if state.use_midi_layers and LAYERS.V196_MIDI_LAYERS and LAYERS.V196_MIDI_LAYERS ~= "" then
    run_action_by_named_cmd(LAYERS.V196_MIDI_LAYERS)
  end

  -- Loop-Layer (V198)
  if state.use_loop_layers and LAYERS.V198_LOOP_LAYERS and LAYERS.V198_LOOP_LAYERS ~= "" then
    run_action_by_named_cmd(LAYERS.V198_LOOP_LAYERS)
  end

  -- Speech-Layer (V198)
  if state.use_speech_layers then
    if LAYERS.V198_SPEECH_LAYERS and LAYERS.V198_SPEECH_LAYERS ~= "" then
      run_action_by_named_cmd(LAYERS.V198_SPEECH_LAYERS)
    elseif LAYERS.V198_LOOP_LAYERS and LAYERS.V198_LOOP_LAYERS ~= "" then
      -- Fallback: gleiche Action für Loop+Speech
      run_action_by_named_cmd(LAYERS.V198_LOOP_LAYERS)
    end
  end
end

return M
