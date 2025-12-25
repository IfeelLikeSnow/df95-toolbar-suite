
-- @description DF95 Drone Enums & Normalization (Phase L Harmonisierung)
-- @version 1.0
-- @author DF95
-- @about
--   Zentrale Definition der kanonischen Drone-Werte für:
--     * df95_drone_centerfreq
--     * df95_drone_density
--     * df95_drone_form
--     * df95_drone_motion
--     * df95_tension
--
--   Idee:
--     * AutoIngest Phase G, Inspector V5, Analyzer, Dashboard und PackExporter
--       sollen die gleichen Wertemengen verwenden.
--     * Diese Datei kann in allen relevanten Skripten via dofile() geladen werden.

local M = {}

-- Kanonische Enums
M.CENTERFREQ = { LOW = "LOW", MID = "MID", HIGH = "HIGH" }
M.DENSITY    = { LOW = "LOW", MED = "MED", HIGH = "HIGH" }
M.FORM       = {
  PAD       = "PAD",
  TEXTURE   = "TEXTURE",
  SWELL     = "SWELL",
  MOVEMENT  = "MOVEMENT",
  GROWL     = "GROWL",
}
M.MOTION     = {
  STATIC    = "STATIC",
  MOVEMENT  = "MOVEMENT",
  PULSE     = "PULSE",
  SWELL     = "SWELL",
}
M.TENSION    = {
  LOW       = "LOW",
  MED       = "MED",
  HIGH      = "HIGH",
  EXTREME   = "EXTREME",
}

-- Helpers
local function up(v)
  if v == nil then return "" end
  return tostring(v):upper()
end

-- Normalizer für unterschiedliche Schreibweisen aus älteren Phasen
function M.normalize_centerfreq(v)
  local s = up(v)
  if s == "LOW" or s == "LO" then return M.CENTERFREQ.LOW end
  if s == "MID" or s == "MIDRANGE" or s == "MID_RANGE" then return M.CENTERFREQ.MID end
  if s == "HIGH" or s == "HI" then return M.CENTERFREQ.HIGH end
  return s
end

function M.normalize_density(v)
  local s = up(v)
  if s == "LOW" or s == "THIN" then return M.DENSITY.LOW end
  if s == "MED" or s == "MEDIUM" or s == "MID" then return M.DENSITY.MED end
  if s == "HIGH" or s == "DENSE" then return M.DENSITY.HIGH end
  return s
end

function M.normalize_form(v)
  local s = up(v)
  if s == "PAD" or s == "DRONE_PAD" then return M.FORM.PAD end
  if s == "TEXTURE" or s == "TX" or s == "TEXTURED" then return M.FORM.TEXTURE end
  if s == "SWELL" or s == "RISE" then return M.FORM.SWELL end
  if s == "MOVEMENT" or s == "MOVING" or s == "MOTION" then return M.FORM.MOVEMENT end
  if s == "GROWL" or s == "GROWLER" then return M.FORM.GROWL end
  return s
end

function M.normalize_motion(v)
  local s = up(v)
  if s == "STATIC" or s == "STILL" then return M.MOTION.STATIC end
  if s == "MOVEMENT" or s == "MOVING" then return M.MOTION.MOVEMENT end
  if s == "PULSE" or s == "PULSING" or s == "RHYTHMIC" then return M.MOTION.PULSE end
  if s == "SWELL" or s == "RAMP" then return M.MOTION.SWELL end
  return s
end

function M.normalize_tension(v)
  local s = up(v)
  if s == "LOW" or s == "RELAXED" then return M.TENSION.LOW end
  if s == "MED" or s == "MEDIUM" or s == "MID" then return M.TENSION.MED end
  if s == "HIGH" or s == "TENSE" then return M.TENSION.HIGH end
  if s == "EXTREME" or s == "ULTRA" or s == "MAX" then return M.TENSION.EXTREME end
  return s
end

-- Normalizer für komplette Item-Tabelle (in-place)
function M.normalize_item_drone_fields(it)
  if not it then return end
  if it.df95_drone_centerfreq then
    it.df95_drone_centerfreq = M.normalize_centerfreq(it.df95_drone_centerfreq)
  end
  if it.df95_drone_density then
    it.df95_drone_density = M.normalize_density(it.df95_drone_density)
  end
  if it.df95_drone_form then
    it.df95_drone_form = M.normalize_form(it.df95_drone_form)
  end
  if it.df95_motion_strength or it.df95_drone_motion then
    local raw = it.df95_motion_strength or it.df95_drone_motion
    local norm = M.normalize_motion(raw)
    it.df95_motion_strength = norm
    it.df95_drone_motion    = norm
  end
  if it.df95_tension then
    it.df95_tension = M.normalize_tension(it.df95_tension)
  end
end

return M
