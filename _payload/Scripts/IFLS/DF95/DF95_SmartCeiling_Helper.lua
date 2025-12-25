-- @description SmartCeiling Helper (robust fallback)
-- @version 1.2
-- @author DF95
-- Liest Data/DF95/SmartCeiling.json, liefert Ceiling (dBTP) je Kategorie.
-- Fallback: sinnvolle Default-Werte für Master/FXBus/Coloring.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function read_text(p)
  local f = io.open(p,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

local DEFAULT = -0.1

local HARDCODE = {
  Default  = -0.1,
  Master   = -1.0,
  FXBus    = -0.5,
  Coloring = -0.3,
  Artists  = -0.5,
  Neutral  = -0.1,
  DF95     = -0.1,
}

local function parse_map(json)
  if not json or json == "" then return {} end

  if r and r.JSON_Decode then
    local ok, obj = pcall(r.JSON_Decode, json)
    if ok and type(obj) == "table" then
      local map = {}

      for k,v in pairs(obj) do
        if type(v) == "number" then
          map[k] = v
        end
      end

      if type(obj.map) == "table" then
        for k,v in pairs(obj.map) do
          if type(v) == "number" then
            map[k] = v
          end
        end
      end

      return map
    end
  end

  local map = {}
  for key, val in json:gmatch('"(.-)"%s*:%s*([%-%d%.]+)') do
    local num = tonumber(val)
    if num then
      map[key] = num
    end
  end
  return map
end

local function get_ceiling(category)
  local p = res..sep.."Data"..sep.."DF95"..sep.."SmartCeiling.json"
  local t = read_text(p)
  local map = t and parse_map(t) or {}
  local cat = category or "Default"

  if map[cat] then return map[cat] end
  if map["Default"] then return map["Default"] end
  if HARDCODE[cat] then return HARDCODE[cat] end
  return DEFAULT
end

return { get = get_ceiling }
