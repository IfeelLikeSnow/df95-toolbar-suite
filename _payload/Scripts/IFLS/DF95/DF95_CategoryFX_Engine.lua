-- DF95_CategoryFX_Engine.lua
-- Phase 113: Kategorie-spezifische FX-Engine für Modulation & Drum-Bus-Design
--
-- Zweck
-- =====
-- Diese Datei stellt eine kleine API bereit, mit der andere DF95/IFLS-Scripte
-- kategorieabhängig sinnvolle FX-Ketten auf Tracks legen können.
--
-- Sie ist bewusst generisch gehalten und nutzt vor allem:
--   * Stock-Plugins (ReaEQ, ReaComp, ReaDelay, ReaVerbate, JSFX)
--   * IFLS/DF95-eigene JSFX, falls vorhanden (z.B. IFLS_Drum_RR_Velocity_Mapper_Phase112)
--
-- WICHTIG:
--   * Wenn ein Plugin nicht installiert ist, wird der Eintrag einfach übersprungen.
--   * Die Engine bestimmt die Kategorie aus dem Tracknamen oder einem expliziten Parameter.
--
-- Öffentliche Funktionen:
--   DF95_CategoryFX_DetectCategoryFromTrackName(track_name) -> string
--   DF95_CategoryFX_ApplyToTrack(track, category, intensity)
--
--   intensity: "subtle", "medium", "extreme" (oder nil -> "medium")

local r = reaper

------------------------------------------------------------
-- Kategorie-Erkennung
------------------------------------------------------------

function DF95_CategoryFX_DetectCategoryFromTrackName(track_name)
  local name = (track_name or ""):lower()

  if name:find("kick") or name:find("bd") or name:find("kic") then
    return "Kick"
  end
  if name:find("snare") or name:find("snr") or name:find("sd") then
    return "Snare"
  end
  if name:find("hat") or name:find("hihat") or name:find("hh") then
    if name:find("open") or name:find("op") then
      return "HihatOpen"
    else
      return "HihatClosed"
    end
  end
  if name:find("tom") then
    return "Tom"
  end
  if name:find("clap") or name:find("clp") then
    return "Clap"
  end
  if name:find("shaker") or name:find("shk") then
    return "Shaker"
  end
  if name:find("perc") or name:find("prc") or name:find("percussion") then
    return "Perc"
  end
  if name:find("room") then
    return "Room"
  end
  if name:find("oh ") or name:find("overhead") then
    return "Overhead"
  end
  if name:find("fx") or name:find("impact") or name:find("rise") or name:find("whoosh") then
    return "FX"
  end

  return "Misc"
end

------------------------------------------------------------
-- FX-Präferenzen pro Kategorie
------------------------------------------------------------

-- Wir verwenden hier bewusst NUR Namen, die in REAPER als FX-Bezeichnung auftauchen.
-- TrackFX_AddByName() wird still scheitern, wenn ein Plugin nicht existiert.
-- Dadurch bleibt das Script robust auf verschiedenen Systemen.

local CATEGORY_FX_PREFERENCES = {

  Kick = {
    -- leichte Sculpting-Chain
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaComp (Cockos)" },
  },

  Snare = {
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaComp (Cockos)" },
  },

  HihatClosed = {
    { type = "vst", name = "ReaEQ (Cockos)" },
  },

  HihatOpen = {
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaComp (Cockos)" },
  },

  Tom = {
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaComp (Cockos)" },
  },

  Clap = {
    { type = "vst", name = "ReaEQ (Cockos)" },
  },

  Shaker = {
    { type = "vst", name = "ReaEQ (Cockos)" },
  },

  Perc = {
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaComp (Cockos)" },
  },

  Room = {
    { type = "vst", name = "ReaComp (Cockos)" },
    { type = "vst", name = "ReaVerbate (Cockos)" },
  },

  Overhead = {
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaComp (Cockos)" },
  },

  FX = {
    { type = "vst", name = "ReaEQ (Cockos)" },
    { type = "vst", name = "ReaDelay (Cockos)" },
    { type = "vst", name = "ReaVerbate (Cockos)" },
  },

  Misc = {
    { type = "vst", name = "ReaEQ (Cockos)" },
  },
}

------------------------------------------------------------
-- Intensitäts-Gewichtung
------------------------------------------------------------

local INTENSITY_SCALE = {
  subtle  = 0.4,
  medium  = 1.0,
  extreme = 1.8,
}

local function resolve_intensity(intensity)
  if not intensity or intensity == "" then return "medium", 1.0 end
  local key = tostring(intensity):lower()
  local scale = INTENSITY_SCALE[key] or 1.0
  return key, scale
end

------------------------------------------------------------
-- FX-Einfügen & leichte Preset-Defaults
------------------------------------------------------------

local function safe_add_fx(track, fx_name)
  if not track or not fx_name or fx_name == "" then return -1 end
  -- instantiate as "by name" on this track; recfx = false
  local idx = r.TrackFX_AddByName(track, fx_name, false, -1)
  return idx
end

local function apply_basic_tuning(track, fx_idx, category, intensity_scale)
  if not track or fx_idx < 0 then return end

  local rv, fx_name = r.TrackFX_GetFXName(track, fx_idx, "")
  fx_name = fx_name or ""

  -- kleine, heuristische Defaults:
  if fx_name:find("ReaComp") then
    -- Ratio
    r.TrackFX_SetParam(track, fx_idx, 1, math.min(1.0, 0.25 * intensity_scale))
    -- Attack (ms) ist param 2, normalized; wir lassen Default meistens
  elseif fx_name:find("ReaEQ") then
    -- nichts spezifisches, Preset bleibt default. Feintuning durch User.
  elseif fx_name:find("ReaVerbate") then
    -- für Room/FX eher kürzere Decay, niedriges Mix im "subtle"-Fall
    if category == "Room" or category == "FX" then
      -- Mix (wet) ist meist param 0 bei ReaVerbate
      local wet = 0.2 * intensity_scale
      if wet > 1.0 then wet = 1.0 end
      r.TrackFX_SetParam(track, fx_idx, 0, wet)
    end
  elseif fx_name:find("ReaDelay") then
    -- Für FX: subtile Delay-Werte
    if category == "FX" then
      -- Erstes Tap-Level etwas runter
      r.TrackFX_SetParam(track, fx_idx, 2, 0.3 * intensity_scale)
    end
  end
end

------------------------------------------------------------
-- Öffentliche Hauptfunktion
------------------------------------------------------------

function DF95_CategoryFX_ApplyToTrack(track, category, intensity)
  if not track then return end

  local _, name = r.GetTrackName(track, "")
  local auto_cat = DF95_CategoryFX_DetectCategoryFromTrackName(name)

  local cat = category or auto_cat or "Misc"
  local prefs = CATEGORY_FX_PREFERENCES[cat] or CATEGORY_FX_PREFERENCES["Misc"]
  if not prefs then return end

  local intensity_key, intensity_scale = resolve_intensity(intensity)

  r.Undo_BeginBlock()
  local added = 0

  for _, fx in ipairs(prefs) do
    local fx_name = fx.name
    local idx = safe_add_fx(track, fx_name)
    if idx >= 0 then
      added = added + 1
      apply_basic_tuning(track, idx, cat, intensity_scale)
    end
  end

  r.Undo_EndBlock(string.format("DF95 Category FX Apply (%s, %s) – %d FX", cat, intensity_key, added), -1)
end

------------------------------------------------------------
-- Falls dieses Script direkt als Action ausgeführt wird:
-- -> wende Kategorie-FX auf alle selektierten Tracks an.
------------------------------------------------------------

local function run_as_action_if_standalone()
  local _, _, sectionID, cmdID, _, _, _ = r.get_action_context()
  -- Wenn es als "Script" in REAPER geladen ist, ist cmdID > 0
  if cmdID == 0 then return end

  local num_sel = r.CountSelectedTracks(0)
  if num_sel == 0 then
    r.ShowMessageBox(
      "Keine Tracks ausgewählt.\nBitte wähle einen oder mehrere Drum-/FX-Tracks aus\nund starte das Script erneut.",
      "DF95 Category FX Engine",
      0
    )
    return
  end

  for i = 0, num_sel-1 do
    local tr = r.GetSelectedTrack(0, i)
    DF95_CategoryFX_ApplyToTrack(tr, nil, "medium")
  end
end

run_as_action_if_standalone()
