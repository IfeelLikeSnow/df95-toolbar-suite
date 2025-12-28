-- DF95_Dynamic_Slicer.lua (v2)
-- Transienten- / Gate-basierter Physical Slicer für DF95-Ökosystem.
-- Neu in v2:
--   * Slice-Length-Modi (ultra/short/medium/long) pro Durchlauf
--   * Länge wird nach dem Slicing physisch gekappt (Items werden kürzer gemacht)
--
-- Integration:
--   Liest optional:
--     ProjExtState "DF95_SLICING" / "ARTIST"
--     ProjExtState "DF95_SLICING" / "INTENSITY"
--     ProjExtState "DF95_DYN"     / "PRESET"       (Preset-Name, z.B. transient_soft)
--     ProjExtState "DF95_DYN"     / "LENGTH_MODE"  ("ultra"/"short"/"medium"/"long")
--
-- Wenn nichts gesetzt:
--   * Fragt nach Preset-Name
--   * Fragt NICHT nach Länge – Standard = "medium"

local r = reaper

------------------------------------------------------------
-- DF95 Artist Profile Loader (generic helper for this script)
------------------------------------------------------------

local function DF95_LoadProfileFromExtState(ns, default_tbl)
  if not reaper.JSONDecode then
    return default_tbl
  end
  local rv, json_str = reaper.GetProjExtState(0, ns, "PROFILE_JSON")
  if rv == 0 or not json_str or json_str == "" then
    return default_tbl
  end
  local ok, tbl = pcall(function() return reaper.JSONDecode(json_str) end)
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
-- Slicing Artist-Profile (falls gesetzt)
------------------------------------------------------------

local DF95_SLICING_PROFILE = DF95_LoadProfileFromExtState("DF95_SLICING", {
  slice_density    = "medium",   -- low_medium / medium / medium_high / high
  crossfade_ms     = 5,
  allow_odd_meters = true
})

local function DF95_MapSliceDensityToLengthMode(density)
  density = (density or "medium"):lower()
  if density == "high" then
    return "ultra"
  elseif density == "medium_high" then
    return "short"
  elseif density == "low_medium" then
    return "long"
  else
    return "medium"
  end
end



------------------------------------------------------------
-- Helpers: Pfad, Datei
------------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local d = f:read("*all")
  f:close()
  return d
end

-- sehr simpler Pseudo-JSON-Parser (Lua-Style): nur wenn du später eine externe Preset-Datei willst
local function parse_json_like(txt)
  if not txt or txt == "" then return nil end
  local ok, res = pcall(function()
    local chunk = "return " .. txt
      :gsub("null", "nil")
      :gsub("true", "true")
      :gsub("false", "false")
    return assert(load(chunk))()
  end)
  if ok then return res end
  return nil
end

------------------------------------------------------------
-- Presets (eingebaut)
------------------------------------------------------------

local PRESETS = {
  -- Transienten-basiert (IDM Drumloops, Glitch)
  transient_soft = {
    mode = "transient",
    threshold_db = -24.0,      -- ab wann überhaupt relevant
    attack_sensitivity_db = 6, -- wie viel dB-Anstieg als „Transiente“ zählt
    min_gap_ms = 120,          -- Mindestabstand zwischen Slices
    step_ms = 5,               -- Analysefenster
    search_zerocross_ms = 3,   -- um die Transiente herum nach ZeroCross suchen
    fade_ms = 5,               -- kleine Fades setzen
  },
  transient_medium = {
    mode = "transient",
    threshold_db = -20.0,
    attack_sensitivity_db = 4,
    min_gap_ms = 80,
    step_ms = 3,
    search_zerocross_ms = 4,
    fade_ms = 4,
  },
  transient_extreme = {
    mode = "transient",
    threshold_db = -30.0,      -- auch leisere Hits
    attack_sensitivity_db = 3,
    min_gap_ms = 40,
    step_ms = 2,
    search_zerocross_ms = 5,
    fade_ms = 3,
  },

  -- Gate-basiert (Rhythmische Stutters)
  gate_sparse = {
    mode = "gate",
    threshold_db = -22.0,
    hold_ms = 150,
    min_gap_ms = 80,
    step_ms = 5,
    search_zerocross_ms = 4,
    fade_ms = 5,
  },
  gate_stutter = {
    mode = "gate",
    threshold_db = -26.0,
    hold_ms = 60,
    min_gap_ms = 40,
    step_ms = 3,
    search_zerocross_ms = 3,
    fade_ms = 4,
  },
  gate_microclicks = {
    mode = "gate",
    threshold_db = -32.0,
    hold_ms = 20,
    min_gap_ms = 15,
    step_ms = 2,
    search_zerocross_ms = 2,
    fade_ms = 3,
  },
}

-- Artist -> Default-Preset
local ARTIST_PRESET_MAP = {
  autechre          = "transient_extreme",
  squarepusher      = "transient_extreme",
  bogdanraczynski   = "transient_extreme",
  jega              = "transient_extreme",
  aphextwin         = "transient_medium",
  flyinglotus       = "gate_stutter",
  mouseonmars       = "gate_stutter",
  boc               = "transient_soft",
  boardsofcanada    = "transient_soft",
  arovane           = "transient_soft",
  monoceros         = "transient_soft",
  janjelinek        = "transient_soft",
  telefontelaviv    = "transient_soft",
  proem             = "transient_soft",
  styrofoam         = "transient_soft",
  plaid             = "transient_medium",
  apparat           = "transient_medium",
  thomyorke         = "transient_medium",
}

-- Slice-Längen-Modi → max. Länge pro Slice
local SLICE_LENGTH_MODES = {
  ultra  = 40,    -- ms
  short  = 90,
  medium = 180,
  long   = 320,
}

------------------------------------------------------------
-- Optional: Presets aus Datei mergen
------------------------------------------------------------

local function load_json_presets()
  local path = df95_root() .. "DF95_DynamicSlicing_Presets.json"
  local txt = read_file(path)
  if not txt then return end
  local data = parse_json_like(txt)
  if not data or type(data) ~= "table" then return end

  if type(data.presets) == "table" then
    for name, cfg in pairs(data.presets) do
      if type(cfg) == "table" then
        PRESETS[name] = cfg
      end
    end
  end
  if type(data.artist_map) == "table" then
    for art, p in pairs(data.artist_map) do
      if type(p) == "string" then
        ARTIST_PRESET_MAP[art:lower()] = p
      end
    end
  end
  if type(data.slice_length_modes) == "table" then
    for k, v in pairs(data.slice_length_modes) do
      if type(v) == "number" then
        SLICE_LENGTH_MODES[k] = v
      end
    end
  end
end

load_json_presets()

------------------------------------------------------------
-- Utility: dB <-> Amp
------------------------------------------------------------

local function amp_to_db(a)
  if a <= 0.0000001 then return -120.0 end
  return 20 * math.log(a, 10)
end

------------------------------------------------------------
-- Artist / Preset / Length-Mode Auswahl
------------------------------------------------------------

local function get_artist_from_extstate()
  local _, art = r.GetProjExtState(0, "DF95_SLICING", "ARTIST")
  if art and art ~= "" then
    art = art:lower():gsub("%s+","")
    if art:find("autechre") or art == "ae" then return "autechre" end
    if art:find("squarepusher") then return "squarepusher" end
    if art:find("aphex") or art:find("afx") then return "aphextwin" end
    if art:find("boardsofcanada") or art:find("boc") then return "boc" end
    if art:find("bogdan") then return "bogdanraczynski" end
    if art:find("flyinglotus") or art:find("flylo") then return "flyinglotus" end
    if art:find("mouseonmars") then return "mouseonmars" end
    if art:find("arovane") then return "arovane" end
    if art:find("monoceros") then return "monoceros" end
    if art:find("jelinek") then return "janjelinek" end
    if art:find("telefontelaviv") or art:find("telefon") then return "telefontelaviv" end
    if art:find("proem") then return "proem" end
    if art:find("styrofoam") then return "styrofoam" end
    if art:find("plaid") then return "plaid" end
    if art:find("apparat") then return "apparat" end
    if art:find("thomyorke") or art:find("thom") then return "thomyorke" end
    if art:find("jega") then return "jega" end
    return art
  end
  return nil
end

local function choose_preset_name()
  -- 1) DF95_DYN/PRESET (z.B. von Autopilot oder Browser)
  local _, p = r.GetProjExtState(0, "DF95_DYN", "PRESET")
  if p and p ~= "" and PRESETS[p] then
    return p
  end

  -- 2) Artist-Mapping
  local art = get_artist_from_extstate()
  if art then
    local mapped = ARTIST_PRESET_MAP[art]
    if mapped and PRESETS[mapped] then
      return mapped
    end
  end

  -- 3) User-Dialog
  local default = "transient_medium"
  local ok, ret = r.GetUserInputs("DF95 Dynamic Slicer", 1,
    "Preset Name (z.B. transient_soft/transient_medium/transient_extreme/gate_stutter),",
    default)
  if not ok then return nil end
  local name = (ret or ""):gsub("%s+","")
  if PRESETS[name] then
    return name
  else
    r.ShowMessageBox("Preset '"..name.."' nicht gefunden. Verwende '"..default.."'.", "DF95 Dynamic Slicer", 0)
    return default
  end
end

local function get_length_mode()
  -- DF95_DYN/LENGTH_MODE (ultra/short/medium/long)
  local _, m = r.GetProjExtState(0, "DF95_DYN", "LENGTH_MODE")
  m = (m or ""):lower()
  if SLICE_LENGTH_MODES[m] then
    return m
  end

  -- Wenn kein expliziter LENGTH_MODE gesetzt ist, Artist-Slicing-Profil nutzen
  if DF95_SLICING_PROFILE and DF95_SLICING_PROFILE.slice_density then
    local mapped = DF95_MapSliceDensityToLengthMode(DF95_SLICING_PROFILE.slice_density)
    if SLICE_LENGTH_MODES[mapped] then
      return mapped
    end
  end

  return "medium"
end

------------------------------------------------------------
-- Audio-Analyse: Transienten / Gate
------------------------------------------------------------

local function collect_slices_for_take(take, preset)
  local slices = {}
  local item = r.GetMediaItemTake_Item(take)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  local aa = r.CreateTakeAudioAccessor(take)
  if not aa then return slices end

  local src = r.GetMediaItemTake_Source(take)
  local samplerate = ({r.GetMediaSourceSampleRate(src)})[2]
  if not samplerate or samplerate <= 0 then samplerate = 44100 end

  local step_s = (preset.step_ms or 5) / 1000.0
  local min_gap_s = (preset.min_gap_ms or 80) / 1000.0
  local search_zerocross_s = (preset.search_zerocross_ms or 3) / 1000.0

  local thr_db = preset.threshold_db or -24.0
  local thr_amp = 10^(thr_db/20)
  local atk_db = preset.attack_sensitivity_db or 4.0

  local buf_samples = math.max(128, math.floor(step_s * samplerate + 0.5))
  local num_ch = ({r.GetMediaSourceNumChannels(src)})[2] or 2
  local buf = r.new_array(buf_samples * num_ch)

  local prev_env = 0.0
  local last_slice_t = 0.0
  local mode = preset.mode or "transient"

  local function get_zero_cross_time(center_time)
    local half = search_zerocross_s
    local start = math.max(0.0, center_time - half)
    local stop  = math.min(item_len, center_time + half)
    local win_len = stop - start
    if win_len <= 0 then return center_time end

    local ns = math.floor(win_len * samplerate + 0.5)
    if ns < 4 then return center_time end

    local buf2 = r.new_array(ns * num_ch)
    r.GetAudioAccessorSamples(aa, samplerate, num_ch, start, ns, buf2)

    local best_t = center_time
    local best_dist = half

    local prev = buf2[1]
    for i = 1, ns-1 do
      local sidx = i*num_ch+1
      local v = buf2[sidx]
      if prev and v and prev*v < 0 then
        local t = start + (i / samplerate)
        local dist = math.abs(t - center_time)
        if dist < best_dist then
          best_dist = dist
          best_t = t
        end
      end
      prev = v
    end
    return best_t
  end

  local t = 0.0
  while t < item_len do
    local ns = math.min(buf_samples, math.floor((item_len - t) * samplerate + 0.5))
    if ns <= 0 then break end
    buf.clear()
    r.GetAudioAccessorSamples(aa, samplerate, num_ch, t, ns, buf)

    local peak = 0.0
    for i = 0, ns-1 do
      local sL = buf[i*num_ch+1] or 0.0
      local sR = (num_ch > 1 and buf[i*num_ch+2]) or 0.0
      local a = math.max(math.abs(sL), math.abs(sR))
      if a > peak then peak = a end
    end

    local env = peak
    local env_db = amp_to_db(env)
    local prev_db = amp_to_db(prev_env + 1e-12)
    local delta_db = env_db - prev_db

    local now = t
    local gap_ok = (now - last_slice_t) >= min_gap_s

    if mode == "transient" then
      if env >= thr_amp and delta_db >= atk_db and gap_ok then
        local candidate = now
        if search_zerocross_s > 0 then
          candidate = get_zero_cross_time(candidate)
        end
        table.insert(slices, item_pos + candidate)
        last_slice_t = now
      end
    elseif mode == "gate" then
      if env >= thr_amp and gap_ok then
        local candidate = now
        if search_zerocross_s > 0 then
          candidate = get_zero_cross_time(candidate)
        end
        table.insert(slices, item_pos + candidate)
        last_slice_t = now
      end
    end

    prev_env = env
    t = t + step_s
  end

  r.DestroyAudioAccessor(aa)
  return slices
end

------------------------------------------------------------
-- Physical Slicing + Fades + Slice-Length-Clamping
------------------------------------------------------------

local function apply_slices_to_items(slices, preset, length_mode)
  if #slices == 0 then return end
  table.sort(slices)
  local fade_ms = preset.fade_ms or 0
  local fade_s = fade_ms / 1000.0

  local max_len_ms = SLICE_LENGTH_MODES[length_mode] or SLICE_LENGTH_MODES["medium"]
  local max_len_s = max_len_ms / 1000.0

  local num_sel = r.CountSelectedMediaItems(0)
  if num_sel == 0 then return end

  -- 1) Splits
  for _, sp in ipairs(slices) do
    for i = 0, num_sel-1 do
      local it = r.GetSelectedMediaItem(0, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if sp > pos+0.0001 and sp < pos+len-0.0001 then
        r.SplitMediaItem(it, sp)
      end
    end
  end

  -- 2) Fades
  local new_num = r.CountSelectedMediaItems(0)
  if fade_s > 0 then
    for i = 0, new_num-1 do
      local it = r.GetSelectedMediaItem(0, i)
      r.SetMediaItemInfo_Value(it, "D_FADEINLEN", fade_s)
      r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", fade_s)
    end
  end

  -- 3) Slice-Length-Clamping
  if max_len_s > 0 then
    for i = 0, new_num-1 do
      local it = r.GetSelectedMediaItem(0, i)
      local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if len > max_len_s then
        r.SetMediaItemInfo_Value(it, "D_LENGTH", max_len_s)
      end
    end
  end

  r.UpdateArrange()
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local num_items = r.CountSelectedMediaItems(0)
  if num_items == 0 then
    r.ShowMessageBox("Bitte zuerst ein oder mehrere Items selektieren.", "DF95 Dynamic Slicer", 0)
    return
  end

  local preset_name = choose_preset_name()
  if not preset_name then return end
  local preset = PRESETS[preset_name]
  if not preset then
    r.ShowMessageBox("Preset '"..preset_name.."' nicht gefunden.", "DF95 Dynamic Slicer", 0)
    return
  end

  local length_mode = get_length_mode() -- ultra/short/medium/long

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local all_slices = {}

  for i = 0, num_items-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(it)
    if take and not r.TakeIsMIDI(take) then
      local slices = collect_slices_for_take(take, preset)
      for _, sp in ipairs(slices) do
        table.insert(all_slices, sp)
      end
    end
  end

  apply_slices_to_items(all_slices, preset, length_mode)

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Dynamic Slicer ["..preset_name.."] / "..length_mode, -1)
end

main()
