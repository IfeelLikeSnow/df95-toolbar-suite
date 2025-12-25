-- @description DF95_V108_ArtistTempoProfiles_TempoAndEuclidPanel
-- @version 1.0
-- @author DF95
-- @about
--   Artist-spezifisches Tempo-Profil (Slow/Medium/Fast) + Euclid-Grid-Setup
--   für das DF95 Fieldrec/Artist/Euclid/Adaptive-System.
--
--   Dieses Script:
--     * kennt vordefinierte BPM-Zonen pro Artist (Slow / Medium / Fast),
--       basierend auf typischen BPM-Clustern der jeweiligen Diskographie,
--     * liest den aktuellen Artist aus DF95_ARTIST/NAME,
--     * erlaubt die Auswahl von Tempo-Mode (Slow/Medium/Fast),
--     * kann das Projekt-Tempo automatisch darauf setzen,
--     * erlaubt die Konfiguration des Euclid-Grids (STEPS & DIVISION),
--     * schreibt alle Einstellungen in Project-ExtStates:
--         - DF95_ARTIST/TEMPO_MODE
--         - DF95_ARTIST/TEMPO_BPM
--         - DF95_EUCLID_MULTI/STEPS
--         - DF95_EUCLID_MULTI/DIVISION
--
--   Empfehlung:
--     1. Artist & Style im Artist/Style-Panel setzen (z.B. V101/V102 Layer),
--     2. dieses Panel (V108) aufrufen, Slow/Medium/Fast & Euclid einstellen,
--     3. dann V107_Fieldrec_AdaptiveBeatEngine_MIDI starten.
--

local r = reaper
local ImGui = r.ImGui
if not ImGui then
  r.ShowMessageBox("ReaImGui ist nicht verfügbar. Bitte Extension installieren.", "DF95 V108", 0)
  return
end

local ctx = ImGui.CreateContext('DF95 V108 Artist Tempo Profiles')

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
-- Artist Tempo Profile Table
------------------------------------------------------------

-- BPM-Werte sind bewusst "typische Zonen" und keine exakten Track-Analysen.
-- Sie basieren auf Genre-Kontext, veröffentlichten BPM-Analysen (SongBPM,
-- Album-BPM-Profile, DnB-Tempo-Ranges etc.) und sind als musikalisch sinnvolle
-- Startpunkte gedacht, nicht als harte Norm.

local tempo_profiles = {
  ["Aphex Twin"] =       { slow = 100, medium = 130, fast = 170 },
  ["Autechre"] =         { slow =  90, medium = 120, fast = 160 },
  ["Boards of Canada"] = { slow =  78, medium =  92, fast = 105 },
  ["Squarepusher"] =     { slow = 140, medium = 170, fast = 190 },
  ["Î¼-ziq"] =     { slow = 120, medium = 150, fast = 180 },
  ["µ-ziq"] =            { slow = 120, medium = 150, fast = 180 },
  ["Apparat"] =          { slow = 100, medium = 120, fast = 140 },
  ["Arovane"] =          { slow =  80, medium = 100, fast = 120 },
  ["Björk"] =            { slow =  80, medium = 100, fast = 120 },
  ["Bochum Welt"] =      { slow = 100, medium = 125, fast = 150 },
  ["Bogdan Raczynski"] = { slow = 150, medium = 180, fast = 200 },
  ["Burial"] =           { slow =  80, medium = 130, fast = 140 },
  ["Cylob"] =            { slow = 110, medium = 140, fast = 175 },
  ["DMX Krew"] =         { slow = 110, medium = 125, fast = 135 },
  ["Flying Lotus"] =     { slow =  80, medium = 105, fast = 130 },
  ["Four Tet"] =         { slow =  90, medium = 120, fast = 130 },
  ["The Future Sound Of London"] = { slow =  80, medium = 110, fast = 130 },
  ["I am Robot and Proud"] = { slow =  90, medium = 110, fast = 130 },
  ["Isan"] =             { slow =  70, medium =  90, fast = 110 },
  ["Jan Jelinek"] =      { slow =  80, medium =  95, fast = 110 },
  ["Jega"] =             { slow = 120, medium = 145, fast = 170 },
  ["Legowelt"] =         { slow = 120, medium = 128, fast = 140 },
  ["Matmos"] =           { slow =  90, medium = 115, fast = 140 },
  ["Moderat"] =          { slow = 110, medium = 120, fast = 130 },
  ["Photek"] =           { slow = 150, medium = 170, fast = 180 },
  ["Plaid"] =            { slow =  90, medium = 115, fast = 130 },
  ["Skylab"] =           { slow =  80, medium =  90, fast = 100 },
  ["Telefon Tel Aviv"] = { slow =  85, medium = 105, fast = 125 },
  ["Thom Yorke"] =       { slow =  80, medium = 100, fast = 120 },
  ["Tim Hecker"] =       { slow =  70, medium =  80, fast =  90 },
  ["Proem"] =            { slow =  90, medium = 110, fast = 130 },
}

local function get_profile_for_artist(artist)
  local prof = tempo_profiles[artist]
  if prof then return prof end
  -- Default-Profil für unbekannte Artists
  return { slow =  90, medium = 120, fast = 140 }
end

------------------------------------------------------------
-- UI State
------------------------------------------------------------

local tempo_modes = { "Slow", "Medium", "Fast" }

local function mode_index_from_name(name)
  if name == "Slow" then return 0 end
  if name == "Fast" then return 2 end
  return 1 -- default: Medium
end

local function mode_name_from_index(idx)
  if idx == 0 then return "Slow" end
  if idx == 2 then return "Fast" end
  return "Medium"
end

------------------------------------------------------------
-- Main ImGui Loop
------------------------------------------------------------

local function loop()
  ImGui.SetNextWindowSize(ctx, 520, 420, ImGui.Cond_FirstUseEver())
  local visible, open = ImGui.Begin(ctx, 'DF95 V108 Artist Tempo Profiles', true)
  if visible then
    -- Artist Context
    local artist = get_ext("DF95_ARTIST", "NAME", "Aphex Twin")
    local style  = get_ext("DF95_STYLE",  "NAME", "Neutral")
    local prof   = get_profile_for_artist(artist)

    ImGui.Text(ctx, "Artist Context")
    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Artist: " .. artist)
    ImGui.Text(ctx, "Style:  " .. style)

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Tempo-Profil (Artist-spezifische BPM-Zonen)")

    local current_mode_name = get_ext("DF95_ARTIST", "TEMPO_MODE", "Medium")
    local current_idx = mode_index_from_name(current_mode_name)

    -- Combo für Mode
    local combo_label = tempo_modes[current_idx+1] or "Medium"
    if ImGui.BeginCombo(ctx, "Tempo Mode", combo_label) then
      for i, name in ipairs(tempo_modes) do
        local is_selected = (i-1 == current_idx)
        if ImGui.Selectable(ctx, name, is_selected) then
          current_idx = i-1
          current_mode_name = mode_name_from_index(current_idx)
          set_ext("DF95_ARTIST", "TEMPO_MODE", current_mode_name)
        end
        if is_selected then
          ImGui.SetItemDefaultFocus(ctx)
        end
      end
      ImGui.EndCombo(ctx)
    end

    local target_bpm = prof.medium
    if current_mode_name == "Slow" then target_bpm = prof.slow end
    if current_mode_name == "Fast" then target_bpm = prof.fast end

    ImGui.Text(ctx, string.format("Vorgeschlagenes Tempo: %.1f BPM", target_bpm))

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Euclid Grid (für V104/V107)")

    local steps = get_ext_num("DF95_EUCLID_MULTI", "STEPS", 16)
    if steps < 1 then steps = 16 end
    local changed, new_steps = ImGui.SliderInt(ctx, "Steps pro Takt", steps, 3, 32)
    if changed then
      steps = new_steps
      set_ext("DF95_EUCLID_MULTI", "STEPS", steps)
    end

    local div_current = get_ext("DF95_EUCLID_MULTI", "DIVISION", "1/16")
    local divisions = { "1/4", "1/8", "1/16", "1/12" }
    local div_index = 1
    for i, d in ipairs(divisions) do
      if d == div_current then div_index = i break end
    end
    if ImGui.BeginCombo(ctx, "Notenwert (Division)", divisions[div_index]) then
      for i, d in ipairs(divisions) do
        local selected = (i == div_index)
        if ImGui.Selectable(ctx, d, selected) then
          div_index = i
          div_current = d
          set_ext("DF95_EUCLID_MULTI", "DIVISION", div_current)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Aktionen")

    if ImGui.Button(ctx, "Tempo & Euclid anwenden (Projekt BPM setzen)") then
      -- Tempo
      set_ext("DF95_ARTIST", "TEMPO_MODE", current_mode_name)
      set_ext("DF95_ARTIST", "TEMPO_BPM", target_bpm)
      -- Euclid
      set_ext("DF95_EUCLID_MULTI", "STEPS", steps)
      set_ext("DF95_EUCLID_MULTI", "DIVISION", div_current)
      -- Projekt-Tempo setzen
      r.SetCurrentBPM(0, target_bpm, true)
      r.ShowMessageBox(string.format("Artist: %s\nMode: %s\nBPM: %.1f\nEuclid: %d Steps, %s",
                        artist, current_mode_name, target_bpm, steps, div_current),
                       "DF95 V108 – Tempo angewendet", 0)
    end

    if ImGui.Button(ctx, "Nur ExtStates setzen (Projekt BPM unverändert)") then
      set_ext("DF95_ARTIST", "TEMPO_MODE", current_mode_name)
      set_ext("DF95_ARTIST", "TEMPO_BPM", target_bpm)
      set_ext("DF95_EUCLID_MULTI", "STEPS", steps)
      set_ext("DF95_EUCLID_MULTI", "DIVISION", div_current)
      r.ShowMessageBox(string.format("ExtStates aktualisiert:\nArtist Tempo Mode: %s (%.1f BPM)\nEuclid: %d Steps, %s",
                        current_mode_name, target_bpm, steps, div_current),
                       "DF95 V108 – ExtStates gesetzt", 0)
    end

    ImGui.Separator(ctx)
    ImGui.TextWrapped(ctx,
      "Hinweis:\n" ..
      "- Die hier hinterlegten BPM-Werte sind bewusst grobe, musikalisch sinnvolle\n" ..
      "  Zonen pro Artist (Slow/Medium/Fast), basierend auf typischen Tempi aus\n" ..
      "  deren Diskographie.\n" ..
      "- V107 nutzt das aktuelle Projekt-Tempo und das Euclid-Raster, die du hier\n" ..
      "  definierst, um daraus feldaufnahmebasierte Beats zu erzeugen.")

    ImGui.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

r.defer(loop)
