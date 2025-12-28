-- IFLS_EuclidProDomain.lua
-- Advanced Euclidean / Probabilistic Rhythm Engine for IFLS
-- mit Ratchets (IDM / Glitch Rolls)

local r = reaper
local M = {}

------------------------------------------------------------
-- ExtState / Paths
------------------------------------------------------------

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
  }
end

local NS_EUCLIDPRO = "IFLS_EUCLIDPRO"

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg("[IFLS_EuclidPro] " .. tostring(s) .. "\n")
end

local function ensure_positive(v, d)
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
  bars  = ensure_positive(bars, 4)

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
-- ExtState → Config
------------------------------------------------------------

local function ep_num(key, def)
  local s = ext.get_proj(NS_EUCLIDPRO, key, tostring(def))
  local v = tonumber(s)
  if not v then return def end
  return v
end

local function load_cfg_from_extstate()
  local cfg = {
    steps        = ep_num("STEPS", 16),
    hits         = ep_num("HITS", 5),
    rotation     = ep_num("ROTATION", 0),
    accent_mode  = ext.get_proj(NS_EUCLIDPRO, "ACCENT_MODE", "none"),
    hit_prob     = ep_num("HIT_PROB", 1.0),
    ghost_prob   = ep_num("GHOST_PROB", 0.0),
    ratchet_prob = ep_num("RATCHET_PROB", 0.0),
    ratchet_min  = ep_num("RATCHET_MIN", 2),
    ratchet_max  = ep_num("RATCHET_MAX", 4),
    ratchet_shape= ext.get_proj(NS_EUCLIDPRO, "RATCHET_SHAPE", "up"),
  }

  cfg.lanes = {
    {
      pitch      = ep_num("L1_PITCH", 36),
      div        = ep_num("L1_DIV", 1),
      base_vel   = ep_num("L1_BASE_VEL", 96),
      accent_vel = ep_num("L1_ACCENT_VEL", 118),
    },
    {
      pitch      = ep_num("L2_PITCH", 38),
      div        = ep_num("L2_DIV", 1),
      base_vel   = ep_num("L2_BASE_VEL", 90),
      accent_vel = ep_num("L2_ACCENT_VEL", 112),
    },
    {
      pitch      = ep_num("L3_PITCH", 42),
      div        = ep_num("L3_DIV", 1),
      base_vel   = ep_num("L3_BASE_VEL", 84),
      accent_vel = ep_num("L3_ACCENT_VEL", 108),
    },
  }

  return cfg
end

------------------------------------------------------------
-- Euclid (Bjorklund)
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
-- Accent / Probability / Ghosts
------------------------------------------------------------

local function apply_accent(seq, accent_mode, base_vel, accent_vel)
  accent_mode = accent_mode or "none"
  base_vel    = base_vel or 88
  accent_vel  = accent_vel or 112

  local out = {}
  local n = #seq

  if accent_mode == "none" then
    for i=1,n do
      out[i] = seq[i] == 1 and base_vel or 0
    end
    return out
  end

  if accent_mode == "alternate" then
    local toggle = false
    for i=1,n do
      if seq[i] == 1 then
        toggle = not toggle
        out[i] = toggle and accent_vel or base_vel
      else
        out[i] = 0
      end
    end
    return out
  end

  if accent_mode == "downbeat" then
    for i=1,n do
      if seq[i] == 1 then
        out[i] = (i == 1) and accent_vel or base_vel
      else
        out[i] = 0
      end
    end
    return out
  end

  if accent_mode == "cluster" then
    local last_hit = 0
    for i=1,n do
      if seq[i] == 1 then
        if i == last_hit+1 then
          out[i] = accent_vel
        else
          out[i] = base_vel
        end
        last_hit = i
      else
        out[i] = 0
      end
    end
    return out
  end

  for i=1,n do
    out[i] = seq[i] == 1 and base_vel or 0
  end
  return out
end

local function apply_probability_and_ghost(seq, vel_seq, hit_prob, ghost_prob)
  hit_prob   = hit_prob or 1.0
  ghost_prob = ghost_prob or 0.0

  local n = #seq
  local out_hits = {}
  local out_vels = {}

  math.randomseed(os.time() % 2147483647)
  local function randf() return math.random() end

  for i=1,n do
    if seq[i] == 1 then
      if randf() <= hit_prob then
        out_hits[i] = 1
        out_vels[i] = vel_seq[i] or 96
      else
        out_hits[i] = 0
        out_vels[i] = 0
      end
      if ghost_prob > 0.0 then
        if i < n and out_hits[i] == 1 and randf() <= ghost_prob then
          out_hits[i+1] = out_hits[i+1] or 1
          out_vels[i+1] = math.floor((vel_seq[i] or 96) * 0.5)
        end
      end
    else
      out_hits[i] = out_hits[i] or 0
      out_vels[i] = out_vels[i] or 0
    end
  end

  return out_hits, out_vels
end

------------------------------------------------------------
-- Ratchet Utils
------------------------------------------------------------

local function shape_ratchet_velocity(base, accent, idx, n, shape)
  base   = base or 80
  accent = accent or 110
  shape  = shape or "up"

  if n <= 1 then return accent end
  local t = (idx-1) / (n-1)

  if shape == "up" then
    return math.floor(base + (accent-base)*t)
  elseif shape == "down" then
    return math.floor(accent + (base-accent)*t)
  elseif shape == "pingpong" then
    if t <= 0.5 then
      local tt = t / 0.5
      return math.floor(base + (accent-base)*tt)
    else
      local tt = (t-0.5)/0.5
      return math.floor(accent + (base-accent)*tt)
    end
  elseif shape == "random" then
    return math.random(math.min(base, accent), math.max(base, accent))
  end

  return accent
end

local function gen_lane_events(steps, hits, rotation, accent_mode, base_vel, accent_vel, hit_prob, ghost_prob)
  local seq = euclid_sequence(hits, steps, rotation)
  local vel_seq = apply_accent(seq, accent_mode, base_vel, accent_vel)
  local hits_out, vel_out = apply_probability_and_ghost(seq, vel_seq, hit_prob, ghost_prob)
  return hits_out, vel_out
end

------------------------------------------------------------
-- Core Generator
------------------------------------------------------------

local function generate_internal(beat_state, cfg, target_track)
  cfg = cfg or {}
  local steps    = ensure_positive(cfg.steps or 16, 16)
  local hits     = ensure_positive(cfg.hits or 5, 5)
  local rotation = math.floor(cfg.rotation or 0)
  local accent_mode = cfg.accent_mode or "none"
  local hit_prob    = cfg.hit_prob or 1.0
  local ghost_prob  = cfg.ghost_prob or 0.0

  local ratchet_prob  = cfg.ratchet_prob or 0.0
  local ratchet_min   = math.max(1, math.floor(cfg.ratchet_min or 2))
  local ratchet_max   = math.max(ratchet_min, math.floor(cfg.ratchet_max or ratchet_min))
  local ratchet_shape = cfg.ratchet_shape or "up"

  local bars   = (beat_state and beat_state.bars)   or 4
  local ts_num = (beat_state and beat_state.ts_num) or 4
  local ts_den = (beat_state and beat_state.ts_den) or 4

  local track = target_track or get_target_track()
  local item, take, start_qn, _ = create_midi_item(track, bars, ts_num, ts_den)
  if not take then
    msg("Konnte kein MIDI-Take erzeugen.")
    return
  end

  local bar_qn   = qn_per_bar(ts_num, ts_den)
  local step_qn  = bar_qn / steps
  local lanes    = cfg.lanes or {
    { pitch=36, div=1, base_vel=96, accent_vel=118 },
    { pitch=38, div=1, base_vel=90, accent_vel=112 },
    { pitch=42, div=1, base_vel=84, accent_vel=108 },
  }

  math.randomseed(os.time() % 2147483647)
  local function randf() return math.random() end
  local function rand_int(a,b) return a + math.random(0, b-a) end

  for _, lane in ipairs(lanes) do
    local pitch      = lane.pitch or 36
    local div        = lane.div or 1
    local base_vel   = lane.base_vel or 96
    local accent_vel = lane.accent_vel or 118

    local hits_seq, vel_seq = gen_lane_events(
      steps, hits, rotation,
      accent_mode, base_vel, accent_vel,
      hit_prob, ghost_prob
    )

    for bar=0,bars-1 do
      for step=1,steps do
        local hit = hits_seq[step]
        local vel = vel_seq[step] or 0
        if hit == 1 and vel > 0 then
          local s_base = start_qn + bar * bar_qn + (step-1) * step_qn / div
          local e_base = s_base + step_qn * 0.8 / div

          -- Entscheiden, ob Ratchet
          local do_ratchet = (ratchet_prob > 0.0) and (randf() <= ratchet_prob)
          if not do_ratchet then
            insert_note_qn(take, pitch, vel, s_base, e_base, 0)
          else
            local n_rat = rand_int(ratchet_min, ratchet_max)
            local span  = (e_base - s_base)
            local seg   = span / n_rat
            for ri=1,n_rat do
              local seg_s = s_base + (ri-1)*seg
              local seg_e = seg_s + seg*0.7
              local rvel  = shape_ratchet_velocity(base_vel, accent_vel, ri, n_rat, ratchet_shape)
              insert_note_qn(take, pitch, rvel, seg_s, seg_e, 0)
            end
          end
        end
      end
    end
  end

  finalize_take(take)
  r.UpdateArrange()
  msg(string.format("EuclidPro: %d hits / %d steps, bars=%d, accent=%s, hitp=%.2f, ghost=%.2f, ratchet=%.2f",
      hits, steps, bars, accent_mode, hit_prob, ghost_prob, ratchet_prob))
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function M.load_cfg_from_extstate()
  return load_cfg_from_extstate()
end

function M.generate(beat_state, cfg, target_track)
  generate_internal(beat_state, cfg, target_track)
end

function M.generate_from_extstate(beat_state, target_track)
  local cfg = load_cfg_from_extstate()
  generate_internal(beat_state, cfg, target_track)
end

return M
