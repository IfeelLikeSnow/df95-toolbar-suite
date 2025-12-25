-- DF95_DynamicSlicing_Inspector_ImGui.lua
-- Dynamic Slicing Inspector & Preset-Editor for DF95
-- Features:
--   * Anzeige aktiver Dynamic-Presets (Transient/Gate)
--   * Bearbeiten von Parametern (Threshold, min_gap, step_ms, usw.)
--   * Artist -> Preset Mapping editieren
--   * Slice-Length-Modi (ultra/short/medium/long) ansehen & anpassen
--   * Test-Run: Apply to selected items (ruft DF95_Dynamic_Slicer.lua)
--   * Kleine Hüllkurven-Visualisierung für das erste selektierte Item
--
-- Benötigt:
--   * ReaImGui
--   * DF95_Dynamic_Slicer.lua
--   * DF95_DynamicSlicing_Presets.json (Lua-Style Table)

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui-Extension nicht gefunden.\nBitte ReaImGui installieren.", "DF95 Dynamic Slicing Inspector", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Dynamic Slicing Inspector')
local FONT = r.ImGui_CreateFont('sans-serif', 17)
r.ImGui_AttachFont(ctx, FONT)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function cfg_path()
  return df95_root() .. "DF95_DynamicSlicing_Presets.json"
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local d = f:read("*all")
  f:close()
  return d
end

local function write_file(path, txt)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(txt or "")
  f:close()
  return true
end

local function parse_cfg()
  local txt = read_file(cfg_path())
  if not txt or txt == "" then
    return { presets = {}, artist_map = {}, slice_length_modes = {} }
  end
  local ok, chunk = pcall(load, "return " .. txt)
  if not ok or not chunk then
    r.ShowMessageBox("Fehler beim Laden von DF95_DynamicSlicing_Presets.json:\n"..tostring(chunk),
      "DF95 Dynamic Slicing Inspector", 0)
    return { presets = {}, artist_map = {}, slice_length_modes = {} }
  end
  local ok2, res = pcall(chunk)
  if not ok2 or type(res) ~= "table" then
    r.ShowMessageBox("Ungültige Preset-Struktur in DF95_DynamicSlicing_Presets.json.", "DF95 Dynamic Slicing Inspector", 0)
    return { presets = {}, artist_map = {}, slice_length_modes = {} }
  end
  res.presets = res.presets or {}
  res.artist_map = res.artist_map or {}
  res.slice_length_modes = res.slice_length_modes or {}
  return res
end

local function serialize_table(t, indent)
  indent = indent or ""
  local buf = {}
  local function add(s) buf[#buf+1] = s end

  if type(t) ~= "table" then
    if type(t) == "string" then
      add(string.format("%q", t))
    elseif type(t) == "number" then
      add(tostring(t))
    elseif type(t) == "boolean" then
      add(t and "true" or "false")
    else
      add("nil")
    end
    return table.concat(buf)
  end

  add("{\n")
  local subindent = indent .. "  "
  local first = true
  for k, v in pairs(t) do
    if not first then add("\n") end
    first = false
    local key_repr
    if type(k) == "string" and k:match("^[_%a][_%w]*$") then
      key_repr = k .. " = "
    else
      key_repr = "[" .. serialize_table(k) .. "] = "
    end
    add(subindent .. key_repr .. serialize_table(v, subindent)..",")
  end
  add("\n" .. indent .. "}")
  return table.concat(buf)
end

local function save_cfg(cfg)
  local txt = "{" ..
    "\n  presets = " .. serialize_table(cfg.presets, "  ") .. "," ..
    "\n  artist_map = " .. serialize_table(cfg.artist_map, "  ") .. "," ..
    "\n  slice_length_modes = " .. serialize_table(cfg.slice_length_modes, "  ") .. "," ..
    "\n}"
  local ok = write_file(cfg_path(), txt)
  if not ok then
    r.ShowMessageBox("Konnte DF95_DynamicSlicing_Presets.json nicht schreiben.", "DF95 Dynamic Slicing Inspector", 0)
  else
    r.ShowMessageBox("Dynamic Slicing Presets gespeichert.", "DF95 Dynamic Slicing Inspector", 0)
  end
end

------------------------------------------------------------
-- Load config
------------------------------------------------------------

local CFG = parse_cfg()

-- Build sorted preset list
local PRESET_IDS = {}
for id, _ in pairs(CFG.presets) do PRESET_IDS[#PRESET_IDS+1] = id end
table.sort(PRESET_IDS)

-- Build sorted artist list
local ARTIST_IDS = {}
for art, _ in pairs(CFG.artist_map) do ARTIST_IDS[#ARTIST_IDS+1] = art end
table.sort(ARTIST_IDS)

local LENGTH_IDS = {}
for id, _ in pairs(CFG.slice_length_modes) do LENGTH_IDS[#LENGTH_IDS+1] = id end
table.sort(LENGTH_IDS)

------------------------------------------------------------
-- GUI state
------------------------------------------------------------

local state = {
  preset_idx = 1,
  artist_idx = 1,
  length_idx = 1,
  new_artist = "",
  new_artist_preset = "",
  preview_length_mode = "medium",
}

local function current_preset_id()
  return PRESET_IDS[state.preset_idx] or PRESET_IDS[1]
end

local function current_preset()
  return CFG.presets[current_preset_id()] or {}
end

local function current_artist_id()
  return ARTIST_IDS[state.artist_idx] or ARTIST_IDS[1]
end

------------------------------------------------------------
-- Run Dynamic Slicer for preview
------------------------------------------------------------

local function run_dynamic_slicer_for_preview()
  local preset_id = current_preset_id()
  local length_mode = state.preview_length_mode or "medium"

  r.SetProjExtState(0, "DF95_DYN", "PRESET", preset_id or "")
  r.SetProjExtState(0, "DF95_DYN", "LENGTH_MODE", length_mode)

  local script_path = df95_root() .. "DF95_Dynamic_Slicer.lua"
  local ok, err = pcall(dofile, script_path)
  if not ok then
    r.ShowMessageBox("Fehler beim Ausführen des Dynamic Slicers:\n"..tostring(err), "DF95 Dynamic Slicing Inspector", 0)
  end
end

------------------------------------------------------------
-- Simple envelope visualization for first selected item
------------------------------------------------------------

local function collect_envelope()
  local num = r.CountSelectedMediaItems(0)
  if num == 0 then return nil end
  local it = r.GetSelectedMediaItem(0, 0)
  local take = r.GetActiveTake(it)
  if not take or r.TakeIsMIDI(take) then return nil end

  local item_pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(it, "D_LENGTH")

  local aa = r.CreateTakeAudioAccessor(take)
  if not aa then return nil end

  local src = r.GetMediaItemTake_Source(take)
  local samplerate = ({r.GetMediaSourceSampleRate(src)})[2]
  if not samplerate or samplerate <= 0 then samplerate = 44100 end

  local num_points = 128
  local step = item_len / num_points
  local num_ch = ({r.GetMediaSourceNumChannels(src)})[2] or 2

  local env = {}
  local buf = r.new_array(256 * num_ch)

  for i = 0, num_points-1 do
    local t = i * step
    local ns = math.floor(step * samplerate + 0.5)
    if ns <= 0 then ns = 64 end
    buf.clear()
    r.GetAudioAccessorSamples(aa, samplerate, num_ch, t, ns, buf)
    local peak = 0.0
    for s = 0, ns-1 do
      local sL = buf[s*num_ch+1] or 0.0
      local sR = (num_ch>1 and buf[s*num_ch+2]) or 0.0
      local a = math.max(math.abs(sL), math.abs(sR))
      if a > peak then peak = a end
    end
    env[#env+1] = peak
  end

  r.DestroyAudioAccessor(aa)

  -- Normalize for plotting
  local maxv = 0.0
  for _, v in ipairs(env) do if v > maxv then maxv = v end end
  if maxv <= 0 then maxv = 1.0 end
  for i, v in ipairs(env) do env[i] = v / maxv end

  return env
end

------------------------------------------------------------
-- Main GUI loop
------------------------------------------------------------

local function loop()
  r.ImGui_PushFont(ctx, FONT)

  r.ImGui_SetNextWindowSize(ctx, 820, 620, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, 'DF95 Dynamic Slicing Inspector', true)

  if visible then
    ------------------------------------------------
    -- Left column: Presets & Artist mapping
    ------------------------------------------------
    r.ImGui_BeginGroup(ctx)

    r.ImGui_Text(ctx, "Dynamic Presets")
    if #PRESET_IDS == 0 then
      r.ImGui_Text(ctx, "Keine Presets in CFG.presets gefunden.")
    else
      -- Preset Combo
      local current_id = current_preset_id()
      local label = current_id or "<none>"
      if r.ImGui_BeginCombo(ctx, "Preset", label) then
        for i, id in ipairs(PRESET_IDS) do
          local is_sel = (i == state.preset_idx)
          if r.ImGui_Selectable(ctx, id, is_sel) then
            state.preset_idx = i
          end
          if is_sel then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end

      local p = current_preset()
      local mode = p.mode or "transient"
      r.ImGui_Text(ctx, "Mode: " .. tostring(mode))

      -- Editable fields depending on mode
      if mode == "transient" then
        local changed
        local thr = p.threshold_db or -24.0
        changed, thr = r.ImGui_SliderFloat(ctx, "Threshold (dB)", thr, -60.0, 0.0)
        if changed then p.threshold_db = thr end

        local atk = p.attack_sensitivity_db or 4.0
        changed, atk = r.ImGui_SliderFloat(ctx, "Attack Sensitivity (dB)", atk, 1.0, 12.0)
        if changed then p.attack_sensitivity_db = atk end

        local mg = p.min_gap_ms or 80
        changed, mg = r.ImGui_SliderFloat(ctx, "Min Gap (ms)", mg, 10, 300)
        if changed then p.min_gap_ms = mg end

        local st = p.step_ms or 3
        changed, st = r.ImGui_SliderFloat(ctx, "Step (ms)", st, 1, 20)
        if changed then p.step_ms = st end

        local zc = p.search_zerocross_ms or 3
        changed, zc = r.ImGui_SliderFloat(ctx, "ZeroCross Window (ms)", zc, 0, 10)
        if changed then p.search_zerocross_ms = zc end

        local fd = p.fade_ms or 4
        changed, fd = r.ImGui_SliderFloat(ctx, "Fade (ms)", fd, 0, 20)
        if changed then p.fade_ms = fd end

      elseif mode == "gate" then
        local changed
        local thr = p.threshold_db or -24.0
        changed, thr = r.ImGui_SliderFloat(ctx, "Threshold (dB)", thr, -60.0, 0.0)
        if changed then p.threshold_db = thr end

        local hold = p.hold_ms or 60
        changed, hold = r.ImGui_SliderFloat(ctx, "Hold (ms)", hold, 5, 400)
        if changed then p.hold_ms = hold end

        local mg = p.min_gap_ms or 80
        changed, mg = r.ImGui_SliderFloat(ctx, "Min Gap (ms)", mg, 10, 300)
        if changed then p.min_gap_ms = mg end

        local st = p.step_ms or 3
        changed, st = r.ImGui_SliderFloat(ctx, "Step (ms)", st, 1, 20)
        if changed then p.step_ms = st end

        local zc = p.search_zerocross_ms or 3
        changed, zc = r.ImGui_SliderFloat(ctx, "ZeroCross Window (ms)", zc, 0, 10)
        if changed then p.search_zerocross_ms = zc end

        local fd = p.fade_ms or 4
        changed, fd = r.ImGui_SliderFloat(ctx, "Fade (ms)", fd, 0, 20)
        if changed then p.fade_ms = fd end
      end
    end

    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Slice Length Modes")
    if #LENGTH_IDS == 0 then
      r.ImGui_Text(ctx, "Keine slice_length_modes in CFG gefunden.")
    else
      for _, id in ipairs(LENGTH_IDS) do
        local val = CFG.slice_length_modes[id] or 0
        local changed
        changed, val = r.ImGui_SliderFloat(ctx, id .. " (ms)", val, 10, 1000)
        if changed then
          CFG.slice_length_modes[id] = val
        end
      end
    end

    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Artist → Preset Mapping")
    if #ARTIST_IDS == 0 then
      r.ImGui_Text(ctx, "Keine Einträge in artist_map gefunden.")
    else
      -- Artist Combo
      local cur_art = current_artist_id() or "<none>"
      if r.ImGui_BeginCombo(ctx, "Artist", cur_art) then
        for i, id in ipairs(ARTIST_IDS) do
          local is_sel = (i == state.artist_idx)
          if r.ImGui_Selectable(ctx, id, is_sel) then
            state.artist_idx = i
          end
          if is_sel then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end

      local art = current_artist_id()
      local mapped = CFG.artist_map[art] or ""
      local idx_for_preset = 1
      for i, id in ipairs(PRESET_IDS) do
        if id == mapped then idx_for_preset = i break end
      end

      if r.ImGui_BeginCombo(ctx, "Mapped Preset", mapped ~= "" and mapped or "<none>") then
        for i, id in ipairs(PRESET_IDS) do
          local is_sel = (id == mapped)
          if r.ImGui_Selectable(ctx, id, is_sel) then
            CFG.artist_map[art] = id
          end
          if is_sel then r.ImGui_SetItemDefaultFocus(ctx) end
        end
        r.ImGui_EndCombo(ctx)
      end
    end

    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Neuen Artist hinzufügen")
    local changed
    changed, state.new_artist = r.ImGui_InputText(ctx, "Artist Name", state.new_artist or "", 128)
    changed, state.new_artist_preset = r.ImGui_InputText(ctx, "Preset ID", state.new_artist_preset or "", 128)
    if r.ImGui_Button(ctx, "Add Artist Mapping", 200, 25) then
      local art = (state.new_artist or ""):lower():gsub("%s+","")
      local pid = state.new_artist_preset or ""
      if art ~= "" and CFG.presets[pid] then
        CFG.artist_map[art] = pid
        ARTIST_IDS[#ARTIST_IDS+1] = art
        table.sort(ARTIST_IDS)
        state.new_artist = ""
        state.new_artist_preset = ""
      else
        r.ShowMessageBox("Artist-Name oder Preset-ID ungültig (Preset muss existieren).", "DF95 Dynamic Slicing Inspector", 0)
      end
    end

    r.ImGui_Separator(ctx)

    if r.ImGui_Button(ctx, "Save Presets to JSON", 220, 30) then
      save_cfg(CFG)
    end

    r.ImGui_EndGroup(ctx)

    ------------------------------------------------
    -- Right column: Preview & Envelope view
    ------------------------------------------------
    r.ImGui_SameLine(ctx)

    r.ImGui_BeginGroup(ctx)

    r.ImGui_Text(ctx, "Preview / Test Run")
    local lengths = { "ultra", "short", "medium", "long" }
    r.ImGui_Text(ctx, "Preview Slice Length Mode:")
    for _, m in ipairs(lengths) do
      local sel = (state.preview_length_mode == m)
      if r.ImGui_RadioButton(ctx, m, sel) then
        state.preview_length_mode = m
      end
      r.ImGui_SameLine(ctx)
    end
    r.ImGui_NewLine(ctx)

    if r.ImGui_Button(ctx, "Apply Current Preset to Selected Items", 320, 30) then
      run_dynamic_slicer_for_preview()
    end

    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Envelope / Transient Visualization (1st selected item):")
    local env = collect_envelope()
    if env and #env > 0 then
      -- Build float buffer for PlotLines
      local arr = r.new_array(#env)
      for i, v in ipairs(env) do arr[i] = v end
      r.ImGui_PlotLines(ctx, "Envelope (normalized)", arr, #env, 0, nil, 0.0, 1.0, 380, 80)
    else
      r.ImGui_Text(ctx, "Keine Audio-Items selektiert oder keine gültige Hüllkurve.")
    end

    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx, "Hinweis: Die Hüllkurve ist nur eine grobe Visualisierung, um Transientendichte und allgemeine Dynamik zu sehen. Threshold-/Sensitivity-Einstellungen bestimmen, wo tatsächlich Slices gesetzt werden.")

    r.ImGui_EndGroup(ctx)

    r.ImGui_End(ctx)
  end

  r.ImGui_PopFont(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
