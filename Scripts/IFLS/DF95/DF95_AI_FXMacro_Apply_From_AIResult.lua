--[[
DF95 - AI FXMacro Apply From AIResult (Lua/ReaScript)

Option 7: AI-FX-Macros (Multiplex) auf bestehenden FXChains.

Idee:
- Die KI liefert nicht nur "welche FXChain?", sondern auch Macro-Werte wie "Punch", "Color", "Air", etc.
- Dieses Script liest eine AI-Result-JSON-Datei (z.B. Data/DF95/ai_fxmacros_result.json)
  und übersetzt die Macro-Werte in konkrete Parameteränderungen auf Tracks/FX.

Annahmen:
- Die FXChain ist bereits auf den entsprechenden Tracks geladen (z.B. durch FullAuto/Resolver).
- Die AI-Result-Datei enthält pro Ziel:
    * track_guid   (Zielspur)
    * fx_name      (Substringsuche im FX-Namen, z.B. "ReaComp", "Saturation", etc.)
    * macros       (Tabelle MacroName -> 0.0 ... 1.0)

Beispiel-JSON (Data/DF95/ai_fxmacros_result.json):

{
  "version": "1.0",
  "generated_at": "2025-12-01T12:34:56Z",
  "targets": [
    {
      "track_guid": "{ABC-123-...}",
      "fx_name": "ReaComp",
      "macros": {
        "Punch": 0.8,
        "Glue": 0.4
      }
    }
  ]
}

Dieses Script:
- sucht die Track(s) per GUID,
- sucht das gewünschte FX per Name-Match,
- kennt für einige FX Makro-Mappings (welche Parameter von "Punch", etc. beeinflusst werden),
- setzt die Parameter entsprechend.

Wenn kein Mapping für ein FX/Makro existiert, wird das Ziel einfach übersprungen (kein Fehler).
]]--

-- @description DF95 - AI FXMacro Apply From AIResult JSON
-- @version 1.0
-- @author DF95 / Reaper DAW Ultimate Assistant
-- @about Applies AI macro values to FX parameters on tracks based on a macro mapping.

local r = reaper

-------------------------------------------------------
-- KONFIGURATION
-------------------------------------------------------

-- AI-FXMacro-Result-Datei
local AI_FXMACROS_FILENAME = "ai_fxmacros_result.json"

-------------------------------------------------------
-- Utility: Paths & File IO
-------------------------------------------------------

local sep = package.config:sub(1, 1)

local function normalize_slashes(path)
  return path:gsub("[/\\]", sep)
end

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_resource_path()
  return normalize_slashes(r.GetResourcePath())
end

local function get_data_root()
  return join_path(get_resource_path(), "Data" .. sep .. "DF95")
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local content = f:read("*a")
  f:close()
  return content, nil
end

local function msgbox(msg)
  r.ShowMessageBox(tostring(msg), "DF95 AI FXMacro Apply", 0)
end

local function log(msg)
  r.ShowConsoleMsg("[DF95 FXMacro] " .. tostring(msg) .. "\n")
end

-------------------------------------------------------
-- Minimal JSON Decoder (für AI-Result)
-------------------------------------------------------

local function json_skip_ws(str, i)
  local l = #str
  while i <= l do
    local c = str:sub(i,i)
    if c ~= " " and c ~= "\n" and c ~= "\r" and c ~= "\t" then
      break
    end
    i = i + 1
  end
  return i
end

local function json_parse_string(str, i)
  i = i + 1 -- skip "
  local res = {}
  local l = #str
  while i <= l do
    local c = str:sub(i,i)
    if c == "\"" then
      return table.concat(res), i + 1
    elseif c == "\\" then
      local n = str:sub(i+1, i+1)
      if n == "\"" or n == "\\" or n == "/" then
        res[#res+1] = n; i = i + 2
      elseif n == "b" then res[#res+1] = "\b"; i = i + 2
      elseif n == "f" then res[#res+1] = "\f"; i = i + 2
      elseif n == "n" then res[#res+1] = "\n"; i = i + 2
      elseif n == "r" then res[#res+1] = "\r"; i = i + 2
      elseif n == "t" then res[#res+1] = "\t"; i = i + 2
      elseif n == "u" then
        -- Unicode -> einfach überspringen und '?' einsetzen
        local hex = str:sub(i+2, i+5)
        res[#res+1] = "?"
        i = i + 6
      else
        res[#res+1] = n; i = i + 2
      end
    else
      res[#res+1] = c
      i = i + 1
    end
  end
  return table.concat(res), i
end

local function json_parse_number(str, i)
  local l = #str
  local start_i = i
  while i <= l do
    local c = str:sub(i,i)
    if not (c:match("[%d%+%-%e%E%.]")) then
      break
    end
    i = i + 1
  end
  local num_str = str:sub(start_i, i-1)
  local num = tonumber(num_str)
  return num, i
end

local function json_parse_literal(str, i, literal, value)
  if str:sub(i, i + #literal - 1) == literal then
    return value, i + #literal
  end
  return nil, i
end

local json_parse_value

local function json_parse_array(str, i)
  i = i + 1 -- skip [
  local arr = {}
  i = json_skip_ws(str, i)
  if str:sub(i,i) == "]" then
    return arr, i + 1
  end
  while true do
    local v
    v, i = json_parse_value(str, i)
    arr[#arr+1] = v
    i = json_skip_ws(str, i)
    local c = str:sub(i,i)
    if c == "]" then
      return arr, i + 1
    elseif c == "," then
      i = i + 1
      i = json_skip_ws(str, i)
    else
      return arr, i
    end
  end
end

local function json_parse_object(str, i)
  i = i + 1 -- skip {
  local obj = {}
  i = json_skip_ws(str, i)
  if str:sub(i,i) == "}" then
    return obj, i + 1
  end
  while true do
    i = json_skip_ws(str, i)
    if str:sub(i,i) ~= "\"" then
      return obj, i
    end
    local key
    key, i = json_parse_string(str, i)
    i = json_skip_ws(str, i)
    if str:sub(i,i) ~= ":" then
      return obj, i
    end
    i = i + 1
    i = json_skip_ws(str, i)
    local v
    v, i = json_parse_value(str, i)
    obj[key] = v
    i = json_skip_ws(str, i)
    local c = str:sub(i,i)
    if c == "}" then
      return obj, i + 1
    elseif c == "," then
      i = i + 1
      i = json_skip_ws(str, i)
    else
      return obj, i
    end
  end
end

json_parse_value = function(str, i)
  i = json_skip_ws(str, i)
  local c = str:sub(i,i)
  if c == "{" then
    return json_parse_object(str, i)
  elseif c == "[" then
    return json_parse_array(str, i)
  elseif c == "\"" then
    return json_parse_string(str, i)
  elseif c == "-" or c:match("%d") then
    return json_parse_number(str, i)
  else
    local v, ni = json_parse_literal(str, i, "true", true); if v ~= nil then return v, ni end
    v, ni = json_parse_literal(str, i, "false", false); if v ~= nil then return v, ni end
    v, ni = json_parse_literal(str, i, "null", nil); if i ~= ni then return v, ni end
  end
  return nil, i
end

local function json_decode(str)
  if type(str) ~= "string" then return nil end
  local ok, res = pcall(function()
    local v, _ = json_parse_value(str, 1)
    return v
  end)
  if ok then return res end
  return nil
end

-------------------------------------------------------
-- FX Macro Mapping
-------------------------------------------------------

-- FX_MACRO_MAP definiert, wie abstrakte Macros (0.0 - 1.0) auf reale FX-Parameter gemappt werden.
-- Beispiel für ein Mapping:
--
-- FX_MACRO_MAP["ReaComp"] = {
--   Punch = {
--     { param = 1, min = 1.5, max = 6.0 },    -- Ratio
--     { param = 2, min = 0.0005, max = 0.02 } -- Attack
--   },
--   Glue = {
--     { param = 3, min = -24.0, max = -3.0 }, -- Threshold (dB)
--   }
-- }
--
-- Die Param-Indizes sind 0-basiert (wie in TrackFX_GetParam/SetParam).

local FX_MACRO_MAP = {

  ["ReaComp"] = {
    Punch = {
      { param = 1, min = 1.5,  max = 6.0  },   -- Ratio
      { param = 2, min = 0.0005, max = 0.02 }, -- Attack
    },
    Glue = {
      { param = 3, min = -30.0, max = -6.0 },  -- Threshold
      { param = 4, min = 0.1,   max = 0.5  },  -- Release
    },
  },

  -- Beispiel: JSFX Saturator (Name enthält "Saturation" oder ähnliches)
  ["Saturation"] = {
    Color = {
      { param = 0, min = 0.0, max = 1.0 },     -- Drive / Color
    },
  },

}

local function lerp(a, b, t)
  return a + (b - a) * t
end

-------------------------------------------------------
-- Track & FX Helpers
-------------------------------------------------------

local function find_track_by_guid(guid)
  local proj = 0
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, tr_guid = r.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
    if tr_guid == guid then
      return tr
    end
  end
  return nil
end

local function find_fx_on_track(tr, fx_name_substr)
  local fx_count = r.TrackFX_GetCount(tr)
  local name_lower_target = (fx_name_substr or ""):lower()
  for fx = 0, fx_count-1 do
    local _, name = r.TrackFX_GetFXName(tr, fx, "")
    local name_lower = (name or ""):lower()
    if name_lower:find(name_lower_target, 1, true) then
      return fx, name
    end
  end
  return nil, nil
end

local function apply_macros_to_fx(tr, fx_idx, fx_name, macros)
  if not macros or type(macros) ~= "table" then return end

  -- Passendes Mapping suchen: exakter Key oder Substring-Key
  local map = nil
  -- 1) exakter Match
  map = FX_MACRO_MAP[fx_name]
  if not map then
    -- 2) heuristisch: erster Key, der im FX-Namen vorkommt
    local fx_lower = fx_name:lower()
    for key, m in pairs(FX_MACRO_MAP) do
      if fx_lower:find(key:lower(), 1, true) then
        map = m
        break
      end
    end
  end

  if not map then
    log("Kein FX_MACRO_MAP für FX: " .. tostring(fx_name))
    return
  end

  for macro_name, value in pairs(macros) do
    local macro_def = map[macro_name]
    if macro_def and type(macro_def) == "table" then
      local t = tonumber(value) or 0.0
      if t < 0.0 then t = 0.0 end
      if t > 1.0 then t = 1.0 end

      for _, p in ipairs(macro_def) do
        local param_idx = p.param
        local minv = p.min
        local maxv = p.max
        if param_idx ~= nil and minv ~= nil and maxv ~= nil then
          local target_val = lerp(minv, maxv, t)
          r.TrackFX_SetParam(tr, fx_idx, param_idx, target_val)
          log(string.format("FXMacro %s: FX=%s param=%d -> %.4f (t=%.2f)", tostring(macro_name), tostring(fx_name), param_idx, target_val, t))
        end
      end
    else
      log("Kein Macro-Mapping für '" .. tostring(macro_name) .. "' auf FX '" .. tostring(fx_name) .. "'.")
    end
  end
end

-------------------------------------------------------
-- Hauptlogik
-------------------------------------------------------

local function main()
  local data_root = get_data_root()
  local in_path = join_path(data_root, AI_FXMACROS_FILENAME)

  local content, err = read_file(in_path)
  if not content then
    msgbox("Konnte AI-FXMacro-Result-Datei nicht lesen:\n" .. tostring(in_path) .. "\nFehler: " .. tostring(err) .. "\n\nBitte stelle sicher, dass dein AI-Worker '" .. AI_FXMACROS_FILENAME .. "' in Data/DF95 erzeugt.")
    return
  end

  local doc = json_decode(content)
  if not doc or type(doc) ~= "table" then
    msgbox("Konnte AI-FXMacro-JSON nicht parsen:\n" .. tostring(in_path))
    return
  end

  local targets = doc.targets
  if not targets or type(targets) ~= "table" or #targets == 0 then
    msgbox("AI-FXMacro-JSON enthält keine 'targets'.\nDatei: " .. tostring(in_path))
    return
  end

  local applied = 0
  for _, t in ipairs(targets) do
    if type(t) == "table" then
      local guid = t.track_guid
      local fx_name = t.fx_name or ""
      local macros = t.macros or {}

      if not guid or guid == "" then
        log("Target ohne track_guid – übersprungen.")
      else
        local tr = find_track_by_guid(guid)
        if not tr then
          log("Keine Spur mit GUID " .. tostring(guid) .. " gefunden – Target übersprungen.")
        else
          local fx_idx, fx_real_name = find_fx_on_track(tr, fx_name)
          if not fx_idx then
            log("Kein FX passend zu '" .. tostring(fx_name) .. "' auf Track gefunden – Target übersprungen.")
          else
            apply_macros_to_fx(tr, fx_idx, fx_real_name or fx_name, macros)
            applied = applied + 1
          end
        end
      end
    end
  end

  msgbox("AI FXMacros angewendet.\nTargets gesamt: " .. tostring(#targets) .. "\nErfolgreich gemappte FX: " .. tostring(applied))
end

r.Undo_BeginBlock()
main()
r.Undo_EndBlock("DF95: AI FXMacro Apply From AIResult", -1)
