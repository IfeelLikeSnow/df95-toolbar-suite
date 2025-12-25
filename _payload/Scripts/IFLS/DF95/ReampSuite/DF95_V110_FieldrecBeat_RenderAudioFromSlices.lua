-- @description DF95_V110_FieldrecBeat_RenderAudioFromSlices
-- @version 1.0
-- @author DF95
-- @about
--   Rendert ein von V107 erzeugtes MIDI-Beatpattern direkt als Audio,
--   indem vorhandene Fieldrec-Slices (KICK/SNARE/HAT/PERC/EXTRA) aus
--   der DF95_ADAPTIVE-Engine dupliziert und auf neue Spuren gelegt werden.
--
--   Annahmen / Design:
--     * V95/V95.2 haben Fieldrec-Material gesplittet & klassifiziert.
--     * V105 (Adaptive Sample Engine) hat GUID-Listen pro Kategorie in
--       DF95_ADAPTIVE/* geschrieben (KICK_GUIDS, SNARE_GUIDS, ...).
--     * V107 hat ein MIDI-Beatpattern erzeugt (Kick=36, Snare=38, Hat=42,
--       Perc=39, Extra=40).
--     * Dieses Script:
--         - erwartet mindestens ein selektiertes MIDI-Item (Beat),
--         - liest die MIDI-Noten,
--         - weist jede Note einer Kategorie (KICK/SNARE/HAT/PERC/EXTRA) zu,
--         - wählt pro Hit ein passendes Slice (GUID) aus den Adaptive-Pools
--           (Round-Robin),
--         - sucht das Quell-Item mit dieser GUID im Projekt,
--         - dupliziert es (inkl. Fades) auf eine neue Kategorie-Spur und
--           setzt es an die Position der Note.
--
--   LIMITIERUNGEN (Prototyp):
--     * GUID-Listen werden als komma- oder leerzeichen-separierte Strings
--       erwartet (DF95_ADAPTIVE/KICK_GUIDS etc.).
--     * Länge des Ziel-Items entspricht der Originallänge des Slices.
--     * Es gibt keine Pitch-Shifts / Microvarianten – Ziel ist ein
--       transparenter, nachvollziehbarer Audio-Render des Patterns.
--

local r = reaper

------------------------------------------------------------
-- ExtState Helpers
------------------------------------------------------------

local function get_proj_ext(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if not v or v == "" then return default end
  return v
end

------------------------------------------------------------
-- Adaptive GUID Pools lesen
------------------------------------------------------------

local function parse_guid_list(s)
  local t = {}
  if not s or s == "" then return t end
  -- Trenner: Komma, Semikolon, Whitespace
  s = s:gsub("[\n\r]", " ")
  for token in s:gmatch("[^,%s;]+") do
    -- GUIDs sollten mit { anfangen
    if token:match("{.*}") then
      t[#t+1] = token
    end
  end
  return t
end

local function read_adaptive_guid_pools()
  local sect = "DF95_ADAPTIVE"
  local pools = {}

  pools.KICK  = parse_guid_list(get_proj_ext(sect, "KICK_GUIDS", ""))
  pools.SNARE = parse_guid_list(get_proj_ext(sect, "SNARE_GUIDS", ""))
  pools.HAT   = parse_guid_list(get_proj_ext(sect, "HAT_GUIDS", ""))
  pools.PERC  = parse_guid_list(get_proj_ext(sect, "PERC_GUIDS", ""))
  pools.OTHER = parse_guid_list(get_proj_ext(sect, "OTHER_GUIDS", ""))

  return pools
end

------------------------------------------------------------
-- Medienobjekte per GUID finden
------------------------------------------------------------

local function build_item_guid_map()
  local map = {}
  local proj = 0
  local track_count = r.CountTracks(proj)
  for ti = 0, track_count-1 do
    local tr = r.GetTrack(proj, ti)
    local item_count = r.CountTrackMediaItems(tr)
    for ii = 0, item_count-1 do
      local it = r.GetTrackMediaItem(tr, ii)
      local _, guid = r.GetSetMediaItemInfo_String(it, "GUID", "", false)
      if guid and guid ~= "" then
        map[guid] = it
      end
    end
  end
  return map
end

------------------------------------------------------------
-- Zielspuren anlegen
------------------------------------------------------------

local function ensure_category_track(name_suffix)
  local proj = 0
  local track_count = r.CountTracks(proj)
  local name = "DF95_V110_" .. name_suffix
  -- Suchen, ob Spur existiert
  for ti = 0, track_count-1 do
    local tr = r.GetTrack(proj, ti)
    local _, tr_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if tr_name == name then
      return tr
    end
  end
  -- sonst neue Spur am Ende
  r.InsertTrackAtIndex(track_count, true)
  local tr = r.GetTrack(proj, track_count)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

------------------------------------------------------------
-- Kategorie aus MIDI-Note bestimmen
------------------------------------------------------------

local function category_from_note(note)
  if note == 36 then return "KICK" end
  if note == 38 then return "SNARE" end
  if note == 42 then return "HAT" end
  if note == 39 then return "PERC" end
  if note == 40 then return "EXTRA" end
  return nil
end

local function category_to_track_suffix(cat)
  if cat == "KICK"  then return "KICK" end
  if cat == "SNARE" then return "SNARE" end
  if cat == "HAT"   then return "HAT" end
  if cat == "PERC"  or cat == "EXTRA" then return "PERC_EXTRA" end
  return "OTHER"
end

local function pool_for_category(pools, cat)
  if cat == "KICK"  then return pools.KICK end
  if cat == "SNARE" then return pools.SNARE end
  if cat == "HAT"   then return pools.HAT end
  if cat == "PERC"  then return pools.PERC end
  if cat == "EXTRA" then return pools.PERC end -- EXTRA nutzt PERC-Pool
  return pools.OTHER
end

------------------------------------------------------------
-- MIDI-Beat-Item lesen
------------------------------------------------------------

local function get_selected_midi_item()
  local sel_item_count = r.CountSelectedMediaItems(0)
  if sel_item_count < 1 then return nil, "Kein Item selektiert." end
  -- Nimm das erste selektierte Item mit einem MIDI-Take
  for i = 0, sel_item_count-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(it)
    if take and r.TakeIsMIDI(take) then
      return it, nil
    end
  end
  return nil, "Kein selektiertes MIDI-Item gefunden (V107-Beat?)."
end

------------------------------------------------------------
-- Hauptlogik: Audio-Render
------------------------------------------------------------

local function render_audio_from_midi()
  local beat_item, err = get_selected_midi_item()
  if not beat_item then
    r.ShowMessageBox(err, "DF95 V110", 0)
    return
  end

  local beat_take = r.GetActiveTake(beat_item)
  local pools = read_adaptive_guid_pools()
  local item_map = build_item_guid_map()

  -- Check: gibt es überhaupt GUIDs?
  local total_pool = 0
  for _, list in pairs(pools) do
    total_pool = total_pool + #list
  end
  if total_pool == 0 then
    r.ShowMessageBox("Keine DF95_ADAPTIVE GUID-Listen gefunden. Bitte zuerst V105 Adaptive Sample Engine ausführen.", "DF95 V110", 0)
    return
  end

  -- Round-Robin Indizes je Kategorie
  local rr_index = {
    KICK = 1, SNARE = 1, HAT = 1, PERC = 1, EXTRA = 1, OTHER = 1
  }

  local proj = 0
  local item_pos = r.GetMediaItemInfo_Value(beat_item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(beat_item, "D_LENGTH")
  local item_end = item_pos + item_len

  r.Undo_BeginBlock()

  -- Zielspuren pro Kategorie
  local target_tracks = {}
  local function get_target_track(cat)
    local suffix = category_to_track_suffix(cat)
    if not target_tracks[suffix] then
      target_tracks[suffix] = ensure_category_track(suffix)
    end
    return target_tracks[suffix]
  end

  -- MIDI-Events auslesen
  local _, midi_str = r.MIDI_GetAllEvts(beat_take, "")
  local ppq_start = 0
  local pos_ppq = 0

  local function ppq_to_time(ppq)
    local qn = r.MIDI_GetProjQNFromPPQPos(beat_take, ppq)
    local t  = r.TimeMap2_QNToTime(proj, qn)
    return t
  end

  local i = 1
  while i <= #midi_str do
    local offset, flags, msg
    offset, flags, msg, i = r.MIDI_GetEvt(beat_take, i, false, false, 0, "")
    if not offset then break end
    pos_ppq = pos_ppq + offset
    if #msg >= 3 then
      local status = msg:byte(1) & 0xF0
      local note   = msg:byte(2)
      local vel    = msg:byte(3)
      if status == 0x90 and vel > 0 then
        local cat = category_from_note(note)
        if cat then
          local pool = pool_for_category(pools, cat)
          if pool and #pool > 0 then
            local idx = rr_index[cat] or 1
            if idx > #pool then idx = 1 end
            rr_index[cat] = idx + 1
            local guid = pool[idx]
            local src_item = item_map[guid]
            if src_item then
              local src_len = r.GetMediaItemInfo_Value(src_item, "D_LENGTH")
              local note_time = ppq_to_time(pos_ppq)
              if note_time >= item_pos and note_time <= item_end then
                local tr = get_target_track(cat)
                local new_item = r.AddMediaItemToTrack(tr)
                r.SetMediaItemInfo_Value(new_item, "D_POSITION", note_time)
                r.SetMediaItemInfo_Value(new_item, "D_LENGTH", src_len)
                -- Copy active take source & fades
                local src_take = r.GetActiveTake(src_item)
                if src_take then
                  local src_src = r.GetMediaItemTake_Source(src_take)
                  local new_take = r.AddTakeToMediaItem(new_item)
                  r.SetMediaItemTake_Source(new_take, src_src)
                  -- Copy fades
                  local fadein_len = r.GetMediaItemInfo_Value(src_item, "D_FADEINLEN")
                  local fadeout_len = r.GetMediaItemInfo_Value(src_item, "D_FADEOUTLEN")
                  r.SetMediaItemInfo_Value(new_item, "D_FADEINLEN", fadein_len)
                  r.SetMediaItemInfo_Value(new_item, "D_FADEOUTLEN", fadeout_len)
                  -- Optional: copy start offset
                  local start_offs = r.GetMediaItemTakeInfo_Value(src_take, "D_STARTOFFS")
                  r.SetMediaItemTakeInfo_Value(new_take, "D_STARTOFFS", start_offs)
                end
              end
            end
          end
        end
      end
    end
  end

  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V110 FieldrecBeat Render Audio From Slices", -1)
end

render_audio_from_midi()
