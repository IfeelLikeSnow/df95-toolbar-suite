-- @description Humanize Apply (Items + MIDI, Artist-Profile aware)
-- @version 2.0
-- @author DF95

local r = reaper
math.randomseed(os.time())

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function db2amp(db)
  return 10 ^ (db / 20)
end

local function read_json(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local d = f:read("*all")
  f:close()
  if r.JSONDecode then
    local ok, obj = pcall(function() return r.JSONDecode(d) end)
    if ok then return obj end
  end
  return nil
end

local function DF95_LoadProfileFromExtState(ns, default_tbl)
  if not r.JSONDecode then
    return default_tbl
  end
  local rv, json_str = r.GetProjExtState(0, ns, "PROFILE_JSON")
  if rv == 0 or not json_str or json_str == "" then
    return default_tbl
  end
  local ok, tbl = pcall(function() return r.JSONDecode(json_str) end)
  if not ok or type(tbl) ~= "table" then
    return default_tbl
  end
  for k, v in pairs(default_tbl or {}) do
    if tbl[k] == nil then
      tbl[k] = v
    end
  end
  return tbl
end

------------------------------------------------------------
-- Humanize-Konfiguration ermitteln
------------------------------------------------------------

local function DF95_GetHumanizeConfig()
  local res = r.GetResourcePath()
  local tmpcfg_path = res .. "/Data/DF95/_Humanize_TMP.json"

  -- 1) TMP-Datei (Preset-Apply)?
  local cfg = read_json(tmpcfg_path)
  if cfg then
    os.remove(tmpcfg_path)
    return cfg, "preset_tmp"
  end

  -- 2) Projekt-ExtState (Artist-Profil)
  local profile = DF95_LoadProfileFromExtState("DF95_HUMANIZE", {
    timing_ms        = 8,
    velocity_percent = 12,
    swing_percent    = 0
  })
  if profile then
    local c = {
      timing_ms        = tonumber(profile.timing_ms) or 8,
      velocity_percent = tonumber(profile.velocity_percent) or 12,
      swing_percent    = tonumber(profile.swing_percent) or 0
    }
    c.length_ms = math.max(0, (tonumber(profile.length_ms) or (c.timing_ms * 0.5)))
    return c, "artist_profile"
  end

  -- 3) Fallback
  return {
    timing_ms        = 8,
    velocity_percent = 12,
    swing_percent    = 0,
    length_ms        = 4
  }, "default"
end

------------------------------------------------------------
-- Humanize für Audio-Items
------------------------------------------------------------

local function DF95_HumanizeAudioItems(cfg)
  local timing_ms  = cfg.timing_ms or 0
  local vol_pct    = cfg.velocity_percent or 0
  local len_ms     = cfg.length_ms or 0

  if timing_ms == 0 and vol_pct == 0 and len_ms == 0 then
    return
  end

  local item_count = r.CountSelectedMediaItems(0)
  if item_count == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, item_count-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
    local vol = r.GetMediaItemInfo_Value(it, "D_VOL")

    -- Timing-Jitter
    if timing_ms ~= 0 then
      local off = (math.random() * 2 - 1) * (timing_ms / 1000.0)
      r.SetMediaItemInfo_Value(it, "D_POSITION", math.max(0, pos + off))
    end

    -- Lautstärke-Jitter
    if vol_pct ~= 0 then
      local max_db = (vol_pct / 4.0)
      local vdb = (math.random() * 2 - 1) * max_db
      r.SetMediaItemInfo_Value(it, "D_VOL", vol * db2amp(vdb))
    end

    -- Längen-Jitter
    if len_ms ~= 0 then
      local loff = (math.random() * 2 - 1) * (len_ms / 1000.0)
      r.SetMediaItemInfo_Value(it, "D_LENGTH", math.max(0.01, len + loff))
    end
  end

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("[DF95] Humanize Items", -1)
end

------------------------------------------------------------
-- Humanize für MIDI-Noten
------------------------------------------------------------

local function DF95_HumanizeMIDINotes(cfg)
  local timing_ms  = cfg.timing_ms or 0
  local vel_pct    = cfg.velocity_percent or 0
  local swing_pct  = cfg.swing_percent or 0

  if timing_ms == 0 and vel_pct == 0 and swing_pct == 0 then
    return
  end

  local item_count = r.CountSelectedMediaItems(0)
  if item_count == 0 then return end

  local _, qn_div, _, _ = r.GetSetProjectGrid(0, false)
  local proj_tempo = r.Master_GetTempo()

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, item_count-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(it)
    if take and r.TakeIsMIDI(take) then
      local _, notes, _, _ = r.MIDI_CountEvts(take)
      for n = 0, notes-1 do
        local ok, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, n)
        if ok and sel then
          local start_time = r.MIDI_GetProjTimeFromPPQPos(take, startppq)
          local jitter = (math.random() * 2 - 1) * (timing_ms / 1000.0)

          local swing_off = 0
          if swing_pct ~= 0 and qn_div and qn_div > 0 then
            local qn_pos = r.TimeMap2_timeToQN(0, start_time)
            local grid_idx = math.floor(qn_pos / qn_div + 0.5)
            if grid_idx % 2 == 1 then
              local grid_len_sec = (60.0 / proj_tempo) * qn_div
              swing_off = (swing_pct / 100.0) * (grid_len_sec * 0.5)
            end
          end

          local new_start_time = start_time + jitter + swing_off
          local new_start_ppq = r.MIDI_GetPPQPosFromProjTime(take, new_start_time)

          local new_vel = vel
          if vel_pct ~= 0 then
            local max_delta = math.floor((vel_pct / 100.0) * 32 + 0.5)
            local delta = math.random(-max_delta, max_delta)
            new_vel = math.max(1, math.min(127, vel + delta))
          end

          r.MIDI_SetNote(take, n, true, muted, new_start_ppq, endppq, chan, pitch, new_vel, true)
        end
      end
      r.MIDI_Sort(take)
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("[DF95] Humanize MIDI", -1)
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local cfg, src = DF95_GetHumanizeConfig()

DF95_HumanizeAudioItems(cfg)
DF95_HumanizeMIDINotes(cfg)

r.ShowConsoleMsg("[DF95] Humanize: applied using " .. tostring(src) .. "\\n")
