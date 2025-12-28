-- DF95_Fieldrec_RS5k_KitBuilder_FromCSV.lua
-- Phase 111: ReaSamplomatic-Kit-Builder aus IFLS-SamplerMapping-CSV
--
-- IDEE
-- =====
-- Dieses Script baut dir aus der Mapping-CSV (Phase 110) automatisch
-- ein ReaSamplomatic5000-Drumkit auf einem neuen Track.
--
-- WORKFLOW:
--   1. Du hast deine Samples bereits via IFLS/DF95-UCS-Workflow exportiert.
--   2. Du hast mit "DF95_Fieldrec_SamplerMapping_Exporter.lua" (Phase 110)
--      im Sample-Root eine CSV erzeugt:
--         IFLS_SamplerMapping_Phase110.csv
--   3. Du startest dieses Script:
--        * Pfad zum Sample-Root eingeben (gleich wie bei Phase 110).
--        * Script liest die CSV.
--        * Es erzeugt einen neuen Track "IFLS RS5k Kit – <Ordnername>".
--        * Für jede Zeile in der CSV wird:
--            - eine ReaSamplomatic5000-Instanz hinzugefügt,
--            - das Sample geladen,
--            - Note-Bereich auf die passende MIDI-Note gesetzt.
--
-- HINWEIS:
--   * Dieses Script setzt bewusst nur Note-Zonen und Sample-Files.
--     Velocity-Layer/Soft/Med/Hard & RR stecken in den Dateinamen/CSV
--     und können für komplexere Mappings weitergenutzt werden.
--   * Es nutzt bekannte ReaSamplomatic-Parameter-Indizes (Note Start/End/Center).
--     Je nach REAPER-Version können diese leicht variieren; bei Bedarf anpassen.

local r = reaper

------------------------------------------------------------
-- Helpers
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

local function parse_csv_line(line)
  -- Einfacher CSV-Parser für Format:
  -- Category,Velocity,RR,MidiNote,NoteName,RelativePath
  if not line or line == "" then return nil end
  if line:match("^Category") then return nil end
  local fields = {}
  for part in string.gmatch(line, "([^,]+)") do
    fields[#fields+1] = part
  end
  if #fields < 6 then return nil end
  local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
  local cat      = trim(fields[1])
  local vel      = trim(fields[2])
  local rr       = tonumber(trim(fields[3])) or 1
  local midinote = tonumber(trim(fields[4])) or 60
  local notename = trim(fields[5])
  local relpath  = trim(table.concat(fields, ",", 6)) -- falls im Pfad Kommas vorkommen
  return {
    category  = cat,
    velocity  = vel,
    rr        = rr,
    midinote  = midinote,
    notename  = notename,
    relpath   = relpath,
  }
end

local function read_mapping_csv(csv_path)
  local f, err = io.open(csv_path, "r")
  if not f then
    return nil, "Kann CSV nicht öffnen: " .. tostring(err)
  end
  local entries = {}
  for line in f:lines() do
    local e = parse_csv_line(line)
    if e then
      entries[#entries+1] = e
    end
  end
  f:close()
  return entries
end

local function ask_root_folder()
  local default_root = strip_trailing_sep(r.GetResourcePath()) .. package.config:sub(1,1) .. "IFLS_Exports"
  local ok, input = r.GetUserInputs(
    "IFLS RS5k KitBuilder (Phase 111)",
    1,
    "Sample Root Folder:",
    default_root
  )
  if not ok or not input or input == "" then
    return nil
  end
  return strip_trailing_sep(input)
end

local function get_pack_name_from_root(root)
  local sep = package.config:sub(1,1)
  local name = root:match("([^"..sep.."]+)$") or root
  return name
end

------------------------------------------------------------
-- RS5k Helpers
------------------------------------------------------------

local function add_rs5k(track, sample_path, midinote)
  local fx_index = r.TrackFX_AddByName(track, "ReaSamplomatic5000 (Cockos)", false, -1)
  if fx_index < 0 then
    return nil, "ReaSamplomatic5000 (Cockos) nicht gefunden."
  end

  -- Sample setzen
  r.TrackFX_SetNamedConfigParm(track, fx_index, "FILE0", sample_path)
  r.TrackFX_SetNamedConfigParm(track, fx_index, "MODE", "0") -- normal

  -- Note-Bereich: wir setzen Start, End und Center auf diese Note
  -- Annahme: Parameter 3=Note start, 4=Note end, 5=Note center (normalized 0..1, 0..127)
  local note = math.floor(midinote or 60)
  if note < 0 then note = 0 end
  if note > 127 then note = 127 end
  local norm = note / 127.0

  -- Sicherstellen, dass die Param-Funktionen vorhanden sind
  if r.TrackFX_SetParam then
    r.TrackFX_SetParam(track, fx_index, 3, norm)
    r.TrackFX_SetParam(track, fx_index, 4, norm)
    r.TrackFX_SetParam(track, fx_index, 5, norm)
  end

  return fx_index
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local root = ask_root_folder()
  if not root then return end

  local csv_path = join_path(root, "IFLS_SamplerMapping_Phase110.csv")
  local entries, err = read_mapping_csv(csv_path)
  if not entries then
    r.ShowMessageBox(
      "Konnte Mapping-CSV nicht lesen:\n" .. tostring(err) ..
      "\nErwarte Datei:\n" .. tostring(csv_path),
      "IFLS RS5k KitBuilder",
      0
    )
    return
  end

  if #entries == 0 then
    r.ShowMessageBox(
      "Die Mapping-CSV enthält keine Einträge.",
      "IFLS RS5k KitBuilder",
      0
    )
    return
  end

  r.Undo_BeginBlock()

  local proj = 0
  local num_tr = r.CountTracks(proj)
  r.InsertTrackAtIndex(num_tr, true)
  local kit_tr = r.GetTrack(proj, num_tr)

  local pack_name = get_pack_name_from_root(root)
  r.GetSetMediaTrackInfo_String(kit_tr, "P_NAME", "IFLS RS5k Kit – " .. pack_name, true)

  msg("=== IFLS RS5k KitBuilder (Phase 111) ===")
  msg("Root: " .. tostring(root))
  msg("CSV:  " .. tostring(csv_path))
  msg(string.format("Einträge: %d", #entries))

  local added = 0
  for _, e in ipairs(entries) do
    local sample_path = join_path(root, e.relpath)
    local f = io.open(sample_path, "rb")
    if f then
      f:close()
      local fx_index, ferr = add_rs5k(kit_tr, sample_path, e.midinote)
      if fx_index then
        added = added + 1
        msg(string.format("  + RS5k: %s (Cat=%s, Vel=%s, RR=%d, Note=%d)",
          e.relpath, e.category, e.velocity, e.rr, e.midinote))
      else
        msg("  ! Fehler beim Hinzufügen von RS5k für: " .. tostring(e.relpath) .. " – " .. tostring(ferr))
      end
    else
      msg("  ! Sample nicht gefunden: " .. tostring(sample_path))
    end
  end

  r.Undo_EndBlock("IFLS RS5k KitBuilder", -1)

  r.ShowMessageBox(
    string.format(
      "RS5k-Kit erstellt.\n\nTrack: IFLS RS5k Kit – %s\nInstanzen: %d\n\n" ..
      "Hinweis:\nJede Instanz ist auf eine MIDI-Note begrenzt.\n" ..
      "Velocity- & RR-Informationen liegen in der CSV/den Dateinamen\n" ..
      "und können für weitergehende Mappings genutzt werden.",
      pack_name, added
    ),
    "IFLS RS5k KitBuilder",
    0
  )
end

main()
