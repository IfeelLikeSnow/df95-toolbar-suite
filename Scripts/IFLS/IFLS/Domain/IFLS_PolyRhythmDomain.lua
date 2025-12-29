-- IFLS_PolyRhythmDomain.lua
-- Polymetrische / polyrhythmische Engine für IFLS
-- Drei Lanes, jede mit eigenem Steps/Hits/Rotation und Divisor.
--
-- Integration:
--   * ExtState: Namespace "IFLS_POLYRHYTHM"
--   * SceneDomain kann diesen ExtState optional mit speichern
--   * PatternDomain kann Mode "EUCLIDPOLY" nutzen und diese Domain callen.

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

local NS_POLY = "IFLS_POLYRHYTHM"

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg("[IFLS_PolyRhythm] " .. tostring(s) .. "\n")
end

local function ensure_pos(v, d)
  v = tonumber(v) or d
  if v <= 0 then return d end
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
-- ExtState
------------------------------------------------------------

local function ep_num(key, def)
  local s = ext.get_proj(NS_POLY, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function ep_bool(key, def)
  local s = ext.get_proj(NS_POLY, key, def and "1" or "0")
  return s == "1"
end

local function load_cfg_from_extstate()
  local cfg = {
    enabled = ep_bool("ENABLED", false),
    bars    = ep_num("BARS", 4),
    lanes   = {
      {
        enabled  = ep_bool("L1_ENABLED", true),
        steps    = ep_num("L1_STEPS", 16),
        hits     = ep_num("L1_HITS", 5),
        rotation = ep_num("L1_ROT", 0),
        pitch    = ep_num("L1_PITCH", 36),
        div      = ep_num("L1_DIV", 1),
      },
      {
        enabled  = ep_bool("L2_ENABLED", true),
        steps    = ep_num("L2_STEPS", 10),
        hits     = ep_num("L2_HITS", 4),
        rotation = ep_num("L2_ROT", 0),
        pitch    = ep_num("L2_PITCH", 38),
        div      = ep_num("L2_DIV", 1),
      },
      {
        enabled  = ep_bool("L3_ENABLED", true),
        steps    = ep_num("L3_STEPS", 7),
        hits     = ep_num("L3_HITS", 3),
        rotation = ep_num("L3_ROT", 0),
        pitch    = ep_num("L3_PITCH", 42),
        div      = ep_num("L3_DIV", 1),
      },
    },
  }
  return cfg
end

local function save_cfg_to_extstate(cfg)
  if not cfg then return end

  local function setnum(key, v)
    if v ~= nil then ext.set_proj(NS_POLY, key, tostring(v)) end
  end
  local function setbool(key, v)
    ext.set_proj(NS_POLY, key, v and "1" or "0")
  end

  setbool("ENABLED", cfg.enabled)
  setnum("BARS",    cfg.bars)

  local lanes = cfg.lanes or {}
  local l1 = lanes[1] or {}
  local l2 = lanes[2] or {}
  local l3 = lanes[3] or {}

  setbool("L1_ENABLED", l1.enabled)
  setnum("L1_STEPS",    l1.steps)
  setnum("L1_HITS",     l1.hits)
  setnum("L1_ROT",      l1.rotation)
  setnum("L1_PITCH",    l1.pitch)
  setnum("L1_DIV",      l1.div)

  setbool("L2_ENABLED", l2.enabled)
  setnum("L2_STEPS",    l2.steps)
  setnum("L2_HITS",     l2.hits)
  setnum("L2_ROT",      l2.rotation)
  setnum("L2_PITCH",    l2.pitch)
  setnum("L2_DIV",      l2.div)

  setbool("L3_ENABLED", l3.enabled)
  setnum("L3_STEPS",    l3.steps)
  setnum("L3_HITS",     l3.hits)
  setnum("L3_ROT",      l3.rotation)
  setnum("L3_PITCH",    l3.pitch)
  setnum("L3_DIV",      l3.div)
end

------------------------------------------------------------
-- Euclid (per Lane)
------------------------------------------------------------

local function euclid_sequence(k, n, rotation)
  k = math.floor(k)
  n = math.floor(n)
  rotation = rotation or 0

  if k <= 0 then
    local s = {}
    for i=1,n do s[i] = 0 end
    return s
  end
  if k >= n then
    local s = {}
    for i=1,n do s[i] = 1 end
    return s
  end

  local pattern, counts, rema = {}, {}, {}
  local divisor = n - k
  rema[1] = k
  local level = 1
  while true do
    counts[level] = math.floor(divisor / rema[level])
    rema[level+1] = divisor % rema[level]
    divisor = rema[level]
    level = level + 1
    if rema[level] <= 1 then break end
  end
  counts[level] = divisor

  local function build(l)
    if l == -1 then
      pattern[#pattern+1] = 0
    elseif l == -2 then
      pattern[#pattern+1] = 1
    else
      for _=1,counts[l] do build(l-1) end
      if rema[l] ~= 0 then build(l-2) end
    end
  end

  build(level)
  local seq = {}
  local len = #pattern
  for i=1,len do
    local idx = ((i-1+rotation)%len)+1
    seq[i] = pattern[idx]
  end
  return seq
end

------------------------------------------------------------
-- Generate
------------------------------------------------------------

local function generate_internal(beat_state, cfg, target_track)
  cfg = cfg or load_cfg_from_extstate()
  if not cfg.enabled then
    msg("Polyrhythm disabled (ENABLED=0) – kein Output.")
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

  local bar_qn = qn_per_bar(ts_num, ts_den)

  for lane_index, lane in ipairs(cfg.lanes or {}) do
    if lane.enabled then
      local steps    = ensure_pos(lane.steps or 16, 16)
      local hits     = ensure_pos(lane.hits or 4, 4)
      local rotation = math.floor(lane.rotation or 0)
      local pitch    = lane.pitch or (35 + lane_index) -- minimal Variation
      local div      = lane.div or 1

      local seq = euclid_sequence(hits, steps, rotation)
      local step_qn = bar_qn / steps

      for bar=0,bars-1 do
        for s=1,steps do
          if seq[s] == 1 then
            local base_qn = start_qn + bar * bar_qn + (s-1) * step_qn
            -- div = Unterteilung innerhalb dieses Steps
            local local_step_qn = step_qn / div
            for d=0,div-1 do
              local s_qn = base_qn + d * local_step_qn
              local e_qn = s_qn + local_step_qn * 0.8
              local vel  = 80 + (lane_index-1)*8
              insert_note_qn(take, pitch, vel, s_qn, e_qn, 0)
            end
          end
        end
      end
    end
  end

  finalize_take(take)
  r.UpdateArrange()
  msg("Polyrhythm Pattern erzeugt.")
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
