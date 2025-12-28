
-- @description DF95 V71 Reamp Router – Flexible Routing Setup
-- @version 1.0
-- @author DF95
--
-- Ziel:
--  - Für die vom SuperPipeline-Script gesetzten Reamp-Tracks (ExtState DF95_REAMP/TRACK_IDS)
--    einen grundlegenden Reamp-Signalweg konfigurieren:
--
--    Source Track (DI / FX Source)
--      → Hardware Out (konfigurierbar)
--      → Reamp Box / Pedale / DI
--      → Hardware In (konfigurierbar)
--      → Return Track (neu erstellt)
--
--  - Es werden KEINE Interface-spezifischen Annahmen hartkodiert.
--    Stattdessen:
--      - werden Default-Werte genutzt (z.B. Out=3, In=1)
--      - können User Overrides via ExtState setzen:
--          DF95_REAMP/OUT_CH   (z.B. '3')
--          DF95_REAMP/IN_CH    (z.B. '1')
--
--  - Der Router ist bewusst generisch gehalten; Feintuning kann je Setup erfolgen.

local r = reaper

local function get_ext(name, key, default)
  local v = r.GetExtState(name, key)
  if not v or v == "" then return default end
  return v
end

local function parse_track_ids(str)
  local ids = {}
  if not str or str == "" then return ids end
  for id in string.gmatch(str, "([^,]+)") do
    local n = tonumber(id)
    if n and n > 0 then ids[#ids+1] = n end
  end
  return ids
end

local function ensure_return_track(src_tr)
  local idx = r.CSurf_TrackToID(src_tr, false)
  local ret_idx = idx + 1
  r.InsertTrackAtIndex(ret_idx-1, true)
  local ret_tr = r.GetTrack(0, ret_idx-1)
  if ret_tr then
    local _, src_name = r.GetTrackName(src_tr)
    r.GetSetMediaTrackInfo_String(ret_tr, "P_NAME", "ReampReturn_" .. (src_name or ""), true)
  end
  return ret_tr
end

local function setup_hw_send(src_tr, out_ch)
  -- Setzt einen Hardware Output Send (z.B. zu Out 3).
  -- Reaper: I_HWOUT, I_HWOUT+...
  -- Einfachste Variante: nutze Main-Send und stelle "Master/Parent Send" aus,
  -- dann expliziten HW-Send hinzufügen.
  local master_off = 0
  r.SetMediaTrackInfo_Value(src_tr, "B_MAINSEND", master_off)

  -- create new HW out send
  local send_idx = r.CreateTrackSend(src_tr, nil) -- nil: hardware send
  if send_idx >= 0 then
    -- I_DSTCHAN: hardware output index, z.B. 2 = Out3/4 (Paare)
    -- Hier vereinfachen wir: Mono Out, Out_ch-1 als Index
    r.SetTrackSendInfo_Value(src_tr, 1, send_idx, "I_DSTCHAN", out_ch-1)
    r.SetTrackSendInfo_Value(src_tr, 1, send_idx, "D_VOL", 1.0)
  end
end

local function setup_return_input(ret_tr, in_ch)
  -- Setzt Input des Return-Tracks auf Hardware Input 'in_ch'
  -- Reaper: I_RECINPUT = 1024 + in_ch-1 (für Mono Hardware Inputs)
  local rec_in = 1024 + (in_ch-1)
  r.SetMediaTrackInfo_Value(ret_tr, "I_RECINPUT", rec_in)
  r.SetMediaTrackInfo_Value(ret_tr, "I_RECMODE", 0) -- Record: input
  r.SetMediaTrackInfo_Value(ret_tr, "I_RECARM", 1)  -- armed
  r.SetMediaTrackInfo_Value(ret_tr, "B_MAINSEND", 1) -- an Master senden
end

local function main()
  local ids_str = r.GetExtState("DF95_REAMP", "TRACK_IDS")
  if not ids_str or ids_str == "" then
    r.ShowMessageBox("Keine Reamp-Track IDs in DF95_REAMP/TRACK_IDS gefunden.\n" ..
                     "Bitte zuerst die V72 SuperPipeline mit Reamp-Kandidaten ausführen.",
                     "DF95 V71 Reamp Router", 0)
    return
  end

  local out_ch = tonumber(get_ext("DF95_REAMP", "OUT_CH", "3")) or 3
  local in_ch  = tonumber(get_ext("DF95_REAMP", "IN_CH", "1")) or 1

  if out_ch == in_ch then
    r.ShowMessageBox("Achtung: OUT_CH und IN_CH sind identisch (" .. out_ch .. ").\n" ..
                     "Das ist für Reamping problematisch (Feedback/Loop).\n" ..
                     "Bitte DF95_REAMP/OUT_CH und DF95_REAMP/IN_CH in den ExtStates anpassen.",
                     "DF95 V71 Reamp Router", 0)
    return
  end

  local ids = parse_track_ids(ids_str)
  if #ids == 0 then
    r.ShowMessageBox("Die Reamp-Trackliste ist leer.\nAbbruch.",
                     "DF95 V71 Reamp Router", 0)
    return
  end

  r.Undo_BeginBlock()

  for _, tid in ipairs(ids) do
    local tr = r.CSurf_TrackFromID(tid, false)
    if tr then
      local ret_tr = ensure_return_track(tr)
      setup_hw_send(tr, out_ch)
      if ret_tr then
        setup_return_input(ret_tr, in_ch)
      end
    end
  end

  r.Undo_EndBlock("DF95 V71 Reamp Router – Setup HW Routing", -1)
end

main()
