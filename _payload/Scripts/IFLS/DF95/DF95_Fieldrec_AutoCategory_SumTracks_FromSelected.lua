-- DF95_Fieldrec_AutoCategory_SumTracks_FromSelected.lua
-- Phase 105: Automatische Kategorisierung & Summen-Busse aus ausgewählten Mic-Tracks
--
-- IDEE
-- ====
-- Dieses Script ist dafür gedacht, im Fieldrec-Workflow nach/um das "Slicing"
-- herum eingesetzt zu werden. Es erledigt zwei Dinge:
--
--   1. Es nimmt alle aktuell selektierten Tracks (Mic-Tracks deiner live Aufnahme),
--      analysiert die Namen und ordnet sie Kategorien zu:
--        Kick, Snare, HihatClosed, HihatOpen, Tom, Clap, Perc, Shaker, FX, Noise, Misc
--
--   2. Für jede Kategorie, in der mindestens ein Track existiert:
--        * Wird ein SUM-Bus angelegt: "[IFLS Sum] <Kategorie>"
--          (z.B. "[IFLS Sum] Kick"), auf den alle Mic-Tracks dieser Kategorie senden.
--        * Optional wird ein leerer Slices-Track angelegt:
--          "[IFLS Slices] <Kategorie>"
--          → Hier können deine Slice-Scripts später ihre Items ablegen.
--
-- Damit hast du:
--   * pro Mikrofon weiterhin eigene Tracks (mit deiner bestehenden Mic-FX-Kette),
--   * einen Bus als "Summe" der Kategorie,
--   * und einen dedizierten Slices-Track, der schon passend benannt ist.
--
-- Du kannst dieses Script:
--   * direkt nach dem Slicing ausführen,
--   * oder in einen Custom-Action packen:
--       "Slicing" → "AutoCategory & SumTracks" → "Modulation Panel öffnen" etc.

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function lower(s) return (s or ""):lower() end

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
-- Main
------------------------------------------------------------

local function main()
  local proj = 0
  local num_sel_tr = r.CountSelectedTracks(proj)
  if num_sel_tr == 0 then
    r.ShowMessageBox(
      "Keine Tracks selektiert.\nBitte wähle deine Mic-Tracks (Kick In/Out, Snare Top/Bottom, FX, etc.) aus\nund starte das Script erneut.",
      "DF95 Fieldrec AutoCategory & SumTracks",
      0
    )
    return
  end

  -- Tracks nach Kategorie gruppieren
  local cats = {}  -- cat -> {tracks = {tr1, tr2, ...}}
  for i = 0, num_sel_tr-1 do
    local tr = r.GetSelectedTrack(proj, i)
    local _, name = r.GetTrackName(tr)
    local cat = track_category_from_name(name)
    if not cats[cat] then
      cats[cat] = { tracks = {} }
    end
    table.insert(cats[cat].tracks, tr)
  end

  r.Undo_BeginBlock()

  msg("=== DF95 Fieldrec AutoCategory & SumTracks ===")
  for cat, info in pairs(cats) do
    local tracks = info.tracks or {}
    msg(string.format("Kategorie %s: %d Track(s)", cat, #tracks))

    -- SUM-Bus
    if #tracks >= 1 then
      local sum_name = string.format("[IFLS Sum] %s", cat)
      local sum_tr = find_or_create_track_by_name(sum_name)
      info.sum_tr = sum_tr

      -- Slices-Track
      local slices_name = string.format("[IFLS Slices] %s", cat)
      local slices_tr = find_or_create_track_by_name(slices_name)
      info.slices_tr = slices_tr

      -- Sends von allen Mic-Tracks zur Summe
      for _, src_tr in ipairs(tracks) do
        ensure_send(src_tr, sum_tr, 0.0) -- 0 dB, das kannst du später anpassen
      end

      msg(string.format("  -> Sum-Track: %s", sum_name))
      msg(string.format("  -> Slices-Track: %s", slices_name))
    end
  end

  r.Undo_EndBlock("DF95 Fieldrec AutoCategory & SumTracks", -1)

  r.ShowMessageBox(
    "Auto-Kategorisierung & SumTracks abgeschlossen.\n\n" ..
    "Für jede gefundene Kategorie wurden erstellt/verwendet:\n" ..
    "  * [IFLS Sum] <Kategorie>\n" ..
    "  * [IFLS Slices] <Kategorie>\n\n" ..
    "Mic-Tracks senden nun auf den jeweiligen Sum-Track.\n" ..
    "Deine Slicing-Scripts können Slices später z.B. auf den [IFLS Slices]-Tracks ablegen.",
    "DF95 Fieldrec AutoCategory & SumTracks",
    0
  )
end

main()
