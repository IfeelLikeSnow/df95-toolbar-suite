-- @description DF95_V105_AdaptiveSampleEngine_FieldrecKit
-- @version 1.0
-- @author DF95
-- @about
--   Adaptive Sample Engine für Fieldrec-basierte Kits in DF95.
--
--   Idee:
--     - Nutzt die selektierten Items (typischerweise Slices aus V95/V98),
--       versucht Kick/Snare/Hat/Extra-Kategorien zu erkennen (Item-Notes,
--       Namen etc.) und baut daraus ein "Availability"-Profil.
--     - Wenn Kategorien fehlen oder sehr wenige Slices haben, werden
--       Fallback-Zuordnungen und virtuelle Duplikate berechnet.
--     - Speichert alles in Project-ExtStates (DF95_ADAPTIVE/*), so dass
--       BeatEngines (V102, Euclid, zukünftige Versionen) wissen:
--         * wie viele Kicks/Snares/Hats vorhanden sind
--         * ob Fallbacks nötig sind (z.B. Snare->Hat)
--         * welche Item-GUIDs als Pool dienen können.
--
--   WICHTIG:
--     - Dieses Script verändert kein Audio-Material und erstellt noch keinen Beat.
--       Es bereitet nur die "Sample-Welt" vor.
--     - Beat-Erzeugung bleibt bei:
--         * V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist
--         * Euclid-MultiLane (V104)
--
--   Typischer Workflow:
--     1. Fieldrec aufnehmen, slicen, klassifizieren (V95/V95.2).
--     2. Relevante Slices selektieren (oder den Kit-Track mit allen Slices).
--     3. DF95_V105_AdaptiveSampleEngine_FieldrecKit ausführen:
--         -> DF95_ADAPTIVE/* wird gesetzt.
--     4. Danach V102/V104 nutzen, die auf diesem Pool aufbauen können
--        (zukünftig: Artist-abhängige Sample-Pick-Logic).
--

local r = reaper

------------------------------------------------------------
-- Helper: GUID von Item holen
------------------------------------------------------------
local function guid_from_item(it)
  local _, g = r.GetSetMediaItemInfo_String(it, "GUID", "", false)
  return g
end

------------------------------------------------------------
-- Helper: Item-Note (SWS) oder -Notiz
------------------------------------------------------------
local function get_item_note(it)
  if r.ULT_GetMediaItemNote then
    local note = r.ULT_GetMediaItemNote(it)
    if note and note ~= "" then return note end
  end
  -- Fallback: Notizen über P_EXT? (nicht standard)
  return ""
end

------------------------------------------------------------
-- Helper: Name des Items (Take-Name) + Track-Name
------------------------------------------------------------
local function get_item_name_and_track(it)
  local tk = r.GetActiveTake(it)
  local name = ""
  if tk then
    local _, tn = r.GetSetMediaItemTakeInfo_String(tk, "P_NAME", "", false)
    name = tn or ""
  end
  local tr = r.GetMediaItem_Track(it)
  local _, trname = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  return name or "", trname or ""
end

------------------------------------------------------------
-- Kategorie-Erkennung (heuristisch)
------------------------------------------------------------


------------------------------------------------------------
-- AIWorker-Notes auswerten (optional)
------------------------------------------------------------

local function get_aiworker_role(it)
  local ok, notes = r.GetSetMediaItemInfo_String(it, "P_NOTES", "", false)
  if not ok or not notes or notes == "" then return nil end

  local start_pos = notes:find("%[DF95 AIWorker%]")
  if not start_pos then return nil end

  local block = notes:sub(start_pos)
  local sep = block:find("\n\n")
  if sep then
    block = block:sub(1, sep-1)
  end

  local role = nil
  for line in block:gmatch("[^\r\n]+") do
    local k, v = line:match("^([^=]+)=(.*)$")
    if k and v then
      k = k:lower()
      v = v:match("^%s*(.-)%s*$")
      if k == "role" and v ~= "" then
        role = v:upper()
        break
      end
    end
  end

  return role
end


local function classify_item(it)

  local note = (get_item_note(it) or ""):lower()
  local iname, tname = get_item_name_and_track(it)
  iname = (iname or ""):lower()
  tname = (tname or ""):lower()

  local text = note .. " " .. iname .. " " .. tname

  -- 0) AIWorker-Rolle (falls vorhanden) priorisieren
  local ai_role = get_aiworker_role(it)
  if ai_role then
    if ai_role:find("KICK") then return "KICK" end
    if ai_role:find("SNARE") or ai_role:find("RIM") then return "SNARE" end
    if ai_role:find("HAT") or ai_role:find("HIHAT") or ai_role:find("CYMBAL") then return "HAT" end
    if ai_role:find("PERC") or ai_role:find("TOM") or ai_role:find("CLAP") or ai_role:find("FX") then
      return "PERC"
    end
  end

  -- 1) Explizite Tags in Item-Notes (z.B. von V95) priorisieren
  if note:find("%[kick%]") or note:find("class:kick") then return "KICK" end
  if note:find("%[snare%]") or note:find("class:snare") then return "SNARE" end
  if note:find("%[hat%]") or note:find("class:hat") or note:find("class:hihat") then return "HAT" end
  if note:find("class:perc") or note:find("%[perc%]") then return "PERC" end

  -- 2) Name-basierte Heuristik
  if text:find("kick") or text:find("bd") or text:find("bassdrum") or text:find("kik") then
    return "KICK"
  end
  if text:find("snare") or text:find("sn") or text:find("rim") then
    return "SNARE"
  end
  if text:find("hat") or text:find("hh") or text:find("hihat") then
    return "HAT"
  end
  if text:find("perc") or text:find("tom") or text:find("clap") or text:find("fx") then
    return "PERC"
  end

  return "OTHER"

end

------------------------------------------------------------
-- Adaptive Pool bauen
------------------------------------------------------------

local function analyze_selected_items()
  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then
    r.ShowMessageBox("Keine Items selektiert. Bitte Slices/Kit-Items auswählen.", "DF95 V105 AdaptiveSampleEngine", 0)
    return nil
  end

  local cats = {
    KICK = {},
    SNARE = {},
    HAT = {},
    PERC = {},
    OTHER = {},
  }

  for i = 0, cnt-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local cat = classify_item(it)
    local guid = guid_from_item(it)
    table.insert(cats[cat], guid)
  end

  return cats
end

------------------------------------------------------------
-- Fallback-Regeln / virtuelle Duplikate
------------------------------------------------------------

local function build_adaptive_profile(cats)
  -- Zielwerte für "reichen aus":
  local target = {
    KICK = 4,
    SNARE = 6,
    HAT = 8,
    PERC = 4,
  }

  local profile = {
    KICK  = { pool = cats.KICK,  fallback = nil, virtual_count = 0 },
    SNARE = { pool = cats.SNARE, fallback = nil, virtual_count = 0 },
    HAT   = { pool = cats.HAT,   fallback = nil, virtual_count = 0 },
    PERC  = { pool = cats.PERC,  fallback = nil, virtual_count = 0 },
  }

  -- Hilfsfunktion: erste GUID aus einer Liste (oder nil)
  local function any_guid(list)
    if #list > 0 then return list[1] end
    return nil
  end

  -- Fallback-Kette für fehlende KICKs
  if #profile.KICK.pool == 0 then
    profile.KICK.fallback = "PERC"
    if #cats.PERC == 0 then
      profile.KICK.fallback = "OTHER"
    end
  end

  -- Fallback SNARE
  if #profile.SNARE.pool == 0 then
    if #cats.PERC > 0 then
      profile.SNARE.fallback = "PERC"
    elseif #cats.HAT > 0 then
      profile.SNARE.fallback = "HAT"
    else
      profile.SNARE.fallback = "OTHER"
    end
  end

  -- Fallback HAT
  if #profile.HAT.pool == 0 then
    if #cats.PERC > 0 then
      profile.HAT.fallback = "PERC"
    else
      profile.HAT.fallback = "OTHER"
    end
  end

  -- PERC-Fallback (falls gewünscht)
  if #profile.PERC.pool == 0 then
    profile.PERC.fallback = "OTHER"
  end

  -- Virtuelle Duplikate (wenn zu wenige reale Slices)
  for key, p in pairs(profile) do
    local needed = target[key] or 0
    local have = #p.pool
    if have == 0 then
      -- wir gehen davon aus, dass Fallback-Kategorie später mehrfach benutzt wird
      p.virtual_count = needed
    elseif have < needed then
      p.virtual_count = needed - have
    else
      p.virtual_count = 0
    end
  end

  return profile
end

------------------------------------------------------------
-- Project-ExtStates schreiben (DF95_ADAPTIVE/*)
------------------------------------------------------------

local function write_profile_to_extstate(cats, profile)
  local sect = "DF95_ADAPTIVE"

  -- Counts pro Kategorie
  r.SetProjExtState(0, sect, "KICK_REAL_COUNT", tostring(#cats.KICK))
  r.SetProjExtState(0, sect, "SNARE_REAL_COUNT", tostring(#cats.SNARE))
  r.SetProjExtState(0, sect, "HAT_REAL_COUNT", tostring(#cats.HAT))
  r.SetProjExtState(0, sect, "PERC_REAL_COUNT", tostring(#cats.PERC))
  r.SetProjExtState(0, sect, "OTHER_COUNT", tostring(#cats.OTHER))

  local function join_guids(list)
    return table.concat(list, ";")
  end

  r.SetProjExtState(0, sect, "KICK_GUIDS", join_guids(cats.KICK))
  r.SetProjExtState(0, sect, "SNARE_GUIDS", join_guids(cats.SNARE))
  r.SetProjExtState(0, sect, "HAT_GUIDS", join_guids(cats.HAT))
  r.SetProjExtState(0, sect, "PERC_GUIDS", join_guids(cats.PERC))
  r.SetProjExtState(0, sect, "OTHER_GUIDS", join_guids(cats.OTHER))

  -- Fallback-Zuordnungen
  for key, p in pairs(profile) do
    local fb_key = key .. "_FALLBACK"
    r.SetProjExtState(0, sect, fb_key, p.fallback or "")
    local virt_key = key .. "_VIRTUAL_COUNT"
    r.SetProjExtState(0, sect, virt_key, tostring(p.virtual_count or 0))
  end
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  local cats = analyze_selected_items()
  if not cats then
    r.Undo_EndBlock("DF95 V105 AdaptiveSampleEngine (keine Items)", -1)
    return
  end

  local profile = build_adaptive_profile(cats)
  write_profile_to_extstate(cats, profile)

  local msg_lines = {}
  local function add(line) msg_lines[#msg_lines+1] = line end

  add("DF95_V105 Adaptive Sample Engine – Analyse")
  add("")
  add("KICK:  " .. #cats.KICK .. " (Fallback: " .. (profile.KICK.fallback or "none") ..
      ", virtuelle Duplikate: " .. tostring(profile.KICK.virtual_count) .. ")")
  add("SNARE: " .. #cats.SNARE .. " (Fallback: " .. (profile.SNARE.fallback or "none") ..
      ", virtuelle Duplikate: " .. tostring(profile.SNARE.virtual_count) .. ")")
  add("HAT:   " .. #cats.HAT .. " (Fallback: " .. (profile.HAT.fallback or "none") ..
      ", virtuelle Duplikate: " .. tostring(profile.HAT.virtual_count) .. ")")
  add("PERC:  " .. #cats.PERC .. " (Fallback: " .. (profile.PERC.fallback or "none") ..
      ", virtuelle Duplikate: " .. tostring(profile.PERC.virtual_count) .. ")")
  add("OTHER: " .. #cats.OTHER)
  add("")
  add("Details sind in Project-ExtStates unter DF95_ADAPTIVE/* gespeichert.")
  add("Zukünftige BeatEngines können diese Infos nutzen, um bei fehlenden")
  add("Samples sinnvolle Ersatz-/Duplikat-Logik anzuwenden.")

  r.ShowMessageBox(table.concat(msg_lines, "\n"), "DF95 V105 AdaptiveSampleEngine", 0)

  r.Undo_EndBlock("DF95 V105 AdaptiveSampleEngine", -1)
end

main()
