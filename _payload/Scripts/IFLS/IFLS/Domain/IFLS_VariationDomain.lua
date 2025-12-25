-- IFLS_VariationDomain.lua
-- VariationDomain – Phrasen-Variationen & Ratchets

local r = reaper
local M = {}
local NS = "IFLS_VARIATION"

local function get_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function get_num(key, default)
  local v = tonumber(get_ext(key, ""))
  if not v then return default end
  return v
end

local function get_bool(key, default)
  local v = get_ext(key, default and "1" or "0")
  return v == "1"
end

local function get_str(key, default)
  local v = get_ext(key, "")
  if v == "" then return default end
  return v
end

local function rand_between(a, b)
  return a + (b - a) * math.random()
end

local function read_lane(prefix, def)
  local lane = {}
  lane.pitch_min  = get_num(prefix .. "_PITCH_MIN", def.pitch_min or 36)
  lane.pitch_max  = get_num(prefix .. "_PITCH_MAX", def.pitch_max or 36)
  lane.add_light  = get_num(prefix .. "_ADD_LIGHT", def.add_light or 0.0)
  lane.rem_light  = get_num(prefix .. "_REM_LIGHT", def.rem_light or 0.0)
  lane.add_fill   = get_num(prefix .. "_ADD_FILL",  def.add_fill or 0.0)
  lane.rem_fill   = get_num(prefix .. "_REM_FILL",  def.rem_fill or 0.0)
  lane.rat_light  = get_num(prefix .. "_RATCH_LIGHT", def.rat_light or 0.0)
  lane.rat_fill   = get_num(prefix .. "_RATCH_FILL",  def.rat_fill or 0.0)
  return lane
end

local function write_lane(prefix, lane)
  if not lane then return end
  set_ext(prefix .. "_PITCH_MIN", lane.pitch_min or 36)
  set_ext(prefix .. "_PITCH_MAX", lane.pitch_max or 36)
  set_ext(prefix .. "_ADD_LIGHT",  lane.add_light or 0.0)
  set_ext(prefix .. "_REM_LIGHT",  lane.rem_light or 0.0)
  set_ext(prefix .. "_ADD_FILL",   lane.add_fill or 0.0)
  set_ext(prefix .. "_REM_FILL",   lane.rem_fill or 0.0)
  set_ext(prefix .. "_RATCH_LIGHT",lane.rat_light or 0.0)
  set_ext(prefix .. "_RATCH_FILL", lane.rat_fill or 0.0)
end

function M.read_cfg()
  local cfg = {
    enabled         = get_bool("ENABLED", false),
    bars_per_pattern= get_num("BARS_PER_PATTERN", 4),
    cycle_light     = get_num("CYCLE_LIGHT", 2),
    cycle_fill      = get_num("CYCLE_FILL", 4),
    ratchet_mode    = get_str("RATCHET_MODE", "FILLS_ONLY"),
    ratchet_density = get_num("RATCHET_DENSITY", 1.0),
    kick_lane       = read_lane("KICK",  {pitch_min=36,pitch_max=36,add_light=0.0,rem_light=0.0,add_fill=0.1,rem_fill=0.0,rat_light=0.0,rat_fill=0.1}),
    snare_lane      = read_lane("SNARE",{pitch_min=38,pitch_max=40,add_light=0.05,rem_light=0.05,add_fill=0.2,rem_fill=0.05,rat_light=0.05,rat_fill=0.3}),
    hat_lane        = read_lane("HAT",  {pitch_min=42,pitch_max=46,add_light=0.0,rem_light=0.1,add_fill=0.05,rem_fill=0.2,rat_light=0.05,rat_fill=0.25}),
  }
  return cfg
end

function M.write_cfg(cfg)
  if not cfg then return end
  set_ext("ENABLED",           cfg.enabled and "1" or "0")
  set_ext("BARS_PER_PATTERN",  cfg.bars_per_pattern or 4)
  set_ext("CYCLE_LIGHT",       cfg.cycle_light or 2)
  set_ext("CYCLE_FILL",        cfg.cycle_fill or 4)
  set_ext("RATCHET_MODE",      cfg.ratchet_mode or "FILLS_ONLY")
  set_ext("RATCHET_DENSITY",   cfg.ratchet_density or 1.0)
  write_lane("KICK",  cfg.kick_lane)
  write_lane("SNARE", cfg.snare_lane)
  write_lane("HAT",   cfg.hat_lane)
end

local function pitch_in_lane(pitch, lane)
  return pitch >= lane.pitch_min and pitch <= lane.pitch_max
end

local function apply_ratchet(take, note_idx, startppq, endppq, chan, pitch, vel, strength)
  local steps = 2
  if strength > 0.7 then steps = 4
  elseif strength > 0.3 then steps = 3 end

  local length = endppq - startppq
  local sub_len = length / steps
  local base_vel = vel

  r.MIDI_DeleteNote(take, note_idx)
  for i = 0, steps-1 do
    local st = startppq + sub_len * i
    local ed = st + sub_len * 0.8
    local v  = math.max(1, math.min(127, math.floor(base_vel * (1.0 - 0.2*i))))
    r.MIDI_InsertNote(take, true, false, st, ed, chan, pitch, v, false)
  end
end

function M.apply_to_take(take, cfg)
  if not take then return end
  cfg = cfg or M.read_cfg()
  if not cfg.enabled then return end

  local item = r.GetMediaItemTake_Item(take)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local _, bpm, ts_num, ts_den = r.GetProjectTimeSignature2(0)
  local qn_start = r.TimeMap2_timeToQN(0, item_pos)
  local qn_per_bar = ts_num * 1.0

  local _, _, note_count, _, _ = r.MIDI_CountEvts(take)
  if note_count == 0 then return end

  r.MIDI_DisableSort(take)

  for idx = note_count-1, 0, -1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, idx)
    if ok then
      local pos_qn = r.MIDI_GetProjQNFromPPQPos(take, startppq)
      local rel_qn = pos_qn - qn_start
      if rel_qn < 0 then rel_qn = 0 end
      local bar_index = math.floor(rel_qn / qn_per_bar)
      local bar_num = bar_index + 1

      local is_light = (cfg.cycle_light > 0) and (bar_num % cfg.cycle_light == 0)
      local is_fill  = (cfg.cycle_fill  > 0) and (bar_num % cfg.cycle_fill  == 0)

      local lane = nil
      if pitch_in_lane(pitch, cfg.kick_lane) then lane = cfg.kick_lane
      elseif pitch_in_lane(pitch, cfg.snare_lane) then lane = cfg.snare_lane
      elseif pitch_in_lane(pitch, cfg.hat_lane) then lane = cfg.hat_lane end

      if lane then
        local add_prob, rem_prob, ratch_prob = 0, 0, 0
        if is_fill then
          add_prob, rem_prob, ratch_prob = lane.add_fill, lane.rem_fill, lane.rat_fill
        elseif is_light then
          add_prob, rem_prob, ratch_prob = lane.add_light, lane.rem_light, lane.rat_light
        end

        if rem_prob > 0 and math.random() < rem_prob then
          r.MIDI_DeleteNote(take, idx)
          goto continue
        end

        local do_ratchet = false
        if cfg.ratchet_mode ~= "OFF" then
          if cfg.ratchet_mode == "ALWAYS" then
            if ratch_prob > 0 and math.random() < (ratch_prob * cfg.ratchet_density) then
              do_ratchet = true
            end
          elseif cfg.ratchet_mode == "FILLS_ONLY" then
            if is_fill and ratch_prob > 0 and math.random() < (ratch_prob * cfg.ratchet_density) then
              do_ratchet = true
            end
          end
        end

        if do_ratchet then
          apply_ratchet(take, idx, startppq, endppq, chan, pitch, vel, cfg.ratchet_density)
          goto continue
        end
      end
    end
    ::continue::
  end

  r.MIDI_Sort(take)
end

function M.apply_to_selected_items()
  local cfg = M.read_cfg()
  if not cfg.enabled then
    r.ShowMessageBox("IFLS_VariationDomain: Variation ist nicht aktiviert.", "IFLS Variation", 0)
    return
  end
  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then
    r.ShowMessageBox("Keine Items selektiert.", "IFLS Variation", 0)
    return
  end
  for i = 0, cnt-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(item)
    if take and r.TakeIsMIDI(take) then
      M.apply_to_take(take, cfg)
    end
  end
end

return M
