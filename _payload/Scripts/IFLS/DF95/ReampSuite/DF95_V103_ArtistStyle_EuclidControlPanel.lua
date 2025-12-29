-- @description DF95_V103_ArtistStyle_EuclidControlPanel
-- @version 1.0
-- @author DF95
-- @about
--   ImGui-Controlpanel für:
--     * Auswahl & Verwaltung von Artist + Style (DF95_ARTIST/NAME, DF95_STYLE/NAME)
--     * Start der V102 Artist+Style BeatEngine
--     * Erzeugung von Euclid-Rhythmen (Kick/Snare/Hat/Custom) in verschiedenen Teilungen
--       (z.B. 3 in 8, 5 in 8, 7 in 8, 3/4, 3/8, 5/8, 7/8 etc.).
--
--   Voraussetzungen:
--     - ReaImGui (SWS/Extensions) muss installiert sein.
--     - Script `DF95_V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist.lua`
--       muss im selben Ordner liegen (ReampSuite-Ordner).

local r = reaper

------------------------------------------------------------
-- ImGui Setup
------------------------------------------------------------
local ImGui = r.ImGui
if not ImGui then
  r.ShowMessageBox("ReaImGui ist nicht verfügbar. Bitte Extension installieren.", "DF95 V103", 0)
  return
end

local ctx = ImGui.CreateContext('DF95 V103 Artist+Style Euclid Panel')

------------------------------------------------------------
-- Artist/Style State
------------------------------------------------------------

local ARTIST_KEY = "DF95_ARTIST"
local ARTIST_EXT_KEY = "NAME"
local STYLE_KEY = "DF95_STYLE"
local STYLE_EXT_KEY = "NAME"

local ARTISTS = {
  "Aphex Twin",
  "Autechre",
  "Boards of Canada",
  "Squarepusher",
  "µ-ziq",
  "Apparat",
  "Arovane",
  "Björk",
  "Bochum Welt",
  "Bogdan Raczynski",
  "Burial",
  "Cylob",
  "DMX Krew",
  "Flying Lotus",
  "Four Tet",
  "The Future Sound Of London",
  "I am Robot and Proud",
  "Isan",
  "Jan Jelinek",
  "Jega",
  "Legowelt",
  "Matmos",
  "Moderat",
  "Photek",
  "Plaid",
  "Skylab",
  "Telefon Tel Aviv",
  "Thom Yorke",
  "Tim Hecker",
  "Proem",
}

local STYLES = {
  "Neutral",
  "IDM_Style",
  "Glitch_Style",
  "WarmTape_Style",
  "HarshDigital_Style",
}

local function get_proj_ext_state(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if v == nil or v == "" then return default end
  return v
end

local function set_proj_ext_state(section, key, value)
  r.SetProjExtState(0, section, key, value or "")
end

local function find_in_list(list, value)
  if not value then return 1 end
  for i, v in ipairs(list) do
    if v == value then return i end
  end
  return 1
end

local currentArtist = get_proj_ext_state(ARTIST_KEY, ARTIST_EXT_KEY, ARTISTS[1])
local currentStyle  = get_proj_ext_state(STYLE_KEY,  STYLE_EXT_KEY,  STYLES[1])

------------------------------------------------------------
-- Euclid Parameter State
------------------------------------------------------------

local EUC_SECTION = "DF95_EUCLID"

local function get_ext_num(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  local n = tonumber(v)
  if not n then return default end
  return n
end

local function get_ext_str(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if v == nil or v == "" then return default end
  return v
end

local function set_ext(section, key, val)
  r.SetProjExtState(0, section, key, tostring(val or ""))
end

local euclid_steps  = get_ext_num(EUC_SECTION, "STEPS", 8)
local euclid_pulses = get_ext_num(EUC_SECTION, "PULSES", 3)
local euclid_rotate = get_ext_num(EUC_SECTION, "ROTATE", 0)
local euclid_div    = get_ext_str(EUC_SECTION, "DIVISION", "1/8")
local euclid_note   = get_ext_num(EUC_SECTION, "NOTE", 36)

local DIVISIONS = { "1/4", "1/8", "1/16", "1/32" }

------------------------------------------------------------
-- Euclidean Algorithm (Bjorklund)
------------------------------------------------------------

local function euclid_pattern(steps, pulses)
  -- Rückgabe: Tabelle mit boolean (true = Hit), Länge = steps
  local pattern = {}
  if pulses <= 0 then
    for i=1,steps do pattern[i] = false end
    return pattern
  end
  if pulses >= steps then
    for i=1,steps do pattern[i] = true end
    return pattern
  end

  local pauses = steps - pulses
  local groups = {}
  for i=1,pulses do groups[i] = {1} end
  local gidx = 1
  while pauses > 0 do
    groups[gidx][#groups[gidx]+1] = 0
    pauses = pauses - 1
    gidx = gidx + 1
    if gidx > pulses then gidx = 1 end
  end

  local out = {}
  for _,g in ipairs(groups) do
    for _,v in ipairs(g) do
      out[#out+1] = (v == 1)
    end
  end

  while #out > steps do
    table.remove(out)
  end
  while #out < steps do
    out[#out+1] = false
  end

  return out
end

local function rotate_pattern(pattern, rot)
  local n = #pattern
  if n == 0 then return pattern end
  rot = rot % n
  if rot == 0 then return pattern end
  local out = {}
  for i=1,n do
    local idx = ((i-1-rot) % n) + 1
    out[i] = pattern[idx]
  end
  return out
end

------------------------------------------------------------
-- Euclid -> MIDI auf Track
------------------------------------------------------------

local function div_to_beat(div)
  if div == "1/4" then return 1.0 end
  if div == "1/8" then return 0.5 end
  if div == "1/16" then return 0.25 end
  if div == "1/32" then return 0.125 end
  return 0.5
end

local function create_euclid_midi_for_selected_track()
  local track = r.GetSelectedTrack(0, 0)
  if not track then
    msg("Bitte einen Ziel-Track auswählen (für Euclid-MIDI).")
    return
  end

  local steps  = math.max(1, math.floor(euclid_steps))
  local pulses = math.max(0, math.floor(euclid_pulses))
  if pulses > steps then pulses = steps end
  local rot    = math.floor(euclid_rotate)
  local div    = euclid_div
  local note   = math.max(0, math.min(127, math.floor(euclid_note)))

  set_ext(EUC_SECTION, "STEPS", steps)
  set_ext(EUC_SECTION, "PULSES", pulses)
  set_ext(EUC_SECTION, "ROTATE", rot)
  set_ext(EUC_SECTION, "DIVISION", div)
  set_ext(EUC_SECTION, "NOTE", note)

  local pattern = euclid_pattern(steps, pulses)
  pattern = rotate_pattern(pattern, rot)

  local beat_len = div_to_beat(div)
  local total_beats = steps * beat_len

  local proj = 0
  local start_beats = r.TimeMap2_timeToBeats(proj, r.GetCursorPosition())
  local start_time  = r.GetCursorPosition()
  local end_time    = r.TimeMap2_beatsToTime(proj, start_beats + total_beats, 0)

  r.Undo_BeginBlock()

  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", start_time)
  r.SetMediaItemInfo_Value(item, "D_LENGTH", end_time - start_time)
  local take = r.AddTakeToMediaItem(item)
  local PPQ = 960
  local function beat_to_ppq(beat) return beat * PPQ end

  local vel = 110
  local note_len_beats = beat_len * 0.8

  local beat_pos = start_beats
  for i=1,steps do
    if pattern[i] then
      local s_ppq = beat_to_ppq(beat_pos - start_beats)
      local e_ppq = beat_to_ppq(beat_pos - start_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, s_ppq, e_ppq, 0, note, vel, false)
    end
    beat_pos = beat_pos + beat_len
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V103 Euclid Pattern", -1)
end

------------------------------------------------------------
-- Child-Script Trigger (V102 Artist+Style BeatEngine)
------------------------------------------------------------

local function get_script_dir()
  local info = debug.getinfo(1, "S")
  local script_path = info.source:match("^@(.+)$")
  return script_path:match("^(.*[\\/])") or ""
end

local function run_v102_beatengine()
  local base_dir = get_script_dir()
  local name = "DF95_V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist.lua"
  local path = base_dir .. name
  local f = io.open(path, "r")
  if not f then
    msg("Konnte V102 BeatEngine nicht finden:\n" .. path)
    return
  end
  f:close()
  dofile(path)
end

------------------------------------------------------------
-- Main ImGui Loop
------------------------------------------------------------

local function loop()
  ImGui.SetNextWindowSize(ctx, 520, 380, ImGui.Cond_FirstUseEver())
  local visible, open = ImGui.Begin(ctx, 'DF95 Artist+Style + Euclid', true)
  if visible then

    -- Artist Auswahl
    ImGui.Text(ctx, "Artist (Person)")
    local currentArtistIdx = find_in_list(ARTISTS, currentArtist)
    if ImGui.BeginCombo(ctx, "Artist", ARTISTS[currentArtistIdx] or "") then
      for i, a in ipairs(ARTISTS) do
        local selected = (i == currentArtistIdx)
        if ImGui.Selectable(ctx, a, selected) then
          currentArtist = a
          set_proj_ext_state(ARTIST_KEY, ARTIST_EXT_KEY, currentArtist)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.Separator(ctx)

    -- Style Auswahl
    ImGui.Text(ctx, "Style (IDM / Glitch / Tape / Harsh)")
    local currentStyleIdx = find_in_list(STYLES, currentStyle)
    if ImGui.BeginCombo(ctx, "Style", STYLES[currentStyleIdx] or "") then
      for i, s in ipairs(STYLES) do
        local selected = (i == currentStyleIdx)
        if ImGui.Selectable(ctx, s, selected) then
          currentStyle = s
          set_proj_ext_state(STYLE_KEY, STYLE_EXT_KEY, currentStyle)
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.Separator(ctx)

    if ImGui.Button(ctx, "V102 Artist+Style BeatEngine starten") then
      run_v102_beatengine()
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Euclid Rhythm Generator")
    ImGui.Text(ctx, "Erzeugt ein Pattern auf dem selektierten Track als MIDI.")

    -- Steps & Pulses
    local changed

    changed, euclid_steps = ImGui.SliderInt(ctx, "Schritte (Steps)", euclid_steps, 1, 32)
    if changed then
      if euclid_steps < 1 then euclid_steps = 1 end
      if euclid_pulses > euclid_steps then euclid_pulses = euclid_steps end
    end
    changed, euclid_pulses = ImGui.SliderInt(ctx, "Pulses (Hits)", euclid_pulses, 0, euclid_steps)
    if changed then
      if euclid_pulses < 0 then euclid_pulses = 0 end
      if euclid_pulses > euclid_steps then euclid_pulses = euclid_steps end
    end

    changed, euclid_rotate = ImGui.SliderInt(ctx, "Rotation", euclid_rotate, 0, euclid_steps > 0 and (euclid_steps-1) or 0)
    if changed and euclid_rotate < 0 then euclid_rotate = 0 end

    -- Division Auswahl (1/4,1/8,1/16,1/32)
    local div_idx = 1
    for i, d in ipairs(DIVISIONS) do
      if d == euclid_div then div_idx = i break end
    end
    if ImGui.BeginCombo(ctx, "Note-Division", DIVISIONS[div_idx] or "") then
      for i, d in ipairs(DIVISIONS) do
        local selected = (i == div_idx)
        if ImGui.Selectable(ctx, d, selected) then
          euclid_div = d
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    -- Ziel-Note
    changed, euclid_note = ImGui.InputInt(ctx, "MIDI-Note (z.B. 36=Kick,38=Snare,42=Hat)", euclid_note)
    if changed then
      if euclid_note < 0 then euclid_note = 0 end
      if euclid_note > 127 then euclid_note = 127 end
    end

    if ImGui.Button(ctx, "Euclid-Muster auf selektiertem Track erzeugen") then
      create_euclid_midi_for_selected_track()
    end

    ImGui.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

r.defer(loop)
