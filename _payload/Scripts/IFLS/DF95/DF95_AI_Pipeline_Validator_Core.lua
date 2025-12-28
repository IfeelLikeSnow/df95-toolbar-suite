\
-- @description DF95_AI_Pipeline_Validator_Core
-- @version 1.0
-- @author DF95
-- @about
--   Hilfsmodul fuer DF95_PostInstall_Validator / DF95_Validator_GUI:
--   Prueft Kernbestandteile der AI-Pipeline (Python, HybridAI, SampleDB Index V2).

local r = reaper

local M = {}

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function join(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function normalize(path)
  if sep == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function get_data_dir()
  return normalize(join(join(res, "Data"), "DF95"))
end

function M.check_ai_pipeline()
  local result = {
    python = { status = "missing", detail = "" },
    hybrid_slices = { status = "missing", detail = "" },
    index_v2 = { status = "missing", detail = "" },
    ingest_py = { status = "missing", detail = "" },
  }

  -- Python / AIWorker
  local ok, py_path = r.GetProjExtState(0, "DF95_AIWorker", "python_exe")
  py_path = (ok ~= 0) and py_path or ""
  if py_path ~= "" then
    result.python.status = "ok"
    result.python.detail = py_path
  else
    result.python.status = "missing"
    result.python.detail = "ProjExtState DF95_AIWorker/python_exe ist leer."
  end

  -- Hybrid Slices
  local dd = get_data_dir()
  local hybrid = normalize(join(dd, "SampleDB_HybridSlices.jsonl"))
  if exists(hybrid) then
    result.hybrid_slices.status = "ok"
    result.hybrid_slices.detail = hybrid
  else
    result.hybrid_slices.status = "warn"
    result.hybrid_slices.detail = "Noch keine HybridAI-Slices exportiert."
  end

  -- SampleDB Index V2
  local indexv2 = normalize(join(dd, "SampleDB_Index_V2.json"))
  if exists(indexv2) then
    result.index_v2.status = "ok"
    result.index_v2.detail = indexv2
  else
    result.index_v2.status = "warn"
    result.index_v2.detail = "Index V2 (SampleDB_Index_V2.json) fehlt. AIWorker-Ingest ausfuehren."
  end

  -- AIWorker ingest.py
  local ingest = normalize(join(join(join(res, "Support"), "DF95_AIWorker"), "df95_aiworker_ingest.py"))
  if exists(ingest) then
    result.ingest_py.status = "ok"
    result.ingest_py.detail = ingest
  else
    result.ingest_py.status = "error"
    result.ingest_py.detail = "Python-Ingest-Script nicht gefunden."
  end

  return result
end

return M
