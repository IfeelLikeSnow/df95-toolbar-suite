-- IFLS_TuningHub_ImGui.lua
-- Phase 9: Einfaches Tuning-Panel (Microtonal-Basis)

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_ui, ui_core = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox("IFLS Tuning Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.", "IFLS Tuning Hub", 0)
  return
end

local ok_tuning, tuning = pcall(dofile, domain_path .. "IFLS_TuningDomain.lua")
if not ok_tuning or type(tuning) ~= "table" then
  r.ShowMessageBox("IFLS Tuning Hub: IFLS_TuningDomain.lua konnte nicht geladen werden.", "IFLS Tuning Hub", 0)
  return
end

local ctx = ui_core.create_context("IFLS_TuningHub")
if not ctx then return end

local profiles = tuning.list_profiles() or {}
local state = tuning.get_state()
local profile_index = 1
for i,name in ipairs(profiles) do
  if name == state.profile then profile_index = i; break end
end

local function draw(ctx)
  ig.Text(ctx, "IFLS Tuning / Microtonal Basis")
  ig.Separator(ctx)

  local enabled = state.enabled and true or false
  local changed
  changed, enabled = ig.Checkbox(ctx, "Tuning Enabled", enabled)
  if changed then state.enabled = enabled end

  ig.Separator(ctx)
  ig.Text(ctx, "Tuning Profile")
  ig.Separator(ctx)

  local preview = profiles[profile_index] or "Equal12"
  if ig.BeginCombo(ctx, "Profile", preview) then
    for i,name in ipairs(profiles) do
      local sel = (i == profile_index)
      if ig.Selectable(ctx, name, sel) then
        profile_index = i
        state.profile = name
      end
      if sel then ig.SetItemDefaultFocus(ctx) end
    end
    ig.EndCombo(ctx)
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Pitchbend / Offset")
  ig.Separator(ctx)

  ig.PushItemWidth(ctx, 200)
  local pb = state.pitch_bend_semi or 2
  changed, pb = ig.InputInt(ctx, "Pitchbend Range (±Halbtöne)", pb)
  if changed then
    if pb < 1 then pb = 1 end
    if pb > 48 then pb = 48 end
    state.pitch_bend_semi = pb
  end

  local mo = state.master_offset or 0
  changed, mo = ig.InputDouble(ctx, "Master Offset (cents)", mo, 1.0, 10.0, "%.2f")
  if changed then state.master_offset = mo end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  if ig.Button(ctx, "Reload state") then
    state = tuning.get_state()
    profile_index = 1
    for i,name in ipairs(profiles) do
      if name == state.profile then profile_index = i; break end
    end
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Write state") then
    tuning.set_state(state)
  end

  ig.Separator(ctx)
  ig.TextWrapped(ctx,
    "IFLS_TuningDomain speichert Tuning-Profile im ExtState. " ..
    "JSFX wie 'IFLS MIDI Processor' können über Bridge-Skripte an diese Werte angepasst werden.")
end

ui_core.run_mainloop(ctx, "IFLS Tuning Hub", draw)
