\
-- @description DF95_SampleDB_IndexV2_Loader
-- @version 1.0
-- @author DF95
-- @about
--   Laedt den von DF95 AIWorker erzeugten SampleDB_Index_V2.json
--   und stellt ihn als Lua-Tabelle bereit.
--
--   Rueckgabewert:
--     return {
--       index = { ... }, -- Liste von Sample-Eintraegen
--       path  = "<voller Pfad zur JSON-Datei>"
--     }

local r = reaper

local M = {}

local function get_sep()
  return package.config:sub(1,1)
end

local function normalize(path)
  local sep = get_sep()
  if sep == "\\" then
    return path:gsub("/", "\\\\")
  else
    return path:gsub("\\", "/")
  end
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local txt = f:read("*a")
  f:close()
  return txt
end

local function load_json_helper()
  local sep = get_sep()
  local base = r.GetResourcePath()
  local candidates = {
    base .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Json.lua",
    base .. sep .. "Scripts" .. sep .. "DF95_Json.lua",
  }
  for _, p in ipairs(candidates) do
    p = normalize(p)
    local f = io.open(p, "r")
    if f then
      f:close()
      local ok, mod = pcall(dofile, p)
      if ok and mod and type(mod.decode) == "function" then
        return mod
      elseif ok and _G.json and type(_G.json.decode) == "function" then
        return _G.json
      end
    end
  end
  return nil
end

local function load_index_v2()
  local sep = get_sep()
  local base = r.GetResourcePath()
  local path = base .. sep .. "Data" .. sep .. "DF95" .. sep .. "SampleDB_Index_V2.json"
  path = normalize(path)

  local txt, err = read_file(path)
  if not txt then
    return nil, "SampleDB_Index_V2.json konnte nicht gelesen werden: " .. tostring(err or "unbekannt")
  end

  local json_helper = load_json_helper()
  if not json_helper then
    return nil, "Kein JSON-Helper (DF95_Json.lua) gefunden."
  end

  local ok, data = pcall(json_helper.decode, txt)
  if not ok then
    return nil, "JSON-Decode-Fehler: " .. tostring(data)
  end

  if type(data) ~= "table" then
    return nil, "SampleDB_Index_V2.json enthaelt keine Tabellendaten."
  end

  return {
    index = data,
    path  = path
  }
end

local ok, res = load_index_v2()
if ok and res then
  M = res
else
  M = { index = {}, path = "" }
end

return M
