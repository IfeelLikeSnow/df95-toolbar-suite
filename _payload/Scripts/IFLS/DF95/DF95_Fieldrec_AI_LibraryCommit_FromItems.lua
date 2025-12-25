-- @description DF95 Fieldrec AI Library Commit (Regions from AI-Items)
-- @version 1.0
-- @author DF95
-- @about
--   Erstellt aus AI-annotierten Items (DF95 AIWorker Tags in Item Notes)
--   automatisch Regions mit UCS-basierten Namen – als Vorbereitung für
--   Region-Render/PackExporter und Library-Build.
--
--   Fokus dieser ersten Version:
--     * Es werden KEINE Dateien geschrieben oder SampleDB-Einträge geändert.
--       Stattdessen:
--         - werden Regions im Projekt angelegt
--         - die Namen basieren auf AI-Infos (UCS, Rolle, Instrument, Material)
--         - optionale farbliche Kodierung nach Drum-Rolle
--
--   Typischer Workflow:
--     1. Fieldrec aufnehmen, Slices erzeugen
--     2. AIWorker-Bridge + Python-AIWorker + ApplyToItems laufen lassen
--     3. Dieses Script ausführen:
--        - für die besten Slices pro Rolle+Instrument werden Regions erzeugt
--     4. Region Render Matrix / PackExporter nutzen, um Library-Files zu rendern.
--
--   Konfiguration:
--     * BESTOF_MODE:
--         true  = nur bestes Item pro (Rolle+Instrument) wird berücksichtigt
--         false = alle AI-annotierten Items werden in Regions verwandelt

local r = reaper

------------------------------------------------------------
-- Konfiguration
------------------------------------------------------------

local BESTOF_MODE = true -- siehe @about

------------------------------------------------------------
-- Utils
------------------------------------------------------------

local function format_time(t)
  return r.format_timestr(t, "")
end

local function get_track_name(tr)
  local ok, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if not ok or name == "" then
    local idx = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    return string.format("Track %d", idx)
  end
  return name
end

local function parse_ai_block(notes)
  if not notes or notes == "" then return nil end

  local start_pos = notes:find("%[DF95 AIWorker%]")
  if not start_pos then return nil end

  local block = notes:sub(start_pos)
  local sep = block:find("\n\n")
  if sep then
    block = block:sub(1, sep-1)
  end

  local lines = {}
  for line in block:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  if #lines == 0 or not lines[1]:match("%[DF95 AIWorker%]") then
    return nil
  end

  local info = {
    raw_block = block,
  }

  for i = 2, #lines do
    local line = lines[i]
    local k, v = line:match("^([^=]+)=(.*)$")
    if k and v then
      k = k:lower()
      v = v:match("^%s*(.-)%s*$")
      if k == "material" then
        info.material = v
      elseif k == "instrument" then
        info.instrument = v
      elseif k == "confidence" then
        info.confidence = tonumber(v)
      elseif k == "tags" then
        info.tags_raw = v
        local tags = {}
        for t in v:gmatch("([^,]+)") do
          tags[#tags+1] = t:match("^%s*(.-)%s*$")
        end
        info.tags = tags
      elseif k == "ucs" then
        local c, s, d = v:match("^(.-)|(.-)|(.*)$")
        info.ucs_category = c
        info.ucs_subcategory = s
        info.ucs_description = d
      elseif k == "role" then
        info.role = v:upper()
      end
    end
  end

  return info
end

local function build_ai_items()
  local items = {}
  local proj = 0
  local num_tracks = r.CountTracks(proj)
  for ti = 0, num_tracks-1 do
    local tr = r.GetTrack(proj, ti)
    local tr_name = get_track_name(tr)
    local num_items = r.CountTrackMediaItems(tr)
    for ii = 0, num_items-1 do
      local it = r.GetTrackMediaItem(tr, ii)
      local take = r.GetActiveTake(it)
      local ok, notes = r.GetSetMediaItemInfo_String(it, "P_NOTES", "", false)
      notes = notes or ""
      if notes:find("%[DF95 AIWorker%]") then
        local ai = parse_ai_block(notes)
        if ai then
          local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
          local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
          items[#items+1] = {
            track = tr,
            track_name = tr_name,
            item = it,
            take = take,
            pos = pos,
            len = len,
            ai = ai,
          }
        end
      end
    end
  end

  table.sort(items, function(a, b)
    if a.track ~= b.track then
      local ta = r.GetMediaTrackInfo_Value(a.track, "IP_TRACKNUMBER")
      local tb = r.GetMediaTrackInfo_Value(b.track, "IP_TRACKNUMBER")
      if ta == tb then
        return a.pos < b.pos
      end
      return ta < tb
    end
    return a.pos < b.pos
  end)

  return items
end

local function sanitize_filename(s)
  if not s or s == "" then
    return ""
  end
  s = s:gsub("[/:\\%*%?\"<>|]", "_")
  s = s:gsub("%s+", "_")
  s = s:gsub("__+", "_")
  return s
end

local function role_color(role)
  if role == "KICK" then
    return r.ColorToNative(255, 80, 80) | 0x1000000
  elseif role == "SNARE" then
    return r.ColorToNative(80, 160, 255) | 0x1000000
  elseif role == "HIHAT" then
    return r.ColorToNative(230, 230, 80) | 0x1000000
  elseif role == "TOM" then
    return r.ColorToNative(255, 160, 80) | 0x1000000
  elseif role == "PERC" then
    return r.ColorToNative(180, 255, 180) | 0x1000000
  elseif role == "FX" then
    return r.ColorToNative(200, 120, 255) | 0x1000000
  elseif role == "AMBIENCE" then
    return r.ColorToNative(120, 200, 255) | 0x1000000
  end
  return 0
end

local function propose_region_name(ai)
  local cat = ai.ucs_category or ""
  local sub = ai.ucs_subcategory or ""
  local desc = ai.ucs_description or ""
  local role = ai.role or ""
  local inst = ai.instrument or ai.material or ""

  local parts = {}

  if cat ~= "" then table.insert(parts, cat) end
  if sub ~= "" then table.insert(parts, sub) end

  local desc_part = desc
  if desc_part == "" then
    if inst ~= "" then
      desc_part = inst
    elseif role ~= "" then
      desc_part = role
    end
  end
  if desc_part ~= "" then
    table.insert(parts, desc_part)
  end

  if #parts == 0 then
    if role ~= "" then
      parts = { "FX", "GEN", role }
    else
      parts = { "FX", "GEN", "Fieldrec" }
    end
  end

  local name = table.concat(parts, "_")
  return sanitize_filename(name)
end

local function bestof_filter(items)
  if not BESTOF_MODE then
    return items
  end

  local groups = {}
  for _, e in ipairs(items) do
    local ai = e.ai
    local role = ai.role or "?"
    local inst = ai.instrument or ai.material or "?"
    local key = role .. "|" .. inst
    local conf = ai.confidence or 0.0
    local g = groups[key]
    if not g or conf > (g.ai.confidence or 0.0) then
      groups[key] = e
    end
  end

  local best = {}
  for _, e in pairs(groups) do
    best[#best+1] = e
  end

  table.sort(best, function(a, b)
    local ta = r.GetMediaTrackInfo_Value(a.track, "IP_TRACKNUMBER")
    local tb = r.GetMediaTrackInfo_Value(b.track, "IP_TRACKNUMBER")
    if ta == tb then
      return a.pos < b.pos
    end
    return ta < tb
  end)

  return best
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  local ai_items = build_ai_items()
  if #ai_items == 0 then
    r.ShowMessageBox(
      "DF95 Fieldrec AI Library Commit:\n\nKeine Items mit [DF95 AIWorker]-Block in den Notes gefunden.\n\n" ..
      "Bitte zuerst:\n  * Bridge → Python AIWorker → ApplyToItems laufen lassen.",
      "DF95 Fieldrec AI Library Commit", 0
    )
    r.Undo_EndBlock("DF95 Fieldrec AI Library Commit (keine AI-Items)", -1)
    return
  end

  local items_to_use = bestof_filter(ai_items)
  if #items_to_use == 0 then
    r.ShowMessageBox(
      "DF95 Fieldrec AI Library Commit:\n\nKeine Items nach Best-of-Filter übrig.\n" ..
      "(evtl. AI-Confidence überall 0 oder fehlend?)",
      "DF95 Fieldrec AI Library Commit", 0
    )
    r.Undo_EndBlock("DF95 Fieldrec AI Library Commit (leer nach Filter)", -1)
    return
  end

  local proj = 0
  local created_regions = 0

  for _, e in ipairs(items_to_use) do
    local ai = e.ai
    local pos = e.pos
    local len = e.len
    local name = propose_region_name(ai)
    local color = role_color(ai.role or "")

    local _, region_idx = r.AddProjectMarker2(
      proj,
      true,              -- isrgn
      pos,
      pos + len,
      name,
      -1,                -- auto index
      color
    )

    if region_idx >= 0 then
      created_regions = created_regions + 1
    end
  end

  r.Undo_EndBlock("DF95 Fieldrec AI Library Commit (Regions erstellt)", -1)
  r.UpdateArrange()

  local msg = string.format(
    "DF95 Fieldrec AI Library Commit abgeschlossen.\n\n" ..
    "AI-annotierte Items gefunden : %d\n" ..
    "Best-of Mode                : %s\n" ..
    "Regions erstellt            : %d\n\n" ..
    "Hinweis:\n" ..
    "  * Regions wurden für ausgewählte AI-Items erzeugt.\n" ..
    "  * Du kannst nun die Region Render Matrix oder DF95 PackExporter nutzen,\n" ..
    "    um Library-Files mit UCS-basierten Namen zu rendern.",
    #ai_items,
    tostring(BESTOF_MODE),
    created_regions
  )

  r.ShowMessageBox(msg, "DF95 Fieldrec AI Library Commit", 0)
end

main()
