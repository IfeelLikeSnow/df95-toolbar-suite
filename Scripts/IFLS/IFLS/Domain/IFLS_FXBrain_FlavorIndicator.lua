-- IFLS_FXBrain_FlavorIndicator.lua
-- Phase 86: Example ReaImGui window to visualize the active IDM flavor.
--
-- REQUIREMENTS:
--   - ReaImGui extension installed (via ReaPack, ReaTeam Extensions).
--   - IFLS_FlavorState.lua in your package.path and require-able.
--
-- This script is meant as a reference implementation:
--   * You can run it as a standalone script to see the flavor indicator.
--   * Or you can copy the core UI block into your existing FX Brain ImGui script.

local ok, FlavorState = pcall(require, "IFLS_FlavorState")
if not ok then
  reaper.ShowMessageBox("Could not require 'IFLS_FlavorState'. Please make sure it is in your ReaScript path.", "IFLS FXBrain", 0)
  return
end

-- Check ReaImGui
if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox("ReaImGui extension is not available. Install 'ReaImGui' via ReaPack (ReaTeam Extensions).", "IFLS FXBrain", 0)
  return
end

local ctx = reaper.ImGui_CreateContext('IFLS FX Brain - Flavor Indicator')
local size_cond = reaper.ImGui_Cond_FirstUseEver()

-- Simple color table for flavors (r,g,b,a 0..1)
local flavor_colors = {
  GlitchCore     = {1.0, 0.3, 0.3, 1.0},
  Microglitch    = {1.0, 0.6, 0.1, 1.0},
  AmbientSpace   = {0.5, 0.8, 1.0, 1.0},
  DrumFX         = {0.8, 0.8, 0.3, 1.0},
  Microbeats     = {0.7, 0.4, 1.0, 1.0},
  Neutral        = {0.8, 0.8, 0.8, 1.0},
}

local function get_flavor_color(flavor)
  local c = flavor_colors[flavor] or flavor_colors["Neutral"]
  local r, g, b, a = table.unpack(c)
  return reaper.ImGui_ColorConvertDouble4ToU32(ctx, r, g, b, a)
end

local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 260, 110, size_cond)

  local visible, open = reaper.ImGui_Begin(ctx, 'IFLS FX Brain - Flavor', true)
  if visible then
    local state = FlavorState.get_active()
    local flavor = state.final_flavor or "Neutral"
    local source = state.source or "default"

    -- Title
    reaper.ImGui_Text(ctx, "Active Flavor")

    -- Colored badge
    local col = get_flavor_color(flavor)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), col)
    reaper.ImGui_BulletText(ctx, flavor)
    reaper.ImGui_PopStyleColor(ctx)

    -- Source info
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Source: " .. source)

    -- Optional extended info in a collapsing header
    if reaper.ImGui_CollapsingHeader(ctx, "Details", true) then
      reaper.ImGui_Text(ctx, "Artist default : " .. tostring(state.artist_default))
      reaper.ImGui_Text(ctx, "Hub override   : " .. tostring(state.hub_override))
      reaper.ImGui_Text(ctx, "Chain override : " .. tostring(state.chain_override))
    end

    -- Small hint
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_TextWrapped(ctx, "Hint: integrate this block into your main FX Brain window where you want the flavor indicator to appear.")
  end
  reaper.ImGui_End(ctx)

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)
