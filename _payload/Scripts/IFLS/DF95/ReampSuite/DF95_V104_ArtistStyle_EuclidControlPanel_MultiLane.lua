-- @description DF95_V104_ArtistStyle_EuclidControlPanel_MultiLane
-- @version 1.0
-- @author DF95
-- @about
--   Erweiterte ImGui-Version des Artist+Style Panels mit Multi-Lane Euclid Engine.
--   - Artist/Style Verwaltung (DF95_ARTIST/NAME, DF95_STYLE/NAME)
--   - Start der V102 Artist+Style BeatEngine
--   - Euclid-Generator mit mehreren Lanes (Kick/Snare/Hat/Extra) gleichzeitig:
--       * global: Steps & Division
--       * pro Lane: Pulses, Rotation, MIDI-Note, Enable
--
--   Voraussetzung:
--     - ReaImGui (REAPER ImGui API) muss verfügbar sein.
--     - DF95_V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist.lua im gleichen Ordner.

local r = reaper
local ImGui = r.ImGui
if not ImGui then
  r.ShowMessageBox("ReaImGui ist nicht verfügbar. Bitte Extension installieren.", "DF95 V104", 0)
  return
end

local ctx = ImGui.CreateContext('DF95 V104 Artist+Style Euclid Panel (MultiLane)')

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
-- Euclid Multi-Lane State
------------------------------------------------------------

local EUC_SECTION = "DF95_EUCLID_MULTI"

local function get_ext_num(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  local n = tonumber(v)
  if not n then return default end
  return n
end

local function get_ext_bool(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if v == "1" then return true end
  if v == "0" then return false end
  return default
end

local function get_ext_str(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if v == nil or v == "" then return default end
  return v
end

local function set_ext(section, key, val)
  r.SetProjExtState(0, section, key, tostring(val or ""))
end

local DIVISIONS = { "1/4", "1/8", "1/16", "1/32" }

local euclid_steps  = get_ext_num(EUC_SECTION, "STEPS", 8)
local euclid_div    = get_ext_str(EUC_SECTION, "DIVISION", "1/8")

-- Lanes: Kick, Snare, Hat, Extra
local lanes = {
  {
    id = "KICK",
    label = "Kick Lane",
    pulses = get_ext_num(EUC_SECTION, "KICK_PULSES", 3),
    rotate = get_ext_num(EUC_SECTION, "KICK_ROT", 0),
    note   = get_ext_num(EUC_SECTION, "KICK_NOTE", 36),
    enabled = get_ext_bool(EUC_SECTION, "KICK_EN", true),
  },
  {
    id = "SNARE",
    label = "Snare Lane",
    pulses = get_ext_num(EUC_SECTION, "SNARE_PULSES", 2),
    rotate = get_ext_num(EUC_SECTION, "SNARE_ROT", 0),
    note   = get_ext_num(EUC_SECTION, "SNARE_NOTE", 38),
    enabled = get_ext_bool(EUC_SECTION, "SNARE_EN", true),
  },
  {
    id = "HAT",
    label = "Hat Lane",
    pulses = get_ext_num(EUC_SECTION, "HAT_PULSES", 5),
    rotate = get_ext_num(EUC_SECTION, "HAT_ROT", 0),
    note   = get_ext_num(EUC_SECTION, "HAT_NOTE", 42),
    enabled = get_ext_bool(EUC_SECTION, "HAT_EN", true),
  },
  {
    id = "EXTRA",
    label = "Extra Lane",
    pulses = get_ext_num(EUC_SECTION, "EXTRA_PULSES", 0),
    rotate = get_ext_num(EUC_SECTION, "EXTRA_ROT", 0),
    note   = get_ext_num(EUC_SECTION, "EXTRA_NOTE", 39),
    enabled = get_ext_bool(EUC_SECTION, "EXTRA_EN", false),
  },
}

------------------------------------------------------------
-- Euclidean Algorithm
------------------------------------------------------------

local function euclid_pattern(steps, pulses)
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

  while #out > steps do table.remove(out) end
  while #out < steps do out[#out+1] = false end

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

local function div_to_beat(div)
  if div == "1/4" then return 1.0 end
  if div == "1/8" then return 0.5 end
  if div == "1/16" then return 0.25 end
  if div == "1/32" then return 0.125 end
  return 0.5
end

------------------------------------------------------------
-- Euclid: Multi-Lane -> MIDI auf selektiertem Track
------------------------------------------------------------

local function create_euclid_midi_multilane()
  local track = r.GetSelectedTrack(0, 0)
  if not track then
    r.ShowMessageBox("Bitte einen Ziel-Track auswählen (für Euclid-MIDI).", "DF95 V104", 0)
    return
  end

  local steps = math.max(1, math.floor(euclid_steps))
  local div = euclid_div

  -- persist globals
  set_ext(EUC_SECTION, "STEPS", steps)
  set_ext(EUC_SECTION, "DIVISION", div)

  for _, lane in ipairs(lanes) do
    set_ext(EUC_SECTION, lane.id .. "_PULSES", lane.pulses)
    set_ext(EUC_SECTION, lane.id .. "_ROT", lane.rotate)
    set_ext(EUC_SECTION, lane.id .. "_NOTE", lane.note)
    set_ext(EUC_SECTION, lane.id .. "_EN", lane.enabled and "1" or "0")
  end

  local beat_len = div_to_beat(div)
  local total_beats = steps * beat_len

  local proj = 0
  local start_time = r.GetCursorPosition()
  local start_beats = r.TimeMap2_timeToBeats(proj, start_time)
  local end_time = r.TimeMap2_beatsToTime(proj, start_beats + total_beats, 0)

  r.Undo_BeginBlock()

  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", start_time)
  r.SetMediaItemInfo_Value(item, "D_LENGTH", end_time - start_time)
  local take = r.AddTakeToMediaItem(item)
  local PPQ = 960
  local function beat_to_ppq(beat) return beat * PPQ end

  local note_len_beats = beat_len * 0.8

  local beat_offset = start_beats
  for _, lane in ipairs(lanes) do
    if lane.enabled and lane.pulses > 0 then
      local pulses = math.max(0, math.floor(lane.pulses))
      if pulses > steps then pulses = steps end
      local pattern = euclid_pattern(steps, pulses)
      pattern = rotate_pattern(pattern, math.floor(lane.rotate or 0))
      local note = math.max(0, math.min(127, math.floor(lane.note or 36)))
      local vel = 110

      local pos_beats = beat_offset
      for i=1,steps do
        if pattern[i] then
          local s_ppq = beat_to_ppq(pos_beats - beat_offset)
          local e_ppq = beat_to_ppq(pos_beats - beat_offset + note_len_beats)
          r.MIDI_InsertNote(take, false, false, s_ppq, e_ppq, 0, note, vel, false)
        end
        pos_beats = pos_beats + beat_len
      end
    end
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V104 Euclid MultiLane Pattern", -1)
end

------------------------------------------------------------
-- Child-Script Trigger (V102 BeatEngine)
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
    r.ShowMessageBox("Konnte V102 BeatEngine nicht finden:\n" .. path, "DF95 V104", 0)
    return
  end
  f:close()
  dofile(path)
end

------------------------------------------------------------
-- Main ImGui Loop
------------------------------------------------------------

local function loop()
  ImGui.SetNextWindowSize(ctx, 560, 520, ImGui.Cond_FirstUseEver())
  local visible, open = ImGui.Begin(ctx, 'DF95 Artist+Style + Euclid (MultiLane)', true)
  if visible then

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

    ImGui.Text(ctx, "Style (Textur / Verhalten)")
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

    if ImGui.Button(ctx, "V102 Artist+Style BeatEngine starten") then
      run_v102_beatengine()
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Euclid Multi-Lane Generator")
    ImGui.Text(ctx, "Erzeugt ein gemeinsames MIDI-Item auf dem selektierten Track.")

    -- Global Steps & Division
    local changed
    changed, euclid_steps = ImGui.SliderInt(ctx, "Global Steps (z.B. 8, 12, 16)", euclid_steps, 1, 32)
    if changed and euclid_steps < 1 then euclid_steps = 1 end

    local div_idx = 1
    for i, d in ipairs(DIVISIONS) do
      if d == euclid_div then div_idx = i break end
    end
    if ImGui.BeginCombo(ctx, "Division (Notewert)", DIVISIONS[div_idx] or "") then
      for i, d in ipairs(DIVISIONS) do
        local selected = (i == div_idx)
        if ImGui.Selectable(ctx, d, selected) then
          euclid_div = d
        end
        if selected then ImGui.SetItemDefaultFocus(ctx) end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Lanes (gleiches Grid, unterschiedliche Pulses/Notes)")

    for _, lane in ipairs(lanes) do
      ImGui.Separator(ctx)
      local changed_en, en = ImGui.Checkbox(ctx, lane.label .. " aktiv", lane.enabled)
      if changed_en then lane.enabled = en end

      ImGui.SameLine(ctx)
      ImGui.Text(ctx, "(" .. lane.id .. ")")

      ImGui.PushID(ctx, lane.id .. "_PULSES")
      local c1; c1, lane.pulses = ImGui.SliderInt(ctx, "Pulses", lane.pulses, 0, euclid_steps)
      ImGui.PopID(ctx)
      if c1 then
        if lane.pulses < 0 then lane.pulses = 0 end
        if lane.pulses > euclid_steps then lane.pulses = euclid_steps end
      end

      ImGui.PushID(ctx, lane.id .. "_ROT")
      local c2; c2, lane.rotate = ImGui.SliderInt(ctx, "Rotation", lane.rotate, 0, euclid_steps>0 and (euclid_steps-1) or 0)
      ImGui.PopID(ctx)
      if c2 and lane.rotate < 0 then lane.rotate = 0 end

      ImGui.PushID(ctx, lane.id .. "_NOTE")
      local c3; c3, lane.note = ImGui.InputInt(ctx, "MIDI Note", lane.note)
      ImGui.PopID(ctx)
      if c3 then
        if lane.note < 0 then lane.note = 0 end
        if lane.note > 127 then lane.note = 127 end
      end
    end

    if ImGui.Button(ctx, "Euclid Multi-Lane auf selektierten Track schreiben") then
      create_euclid_midi_multilane()
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
