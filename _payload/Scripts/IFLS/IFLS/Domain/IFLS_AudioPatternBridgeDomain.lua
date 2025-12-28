-- IFLS_AudioPatternBridgeDomain.lua
-- Phase 31: Audio → Pattern Bridge
--
-- Ziele:
--   * Aus selektierten Audio-Items (z.B. Slices) ein MIDI-Pattern erzeugen.
--   * Grid-basiert (Step-Länge in QN), passend zu Projekt-Taktart.
--   * Als einfache "Seed"-Ebene für weitere Pattern/Variation.
--
-- Aktuell:
--   * Erstellt ein neues MIDI-Item auf der aktuellen Spur (oder erster Spur),
--     in dem jede Slice-Position als Note (steigende MIDI-Noten) repräsentiert wird.

local r = reaper
local M = {}

local NS = "IFLS_AUDIOPATTERN"

local function get_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function get_str(key, default)
  local v = get_ext(key, "")
  if v == "" then return default end
  return v
end

local function get_num(key, default)
  local v = tonumber(get_ext(key, ""))
  if not v then return default end
  return v
end

----------------------------------------------------------------
-- Config
----------------------------------------------------------------

function M.read_cfg()
  local cfg = {
    step_div     = get_str("STEP_DIV", "1/16"),   -- 1/8, 1/16, 1/32
    base_note    = get_num("BASE_NOTE", 36),      -- C1
    note_span    = get_num("NOTE_SPAN", 16),      -- wie viele Noten wir verwenden
    note_len_mul = get_num("NOTE_LEN_MUL", 0.5),  -- relative Länge zu Step (0..1)
  }
  return cfg
end

function M.write_cfg(cfg)
  if not cfg then return end
  set_ext("STEP_DIV",     cfg.step_div or "1/16")
  set_ext("BASE_NOTE",    cfg.base_note or 36)
  set_ext("NOTE_SPAN",    cfg.note_span or 16)
  set_ext("NOTE_LEN_MUL", cfg.note_len_mul or 0.5)
end

local function parse_step_div(step_div)
  if step_div == "1/4" then return 1.0
  elseif step_div == "1/8" then return 0.5
  elseif step_div == "1/16" then return 0.25
  elseif step_div == "1/32" then return 0.125
  end
  return 0.25
end

local function get_target_track()
  local tr = r.GetSelectedTrack(0,0)
  if tr then return tr end
  tr = r.GetTrack(0,0)
  if tr then return tr end
  r.InsertTrackAtIndex(0, true)
  return r.GetTrack(0,0)
end

local function analyze_slices(cfg)
  local sel_cnt = r.CountSelectedMediaItems(0)
  if sel_cnt == 0 then
    return nil, "Keine Items selektiert."
  end

  local items = {}
  local min_pos = nil
  local max_pos = nil

  for i = 0, sel_cnt-1 do
    local item = r.GetSelectedMediaItem(0, i)
    if item then
      local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      local _, name = r.GetSetMediaItemInfo_String(item, "P_NAME", "", false)
      items[#items+1] = { item=item, pos=pos, len=len, name=name or "" }
      if not min_pos or pos < min_pos then min_pos = pos end
      local endpos = pos + len
      if not max_pos or endpos > max_pos then max_pos = endpos end
    end
  end

  if not min_pos or not max_pos then
    return nil, "Konnte Positionsinfos nicht auslesen."
  end

  local ok_ts, ts_num, ts_den = r.TimeMap_GetTimeSigAtTime(0, min_pos)
  if not ok_ts then ts_num, ts_den = 4,4 end

  local step_qn = parse_step_div(cfg.step_div or "1/16")
  local qn_start = r.TimeMap2_timeToQN(0, min_pos)
  local qn_end   = r.TimeMap2_timeToQN(0, max_pos)
  local total_qn = qn_end - qn_start
  if total_qn <= 0 then total_qn = step_qn * 4 end

  local steps = math.ceil(total_qn / step_qn)

  local events = {}
  for idx, info in ipairs(items) do
    local item_qn = r.TimeMap2_timeToQN(0, info.pos)
    local rel_qn  = item_qn - qn_start
    local step_idx = math.floor(rel_qn / step_qn) + 1
    if step_idx < 1 then step_idx = 1 end
    if step_idx > steps then step_idx = steps end

    local pitch = cfg.base_note + ((idx-1) % cfg.note_span)
    table.insert(events, {
      step = step_idx,
      pitch = pitch,
      name = info.name,
    })
  end

  return {
    min_pos = min_pos,
    max_pos = max_pos,
    qn_start = qn_start,
    qn_end   = qn_end,
    step_qn  = step_qn,
    steps    = steps,
    ts_num   = ts_num,
    ts_den   = ts_den,
    events   = events,
  }
end

local function create_midi_from_analysis(analysis, cfg)
  local tr = get_target_track()
  local start_time = analysis.min_pos
  local end_time   = analysis.max_pos
  local item = r.CreateNewMIDIItemInProj(tr, start_time, end_time, false)
  local take = r.GetTake(item, 0)
  if not take then return end

  local note_len_qn = analysis.step_qn * (cfg.note_len_mul or 0.5)
  if note_len_qn <= 0 then note_len_qn = analysis.step_qn * 0.5 end

  for _, ev in ipairs(analysis.events) do
    local start_qn = analysis.qn_start + (ev.step-1)*analysis.step_qn
    local end_qn   = start_qn + note_len_qn
    local ppq_start = r.MIDI_GetPPQPosFromProjQN(take, start_qn)
    local ppq_end   = r.MIDI_GetPPQPosFromProjQN(take, end_qn)
    local vel = 96
    r.MIDI_InsertNote(take, false, false, ppq_start, ppq_end, 0, ev.pitch, vel, false)
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
end

function M.create_pattern_from_selected_items()
  local cfg = M.read_cfg()
  local analysis, err = analyze_slices(cfg)
  if not analysis then
    r.ShowMessageBox(err or "Analyse fehlgeschlagen.", "IFLS AudioPatternBridge", 0)
    return
  end

  r.Undo_BeginBlock2(0)
  create_midi_from_analysis(analysis, cfg)
  r.Undo_EndBlock2(0, "IFLS: Audio → Pattern (Bridge)", -1)
end

return M
