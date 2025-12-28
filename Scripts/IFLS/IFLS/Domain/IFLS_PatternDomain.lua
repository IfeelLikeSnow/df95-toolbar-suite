-- IFLS_PatternDomain.lua
-- Phase 8+9: Pattern Domain (IDM / Euclid / Microbeat / Granular) mit Parametern
-- -------------------------------------------------------------------------------
-- Erzeugt MIDI-Pattern auf Basis von Beat-/Artist-State und Pattern-Config (cfg).

local r = reaper
local M = {}

local function msg(s) r.ShowConsoleMsg(tostring(s) .. "\n") end

local function get_target_track()
  local tr = r.GetSelectedTrack(0,0)
  if tr then return tr end
  tr = r.GetTrack(0,0)
  if tr then return tr end
  r.InsertTrackAtIndex(0, true)
  return r.GetTrack(0,0)
end

local function get_project_timesig_and_bpm()
  local _, bpm = r.GetProjectTimeSignature2(0)
  local ok, num, den = r.TimeMap_GetTimeSigAtTime(0,0)
  if not ok then num, den = 4,4 end
  return bpm, num, den
end

local function qn_per_bar(ts_num, ts_den)
  ts_num = ts_num or 4
  ts_den = ts_den or 4
  return ts_num * (4.0/ts_den)
end

local function ensure_positive(v,d)
  v = tonumber(v) or d
  if v <= 0 then return d end
  return v
end

local function create_midi_item(track, bars, ts_num, ts_den)
  track = track or get_target_track()
  bars  = ensure_positive(bars,4)
  ts_num = ts_num or 4
  ts_den = ts_den or 4

  local qn_len = qn_per_bar(ts_num, ts_den)*bars
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

-- Euklid
local function euclid_sequence(k,n,rotation)
  k = math.floor(k); n = math.floor(n); rotation = rotation or 0
  if k <= 0 then
    local s = {}; for i=1,n do s[i]=0 end; return s
  end
  if k >= n then
    local s = {}; for i=1,n do s[i]=1 end; return s
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
      for i=1,counts[l] do build(l-1) end
      if rema[l] ~= 0 then build(l-2) end
    end
  end
  build(level)
  local seq = {}; local len = #pattern
  for i=1,len do
    local idx = ((i-1+rotation)%len)+1
    seq[i] = pattern[idx]
  end
  return seq
end

local function generate_euclid_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  cfg = cfg or {}
  local bar_qn = qn_per_bar(ts_num, ts_den)
  local total_steps = 16
  local step_qn = bar_qn/total_steps

  local k   = cfg.euclid_k or 3
  local n   = cfg.euclid_n or 8
  local rot = cfg.euclid_rotation or 0
  local base_seq = euclid_sequence(k,n,rot)

  local lanes = {
    { pitch=36, div=2 },
    { pitch=38, div=4 },
    { pitch=42, div=1 },
  }

  for _, lane in ipairs(lanes) do
    for bar=0,bars-1 do
      for step=1,total_steps do
        local idx = ((step-1)%n)+1
        if base_seq[idx] == 1 then
          local s_qn = start_qn + bar*bar_qn + (step-1)*step_qn/lane.div
          local e_qn = s_qn + step_qn*0.9/lane.div
          insert_note_qn(take, lane.pitch, 96, s_qn, e_qn, 0)
        end
      end
    end
  end
end

-- IDM
local function generate_idm_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  cfg = cfg or {}
  local chaos = cfg.chaos or 0.7
  local bar_qn = qn_per_bar(ts_num, ts_den)
  local steps_per_bar = 16
  local step_qn = bar_qn/steps_per_bar
  local function randf() return math.random() end

  for bar=0,bars-1 do
    for step=0,steps_per_bar-1 do
      local base_qn = start_qn + bar*bar_qn + step*step_qn
      if randf() < 0.5 then
        local pitch = (randf() < 0.5) and 36 or 38
        local len = step_qn*(0.6+randf()*0.3)
        insert_note_qn(take, pitch, 100, base_qn, base_qn+len, 0)
      end
      if randf() < chaos then
        local sub_count = 1+math.floor(randf()*3)
        for i=1,sub_count do
          local off = (step_qn*randf())*0.9
          local glen= step_qn*(0.15+randf()*0.2)
          local pitch = 42+math.floor(randf()*4)*2
          insert_note_qn(take, pitch, 60+math.floor(randf()*40),
                         base_qn+off, base_qn+off+glen, 0)
        end
      end
    end
  end
end

-- Microbeat
local function generate_microbeat_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  cfg = cfg or {}
  local density = cfg.density or 0.4
  local bar_qn = qn_per_bar(ts_num, ts_den)
  local steps_per_bar = 32
  local step_qn = bar_qn/steps_per_bar
  local function randf() return math.random() end

  for bar=0,bars-1 do
    for step=0,steps_per_bar-1 do
      if randf() < density then
        local base_qn = start_qn + bar*bar_qn + step*step_qn
        local len = step_qn*(0.3+randf()*0.3)
        local pitch = 36 + (step%5)
        local vel = 40+math.floor(randf()*60)
        insert_note_qn(take, pitch, vel, base_qn, base_qn+len, 0)
      end
    end
  end
end

-- Granular
local function generate_granular_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  cfg = cfg or {}
  local cluster_prob = cfg.cluster_prob or 0.35
  local bar_qn = qn_per_bar(ts_num, ts_den)
  local steps_per_bar = 8
  local step_qn = bar_qn/steps_per_bar
  local function randf() return math.random() end

  for bar=0,bars-1 do
    for step=0,steps_per_bar-1 do
      local base_qn = start_qn + bar*bar_qn + step*step_qn
      if randf() < cluster_prob then
        local grains = 3+math.floor(randf()*6)
        for i=1,grains do
          local off = step_qn*randf()
          local glen= step_qn*(0.1+randf()*0.2)
          local pitch = 36+math.floor(randf()*24)
          local vel = 30+math.floor(randf()*70)
          insert_note_qn(take, pitch, vel, base_qn+off, base_qn+off+glen, 0)
        end
      end
    end
  end
end

-- Mode-Erkennung
local function normalize_mode(str)
  if not str or str == "" then return nil end
  local s = string.lower(str)

  -- Priorität: explizite EuclidPro-Hinweise
  if s:find("euclidpro") or s:find("euclid_pro") or s:find("euclid pro") then
    return "EUCLIDPRO"
  end

  -- Polymetrische / polyrhythmische Hinweise
  if s:find("polyr") or s:find("poly-r") or s:find("polymetric") or s:find("poly\s*euclid") then
    return "EUCLIDPOLY"
  end

  -- Glitch-/IDM-Kombination gezielt auf EuclidPro mappen
  if (s:find("idm") and s:find("glitch")) or s:find("glitch_euclid") then
    return "EUCLIDPRO"
  end

  if s:find("idm") then return "IDM" end
  if s:find("euclid") or s:find("euklid") then return "EUCLID" end
  if s:find("micro") then return "MICROBEAT" end
  if s:find("grain") or s:find("granular") then return "GRANULAR" end
  if s:find("markov") or s:find("prob") or s:find("stoch") then return "MARKOV" end
  return nil
end

local function choose_mode(artist_state, beat_state, explicit_mode)
  if explicit_mode and explicit_mode ~= "" then
    return string.upper(explicit_mode)
  end
  local mode
  if artist_state then
    mode = normalize_mode(artist_state.pattern_mode)
    if not mode then mode = normalize_mode(artist_state.style_preset) end
  end
  if (not mode) and beat_state and beat_state.mode and beat_state.mode ~= "" then
    mode = normalize_mode(beat_state.mode)
  end
  if not mode then mode = "IDM" end
  return mode
end

function M.generate(artist_state, beat_state, explicit_mode, cfg)
  math.randomseed(os.time() % 2147483647)

  local track = get_target_track()
  local bpm_proj, ts_num_proj, ts_den_proj = get_project_timesig_and_bpm()

  local bars   = (beat_state and beat_state.bars)   or 4
  local ts_num = (beat_state and beat_state.ts_num) or ts_num_proj
  local ts_den = (beat_state and beat_state.ts_den) or ts_den_proj

  local mode = choose_mode(artist_state, beat_state, explicit_mode)

  -- MARKOV: delegiere an IFLS_MarkovRhythmDomain (falls vorhanden)
  if mode == "MARKOV" then
    local mk_ok, mk = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_MarkovRhythmDomain.lua")
    if mk_ok and type(mk) == "table" and mk.generate_from_extstate then
      local bs = {
        bpm   = bpm_proj,
        ts_num= ts_num,
        ts_den= ts_den,
        bars  = bars,
      }
      if beat_state then
        bs.bpm   = beat_state.bpm   or bs.bpm
        bs.ts_num= beat_state.ts_num or bs.ts_num
        bs.ts_den= beat_state.ts_den or bs.ts_den
        bs.bars  = beat_state.bars  or bs.bars
      end
      mk.generate_from_extstate(bs, track)
      r.UpdateArrange()
      msg(string.format("IFLS_PatternDomain: MarkovRhythm-Pattern erzeugt (%d Bars, %d/%d).", bs.bars or bars, bs.ts_num or ts_num, bs.ts_den or ts_den))
      return
    else
      msg("IFLS_PatternDomain: Mode 'MARKOV', aber IFLS_MarkovRhythmDomain.lua fehlt oder ist ungültig. Fallback auf 'EUCLID'.")
      mode = "EUCLID"
    end
  end

  -- EUCLIDPOLY: delegiere an IFLS_PolyRhythmDomain (falls vorhanden)
  if mode == "EUCLIDPOLY" then
    local pr_ok, pr = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_PolyRhythmDomain.lua")
    if pr_ok and type(pr) == "table" and pr.generate_from_extstate then
      local bs = {
        bpm   = bpm_proj,
        ts_num= ts_num,
        ts_den= ts_den,
        bars  = bars,
      }
      if beat_state then
        bs.bpm   = beat_state.bpm   or bs.bpm
        bs.ts_num= beat_state.ts_num or bs.ts_num
        bs.ts_den= beat_state.ts_den or bs.ts_den
        bs.bars  = beat_state.bars  or bs.bars
      end
      pr.generate_from_extstate(bs, track)
      r.UpdateArrange()
      msg(string.format("IFLS_PatternDomain: PolyRhythm-Pattern erzeugt (%d Bars, %d/%d).", bs.bars or bars, bs.ts_num or ts_num, bs.ts_den or ts_den))
      return
    else
      msg("IFLS_PatternDomain: Mode 'EUCLIDPOLY', aber IFLS_PolyRhythmDomain.lua fehlt oder ist ungültig. Fallback auf 'EUCLID'.")
      mode = "EUCLID"
    end
  end

  -- EUCLIDPRO: delegiere an IFLS_EuclidProDomain (falls vorhanden)
  if mode == "EUCLIDPRO" then
    local ep_ok, ep = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_EuclidProDomain.lua")
    if ep_ok and type(ep) == "table" and ep.generate_from_extstate then
      local bs = {
        bpm   = bpm_proj,
        ts_num= ts_num,
        ts_den= ts_den,
        bars  = bars,
      }
      if beat_state then
        bs.bpm   = beat_state.bpm   or bs.bpm
        bs.ts_num= beat_state.ts_num or bs.ts_num
        bs.ts_den= beat_state.ts_den or bs.ts_den
        bs.bars  = beat_state.bars  or bs.bars
      end
      ep.generate_from_extstate(bs, track)
      r.UpdateArrange()
      msg(string.format("IFLS_PatternDomain: EuclidPro-Pattern erzeugt (%d Bars, %d/%d).", bs.bars or bars, bs.ts_num or ts_num, bs.ts_den or ts_den))
      return
    else
      msg("IFLS_PatternDomain: Mode 'EUCLIDPRO', aber IFLS_EuclidProDomain.lua fehlt oder ist ungültig. Fallback auf 'EUCLID'.")
      mode = "EUCLID"
    end
  end

  local item, take, start_qn, end_qn = create_midi_item(track, bars, ts_num, ts_den)
  if not take then
    msg("IFLS_PatternDomain: Konnte kein MIDI-Take erzeugen.")
    return
  end

  cfg = cfg or {}

  if mode == "EUCLID" then
    generate_euclid_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  elseif mode == "MICROBEAT" then
    generate_microbeat_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  elseif mode == "GRANULAR" then
    generate_granular_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  else
    generate_idm_pattern(take, start_qn, bars, ts_num, ts_den, cfg)
  end

  finalize_take(take)
  r.UpdateArrange()
  msg(string.format("IFLS_PatternDomain: Pattern '%s' erzeugt (%d Bars, %d/%d).", mode, bars, ts_num, ts_den))
end

return M
