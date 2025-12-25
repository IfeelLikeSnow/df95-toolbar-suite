-- DF95_SlicingHub_ImGui.lua
-- Zentrales Slicing-Hub-GUI für DF95:
--  * Artist Autopilot (voller Flow)
--  * Dynamic Slicing (Transient/Gate + Length)
--  * Weighted/Classic Slicing Menu
--
-- Voraussetzung: ReaImGui installiert, DF95-Ordnerstruktur vorhanden.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui-Extension nicht gefunden.\nBitte ReaImGui installieren.", "DF95 Slicing Hub", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Slicing Hub')
local FONT = r.ImGui_CreateFont('sans-serif', 18)
r.ImGui_AttachFont(ctx, FONT)

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

------------------------------------------------------------
-- Runner für die drei Slicing-Welten
------------------------------------------------------------

local function run_autopilot_gui()
  local path = df95_root() .. "DF95_Autopilot_ArtistDynamicSlice_GUI.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    reaper.ShowMessageBox("Fehler beim Starten der Autopilot-GUI:\n"..tostring(err).."\nPfad: "..path,
      "DF95 Slicing Hub", 0)
  end
end

local function run_dynamic_browser()
  local path = df95_root() .. "DF95_SlicingBrowser_Dynamic_ImGui.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    reaper.ShowMessageBox("Fehler beim Starten des Dynamic Slicing Browsers:\n"..tostring(err).."\nPfad: "..path,
      "DF95 Slicing Hub", 0)
  end
end

local function run_weighted_menu()
  -- Klassische/Weighted Menü-Logik über DF95_Slice_Menu.lua (das intern Weighted/Dropdown/Fallback wählt)
  local path = df95_root() .. "DF95_Slice_Menu.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    reaper.ShowMessageBox("Fehler beim Starten des Slicing-Menüs:\n"..tostring(err).."\nPfad: "..path,
      "DF95 Slicing Hub", 0)
  end
end

------------------------------------------------------------
-- GUI Loop
------------------------------------------------------------

local function loop()
  reaper.ImGui_PushFont(ctx, FONT)

  reaper.ImGui_SetNextWindowSize(ctx, 420, 360, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'DF95 Slicing Hub', true)

  if visible then
    reaper.ImGui_Text(ctx, "DF95 Slicing Hub")
    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "1) Artist Autopilot")
    reaper.ImGui_TextWrapped(ctx, "Kompletter Flow: Artist → Dynamic Slice → Rearrange → Humanize → DrumSetup/Bus.")
    if reaper.ImGui_Button(ctx, "Open Artist Autopilot GUI", 380, 40) then
      run_autopilot_gui()
    end

    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "2) Dynamic Slicing")
    reaper.ImGui_TextWrapped(ctx, "Transient/Gate-basierte physische Slices mit konfigurierbarer Slice-Länge (ultra/short/medium/long).")
    if reaper.ImGui_Button(ctx, "Open Dynamic Slicing Browser", 380, 40) then
      run_dynamic_browser()
    end

    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "3) Weighted / Classic Slicing")
    reaper.ImGui_TextWrapped(ctx, "Artist-/IDM-/Euclid-Presets, Weighting & Randomization über das klassische DF95 Slicing-Menü.")
    if reaper.ImGui_Button(ctx, "Open Weighted/Classic Slicing Menu", 380, 40) then
      run_weighted_menu()
    end
    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "4) Dynamic Preset Inspector")
    reaper.ImGui_TextWrapped(ctx, "Inspect & edit Dynamic Slicing Presets (thresholds, gaps, slice-length modes) und Artist-Mappings. Mit Hüllkurven-Preview.")
    if reaper.ImGui_Button(ctx, "Open Dynamic Slicing Inspector", 380, 40) then
      local path = df95_root() .. "DF95_DynamicSlicing_Inspector_ImGui.lua"
      local ok, err = pcall(dofile, path)
      if not ok then
        reaper.ShowMessageBox("Fehler beim Starten des Dynamic Slicing Inspectors:\n"..tostring(err).."\nPfad: "..path,
          "DF95 Slicing Hub", 0)
      end
    end

    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "5) Autopilot Pipeline Visualizer")
    reaper.ImGui_TextWrapped(ctx, "Zeigt Artist → Preset → Slice Length → Rearrange → Humanize → DrumSetup als Pipeline + letzte Log-Einträge.")
    if reaper.ImGui_Button(ctx, "Open Autopilot Pipeline Visualizer", 380, 40) then
      local path = df95_root() .. "DF95_Autopilot_Pipeline_Visualizer_ImGui.lua"
      local ok, err = pcall(dofile, path)
      if not ok then
        reaper.ShowMessageBox("Fehler beim Starten des Autopilot Pipeline Visualizers:\n"..tostring(err).."\nPfad: "..path,
          "DF95 Slicing Hub", 0)
      end
    end

    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "6) ZeroCross Fade Optimizer")
    reaper.ImGui_TextWrapped(ctx, "RMS-/Transient-basierte Fade-Anpassung für geslicte Items, um Clicks zu minimieren.")
    if reaper.ImGui_Button(ctx, "Run ZeroCross Fade Optimizer", 380, 40) then
      local path = df95_root() .. "DF95_ZeroCross_FadeOptimizer.lua"
      local ok, err = pcall(dofile, path)
      if not ok then
        reaper.ShowMessageBox("Fehler beim Ausführen des ZeroCross Fade Optimizers:\n"..tostring(err).."\nPfad: "..path,
          "DF95 Slicing Hub", 0)
      end
    end


    reaper.ImGui_End(ctx)
  end

  reaper.ImGui_PopFont(ctx)

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

loop()
