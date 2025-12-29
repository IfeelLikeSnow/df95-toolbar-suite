-- @description DF95 Safety AIWorker Helper (Stufe 3)
-- @version 1.0
-- @author DF95
-- @about
--   Prüft, ob der ZoomF6-AIWorker im System vorhanden ist und protokolliert den Status.
--   Diese Version startet noch keine Scripts automatisch, gibt aber sinnvolle Hinweise.

local r = reaper

local SafetyAI = {}

local function dbg(msg)
  if _G.DF95_DEBUG_SAFETY then
    r.ShowConsoleMsg("[DF95 AI Safety] " .. tostring(msg) .. "\n")
  end
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

function SafetyAI.check_zoom_aiworker_present()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local script_path = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_V160_SampleDB_AIWorker_ZoomF6.lua"

  if file_exists(script_path) then
    dbg("AIWorker ZoomF6 gefunden.")
    return true
  else
    dbg("AIWorker ZoomF6 NICHT gefunden – bitte Script DF95_V160_SampleDB_AIWorker_ZoomF6.lua installieren.")
    return false
  end
end

return SafetyAI
