-- DF95_ArtistConsole_ImGui.lua
-- Zentrale "Artist Console" für DF95:
--   * Tab 1: FLOW  -> Artist-basierter Slicing-Autopilot (Artist + Intensity + Slice-Length + Rearrange + Humanize + Bus + ZC-Fade)
--   * Tab 2: PRESETS -> Dynamic Slicing Preset Inspector (öffnet DF95_DynamicSlicing_Inspector_ImGui.lua)
--   * Tab 3: PIPELINE -> Autopilot Pipeline Visualizer (öffnet DF95_Autopilot_Pipeline_Visualizer_ImGui.lua)
--   * Tab 4: TOOLS -> Slicing Hub, Weighted Menu, ZeroCross Optimizer etc.
--
-- Achtung:
--   Dies ist ein "Orchestrator"-GUI. Die eigentliche Logik steckt weiterhin in:
--     * DF95_Autopilot_ArtistDynamicSlice.lua
--     * DF95_Dynamic_Slicer.lua
--     * DF95_Rearrange_Align.lua
--     * DF95_Humanize_Preset_Apply.lua
--     * DF95_IDM_DrumSetup.lua (im _selectors-Ordner)
--     * DF95_ZeroCross_FadeOptimizer.lua
--     * DF95_SlicingHub_ImGui.lua / DF95_Slice_Menu.lua
--
-- Konzeption:
--   * Ein Fenster, mehrere Tabs, alle Slicing-Funktionen zentral steuern.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui-Extension nicht gefunden.\nBitte ReaImGui installieren.", "DF95 Artist Console", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Artist Console')
local FONT = r.ImGui_CreateFont('sans-serif', 18)
r.ImGui_AttachFont(ctx, FONT)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function selectors_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "_selectors" .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function msg(s)
  r.ShowMessageBox(s, "DF95 Artist Console", 0)
end


local function DF95_SetExportTag(key, value)
  if not key then return end
  reaper.SetExtState("DF95_EXPORT_TAGS", tostring(key), tostring(value or ""), true)
end

local function DF95_GetExportTag(key, default)
  if not key then return default end
  local v = reaper.GetExtState("DF95_EXPORT_TAGS", tostring(key))
  if v == nil or v == "" then return default end
  return v
end
----------------------
local DF95_Export_Presets      = nil
local DF95_Export_Preset_List  = nil
local DF95_Export_Preset_Index = 1
local DF95_Export_Core         = nil

local function DF95_LoadExportPresets()
  if DF95_Export_Presets and DF95_Export_Preset_List and DF95_Export_Core then return end
local function DF95_RunPackWizard(default_pack_label, default_dest, default_dryrun)
local function DF95_SetMobileFRProfile(profile)
  if not profile or profile == "" then return end
  if profile:lower() == "atmos" then
    reaper.SetExtState("DF95_MOBILEFR", "profile", "Atmos", true)
  else
    reaper.SetExtState("DF95_MOBILEFR", "profile", "Clean", true)
  end
end

local function DF95_GetMobileFRProfile()
  local p = reaper.GetExtState("DF95_MOBILEFR", "profile")
  if p == nil or p == "" then
    p = "Clean"
  end
  if p:lower() == "atmos" then return "Atmos" end
  return "Clean"
end

local function DF95_RunMobileFR_AutoExplodeRoute()
local function DF95_GetExportTagsSummary()
  local role     = reaper.GetExtState("DF95_EXPORT_TAGS", "Role")
  local source   = reaper.GetExtState("DF95_EXPORT_TAGS", "Source")
  local fxflavor = reaper.GetExtState("DF95_EXPORT_TAGS", "FXFlavor")

  if role == nil or role == "" then role = "Any" end
  if source == nil or source == "" then source = "Any" end
  if fxflavor == nil or fxflavor == "" then fxflavor = "Generic" end

  return role, source, fxflavor
end

local function DF95_ClearExportTags()
local function DF95_LoadLastKitMetaJSON()
  local json = reaper.GetExtState("DF95_SAMPLER_KIT_META", "last_kit")
  if not json or json == "" then return nil end
  return json
end

local function DF95_ParseRolesFromKitMeta(json)
  local roles = {}
  if not json or json == "" then return roles end
  for role in json:gmatch('"role"%s*:%s*"([^"]-)"') do
    if role ~= nil and role ~= "" and role ~= "null" and role ~= "Any" then
      roles[role] = (roles[role] or 0) + 1
    end
  end
  return roles
end

local function DF95_BuildKitMetaSummary(roles)
  local parts = {}
  for role, count in pairs(roles) do
    parts[#parts+1] = string.format("%s: %d Slots", role, count)
  end
  if #parts == 0 then
    return "Keine spezifischen Rollen im KitMeta gefunden (evtl. ältere Kits ohne Annotation oder Kit noch nicht gebaut)."
  end
  table.sort(parts)
  return table.concat(parts, "\\n")
end

local function DF95_OpenPackWizard_FromKitMeta()
  local path = df95_root() .. "DF95_PackWizard_From_KitMeta.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Starten DF95_PackWizard_From_KitMeta:\\n"..tostring(err).."\nPfad: "..path)
  end
end

local function DF95_OpenPackWizard_FromKitMeta_PerRole()
  local path = df95_root() .. "DF95_PackWizard_From_KitMeta_PerRole.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Starten DF95_PackWizard_From_KitMeta_PerRole:\\n"..tostring(err).."\nPfad: "..path)
  end
end

  reaper.SetExtState("DF95_EXPORT_TAGS", "Role", "", true)
  reaper.SetExtState("DF95_EXPORT_TAGS", "Source", "", true)
  reaper.SetExtState("DF95_EXPORT_TAGS", "FXFlavor", "", true)
end

local function DF95_IsMobileFRQAEnabled()
  local v = reaper.GetExtState("DF95_MOBILEFR", "qa_enabled")
  return (v == "1" or v == "true" or v == "yes")
end

local function DF95_SetMobileFRQAEnabled(enabled)
  reaper.SetExtState("DF95_MOBILEFR", "qa_enabled", enabled and "1" or "0", true)
end

local function DF95_IsMobileFRAutoTagEnabled()
  local v = reaper.GetExtState("DF95_MOBILEFR", "autotag_enabled")
  return (v == "1" or v == "true" or v == "yes")
end

local function DF95_SetMobileFRAutoTagEnabled(enabled)
  reaper.SetExtState("DF95_MOBILEFR", "autotag_enabled", enabled and "1" or "0", true)
end

  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return end
  local dir = script_path:match("^(.*[\\/])") or ""
  local ok, err = pcall(dofile, dir .. "DF95_Explode_AutoBus_MobileFR.lua")
  if not ok then
    reaper.ShowMessageBox("Fehler beim Start von DF95_Explode_AutoBus_MobileFR.lua:\n" .. tostring(err), "DF95 MobileFR", 0)
  end
end

  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return end
  local dir = script_path:match("^(.*[\\/])") or ""
  local ok, _ = pcall(dofile, dir .. "DF95_Export_PackWizard.lua")
  -- Der PackWizard verwendet GetExtState/SetExtState für Defaults,
  -- hier können wir optionale Startwerte setzen.
  if default_pack_label and default_pack_label ~= "" then
    reaper.SetExtState("DF95_EXPORT", "packwizard_last_label", default_pack_label, true)
  end
  if default_dest and default_dest ~= "" then
    reaper.SetExtState("DF95_EXPORT", "packwizard_last_dest", default_dest, true)
  end
  if default_dryrun ~= nil then
    reaper.SetExtState("DF95_EXPORT", "packwizard_last_dryrun", default_dryrun and "true" or "false", true)
  end
end


  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return end
  local dir = script_path:match("^(.*[\\/])") or ""
  local okP, presets = pcall(dofile, dir .. "DF95_Export_Presets.lua")
  local okC, core    = pcall(dofile, dir .. "DF95_Export_Core.lua")
  if okP and presets and presets.get_list and okC and core and core.run then
    DF95_Export_Presets     = presets
    DF95_Export_Preset_List = presets.get_list()
    DF95_Export_Core        = core
  end
end
--------------------------------------
-- Artist Liste (analog Autopilot GUI)
------------------------------------------------------------

local ARTISTS = {
  "autechre",
  "squarepusher",
  "bogdan",
  "aphextwin",
  "boc",
  "arovane",
  "monoceros",
  "janjelinek",
  "flyinglotus",
  "mouseonmars",
  "plaid",
  "apparat",
  "thomyorke",
  "jega",
  "telefontelaviv",
  "proem",
  "styrofoam"
}

------------------------------------------------------------
-- FLOW State (Tab 1)
------------------------------------------------------------

local flow_state = {
  artist = "autechre",
  intensity = "auto",
  slice_length = "medium",
  do_rearrange = true,
  do_humanize = true,
  do_drumsetup = true,
  do_zerocross = false,
}

------------------------------------------------------------
-- Runner: Autopilot & Einzel-Module
------------------------------------------------------------

local function run_autopilot_full()
  local num = r.CountSelectedMediaItems(0)
  if num == 0 then
    msg("Bitte zuerst Audio-Items selektieren (z.B. Drumloop / Stems).")
    return
  end

  -- ExtStates setzen, damit der Autopilot sie lesen kann
  r.SetProjExtState(0, "DF95_SLICING", "ARTIST", flow_state.artist)
  r.SetProjExtState(0, "DF95_SLICING", "INTENSITY", flow_state.intensity)
  r.SetProjExtState(0, "DF95_DYN", "LENGTH_MODE", flow_state.slice_length)
  r.SetProjExtState(0, "DF95_AUTOPILOT", "REARR", flow_state.do_rearrange and "yes" or "no")
  r.SetProjExtState(0, "DF95_AUTOPILOT", "HUM", flow_state.do_humanize and "yes" or "no")

  local path = df95_root() .. "DF95_Autopilot_ArtistDynamicSlice.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen des Autopilots:\n"..tostring(err).."\nPfad: "..path)
  end

  if flow_state.do_zerocross then
    local zc = df95_root() .. "DF95_ZeroCross_FadeOptimizer.lua"
    local ok2, err2 = pcall(dofile, zc)
    if not ok2 then
      msg("Fehler beim Ausführen des ZeroCross Fade Optimizers:\n"..tostring(err2).."\nPfad: "..zc)
    end
  end
end

local function run_dynamic_slice_only()
  local num = r.CountSelectedMediaItems(0)
  if num == 0 then
    msg("Bitte Audio-Items selektieren.")
    return
  end
  r.SetProjExtState(0, "DF95_SLICING", "ARTIST", flow_state.artist)
  r.SetProjExtState(0, "DF95_SLICING", "INTENSITY", flow_state.intensity)
  r.SetProjExtState(0, "DF95_DYN", "LENGTH_MODE", flow_state.slice_length)

  local path = df95_root() .. "DF95_Dynamic_Slicer.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Dynamic_Slicer.lua:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function run_rearrange_only()
  local path = df95_root() .. "DF95_Rearrange_Align.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Rearrange_Align.lua:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function run_humanize_only()
  -- nutzt das gleiche Preset-Schema wie Autopilot: artist_intensity
  local preset_name = (flow_state.artist or "artist") .. "_" .. (flow_state.intensity or "auto")
  r.SetProjExtState(0, "DF95_HUMANIZE", "PRESET_NAME", preset_name)
  local path = df95_root() .. "DF95_Humanize_Preset_Apply.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Humanize_Preset_Apply.lua:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function run_drumsetup_only()
  local path = selectors_root() .. "DF95_IDM_DrumSetup.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_IDM_DrumSetup.lua:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function run_zerocross_only()
  local zc = df95_root() .. "DF95_ZeroCross_FadeOptimizer.lua"
  local ok2, err2 = pcall(dofile, zc)
  if not ok2 then
    msg("Fehler beim Ausführen des ZeroCross Fade Optimizers:\n"..tostring(err2).."\nPfad: "..zc)
  end
end



local function load_pipeline_core()
  local path = df95_root() .. "DF95_Pipeline_Core.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Laden von DF95_Pipeline_Core.lua:\n"..tostring(mod).."\nPfad: "..path)
    return nil
  end
  return mod
end

local function pipeline_run(stages, options)
  local core = load_pipeline_core()
  if core and core.run then
    core.run(stages, options or {})
  end
end

local function pipeline_recording_qa()
  pipeline_run({"RECORDING_QA"})
end

local function pipeline_mobile_clean()
  pipeline_run({"SOURCE_NORMALIZATION_MOBILE"}, { mobile = { mode = "clean" } })
end

local function pipeline_mobile_atmos()
  pipeline_run({"SOURCE_NORMALIZATION_MOBILE"}, { mobile = { mode = "atmos" } })
end

local function pipeline_mobile_full_export()
  -- Default-Tags für Mobile Field Recorder Flow:
  --   Role:     wenn vorher gesetzt (z.B. Kick/Snare/etc.) bleibt bestehen,
  --             sonst "Any"
  --   Source:   "MobileFR"
  --   FXFlavor: "Clean" (da wir den Clean-FXBus nutzen)
  DF95_SetExportTag("Source", "MobileFR")
  local current_role     = DF95_GetExportTag("Role", "Any")
  local current_fxflavor = DF95_GetExportTag("FXFlavor", "Clean")

  pipeline_run({"RECORDING_QA","SOURCE_NORMALIZATION_MOBILE","SAMPLER_BUILD","EXPORT_SLICES"}, {
    mobile  = { mode = "clean" },
    sampler = { mode = "folder", annotate_roles = true },
    export  = {
      mode     = "SELECTED_SLICES_SUM",
      target   = "SPLICE_44_24",
      category = "Slices_Master",
      subtype  = "MobileFR",
      role     = current_role,
      source   = "MobileFR",
      fxflavor = current_fxflavor,
    }
  })
end

------------------------------------------------------------
-- Tab 2/3/4: Helper to launch other GUIs
------------------------------------------------------------
local function open_dynamic_inspector()
  local path = df95_root() .. "DF95_DynamicSlicing_Inspector_ImGui.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Starten des Dynamic Slicing Inspectors:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function open_pipeline_visualizer()
  local path = df95_root() .. "DF95_Autopilot_Pipeline_Visualizer_ImGui.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Starten des Autopilot Pipeline Visualizers:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function open_slicing_hub()
  local path = df95_root() .. "DF95_SlicingHub_ImGui.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Starten des DF95 Slicing Hubs:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function open_weighted_menu()
  local path = df95_root() .. "DF95_Slice_Menu.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen des Weighted/Classic Slicing Menüs:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function open_loopbuilder2()
  local path = df95_root() .. "DF95_LoopBuilder2.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Starten des LoopBuilder2:\n"..tostring(err).."\nPfad: "..path)
  end

local function open_sampler_build_from_folder()
  local path = df95_root() .. "DF95_Sampler_Build_RS5K_Kit_From_Folder.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Sampler_Build_RS5K_Kit_From_Folder:\n"..tostring(err).."\nPfad: "..path)
  end
end

local function open_sampler_map_selected_items()
  local path = df95_root() .. "DF95_Sampler_Map_Selected_Items_To_RS5K.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Sampler_Map_Selected_Items_To_RS5K:\n"..tostring(err).."\nPfad: "..path)
  end

local function open_sampler_build_roundrobin()
  local path = df95_root() .. "DF95_Sampler_Build_RoundRobin_Kit.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Sampler_Build_RoundRobin_Kit.lua:\n"..tostring(err).."\nPfad: "..path)
  end
end


local function open_sampler_annotate_roles()
  local path = df95_root() .. "DF95_Sampler_Annotate_DrumRoles_From_Notes.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Sampler_Annotate_DrumRoles_From_Notes.lua:\n"..tostring(err).."\nPfad: "..path)
  end

local function open_sampler_kit_wizard()
  local path = df95_root() .. "DF95_Sampler_KitWizard.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_Sampler_KitWizard.lua:\n"..tostring(err).."\nPfad: "..path)
  end
end

end

end

end


------------------------------------------------------------
-- MAIN GUI LOOP
------------------------------------------------------------

local function loop()
  r.ImGui_PushFont(ctx, FONT)

  r.ImGui_SetNextWindowSize(ctx, 880, 640, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, 'DF95 Artist Console', true)

  if visible then
    if r.ImGui_BeginTabBar(ctx, "DF95ArtistTabs") then

      ------------------------------------------------
      -- TAB 1: FLOW
      ------------------------------------------------
      if r.ImGui_BeginTabItem(ctx, "FLOW") then
        r.ImGui_Text(ctx, "Artist Flow – From Source to IDM Drum Setup")
        r.ImGui_Separator(ctx)

        -- Artist Auswahl
        r.ImGui_Text(ctx, "Artist:")
        for _, art in ipairs(ARTISTS) do
          local sel = (flow_state.artist == art)
          if r.ImGui_RadioButton(ctx, art, sel) then
            flow_state.artist = art
          end
          if _ % 3 ~= 0 then
            r.ImGui_SameLine(ctx)
          else
            r.ImGui_NewLine(ctx)
          end
        end
        r.ImGui_NewLine(ctx)
        r.ImGui_Separator(ctx)

        -- Intensity
        r.ImGui_Text(ctx, "Intensity:")
        local intensities = { "auto", "soft", "medium", "extreme" }
        for _, imode in ipairs(intensities) do
          local sel = (flow_state.intensity == imode)
          if r.ImGui_RadioButton(ctx, imode, sel) then
            flow_state.intensity = imode
          end
          r.ImGui_SameLine(ctx)
        end
        r.ImGui_NewLine(ctx)

        -- Slice Length
        r.ImGui_Text(ctx, "Slice Length:")
        local lengths = { "ultra", "short", "medium", "long" }
        for _, m in ipairs(lengths) do
          local sel = (flow_state.slice_length == m)
          if r.ImGui_RadioButton(ctx, m, sel) then
            flow_state.slice_length = m
          end
          r.ImGui_SameLine(ctx)
        end
        r.ImGui_NewLine(ctx)

        r.ImGui_Separator(ctx)

        -- Options
        local changed
        changed, flow_state.do_rearrange = r.ImGui_Checkbox(ctx, "Rearrange after slicing", flow_state.do_rearrange)
        changed, flow_state.do_humanize = r.ImGui_Checkbox(ctx, "Apply Humanize", flow_state.do_humanize)
        changed, flow_state.do_drumsetup = r.ImGui_Checkbox(ctx, "Run DrumSetup (Bus/Routing)", flow_state.do_drumsetup)
        changed, flow_state.do_zerocross = r.ImGui_Checkbox(ctx, "Auto ZeroCross Fade Optimize after Flow", flow_state.do_zerocross)

        r.ImGui_Separator(ctx)

        -- Run Buttons
        if r.ImGui_Button(ctx, "RUN FULL ARTIST FLOW", 380, 40) then
          run_autopilot_full()
        end

        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Dynamic Slice ONLY", 200, 40) then
          run_dynamic_slice_only()
        end

        if r.ImGui_Button(ctx, "Rearrange ONLY", 180, 30) then
          run_rearrange_only()
        end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Humanize ONLY", 180, 30) then
          run_humanize_only()
        end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "DrumSetup ONLY", 180, 30) then
          run_drumsetup_only()
        end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "ZeroCross ONLY", 180, 30) then
          run_zerocross_only()
        end

        r.ImGui_Separator(ctx)
        r.ImGui_TextWrapped(ctx, "Hinweis: FLOW nutzt intern die bestehende DF95-Autopilot-Logik. Artist/Intensity/Slice-Length werden über ProjExtStates an Dynamic Slicer, Rearrange, Humanize und DrumSetup übergeben.")

        r.ImGui_EndTabItem(ctx)
      end

      ------------------------------------------------
      -- TAB 2: PRESETS
      ------------------------------------------------
      if r.ImGui_BeginTabItem(ctx, "PRESETS") then
        r.ImGui_Text(ctx, "Dynamic Slicing Presets & Artist Mapping")
        r.ImGui_Separator(ctx)
        r.ImGui_TextWrapped(ctx, "Dieser Bereich öffnet den Dynamic Slicing Inspector, in dem du Schwellen, Abstände, ZeroCross-Fenster, Fade-Längen und Artist→Preset-Mappings editieren kannst.")
        if r.ImGui_Button(ctx, "Open Dynamic Slicing Inspector", 320, 40) then
          open_dynamic_inspector()
        end
        r.ImGui_EndTabItem(ctx)
      end

      ------------------------------------------------
      
------------------------------------------------
-- TAB X: LOOP
------------------------------------------------
if r.ImGui_BeginTabItem(ctx, "LOOP") then
  r.ImGui_Text(ctx, "LoopBuilder2 – Commit & Generate IDM Loops")
  r.ImGui_Separator(ctx)

  r.ImGui_Text(ctx, "Commit:")
  if r.ImGui_Button(ctx, "Commit selected slices as DF95 Loop", 320, 30) then
    open_loopbuilder2()
  end

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Generate Loops:")
  if r.ImGui_Button(ctx, "Generate Euclid DrumLoop", 260, 28) then
    open_loopbuilder2()
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Generate StepGrid IDM DrumLoop", 260, 28) then
    open_loopbuilder2()
  end

  r.ImGui_TextWrapped(ctx, "Hinweis: LoopBuilder2 öffnet ein kleines Kontext-Menü, in dem du Commit / Euclid / StepGrid auswählen kannst. Diese Buttons sind Shortcuts direkt aus der Artist Console.")
  r.ImGui_EndTabItem(ctx)

------------------------------------------------
-- TAB : SAMPLER
------------------------------------------------
if r.ImGui_BeginTabItem(ctx, "SAMPLER") then
  r.ImGui_Text(ctx, "DF95 Sampler – RS5k Kit Tools")
  r.ImGui_Separator(ctx)

  r.ImGui_Text(ctx, "Build Kits:")
  if r.ImGui_Button(ctx, "Build RS5k Kit from Folder", 300, 28) then
    open_sampler_build_from_folder()
  end

  if r.ImGui_Button(ctx, "Build RS5k Kit from selected Items", 300, 28) then
    open_sampler_map_selected_items()

r.ImGui_Separator(ctx)
r.ImGui_Text(ctx, "Advanced / RoundRobin:")
if r.ImGui_Button(ctx, "Build RS5k RoundRobin Kit from Folder", 340, 28) then
  open_sampler_build_roundrobin()
end
if r.ImGui_Button(ctx, "Annotate Drum Roles from Notes", 340, 28) then
  open_sampler_annotate_roles()
end
r.ImGui_Separator(ctx)
r.ImGui_Text(ctx, "Kit Wizard:")
if r.ImGui_Button(ctx, "Open Sampler Kit Wizard", 260, 28) then
  open_sampler_kit_wizard("Zusätzliche DF95 Slicing Tools")
end
r.ImGui_Separator(ctx)
r.ImGui_Text(ctx, "Slicing Hub & Weighted Menu:")
if r.ImGui_Button(ctx, "Open Slicing Hub (ImGui)", 280, 30) then
  open_slicing_hub()
end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Open Weighted/Classic Menu", 280, 30) then
  open_weighted_menu()
end

        r.ImGui_Separator(ctx)

        r.ImGui_Text(ctx, "ZeroCross Fade Optimizer:")
        if r.ImGui_Button(ctx, "Run ZeroCross Fade Optimizer", 320, 30) then
          run_zerocross_only()
        end


        r.ImGui_Separator(ctx)
        r.ImGui_Separator(ctx)
        local cur_role     = DF95_GetExportTag("Role", "Any")
        local cur_source   = DF95_GetExportTag("Source", "Any")
        local cur_fxflavor = DF95_GetExportTag("FXFlavor", "Generic")
        r.ImGui_Text(ctx, string.format("Current Tags: Role=%s | Source=%s | FX=%s", cur_role, cur_source, cur_fxflavor))

                local cur_role     = DF95_GetExportTag("Role", "Any")
        local cur_source   = DF95_GetExportTag("Source", "Any")
        local cur_fxflavor = DF95_GetExportTag("FXFlavor", "Generic")
        r.ImGui_Text(ctx, string.format("Current Tags: Role=%s | Source=%s | FX=%s", cur_role, cur_source, cur_fxflavor))

        r.ImGui_Text(ctx, "DF95 Export Tags:")
        r.ImGui_Text(ctx, "Role:")
        if r.ImGui_Button(ctx, "Any", 80, 22) then DF95_SetExportTag("Role", "Any") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Kick", 80, 22) then DF95_SetExportTag("Role", "Kick") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Snare", 80, 22) then DF95_SetExportTag("Role", "Snare") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Hat", 80, 22) then DF95_SetExportTag("Role", "Hat") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Perc", 80, 22) then DF95_SetExportTag("Role", "Perc") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Clicks/Pops", 100, 22) then DF95_SetExportTag("Role", "ClicksPops") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Synth", 80, 22) then DF95_SetExportTag("Role", "Synth") end

        r.ImGui_Text(ctx, "Source:")
        if r.ImGui_Button(ctx, "Any", 80, 22) then DF95_SetExportTag("Source", "Any") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "MobileFR", 100, 22) then DF95_SetExportTag("Source", "MobileFR") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "ZoomF6", 80, 22) then DF95_SetExportTag("Source", "ZoomF6") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Studio", 80, 22) then DF95_SetExportTag("Source", "Studio") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "DrumMachine", 110, 22) then DF95_SetExportTag("Source", "DrumMachine") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Synth", 80, 22) then DF95_SetExportTag("Source", "Synth") end

        r.ImGui_Text(ctx, "FX Flavor:")
        if r.ImGui_Button(ctx, "Generic", 90, 22) then DF95_SetExportTag("FXFlavor", "Generic") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Clean", 80, 22) then DF95_SetExportTag("FXFlavor", "Clean") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Safe", 80, 22) then DF95_SetExportTag("FXFlavor", "Safe") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "BusIDM", 90, 22) then DF95_SetExportTag("FXFlavor", "BusIDM") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "IDMGlitch", 100, 22) then DF95_SetExportTag("FXFlavor", "IDMGlitch") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "LoFiTape", 100, 22) then DF95_SetExportTag("FXFlavor", "LoFiTape") end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Extreme", 90, 22) then DF95_SetExportTag("FXFlavor", "Extreme") end

        -- Export Presets (minimal UI)
        DF95_LoadExportPresets()
        if DF95_Export_Preset_List and DF95_Export_Core then
          r.ImGui_Separator(ctx)
          r.ImGui_Text(ctx, "Export Presets:")

-- Aktuelle Export-Tags anzeigen
local tag_role, tag_source, tag_fx = DF95_GetExportTagsSummary()
r.ImGui_Text(ctx, "Export Tags:")
r.ImGui_Text(ctx, "  Role: " .. tag_role)
r.ImGui_Text(ctx, "  Source: " .. tag_source)
r.ImGui_Text(ctx, "  FXFlavor: " .. tag_fx)
if r.ImGui_Button(ctx, "Clear Export Tags", 150, 22) then
  DF95_ClearExportTags()
end

          local labels = ""
          for i, p in ipairs(DF95_Export_Preset_List) do
            labels = labels .. p.label .. "\0"
          end

          local idx = DF95_Export_Preset_Index or 1
          if idx < 1 then idx = 1 end
          if idx > #DF95_Export_Preset_List then idx = #DF95_Export_Preset_List end

          local changed, new_idx = r.ImGui_Combo(ctx, "Preset", idx-1, labels, #DF95_Export_Preset_List)
          if changed then
            DF95_Export_Preset_Index = (new_idx or 0) + 1
          end
          idx = DF95_Export_Preset_Index or 1
          if idx < 1 then idx = 1 end
          if idx > #DF95_Export_Preset_List then idx = #DF95_Export_Preset_List end

          local preset = DF95_Export_Preset_List[idx]

          if r.ImGui_Button(ctx, "DryRun (Preset)", 150, 24) and preset then
            local opts = {}
            for k, v in pairs(preset.opts or {}) do opts[k] = v end
            opts.dry_run = true
            DF95_Export_Core.run(opts)
          end
          r.ImGui_SameLine(ctx)
          if r.ImGui_Button(ctx, "Export (Preset)", 150, 24) and preset then
            local opts = {}
            for k, v in pairs(preset.opts or {}) do opts[k] = v end

r.ImGui_Separator(ctx)

r.ImGui_Separator(ctx)
r.ImGui_Text(ctx, "MobileFR / Field Recorder:")
local cur_mprof = DF95_GetMobileFRProfile()
r.ImGui_Text(ctx, "Current Profile: " .. cur_mprof)
if r.ImGui_Button(ctx, "Profile: Clean", 120, 22) then
  DF95_SetMobileFRProfile("Clean")
end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Profile: Atmos", 120, 22) then
  DF95_SetMobileFRProfile("Atmos")
end

local qa_enabled = DF95_IsMobileFRQAEnabled()
local autotag_enabled = DF95_IsMobileFRAutoTagEnabled()
local changed_qa, new_qa = r.ImGui_Checkbox(ctx, "QA on Auto-Run", qa_enabled)
if changed_qa then
  DF95_SetMobileFRQAEnabled(new_qa)
end
r.ImGui_SameLine(ctx)
local changed_tag, new_tag = r.ImGui_Checkbox(ctx, "AutoTag", autotag_enabled)
if changed_tag then
  DF95_SetMobileFRAutoTagEnabled(new_tag)
end
if r.ImGui_Button(ctx, "MobileFR Auto-Explode+Route", 220, 24) then
  DF95_RunMobileFR_AutoExplodeRoute()
end
r.ImGui_Text(ctx, "Export Packs:")
if r.ImGui_Button(ctx, "Export Pack (Wizard)", 180, 24) then
  -- Default: Artist-Based Pack, DryRun erstmal true
  DF95_RunPackWizard("Artist-Based (Auto) Pack", "", true)
end

            opts.dry_run = false
            DF95_Export_Core.run(opts)
          end
        end


r.ImGui_Text(ctx, "Role:")
if r.ImGui_Button(ctx, "Any", 80, 22) then DF95_SetExportTag("Role", "Any") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Kick", 80, 22) then DF95_SetExportTag("Role", "Kick") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Snare", 80, 22) then DF95_SetExportTag("Role", "Snare") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Hat", 80, 22) then DF95_SetExportTag("Role", "Hat") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Perc", 80, 22) then DF95_SetExportTag("Role", "Perc") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Clicks/Pops", 100, 22) then DF95_SetExportTag("Role", "ClicksPops") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Synth", 80, 22) then DF95_SetExportTag("Role", "Synth") end

r.ImGui_Text(ctx, "Source:")
if r.ImGui_Button(ctx, "Any", 80, 22) then DF95_SetExportTag("Source", "Any") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "MobileFR", 100, 22) then DF95_SetExportTag("Source", "MobileFR") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "ZoomF6", 80, 22) then DF95_SetExportTag("Source", "ZoomF6") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Studio", 80, 22) then DF95_SetExportTag("Source", "Studio") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "DrumMachine", 110, 22) then DF95_SetExportTag("Source", "DrumMachine") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Synth", 80, 22) then DF95_SetExportTag("Source", "Synth") end

r.ImGui_Text(ctx, "FX Flavor:")
if r.ImGui_Button(ctx, "Generic", 90, 22) then DF95_SetExportTag("FXFlavor", "Generic") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Clean", 80, 22) then DF95_SetExportTag("FXFlavor", "Clean") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Safe", 80, 22) then DF95_SetExportTag("FXFlavor", "Safe") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "BusIDM", 90, 22) then DF95_SetExportTag("FXFlavor", "BusIDM") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "IDMGlitch", 100, 22) then DF95_SetExportTag("FXFlavor", "IDMGlitch") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "LoFiTape", 100, 22) then DF95_SetExportTag("FXFlavor", "LoFiTape") end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Extreme", 90, 22) then DF95_SetExportTag("FXFlavor", "Extreme") end
r.ImGui_Text(ctx, "Mobile Recording / Field Recorder (S24 Ultra):")

        if r.ImGui_Button(ctx, "Recording QA (Selected Items)", 260, 26) then
          pipeline_recording_qa()
        end

        if r.ImGui_Button(ctx, "Apply Mobile FXBus (Clean)", 260, 26) then
          pipeline_mobile_clean()
        end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Apply Mobile FXBus (Atmos)", 260, 26) then
          pipeline_mobile_atmos()
        end

        if r.ImGui_Button(ctx, "Full Mobile Flow: QA → Normalize → Sampler → Export", 520, 26) then
          pipeline_mobile_full_export()
        end
        r.ImGui_Separator(ctx)
        r.ImGui_TextWrapped(ctx, "Hinweis: Die TOOLS-Tab bündelt vorhandene DF95-Slicing-Skripte, falls du sie separat vom Artist-Flow nutzen möchtest.")

        if r.ImGui_Button(ctx, "Open Autopilot Pipeline Visualizer", 360, 40) then
          open_pipeline_visualizer()
        end
        r.ImGui_EndTabItem(ctx)

------------------------------------------------
-- TAB : EXPORT
------------------------------------------------
if r.ImGui_BeginTabItem(ctx, "EXPORT") then
  r.ImGui_Text(ctx, "DF95 Export – KitMeta aware Packs")
  r.ImGui_Separator(ctx)

  -- Auto-Analyse der letzten KitMeta (falls vorhanden)
  local km_json = DF95_LoadLastKitMetaJSON()
  if not km_json then
    r.ImGui_TextWrapped(ctx, "Keine KitMeta gefunden. Bitte zuerst mit dem DF95 Sampler KitWizard ein C2-Kit bauen, damit Slot-Rollen (Kick/Snare/Hats/MicroPerc/ClicksPops/...) im System landen.")
  else
    local roles = DF95_ParseRolesFromKitMeta(km_json)
    local summary = DF95_BuildKitMetaSummary(roles)
    r.ImGui_Text(ctx, "KitMeta Rollenübersicht:")
    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx, summary)
  end

r.ImGui_Separator(ctx)

-- Naming-Style Auswahl für Export (wirkt auf DF95_Export_Core.NameEngine)
local current_style = reaper.GetExtState("DF95_EXPORT_NAMESTYLE", "Style")
if not current_style or current_style == "" then current_style = "DF95" end
r.ImGui_Text(ctx, "Naming Style (NameEngine):  " .. current_style)

if r.ImGui_Button(ctx, "DF95", 70, 22) then
  reaper.SetExtState("DF95_EXPORT_NAMESTYLE", "Style", "DF95", true)
  current_style = "DF95"
end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Splice", 70, 22) then
  reaper.SetExtState("DF95_EXPORT_NAMESTYLE", "Style", "SPLICE", true)
  current_style = "SPLICE"
end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Loopmasters", 110, 22) then
  reaper.SetExtState("DF95_EXPORT_NAMESTYLE", "Style", "LOOPMASTERS", true)
  current_style = "LOOPMASTERS"
end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "ADSR", 70, 22) then
  reaper.SetExtState("DF95_EXPORT_NAMESTYLE", "Style", "ADSR", true)
  current_style = "ADSR"
end

r.ImGui_Separator(ctx)

r.ImGui_Text(ctx, "Export aus KitMeta:")
  if r.ImGui_Button(ctx, "DrumKit Pack (Single Pack aus KitMeta)", 320, 26) then
    DF95_OpenPackWizard_FromKitMeta()
  end

  if r.ImGui_Button(ctx, "Multi-Packs per Role (Kick/Snare/Hats/...)", 320, 26) then
    DF95_OpenPackWizard_FromKitMeta_PerRole()
  end

  r.ImGui_Separator(ctx)
  r.ImGui_TextWrapped(ctx, "Hinweis: Die Export-Wizards verwenden die zentrale DF95 NameEngine + AutoTag-Logik. Die Track/Item-Selektion im Projekt bestimmt, was tatsächlich gerendert wird (z.B. aktuelle Slices, Drumbus, FXBus-Routing).")

  r.ImGui_EndTabItem(ctx)
end

      end

      ------------------------------------------------
      -- TAB 4: TOOLS
      ------------------------------------------------
      if r.ImGui_BeginTabItem(ctx, "TOOLS") then
        r.ImGui_Text(ctx, "Zusätzliche DF95 Slicing Tools")
        r.ImGui_Separator(ctx)

        r.ImGui_Text(ctx, "Slicing Hub & Weighted Menu:")
        if r.ImGui_Button(ctx, "Open Slicing Hub (ImGui)", 280, 30) then
          open_slicing_hub()
        end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Open Weighted/Classic Menu", 280, 30) then
          open_weighted_menu()
        end

        r.ImGui_Separator(ctx)

        r.ImGui_Text(ctx, "ZeroCross Fade Optimizer:")
        if r.ImGui_Button(ctx, "Run ZeroCross Fade Optimizer", 320, 30) then
          run_zerocross_only()
        end

        r.ImGui_Separator(ctx)
        r.ImGui_TextWrapped(ctx, "Hinweis: Die TOOLS-Tab bündelt vorhandene DF95-Slicing-Skripte, falls du sie separat vom Artist-Flow nutzen möchtest.")

        r.ImGui_EndTabItem(ctx)
      end

      r.ImGui_EndTabBar(ctx)
    end

    r.ImGui_End(ctx)
  end

  r.ImGui_PopFont(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()