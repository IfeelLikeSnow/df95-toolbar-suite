-- @description DF95_V109_TimeSignatureEngine_MeterPanel
-- @version 1.1
-- @author DF95
-- @about
--   Time Signature / Meter Panel für das DF95 Artist+Style / Euclid / Adaptive Beat System.
--
--   Dieses Script:
--     * erlaubt dir, eine echte Taktart zu wählen (z.B. 3/4, 5/4, 5/8, 7/8, 9/8, 12/8, 17/8, 19/8, ...),
--     * speichert Zähler (Numerator) & Nenner (Denominator) nach DF95_TIME/*,
--     * berechnet daraus eine interne Grid-Länge (BAR_STEPS),
--     * kann die Euclid-Engine (DF95_EUCLID_MULTI/STEPS) an dieses Meter binden,
--     * definiert einen "Meter Mode" für die BeatEngine (ArtistOnly / EuclidOnly / Hybrid),
--     * kann auf Wunsch die Projekt-Taktart direkt in REAPER setzen.
--
--   Empfohlener Workflow:
--     1. V109 starten, gewünschte Taktart und Meter Mode wählen,
--     2. optional: Artist & Tempo in V108 setzen (Slow/Medium/Fast),
--     3. V106 (Permissions) und V105 (Adaptive) verwenden,
--     4. V107 BeatEngine starten (nutzt Projekt-Tempo + Euclid-Grid + Artist-Kontext).
--

local r = reaper
local ImGui = r.ImGui
if not ImGui then
  r.ShowMessageBox("ReaImGui ist nicht verfügbar. Bitte ReaImGui Extension installieren.", "DF95 V109", 0)
  return
end

local ctx = ImGui.CreateContext('DF95 V109 Time Signature Engine')

------------------------------------------------------------
-- ExtState Helpers
------------------------------------------------------------

local function get_ext(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if not v or v == "" then return default end
  return v
end

local function set_ext(section, key, value)
  r.SetProjExtState(0, section, key, tostring(value or ""))
end

local function get_ext_num(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  local n = tonumber(v)
  if not n then return default end
  return n
end

------------------------------------------------------------
-- Meter Mode
------------------------------------------------------------

local meter_modes = {
  "Artist+Euclid (Hybrid)",
  "Artist only",
  "Euclid only",
}

local function mode_index_from_name(name)
  if name == "Artist only" then return 1 end
  if name == "Euclid only" then return 2 end
  return 0
end

local function mode_name_from_index(idx)
  if idx == 1 then return "Artist only" end
  if idx == 2 then return "Euclid only" end
  return "Artist+Euclid (Hybrid)"
end

------------------------------------------------------------
-- Main ImGui Loop
------------------------------------------------------------

local function loop()
  ImGui.SetNextWindowSize(ctx, 520, 420, ImGui.Cond_FirstUseEver())
  local visible, open = ImGui.Begin(ctx, 'DF95 V109 Time Signature / Meter Engine', true)
  if visible then
    -- Read current context
    local artist = get_ext("DF95_ARTIST", "NAME", "Aphex Twin")
    local style  = get_ext("DF95_STYLE",  "NAME", "Neutral")

    ImGui.Text(ctx, "Context")
    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Artist: " .. artist)
    ImGui.Text(ctx, "Style:  " .. style)

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Taktart / Time Signature")

    -- Numerator
    local num = get_ext_num("DF95_TIME", "NUMERATOR", 4)
    if num < 2 then num = 2 end
    if num > 32 then num = 32 end
    local changed, new_num = ImGui.SliderInt(ctx, "Zähler (Numerator)", num, 2, 32)
    if changed then
      num = new_num
      set_ext("DF95_TIME", "NUMERATOR", num)
    end

    -- Denominator
    local denom_current = get_ext("DF95_TIME", "DENOMINATOR", "1/4")
    local denom_options = { "1/4", "1/8", "1/16" }
    local denom_index = 1
    for i, d in ipairs(denom_options) do
      if d == denom_current then
        denom_index = i
        break
      end
    end

    if ImGui.BeginCombo(ctx, "Nenner (Denominator)", denom_options[denom_index]) then
      for i, d in ipairs(denom_options) do
        local selected = (i == denom_index)
        if ImGui.Selectable(ctx, d, selected) then
          denom_index = i
          denom_current = d
          set_ext("DF95_TIME", "DENOMINATOR", denom_current)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    -- BAR_STEPS Berechnung
    local factor = 4
    if denom_current == "1/8" then
      factor = 2
    elseif denom_current == "1/16" then
      factor = 1
    end

    local bar_steps = num * (16 / factor)
    bar_steps = math.floor(bar_steps + 0.5)
    if bar_steps < 1 then bar_steps = 1 end

    
    ImGui.Text(ctx, "(Beispiele: 12/8 → 24 Steps, 17/8 → 34 Steps, 7/4 → 28 Steps, 3/8 → 6 Steps usw.)")
    set_ext("DF95_TIME", "BAR_STEPS", bar_steps)

    -- Anzahl der zu generierenden Takte für die BeatEngine
    local bars = get_ext_num("DF95_TIME", "BARS", 4)
    if bars < 1 then bars = 1 end
    if bars > 32 then bars = 32 end
    local changed_bars
    changed_bars, bars = ImGui.SliderInt(ctx, "Anzahl Takte (BeatEngine)", bars, 1, 32)
    if changed_bars then
      set_ext("DF95_TIME", "BARS", bars)
    end
    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Meter Mode für BeatEngine")

    local current_mode_name = get_ext("DF95_TIME", "MODE", "Artist+Euclid (Hybrid)")
    local mode_idx = mode_index_from_name(current_mode_name)

    local combo_label = meter_modes[mode_idx+1] or "Artist+Euclid (Hybrid)"
    if ImGui.BeginCombo(ctx, "Meter Mode", combo_label) then
      for i, name in ipairs(meter_modes) do
        local selected = (i-1 == mode_idx)
        if ImGui.Selectable(ctx, name, selected) then
          mode_idx = i-1
          current_mode_name = mode_name_from_index(mode_idx)
          set_ext("DF95_TIME", "MODE", current_mode_name)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Euclid-Bindung")

    local lock_euclid = get_ext("DF95_TIME", "LOCK_EUCLID_TO_METER", "1") == "1"
    local changed_lock
    changed_lock, lock_euclid = ImGui.Checkbox(ctx, "Euclid Steps an Taktart koppeln (DF95_EUCLID_MULTI/STEPS = BAR_STEPS)", lock_euclid)
    if changed_lock then
      set_ext("DF95_TIME", "LOCK_EUCLID_TO_METER", lock_euclid and "1" or "0")
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Aktionen")

    if ImGui.Button(ctx, "Taktart + Euclid anwenden (Projekt-Takt setzen)") then
      -- DF95_TIME ExtStates aktualisieren
      set_ext("DF95_TIME", "NUMERATOR", num)
      set_ext("DF95_TIME", "DENOMINATOR", denom_current)
      set_ext("DF95_TIME", "BAR_STEPS", bar_steps)
      set_ext("DF95_TIME", "MODE", current_mode_name)

      -- Euclid Steps setzen, wenn gekopppelt
      if lock_euclid then
        set_ext("DF95_EUCLID_MULTI", "STEPS", bar_steps)
        -- Division: aus Denominator ableiten, falls noch nicht gesetzt
        local div = get_ext("DF95_EUCLID_MULTI", "DIVISION", "")
        if div == "" then
          if denom_current == "1/4" then
            div = "1/4"
          elseif denom_current == "1/8" then
            div = "1/8"
          else
            div = "1/16"
          end
          set_ext("DF95_EUCLID_MULTI", "DIVISION", div)
        end
      end

      -- Projekt-Taktart setzen
      local proj = 0
      -- SetProjectTimeSignature2(proj, time_sig_num, time_sig_denom, wantUndo)
      local denom_val = 4
      if denom_current == "1/8" then denom_val = 8 end
      if denom_current == "1/16" then denom_val = 16 end
      r.SetProjectTimeSignature2(proj, num, denom_val, true)

      local msg = string.format("Taktart gesetzt: %d%s\nBAR_STEPS: %d\nMeter Mode: %s\nEuclid gekoppelt: %s",
        num, denom_current, bar_steps, current_mode_name, lock_euclid and "Ja" or "Nein")
      r.ShowMessageBox(msg, "DF95 V109 – Takt & Euclid angewendet", 0)
    end

    if ImGui.Button(ctx, "Nur ExtStates setzen (Projekt-Takt unverändert)") then
      set_ext("DF95_TIME", "NUMERATOR", num)
      set_ext("DF95_TIME", "DENOMINATOR", denom_current)
      set_ext("DF95_TIME", "BAR_STEPS", bar_steps)
      set_ext("DF95_TIME", "MODE", current_mode_name)
      if lock_euclid then
        set_ext("DF95_EUCLID_MULTI", "STEPS", bar_steps)
      end
      local msg = string.format("ExtStates aktualisiert:\nNUMERATOR=%d, DENOMINATOR=%s, BAR_STEPS=%d, MODE=%s",
        num, denom_current, bar_steps, current_mode_name)
      r.ShowMessageBox(msg, "DF95 V109 – ExtStates gesetzt", 0)
    end

    ImGui.Separator(ctx)
    ImGui.TextWrapped(ctx,
      "Hinweise:\n" ..
      "- Zuerst Taktart hier wählen (z.B. 5/8, 7/8, 12/8, 17/8, 19/8, 3/4, 5/4, 7/4 ...).\n" ..
      "- Dann Artist & Tempo in V108 wählen (Slow/Medium/Fast pro Artist).\n" ..
      "- V109 definiert damit das zeitliche Raster, V107 nutzt dieses Raster,\n" ..
      "  um Artist-Patterns/Euclid/Adaptive Beats darauf abzubilden.")

    ImGui.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

r.defer(loop)
