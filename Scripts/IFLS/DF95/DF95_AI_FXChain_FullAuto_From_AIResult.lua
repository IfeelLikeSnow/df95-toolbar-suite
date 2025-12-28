--[[
DF95 - AI FXChain Full Auto Apply From AI Result (Lua/ReaScript)

Option 3: Vollautomatischer AI-FXChain-Apply-Modus.

Dieses Script ist für "Headless" / Worker / One-Click gedacht:

- liest AI-Result-JSON (z.B. Data/DF95/ai_fxchains_result.json)
- liest den DF95 FXChains Index (fxchains_index.json, idealerweise vorher mit Enricher angereichert)
- resolved fxchain_id -> rfxchain-Pfad
- schreibt den Pfad in eine ExtState (DF95 / ApplyFXChain_Path)
- ruft automatisch deinen bestehenden "DF95_AI_ApplyFXChain_FromExtState"-Chunk-Loader auf,
  der die FXChain auf die selektierten Tracks anwendet.

So entsteht eine End-to-End Pipeline:
AI → JSON → FullAuto Script → ApplyFXChain_FromExtState → Reaper-Spuren.

Dieses Script verzichtet weitgehend auf Popups und meldet nur Fehler.
]]--

-- @description DF95 - AI FXChain Full Auto Apply From AIResult JSON
-- @version 1.0
-- @changelog Initial version
-- @about Fully automatic AI FXChain resolve + apply for DF95.

-------------------------------------------------------
-- KONFIGURATION
-------------------------------------------------------

-- Name der AI-Result-Datei relativ zu REAPER/Data/DF95
local AI_RESULT_FILENAME  = "ai_fxchains_result.json"

-- Name der Index-Datei (vom DF95_FXChains_Index_Builder erzeugt + optional Enricher)
local INDEX_FILENAME      = "fxchains_index.json"

-- ExtState Section/Key, kompatibel mit DF95_AI_ApplyFXChain_FromExtState
local EXT_SECTION         = "DF95"
local EXT_KEY_PATH        = "ApplyFXChain_Path"

-- Command-ID deiner "DF95_AI_ApplyFXChain_FromExtState"-Action
-- WICHTIG:
-- 1. In Actions-Liste: DF95_AI_ApplyFXChain_FromExtState.lua finden
-- 2. Rechtsklick → "Copy selected action command ID"
-- 3. Hier einfügen, z.B. "_RS1234567890abcdef"
local APPLY_ACTION_COMMAND_ID = "" -- <- HIER DEINE COMMAND-ID EINTRAGEN

-------------------------------------------------------
-- Utility: Pfade
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

local resource_path = normalize_slashes(reaper.GetResourcePath())
local data_df95     = join_path(join_path(resource_path, "Data"), "DF95")

local ai_result_path = join_path(data_df95, AI_RESULT_FILENAME)
local index_path     = join_path(data_df95, INDEX_FILENAME)

-------------------------------------------------------
-- Utility: File IO
-------------------------------------------------------

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local content = f:read("*a")
  f:close()
  return content, nil
end

-------------------------------------------------------
-- Minimal JSON Decoder
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
  i = i + 1 -- skip opening "
  local res = {}
  local l = #str
  while i <= l do
    local c = str:sub(i,i)
    if c == "\"" then
      return table.concat(res), i + 1
    elseif c == "\\" then
      local n = str:sub(i+1, i+1)
      if n == "\"" or n == "\\" or n == "/" then
        table.insert(res, n); i = i + 2
      elseif n == "b" then table.insert(res, "\b"); i = i + 2
      elseif n == "f" then table.insert(res, "\f"); i = i + 2
      elseif n == "n" then table.insert(res, "\n"); i = i + 2
      elseif n == "r" then table.insert(res, "\r"); i = i + 2
      elseif n == "t" then table.insert(res, "\t"); i = i + 2
      elseif n == "u" then
        -- Unicode minimal, wir ersetzen durch '?'
        local hex = str:sub(i+2, i+5)
        table.insert(res, "?"); i = i + 6
      else
        table.insert(res, n); i = i + 2
      end
    else
      table.insert(res, c); i = i + 1
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
    local val
    val, i = json_parse_value(str, i)
    table.insert(arr, val)
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
    local val
    val, i = json_parse_value(str, i)
    obj[key] = val
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
-- Index-Helfer
-------------------------------------------------------

local function build_fxchain_lookup(index_tbl)
  local lookup = {}
  if type(index_tbl) ~= "table" then return lookup end
  local list = index_tbl.fxchains
  if type(list) ~= "table" then return lookup end

  for _, entry in ipairs(list) do
    if type(entry) == "table" and entry.id then
      lookup[entry.id] = entry
    end
  end
  return lookup
end

local function select_best_recommendation(ai_tbl)
  if type(ai_tbl) ~= "table" then return nil end

  local recs = ai_tbl.recommendations
  if type(recs) ~= "table" or #recs == 0 then
    return nil
  end

  local best = recs[1]
  local best_conf = tonumber(best.confidence or 0) or 0

  for i = 2, #recs do
    local r = recs[i]
    local c = tonumber(r.confidence or 0) or 0
    if c > best_conf then
      best = r
      best_conf = c
    end
  end

  return best
end

-------------------------------------------------------
-- Hauptlogik
-------------------------------------------------------

local function log(msg)
  reaper.ShowConsoleMsg("[DF95 FullAuto AI FXChain] " .. tostring(msg) .. "\n")
end

local function main()
  -- 0) Basic Checks
  if APPLY_ACTION_COMMAND_ID == nil or APPLY_ACTION_COMMAND_ID == "" then
    reaper.ShowMessageBox("APPLY_ACTION_COMMAND_ID ist nicht gesetzt.\nBitte in DF95_AI_FXChain_FullAuto_From_AIResult.lua konfigurieren.", "DF95 FullAuto AI FXChain", 0)
    return
  end

  -- 1) Index lesen
  local index_content, ierr = read_file(index_path)
  if not index_content then
    reaper.ShowMessageBox("Konnte FXChains Index nicht lesen:\n" .. tostring(index_path) .. "\nFehler: " .. tostring(ierr) .. "\nBitte zuerst den Index-Builder ausführen.", "DF95 FullAuto AI FXChain", 0)
    return
  end

  local index_tbl = json_decode(index_content)
  if not index_tbl or type(index_tbl) ~= "table" then
    reaper.ShowMessageBox("FXChains Index konnte nicht als JSON geparst werden:\n" .. tostring(index_path), "DF95 FullAuto AI FXChain", 0)
    return
  end

  local lookup = build_fxchain_lookup(index_tbl)

  -- 2) AI-Result lesen
  local ai_content, aerr = read_file(ai_result_path)
  if not ai_content then
    reaper.ShowMessageBox("Konnte AI-Result-JSON nicht lesen:\n" .. tostring(ai_result_path) .. "\nFehler: " .. tostring(aerr), "DF95 FullAuto AI FXChain", 0)
    return
  end

  local ai_tbl = json_decode(ai_content)
  if not ai_tbl or type(ai_tbl) ~= "table" then
    reaper.ShowMessageBox("AI-Result-JSON konnte nicht geparst werden:\n" .. tostring(ai_result_path), "DF95 FullAuto AI FXChain", 0)
    return
  end

  -- 3) Beste Recommendation
  local rec = select_best_recommendation(ai_tbl)
  if not rec then
    reaper.ShowMessageBox("AI-Result enthält keine gültige 'recommendations'-Liste.", "DF95 FullAuto AI FXChain", 0)
    return
  end

  local fx_id = rec.fxchain_id or rec.id
  if not fx_id then
    reaper.ShowMessageBox("AI-Empfehlung enthält kein Feld 'fxchain_id'.", "DF95 FullAuto AI FXChain", 0)
    return
  end

  local fx_entry = lookup[fx_id]
  if not fx_entry then
    reaper.ShowMessageBox("FXChain-ID aus AI-Result nicht im Index gefunden:\n" .. tostring(fx_id), "DF95 FullAuto AI FXChain", 0)
    return
  end

  local rel_path = fx_entry.path or fx_entry.filename
  if not rel_path then
    reaper.ShowMessageBox("FXChain-Eintrag im Index hat keinen Pfad:\n" .. tostring(fx_id), "DF95 FullAuto AI FXChain", 0)
    return
  end

  local abs_path = normalize_slashes(resource_path .. "/" .. rel_path:gsub("[/\\]", sep))

  -- 4) ExtState setzen
  reaper.SetExtState(EXT_SECTION, EXT_KEY_PATH, abs_path, true)
  log("Set ExtState " .. EXT_SECTION .. " / " .. EXT_KEY_PATH .. " = " .. abs_path)

  -- 5) Apply-Action ausführen
  local cmd = reaper.NamedCommandLookup(APPLY_ACTION_COMMAND_ID)
  if cmd == 0 then
    reaper.ShowMessageBox("APPLY_ACTION_COMMAND_ID konnte nicht aufgelöst werden:\n" .. tostring(APPLY_ACTION_COMMAND_ID) .. "\nBitte Command-ID in der Konfiguration prüfen.", "DF95 FullAuto AI FXChain", 0)
    return
  end

  log("Running Apply action: " .. tostring(APPLY_ACTION_COMMAND_ID) .. " (cmd=" .. tostring(cmd) .. ")")
  reaper.Main_OnCommand(cmd, 0)

  -- 6) Fertig (kein Popup, nur Log)
  log("FullAuto AI FXChain angewendet für fxchain_id=" .. tostring(fx_id))
end

-------------------------------------------------------
-- Run with Undo
-------------------------------------------------------

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("DF95: FullAuto AI FXChain Apply From AIResult", -1)
reaper.UpdateArrange()
