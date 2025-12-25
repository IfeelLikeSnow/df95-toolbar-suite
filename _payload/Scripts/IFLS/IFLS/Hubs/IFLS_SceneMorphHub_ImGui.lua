-- IFLS_SceneMorphHub_ImGui.lua
-- Interaktives Morphing zwischen zwei IFLS-Szenen (inkl. EuclidPro/OXY-Pro)
-- Nutzt IFLS_SceneDomain.morph_scenes(slot_a, slot_b, t)

local r = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local function load_dom(name)
  local ok, mod = pcall(dofile, domain_path .. name .. ".lua")
  if not ok or type(mod) ~= "table" then return nil end
  return mod
end

local scenedom = load_dom("IFLS_SceneDomain")

if not ig then
  r.ShowMessageBox("ReaImGui nicht verfügbar.", "IFLS Scene Morph Hub", 0)
  return
end

local ctx = ig.CreateContext("IFLS Scene Morph")

local slot_a = 1
local slot_b = 2
local t_val  = 0.0

local function main_loop()
  ig.SetNextWindowSize(ctx, 420, 220, ig.Cond_FirstUseEver)
  local visible, open = ig.Begin(ctx, "IFLS Scene Morph Hub", true)

  if visible then
    ig.Text(ctx, "Scene Morphing (inkl. EuclidPro/OXY-Pro)")
    ig.Separator(ctx)

    ig.PushItemWidth(ctx, 80)
    local changed_a, new_a = ig.InputInt(ctx, "Scene A", slot_a)
    if changed_a then slot_a = math.max(1, new_a) end
    local changed_b, new_b = ig.InputInt(ctx, "Scene B", slot_b)
    if changed_b then slot_b = math.max(1, new_b) end
    ig.PopItemWidth(ctx)

    ig.Separator(ctx)
    ig.Text(ctx, "Morph Position")
    ig.PushItemWidth(ctx, 260)
    local changed_t, new_t = ig.SliderDouble(ctx, "t (0=A, 1=B)", t_val, 0.0, 1.0, "%.2f")
    if changed_t then
      t_val = new_t
      if scenedom and scenedom.morph_scenes then
        scenedom.morph_scenes(slot_a, slot_b, t_val)
      end
    end
    ig.PopItemWidth(ctx)

    ig.Separator(ctx)
    if ig.Button(ctx, "Snap to A (t=0)") then
      t_val = 0.0
      if scenedom and scenedom.morph_scenes then
        scenedom.morph_scenes(slot_a, slot_b, t_val)
      end
    end
    ig.SameLine(ctx)
    if ig.Button(ctx, "Snap to B (t=1)") then
      t_val = 1.0
      if scenedom and scenedom.morph_scenes then
        scenedom.morph_scenes(slot_a, slot_b, t_val)
      end
    end

    ig.End(ctx)
  else
    ig.End(ctx)
  end

  if open then
    r.defer(main_loop)
  else
    ig.DestroyContext(ctx)
  end
end

r.defer(main_loop)
