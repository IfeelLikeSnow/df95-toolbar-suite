-- IFLS_FlavorState.lua
-- Phase 86: Flavor Propagation Visualization
-- Central helper for reading/writing the currently active IDM "flavor"
-- across Artist defaults, ArtistHub overrides and ArtistFXChain overrides.
--
-- Drop this file into your IFLS/DF95 Lua modules folder and:
--   local FlavorState = require("IFLS_FlavorState")
--
-- Then use:
--   local state = FlavorState.get_active()
--   reaper.ShowConsoleMsg(state.final_flavor .. " from " .. state.source .. "\n")

local FlavorState = {}

----------------------------------------------------------------
-- CONFIGURATION
----------------------------------------------------------------

-- Namespace used for project extstate
local NS = "IFLS"

-- Keys used in project extstate.
-- You can adapt these to your existing naming.
local KEY_ARTIST_DEFAULT   = "artist_default_flavor"
local KEY_HUB_OVERRIDE     = "artisthub_flavor_override"
local KEY_CHAIN_OVERRIDE   = "artistfxchain_flavor_override"

-- Optional cache key, if you want to store the resolved flavor.
local KEY_FINAL_CACHE      = "active_flavor_cache"

-- Optional: default flavor if absolutely nothing is set.
local DEFAULT_FLAVOR       = "Neutral"

----------------------------------------------------------------
-- INTERNAL HELPERS
----------------------------------------------------------------

local function get_proj()
  -- 0 = current project
  return 0
end

local function get_ext_state(key)
  local proj = get_proj()
  local rv, val = reaper.GetProjExtState(proj, NS, key)
  if rv == 0 or val == "" then return nil end
  return val
end

local function set_ext_state(key, val)
  local proj = get_proj()
  if val == nil or val == "" then
    -- clear key by setting empty string
    reaper.SetProjExtState(proj, NS, key, "")
  else
    reaper.SetProjExtState(proj, NS, key, tostring(val))
  end
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

--- Resolve the currently active flavor and its source.
-- Returns a table:
-- {
--   artist_default = string|nil,
--   hub_override   = string|nil,
--   chain_override = string|nil,
--   final_flavor   = string,  -- always non-nil
--   source         = "chain_override" | "hub_override" | "artist_default" | "default"
-- }
function FlavorState.get_active()
  local artist_default = get_ext_state(KEY_ARTIST_DEFAULT)
  local hub_override   = get_ext_state(KEY_HUB_OVERRIDE)
  local chain_override = get_ext_state(KEY_CHAIN_OVERRIDE)

  local final_flavor, source

  if chain_override and chain_override ~= "" then
    final_flavor = chain_override
    source = "chain_override"
  elseif hub_override and hub_override ~= "" then
    final_flavor = hub_override
    source = "hub_override"
  elseif artist_default and artist_default ~= "" then
    final_flavor = artist_default
    source = "artist_default"
  else
    final_flavor = DEFAULT_FLAVOR
    source = "default"
  end

  -- optional cache write
  set_ext_state(KEY_FINAL_CACHE, final_flavor)

  return {
    artist_default = artist_default,
    hub_override   = hub_override,
    chain_override = chain_override,
    final_flavor   = final_flavor,
    source         = source,
  }
end

----------------------------------------------------------------
-- Mutators for the different levels
----------------------------------------------------------------

function FlavorState.set_artist_default(flavor)
  set_ext_state(KEY_ARTIST_DEFAULT, flavor)
end

function FlavorState.clear_artist_default()
  set_ext_state(KEY_ARTIST_DEFAULT, "")
end

function FlavorState.set_hub_override(flavor)
  set_ext_state(KEY_HUB_OVERRIDE, flavor)
end

function FlavorState.clear_hub_override()
  set_ext_state(KEY_HUB_OVERRIDE, "")
end

function FlavorState.set_chain_override(flavor)
  set_ext_state(KEY_CHAIN_OVERRIDE, flavor)
end

function FlavorState.clear_chain_override()
  set_ext_state(KEY_CHAIN_OVERRIDE, "")
end

----------------------------------------------------------------
-- Debug helpers
----------------------------------------------------------------

function FlavorState.debug_dump_to_console()
  local s = FlavorState.get_active()
  reaper.ShowConsoleMsg("=== IFLS FlavorState ===\n")
  reaper.ShowConsoleMsg("artist_default : " .. tostring(s.artist_default) .. "\n")
  reaper.ShowConsoleMsg("hub_override   : " .. tostring(s.hub_override) .. "\n")
  reaper.ShowConsoleMsg("chain_override : " .. tostring(s.chain_override) .. "\n")
  reaper.ShowConsoleMsg("final_flavor   : " .. tostring(s.final_flavor) .. "\n")
  reaper.ShowConsoleMsg("source         : " .. tostring(s.source) .. "\n")
  reaper.ShowConsoleMsg("========================\n")
end

return FlavorState
