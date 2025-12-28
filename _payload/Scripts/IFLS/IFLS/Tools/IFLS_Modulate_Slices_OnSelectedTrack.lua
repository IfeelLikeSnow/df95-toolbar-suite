-- IFLS_Modulate_Slices_OnSelectedTrack.lua
-- Phase 101: Slice Modulation Engine for selected track
--
-- IDEE
-- ====
-- Du hast bereits Slices erstellt und diese liegen als Items auf einem Track
-- (z.B. Kick-Slices auf einem Kick-Track, Snare-Slices auf einem Snare-Track).
--
-- Dieses Script:
--   * Nimmt den aktuell ausgewählten Track.
--   * Analysiert alle Media Items (Slices) auf diesem Track.
--   * Moduliert JEDE Slice leicht anders:
--       - Item-Lautstärke
--       - Länge / Fade-In / Fade-Out
--       - Start-Offset (kleine Timing-Variationen)
--   * Erstellt (falls noch nicht vorhanden) einen dedizierten Mod-FX-Bus
--     pro Kategorie (Kick, Snare, etc.) und legt dort eine passende FX-Kette an.
--   * Legt einen Send vom Quell-Track auf diesen FX-Bus an.
--
-- Ziel: Kein Slice klingt identisch, aber die Gesamtästhetik bleibt konsistent.
--
-- HINWEIS:
--   * Dieses Script verändert KEINE vorhandene "Mikrofon-FX-Kette" auf dem Track.
--   * Die Modulation via FX läuft über einen zusätzlichen Mod-FX-Bus (Send).
--   * Du kannst die Intensität einfach über den Send-Pegel steuern.

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function lower(s) return (s or ""):lower() end

local function strip_trailing_sep(path)
  local sep = package.config:sub(1,1)
  if not path or path == "" then return "" end
  if path:sub(-1) == sep then
    return path:sub(1, -2)
  end
  return path
end

local function join(a, b)
  local sep = package.config:sub(1,1)
  a = strip_trailing_sep(a or "")
  if a == "" then return b end
  return a .. sep .. b
end

local function clamp(x, lo, hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

------------------------------------------------------------
-- Kategorie-Heuristik aus Tracknamen
------------------------------------------------------------

local function guess_category_from_track_name(track_name)
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

------------------------------------------------------------
-- FX-Bus Management
------------------------------------------------------------

local function find_or_create_mod_bus(category)
  local proj = 0
  local num_tracks = r.CountTracks(proj)
  local target_name = string.format("[IFLS Mod FX] %s", category)

  -- Suche bestehenden Bus
  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetTrackName(tr)
    if name == target_name then
      return tr
    end
  end

  -- Erstelle neuen Bus am Ende
  r.InsertTrackAtIndex(num_tracks, true)
  local bus = r.GetTrack(proj, num_tracks)
  r.GetSetMediaTrackInfo_String(bus, "P_NAME", target_name, true)

  -- FX-Kette je Kategorie
  -- Wir nutzen nur Cockos/JS Standard-FX, damit es überall funktioniert
  local function add_fx(name)
    -- -1: am Ende einfügen
    return r.TrackFX_AddByName(bus, name, false, -1)
  end

  if category == "Kick" then
    -- Tiefen betonen, etwas Sättigung
    add_fx("ReaEQ (Cockos)")
    add_fx("JS: Saturation")
  elseif category == "Snare" then
    add_fx("ReaEQ (Cockos)")
    add_fx("ReaComp (Cockos)")
    add_fx("JS: LOSER/Exciter")
  elseif category == "HihatClosed" or category == "HihatOpen" then
    add_fx("ReaEQ (Cockos)")
    add_fx("JS: LOSER/Exciter")
  elseif category == "Tom" or category == "Perc" or category == "Shaker" then
    add_fx("ReaEQ (Cockos)")
    add_fx("ReaComp (Cockos)")
  elseif category == "FX" or category == "Noise" then
    add_fx("ReaEQ (Cockos)")
    add_fx("JS: Saturation")
  else
    add_fx("ReaEQ (Cockos)")
  end

  -- Grobe EQ-Voreinstellungen je nach Kategorie (nur sehr basic)
  local fx_count = r.TrackFX_GetCount(bus)
  for fx = 0, fx_count-1 do
    local _, fx_name = r.TrackFX_GetFXName(bus, fx, "")
    if fx_name:find("ReaEQ") then
      -- Beispiel-EQ-Settings je Kategorie (wir setzen nur ein paar Parameter)
      -- Band 1: Low Shelf, Band 4: High Shelf
      -- Param-Belegung in ReaEQ:
      --   Bypass      = 0
      --   Global Gain = 1
      --   Band1 Freq  = 2, Gain=3, Q=4, Type=5
      if category == "Kick" then
        -- Tiefe anheben, Höhen leicht abschneiden
        r.TrackFX_SetParam(bus, fx, 2, 0.1)  -- Low Shelf Freq (log, ~60 Hz)
        r.TrackFX_SetParam(bus, fx, 3, 0.65) -- Low Shelf Gain (+2..+3dB)
      elseif category == "Snare" then
        r.TrackFX_SetParam(bus, fx, 2, 0.3)  -- etwas höherer Lowcut
      elseif category == "HihatClosed" or category == "HihatOpen" then
        r.TrackFX_SetParam(bus, fx, 2, 0.4)  -- mehr Lowcut
      end
    end
  end

  return bus
end

local function ensure_send(src_tr, bus_tr)
  if not src_tr or not bus_tr then return end
  local proj = 0
  local num_sends = r.GetTrackNumSends(src_tr, 0) -- 0 = sends
  for i = 0, num_sends-1 do
    local dest = r.BR_GetMediaTrackSendInfo_Track(src_tr, 0, i, 1) -- 1=destination track
    if dest == bus_tr then
      return
    end
  end
  local send_idx = r.CreateTrackSend(src_tr, bus_tr)
  -- etwas konservativer Pegel
  r.SetTrackSendInfo_Value(src_tr, 0, send_idx, "D_VOL", 10^( -6 / 20)) -- -6 dB
end

------------------------------------------------------------
-- Item-Modulation
------------------------------------------------------------

local function random_range(a, b)
  return a + (b - a) * math.random()
end

local function modulate_items_on_track(tr, category)
  local num_items = r.CountTrackMediaItems(0, tr)
  if num_items == 0 then return 0 end

  local count = 0
  for i = 0, num_items-1 do
    local item = r.GetTrackMediaItem(tr, i)
    if item then
      count = count + 1

      -- Item Volume
      local vol = r.GetMediaItemInfo_Value(item, "D_VOL")
      -- leichte Variation +/- 3 dB
      local db_variation = random_range(-3.0, 3.0)
      local factor = 10^(db_variation / 20)
      local new_vol = vol * factor
      new_vol = clamp(new_vol, 0.05, 4.0)
      r.SetMediaItemInfo_Value(item, "D_VOL", new_vol)

      -- Item Length Variation (max +/- 15%)
      local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      local len_factor = random_range(0.85, 1.15)
      local new_len = len * len_factor
      new_len = math.max(0.01, new_len)
      r.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)

      -- Kleine Timingvariation via Start Offset (max +/- 5 ms)
      local start_offs = r.GetMediaItemInfo_Value(item, "D_STARTOFFS")
      local jitter = random_range(-0.005, 0.005) -- Sekunden im Source
      local new_offs = start_offs + jitter
      if new_offs < 0 then new_offs = 0 end
      r.SetMediaItemInfo_Value(item, "D_STARTOFFS", new_offs)

      -- Fades (leichte Varianz)
      local fadein  = random_range(0.001, 0.01)
      local fadeout = random_range(0.001, 0.02)
      r.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadein)
      r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeout)
    end
  end

  return count
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  math.randomseed(os.time())

  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox(
      "Kein Track ausgewählt.\nBitte wähle den Track mit deinen Slices aus und starte das Script erneut.",
      "IFLS Slice Modulation",
      0
    )
    return
  end

  local _, track_name = r.GetTrackName(tr)
  local category = guess_category_from_track_name(track_name)
  if not category then category = "Misc" end

  r.Undo_BeginBlock()

  -- FX-Bus finden/erstellen und Send anlegen
  local bus = find_or_create_mod_bus(category)
  ensure_send(tr, bus)

  -- Items modulieren
  local num = modulate_items_on_track(tr, category)

  r.Undo_EndBlock(string.format("IFLS Slice Modulation on '%s' (%s)", track_name, category), -1)

  if num == 0 then
    r.ShowMessageBox(
      "Auf dem ausgewählten Track wurden keine Media Items gefunden.\n" ..
      "Bitte stelle sicher, dass deine Slices als Items auf diesem Track liegen.",
      "IFLS Slice Modulation",
      0
    )
  else
    r.ShowMessageBox(
      string.format("Modulation abgeschlossen.\n\nTrack: %s\nKategorie: %s\nSlices: %d",
        track_name, category, num),
      "IFLS Slice Modulation",
      0
    )
  end
end

main()
