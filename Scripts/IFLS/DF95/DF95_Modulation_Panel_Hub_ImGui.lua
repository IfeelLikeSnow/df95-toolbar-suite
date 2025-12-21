-- DF95_Modulation_Panel_Hub_ImGui.lua
-- Phase 102: IFLS / DF95 Modulation Panel Hub (ImGui)
--
-- IDEE
-- ====
-- Interaktives ImGui-Panel, mit dem du:
--   * Einen Track mit Slices auswählst (Kick, Snare, Hats, etc.).
--   * Kategorie siehst (auto-detektiert aus Tracknamen, aber manuell überschreibbar).
--   * Modulationsstärke für:
--       - Lautstärke (dB)
--       - Länge (%)
--       - Start-Jitter (ms)
--       - Fade-In / Fade-Out (ms)
--     einstellen kannst.
--   * Einen Button "Modulate Now" hast, der die Slices auf dem gewählten Track
--     mit zufälligen, aber begrenzten Variationen moduliert.
--   * Für den Track einen passenden Mod-FX-Bus erstellt/benutzt:
--       [IFLS Mod FX] Kick / Snare / Hats / ...
--
-- Das Script verändert NICHT deine vorhandenen Track-FX-Ketten, sondern
-- arbeitet über einen zusätzlichen Bus plus Item-Parameter.

local r = reaper

------------------------------------------------------------
-- Category FX Engine Loader (Phase 113/114)
------------------------------------------------------------

local function DF95_ModHub_EnsureCategoryFXEngine()
  if DF95_CategoryFX_ApplyToTrack then
    return true
  end

  local info = debug.getinfo(1, "S")
  local this_path = info and info.source:match("^@(.+)$") or ""
  if this_path == "" then
    return false, "Konnte Script-Pfad nicht bestimmen."
  end
  local sep = package.config:sub(1,1)
  local base = this_path:match("^(.*"..sep..")") or ""
  if base == "" then
    return false, "Konnte Basisverzeichnis nicht bestimmen."
  end
  local engine_path = base .. "DF95_CategoryFX_Engine.lua"
  local f = io.open(engine_path, "r")
  if not f then
    return false, "DF95_CategoryFX_Engine.lua nicht gefunden neben diesem Script."
  end
  f:close()
  dofile(engine_path)
  if not DF95_CategoryFX_ApplyToTrack then
    return false, "DF95_CategoryFX_Engine.lua konnte nicht geladen werden."
  end
  return true
end



------------------------------------------------------------
-- ImGui Bootstrap
------------------------------------------------------------

local function ensure_imgui()
  if not r.ImGui_CreateContext then
    r.ShowMessageBox(
      "ReaImGui scheint nicht installiert zu sein.\n" ..
      "Bitte installiere 'ReaImGui: ReaScript binding for Dear ImGui' über ReaPack\n" ..
      "und starte REAPER neu.",
      "DF95 Modulation Panel Hub",
      0
    )
    return false
  end
  return true
end

if not ensure_imgui() then return end

local ctx = r.ImGui_CreateContext('DF95 Modulation Hub##IFLS', r.ImGui_ConfigFlags_DockingEnable())
local font = r.ImGui_CreateFont('sans-serif', 14.0)
r.ImGui_AttachFont(ctx, font)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function lower(s) return (s or ""):lower() end

local function clamp(x, lo, hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

local function track_category_from_name(track_name)
  local s = lower(track_name or "")

  if s:find("kick") or s:find("bd") or s:find("kck") then
    return "Kick"
  end
  if s:find("snare") or s:find("sd") then
    return "Snare"
  end
  if s:find("hat") or s:find("hihat") or s:find("hh") then
    if s:find("open") or s:find("op") then
      return "HihatOpen"
    else
      return "HihatClosed"
    end
  end
  if s:find("clap") then
    return "Clap"
  end
  if s:find("tom") then
    return "Tom"
  end
  if s:find("shaker") or s:find("shak") then
    return "Shaker"
  end
  if s:find("perc") or s:find("percussion") then
    return "Perc"
  end
  if s:find("fx") or s:find("rise") or s:find("impact") or s:find("whoosh") then
    return "FX"
  end
  if s:find("noise") or s:find("hiss") then
    return "Noise"
  end
  return "Misc"
end

------------------------------------------------------------
-- FX-Bus Management (wie im Modulate-Script, aber parametrisiert)
------------------------------------------------------------

local function find_or_create_mod_bus(category)
  local proj = 0
  local num_tracks = r.CountTracks(proj)
  local target_name = string.format("[IFLS Mod FX] %s", category)

  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetTrackName(tr)
    if name == target_name then
      return tr
    end
  end

  -- neuer Bus
  r.InsertTrackAtIndex(num_tracks, true)
  local bus = r.GetTrack(proj, num_tracks)
  r.GetSetMediaTrackInfo_String(bus, "P_NAME", target_name, true)

  local function add_fx(name)
    return r.TrackFX_AddByName(bus, name, false, -1)
  end

  if category == "Kick" then
    add_fx("ReaEQ (Cockos)")
    add_fx("JS: Saturation")
  elseif category == "Snare" then
    add_fx("ReaEQ (Cockos)")
    add_fx("ReaComp (Cockos)")
    add_fx("JS: LOSER/Exciter")
  elseif category == "HihatClosed" or category == "HihatOpen" then
    add_fx("ReaEQ (Cockos)")
    add_fx("JS: LOSER/Exciter")
  elseif category == "Tom" or category == "Perc" or category == "Shaker" then
    add_fx("ReaEQ (Cockos)")
    add_fx("ReaComp (Cockos)")
  elseif category == "FX" or category == "Noise" then
    add_fx("ReaEQ (Cockos)")
    add_fx("JS: Saturation")
  else
    add_fx("ReaEQ (Cockos)")
  end

  -- grobe EQ-Shapes
  local fx_count = r.TrackFX_GetCount(bus)
  for fx = 0, fx_count-1 do
    local _, fx_name = r.TrackFX_GetFXName(bus, fx, "")
    if fx_name:find("ReaEQ") then
      if category == "Kick" then
        r.TrackFX_SetParam(bus, fx, 2, 0.1)  -- Low-Freq
        r.TrackFX_SetParam(bus, fx, 3, 0.65) -- Low-Gain
      elseif category == "Snare" then
        r.TrackFX_SetParam(bus, fx, 2, 0.3)
      elseif category == "HihatClosed" or category == "HihatOpen" then
        r.TrackFX_SetParam(bus, fx, 2, 0.4)
      end
    end
  end

  return bus
end

local function ensure_send(src_tr, bus_tr, send_gain_db)
  if not src_tr or not bus_tr then return end
  local proj = 0
  local num_sends = r.GetTrackNumSends(src_tr, 0)
  for i = 0, num_sends-1 do
    local dest = r.BR_GetMediaTrackSendInfo_Track(src_tr, 0, i, 1)
    if dest == bus_tr then
      -- bestehenden Send einfach auf den neuen Gain setzen
      if send_gain_db then
        r.SetTrackSendInfo_Value(src_tr, 0, i, "D_VOL", 10^(send_gain_db / 20))
      end
      return
    end
  end
  local send_idx = r.CreateTrackSend(src_tr, bus_tr)
  local gain_db = send_gain_db or -6.0
  r.SetTrackSendInfo_Value(src_tr, 0, send_idx, "D_VOL", 10^(gain_db / 20))
end

------------------------------------------------------------
-- Modulation
------------------------------------------------------------

local function random_range(a, b)
  return a + (b - a) * math.random()
end

local function modulate_items_on_track(tr, cfg)
  local proj = 0
  local num_items = r.CountTrackMediaItems(proj, tr)
  if num_items == 0 then return 0 end

  local count = 0
  for i = 0, num_items-1 do
    local item = r.GetTrackMediaItem(tr, i)
    if item then
      count = count + 1

      -- Lautstärke
      if cfg.enable_vol then
        local vol = r.GetMediaItemInfo_Value(item, "D_VOL")
        local db_variation = random_range(cfg.vol_min_db, cfg.vol_max_db)
        local factor = 10^(db_variation / 20)
        local new_vol = vol * factor
        new_vol = clamp(new_vol, 0.02, 8.0)
        r.SetMediaItemInfo_Value(item, "D_VOL", new_vol)
      end

      -- Länge
      if cfg.enable_len then
        local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local len_factor = random_range(cfg.len_min_factor, cfg.len_max_factor)
        local new_len = len * len_factor
        new_len = math.max(0.005, new_len)
        r.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
      end

      -- Start-Jitter (in Sekunden)
      if cfg.enable_jitter then
        local start_offs = r.GetMediaItemInfo_Value(item, "D_STARTOFFS")
        local jitter_s = random_range(cfg.jitter_min_ms, cfg.jitter_max_ms) / 1000.0
        local new_offs = start_offs + jitter_s
        if new_offs < 0 then new_offs = 0 end
        r.SetMediaItemInfo_Value(item, "D_STARTOFFS", new_offs)
      end

      -- Fades
      if cfg.enable_fades then
        local fadein_s  = random_range(cfg.fadein_min_ms,  cfg.fadein_max_ms)  / 1000.0
        local fadeout_s = random_range(cfg.fadeout_min_ms, cfg.fadeout_max_ms) / 1000.0
        r.SetMediaItemInfo_Value(item, "D_FADEINLEN",  fadein_s)
        r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeout_s)
      end
    end
  end

  return count
end

------------------------------------------------------------
-- Presets
------------------------------------------------------------

local category_options = {
  "Auto", "Kick", "Snare", "HihatClosed", "HihatOpen",
  "Clap", "Tom", "Perc", "Shaker", "FX", "Noise", "Misc",
}

local presets = {
  Kick_Punchy = function(cfg)
    cfg.enable_vol       = true
    cfg.vol_min_db       = -2.0
    cfg.vol_max_db       = +3.0
    cfg.enable_len       = true
    cfg.len_min_factor   = 0.9
    cfg.len_max_factor   = 1.1
    cfg.enable_jitter    = true
    cfg.jitter_min_ms    = -3
    cfg.jitter_max_ms    = +3
    cfg.enable_fades     = true
    cfg.fadein_min_ms    = 0.5
    cfg.fadein_max_ms    = 4
    cfg.fadeout_min_ms   = 2
    cfg.fadeout_max_ms   = 12
    cfg.send_gain_db     = -4
  end,

  Snare_Dusty = function(cfg)
    cfg.enable_vol       = true
    cfg.vol_min_db       = -4.0
    cfg.vol_max_db       = +2.0
    cfg.enable_len       = true
    cfg.len_min_factor   = 0.85
    cfg.len_max_factor   = 1.15
    cfg.enable_jitter    = true
    cfg.jitter_min_ms    = -5
    cfg.jitter_max_ms    = +7
    cfg.enable_fades     = true
    cfg.fadein_min_ms    = 1
    cfg.fadein_max_ms    = 8
    cfg.fadeout_min_ms   = 5
    cfg.fadeout_max_ms   = 30
    cfg.send_gain_db     = -6
  end,

  Hats_LoFi = function(cfg)
    cfg.enable_vol       = true
    cfg.vol_min_db       = -5.0
    cfg.vol_max_db       = +1.0
    cfg.enable_len       = true
    cfg.len_min_factor   = 0.7
    cfg.len_max_factor   = 1.1
    cfg.enable_jitter    = true
    cfg.jitter_min_ms    = -8
    cfg.jitter_max_ms    = +8
    cfg.enable_fades     = true
    cfg.fadein_min_ms    = 0.5
    cfg.fadein_max_ms    = 5
    cfg.fadeout_min_ms   = 10
    cfg.fadeout_max_ms   = 60
    cfg.send_gain_db     = -8
  end,

  FX_Wild = function(cfg)
    cfg.enable_vol       = true
    cfg.vol_min_db       = -8.0
    cfg.vol_max_db       = +6.0
    cfg.enable_len       = true
    cfg.len_min_factor   = 0.5
    cfg.len_max_factor   = 1.5
    cfg.enable_jitter    = true
    cfg.jitter_min_ms    = -20
    cfg.jitter_max_ms    = +20
    cfg.enable_fades     = true
    cfg.fadein_min_ms    = 0.5
    cfg.fadein_max_ms    = 10
    cfg.fadeout_min_ms   = 20
    cfg.fadeout_max_ms   = 200
    cfg.send_gain_db     = -10
  end,
}

local function apply_preset(name, cfg)
  local fn = presets[name]
  if fn then
    fn(cfg)
  end
end

------------------------------------------------------------
-- UI State
------------------------------------------------------------

local state = {
  selected_category_idx = 0, -- 0 = Auto
  cfg = {
    enable_vol       = true,
    vol_min_db       = -3.0,
    vol_max_db       = +3.0,

    enable_len       = true,
    len_min_factor   = 0.85,
    len_max_factor   = 1.15,

    enable_jitter    = true,
    jitter_min_ms    = -5,
    jitter_max_ms    = +5,

    enable_fades     = true,
    fadein_min_ms    = 0.5,
    fadein_max_ms    = 5,
    fadeout_min_ms   = 3,
    fadeout_max_ms   = 20,

    send_gain_db     = -6,
  },
    user_preset_slot   = 1, -- 1..4
    last_track_guid   = nil,
    last_effective_category = nil,
}

------------------------------------------------------------
-- User Presets (ExtState-basiert)
------------------------------------------------------------

local MODHUB_EXT_NS = "IFLS_ModulationHub"

local function encode_cfg(cfg)
  local parts = {
    cfg.enable_vol and "1" or "0",
    tostring(cfg.vol_min_db or 0),
    tostring(cfg.vol_max_db or 0),
    cfg.enable_len and "1" or "0",
    tostring(cfg.len_min_factor or 1.0),
    tostring(cfg.len_max_factor or 1.0),
    cfg.enable_jitter and "1" or "0",
    tostring(cfg.jitter_min_ms or 0),
    tostring(cfg.jitter_max_ms or 0),
    cfg.enable_fades and "1" or "0",
    tostring(cfg.fadein_min_ms or 0),
    tostring(cfg.fadein_max_ms or 0),
    tostring(cfg.fadeout_min_ms or 0),
    tostring(cfg.fadeout_max_ms or 0),
    tostring(cfg.send_gain_db or -6),
  }
  return table.concat(parts, "|")
end

local function decode_cfg(str, cfg)
  if not str or str == "" then return false end
  local fields = {}
  for part in string.gmatch(str, "([^|]+)") do
    fields[#fields+1] = part
  end
  local function tobool(v) return v == "1" end
  local function tonumber_safe(v, default)
    local n = tonumber(v)
    if not n then return default end
    return n
  end
  cfg.enable_vol       = tobool(fields[1]  or "1")
  cfg.vol_min_db       = tonumber_safe(fields[2],  -3)
  cfg.vol_max_db       = tonumber_safe(fields[3],   3)
  cfg.enable_len       = tobool(fields[4]  or "1")
  cfg.len_min_factor   = tonumber_safe(fields[5], 0.85)
  cfg.len_max_factor   = tonumber_safe(fields[6], 1.15)
  cfg.enable_jitter    = tobool(fields[7]  or "1")
  cfg.jitter_min_ms    = tonumber_safe(fields[8],  -5)
  cfg.jitter_max_ms    = tonumber_safe(fields[9],   5)
  cfg.enable_fades     = tobool(fields[10] or "1")
  cfg.fadein_min_ms    = tonumber_safe(fields[11], 0.5)
  cfg.fadein_max_ms    = tonumber_safe(fields[12], 5.0)
  cfg.fadeout_min_ms   = tonumber_safe(fields[13], 3.0)
  cfg.fadeout_max_ms   = tonumber_safe(fields[14], 20.0)
  cfg.send_gain_db     = tonumber_safe(fields[15], -6.0)
  return true
end

local function save_user_preset(slot, cfg)
  local key = string.format("user_preset_%d", slot)
  r.SetExtState(MODHUB_EXT_NS, key, encode_cfg(cfg), true)
end

local function load_user_preset(slot, cfg)
  local key = string.format("user_preset_%d", slot)
  local s = r.GetExtState(MODHUB_EXT_NS, key)
  if not s or s == "" then return false end
  return decode_cfg(s, cfg)
end

local function clear_user_preset(slot)
  local key = string.format("user_preset_%d", slot)
  r.DeleteExtState(MODHUB_EXT_NS, key, true)
end

------------------------------------------------------------
-- Hauptaktion: Modulate Now
------------------------------------------------------------

local function do_modulate()
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox(
      "Kein Track ausgewählt.\nBitte wähle den Slices-Track aus und versuche es erneut.",
      "DF95 Modulation Hub",
      0
    )
    return
  end

  local _, track_name = r.GetTrackName(tr)
  local auto_cat = track_category_from_name(track_name)
  local ui_cat = category_options[state.selected_category_idx + 1] or "Auto"

  local category
  if ui_cat == "Auto" then
    category = auto_cat
  else
    category = ui_cat
  end
  if not category or category == "" then category = "Misc" end

  r.Undo_BeginBlock()

  local bus = find_or_create_mod_bus(category)
  ensure_send(tr, bus, state.cfg.send_gain_db or -6)

  -- Optional: Category-FX-Engine anwenden (Phase 113/114)
  if state.cfg.use_category_fx then
    local ok, err = DF95_ModHub_EnsureCategoryFXEngine()
    if ok and DF95_CategoryFX_ApplyToTrack then
      local intensity = state.cfg.category_fx_intensity or "medium"
      DF95_CategoryFX_ApplyToTrack(bus, category, intensity)
    else
      -- nur warnen, nicht abbrechen
      msg("Category FX Engine konnte nicht geladen werden: " .. tostring(err or "?"))
    end
  end


  local cfg = state.cfg
  local num = modulate_items_on_track(tr, cfg)

  r.Undo_EndBlock(
    string.format("DF95 Modulation Hub: %s (%d slices)", category, num),
    -1
  )

  if num == 0 then
    r.ShowMessageBox(
      "Keine Media Items auf dem ausgewählten Track gefunden.\n" ..
      "Bitte stelle sicher, dass dort deine Slices liegen.",
      "DF95 Modulation Hub",
      0
    )
  else
    r.ShowMessageBox(
      string.format(
        "Modulation abgeschlossen.\nTrack: %s\nKategorie: %s\nSlices: %d",
        track_name, category, num
      ),
      "DF95 Modulation Hub",
      0
    )
  end
end

------------------------------------------------------------
-- UI Rendering
------------------------------------------------------------

local function draw_category_section()
  r.ImGui_Text(ctx, "Track / Kategorie")
  local tr = r.GetSelectedTrack(0, 0)
  if tr then
    local _, name = r.GetTrackName(tr)
    r.ImGui_Text(ctx, "Aktueller Track: " .. (name or "<unbenannt>"))

    local auto_cat = track_category_from_name(name)
    r.ImGui_Text(ctx, "Auto-Kategorie: " .. (auto_cat or "Misc"))
  else
    r.ImGui_Text(ctx, "Kein Track ausgewählt.")
  end

  -- Kategorie-Override
  local current_idx = state.selected_category_idx
  if r.ImGui_BeginCombo(ctx, "Kategorie", category_options[current_idx + 1]) then
    for i, label in ipairs(category_options) do
      local is_selected = (i-1 == current_idx)
      if r.ImGui_Selectable(ctx, label, is_selected) then
        state.selected_category_idx = i-1
      end
      if is_selected then
        r.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    r.ImGui_EndCombo(ctx)
  end
end

local function draw_preset_section()
  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Presets")
  if r.ImGui_Button(ctx, "Kick – Punchy") then
    apply_preset("Kick_Punchy", state.cfg)
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Snare – Dusty") then
    apply_preset("Snare_Dusty", state.cfg)
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Hats – LoFi") then
    apply_preset("Hats_LoFi", state.cfg)
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "FX – Wild") then
    apend

local function draw_user_presets_section()
  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "User Presets (pro Projekt gespeichert)")
  local labels = { "Slot 1", "Slot 2", "Slot 3", "Slot 4" }
  local current = state.user_preset_slot or 1
  local disp = labels[current] or labels[1]
  if r.ImGui_BeginCombo(ctx, "User Preset Slot", disp) then
    for i = 1, #labels do
      local is_sel = (i == current)
      if r.ImGui_Selectable(ctx, labels[i], is_sel) then
        state.user_preset_slot = i
        current = i
      end
      if is_sel then r.ImGui_SetItemDefaultFocus(ctx) end
    end
    r.ImGui_EndCombo(ctx)
  end

  if r.ImGui_Button(ctx, "Slot laden") then
    if not load_user_preset(current, state.cfg) then
      msg(string.format("Kein User-Preset in Slot %d gefunden.", current))
    end
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Slot speichern") then
    save_user_preset(current, state.cfg)
    msg(string.format("User-Preset in Slot %d gespeichert.", current))
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Slot leeren") then
    clear_user_preset(current)
    msg(string.format("User-Preset Slot %d geleert.", current))
  end
end


local function draw_modulation_section()
  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Modulations-Intensität")

  -- Category FX Engine
  r.ImGui_Separator(ctx)
  local changed
  state.cfg.use_category_fx, changed = r.ImGui_Checkbox(ctx, "Kategorie-FX-Engine verwenden", state.cfg.use_category_fx)
  if state.cfg.use_category_fx then
    r.ImGui_Indent(ctx)
    local current_intensity = state.cfg.category_fx_intensity or "medium"
    if r.ImGui_BeginCombo(ctx, "FX-Intensität", current_intensity) then
      local labels = { "subtle", "medium", "extreme" }
      for i = 1, #labels do
        local lbl = labels[i]
        local is_selected = (lbl == current_intensity)
        if r.ImGui_Selectable(ctx, lbl, is_selected) then
          current_intensity = lbl
        end
        if is_selected then
          r.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      r.ImGui_EndCombo(ctx)
    end
    state.cfg.category_fx_intensity = current_intensity
    r.ImGui_Unindent(ctx)
  end


  -- Volume
  local changed
  state.cfg.enable_vol, changed = r.ImGui_Checkbox(ctx, "Lautstärke variieren (dB)", state.cfg.enable_vol)
  if state.cfg.enable_vol then
    r.ImGui_Indent(ctx)
    local val_min = state.cfg.vol_min_db
    local val_max = state.cfg.vol_max_db
    changed, val_min, val_max = r.ImGui_DragFloatRange2(ctx,
      "dB Range", val_min, val_max, 0.1, -24.0, 24.0, "%.1f dB")
    if changed then
      state.cfg.vol_min_db = val_min
      state.cfg.vol_max_db = val_max
    end
    r.ImGui_Unindent(ctx)
  end

  -- Length
  state.cfg.enable_len, changed = r.ImGui_Checkbox(ctx, "Länge variieren (%)", state.cfg.enable_len)
  if state.cfg.enable_len then
    r.ImGui_Indent(ctx)
    local val_min = state.cfg.len_min_factor * 100.0
    local val_max = state.cfg.len_max_factor * 100.0
    changed, val_min, val_max = r.ImGui_DragFloatRange2(ctx,
      "Länge %", val_min, val_max, 0.5, 10.0, 200.0, "%.1f %%")
    if changed then
      state.cfg.len_min_factor = clamp(val_min / 100.0, 0.1, 4.0)
      state.cfg.len_max_factor = clamp(val_max / 100.0, 0.1, 4.0)
    end
    r.ImGui_Unindent(ctx)
  end

  -- Jitter
  state.cfg.enable_jitter, changed = r.ImGui_Checkbox(ctx, "Start-Jitter (ms)", state.cfg.enable_jitter)
  if state.cfg.enable_jitter then
    r.ImGui_Indent(ctx)
    local val_min = state.cfg.jitter_min_ms
    local val_max = state.cfg.jitter_max_ms
    changed, val_min, val_max = r.ImGui_DragFloatRange2(ctx,
      "Jitter", val_min, val_max, 0.1, -100.0, 100.0, "%.1f ms")
    if changed then
      state.cfg.jitter_min_ms = val_min
      state.cfg.jitter_max_ms = val_max
    end
    r.ImGui_Unindent(ctx)
  end

  -- Fades
  state.cfg.enable_fades, changed = r.ImGui_Checkbox(ctx, "Fades variieren (ms)", state.cfg.enable_fades)
  if state.cfg.enable_fades then
    r.ImGui_Indent(ctx)
    local fi_min = state.cfg.fadein_min_ms
    local fi_max = state.cfg.fadein_max_ms
    changed, fi_min, fi_max = r.ImGui_DragFloatRange2(ctx,
      "Fade-In", fi_min, fi_max, 0.1, 0.0, 100.0, "%.1f ms")
    if changed then
      state.cfg.fadein_min_ms = fi_min
      state.cfg.fadein_max_ms = fi_max
    end

    local fo_min = state.cfg.fadeout_min_ms
    local fo_max = state.cfg.fadeout_max_ms
    changed, fo_min, fo_max = r.ImGui_DragFloatRange2(ctx,
      "Fade-Out", fo_min, fo_max, 0.1, 0.0, 500.0, "%.1f ms")
    if changed then
      state.cfg.fadeout_min_ms = fo_min
      state.cfg.fadeout_max_ms = fo_max
    end
    r.ImGui_Unindent(ctx)
  end

  r.ImGui_Separator(ctx)
  local gain = state.cfg.send_gain_db
  changed, gain = r.ImGui_SliderFloat(ctx, "FX-Bus Send Gain (dB)", gain, -24.0, 0.0, "%.1f dB")
  if changed then
    state.cfg.send_gain_db = gain
  end
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------


------------------------------------------------------------
-- Auto-Defaults: Kategorie-Presets und Track-basierte User-Slots
------------------------------------------------------------

local function apply_default_preset_for_category(cat, cfg)
  if not cat or cat == "" then return end
  if cat == "Kick" then
    if presets.Kick_Punchy then presets.Kick_Punchy(cfg) end
  elseif cat == "Snare" then
    if presets.Snare_Dusty then presets.Snare_Dusty(cfg) end
  elseif cat == "HihatClosed" or cat == "HihatOpen" then
    if presets.Hats_LoFi then presets.Hats_LoFi(cfg) end
  elseif cat == "FX" or cat == "Noise" then
    if presets.FX_Wild then presets.FX_Wild(cfg) end
  else
    -- für Perc/Tom/Shaker/Misc lassen wir einfach die aktuellen Werte
    -- oder das zuletzt gesetzte Preset stehen.
  end
end

local function default_slot_for_track_name(track_name)
  local s = lower(track_name or "")
  if s:find("kick") or s:find("bd") or s:find("kck") then
    return 1
  elseif s:find("snare") or s:find("sd") then
    return 2
  elseif s:find("hat") or s:find("hihat") or s:find("hh") then
    return 3
  elseif s:find("perc") or s:find("tom") or s:find("shaker") or s:find("fx") or s:find("noise") then
    return 4
  else
    return 1
  end
end

local function update_auto_defaults()
  local tr = r.GetSelectedTrack(0, 0)
  local track_guid = nil
  local track_name = ""
  if tr then
    track_guid = r.GetTrackGUID(tr)
    local _, tn = r.GetTrackName(tr)
    track_name = tn or ""
  end

  local auto_cat = track_category_from_name(track_name)
  local ui_cat   = category_options[state.selected_category_idx + 1] or "Auto"
  local effective_cat
  if ui_cat == "Auto" then
    effective_cat = auto_cat or "Misc"
  else
    effective_cat = ui_cat
  end

  local track_changed = (track_guid ~= state.last_track_guid)
  local cat_changed   = (effective_cat ~= state.last_effective_category)

  if track_changed then
    state.last_track_guid = track_guid

    local slot = default_slot_for_track_name(track_name)
    state.user_preset_slot = slot

    -- Versuche, User-Preset für diesen Slot zu laden.
    -- Wenn keiner existiert, fallback auf Kategorie-Default.
    if not load_user_preset(slot, state.cfg) then
      apply_default_preset_for_category(effective_cat, state.cfg)
    end

    state.last_effective_category = effective_cat

  elseif cat_changed then
    -- Kategorie wurde manuell gewechselt → Standardpreset für neue Kategorie setzen
    apply_default_preset_for_category(effective_cat, state.cfg)
    state.last_effective_category = effective_cat
  end
end

local function loop()
  update_auto_defaults()

  r.ImGui_PushFont(ctx, font)
  local visible, open = r.ImGui_Begin(ctx, "DF95 Modulation Panel Hub##IFLS", true,
    r.ImGui_WindowFlags_NoCollapse())
  if visible then
    draw_category_section()
    draw_preset_section()
    draw_user_presets_section()
    draw_modulation_section()

    r.ImGui_Separator(ctx)
    if r.ImGui_Button(ctx, "Modulate Now") then
      math.randomseed(os.time())
      do_modulate()
    end
    r.ImGui_SameLine(ctx)
    r.ImGui_TextDisabled(ctx, "Hinweis: wirkt auf den aktuell ausgewählten Track (alle Slices-Items).")

    r.ImGui_End(ctx)
  end
  r.ImGui_PopFont(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)
