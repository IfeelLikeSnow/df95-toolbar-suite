-- IFLS_TuningDomain.lua
-- Phase 9+11: Tuning / Microtonal Domain (Basis)
-- ----------------------------------------------
-- Hält Tuning-Profile und Parameter im projektbezogenen ExtState.

local r = reaper
local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"

local ok_ext, ext = pcall(dofile, core_path .. "IFLS_ExtState.lua")
if not ok_ext or type(ext) ~= "table" then
  ext = {
    get_proj = function(_,_,d) return d end,
    set_proj = function() end,
  }
end

local M = {}
local NS_TUNING = "DF95_TUNING"

local function get_state()
  local st = {}
  st.enabled        = (ext.get_proj(NS_TUNING, "ENABLED", "0") == "1")
  st.profile        = ext.get_proj(NS_TUNING, "PROFILE", "Equal12")
  st.pitch_bend_semi= tonumber(ext.get_proj(NS_TUNING, "PITCH_BEND_SEMI", "2")) or 2
  st.master_offset  = tonumber(ext.get_proj(NS_TUNING, "MASTER_OFFSET", "0")) or 0
  return st
end

local function set_state(st)
  if st.enabled ~= nil then
    ext.set_proj(NS_TUNING, "ENABLED", st.enabled and "1" or "0")
  end
  if st.profile ~= nil then
    ext.set_proj(NS_TUNING, "PROFILE", tostring(st.profile))
  end
  if st.pitch_bend_semi ~= nil then
    ext.set_proj(NS_TUNING, "PITCH_BEND_SEMI", tostring(st.pitch_bend_semi))
  end
  if st.master_offset ~= nil then
    ext.set_proj(NS_TUNING, "MASTER_OFFSET", tostring(st.master_offset))
  end
end

local TUNING_PROFILES = {
  Equal12 = {
    name        = "Equal12",
    description = "Standard 12-TET ohne Abweichung.",
  },
  QuarterTone = {
    name        = "QuarterTone",
    description = "Jede zweite Note ±50 cents verschoben.",
  },
  FifthShift = {
    name        = "FifthShift",
    description = "Einige Noten leicht Richtung Quinte verschoben.",
  },
}

local function list_profiles()
  local names = {}
  for k in pairs(TUNING_PROFILES) do names[#names+1] = k end
  table.sort(names)
  return names
end

local function get_profile(name)
  if not name or name == "" then return TUNING_PROFILES.Equal12 end
  return TUNING_PROFILES[name] or TUNING_PROFILES.Equal12
end

local function offset_equal12(note) return 0.0 end

local function offset_quartertone(note)
  local idx = note % 2
  if idx == 0 then return -50.0 else return 50.0 end
end

local function offset_fifthshift(note)
  local idx = note % 12
  if idx == 1 or idx == 6 then
    return 14.0
  elseif idx == 4 or idx == 9 then
    return -14.0
  end
  return 0.0
end

local function offset_for_profile(name, note)
  if name == "QuarterTone" then
    return offset_quartertone(note)
  elseif name == "FifthShift" then
    return offset_fifthshift(note)
  end
  return offset_equal12(note)
end

function M.get_state() return get_state() end
function M.set_state(st) return set_state(st or {}) end
function M.list_profiles() return list_profiles() end
function M.get_profile(name) return get_profile(name) end

function M.get_note_offset_cents(note)
  local st = get_state()
  if not st.enabled then return 0.0 end
  local base = offset_for_profile(st.profile, note or 60)
  return base + (st.master_offset or 0)
end

function M.cents_to_pitchbend_value(cents, pb_range_semi)
  local st = get_state()
  pb_range_semi = pb_range_semi or st.pitch_bend_semi or 2
  local semitones = cents / 100.0
  local norm = (semitones / pb_range_semi)
  local value = 8192 + math.floor(norm * 8192)
  if value < 0 then value = 0 end
  if value > 16383 then value = 16383 end
  return value
end

return M
