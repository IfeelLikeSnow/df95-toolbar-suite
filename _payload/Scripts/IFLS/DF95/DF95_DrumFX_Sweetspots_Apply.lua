-- DF95_DrumFX_Sweetspots_Apply.lua
-- Setzt "Sweetspot"-Parameter für wichtige Drum-FX auf ausgewählten Tracks.
-- Arbeitet auf bereits geladenen FX-Chains (VST3/VST2) und nutzt die im DF95_ParamDump
-- ermittelten Param-Indices.
--
-- Unterstützte Plugins:
--   - VST3: Bark of Dog 3 (Boz Digital Labs) (mono)
--   - VST3: bx_boom (Plugin Alliance)
--   - VST3: bx_subfilter (Plugin Alliance)
--   - VST3: kHs Transient Shaper (Kilohearts)
--   - VST : MH Thump (Metric Halo)
--
-- Workflow:
--   1. Lade eine der neuen Bus_IDM_* RfxChains auf den entsprechenden Drum-Bus.
--   2. Wähle den/die Bus-Tracks aus.
--   3. Setze ROLE unten auf "kick_A", "kick_B", "kick_C", "snare", "hats", "perc", "glitch",
--      "kick_thump" oder "snare_thump".
--   4. Script ausführen → es stellt die wichtigsten Parameter passend ein.

local r = reaper

------------------------------------------------------------
-- USER CONFIG
------------------------------------------------------------

-- Rolle dieses Bus-Tracks:
--   "kick_A"       - Kick Punch+Sub (bx_boom + subfilter + Bark)
--   "kick_B"       - Kick Analog Warm
--   "kick_C"       - Kick IDM Hard
--   "kick_thump"   - reiner Thump-Sub-Bus
--   "snare"        - Snare Snap+Body
--   "snare_thump"  - Snare Body-Thump
--   "hats"         - Hats Tick+Dry
--   "perc"         - MicroPerc TransientGlue
--   "glitch"       - Glitch Smash/Transient
local ROLE = "kick_A"

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function fx_name(track, fx)
  local ok, name = r.TrackFX_GetFXName(track, fx, "")
  if not ok then return "" end
  return name
end

local function contains(str, needle)
  if not str then return false end
  return str:lower():find(needle:lower(), 1, true) ~= nil
end

------------------------------------------------------------
-- Sweetspot Parameter-Setter
------------------------------------------------------------

local function set_param(track, fx, param_idx, val)
  if fx < 0 or param_idx < 0 then return end
  r.TrackFX_SetParamNormalized(track, fx, param_idx, val)
end

-- Bark of Dog 3 (Boz Digital Labs) (mono)
-- Param-Indices aus Dump:
--   0 Plugin Enable
--   1 Channel Mode
--   2 Mix
--   3 Input Gain
--   4 Boost
--   5 Frequency
--   6 Mode
--   7 Analog
--   8 Bypass
--   9 Bypass
--   10 Wet
--   11 Delta
local function tune_bark_of_dog(track, fx, role)
  if role == "kick_A" or role == "kick_B" or role == "kick_C" then
    -- Kick: Sub-Fokus um 50–80 Hz, moderater Boost
    set_param(track, fx, 2, 1.0)      -- Mix
    set_param(track, fx, 3, 0.5)      -- Input
    set_param(track, fx, 4, 0.30)     -- Boost
    set_param(track, fx, 5, 0.38)     -- Frequency ~60–80 Hz
    set_param(track, fx, 6, 0.0)      -- Mode Classic
    set_param(track, fx, 7, 0.25)     -- Analog leicht
    set_param(track, fx, 10, 1.0)     -- Wet
  elseif role == "snare" or role == "snare_thump" then
    -- Snare: Low-Mid Body
    set_param(track, fx, 2, 0.8)
    set_param(track, fx, 3, 0.5)
    set_param(track, fx, 4, 0.22)
    set_param(track, fx, 5, 0.55)     -- ~180–220 Hz
    set_param(track, fx, 6, 0.4)      -- Passive/Combo
    set_param(track, fx, 7, 0.2)
    set_param(track, fx, 10, 0.8)
  elseif role == "perc" then
    set_param(track, fx, 2, 0.65)
    set_param(track, fx, 3, 0.5)
    set_param(track, fx, 4, 0.18)
    set_param(track, fx, 5, 0.45)
    set_param(track, fx, 6, 0.0)
    set_param(track, fx, 7, 0.15)
    set_param(track, fx, 10, 0.7)
  elseif role == "glitch" then
    set_param(track, fx, 2, 0.7)
    set_param(track, fx, 3, 0.5)
    set_param(track, fx, 4, 0.35)
    set_param(track, fx, 5, 0.5)
    set_param(track, fx, 6, 0.7)
    set_param(track, fx, 7, 0.3)
    set_param(track, fx, 10, 0.9)
  end
end

-- bx_boom (Plugin Alliance)
-- Params:
--   0 Master Bypass
--   1 Boom! Factor
--   2 Mode
--   5 Wet
local function tune_bx_boom(track, fx, role)
  if role == "kick_A" then
    set_param(track, fx, 1, 0.65)
    set_param(track, fx, 2, 0.4)
    set_param(track, fx, 5, 0.9)
  elseif role == "kick_B" then
    set_param(track, fx, 1, 0.58)
    set_param(track, fx, 2, 0.5)
    set_param(track, fx, 5, 0.75)
  elseif role == "kick_C" then
    set_param(track, fx, 1, 0.78)
    set_param(track, fx, 2, 0.8)
    set_param(track, fx, 5, 1.0)
  end
end

-- bx_subfilter (Plugin Alliance)
-- Params:
--   0 Bypass
--   1 Setting
--   2 Input Gain
--   3 Tight Punch Filter
--   4 Resonance
--   5 Low End
--   6 Output Gain
--   9 Wet
local function tune_bx_subfilter(track, fx, role)
  if role == "kick_A" or role == "kick_C" or role == "kick_B" then
    set_param(track, fx, 1, 0.0)      -- default setting
    set_param(track, fx, 2, 0.5)      -- in gain
    set_param(track, fx, 3, 0.9)      -- Tight Punch on
    set_param(track, fx, 4, 0.62)     -- Resonance
    set_param(track, fx, 5, 0.62)     -- Low End
    set_param(track, fx, 6, 0.5)      -- out gain
    set_param(track, fx, 9, 0.9)      -- wet
  elseif role == "snare" or role == "perc" then
    set_param(track, fx, 3, 0.5)
    set_param(track, fx, 4, 0.45)
    set_param(track, fx, 5, 0.35)
    set_param(track, fx, 9, 0.7)
  elseif role == "glitch" then
    set_param(track, fx, 3, 1.0)
    set_param(track, fx, 4, 0.8)
    set_param(track, fx, 5, 0.75)
    set_param(track, fx, 9, 1.0)
  end
end

-- kHs Transient Shaper (Kilohearts)
-- Params:
--   0 Attack
--   1 Pump
--   2 Sustain
--   3 Speed
--   4 Clip
local function tune_khs_transient(track, fx, role)
  if role == "kick_A" or role == "kick_B" or role == "kick_C" then
    set_param(track, fx, 0, 0.68)  -- Attack +
    set_param(track, fx, 1, 0.22)  -- Pump moderat
    set_param(track, fx, 2, 0.42)  -- Sustain leicht runter
    set_param(track, fx, 3, 0.52)  -- Speed mid
    set_param(track, fx, 4, 0.6)   -- Clip leicht an
  elseif role == "snare" then
    set_param(track, fx, 0, 0.72)
    set_param(track, fx, 1, 0.3)
    set_param(track, fx, 2, 0.45)
    set_param(track, fx, 3, 0.65)
    set_param(track, fx, 4, 0.65)
  elseif role == "hats" then
    set_param(track, fx, 0, 0.6)
    set_param(track, fx, 1, 0.35)
    set_param(track, fx, 2, 0.3)
    set_param(track, fx, 3, 0.7)
    set_param(track, fx, 4, 0.6)
  elseif role == "perc" then
    set_param(track, fx, 0, 0.65)
    set_param(track, fx, 1, 0.28)
    set_param(track, fx, 2, 0.5)
    set_param(track, fx, 3, 0.55)
    set_param(track, fx, 4, 0.5)
  elseif role == "glitch" then
    set_param(track, fx, 0, 0.8)
    set_param(track, fx, 1, 0.5)
    set_param(track, fx, 2, 0.3)
    set_param(track, fx, 3, 0.7)
    set_param(track, fx, 4, 0.8)
  end
end

-- MH Thump (Metric Halo)
-- Params (Auszug):
--   0 MstrByp
--   1 Osc1Att
--   2 Osc1Sst
--   3 Osc1Enb
--   4 Osc1MxG
--   ...
--   13 Wet/Dry
--   14 OutptGn
local function tune_thump(track, fx, role)
  if role == "kick_thump" or role == "kick_A" or role == "kick_B" or role == "kick_C" then
    -- Sub-Kick
    set_param(track, fx, 3, 1.0)    -- Osc1 enable
    set_param(track, fx, 1, 0.1)    -- Attack kurz
    set_param(track, fx, 2, 0.35)   -- Sustain ~150–200ms
    set_param(track, fx, 4, 0.8)    -- Max Gain
    set_param(track, fx, 13, 0.85)  -- Wet/Dry
    set_param(track, fx, 14, 0.5)   -- Out Gain neutral
  elseif role == "snare_thump" or role == "snare" then
    -- Snare-Body
    set_param(track, fx, 3, 1.0)
    set_param(track, fx, 1, 0.05)
    set_param(track, fx, 2, 0.25)
    set_param(track, fx, 4, 0.6)
    set_param(track, fx, 13, 0.6)
    set_param(track, fx, 14, 0.5)
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function process_track(track)
  local fx_count = r.TrackFX_GetCount(track)
  for fx = 0, fx_count-1 do
    local name = fx_name(track, fx)
    if contains(name, "Bark of Dog 3") then
      tune_bark_of_dog(track, fx, ROLE)
    elseif contains(name, "bx_boom") then
      tune_bx_boom(track, fx, ROLE)
    elseif contains(name, "bx_subfilter") then
      tune_bx_subfilter(track, fx, ROLE)
    elseif contains(name, "kHs Transient Shaper") then
      tune_khs_transient(track, fx, ROLE)
    elseif contains(name, "MH Thump") then
      tune_thump(track, fx, ROLE)
    end
  end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
r.ClearConsole()

local sel_count = r.CountSelectedTracks(0)
if sel_count == 0 then
  msg("Keine Tracks ausgewählt. Bitte mindestens einen Drum-Bus auswählen.")
else
  msg("DF95 DrumFX Sweetspots: ROLE = " .. ROLE)
  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    process_track(tr)
  end
end

r.PreventUIRefresh(-1)
r.Undo_EndBlock("DF95 DrumFX Sweetspots Apply (" .. ROLE .. ")", -1)
