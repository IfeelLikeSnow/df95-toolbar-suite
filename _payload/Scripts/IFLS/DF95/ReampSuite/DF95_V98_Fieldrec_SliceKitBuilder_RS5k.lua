-- @description DF95_V98_Fieldrec_SliceKitBuilder_RS5k
-- @version 1.0
-- @author DF95
-- @about
--   Baut aus V95/V95.1-Slices automatisch ein kleines RS5k-Drumkit:
--     * LOW_PERC   -> Kick (Note 36)
--     * SNARE_PERC -> Snare (Note 38)
--     * HAT_CYMBAL -> Hat   (Note 42)
--
--   Workflow:
--     1. Wende V95/V95.1 auf dein Fieldrec-Material an, so dass Tracks existieren wie:
--          - V95_LOW_PERC*
--          - V95_SNARE_PERC*
--          - V95_HAT_CYMBAL*
--     2. Starte dieses Script.
--     3. Es erzeugt einen Track "V98_SliceKit_RS5k" mit bis zu 3 ReaSamplomatic5000-Instanzen.
--        Jede Instanz bekommt einen repräsentativen Slice (beste RMS) zugewiesen,
--        inklusive Start/End-Offsets aus dem Slice.
--     4. Du kannst den Kit-Track direkt mit V97_BeatEngine_MIDI (Kick=36, Snare=38, Hat=42)
--        ansteuern.
--
--   Hinweis:
--     - Dies ist eine einfache Kit-Version (eine Sample-Variante pro Rolle).
--       Erweiterte Round-Robin/Velocity-Layer wären eine mögliche V98.x-Erweiterung.

local r = reaper

local function msg(s)
  r.ShowMessageBox(s, "DF95 V98 SliceKit Builder", 0)
end

------------------------------------------------------------
-- V95-Klassen-Items einsammeln
------------------------------------------------------------
local function collect_class_items()
  local proj = 0
  local n_tr = r.CountTracks(proj)
  local classes = {
    LOW_PERC   = {},
    SNARE_PERC = {},
    HAT_CYMBAL = {},
  }

  for i = 0, n_tr-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if name and name ~= "" then
      local upper = name:upper()
      local class_key = nil
      if upper:find("V95_LOW_PERC") then
        class_key = "LOW_PERC"
      elseif upper:find("V95_SNARE_PERC") then
        class_key = "SNARE_PERC"
      elseif upper:find("V95_HAT_CYMBAL") then
        class_key = "HAT_CYMBAL"
      end
      if class_key then
        local item_count = r.CountTrackMediaItems(tr)
        for it = 0, item_count-1 do
          local item = r.GetTrackMediaItem(tr, it)
          local take = r.GetActiveTake(item)
          if take and not r.TakeIsMIDI(take) then
            table.insert(classes[class_key], { item = item, take = take })
          end
        end
      end
    end
  end

  return classes
end

------------------------------------------------------------
-- RMS eines Items (Slice) grob berechnen
------------------------------------------------------------
local function compute_item_rms(slice)
  local item = slice.item
  local take = slice.take
  local src = r.GetMediaItemTake_Source(take)
  local src_len, _ = r.GetMediaSourceLength(src)
  local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
  if sr <= 0 then sr = 44100 end

  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  local accessor = r.CreateTakeAudioAccessor(take)
  if not accessor then return 0 end

  local num_samples = math.floor(item_len * sr + 0.5)
  num_samples = math.min(num_samples, 20000)
  if num_samples < 16 then num_samples = 16 end

  local src_numch = r.GetMediaSourceNumChannels(src)
  if src_numch < 1 then src_numch = 1 end

  local buf = r.new_array(src_numch * num_samples)
  r.GetAudioAccessorSamples(accessor, sr, src_numch, item_pos, num_samples, buf)

  local sum_sq = 0.0
  for i = 0, num_samples-1 do
    local s = 0.0
    for c = 0, src_numch-1 do
      s = s + buf[i*src_numch + c]
    end
    s = s / src_numch
    sum_sq = sum_sq + s*s
  end

  r.DestroyAudioAccessor(accessor)

  local rms = math.sqrt(sum_sq / num_samples)
  return rms
end

------------------------------------------------------------
-- Besten Slice pro Klasse wählen (lautester RMS)
------------------------------------------------------------
local function pick_best_slice(slices)
  local best_slice = nil
  local best_rms = -1.0
  for _, s in ipairs(slices) do
    local rms = compute_item_rms(s)
    if rms > best_rms then
      best_rms = rms
      best_slice = s
    end
  end
  return best_slice
end

------------------------------------------------------------
-- RS5k-Instanz für einen Slice erzeugen (Kick/Snare/Hat)
------------------------------------------------------------
local function add_rs5k_for_slice(track, slice, note)
  local item = slice.item
  local take = slice.take

  local src = r.GetMediaItemTake_Source(take)
  local src_len, _ = r.GetMediaSourceLength(src)
  if not src_len or src_len <= 0 then return end

  local _, filepath = r.GetMediaSourceFileName(src, "")
  if not filepath or filepath == "" then return end

  local start_offs = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local item_len   = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local playrate   = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  if playrate <= 0 then playrate = 1.0 end

  local seg_len_src    = item_len * playrate
  local seg_start_norm = math.max(0.0, math.min(1.0, start_offs / src_len))
  local seg_end_norm   = math.max(seg_start_norm, math.min(1.0, (start_offs + seg_len_src) / src_len))

  local fx_idx = r.TrackFX_AddByName(track, "ReaSamplomatic5000 (Cockos)", false, -1)
  if fx_idx < 0 then
    fx_idx = r.TrackFX_AddByName(track, "ReaSamplOmatic5000 (Cockos)", false, -1)
  end
  if fx_idx < 0 then
    msg("Konnte ReaSamplomatic5000 nicht einfügen. Ist der FX vorhanden?")
    return
  end

  r.TrackFX_SetNamedConfigParm(track, fx_idx, "FILE0", filepath)
  r.TrackFX_SetNamedConfigParm(track, fx_idx, "DONE", "")

  local norm_note = note / 127.0
  r.TrackFX_SetParamNormalized(track, fx_idx, 3, norm_note)
  r.TrackFX_SetParamNormalized(track, fx_idx, 4, norm_note)

  r.TrackFX_SetParamNormalized(track, fx_idx, 8, 8/64)
  r.TrackFX_SetParamNormalized(track, fx_idx, 9,  0.0)
  r.TrackFX_SetParamNormalized(track, fx_idx, 10, 0.15)
  r.TrackFX_SetParamNormalized(track, fx_idx, 11, 1.0)

  r.TrackFX_SetParamNormalized(track, fx_idx, 13, seg_start_norm)
  r.TrackFX_SetParamNormalized(track, fx_idx, 14, seg_end_norm)

  r.TrackFX_SetParamNormalized(track, fx_idx, 2, 0.25)

  local label = "RS5k_" .. tostring(note)
  r.TrackFX_SetNamedConfigParm(track, fx_idx, "renamed_name", label)
end

------------------------------------------------------------
local function create_kit_track()
  local proj = 0
  local idx = r.CountTracks(proj)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "V98_SliceKit_RS5k", true)
  return tr
end

------------------------------------------------------------
local function main()
  local classes = collect_class_items()
  local have_any =
    (#classes.LOW_PERC   > 0) or
    (#classes.SNARE_PERC > 0) or
    (#classes.HAT_CYMBAL > 0)

  if not have_any then
    msg("Keine V95-Klassentracks mit Items gefunden. Bitte zuerst V95/V95.1 ausführen.")
    return
  end

  r.Undo_BeginBlock()

  local kit_track = create_kit_track()

  if #classes.LOW_PERC > 0 then
    local slice = pick_best_slice(classes.LOW_PERC)
    if slice then add_rs5k_for_slice(kit_track, slice, 36) end
  end

  if #classes.SNARE_PERC > 0 then
    local slice = pick_best_slice(classes.SNARE_PERC)
    if slice then add_rs5k_for_slice(kit_track, slice, 38) end
  end

  if #classes.HAT_CYMBAL > 0 then
    local slice = pick_best_slice(classes.HAT_CYMBAL)
    if slice then add_rs5k_for_slice(kit_track, slice, 42) end
  end

  r.TrackList_AdjustWindows(false)
  r.Undo_EndBlock("DF95 V98 SliceKit Builder RS5k", -1)
end

main()
