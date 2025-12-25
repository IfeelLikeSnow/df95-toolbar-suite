-- @description DF95 Fieldrec → AIWorker Tags to Items
-- @version 1.0
-- @author DF95
-- @about
--   Liest das neueste DF95_AIWorker_UCSResult_*.json aus dem AIWorker-Results-Ordner
--   und schreibt die dort enthaltenen AI-Infos (Material, Instrument, UCS-Felder, Tags)
--   zurück auf die passenden Items im aktuellen Projekt.
--
--   Typischer Workflow:
--     1. Fieldrec-Projekt: relevante Items auswählen
--     2. DF95_Fieldrec_AIWorker_Bridge_FromProject.lua ausführen → Job
--     3. Python-AIWorker mit diesem Job laufen lassen → Result-JSON
--     4. Dieses Script ausführen:
--        - sucht das neueste Result-JSON
--        - mappt die Einträge auf MediaItems (per Source-File)
--        - schreibt AI-Infos in Item Notes / Take-Namen
--        - färbt Items anhand Drum-Rolle (Kick/Snare/HiHat/Tom/FX/Ambience)
--
--   Hinweis:
--     * Dieses Script ändert NICHT die SampleDB; es schreibt nur Metadaten ins Projekt.
--     * Es erwartet, dass der Python-AIWorker Result-Einträge mit Pfadangaben liefert
--       (z.B. full_path / path / file) und Felder wie material / instrument / ucs_* / ai_tags.

local r = reaper

------------------------------------------------------------
-- Pfad- & FS-Utils
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function get_aiworker_paths()
  local root = join_path(get_resource_path(), "Support")
  root = join_path(root, "DF95_AIWorker")
  local jobs   = join_path(root, "Jobs")
  local result = join_path(root, "Results")
  local logs   = join_path(root, "Logs")
  return root, jobs, result, logs
end

------------------------------------------------------------
-- JSON-Lesen (DF95_ReadJSON)
------------------------------------------------------------

local function read_json(path)
  local res = get_resource_path()
  local sroot = join_path(join_path(res, "Scripts"), "IfeelLikeSnow")
  sroot = join_path(sroot, "DF95")
  local reader_path = join_path(sroot, "DF95_ReadJSON.lua")
  local ok, reader = pcall(dofile, reader_path)
  if not ok or type(reader) ~= "function" then
    return nil, "DF95_ReadJSON.lua konnte nicht geladen werden: " .. tostring(reader)
  end
  local ok2, data = pcall(reader, path)
  if not ok2 then
    return nil, "Fehler beim Lesen von JSON: " .. tostring(data)
  end
  return data, nil
end

------------------------------------------------------------
-- Neuestes Result-File finden
------------------------------------------------------------

local function find_latest_result()
  local _, _, results_dir, _ = get_aiworker_paths()
  if not results_dir or results_dir == "" then
    return nil, "Results-Ordner nicht gefunden."
  end

  local latest_name, latest_full = nil, nil
  local i = 0
  while true do
    local fname = reaper.EnumerateFiles(results_dir, i)
    if not fname then break end
    if fname:match("^DF95_AIWorker_UCSResult_.*%.json$") then
      local full = join_path(results_dir, fname)
      if not latest_name or fname > latest_name then
        latest_name, latest_full = fname, full
      end
    end
    i = i + 1
  end

  if not latest_full then
    return nil, "Kein DF95_AIWorker_UCSResult_*.json im Results-Ordner gefunden."
  end
  return latest_full, nil
end

------------------------------------------------------------
-- Drum-Rollen & Farben
------------------------------------------------------------

local function classify_drum_role(material, instrument, tags)
  local s = ""
  if material then s = s .. " " .. tostring(material) end
  if instrument then s = s .. " " .. tostring(instrument) end
  if type(tags) == "table" then
    for _, t in ipairs(tags) do
      s = s .. " " .. tostring(t)
    end
  elseif type(tags) == "string" then
    s = s .. " " .. tags
  end
  s = s:lower()

  -- einfache Heuristik; Fein-Tuning kann im Python-Worker passieren
  if s:find("kick") or s:find("bd") or s:find("bassdrum") then
    return "KICK"
  end
  if s:find("snare") or s:find("sd") or s:find("rimshot") then
    return "SNARE"
  end
  if s:find("hihat") or s:find("hi%-hat") or s:find("hi_hat") or s:find("hh ") or s:find(" hh") then
    return "HIHAT"
  end
  if s:find("tom") or s:find("tomh") or s:find("toml") then
    return "TOM"
  end
  if s:find("perc") or s:find("shaker") or s:find("clap") then
    return "PERC"
  end
  if s:find("fx") or s:find("impact") or s:find("whoosh") or s:find("rise") or s:find("hit") then
    return "FX"
  end
  if s:find("amb") or s:find("ambience") or s:find("room") or s:find("atmo") then
    return "AMBIENCE"
  end
  return nil
end

local function color_for_role(role)
  -- einfache, feste Farbpalette
  if role == "KICK" then
    return 255, 80, 80
  elseif role == "SNARE" then
    return 80, 160, 255
  elseif role == "HIHAT" then
    return 230, 230, 80
  elseif role == "TOM" then
    return 255, 160, 80
  elseif role == "PERC" then
    return 180, 255, 180
  elseif role == "FX" then
    return 200, 120, 255
  elseif role == "AMBIENCE" then
    return 120, 200, 255
  end
  return nil
end

------------------------------------------------------------
-- Helper: Items im Projekt nach Source-File indexieren
------------------------------------------------------------

local function build_item_index()
  local index = {}
  local proj = 0
  local num_tracks = reaper.CountTracks(proj)
  for ti = 0, num_tracks-1 do
    local tr = reaper.GetTrack(proj, ti)
    local num_items = reaper.CountTrackMediaItems(tr)
    for ii = 0, num_items-1 do
      local it = reaper.GetTrackMediaItem(tr, ii)
      local take = reaper.GetActiveTake(it)
      if take then
        local src = reaper.GetMediaItemTake_Source(take)
        local _, fn = reaper.GetMediaSourceFileName(src, "", 2048)
        if fn ~= "" then
          local key = fn:gsub("\\", "/")
          index[key] = index[key] or {}
          table.insert(index[key], { item = it, take = take, track = tr })
        end
      end
    end
  end
  return index
end

local function normalize_path_for_index(p)
  if not p or p == "" then return "" end
  p = p:gsub("\\", "/")
  return p
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  reaper.Undo_BeginBlock()

  local result_path, err = find_latest_result()
  if not result_path then
    reaper.ShowMessageBox(
      "DF95 Fieldrec → AIWorker Tags to Items:\n\n" ..
      tostring(err) .. "\n\n" ..
      "Bitte stelle sicher, dass der Python-AIWorker Result-JSONs im\n" ..
      "Ordner Support/DF95_AIWorker/Results erzeugt.",
      "DF95 Fieldrec → AIWorker", 0
    )
    reaper.Undo_EndBlock("DF95 Fieldrec → AIWorker Tags to Items (kein Result)", -1)
    return
  end

  local data, jerr = read_json(result_path)
  if not data then
    reaper.ShowMessageBox(
      "DF95 Fieldrec → AIWorker Tags to Items:\n\nFehler beim Lesen von:\n" ..
      tostring(result_path) .. "\n\n" .. tostring(jerr),
      "DF95 Fieldrec → AIWorker", 0
    )
    reaper.Undo_EndBlock("DF95 Fieldrec → AIWorker Tags to Items (JSON-Fehler)", -1)
    return
  end

  local results = data.results or data.entries or data or {}
  if type(results) ~= "table" then
    reaper.ShowMessageBox(
      "DF95 Fieldrec → AIWorker Tags to Items:\n\nUnerwartete Struktur im Result-JSON:\n" ..
      tostring(result_path),
      "DF95 Fieldrec → AIWorker", 0
    )
    reaper.Undo_EndBlock("DF95 Fieldrec → AIWorker Tags to Items (Strukturfehler)", -1)
    return
  end

  local index = build_item_index()
  local updated_items = 0
  local total_matches = 0

  for _, res in ipairs(results) do
    local full = res.full_path or res.path or res.file or res.filename
    if full and full ~= "" then
      local key = normalize_path_for_index(full)
      local items = index[key]
      if items and #items > 0 then
        total_matches = total_matches + #items

        local mat = res.df95_material or res.material
        local inst = res.df95_instrument or res.instrument
        local ai_conf = res.ai_confidence or res.confidence or res.ai_conf
        local tags = res.ai_tags or res.tags
        local ucs_cat = (res.ucs and res.ucs.category) or res.ucs_category
        local ucs_sub = (res.ucs and res.ucs.subcategory) or res.ucs_subcategory
        local ucs_desc = (res.ucs and res.ucs.description) or res.ucs_description

        local pn = res.proposed_new
        if pn then
          if not mat and pn.material then mat = pn.material end
          if not inst and pn.instrument then inst = pn.instrument end
          if not ucs_cat and pn.ucs_category then ucs_cat = pn.ucs_category end
          if not ucs_sub and pn.ucs_subcategory then ucs_sub = pn.ucs_subcategory end
          if not ucs_desc and pn.ucs_description then ucs_desc = pn.ucs_description end
        end

        local role = nil
        local drum_role = res.drum_role or res.drumRole or res.role
        if type(drum_role) == "string" and drum_role ~= "" then
          local up = drum_role:upper()
          -- normalize some common variants
          if up == "BD" or up == "BASSDRUM" then up = "KICK" end
          if up == "HH" or up == "HIHAT" then up = "HIHAT" end
          role = up
        else
          role = classify_drum_role(mat, inst, tags)
        end
        local cr, cg, cb = nil, nil, nil
        if role then
          cr, cg, cb = color_for_role(role)
        end

        for _, info in ipairs(items) do
          local it = info.item
          local take = info.take
          local _, notes = reaper.GetSetMediaItemInfo_String(it, "P_NOTES", "", false)
          notes = notes or ""

          local ai_block_lines = {}
          table.insert(ai_block_lines, "[DF95 AIWorker]")
          if mat then table.insert(ai_block_lines, "material=" .. tostring(mat)) end
          if inst then table.insert(ai_block_lines, "instrument=" .. tostring(inst)) end
          if ucs_cat or ucs_sub or ucs_desc then
            local ucs_str = string.format("ucs=%s|%s|%s", tostring(ucs_cat or ""), tostring(ucs_sub or ""), tostring(ucs_desc or ""))
            table.insert(ai_block_lines, ucs_str)
          end
          if ai_conf then
            table.insert(ai_block_lines, "confidence=" .. tostring(ai_conf))
            if res.drum_confidence then
              table.insert(ai_block_lines, "drum_confidence=" .. tostring(res.drum_confidence))
            end
          end
          if tags then
            if type(tags) == "table" then
              table.insert(ai_block_lines, "tags=" .. table.concat(tags, ","))
            else
              table.insert(ai_block_lines, "tags=" .. tostring(tags))
            end
          end
          if role then
            table.insert(ai_block_lines, "role=" .. role)
          end
          local ai_block = table.concat(ai_block_lines, "\n")

          local new_notes
          if notes == "" then
            new_notes = ai_block
          else
            new_notes = notes .. "\n\n" .. ai_block
          end
          reaper.GetSetMediaItemInfo_String(it, "P_NOTES", new_notes, true)

          if take then
            local _, tname = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            tname = tname or ""
            local base_name = tname
            if base_name == "" and inst then
              base_name = tostring(inst)
            elseif base_name == "" and mat then
              base_name = tostring(mat)
            end
            if base_name ~= "" then
              if role and not base_name:lower():find(role:lower()) then
                base_name = role .. " - " .. base_name
              end
              reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", base_name, true)
            end
          end

          if cr and cg and cb then
            local color = reaper.ColorToNative(cr, cg, cb) | 0x1000000
            reaper.SetMediaItemInfo_Value(it, "I_CUSTOMCOLOR", color)
          end

          updated_items = updated_items + 1
        end
      end
    end
  end

  reaper.UpdateArrange()

  local msg = string.format(
    "DF95 Fieldrec → AIWorker Tags to Items abgeschlossen.\n\n" ..
    "Result-File: %s\n\n" ..
    "Gematchte Items    : %d\n" ..
    "Aktualisierte Items: %d\n\n" ..
    "Hinweis:\n" ..
    "  * Material/Instrument/UCS/Tags wurden in die Item Notes geschrieben.\n" ..
    "  * Falls eine Drum-Rolle erkannt wurde (Kick/Snare/HiHat/Tom/Perc/FX/Ambience),\n" ..
    "    wurde das Item entsprechend eingefärbt und der Take-Name angepasst.",
    tostring(result_path), total_matches, updated_items
  )

  reaper.ShowMessageBox(msg, "DF95 Fieldrec → AIWorker Tags to Items", 0)
  reaper.Undo_EndBlock("DF95 Fieldrec → AIWorker Tags to Items", -1)
end

main()
