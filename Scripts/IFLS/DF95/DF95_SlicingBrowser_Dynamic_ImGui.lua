-- DF95_SlicingBrowser_Dynamic_ImGui.lua
-- ImGui-Browser für dynamische Slicing-Presets (Transient/Gate + Slice-Länge)
-- Nutzt DF95_Dynamic_Slicer.lua im DF95-Ordner.
--
-- Anforderungen:
--   * ReaImGui installiert
--   * Scripts/IFLS/DF95/DF95_Dynamic_Slicer.lua vorhanden

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui-Extension nicht gefunden.\nBitte SWS/ReaImGui / ReaImGui installieren.", "DF95 Dynamic Slicing Browser", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Dynamic Slicing Browser')
local FONT = r.ImGui_CreateFont('sans-serif', 17)
r.ImGui_AttachFont(ctx, FONT)

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local PRESET_GROUPS = {
  transient = {
    label = "Transient Detection",
    presets = {
      { id="transient_soft",   label="Soft (gentle, musical)" },
      { id="transient_medium", label="Medium (IDM drums)"     },
      { id="transient_extreme",label="Extreme (glitchy)"     },
    }
  },
  gate = {
    label = "Gate-Based (On/Off)",
    presets = {
      { id="gate_sparse",      label="Sparse (slow stutters)" },
      { id="gate_stutter",     label="Stutter (IDM style)"    },
      { id="gate_microclicks", label="Microclicks/Granular"   },
    }
  }
}

local LENGTH_MODES = {
  { id="ultra",  label="Ultra Short (micro)" },
  { id="short",  label="Short" },
  { id="medium", label="Medium" },
  { id="long",   label="Long" },
}

local state = {
  group = "transient",
  preset = "transient_medium",
  length = "medium",
}

local function run_dynamic_slicer()
  local root = df95_root()
  local script_path = root .. "DF95_Dynamic_Slicer.lua"

  -- ExtStates setzen, damit DF95_Dynamic_Slicer das Preset + Length kennt
  r.SetProjExtState(0, "DF95_DYN", "PRESET", state.preset or "")
  r.SetProjExtState(0, "DF95_DYN", "LENGTH_MODE", state.length or "medium")

  local ok, err = pcall(dofile, script_path)
  if not ok then
    r.ShowMessageBox("Fehler beim Ausführen von DF95_Dynamic_Slicer.lua:\n"..tostring(err),
      "DF95 Dynamic Slicing Browser", 0)
  end
end

local function loop()
  r.ImGui_PushFont(ctx, FONT)

  r.ImGui_SetNextWindowSize(ctx, 450, 520, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, 'DF95 Dynamic Slicing Browser', true)

  if visible then
    r.ImGui_Text(ctx, "Dynamic Slicing – Physical Slices")
    r.ImGui_Separator(ctx)

    --------------------------------
    -- Modus auswählen (Transient / Gate)
    --------------------------------
    r.ImGui_Text(ctx, "Detection Mode:")
    for key, grp in pairs(PRESET_GROUPS) do
      local selected = (state.group == key)
      if r.ImGui_RadioButton(ctx, grp.label, selected) then
        state.group = key
        -- Default-Preset pro Gruppe setzen
        if key == "transient" then
          state.preset = "transient_medium"
        elseif key == "gate" then
          state.preset = "gate_stutter"
        end
      end
    end

    r.ImGui_Separator(ctx)

    --------------------------------
    -- Presets innerhalb der Gruppe
    --------------------------------
    local grp = PRESET_GROUPS[state.group]
    if grp then
      r.ImGui_Text(ctx, "Preset:")
      for _, p in ipairs(grp.presets) do
        local sel = (state.preset == p.id)
        if r.ImGui_RadioButton(ctx, p.label, sel) then
          state.preset = p.id
        end
      end
    end

    r.ImGui_Separator(ctx)

    --------------------------------
    -- Slice-Länge
    --------------------------------
    r.ImGui_Text(ctx, "Slice Length:")
    for _, m in ipairs(LENGTH_MODES) do
      local sel = (state.length == m.id)
      if r.ImGui_RadioButton(ctx, m.label, sel) then
        state.length = m.id
      end
    end

    r.ImGui_Separator(ctx)

    --------------------------------
    -- Preview
    --------------------------------
    r.ImGui_Text(ctx, "Preview:")
    local mode_label = (state.group == "transient") and "Transient" or "Gate"
    r.ImGui_BulletText(ctx, "Mode: " .. mode_label)
    r.ImGui_BulletText(ctx, "Preset ID: " .. tostring(state.preset))
    r.ImGui_BulletText(ctx, "Slice Length: " .. tostring(state.length))

    r.ImGui_Separator(ctx)

    --------------------------------
    -- RUN
    --------------------------------
    if r.ImGui_Button(ctx, "APPLY TO SELECTED ITEMS", 420, 40) then
      run_dynamic_slicer()
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
