-- IFLS_GrooveDomain.lua
-- GrooveDomain: Swing, Microtiming & Velocity-Groove

local r = reaper
local M = {}
local NS = "IFLS_GROOVE"

local function get_proj_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_proj_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function get_num(key, default)
  local v = tonumber(get_proj_ext(key, ""))
  if not v then return default end
  return v
end

local function get_bool(key, default)
  local v = get_proj_ext(key, default and "1" or "0")
  return v == "1"
end

local function get_str(key, default)
  local v = get_proj_ext(key, "")
  if v == "" then return default end
  return v
end

local function rand_between(a, b)
  return a + (b - a) * math.random()
end

local function get_grid_qn(swing_grid)
  if swing_grid == "1/8" then return 0.5 end
  return 0.25
end

function M.read_cfg()
  local cfg = {
    enabled        = get_bool("ENABLED", false),
    template       = get_str("TEMPLATE", "IDM_LOOSE"),
    swing_amount   = get_num("SWING_AMOUNT", 0.0),
    swing_grid     = get_str("SWING_GRID", "1/16"),
    humanize_t     = get_num("HUMANIZE_T", 0.0),
    humanize_v     = get_num("HUMANIZE_V", 0.0),
    accent_strength= get_num("ACCENT_STRENGTH", 0.0),
    accent_type    = get_str("ACCENT_TYPE", "OFFBEAT"),
  }
  return cfg
end

function M.write_cfg(cfg)
  if not cfg then return end
  set_proj_ext("ENABLED",        cfg.enabled and "1" or "0")
  set_proj_ext("TEMPLATE",       cfg.template or "IDM_LOOSE")
  set_proj_ext("SWING_AMOUNT",   cfg.swing_amount or 0.0)
  set_proj_ext("SWING_GRID",     cfg.swing_grid or "1/16")
  set_proj_ext("HUMANIZE_T",     cfg.humanize_t or 0.0)
  set_proj_ext("HUMANIZE_V",     cfg.humanize_v or 0.0)
  set_proj_ext("ACCENT_STRENGTH",cfg.accent_strength or 0.0)
  set_proj_ext("ACCENT_TYPE",    cfg.accent_type or "OFFBEAT")
end

function M.apply_to_take(take, cfg)
  if not take then return end
  cfg = cfg or M.read_cfg()
  if not cfg.enabled then return end

  local _, bpm = r.GetProjectTimeSignature2(0)
  local ms_per_qn = (60.0 / bpm) * 1000.0

  local swing_amount   = cfg.swing_amount or 0.0
  local swing_grid_qn  = get_grid_qn(cfg.swing_grid)
  local humanize_t     = cfg.humanize_t or 0.0
  local humanize_v     = cfg.humanize_v or 0.0
  local accent_strength= cfg.accent_strength or 0.0
  local accent_type    = cfg.accent_type or "OFFBEAT"

  local item = r.GetMediaItemTake_Item(take)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local qn_start = r.TimeMap2_timeToQN(0, item_pos)

  r.MIDI_DisableSort(take)
  local _, _, note_count, _, _ = r.MIDI_CountEvts(take)
  for i = 0, note_count-1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
    if ok then
      local pos_qn = r.MIDI_GetProjQNFromPPQPos(take, startppq)

      if swing_amount > 0.0 then
        local rel_qn = pos_qn - qn_start
        local grid_idx = math.floor(rel_qn / swing_grid_qn + 0.5)
        if grid_idx % 2 == 1 then
          local offset_qn = swing_grid_qn * swing_amount * 0.5
          pos_qn = pos_qn + offset_qn
        end
      end

      if humanize_t > 0.0 then
        local max_qn = humanize_t / ms_per_qn
        local jitter = rand_between(-max_qn, max_qn)
        pos_qn = pos_qn + jitter
      end

      local new_startppq = r.MIDI_GetPPQPosFromProjQN(take, pos_qn)
      local len_ppq = endppq - startppq
      local new_endppq = new_startppq + len_ppq

      if humanize_v > 0.0 then
        local max_delta = 127 * humanize_v
        local delta = rand_between(-max_delta, max_delta)
        vel = math.max(1, math.min(127, math.floor(vel + delta + 0.5)))
      end

      r.MIDI_SetNote(take, i, sel, mute, new_startppq, new_endppq, chan, pitch, vel, true)
    end
  end
  r.MIDI_Sort(take)
end

function M.apply_to_selected_items()
  local cfg = M.read_cfg()
  if not cfg.enabled then
    r.ShowMessageBox("IFLS_GrooveDomain: Groove ist nicht aktiviert.", "IFLS Groove", 0)
    return
  end
  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then
    r.ShowMessageBox("Keine Items selektiert.", "IFLS Groove", 0)
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
