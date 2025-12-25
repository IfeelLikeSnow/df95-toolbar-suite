-- DF95_Fieldrec_SamplerMapping_Exporter.lua
-- Phase 110: Sampler-Mapping-Exporter für UCS-Samples
--
-- IDEE
-- =====
-- Dieses Script erzeugt eine Mapping-Datei (CSV), die deine exportierten
-- Samples (z.B. aus IFLS_UCS_Export) in eine einfache, sampler-freundliche
-- Struktur beschreibt:
--
--   * Category   (Kick, Snare, HihatClosed, FX, ...)
--   * Velocity   (Soft, Med, Hard, UNK)
--   * RR         (Round-Robin Index, 1..N)
--   * MidiNote   (z.B. 36 für Kick)
--   * NoteName   (z.B. C1)
--   * RelativePath (Pfad relativ zum Sample-Root-Folder)
--
-- ANNAHME:
--   * Deine Samples liegen in einem Ordner (z.B. IFLS_Exports/PACK_XYZ).
--   * Die Dateinamen enthalten Hinweise:
--       - Kategorie (Kick/KIC, Snare/SNR, Hihat/HHC/HHO, etc.)
--       - Velocity-Token: "Soft", "Med"/"Medium", "Hard" (optional)
--       - Round-Robin-Token: "RR1", "RR2", ... (optional)
--   * Falls keine Tokens vorhanden sind, werden sinnvolle Defaults gesetzt.
--
-- WORKFLOW:
--   1. Du wählst im Dialog den "Sample Root Folder" (dort, wo deine UCS-Exports liegen).
--   2. Script scannt rekursiv alle .wav-Dateien.
--   3. Mapping wird als CSV gespeichert:
--        <SampleRoot>/IFLS_SamplerMapping_Phase110.csv
--
-- Diese CSV kannst du nutzen, um:
--   * eigene Mapping-Scripte für Sampler zu füttern,
--   * Round-Robin/Velocity-Zonen zu bauen,
--   * einen Überblick über dein Pack zu bekommen.

local r = reaper

------------------------------------------------------------
-- Helpers: Pfade & Strings
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function lower(s) return (s or ""):lower() end

local function strip_trailing_sep(path)
  if not path then return "" end
  local sep = package.config:sub(1,1)
  if path:sub(-1) == sep then
    return path:sub(1, -2)
  end
  return path
end

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  a = strip_trailing_sep(a or "")
  if a == "" then return b end
  return a .. sep .. b
end

------------------------------------------------------------
-- Kategorie & Tokens aus Dateinamen ermitteln
------------------------------------------------------------

local function category_from_filename(fname)
  local s = lower(fname or "")

  -- Prefixtypen (UCS/Custom Kürzel)
  if s:match("^kic") then return "Kick" end
  if s:match("^snr") then return "Snare" end
  if s:match("^hhc") then return "HihatClosed" end
  if s:match("^hho") then return "HihatOpen" end
  if s:match("^clp") then return "Clap" end
  if s:match("^tom") then return "Tom" end
  if s:match("^prc") then return "Perc" end
  if s:match("^fx")  then return "FX" end
  if s:match("^noi") then return "Noise" end

  -- Vollworte / allgemeine Heuristik
  if s:find("kick") or s:find("bd") or s:find("bassdrum") then
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

local function velocity_from_filename(fname)
  local s = lower(fname or "")
  if s:find("soft") or s:find("_sf") then
    return "Soft"
  end
  if s:find("hard") or s:find("_hr") then
    return "Hard"
  end
  if s:find("med") or s:find("medium") or s:find("_md") then
    return "Med"
  end
  return "UNK"
end

local function rr_from_filename(fname)
  local s = lower(fname or "")
  local num = s:match("rr(%d+)")
  if num then
    local n = tonumber(num)
    if n and n > 0 then return n end
  end
  return 1
end

------------------------------------------------------------
-- MIDI-Noten pro Kategorie
------------------------------------------------------------

local midi_map = {
  Kick         = { note = 36, name = "C1"  },
  Snare        = { note = 38, name = "D1"  },
  HihatClosed  = { note = 42, name = "F#1" },
  HihatOpen    = { note = 46, name = "A#1" },
  Clap         = { note = 39, name = "D#1" },
  Tom          = { note = 45, name = "A1"  },
  Shaker       = { note = 82, name = "A#5" },
  Perc         = { note = 60, name = "C4"  },
  FX           = { note = 49, name = "C#2" },
  Noise        = { note = 57, name = "A2"  },
  Misc         = { note = 60, name = "C4"  },
}

local function midi_info_for_category(cat)
  local info = midi_map[cat]
  if info then return info.note, info.name end
  return 60, "C4"
end

------------------------------------------------------------
-- Verzeichnis rekursiv scannen
------------------------------------------------------------

local function scan_wavs(root)
  local files = {}
  local sep = package.config:sub(1,1)

  local function scan_dir(path)
    local i = 0
    while true do
      local fname = r.EnumerateFiles(path, i)
      if not fname then break end
      if lower(fname):match("%.wav$") then
        table.insert(files, join_path(path, fname))
      end
      i = i + 1
    end
    i = 0
    while true do
      local dname = r.EnumerateSubdirectories(path, i)
      if not dname then break end
      scan_dir(join_path(path, dname))
      i = i + 1
    end
  end

  scan_dir(root)
  return files
end

------------------------------------------------------------
-- User Input: Root-Ordner
------------------------------------------------------------

local function ask_root_folder()
  local default_root = strip_trailing_sep(r.GetResourcePath()) .. package.config:sub(1,1) .. "IFLS_Exports"
  local ok, input = r.GetUserInputs(
    "IFLS Sampler Mapping Export",
    1,
    "Sample Root Folder:",
    default_root
  )
  if not ok or not input or input == "" then
    return nil
  end
  return strip_trailing_sep(input)
end

------------------------------------------------------------
-- CSV schreiben
------------------------------------------------------------

local function write_csv(root, entries)
  if #entries == 0 then return nil, "no entries" end
  local csv_path = join_path(root, "IFLS_SamplerMapping_Phase110.csv")
  local f, err = io.open(csv_path, "w")
  if not f then return nil, err end

  f:write("Category,Velocity,RR,MidiNote,NoteName,RelativePath\n")
  for _, e in ipairs(entries) do
    local line = string.format(
      "%s,%s,%d,%d,%s,%s\n",
      e.category,
      e.velocity,
      e.rr,
      e.midi_note,
      e.midi_name,
      e.rel_path
    )
    f:write(line)
  end
  f:close()
  return csv_path
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local root = ask_root_folder()
  if not root then return end

  r.Undo_BeginBlock()

  msg("=== IFLS Sampler Mapping Export (Phase 110) ===")
  msg("Root: " .. tostring(root))

  local wavs = scan_wavs(root)
  msg(string.format("Gefundene WAV-Dateien: %d", #wavs))

  if #wavs == 0 then
    r.ShowMessageBox(
      "Keine .wav-Dateien im angegebenen Ordner gefunden.\nBitte prüfe den Pfad.",
      "IFLS Sampler Mapping Export",
      0
    )
    r.Undo_EndBlock("IFLS Sampler Mapping Export (no files)", -1)
    return
  end

  local entries = {}
  local cat_counts = {}

  local root_len = #root

  for _, fullpath in ipairs(wavs) do
    local fname = fullpath:match("([^/\\]+)$") or fullpath
    local cat = category_from_filename(fname)
    local vel = velocity_from_filename(fname)
    local rr  = rr_from_filename(fname)
    local note, notename = midi_info_for_category(cat)

    local rel = fullpath:sub(root_len+2) -- +1 für sep, +1 Indexbasis

    table.insert(entries, {
      category   = cat,
      velocity   = vel,
      rr         = rr,
      midi_note  = note,
      midi_name  = notename,
      rel_path   = rel,
    })

    cat_counts[cat] = (cat_counts[cat] or 0) + 1
  end

  local csv_path, err = write_csv(root, entries)
  if not csv_path then
    r.ShowMessageBox(
      "Fehler beim Schreiben der CSV:\n" .. tostring(err),
      "IFLS Sampler Mapping Export",
      0
    )
    r.Undo_EndBlock("IFLS Sampler Mapping Export (failed)", -1)
    return
  end

  msg("=== Kategorie-Übersicht ===")
  for cat, count in pairs(cat_counts) do
    msg(string.format("  %s: %d Files", cat, count))
  end
  msg("Mapping CSV: " .. tostring(csv_path))

  r.Undo_EndBlock("IFLS Sampler Mapping Export", -1)

  r.ShowMessageBox(
    "Sampler-Mapping exportiert.\n\n" ..
    "Datei: " .. tostring(csv_path) .. "\n\n" ..
    "Spalten:\n" ..
    "  Category, Velocity, RR, MidiNote, NoteName, RelativePath\n\n" ..
    "Diese CSV kannst du in eigene Tools/Scripts/Sampler konvertieren.",
    "IFLS Sampler Mapping Export",
    0
  )
end

main()
