-- DF95_Fieldrec_OneClick_DrumFactory.lua
-- Phase 107: One-Click Workflow – Slice → Category → Modulate → UCS-Export
--
-- WICHTIG:
-- Dieses Script ist als "Kleber" gedacht, der bereits existierende IFLS/DF95-Scripts
-- in einer sinnvollen Reihenfolge aufruft. Es nimmt an, dass folgende Dateien
-- im System vorhanden sind (Pfadangaben relativ zu diesem Script):
--
--   1) Dein Slicing-Script (manuell einzutragen, siehe CONFIG_SLICER_PATH)
--   2) DF95_Fieldrec_CategoryAware_SliceRouter.lua
--   3) DF95_Modulation_Panel_Hub_ImGui.lua (optional, für visuelle Modulation)
--   4) IFLS_UCS_Export_FromSelectedItems.lua
--
-- Idee:
--   * Du nimmst live auf (mehrere Mic-Tracks).
--   * Du startest DIESES Script:
--       - ruft dein Slice-Script auf
--       - kategorisiert die Slices und routet sie (Sum, Slices, FX-Busse)
--       - optional öffnet es das Modulation Panel
--       - exportiert die Slices als UCS-benannte Samples
--
-- Du kannst einzelne Schritte via CONFIG ein-/ausschalten.

local r = reaper

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local CONFIG = {
  -- Pfad zu deinem Slicing-Script relativ zu DIESEM Script.
  -- Beispiel:
  --   "DF95_Fieldrec_Slicing_FromItems.lua"
  --   "DF95_V170_Fieldrec_Fusion_Export_GUI.lua" (falls dort ein "Slice"-Modus existiert)
  --
  -- Wenn du kein automatisches Slicing willst, kannst du diesen Eintrag leer lassen
  -- und stattdessen VORHER manuell slicen.
  slicer_script_relpath = "",

  -- Category-Aware Slice Router (Phase 106)
  router_script_relpath = "DF95_Fieldrec_CategoryAware_SliceRouter.lua",

  -- Modulation Panel (optional)
  modulation_panel_relpath = "DF95_Modulation_Panel_Hub_ImGui.lua",
  open_modulation_panel    = true,  -- Panel nach Routing öffnen?

  -- UCS-Export Script
  ucs_export_relpath = "../IFLS/Tools/IFLS_UCS_Export_FromSelectedItems.lua",

  -- Nach der Kategorie-Routing-Phase: welche Items exportieren?
  -- "slices_tracks" -> Script selektiert alle Items auf den [IFLS Slices] <Kategorie>-Tracks
  -- "current_selection" -> es wird mit der bestehenden Item-Selektion gearbeitet
  export_item_mode = "slices_tracks",
}

------------------------------------------------------------
-- Helper: Pfadauflösung
------------------------------------------------------------

local function get_this_script_dir()
  local _, this_path = r.get_action_context()
  if not this_path or this_path == "" then
    return nil
  end
  local sep = package.config:sub(1,1)
  return this_path:match("^(.*"..sep..")")
end

local function build_path(relpath)
  if not relpath or relpath == "" then return nil end
  local base = get_this_script_dir()
  if not base then return nil end
  local sep = package.config:sub(1,1)
  -- Normalisieren
  relpath = relpath:gsub("[/\\\\]", sep)
  return base .. relpath
end

local function file_exists(path)
  if not path or path == "" then return false end
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function run_script_by_path(path)
  if not path or path == "" then return true end
  if not file_exists(path) then
    r.ShowMessageBox(
      "Konnte Script nicht finden:\n" .. tostring(path),
      "DF95 OneClick DrumFactory",
      0
    )
    return false
  end
  dofile(path)
  return true
end

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

------------------------------------------------------------
-- Helper: Kategorie-Slices-Tracks finden & Items selektieren
------------------------------------------------------------

local function is_slices_track_name(name)
  if not name then return false end
  return name:match("^%[IFLS Slices%] ")
end

local function select_all_items_on_slices_tracks()
  local proj = 0
  local num_tracks = r.CountTracks(proj)
  -- Deselektiere alles
  r.Main_OnCommand(40289, 0) -- Unselect all items

  local any = false
  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetTrackName(tr)
    if is_slices_track_name(name) then
      local num_items = r.CountTrackMediaItems(proj, tr)
      for j = 0, num_items-1 do
        local item = r.GetTrackMediaItem(tr, j)
        r.SetMediaItemSelected(item, true)
        any = true
      end
    end
  end
  r.UpdateArrange()
  return any
end

------------------------------------------------------------
-- Hauptworkflow
------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()
  msg("=== DF95_Fieldrec_OneClick_DrumFactory – Start ===")

  -- 1) SLICING (optional)
  if CONFIG.slicer_script_relpath ~= "" then
    local slicer_path = build_path(CONFIG.slicer_script_relpath)
    msg("-> Running slicer: " .. tostring(slicer_path))
    if not run_script_by_path(slicer_path) then
      r.Undo_EndBlock("DF95 OneClick DrumFactory (FAILED at slicer)", -1)
      return
    end
  else
    msg("-> Kein Slicing-Script konfiguriert. Nutze vorhandene Items als Slices.")
  end

  -- 2) CATEGORY-AWARE ROUTING
  if CONFIG.router_script_relpath and CONFIG.router_script_relpath ~= "" then
    local router_path = build_path(CONFIG.router_script_relpath)
    msg("-> Running category-aware slice router: " .. tostring(router_path))
    if not run_script_by_path(router_path) then
      r.Undo_EndBlock("DF95 OneClick DrumFactory (FAILED at router)", -1)
      return
    end
  else
    msg("-> Kein Router-Script konfiguriert, überspringe Kategorie-Routing.")
  end

  -- 3) MODULATION PANEL (optional)
  if CONFIG.open_modulation_panel and CONFIG.modulation_panel_relpath and CONFIG.modulation_panel_relpath ~= "" then
    local mod_path = build_path(CONFIG.modulation_panel_relpath)
    msg("-> Opening Modulation Panel: " .. tostring(mod_path))
    run_script_by_path(mod_path) -- auch wenn es fehlschlägt, geht Workflow weiter
  else
    msg("-> Modulation Panel nicht automatisch geöffnet.")
  end

  -- 4) UCS EXPORT
  local export_path = build_path(CONFIG.ucs_export_relpath)
  if not file_exists(export_path) then
    r.ShowMessageBox(
      "Konnte das UCS-Export-Script nicht finden:\n" .. tostring(export_path) ..
      "\nBitte passe CONFIG.ucs_export_relpath an.",
      "DF95 OneClick DrumFactory",
      0
    )
    r.Undo_EndBlock("DF95 OneClick DrumFactory (FAILED at UCS export – script missing)", -1)
    return
  end

  if CONFIG.export_item_mode == "slices_tracks" then
    msg("-> Selektiere alle Items auf [IFLS Slices] <Kategorie>-Tracks für den Export.")
    local any = select_all_items_on_slices_tracks()
    if not any then
      r.ShowMessageBox(
        "Keine Items auf [IFLS Slices] <Kategorie>-Tracks gefunden.\n" ..
        "Bitte prüfe, ob der Category-Aware Router zuvor korrekt gelaufen ist.",
        "DF95 OneClick DrumFactory",
        0
      )
      r.Undo_EndBlock("DF95 OneClick DrumFactory (FAILED at UCS export – no slice items)", -1)
      return
    end
  else
    msg("-> Nutze bestehende Item-Selektion für den UCS-Export.")
  end

  msg("-> Running UCS Export: " .. tostring(export_path))
  run_script_by_path(export_path)

  r.Undo_EndBlock("DF95 OneClick DrumFactory", -1)
  msg("=== DF95_Fieldrec_OneClick_DrumFactory – Done ===")
end

main()
