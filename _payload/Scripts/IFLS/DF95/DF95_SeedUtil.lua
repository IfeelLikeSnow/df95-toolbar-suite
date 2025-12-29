-- @description Seed Utility (Save/Load per Project ExtState)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Hilfsskripte: Speichern/Laden eines Seeds pro Projekt: ExtState("DF95","SEED")

local r = reaper

local function save_seed()
  local ok, seed = r.GetUserInputs("DF95 Seed speichern", 1, "Seed-Wert (Integer):", "")
  if not ok then return end
  r.SetProjExtState(0, "DF95", "SEED", seed or "")
  r.ShowMessageBox("Seed gespeichert: "..tostring(seed), "DF95 Seed", 0)
end

local function load_seed()
  local _, seed = r.GetProjExtState(0, "DF95", "SEED")
  r.ShowMessageBox("Aktueller Project-Seed: "..(seed or "(leer)"), "DF95 Seed", 0)
end

-- expose
return { save_seed = save_seed, load_seed = load_seed }