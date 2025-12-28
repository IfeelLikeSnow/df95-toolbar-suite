-- IFLS_SceneHub_ImGui.lua
-- Phase 13: Scene / Snapshot Hub (ImGui)
-- --------------------------------------
-- UI für:
--   * Speichern & Laden von Szenen (Slots 1..8 standardmäßig)
--   * Benennen / Umbenennen
--   * Löschen
--   * Anzeigen des aktuellen Scene-Status.

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_ui, ui_core = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox("IFLS Scene Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.", "IFLS Scene Hub", 0)
  return
end

local ok_scene, scenedom = pcall(dofile, domain_path .. "IFLS_SceneDomain.lua")
if not ok_scene or type(scenedom) ~= "table" then
  r.ShowMessageBox("IFLS Scene Hub: IFLS_SceneDomain.lua konnte nicht geladen werden.", "IFLS Scene Hub", 0)
  return
end

local ok_beat, beatdom   = pcall(dofile, domain_path .. "IFLS_BeatDomain.lua")
local ok_artist, artistdom = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")
local ok_tuning, tuningdom = pcall(dofile, domain_path .. "IFLS_TuningDomain.lua")

local ctx = ui_core.create_context("IFLS_SceneHub")
if not ctx then return end

local slots = {}
for i=1,8 do
  slots[i] = { name = "Scene " .. tostring(i) }
end

local function refresh_slots_from_meta()
  local meta = scenedom.list_scenes()
  local map = {}
  for _,sc in ipairs(meta) do
    map[sc.slot] = sc.name
  end
  for i=1,#slots do
    if map[i] then
      slots[i].name = map[i]
    else
      slots[i].name = "Scene " .. tostring(i)
    end
  end
end

refresh_slots_from_meta()

local last_message = ""

local function show_message(msg)
  last_message = msg or ""
end

local function draw(ctx)
  ig.Text(ctx, "IFLS Scene Hub")
  ig.Separator(ctx)

  ig.Text(ctx, "Scenes (Slots 1..8)")
  ig.Separator(ctx)

  for i=1,#slots do
    ig.PushID(ctx, i)
    ig.Text(ctx, string.format("Slot %d:", i))
    ig.SameLine(ctx)
    ig.PushItemWidth(ctx, 160)
    local changed
    local name = slots[i].name
    changed, name = ig.InputText(ctx, "##name", name)
    if changed then
      slots[i].name = name
      scenedom.rename_scene(i, name)
      show_message(string.format("Scene %d renamed to '%s'.", i, name))
    end
    ig.PopItemWidth(ctx)

    ig.SameLine(ctx)
    if ig.Button(ctx, "Save") then
      local ok = scenedom.save_scene(i, slots[i].name)
      if ok then
        show_message(string.format("Scene %d saved.", i))
      end
    end

    ig.SameLine(ctx)
    if ig.Button(ctx, "Load") then
      local ok, err = scenedom.load_scene(i)
      if not ok then
        show_message(err or ("Failed to load scene " .. tostring(i)))
      else
        show_message(string.format("Scene %d loaded.", i))
      end
    end

    ig.SameLine(ctx)
    if ig.Button(ctx, "Delete") then
      scenedom.delete_scene(i)
      refresh_slots_from_meta()
      show_message(string.format("Scene %d deleted.", i))
    end

    ig.PopID(ctx)
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Current State (Beat / Artist / Tuning)")
  ig.Separator(ctx)

  if ok_artist and artistdom and artistdom.get_artist_state then
    local as = artistdom.get_artist_state()
    ig.Text(ctx, ("Artist:   %s"):format(as.name or "<none>"))
    ig.Text(ctx, ("Style:    %s"):format(as.style_preset or "<none>"))
  end

  if ok_beat and beatdom and beatdom.get_state then
    local bs = beatdom.get_state()
    ig.Text(ctx, ("Beat:     %d BPM, %d/%d, Bars=%d"):format(bs.bpm or 0, bs.ts_num or 4, bs.ts_den or 4, bs.bars or 4))
  end

  if ok_tuning and tuningdom and tuningdom.get_state then
    local ts = tuningdom.get_state()
    ig.Text(ctx, ("Tuning:   %s, Profile=%s, PB=±%d, Off=%.2f c"):format(
      ts.enabled and "On" or "Off",
      ts.profile or "Equal12",
      ts.pitch_bend_semi or 2,
      ts.master_offset or 0
    ))
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Log")
  ig.Separator(ctx)
  ig.TextWrapped(ctx, last_message ~= "" and last_message or "<no message>")


  ig.Separator(ctx)
  if ig.Button(ctx, "Open Scene Morph Hub") then
    local path = r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Hubs/IFLS_SceneMorphHub_ImGui.lua"
    local ok, err = pcall(dofile, path)
    if not ok then
      r.ShowMessageBox("Could not open SceneMorphHub:\n" .. tostring(err), "IFLS Scene Hub", 0)
    end
  end
end

ui_core.run_mainloop(ctx, "IFLS Scene Hub", draw)
