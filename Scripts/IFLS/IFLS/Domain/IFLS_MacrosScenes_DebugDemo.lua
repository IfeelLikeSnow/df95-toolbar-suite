-- IFLS_MacrosScenes_DebugDemo.lua
-- Phase 92: Debug/demo script for MacroControls + ScenePresets.
--
-- This script:
--   * tweaks some macro values,
--   * prints derived settings,
--   * builds a demo scene and saves it,
--   * lists all saved scenes.

local MacroControls = require("IFLS_MacroControls")
local ScenePresets  = require("IFLS_ScenePresets")

reaper.ShowConsoleMsg("=== IFLS Macros & Scenes Demo ===\n")

-- Set some macros
MacroControls.set("glitch_intensity", 0.8)
MacroControls.set("rhythm_chaos",     0.7)
MacroControls.set("texture_depth",    0.6)
MacroControls.set("human_vs_robot",   0.3)

local derived = MacroControls.get_derived_snapshot()
reaper.ShowConsoleMsg("Derived macro settings:\n")
for group, vals in pairs(derived) do
  reaper.ShowConsoleMsg("["..group.."]\n")
  for k, v in pairs(vals) do
    reaper.ShowConsoleMsg(string.format("  %s = %s\n", k, tostring(v)))
  end
end

-- Build a demo scene from these macros
local scene = ScenePresets.capture_current{
  id             = "demo_glitch_intro",
  name           = "Demo Glitch Intro",
  artist_id      = "artist_demo",
  artist_name    = "Demo Artist",
  flavor         = "GlitchCore",
  groove_profile = "IDM_MicroSwing",
  rhythm_style   = derived.rhythm.style_name or "IDM_Chaos",
  macros         = MacroControls.get_all(),
  meta           = {
    bpm_min = 140,
    bpm_max = 180,
    tags    = {"intro","glitch"},
    notes   = "High-energy glitch intro scene",
  },
}

ScenePresets.save(scene)
reaper.ShowConsoleMsg("Saved scene: "..scene.id.."\n")

-- List all scenes
local scenes = ScenePresets.list()
reaper.ShowConsoleMsg("Current scenes:\n")
for _, sc in ipairs(scenes) do
  reaper.ShowConsoleMsg(string.format("  id=%s, name=%s, flavor=%s, groove=%s, rhythm=%s\n",
    tostring(sc.id), tostring(sc.name), tostring(sc.flavor),
    tostring(sc.groove_profile), tostring(sc.rhythm_style)))
end

reaper.ShowConsoleMsg("=== End Macros & Scenes Demo ===\n")
