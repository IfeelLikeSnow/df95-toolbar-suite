
-- @description DF95_ReampSuite_AutoGain
-- @version 1.0
-- @author DF95
-- @about
--   Analysiert die Pegel der ReampReturn-Tracks und berechnet einen
--   Gain-Offset, um einen Ziel-Peak (z. B. -12 dBFS) zu erreichen.
--
--   - Liest das aktive Reamp-Profil aus DF95_ReampSuite_Profiles.lua.
--   - Sucht Ziel-Tracks:
--       * Wenn Tracks selektiert sind: genau diese.
--       * Wenn nichts selektiert ist: alle Tracks mit "ReampReturn" im Namen.
--   - Analysiert die Items auf diesen Tracks per GetMediaItemTake_Peaks.
--   - Berechnet den maximalen Peak und daraus einen Gain-Offset in dB.
--   - Speichert den Wert in DF95_REAMP/OUT_GAIN_DB_<PROFILE_KEY>.
--   - Optional: wendet den Gain direkt auf die Track-Volumes an.
--
--   Ziel ist primär die Kalibrierung:
--     1. Referenzsignal reampen (z. B. DI-Referenz oder Testimpuls-Loop).
--     2. Dieses Script ausführen.
--     3. DF95_REAMP/OUT_GAIN_DB_<PROFILE> kann später vom Router ausgewertet werden.

local r = reaper

---------------------------------------------------------
-- User-Settings
---------------------------------------------------------

-- Ziel-Peak in dBFS (z. B. -12.0 oder -18.0)
local TARGET_PEAK_DB = -12.0

-- Maximal erlaubte Gain-Korrektur in dB (Schutz, um extreme Werte zu vermeiden)
local MAX_ABS_GAIN_DB = 24.0

-- Soll der berechnete Gain direkt als Track-Volume angewendet werden?
local APPLY_GAIN_TO_TRACKS = false  -- für reine Kalibrierung: false lassen

---------------------------------------------------------
-- Helpers
---------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end

local function get_track_name(tr)
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  return name or ""
end

local function collect_target_tracks()
  local targets = {}

  local sel_cnt = r.CountSelectedTracks(0)
  if sel_cnt > 0 then
    for i = 0, sel_cnt - 1 do
      targets[#targets+1] = r.GetSelectedTrack(0, i)
    end
    return targets, true
  end

  -- keine selektierten Tracks -> alle ReampReturn-Tracks
  local tr_cnt = r.CountTracks(0)
  for i = 0, tr_cnt - 1 do
    local tr = r.GetTrack(0, i)
    local name = get_track_name(tr)
    if name:match("ReampReturn") or name:match("^ReampReturn_") then
      targets[#targets+1] = tr
    end
  end

  return targets, false
end

local function db_from_amp(a)
  if a <= 0 then return -math.huge end
  return 20.0 * math.log(a, 10)
end

local function amp_from_db(db)
  return 10.0 ^ (db / 20.0)
end

---------------------------------------------------------
-- Peak-Analyse via GetMediaItemTake_Peaks
---------------------------------------------------------

local function measure_peak_for_take(take)
  if not take then return 0.0 end

  local src = r.GetMediaItemTake_Source(take)
  if not src then return 0.0 end

  local src_len, _ = r.GetMediaSourceLength(src)
  if not src_len or src_len <= 0 then return 0.0 end

  local numch = r.GetMediaSourceNumChannels(src)
  if not numch or numch < 1 then numch = 1 end

  -- Auflösungs-Parameter: 500 "Peaks" pro Sekunde reichen für eine solide Abschätzung.
  local peakrate = 500
  local total_samples = math.floor(src_len * peakrate + 0.5)
  if total_samples <= 0 then return 0.0 end

  local block = 4096  -- Anzahl Samples pro Kanal pro GetPeaks-Aufruf
  local maxpeak = 0.0
  local processed = 0

  while processed < total_samples do
    local remaining = total_samples - processed
    local this_block = math.min(block, remaining)

    local starttime = processed / peakrate
    local retval, peaks = r.GetMediaItemTake_Peaks(take, peakrate, starttime, numch, this_block)
    if not retval or not peaks then break end

    -- peaks ist eine Lua-Tabelle mit (this_block * numch) Einträgen.
    local count = this_block * numch
    for i = 1, count do
      local v = peaks[i]
      if v then
        local a = math.abs(v)
        if a > maxpeak then maxpeak = a end
      end
    end

    processed = processed + this_block
  end

  return maxpeak
end

local function measure_peak_for_track(tr)
  local item_cnt = r.CountTrackMediaItems(tr)
  local maxpeak = 0.0

  for i = 0, item_cnt - 1 do
    local it = r.GetTrackMediaItem(tr, i)
    local take = r.GetActiveTake(it)
    if take then
      local p = measure_peak_for_take(take)
      if p > maxpeak then maxpeak = p end
    end
  end

  return maxpeak
end

---------------------------------------------------------
-- Main
---------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  -- 1) Profil laden
  local profiles_path = df95_root() .. "ReampSuite/DF95_ReampSuite_Profiles.lua"
  local profiles_mod, err = safe_require(profiles_path)
  if not profiles_mod or type(profiles_mod) ~= "table" or type(profiles_mod.get_active_key) ~= "function" then
    r.ShowMessageBox(
      "Konnte DF95_ReampSuite_Profiles.lua nicht laden.\n\nFehler: " .. tostring(err or "?") ..
      "\nPfad: " .. profiles_path,
      "DF95 ReampSuite – AutoGain",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – AutoGain (Fehler: Profiles)", -1)
    return
  end

  local active_key = profiles_mod.get_active_key()
  if not active_key or active_key == "" then
    r.ShowMessageBox(
      "Kein aktives Reamp-Profil gefunden.\n\nBitte zuerst im ReampSuite-Router ein Profil wählen.",
      "DF95 ReampSuite – AutoGain",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – AutoGain (kein Profil)", -1)
    return
  end

  -- 2) Ziel-Tracks bestimmen
  local tracks, from_selection = collect_target_tracks()
  if not tracks or #tracks == 0 then
    r.ShowMessageBox(
      "Keine Ziel-Tracks gefunden.\n\n" ..
      "Bitte entweder ReampReturn-Tracks selektieren oder sicherstellen,\n" ..
      "dass die ReampReturn-Tracks 'ReampReturn' im Namen haben.",
      "DF95 ReampSuite – AutoGain",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – AutoGain (keine Tracks)", -1)
    return
  end

  -- 3) Peaks analysieren
  local global_peak = 0.0
  local per_track = {}

  for _, tr in ipairs(tracks) do
    local name = get_track_name(tr)
    local p = measure_peak_for_track(tr)
    per_track[#per_track+1] = { track = tr, name = name, peak = p }
    if p > global_peak then global_peak = p end
  end

  if global_peak <= 0 then
    r.ShowMessageBox(
      "Es konnten keine sinnvollen Peaks gemessen werden (globaler Peak = 0).\n\n" ..
      "Bitte sicherstellen, dass auf den ReampReturn-Tracks Items mit Audio liegen.",
      "DF95 ReampSuite – AutoGain",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – AutoGain (Peak = 0)", -1)
    return
  end

  local current_peak_db = db_from_amp(global_peak)
  if current_peak_db == -math.huge then
    r.ShowMessageBox(
      "Berechnung des aktuellen Peaks ist fehlgeschlagen (logarithmischer Fehler).",
      "DF95 ReampSuite – AutoGain",
      0
    )
    r.Undo_EndBlock("DF95 ReampSuite – AutoGain (log Fehler)", -1)
    return
  end

  -- 4) Gain-Offset berechnen
  local gain_db = TARGET_PEAK_DB - current_peak_db

  if gain_db >  MAX_ABS_GAIN_DB then gain_db =  MAX_ABS_GAIN_DB end
  if gain_db < -MAX_ABS_GAIN_DB then gain_db = -MAX_ABS_GAIN_DB end

  local gain_amp = amp_from_db(gain_db)

  -- 5) ExtState setzen
  local ext_ns = "DF95_REAMP"
  local ext_key = "OUT_GAIN_DB_" .. tostring(active_key)
  r.SetExtState(ext_ns, ext_key, string.format("%.2f", gain_db), true)

  local applied_tracks = 0
  if APPLY_GAIN_TO_TRACKS and math.abs(gain_db) > 0.01 then
    for _, info in ipairs(per_track) do
      local tr = info.track
      local cur_vol = r.GetMediaTrackInfo_Value(tr, "D_VOL") or 1.0
      local new_vol = cur_vol * gain_amp
      r.SetMediaTrackInfo_Value(tr, "D_VOL", new_vol)
      applied_tracks = applied_tracks + 1
    end
  end

  r.UpdateArrange()

  local msg = string.format(
    "DF95 ReampSuite – AutoGain abgeschlossen.\n\n" ..
    "Aktives Profil: %s\n" ..
    "Globaler Peak:  %.2f dBFS\n" ..
    "Ziel-Peak:      %.2f dBFS\n" ..
    "Gain-Offset:    %.2f dB\n" ..
    "Gespeichert in: %s / %s\n" ..
    "Tracks analysiert: %d\n" ..
    "Tracks mit angewendetem Gain: %d\n\n" ..
    "Hinweis:\n" ..
    "- APPLY_GAIN_TO_TRACKS = %s (im Script änderbar)\n" ..
    "- OUT_GAIN_DB_%s kann später im Router ausgewertet werden,\n" ..
    "  um den Hardware-Out-Gain für dieses Profil anzupassen.",
    tostring(active_key),
    current_peak_db,
    TARGET_PEAK_DB,
    gain_db,
    ext_ns,
    ext_key,
    #per_track,
    applied_tracks,
    tostring(APPLY_GAIN_TO_TRACKS),
    tostring(active_key)
  )

  r.ShowMessageBox(msg, "DF95 ReampSuite – AutoGain", 0)
  r.Undo_EndBlock("DF95 ReampSuite – AutoGain", -1)
end

main()
