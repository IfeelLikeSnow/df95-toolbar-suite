-- IFLS_PatternHub_ImGui.lua
-- Phase 9: Pattern Control Panel (IDM / Euclid / Microbeat / Granular)
-- --------------------------------------------------------------------

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"

local ok_ui, ui_core = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
local ok_ext, ext    = pcall(dofile, core_path .. "IFLS_ExtState.lua")

if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox("IFLS Pattern Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.", "IFLS Pattern Hub", 0)
  return
end

if not ok_ext or type(ext) ~= "table" then
  r.ShowMessageBox("IFLS Pattern Hub: IFLS_ExtState.lua konnte nicht geladen werden.", "IFLS Pattern Hub", 0)
  return
end

local ctx = ui_core.create_context("IFLS_PatternHub")
if not ctx then return end

local NS_PATTERN = "DF95_PATTERN"

local state = {
  mode_hint    = ext.get_proj(NS_PATTERN, "MODE_HINT", ""),
  chaos        = tonumber(ext.get_proj(NS_PATTERN, "CHAOS", "0.7")) or 0.7,
  density      = tonumber(ext.get_proj(NS_PATTERN, "DENSITY", "0.4")) or 0.4,
  cluster_prob = tonumber(ext.get_proj(NS_PATTERN, "CLUSTER_PROB", "0.35")) or 0.35,
  euclid_k     = tonumber(ext.get_proj(NS_PATTERN, "EUCLID_K", "3")) or 3,
  euclid_n     = tonumber(ext.get_proj(NS_PATTERN, "EUCLID_N", "8")) or 8,
  euclid_rot   = tonumber(ext.get_proj(NS_PATTERN, "EUCLID_ROT", "0")) or 0,
}

local function save_state()
  ext.set_proj(NS_PATTERN, "MODE_HINT", state.mode_hint or "")
  ext.set_proj(NS_PATTERN, "CHAOS", tostring(state.chaos or 0.7))
  ext.set_proj(NS_PATTERN, "DENSITY", tostring(state.density or 0.4))
  ext.set_proj(NS_PATTERN, "CLUSTER_PROB", tostring(state.cluster_prob or 0.35))
  ext.set_proj(NS_PATTERN, "EUCLID_K", tostring(state.euclid_k or 3))
  ext.set_proj(NS_PATTERN, "EUCLID_N", tostring(state.euclid_n or 8))
  ext.set_proj(NS_PATTERN, "EUCLID_ROT", tostring(state.euclid_rot or 0))
end

local function reload_state()
  state.mode_hint    = ext.get_proj(NS_PATTERN, "MODE_HINT", state.mode_hint or "")
  state.chaos        = tonumber(ext.get_proj(NS_PATTERN, "CHAOS", tostring(state.chaos or 0.7))) or 0.7
  state.density      = tonumber(ext.get_proj(NS_PATTERN, "DENSITY", tostring(state.density or 0.4))) or 0.4
  state.cluster_prob = tonumber(ext.get_proj(NS_PATTERN, "CLUSTER_PROB", tostring(state.cluster_prob or 0.35))) or 0.35
  state.euclid_k     = tonumber(ext.get_proj(NS_PATTERN, "EUCLID_K", tostring(state.euclid_k or 3))) or 3
  state.euclid_n     = tonumber(ext.get_proj(NS_PATTERN, "EUCLIT_N", tostring(state.euclid_n or 8))) or 8
  state.euclid_rot   = tonumber(ext.get_proj(NS_PATTERN, "EUCLID_ROT", tostring(state.euclid_rot or 0))) or 0
end

local function draw(ctx)
  ig.Text(ctx, "IFLS Pattern Hub")
  ig.Separator(ctx)

  ig.Text(ctx, "Mode Hint")
  ig.PushItemWidth(ctx, 240)
  local changed
  local mode_hint = state.mode_hint or ""
  changed, mode_hint = ig.InputText(ctx, "Mode Hint (IDM/EUCLID/MICROBEAT/GRANULAR)", mode_hint)
  if changed then state.mode_hint = mode_hint end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "IDM")
  ig.Separator(ctx)

  ig.PushItemWidth(ctx, 200)
  local chaos = state.chaos or 0.7
  changed, chaos = ig.SliderDouble(ctx, "Chaos", chaos, 0.0, 1.5, "%.3f")
  if changed then state.chaos = chaos end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "Microbeat")
  ig.Separator(ctx)

  ig.PushItemWidth(ctx, 200)
  local density = state.density or 0.4
  changed, density = ig.SliderDouble(ctx, "Density", density, 0.0, 1.0, "%.3f")
  if changed then state.density = density end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "Granular")
  ig.Separator(ctx)

  ig.PushItemWidth(ctx, 200)
  local cluster = state.cluster_prob or 0.35
  changed, cluster = ig.SliderDouble(ctx, "Cluster Prob", cluster, 0.0, 1.0, "%.3f")
  if changed then state.cluster_prob = cluster end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "Euclid")
  ig.Separator(ctx)

  ig.PushItemWidth(ctx, 200)
  local ek = state.euclid_k or 3
  changed, ek = ig.InputInt(ctx, "k (Pulses)", ek)
  if changed then if ek < 0 then ek = 0 end; state.euclid_k = ek end

  local en = state.euclid_n or 8
  changed, en = ig.InputInt(ctx, "n (Steps)", en)
  if changed then if en < 1 then en = 1 end; state.euclid_n = en end

  local er = state.euclid_rot or 0
  changed, er = ig.InputInt(ctx, "Rotation", er)
  if changed then state.euclid_rot = er end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)

  if ig.Button(ctx, "Reload") then reload_state() end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Save") then save_state() end

  ig.Separator(ctx)
  ig.TextWrapped(ctx, "Diese Parameter werden von IFLS_GeneratePattern_FromArtist und IFLS_OutputRouter als cfg verwendet.")
end

ui_core.run_mainloop(ctx, "IFLS Pattern Hub", draw)
