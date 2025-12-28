-- DF95_Modulate_ApplyCategoryFX_ToSelectedTracks.lua
-- Phase 113: Helper-Script zum Aufruf der DF95_CategoryFX_Engine
--
-- Dieses Script ist als "Frontdoor" gedacht:
--   * Wähle einen oder mehrere Tracks (z.B. [IFLS Sum] Kick, [IFLS Slices] Snare, FX-Busse)
--   * Starte dieses Script
--   * Es ruft DF95_CategoryFX_ApplyToTrack(...) aus DF95_CategoryFX_Engine.lua auf
--
-- Intensität kann per einfachem Dialog gewählt werden:
--   "subtle", "medium", "extreme"

local r = reaper

local function ensure_engine_loaded()
  local info = debug.getinfo(1, "S")
  local this_path = info and info.source:match("^@(.+)$") or ""
  if this_path == "" then
    return false, "Konnte Script-Pfad nicht bestimmen."
  end
  local sep = package.config:sub(1,1)
  local base = this_path:match("^(.*"..sep..")") or ""
  if base == "" then
    return false, "Konnte Basisverzeichnis nicht bestimmen."
  end
  local engine_path = base .. "DF95_CategoryFX_Engine.lua"
  local f = io.open(engine_path, "r")
  if not f then
    return false, "DF95_CategoryFX_Engine.lua nicht gefunden neben diesem Script."
  end
  f:close()
  dofile(engine_path)
  if not DF95_CategoryFX_ApplyToTrack then
    return false, "DF95_CategoryFX_Engine.lua konnte nicht geladen werden."
  end
  return true
end

local function main()
  local ok, err = ensure_engine_loaded()
  if not ok then
    r.ShowMessageBox(
      "Fehler beim Laden der Category FX Engine:\n" .. tostring(err),
      "DF95 Category FX Modulate Helper",
      0
    )
    return
  end

  local num_sel = r.CountSelectedTracks(0)
  if num_sel == 0 then
    r.ShowMessageBox(
      "Keine Tracks ausgewählt.\nBitte wähle einen oder mehrere Tracks aus\nund starte das Script erneut.",
      "DF95 Category FX Modulate Helper",
      0
    )
    return
  end

  local ok2, input = r.GetUserInputs(
    "DF95 Category FX – Intensität",
    1,
    "Intensity (subtle/medium/extreme):",
    "medium"
  )
  if not ok2 or not input or input == "" then return end
  local intensity = input:match("^%s*(.-)%s*$")

  r.Undo_BeginBlock()

  for i = 0, num_sel-1 do
    local tr = r.GetSelectedTrack(0, i)
    DF95_CategoryFX_ApplyToTrack(tr, nil, intensity)
  end

  r.Undo_EndBlock("DF95 Category FX Modulate (" .. intensity .. ")", -1)
end

main()
