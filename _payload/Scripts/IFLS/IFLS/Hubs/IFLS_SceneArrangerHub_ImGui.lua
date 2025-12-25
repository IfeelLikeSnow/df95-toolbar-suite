-- IFLS_SceneArrangerHub_ImGui.lua
-- Phase 26: Scene Arranger Hub (ImGui)

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_SceneArrangerHub')

local function load_arranger()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. '/Scripts/IFLS/IFLS/Domain/IFLS_SceneArrangerDomain.lua')
  if ok and type(mod) == 'table' then return mod end
  r.ShowMessageBox('IFLS_SceneArrangerDomain.lua konnte nicht geladen werden.', 'IFLS SceneArranger', 0)
  return nil
end

local arranger = nil
local arr = nil
local current_index = 1

local preset_names = {
  "IDM_ARC",
  "GLITCH_SPIKES",
  "AMBIENT_DRIFT",
}

local function ensure_arranger()
  if not arranger then arranger = load_arranger() end
  if arranger and not arr then
    if arranger.read_arrangement then
      arr = arranger.read_arrangement()
    else
      arr = arranger.default_arrangement and arranger.default_arrangement() or {scenes={}}
    end
  end
end

local function save_arr()
  if arranger and arranger.write_arrangement and arr then
    arranger.write_arrangement(arr)
  end
end

local function draw_scene_row(idx, step)
  ig.PushID(ctx, idx)
  ig.Text(ctx, tostring(idx) .. ".")
  ig.SameLine(ctx)
  local name = step.name or ""
  local changed, new_name = ig.InputText(ctx, "Name", name, 128)
  if changed then step.name = new_name end

  local slot = step.scene_slot or 1
  changed, slot = ig.SliderInt(ctx, "Scene Slot", slot, 1, 32)
  if changed then step.scene_slot = slot end

  local energy = step.energy or 0.5
  step.energy = select(2, ig.SliderDouble(ctx, "Energy", energy, 0.0, 1.0, '%.2f'))

  local length_bars = step.length_bars or 8
  changed, length_bars = ig.SliderInt(ctx, "Length (Bars)", length_bars, 1, 128)
  if changed then step.length_bars = length_bars end

  local macros = step.macros or {variation=0.5,melody=0.5,groove=0.5,chaos=0.0}
  step.macros = macros
  ig.Text(ctx, "Macros")
  macros.variation = select(2, ig.SliderDouble(ctx, "Variation", macros.variation or 0.5, 0.0, 1.0, '%.2f'))
  macros.melody    = select(2, ig.SliderDouble(ctx, "Melody",    macros.melody or 0.5,    0.0, 1.0, '%.2f'))
  macros.groove    = select(2, ig.SliderDouble(ctx, "Groove",    macros.groove or 0.5,    0.0, 1.0, '%.2f'))
  macros.chaos     = select(2, ig.SliderDouble(ctx, "Chaos",     macros.chaos or 0.0,     0.0, 1.0, '%.2f'))

  ig.PopID(ctx)
end

local function loop()
  ensure_arranger()

  ig.SetNextWindowSize(ctx, 620, 520, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Scene Arranger', true)
  if visible then
    ig.Text(ctx, 'IFLS Scene Arranger – Energy & Macro Curves')
    ig.Separator(ctx)

    if arr and arr.scenes then
      -- Preset row
      ig.Text(ctx, 'Arrangement Presets')
      ig.SameLine(ctx)
      for _, pname in ipairs(preset_names) do
        if ig.Button(ctx, pname) and arranger and arranger.generate_preset then
          arr = arranger.generate_preset(pname)
          current_index = 1
        end
        ig.SameLine(ctx)
      end
      ig.NewLine(ctx)

      ig.Separator(ctx)
      ig.Text(ctx, 'Scenes in Arrangement')

      if ig.Button(ctx, 'Add Step') then
        table.insert(arr.scenes, {
          name        = "New Step",
          scene_slot  = 1,
          energy      = 0.5,
          length_bars = 8,
          macros      = {variation=0.5,melody=0.5,groove=0.5,chaos=0.0},
        })
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, 'Remove Last') then
        table.remove(arr.scenes)
      end

      ig.Separator(ctx)

      local avail_y = ig.GetWindowHeight(ctx) - 220
      if ig.BeginChild(ctx, "SceneList", 0, avail_y, true) then
        for i, step in ipairs(arr.scenes) do
          if ig.CollapsingHeader(ctx, string.format("%d: %s", i, step.name or "Step"), ig.TreeNodeFlags_DefaultOpen()) then
            draw_scene_row(i, step)
            ig.Separator(ctx)
          end
        end
        ig.EndChild(ctx)
      end

      ig.Separator(ctx)
      ig.Text(ctx, 'Playback Control (manual)')
      local count = #arr.scenes
      ig.Text(ctx, string.format("Current Index: %d / %d", current_index or 0, count or 0))
      if ig.Button(ctx, 'Prev Step') and arranger and arranger.get_prev_index then
        current_index = arranger.get_prev_index(current_index)
        arranger.apply_scene_index(current_index)
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, 'Next Step') and arranger and arranger.get_next_index then
        current_index = arranger.get_next_index(current_index)
        arranger.apply_scene_index(current_index)
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, 'Apply Current Step') and arranger then
        arranger.apply_scene_index(current_index)
      end

      ig.SameLine(ctx)
      if ig.Button(ctx, 'Save Arrangement') then
        save_arr()
      end

      ig.Spacing(ctx)
      ig.TextWrapped(ctx, 'Workflow: Baue dir mit dem SceneHub deine Scenes (Intro, Build, Peak ...), '
        .. 'dann mappe im Scene Arranger diese Scene-Slots auf Steps und forme Energy + Makro-Kurven.\n'
        .. 'Via SceneEvolutionDomain werden Variation/Groove/Melody passend zur aktuellen Step-Definition angepasst.')
    else
      ig.Text(ctx, 'Kein Arrangement geladen.')
    end

    ig.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
