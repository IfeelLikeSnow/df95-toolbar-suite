-- @description Pipeline Core
-- @version 1.2
-- @author DF95
-- @about
--   Zentrale Ablauf-Engine für DF95:
--     - Definiert "Stages" (z.B. RECORDING_QA, SOURCE_NORMALIZATION_MOBILE,
--       SAMPLER_BUILD, EXPORT_SLICES, ...)
--     - Ruft je nach Stage die zuständigen Module (Sampler_Core, Export_Core, QA, FX usw.)
--
--   Aktuell implementiert:
--     - RECORDING_QA
--         -> führt DF95_Recording_QA_Metadata.lua aus (Analyse von SR/Bit/Peak)
--     - SOURCE_NORMALIZATION_MOBILE
--         -> lädt die FieldRecorder-FXBus-FX-Ketten auf selektierte Tracks
--            (Clean/Atmos) für dein Samsung S24 Ultra + Field Recorder App
--     - SAMPLER_BUILD
--         -> DF95_Sampler_Core.pipeline_sampler_build(...)
--     - EXPORT_SLICES
--         -> DF95_Export_Core.run(...)

local r = reaper
local Pipeline = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_sampler_core()
  local path = df95_root() .. "DF95_Sampler_Core.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("DF95_Pipeline_Core: Fehler beim Laden von DF95_Sampler_Core.lua:\n"
                     ..tostring(mod), "DF95 Pipeline Core", 0)
    return nil
  end
  return mod
end

local function load_export_core()
  local path = df95_root() .. "DF95_Export_Core.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("DF95_Pipeline_Core: Fehler beim Laden von DF95_Export_Core.lua:\n"
                     ..tostring(mod), "DF95 Pipeline Core", 0)
    return nil
  end
  return mod
end

------------------------------------------------------------
-- RECORDING_QA Stage
-- Führt DF95_Recording_QA_Metadata.lua aus (zeigt Infos in Console)
------------------------------------------------------------

local function run_recording_qa(stage_options)
  local path = df95_root() .. "DF95_Recording_QA_Metadata.lua"
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("DF95_Pipeline_Core: Fehler beim Recording-QA:\n"
                     ..tostring(err), "DF95 Pipeline Core", 0)
  end
end

------------------------------------------------------------
-- SOURCE_NORMALIZATION_MOBILE Stage
-- Lädt deine FieldRecorder-FXBus-Ketten auf selektierte Tracks
--   mode = "clean" (Default)  -> DF95_FXBus_FieldRecorder_S24U_Clean_01
--        = "atmos"            -> DF95_FXBus_FieldRecorder_S24U_Atmos_01
------------------------------------------------------------

local function run_source_normalization_mobile(stage_options)
  local opt = (stage_options and stage_options.mobile) or {}
  local mode = (opt.mode or "clean"):lower()

  local chain_name
  if mode == "atmos" then
    chain_name = "FXCHAIN:DF95/DF95_FXBus_FieldRecorder_S24U_Atmos_01"
  else
    chain_name = "FXCHAIN:DF95/DF95_FXBus_FieldRecorder_S24U_Clean_01"
  end

  local proj = 0
  local sel_cnt = reaper.CountSelectedTracks(proj)
  if sel_cnt == 0 then
    r.ShowMessageBox(
      "DF95 SOURCE_NORMALIZATION_MOBILE:\n" ..
      "Keine Tracks ausgewählt.\n\n" ..
      "Bitte wähle die FieldRecorder-Spur(en) oder deinen Mobile-FX-Bus aus,\n" ..
      "bevor du diese Stage ausführst.",
      "DF95 Pipeline Core", 0
    )
    return
  end

  for i = 0, sel_cnt-1 do
    local tr = reaper.GetSelectedTrack(proj, i)
    reaper.TrackFX_AddByName(tr, chain_name, false, 1)
  end
end

------------------------------------------------------------
-- SAMPLER_BUILD Stage
------------------------------------------------------------

local function run_sampler_build(stage_options)
  local sampler = load_sampler_core()
  if sampler and sampler.pipeline_sampler_build then
    sampler.pipeline_sampler_build(stage_options.sampler or {})
  end
end

------------------------------------------------------------
-- EXPORT_SLICES Stage
------------------------------------------------------------

local function run_export_slices(stage_options)
  local export = load_export_core()
  if not export or not export.run then return end
  export.run(stage_options.export or {
    mode      = "SELECTED_SLICES_SUM", -- Multi-Mic-Slices als Summe
    target    = "ORIGINAL",            -- oder z.B. "SPLICE_44_24"
    category  = "Slices_Master",
    subtype   = "Pipeline",
    dest_root = nil,                   -- DF95_EXPORT im Projektordner
  })
end

------------------------------------------------------------
-- Dispatcher
------------------------------------------------------------

function Pipeline.run_stage(stage_name, stage_options)
  stage_options = stage_options or {}

  if stage_name == "RECORDING_QA" then
    run_recording_qa(stage_options)

  elseif stage_name == "SOURCE_NORMALIZATION_MOBILE" then
    run_source_normalization_mobile(stage_options)

  elseif stage_name == "SAMPLER_BUILD" then
    run_sampler_build(stage_options)

  elseif stage_name == "EXPORT_SLICES" then
    run_export_slices(stage_options)

  else
    r.ShowConsoleMsg(
      string.format("DF95_Pipeline_Core: Unbekannte Stage '%s' (noch nicht implementiert)\n",
      tostring(stage_name))
    )
  end
end

-- Führt mehrere Stages der Reihe nach aus.
function Pipeline.run(stages, options)
  if type(stages) ~= "table" then return end
  options = options or {}
  for _, st in ipairs(stages) do
    Pipeline.run_stage(st, options)
  end
end

return Pipeline
