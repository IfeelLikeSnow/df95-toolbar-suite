
-- DF95_ReampSuite_Profiles.lua
-- Kapselt Reamp-Profile (Interface + Routing-Presets)
-- Gibt eine Tabelle `profiles` zurück und Hilfsfunktionen zum Auswählen/Anwenden.

local M = {}

M.profiles = {
  UR22_DI_Pedals = {
    name        = "UR22mkII → DI/Pedals",
    interface   = "Steinberg UR22mkII",
    out_ch      = 3,   -- Beispiel-Defaults, bitte an dein Setup anpassen
    in_ch       = 1,
    description = "Reamp über UR22: Out3 → Palmer/DI → In1 (Mono).",
  },
  Presonus_DI_Pedals = {
    name        = "PreSonus → DI/Pedals",
    interface   = "PreSonus",
    out_ch      = 3,
    in_ch       = 1,
    description = "Reamp über PreSonus: Out3 → Palmer/DI → In1 (Mono).",
  },
  ZoomF6_Reamp = {
    name        = "Zoom F6 → DI/Pedals",
    interface   = "Zoom F6",
    out_ch      = 3,
    in_ch       = 1,
    description = "Reamp über Zoom F6 (Line Out) → Palmer/DI → In1 (Mono).",
  },
  Generic_Reamp = {
    name        = "Generic Reamp",
    interface   = "Generic",
    out_ch      = 3,
    in_ch       = 1,
    description = "Generisches Reamp-Setup: Out3 → Palmer/DI → In1 (Mono).",
  },
}

local EXT_NS = "DF95_REAMP"
local KEY_PROFILE = "PROFILE"

function M.get_active_key()
  local r = reaper
  local val = r.GetExtState(EXT_NS, KEY_PROFILE)
  if val and val ~= "" and M.profiles[val] then
    return val
  end
  return "Generic_Reamp"
end

function M.set_active_key(key)
  local r = reaper
  if not key or not M.profiles[key] then return end
  r.SetExtState(EXT_NS, KEY_PROFILE, key, true)
end

function M.get_active_profile()
  return M.profiles[M.get_active_key()]
end

function M.apply_active_to_ext()
  local r = reaper
  local key = M.get_active_key()
  local p = M.profiles[key]
  if not p then return end
  r.SetExtState(EXT_NS, "OUT_CH", tostring(p.out_ch or 3), true)
  r.SetExtState(EXT_NS, "IN_CH",  tostring(p.in_ch or 1), true)
end

return M
