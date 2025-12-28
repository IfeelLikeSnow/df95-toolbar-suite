-- DF95_Autopilot_ArtistDynamicSlice_GUI.lua
-- ReaImGui control panel for DF95 Artist Dynamic Slice Autopilot
-- Shows Artists as buttons, Intensity selector, Slice-Length selector,
-- and optional Rearrange/Humanize toggles.
--
-- Voraussetzung: ReaImGui-Extension muss installiert sein.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui-Extension nicht gefunden.\nBitte SWS/ReaImGui installieren.", "DF95 Autopilot GUI", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Artist Autopilot')
local FONT = r.ImGui_CreateFont('sans-serif', 18)
r.ImGui_AttachFont(ctx, FONT)

-------------------------------
-- Artist List
-------------------------------
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

-------------------------------
-- GUI State
-------------------------------
local state = {
  artist = "autechre",
  intensity = "auto",
  slice_length = "medium",
  do_rearrange = true,
  do_humanize = true
}

-------------------------------
-- Helper: Run Autopilot Script
-------------------------------
local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function run_autopilot()
  local fn = df95_root() .. "DF95_Autopilot_ArtistDynamicSlice.lua"
  local ok, err = pcall(dofile, fn)
  if not ok then
    r.ShowMessageBox("Fehler beim Ausführen des Autopilot-Skripts:\n"..tostring(err),
      "DF95 Autopilot GUI", 0)
  end
end

-------------------------------
-- GUI
-------------------------------
local function loop()
  r.ImGui_PushFont(ctx, FONT)

  r.ImGui_SetNextWindowSize(ctx, 420, 800, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, 'DF95 Artist Autopilot', true)

  if visible then

    --------------------------------
    -- Artist selection
    --------------------------------
    r.ImGui_Text(ctx, "Artist Presets:")
    for i, art in ipairs(ARTISTS) do
      if r.ImGui_Button(ctx, art, 200, 25) then
        state.artist = art
      end
    end
    r.ImGui_Separator(ctx)

    --------------------------------
    -- Intensity
    --------------------------------
    r.ImGui_Text(ctx, "Intensity:")
    if r.ImGui_RadioButton(ctx, "auto", state.intensity == "auto") then
      state.intensity = "auto"
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_RadioButton(ctx, "soft", state.intensity == "soft") then
      state.intensity = "soft"
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_RadioButton(ctx, "medium", state.intensity == "medium") then
      state.intensity = "medium"
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_RadioButton(ctx, "extreme", state.intensity == "extreme") then
      state.intensity = "extreme"
    end

    r.ImGui_Separator(ctx)

    --------------------------------
    -- Slice Length
    --------------------------------
    r.ImGui_Text(ctx, "Slice Length:")
    local lengths = {"ultra", "short", "medium", "long"}
    for _, m in ipairs(lengths) do
      if r.ImGui_RadioButton(ctx, m, state.slice_length == m) then
        state.slice_length = m
      end
      r.ImGui_SameLine(ctx)
    end
    r.ImGui_NewLine(ctx)

    r.ImGui_Separator(ctx)

    --------------------------------
    -- Options
    --------------------------------
    local _, dr = r.ImGui_Checkbox(ctx, "Rearrange after slicing", state.do_rearrange)
    state.do_rearrange = dr

    local _, dh = r.ImGui_Checkbox(ctx, "Apply Humanize", state.do_humanize)
    state.do_humanize = dh

    r.ImGui_Separator(ctx)

    --------------------------------
    -- Preview Info
    --------------------------------
    r.ImGui_Text(ctx, "Preview:")
    r.ImGui_BulletText(ctx, "Artist: " .. state.artist)
    r.ImGui_BulletText(ctx, "Intensity: " .. state.intensity)
    r.ImGui_BulletText(ctx, "Slice Length: " .. state.slice_length)
    r.ImGui_BulletText(ctx, "Rearrange: " .. tostring(state.do_rearrange))
    r.ImGui_BulletText(ctx, "Humanize: " .. tostring(state.do_humanize))

    r.ImGui_Separator(ctx)

    --------------------------------
    -- RUN BUTTON
    --------------------------------
    if r.ImGui_Button(ctx, "RUN AUTOPILOT", 400, 40) then
      -- ExtStates für Autopilot setzen
      r.SetProjExtState(0, "DF95_SLICING", "ARTIST", state.artist)
      r.SetProjExtState(0, "DF95_SLICING", "INTENSITY", state.intensity)
      r.SetProjExtState(0, "DF95_DYN", "LENGTH_MODE", state.slice_length)

      r.SetProjExtState(0, "DF95_AUTOPILOT", "REARR",
        state.do_rearrange and "yes" or "no")
      r.SetProjExtState(0, "DF95_AUTOPILOT", "HUM",
        state.do_humanize and "yes" or "no")

      run_autopilot()
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
