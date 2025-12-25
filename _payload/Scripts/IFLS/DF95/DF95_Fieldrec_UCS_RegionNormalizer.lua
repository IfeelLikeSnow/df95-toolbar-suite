-- @description DF95 Fieldrec – UCS Region Normalizer
-- @version 1.0
-- @author DF95
-- @about
--   Normalisiert Regions-Namen im aktuellen Projekt zu einem konsistenten,
--   UCS-inspirierten Schema:
--
--       UCS_CATEGORY_UCS_SUBCATEGORY_Descriptor
--
--   Fokus:
--     * Aus Fieldrec/AI-Workflows erzeugte Regions (z.B. durch
--       DF95_Fieldrec_AI_LibraryCommit_FromItems.lua) nachträglich
--       einheitlich bereinigen.
--     * Nur der Region-Name wird geändert; keine Dateien oder SampleDB.
--
--   Verhalten:
--     * Alle Regions werden geprüft.
--     * Die ersten beiden Tokens vor dem dritten "_" werden als
--       UCS_CATEGORY und UCS_SUBCATEGORY interpretiert.
--     * Der Rest wird als "Descriptor" behandelt.
--     * Tokens werden gesäubert (Großschreibung, unerlaubte Zeichen raus).
--
--   Beispiel:
--     "Kitchen_Dishes Handling CrashPlate" ->
--       "KITCHEN_Dishes_Handling_CrashPlate"

local r = reaper

------------------------------------------------------------
-- Konfiguration
------------------------------------------------------------

-- DRY_RUN:
--   true  = nur Vorschau in der Konsole, keine Umbenennung
--   false = Region-Namen werden wirklich gesetzt
local DRY_RUN = true

-- Nur Regions normalisieren, deren Name mindestens diese Anzahl von
-- "_" enthält (d.h. min. 3 Segmente).
local MIN_UNDERSCORES = 2

------------------------------------------------------------
-- Utils
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function sanitize_token(s, upper)
  s = s or ""
  -- Ersetze nicht-Alphanumerik durch Unterstriche
  s = s:gsub("[^%w]+", "_")
  -- Mehrere Unterstriche zusammenfassen
  s = s:gsub("_+", "_")
  -- führende/trailing _ entfernen
  s = s:gsub("^_+", "")
  s = s:gsub("_+$", "")
  if upper then
    s = s:upper()
  end
  return s
end

local function titlecase_underscore(s)
  s = s or ""
  local parts = {}
  for part in s:gmatch("[^_]+") do
    local first = part:sub(1,1):upper()
    local rest  = part:sub(2):lower()
    parts[#parts+1] = first .. rest
  end
  return table.concat(parts, "_")
end

------------------------------------------------------------
-- Region-Name Normalisierung
------------------------------------------------------------

local function normalize_region_name(name)
  if not name or name == "" then return name, false end

  -- grob spalten
  local base = name
  -- alles vor erster Leerstelle nehmen (falls jemand später Kommentare angehängt hat)
  base = base:match("^(%S+)") or base

  local underscore_count = select(2, base:gsub("_", ""))
  if underscore_count < MIN_UNDERSCORES then
    return name, false
  end

  local tokens = {}
  for tok in base:gmatch("([^_]+)") do
    tokens[#tokens+1] = tok
  end

  if #tokens < 3 then
    return name, false
  end

  local cat_raw = tokens[0+1]
  local sub_raw = tokens[0+2]
  local desc_tokens = {}
  for i = 3, #tokens do
    desc_tokens[#desc_tokens+1] = tokens[i]
  end
  local desc_raw = table.concat(desc_tokens, "_")

  local cat = sanitize_token(cat_raw, true)            -- UCS_CATEGORY im Uppercase
  local sub = sanitize_token(sub_raw, false)           -- Subcategory: später TitleCase
  sub = titlecase_underscore(sub)

  local desc = sanitize_token(desc_raw, false)
  -- Descriptor etwas lesbarer machen (TitleCase bei Unterstrichen)
  desc = titlecase_underscore(desc)

  if cat == "" or sub == "" then
    return name, false
  end

  local new_name
  if desc ~= "" then
    new_name = string.format("%s_%s_%s", cat, sub, desc)
  else
    new_name = string.format("%s_%s", cat, sub)
  end

  if new_name == name then
    return name, false
  end

  return new_name, true
end

------------------------------------------------------------
-- Hauptlogik
------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()
  r.ShowConsoleMsg("DF95 Fieldrec – UCS Region Normalizer\n")
  r.ShowConsoleMsg("DRY_RUN = " .. tostring(DRY_RUN) .. "\n\n")

  local proj = 0
  local num_markers, num_regions = r.CountProjectMarkers(proj)
  local total_checked = 0
  local total_changed = 0

  local idx = 0
  while true do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(idx)
    if retval == 0 then break end

    if isrgn then
      total_checked = total_checked + 1
      local new_name, changed = normalize_region_name(name)
      if changed then
        total_changed = total_changed + 1
        msg(string.format("Region %d: '%s'  ->  '%s'", markrgnindexnumber, name, new_name))
        if not DRY_RUN then
          r.SetProjectMarker(markrgnindexnumber, true, pos, rgnend, new_name)
        end
      end
    end

    idx = idx + 1
  end

  msg("")
  msg(string.format("Regions geprüft : %d", total_checked))
  msg(string.format("Regions geändert: %d (DRY_RUN=%s)", total_changed, tostring(DRY_RUN)))

  local undo_label = "DF95 Fieldrec – UCS Region Normalizer"
  if DRY_RUN then
    undo_label = undo_label .. " (DryRun)"
  end
  r.Undo_EndBlock(undo_label, -1)

  if total_changed == 0 then
    r.ShowMessageBox(
      "DF95 Fieldrec – UCS Region Normalizer:\n\n" ..
      "Keine Regions gefunden, deren Name nach diesem Schema normalisiert werden konnte.\n\n" ..
      "Hinweis:\n" ..
      "  * Es werden nur Regions mit mindestens " .. tostring(MIN_UNDERSCORES) .. " Unterstrichen geprüft.\n" ..
      "  * DRY_RUN ist momentan " .. tostring(DRY_RUN) .. ".",
      "DF95 Fieldrec – UCS Region Normalizer",
      0
    )
  else
    r.ShowMessageBox(
      "DF95 Fieldrec – UCS Region Normalizer abgeschlossen.\n\n" ..
      "Regions geprüft : " .. tostring(total_checked) .. "\n" ..
      "Regions geändert: " .. tostring(total_changed) .. "\n\n" ..
      "Details siehe REAPER-Konsole.\n\n" ..
      "Hinweis:\n" ..
      "  * DRY_RUN = " .. tostring(DRY_RUN) .. " (im Script anpassbar).",
      "DF95 Fieldrec – UCS Region Normalizer",
      0
    )
  end
end

main()
