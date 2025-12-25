-- IFLS_MarkovRhythmDomain.lua
-- Markov-basierter Rhythmusgenerator für IFLS
-- Idee: Ein globales Hit/Rest-Muster (0/1) via 2x2-Markovkette,
--       verteilt auf bis zu drei Drumlane (Kick/Snare/Hat) mit eigenen "apply_prob".
--
-- ExtState: Namespace "IFLS_MARKOVRHYTHM"

local r = reaper
local M = {}

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
  }
end

local NS_MARKOV = "IFLS_MARKOVRHYTHM"

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg("[IFLS_MarkovRhythm] " .. tostring(s) .. "\n")
end

local function ensure_pos(v, d)
  v = tonumber(v) or d
  if v <= 0 then return d end
  return v
end

local function clamp01(v)
  v = tonumber(v) or 0.0
  if v < 0 then v = 0 end
  if v > 1 then v = 1 end
  return v
end

local function qn_per_bar(ts_num, ts_den)
  ts_num = ts_num or 4
  ts_den = ts_den or 4
  return ts_num * (4.0 / ts_den)
end

local function get_target_track()
  local tr = r.GetSelectedTrack(0, 0)
  if tr then return tr end
  tr = r.GetTrack(0, 0)
  if tr then return tr end
  r.InsertTrackAtIndex(0, true)
  return r.GetTrack(0, 0)
end

local function create_midi_item(track, bars, ts_num, ts_den)
  track = track or get_target_track()
  bars  = ensure_pos(bars, 4)

  ts_num = ts_num or 4
  ts_den = ts_den or 4

  local qn_len   = qn_per_bar(ts_num, ts_den) * bars
  local start_qn = 0.0
  local end_qn   = start_qn + qn_len

  local st_time  = r.TimeMap2_QNToTime(0, start_qn)
  local en_time  = r.TimeMap2_QNToTime(0, end_qn)

  local item = r.CreateNewMIDIItemInProj(track, st_time, en_time, false)
  local take = r.GetTake(item, 0)
  return item, take, start_qn, end_qn
end

local function insert_note_qn(take, pitch, vel, start_qn, end_qn, chan)
  chan = chan or 0
  vel  = vel or 96
  local ppq_start = r.MIDI_GetPPQPosFromProjQN(take, start_qn)
  local ppq_end   = r.MIDI_GetPPQPosFromProjQN(take, end_qn)
  r.MIDI_InsertNote(take, false, false, ppq_start, ppq_end, chan, pitch, vel, false)
end

local function finalize_take(take)
  r.MIDI_Sort(take)
end

------------------------------------------------------------
-- ExtState Config
------------------------------------------------------------

local function ep_num(key, def)
  local s = ext.get_proj(NS_MARKOV, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function ep_bool(key, def)
  local s = ext.get_proj(NS_MARKOV, key, def and "1" or "0")
  return s == "1"
end

local function load_cfg_from_extstate()
  local cfg = {
    enabled = ep_bool("ENABLED", false),
    bars    = ep_num("BARS", 4),
    steps   = ep_num("STEPS", 16),

    start_hit_prob = clamp01(ep_num("START_HIT_PROB", 0.5)),

    p_hh = clamp01(ep_num("P_HH", 0.8)), -- P(hit | hit)
    p_rh = clamp01(ep_num("P_RH", 0.4)), -- P(hit | rest)

    seed = ep_num("SEED", 0),

    lanes = {
      {
        enabled      = ep_bool("L1_ENABLED", true),
        pitch        = ep_num("L1_PITCH", 36),
        base_vel     = ep_num("L1_BASE_VEL", 96),
        accent_vel   = ep_num("L1_ACC_VEL", 118),
        apply_prob   = clamp01(ep_num("L1_APPLY_PROB", 0.9)),
        accent_prob  = clamp01(ep_num("L1_ACC_PROB", 0.2)),
      },
      {
        enabled      = ep_bool("L2_ENABLED", true),
        pitch        = ep_num("L2_PITCH", 38),
        base_vel     = ep_num("L2_BASE_VEL", 92),
        accent_vel   = ep_num("L2_ACC_VEL", 116),
        apply_prob   = clamp01(ep_num("L2_APPLY_PROB", 0.7)),
        accent_prob  = clamp01(ep_num("L2_ACC_PROB", 0.25)),
      },
      {
        enabled      = ep_bool("L3_ENABLED", true),
        pitch        = ep_num("L3_PITCH", 42),
        base_vel     = ep_num("L3_BASE_VEL", 88),
        accent_vel   = ep_num("L3_ACC_VEL", 112),
        apply_prob   = clamp01(ep_num("L3_APPLY_PROB", 0.5)),
        accent_prob  = clamp01(ep_num("L3_ACC_PROB", 0.3)),
      },
    },
  }
  return cfg
end

local function save_cfg_to_extstate(cfg)
  if not cfg then return end

  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_MARKOV, key, tostring(v)) end
  end
  local function setbool(key, v)
    ext.set_proj(NS_MARKOV, key, v and "1" or "0")
  end

  setbool("ENABLED", cfg.enabled)
  setnum("BARS",    cfg.bars)
  setnum("STEPS",   cfg.steps)
  setnum("START_HIT_PROB", cfg.start_hit_prob)
  setnum("P_HH",    cfg.p_hh)
  setnum("P_RH",    cfg.p_rh)
  setnum("SEED",    cfg.seed or 0)

  local lanes = cfg.lanes or {}
  local l1 = lanes[1] or {}
  local l2 = lanes[2] or {}
  local l3 = lanes[3] or {}

  setbool("L1_ENABLED",    l1.enabled)
  setnum("L1_PITCH",       l1.pitch)
  setnum("L1_BASE_VEL",    l1.base_vel)
  setnum("L1_ACC_VEL",     l1.accent_vel)
  setnum("L1_APPLY_PROB",  l1.apply_prob)
  setnum("L1_ACC_PROB",    l1.accent_prob)

  setbool("L2_ENABLED",    l2.enabled)
  setnum("L2_PITCH",       l2.pitch)
  setnum("L2_BASE_VEL",    l2.base_vel)
  setnum("L2_ACC_VEL",     l2.accent_vel)
  setnum("L2_APPLY_PROB",  l2.apply_prob)
  setnum("L2_ACC_PROB",    l2.accent_prob)

  setbool("L3_ENABLED",    l3.enabled)
  setnum("L3_PITCH",       l3.pitch)
  setnum("L3_BASE_VEL",    l3.base_vel)
  setnum("L3_ACC_VEL",     l3.accent_vel)
  setnum("L3_APPLY_PROB",  l3.apply_prob)
  setnum("L3_ACC_PROB",    l3.accent_prob)
end

------------------------------------------------------------
-- Markov-Pattern erstellen
------------------------------------------------------------

local function make_markov_pattern(total_steps, cfg)
  local p_hh = clamp01(cfg.p_hh or 0.8)
  local p_rh = clamp01(cfg.p_rh or 0.4)
  local start_hit_prob = clamp01(cfg.start_hit_prob or 0.5)

  local pattern = {}
  local prev = (math.random() < start_hit_prob) and 1 or 0

  for i=1,total_steps do
    local hit
    if prev == 1 then
      hit = (math.random() < p_hh) and 1 or 0
    else
      hit = (math.random() < p_rh) and 1 or 0
    end
    pattern[i] = hit
    prev = hit
  end

  return pattern
end

------------------------------------------------------------
-- Generate
------------------------------------------------------------

local function generate_internal(beat_state, cfg, target_track)
  cfg = cfg or load_cfg_from_extstate()
  if not cfg.enabled then
    msg("MarkovRhythm disabled (ENABLED=0) – kein Output.")
    return
  end

  local bars   = cfg.bars
  local ts_num = (beat_state and beat_state.ts_num) or 4
  local ts_den = (beat_state and beat_state.ts_den) or 4

  local track = target_track or get_target_track()
  local item, take, start_qn, _ = create_midi_item(track, bars, ts_num, ts_den)
  if not take then
    msg("Konnte kein MIDI-Take erzeugen.")
    return
  end

  -- RNG-Seed
  local seed = cfg.seed or 0
  if seed == 0 then
    seed = os.time() % 2147483647
  end
  math.randomseed(seed)

  local steps_per_bar = ensure_pos(cfg.steps or 16, 16)
  local total_steps   = steps_per_bar * bars

  local bar_qn   = qn_per_bar(ts_num, ts_den)
  local step_qn  = bar_qn / steps_per_bar

  local markov_pattern = make_markov_pattern(total_steps, cfg)

  for idx, hit in ipairs(markov_pattern) do
    if hit == 1 then
      local step_index = idx - 1
      local bar_idx    = math.floor(step_index / steps_per_bar)
      local step_in_bar= step_index % steps_per_bar

      local base_qn = start_qn + bar_idx * bar_qn + step_in_bar * step_qn
      local note_len_qn = step_qn * 0.8

      for lane_index, lane in ipairs(cfg.lanes or {}) do
        if lane.enabled and (math.random() < (lane.apply_prob or 1.0)) then
          local vel = lane.base_vel or 96
          if math.random() < (lane.accent_prob or 0.0) then
            vel = lane.accent_vel or (vel+12)
          end
          insert_note_qn(take, lane.pitch or (35+lane_index), vel, base_qn, base_qn + note_len_qn, 0)
        end
      end
    end
  end

  finalize_take(take)
  r.UpdateArrange()
  msg(string.format("MarkovRhythm Pattern erzeugt: %d Bars, %d Steps/Bar, seed=%d.", bars, steps_per_bar, seed))
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function M.load_cfg_from_extstate()
  return load_cfg_from_extstate()
end

function M.save_cfg_to_extstate(cfg)
  return save_cfg_to_extstate(cfg)
end

function M.generate(beat_state, cfg, target_track)
  generate_internal(beat_state, cfg, target_track)
end

function M.generate_from_extstate(beat_state, target_track)
  local cfg = load_cfg_from_extstate()
  generate_internal(beat_state, cfg, target_track)
end

return M
