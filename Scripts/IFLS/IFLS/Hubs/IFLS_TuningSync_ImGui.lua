-- IFLS_TuningSync_ImGui.lua
-- Phase 11: Unified Tuning Engine - Sync Panel

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"
local tools_path    = resource_path .. "/Scripts/IFLS/IFLS/Tools/"

local ok_ui, ui_core = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox("IFLS Tuning Sync Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.", "IFLS Tuning Sync Hub", 0)
  return
end

local ok_tuning, tuning = pcall(dofile, domain_path .. "IFLS_TuningDomain.lua")
if not ok_tuning or type(tuning) ~= "table" then
  r.ShowMessageBox("IFLS Tuning Sync Hub: IFLS_TuningDomain.lua konnte nicht geladen werden.", "IFLS Tuning Sync Hub", 0)
  return
end

local ok_bridge, bridge = pcall(dofile, tools_path .. "IFLS_TuningBridge.lua")
if not ok_bridge or type(bridge) ~= "table" then
  r.ShowMessageBox("IFLS Tuning Sync Hub: IFLS_TuningBridge.lua konnte nicht geladen werden.", "IFLS Tuning Sync Hub", 0)
  return
end

local ctx = ui_core.create_context("IFLS_TuningSyncHub")
if not ctx then return end

local auto_sync_selected = false
local last_sync_count = 0

local function draw(ctx)
  local st = tuning.get_state()

  ig.Text(ctx, "IFLS Tuning Sync Hub")
  ig.Separator(ctx)

  ig.Text(ctx, "Current Tuning State")
  ig.Separator(ctx)
  ig.Text(ctx, ("Enabled:         %s"):format(st.enabled and "Yes" or "No"))
  ig.Text(ctx, ("Profile:         %s"):format(st.profile or "Equal12"))
  ig.Text(ctx, ("Pitchbend Range: ±%d semitones"):format(st.pitch_bend_semi or 2))
  ig.Text(ctx, ("Master Offset:   %.2f cents"):format(st.master_offset or 0))

  ig.Separator(ctx)
  ig.Text(ctx, "Sync")
  ig.Separator(ctx)

  if ig.Button(ctx, "Sync Selected Tracks") then
    last_sync_count = bridge.sync_selected()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Sync All Tracks") then
    last_sync_count = bridge.sync_all()
  end

  local changed
  changed, auto_sync_selected = ig.Checkbox(ctx, "Auto-sync selected tracks (on UI refresh)", auto_sync_selected)
  if auto_sync_selected then
    last_sync_count = bridge.sync_selected()
  end

  ig.Separator(ctx)
  ig.Text(ctx, ("Last sync: %d IFLS_MIDIProcessor instances updated."):format(last_sync_count))

  ig.Separator(ctx)
  ig.TextWrapped(ctx,
    "Workflow:
" ..
    "  1. Stelle Tuning in IFLS_TuningHub ein.
" ..
    "  2. Füge 'IFLS MIDI Processor' im FX-Chain deiner Instrument-Spuren ein.
" ..
    "  3. Nutze diesen Hub, um die Slider des JSFX mit dem Tuning-State zu synchronisieren.")
end

ui_core.run_mainloop(ctx, "IFLS Tuning Sync Hub", draw)
