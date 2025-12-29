-- @description Artist Filter Motion Apply (FilterProfile-aware)
-- @version 1.0
-- @author DF95

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function load_artist_profile()
  local ok, M = pcall(dofile, df95_root() .. "DF95_ArtistProfile_Loader.lua")
  if not ok or not M or type(M.load) ~= "function" then
    r.ShowMessageBox("Could not load DF95_ArtistProfile_Loader.lua:\n" .. tostring(M),
      "DF95 Artist Filter Motion", 0)
    return nil
  end
  local prof, status = M.load()
  if status ~= "ok" then
    r.ShowMessageBox("DF95 ArtistProfile Loader returned status: " .. tostring(status),
      "DF95 Artist Filter Motion", 0)
    return nil
  end
  return prof
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function ensure_filter_fx(track, fx_label)
  if not fx_label or fx_label == "" then return nil end
  -- Try exact match first
  local fx = r.TrackFX_AddByName(track, fx_label, false, 0)
  if fx >= 0 then return fx end
  -- Try "insert if not found"
  fx = r.TrackFX_AddByName(track, fx_label, false, 1)
  if fx >= 0 then return fx end
  return nil
end

local function find_param_index(track, fx, hint)
  if not hint or hint == "" then
    return 0
  end
  local param_count = r.TrackFX_GetNumParams(track, fx)
  local lower_hint = hint:lower()
  for i = 0, param_count-1 do
    local _, pname = r.TrackFX_GetParamName(track, fx, i, "")
    if pname and pname:lower():find(lower_hint, 1, true) then
      return i
    end
  end
  return 0
end

local function get_time_selection()
  local _, isrgn, start_time, end_time = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if end_time <= start_time then
    return nil, nil
  end
  return start_time, end_time
end

------------------------------------------------------------
-- Envelope drawing
------------------------------------------------------------

local function clear_env_range(env, t0, t1)
  if not env or not t0 or not t1 then return end
  r.DeleteEnvelopePointRange(env, t0, t1)
end

local function draw_step_seq(env, t0, t1, cfg)
  local steps = cfg.steps or 16
  local depth = clamp(cfg.depth or 0.7, 0.0, 1.0)
  local randomness = clamp(cfg.randomness or 0.5, 0.0, 1.0)

  if steps < 2 then steps = 2 end

  local dur = t1 - t0
  math.randomseed(os.time() + math.floor(t0 * 1000))

  for i = 0, steps do
    local frac = i / steps
    local t = t0 + dur * frac
    local base = 0.5
    local rand = (math.random() * 2 - 1) * randomness
    local value = clamp(base + rand * depth, 0.0, 1.0)
    r.InsertEnvelopePoint(env, t, value, 0, 0.0, true, true)
  end
  r.Envelope_SortPoints(env)
end

local function draw_lfo_sine(env, t0, t1, cfg)
  local depth = clamp(cfg.depth or 0.5, 0.0, 1.0)
  local cycles = cfg.cycles or 1
  if cycles < 0.25 then cycles = 0.25 end

  local dur = t1 - t0
  local steps = (cfg.steps or 64)
  if steps < 32 then steps = 32 end

  local two_pi = math.pi * 2.0
  for i = 0, steps do
    local frac = i / steps
    local t = t0 + dur * frac
    local phase = frac * cycles * two_pi
    local value = clamp(0.5 + math.sin(phase) * 0.5 * depth, 0.0, 1.0)
    r.InsertEnvelopePoint(env, t, value, 0, 0.0, true, true)
  end
  r.Envelope_SortPoints(env)
end

local function draw_random_walk(env, t0, t1, cfg)
  local steps = cfg.steps or 32
  if steps < 4 then steps = 4 end
  local depth = clamp(cfg.depth or 0.6, 0.0, 1.0)
  local randomness = clamp(cfg.randomness or 0.5, 0.0, 1.0)

  local dur = t1 - t0
  math.randomseed(os.time() + math.floor(t0 * 1234))

  local current = 0.5
  for i = 0, steps do
    local frac = i / steps
    local t = t0 + dur * frac
    local step = (math.random() * 2 - 1) * 0.2 * randomness
    current = clamp(current + step * depth, 0.0, 1.0)
    r.InsertEnvelopePoint(env, t, current, 0, 0.0, true, true)
  end
  r.Envelope_SortPoints(env)
end

local function apply_filter_motion_to_track(track, filter_cfg, t0, t1)
  if not filter_cfg then return end
  local fx_label = filter_cfg.filter_fx or "VST: ReaEQ (Cockos)"
  local mode = filter_cfg.mode or "lfo_sine"

  local fx = ensure_filter_fx(track, fx_label)
  if not fx then
    r.ShowMessageBox("Could not insert or find filter FX:\n" .. tostring(fx_label),
      "DF95 Artist Filter Motion", 0)
    return
  end

  local param_idx = 0
  if filter_cfg.param_hint and filter_cfg.param_hint ~= "" then
    param_idx = find_param_index(track, fx, filter_cfg.param_hint)
  end

  local env = r.GetFXEnvelope(track, fx, param_idx, true)
  if not env then
    r.ShowMessageBox("Could not create FX envelope for parameter index " .. tostring(param_idx),
      "DF95 Artist Filter Motion", 0)
    return
  end

  clear_env_range(env, t0, t1)

  if mode == "step_seq" then
    draw_step_seq(env, t0, t1, filter_cfg)
  elseif mode == "random_walk" then
    draw_random_walk(env, t0, t1, filter_cfg)
  else
    -- default to sine LFO
    draw_lfo_sine(env, t0, t1, filter_cfg)
  end
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local prof = load_artist_profile()
  if not prof then return end

  local filter_cfg = prof.filter or {}
  if not next(filter_cfg) then
    -- No artist-specific entry found, use defaults via loader JSON
    -- (filter_cfg will at least hold defaults if JSON is present)
  end

  local t0, t1 = get_time_selection()
  if not t0 or not t1 then
    r.ShowMessageBox("Please set a time selection first.\nFilter motion will be drawn over that range.",
      "DF95 Artist Filter Motion", 0)
    return
  end

  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("No tracks selected.\nSelect one or more tracks to apply filter motion.",
      "DF95 Artist Filter Motion", 0)
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    apply_filter_motion_to_track(tr, filter_cfg, t0, t1)
  end

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 Artist Filter Motion Apply", -1)
end

main()
