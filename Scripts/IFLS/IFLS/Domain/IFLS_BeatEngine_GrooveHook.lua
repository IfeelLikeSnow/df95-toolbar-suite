-- IFLS_BeatEngine_GrooveHook.lua
-- Phase 87: Reference hook for integrating GroovePool with your BeatEngine.
--
-- This script is NOT meant to replace your existing BeatEngine, but to
-- show how/where to call the groove logic before MIDI export.
--
-- EXPECTED CONTEXT (adapt names to your repo):
--   - A function BeatEngine.collect_midi_events(pattern, track_context) -> events[]
--   - An "artist" table with groove_profile_name attached to project/session.
--   - IFLS_GroovePool.lua & IFLS_GrooveProfiles.lua available via require().
--
-- Deep thinking / rationale:
--   * Groove is a separate step AFTER rhythmic pattern generation but
--     BEFORE final quantization/export, similar to how Live's Groove Pool
--     can be applied non-destructively to MIDI/audio clips. citeturn2search0turn2search3turn2search8
--   * It sits conceptually next to your existing Humanize/Microtiming
--     logic described in your snapshot, but is deterministic rather than
--     random. fileciteturn1file0

local GroovePool = require("IFLS_GroovePool")

local BeatEngineGrooveHook = {}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

-- Helper to get current artist profile; adapt to your system.
local function get_current_artist()
  -- Placeholder: fetch from your Artist system / ExtState.
  -- e.g. IFLS_ArtistDomain.get_active_artist()
  return {
    name = "DefaultArtist",
    groove_profile_name = "IDM_MicroSwing",
  }
end

-- Decide which groove profile and amount to use.
local function decide_groove(pattern, track_ctx)
  local artist = get_current_artist()
  local profile = GroovePool.get_default_for_artist(artist)
  local amount = 1.0

  -- Optionally adapt amount based on:
  --   * pattern complexity
  --   * BPM
  --   * Artist style flags
  -- etc.
  return profile, amount
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

--- Main entry point called by your BeatEngine before MIDI export.
-- params:
--   pattern: your internal pattern representation
--   track_ctx: additional context (e.g. instrument type)
--   collect_fn: function(pattern, track_ctx) -> events[]
--
-- returns:
--   events[] with groove applied.
function BeatEngineGrooveHook.process(pattern, track_ctx, collect_fn)
  local events = collect_fn(pattern, track_ctx)
  if not events or #events == 0 then return events end

  local profile, amount = decide_groove(pattern, track_ctx)
  if not profile or amount <= 0.0 then
    return events
  end

  events = GroovePool.apply_to_note_events(events, profile, amount)
  return events
end

return BeatEngineGrooveHook
