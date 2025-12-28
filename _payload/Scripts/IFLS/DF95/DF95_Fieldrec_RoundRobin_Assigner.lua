-- DF95_Fieldrec_RoundRobin_Assigner.lua
-- Phase 109: Round-Robin & Velocity-Layer Engine für Slices
--
-- IDEE
-- =====
-- Dieses Script hilft dir, aus deinen Slices ein sampler-freundliches
-- Round-Robin/Velocity-System zu machen – voll kompatibel mit dem
-- bestehenden IFLS/DF95-Workflow und dem UCS-Export.
--
-- FUNKTION:
--   * Arbeitet auf:
--       - aktuell selektierten Media Items ODER
--       - (falls keine Selektion vorhanden) auf allen Items der
--         "[IFLS Slices] <Kategorie>"-Tracks.
--   * Bestimmt pro Item:
--       - Kategorie aus Tracknamen (Kick, Snare, Hats, FX, etc.)
--       - Lautheits-Skalar ("Score") für grobe Velocity-Einteilung
--   * Pro Kategorie:
--       - sortiert die Items nach Lautheit
--       - teilt sie in 3 Velocity-Layer:
--           Soft (leise), Med (mittel), Hard (laut)
--       - weist innerhalb jedes Layers Round-Robin-Nummern zu:
--           RR1, RR2, RR3, RR4 (zyklisch)
--       - setzt Take-Namen auf:
--           <Kategorie>_<Velocity>_RR<Index>
--         z.B. "Kick_Hard_RR3"
--
-- Diese Namen werden von deinen bestehenden Heuristiken verstanden:
--   * "Soft"/"Med"/"Hard" werden von IFLS_UCS_ExportEngine als Dynamik erkannt.
--   * RR-Index eignet sich perfekt für Sampler-Zonen/Round-Robin-Maps.
--
-- HINWEIS:
--   * Für "Lautheit" wird primär SWS NF_AnalyzeTakeLoudness genutzt, falls vorhanden.
--   * Ohne SWS wird eine einfache Heuristik (Item- + Take-Volume) verwendet.
--   * Feintuning bleibt dir überlassen – das Script liefert einen guten Startpunkt.

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
  if s:find("fx") or s:find("rise") or s:find("impact") or s:find("whoosh") then
    return "FX"
  end
  if s:find("noise") or s:find("hiss") then
    return "Noise"
  end
  return "Misc"
end

local function is_slices_track_name(name)
  return name and name:match("^%[IFLS Slices%] ")
end

local function get_items_from_selection_or_slices_tracks()
  local proj = 0
  local num_sel = r.CountSelectedMediaItems(proj)
  local items = {}

  if num_sel > 0 then
    for i = 0, num_sel-1 do
      local it = r.GetSelectedMediaItem(proj, i)
      table.insert(items, it)
    end
    return items, "selection"
  end

  -- Fallback: alle Items auf [IFLS Slices]-Tracks
  local num_tr = r.CountTracks(proj)
  for i = 0, num_tr-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetTrackName(tr)
    if is_slices_track_name(name) then
      local num_items = r.CountTrackMediaItems(proj, tr)
      for j = 0, num_items-1 do
        local it = r.GetTrackMediaItem(proj, j)
        table.insert(items, it)
      end
    end
  end

  return items, "slices_tracks"
end

------------------------------------------------------------
-- Lautheits-Schätzung
------------------------------------------------------------

local has_sws = (reaper.NF_AnalyzeTakeLoudness ~= nil)

local function loudness_score_for_take(take, item)
  if not take then return 0.0 end

  if has_sws then
    -- SWS: NF_AnalyzeTakeLoudness(take)
    -- Rückgabe (Stand Doku): retval, LUFSintegrated, LRA, truepeak, momentaryMax, shortTermMax, range
    local ok, LUFSi, _, truepeak = r.NF_AnalyzeTakeLoudness(take)
    if ok then
      -- LUFSi ist negativ (z.B. -18). Je kleiner (mehr negativ), desto lauter.
      -- Wir drehen das um, so dass "größer" = lauter:
      return -(LUFSi or -30)
    end
  end

  -- Fallback: einfache Volume-Heuristik
  local item_vol = r.GetMediaItemInfo_Value(item, "D_VOL") or 1.0
  local take_vol = r.GetMediaItemTakeInfo_Value(take, "D_VOL") or 1.0
  local v = item_vol * take_vol
  return v
end

------------------------------------------------------------
-- Round-Robin / Velocity-Zuweisung
------------------------------------------------------------

local function assign_rr_and_velocity_for_category(cat, entries, rr_cycles)
  if #entries == 0 then return end

  -- 1) sortieren nach loudness_score (aufsteigend: leise -> laut)
  table.sort(entries, function(a, b) return a.loudness < b.loudness end)

  local n = #entries
  if n == 0 then return end

  -- Grenzen für Soft/Med/Hard bestimmen
  local third = math.floor(n / 3)
  local idx_soft_end  = math.max(third, 1)
  local idx_hard_start = math.max(n - third + 1, idx_soft_end + 1)

  -- falls wenig Slices, fallback:
  if n <= 3 then
    idx_soft_end   = 1
    idx_hard_start = n
  end

  for i, e in ipairs(entries) do
    local vel
    if i <= idx_soft_end then
      vel = "Soft"
    elseif i >= idx_hard_start then
      vel = "Hard"
    else
      vel = "Med"
    end

    local rr_index = ((e.rr_counter - 1) % rr_cycles) + 1

    -- Take-Name setzen: <Kategorie>_<Velocity>_RR<Index>
    local new_name = string.format("%s_%s_RR%d", cat, vel, rr_index)
    r.GetSetMediaItemTakeInfo_String(e.take, "P_NAME", new_name, true)

    e.velocity = vel
    e.rr_index = rr_index
  end
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local items, mode = get_items_from_selection_or_slices_tracks()
  if #items == 0 then
    r.ShowMessageBox(
      "Keine Slices gefunden.\n\n" ..
      "Bitte wähle entweder Items aus oder stelle sicher,\n" ..
      "dass [IFLS Slices] <Kategorie>-Tracks Items enthalten.",
      "DF95 RoundRobin Assigner",
      0
    )
    return
  end

  -- Items in Kategorien aufteilen
  local cats = {} -- cat -> { entries = {} }

  for _, item in ipairs(items) do
    local tr = r.GetMediaItem_Track(item)
    if tr then
      local _, tr_name = r.GetTrackName(tr)
      local cat = track_category_from_name(tr_name)
      local take = r.GetActiveTake(item)
      if take then
        local loud = loudness_score_for_take(take, item)
        if not cats[cat] then
          cats[cat] = { entries = {}, counter = 0 }
        end
        local bucket = cats[cat]
        bucket.counter = bucket.counter + 1
        table.insert(bucket.entries, {
          item      = item,
          take      = take,
          loudness  = loud,
          rr_counter= bucket.counter,
        })
      end
    end
  end

  if not next(cats) then
    r.ShowMessageBox(
      "Keine gültigen Takes gefunden.\nSind deine Items Audio-Slices mit einem aktiven Take?",
      "DF95 RoundRobin Assigner",
      0
    )
    return
  end

  r.Undo_BeginBlock()
  msg("=== DF95 Fieldrec RoundRobin & Velocity Assigner ===")
  msg(string.format("Modus: %s, Slices: %d", mode, #items))

  local rr_cycles = 4

  for cat, info in pairs(cats) do
    msg(string.format("Kategorie %s: %d Slices", cat, #info.entries))
    assign_rr_and_velocity_for_category(cat, info.entries, rr_cycles)
  end

  r.Undo_EndBlock("DF95 RoundRobin & Velocity Assigner", -1)

  r.ShowMessageBox(
    "Round-Robin & Velocity-Zuweisung abgeschlossen.\n\n" ..
    "Die Take-Namen haben jetzt das Format:\n" ..
    "  <Kategorie>_<Soft/Med/Hard>_RR1..RR4\n\n" ..
    "Diese Informationen werden vom UCS-Export und vom Modulations-/Export-Workflow\n" ..
    "verstanden und können direkt für Sampler-Mappings genutzt werden.",
    "DF95 RoundRobin Assigner",
    0
  )
end

main()
