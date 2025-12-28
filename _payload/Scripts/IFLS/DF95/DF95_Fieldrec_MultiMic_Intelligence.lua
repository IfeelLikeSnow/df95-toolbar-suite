-- DF95_Fieldrec_MultiMic_Intelligence.lua
-- Phase 108: Multi-Mic Intelligence – Gruppenbildung & Level-Balancing
--
-- IDEE
-- ====
-- Dieses Script soll dir helfen, typische Live-Drum-Multi-Mic-Sets automatisch
-- sinnvoll zu gruppieren und grob auszubalancieren – ohne dein kreatives
-- Tuning zu ersetzen.
--
-- KONZEPT:
--   * Du selektierst deine Drum-Mic-Tracks (Kick In/Out/Sub, Snare Top/Bottom, OHs, Rooms, etc.).
--   * Script analysiert Tracknamen und ordnet:
--        - Instrument-Kategorie (Kick, Snare, Hats, Toms, OH, Room, FX, etc.)
--        - Sub-Rolle innerhalb dieser Kategorie (In/Out/Sub, Top/Bottom, Close/Room, etc.)
--   * Für jede Kategorie:
--        - Es wird (falls nötig) ein [IFLS Sum] <Kategorie>-Track gesucht/erstellt.
--        - Von allen Mic-Tracks werden Sends zu diesem Sum-Track angelegt.
--        - Die Send-Pegel werden nach heuristischen Defaults gesetzt, z.B.:
--             Kick In  :  0 dB
--             Kick Out : -3 dB
--             Kick Sub : -6 dB
--             Snare Top   :  0 dB
--             Snare Bottom: -6 dB
--             Overheads   : -4 dB
--             Rooms       : -6..-8 dB
--
-- Du kannst dieses Script:
--   * direkt nach der Aufnahme verwenden, um einen "Startpunkt" zu bekommen,
--   * vor/parallel zu DF95_Fieldrec_CategoryAware_SliceRouter einsetzen,
--   * in deinen OneClick-Workflow einbauen (Phase 107), z.B.:
--       Slicing → MultiMic_Intelligence → CategoryAware_SliceRouter → Modulation → UCS-Export
--
-- HINWEIS:
--   Dies ist eine Heuristik, kein Mischer-Ersatz. Feintuning immer nach Ohren!

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function lower(s) return (s or ""):lower() end

local function track_category_from_name(name)
  local s = lower(name or "")

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
  if s:find("tom") then
    return "Tom"
  end
  if s:find("clap") then
    return "Clap"
  end
  if s:find("shaker") or s:find("shak") then
    return "Shaker"
  end
  if s:find("perc") or s:find("percussion") then
    return "Perc"
  end
  if s:find("oh") or s:find("overhead") then
    return "Overhead"
  end
  if s:find("room") then
    return "Room"
  end
  if s:find("fx") or s:find("rise") or s:find("impact") or s:find("whoosh") then
    return "FX"
  end
  if s:find("noise") or s:find("hiss") then
    return "Noise"
  end
  return "Misc"
end

local function track_subrole_from_name(cat, name)
  local s = lower(name or "")

  if cat == "Kick" then
    if s:find("sub") or s:find("subkick") then return "Sub" end
    if s:find("out") or s:find("outside") or s:find("front") then return "Out" end
    if s:find("in") or s:find("inside") then return "In" end
    return "In"
  elseif cat == "Snare" then
    if s:find("bottom") or s:find("bot") then return "Bottom" end
    if s:find("top") then return "Top" end
    return "Top"
  elseif cat == "Tom" then
    if s:find("floor") or s:find("ft") then return "Floor" end
    if s:find("rack") or s:find("rt") then return "Rack" end
    return "Close"
  elseif cat == "Overhead" then
    if s:find(" l") or s:find(" left") or s:find("l_") then return "L" end
    if s:find(" r") or s:find(" right") or s:find("r_") then return "R" end
    return "Stereo"
  elseif cat == "Room" then
    if s:find("far") then return "Far" end
    if s:find("near") then return "Near" end
    return "Room"
  else
    return "Close"
  end
end

local function find_or_create_track_by_name(name)
  local proj = 0
  local num = r.CountTracks(proj)
  for i = 0, num-1 do
    local tr = r.GetTrack(proj, i)
    local _, tr_name = r.GetTrackName(tr)
    if tr_name == name then
      return tr
    end
  end

  r.InsertTrackAtIndex(num, true)
  local tr = r.GetTrack(proj, num)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function ensure_send(src_tr, dst_tr, gain_db)
  if not src_tr or not dst_tr then return end
  local proj = 0
  local num_sends = r.GetTrackNumSends(src_tr, 0) -- 0 = sends
  for i = 0, num_sends-1 do
    local dest = r.BR_GetMediaTrackSendInfo_Track(src_tr, 0, i, 1)
    if dest == dst_tr then
      if gain_db then
        r.SetTrackSendInfo_Value(src_tr, 0, i, "D_VOL", 10^(gain_db / 20))
      end
      return
    end
  end
  local send_idx = r.CreateTrackSend(src_tr, dst_tr)
  local g = gain_db or 0.0
  r.SetTrackSendInfo_Value(src_tr, 0, send_idx, "D_VOL", 10^(g / 20))
end

------------------------------------------------------------
-- Heuristische Balance-Tabelle
------------------------------------------------------------

local function target_send_gain_db(cat, subrole)
  cat = cat or "Misc"
  subrole = subrole or "Close"

  if cat == "Kick" then
    if subrole == "In" then return 0.0 end
    if subrole == "Out" then return -3.0 end
    if subrole == "Sub" then return -6.0 end
    return -3.0
  elseif cat == "Snare" then
    if subrole == "Top" then return 0.0 end
    if subrole == "Bottom" then return -6.0 end
    return -3.0
  elseif cat == "Tom" then
    if subrole == "Floor" then return 0.0 end
    if subrole == "Rack" then return -1.5 end
    return -3.0
  elseif cat == "Overhead" then
    return -4.0
  elseif cat == "Room" then
    if subrole == "Far" then return -8.0 end
    if subrole == "Near" then return -6.0 end
    return -6.0
  elseif cat == "FX" or cat == "Noise" then
    return -6.0
  else
    return -3.0
  end
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local proj = 0
  local num_sel_tr = r.CountSelectedTracks(proj)
  if num_sel_tr == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\nBitte wähle deine Drum-Mic-Tracks aus (Kick In/Out/Sub, Snare Top/Bottom, OH, Rooms, etc.)\nund starte das Script erneut.",
      "DF95 Fieldrec Multi-Mic Intelligence",
      0
    )
    return
  end

  -- 1) Tracks nach Kategorie & Subrole gruppieren
  local cats = {} -- cat -> { sum_tr = track, members = { {tr, subrole} ... } }

  for i = 0, num_sel_tr-1 do
    local tr = r.GetSelectedTrack(proj, i)
    local _, name = r.GetTrackName(tr)
    local cat = track_category_from_name(name)
    local sub = track_subrole_from_name(cat, name)

    if not cats[cat] then
      cats[cat] = { members = {} }
    end
    table.insert(cats[cat].members, { track = tr, name = name, subrole = sub })
  end

  r.Undo_BeginBlock()
  msg("=== DF95 Fieldrec Multi-Mic Intelligence ===")

  for cat, info in pairs(cats) do
    local members = info.members or {}
    if #members > 0 then
      msg(string.format("Kategorie %s: %d Mic-Track(s)", cat, #members))

      -- SUM-Track suchen/erstellen
      local sum_name = string.format("[IFLS Sum] %s", cat)
      local sum_tr = find_or_create_track_by_name(sum_name)
      info.sum_tr = sum_tr

      -- Für jedes Mitglied: Send zum Sum mit heuristischem Pegel
      for _, m in ipairs(members) do
        local subrole = m.subrole
        local target_db = target_send_gain_db(cat, subrole)
        msg(string.format("  - %s (%s) -> %s @ %.1f dB", m.name or "?", subrole or "?", sum_name, target_db))
        ensure_send(m.track, sum_tr, target_db)
      end
    end
  end

  r.Undo_EndBlock("DF95 Fieldrec Multi-Mic Intelligence", -1)

  r.ShowMessageBox(
    "Multi-Mic-Intelligenz abgeschlossen.\n\n" ..
    "Für alle selektierten Tracks wurden Kategorien & Subrollen abgeleitet\n" ..
    "und passende Sends zu [IFLS Sum] <Kategorie>-Tracks mit heuristischen Pegeln erstellt.\n\n" ..
    "Nutze dies als Startpunkt und feintune nach Gehör.",
    "DF95 Fieldrec Multi-Mic Intelligence",
    0
  )
end

main()
