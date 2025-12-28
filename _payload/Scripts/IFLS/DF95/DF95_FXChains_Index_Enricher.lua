--[[
DF95 - FXChains Index Enricher (Lua/ReaScript)

Option 2: Index um Artist / Intensity / UCS / CPU / Style erweitern.

Dieses Script:
- liest Data/DF95/fxchains_index.json (vom DF95_FXChains_Index_Builder erzeugt)
- iteriert über alle fxchains-Entries
- errechnet zusätzliche Metadaten-Felder:
    * artist_id   (z.B. aus Artists-Unterordnern)
    * style       (grobe stilistische Kategorie)
    * intensity   (0.0 - 1.0, basierend auf Dateinamen/Keywords)
    * ucs_tags    (UCS-kompatible Tags wie WHOOSH, IMPACT, RISE, SWEEP)
    * cpu_cost    (0.0 - 1.0, günstige bis teure FXChains)
    * role_primary (item / bus / master, aus vorhandenen roles/Ordnern abgeleitet)
- schreibt den erweiterten Index wieder nach fxchains_index.json
  (vorher wird eine Backup-Datei fxchains_index_raw.json angelegt)

Design:
- Heuristiken sind bewusst einfach gehalten, können später verfeinert oder mit AI überschrieben werden.
- Ziel: AI & Workflow-Brains haben eine reichhaltigere, aber deterministische Datenbasis.

]]--

-- @description DF95 - Enrich FXChains Index (Artist / Intensity / UCS / CPU / Style)
-- @version 1.0
-- @changelog Initial version
-- @about Enriches fxchains_index.json with additional metadata fields for AI / workflow brains.

-------------------------------------------------------
-- Utility: Paths
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

local index_path    = join_path(data_df95, "fxchains_index.json")
local backup_path   = join_path(data_df95, "fxchains_index_raw.json")

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

local function write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then return false, err end
  f:write(content)
  f:close()
  return true
end

-------------------------------------------------------
-- Minimal JSON Decoder (kompatibel mit unserem Index/AIR-Format)
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
        -- Unicode: minimal, ignorieren & als ? einsetzen
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
-- Minimal JSON Encoder (kompatibel mit Index-Struktur)
-------------------------------------------------------

local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  str = str:gsub("\t", "\\t")
  return str
end

local function json_encode_value(v)
  local t = type(v)
  if t == "string" then
    return "\"" .. json_escape(v) .. "\""
  elseif t == "number" then
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    -- Array vs. Map
    local isArray = true
    local maxIndex = 0
    for k, _ in pairs(v) do
      if type(k) ~= "number" then
        isArray = false
        break
      else
        if k > maxIndex then maxIndex = k end
      end
    end

    local parts = {}
    if isArray then
      for i = 1, maxIndex do
        table.insert(parts, json_encode_value(v[i]))
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      for k, val in pairs(v) do
        table.insert(parts, "\"" .. json_escape(k) .. "\":" .. json_encode_value(val))
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  elseif t == "nil" then
    return "null"
  else
    return "\"" .. json_escape(tostring(v)) .. "\""
  end
end

local function json_encode(tbl)
  return json_encode_value(tbl)
end

-------------------------------------------------------
-- Heuristiken für Artist / Style / Intensity / UCS / CPU / Role
-------------------------------------------------------

local function detect_artist_id(entry)
  -- Versuch: Wenn category mit "Artists/XYZ" startet, nehmen wir "XYZ" als artist_id
  local cat = (entry.category or ""):gsub("\\","/")

  local artists_prefix = "artists/"
  local cat_lower = cat:lower()
  local s, e = cat_lower:find(artists_prefix, 1, true)
  if s == 1 or s == 0 then
    -- Category beginnt mit "Artists/"
    local rest = cat:sub(#artists_prefix + 1)
    local artist = rest:match("([^/]+)")
    return artist
  end

  -- Alternativ: Try parse path
  local path = (entry.path or ""):gsub("\\","/")
  local path_lower = path:lower()
  local s2, e2 = path_lower:find(artists_prefix, 1, true)
  if s2 then
    local rest = path:sub(e2+1)
    local artist = rest:match("([^/]+)")
    return artist
  end

  return nil
end

local function detect_style(entry)
  local cat = (entry.category or ""):lower()
  local name = (entry.filename or ""):lower()
  local path = (entry.path or ""):lower()
  local s = cat .. " " .. name .. " " .. path

  if s:find("idm") then
    return "IDM"
  elseif s:find("drum") or s:find("drums") or s:find("kit") then
    return "Drums"
  elseif s:find("sfx") or s:find("whoosh") or s:find("impact") or s:find("boom") then
    return "SFX"
  elseif s:find("dialog") or s:find("voice") or s:find("vox") then
    return "Dialog/Vox"
  elseif s:find("master") then
    return "Mastering"
  elseif s:find("bus") or s:find("stem") then
    return "Bus Processing"
  elseif s:find("ambience") or s:find("atmo") or s:find("pad") then
    return "Ambience"
  end

  return "Generic"
end

local function detect_intensity(entry)
  local s = ((entry.category or "") .. " " .. (entry.filename or "") .. " " .. (entry.path or "")):lower()

  local intensity = 0.5

  if s:find("light") or s:find("gentle") or s:find("soft") or s:find("subtle") then
    intensity = 0.3
  elseif s:find("medium") or s:find("normal") or s:find("std") or s:find("standard") then
    intensity = 0.5
  elseif s:find("hard") or s:find("heavy") or s:find("slam") or s:find("crush") or s:find("max") then
    intensity = 0.8
  end

  if intensity < 0.0 then intensity = 0.0 end
  if intensity > 1.0 then intensity = 1.0 end
  return intensity
end

local function detect_ucs_tags(entry)
  local tags = {}

  local s = ((entry.category or "") .. " " .. (entry.filename or "") .. " " .. (entry.path or "")):lower()

  local function add(tag)
    for _, t in ipairs(tags) do
      if t == tag then return end
    end
    table.insert(tags, tag)
  end

  if s:find("whoosh") or s:find("swoosh") then
    add("WHOOSH")
  end
  if s:find("impact") or s:find("hit") or s:find("slam") or s:find("boom") then
    add("IMPACT")
  end
  if s:find("rise") or s:find("riser") or s:find("build") then
    add("RISE")
  end
  if s:find("sweep") or s:find("sweeper") then
    add("SWEEP")
  end
  if s:find("texture") or s:find("grain") or s:find("layer") then
    add("TEXTURE")
  end
  if s:find("whoosh") and s:find("sweet") then
    add("SWEETENER")
  end
  if s:find("ambience") or s:find("room") or s:find("atmo") then
    add("AMBIENCE")
  end

  -- falls wir keine speziellen UCS-Tags gefunden haben, ggf. Basistag aus roles ableiten
  local roles = entry.roles or {}
  if #tags == 0 then
    for _, r in ipairs(roles) do
      local rl = tostring(r):lower()
      if rl == "master" then
        add("MASTER")
      elseif rl == "bus" then
        add("BUS")
      elseif rl == "item" then
        add("ITEM")
      end
    end
  end

  return tags
end

local function detect_cpu_cost(entry)
  local s = ((entry.category or "") .. " " .. (entry.filename or "") .. " " .. (entry.path or "")):lower()

  local cost = 0.4

  if s:find("linear") or s:find("linphase") then
    cost = cost + 0.3
  end
  if s:find("mb") or s:find("multiband") then
    cost = cost + 0.2
  end
  if s:find("convolution") or s:find("ir ") or s:find("impulse") then
    cost = cost + 0.3
  end
  if s:find("lookahead") then
    cost = cost + 0.15
  end

  if cost < 0.0 then cost = 0.0 end
  if cost > 1.0 then cost = 1.0 end
  return cost
end

local function detect_role_primary(entry)
  local roles = entry.roles or {}
  local cat = (entry.category or ""):lower()

  local primary = "item"

  for _, r in ipairs(roles) do
    local rl = tostring(r):lower()
    if rl == "master" then
      return "master"
    elseif rl == "bus" then
      primary = "bus"
    end
  end

  if cat:find("master") then
    return "master"
  elseif cat:find("bus") or cat:find("stem") then
    return "bus"
  end

  return primary
end

-------------------------------------------------------
-- Hauptlogik: Index laden, anreichern, speichern
-------------------------------------------------------

local function enrich_index()
  -- JSON laden
  local content, err = read_file(index_path)
  if not content then
    reaper.ShowMessageBox("Konnte fxchains_index.json nicht lesen:\n" .. tostring(index_path) .. "\nFehler: " .. tostring(err) .. "\nBitte zuerst 'DF95_FXChains_Index_Builder.lua' ausführen.", "DF95 FXChains Enricher", 0)
    return
  end

  local tbl = json_decode(content)
  if not tbl or type(tbl) ~= "table" then
    reaper.ShowMessageBox("Konnte fxchains_index.json nicht als JSON parsen:\n" .. tostring(index_path), "DF95 FXChains Enricher", 0)
    return
  end

  local list = tbl.fxchains
  if type(list) ~= "table" then
    reaper.ShowMessageBox("fxchains_index.json hat kein 'fxchains' Array.\nStruktur unerwartet.", "DF95 FXChains Enricher", 0)
    return
  end

  local changed = 0

  for _, entry in ipairs(list) do
    if type(entry) == "table" then
      entry.meta = entry.meta or {}
      entry.profile = entry.profile or {}

      -- Artist
      local artist_id = detect_artist_id(entry)
      if artist_id then
        entry.profile.artist_id = artist_id
      end

      -- Style
      local style = detect_style(entry)
      entry.profile.style = style

      -- Intensity
      local intensity = detect_intensity(entry)
      entry.profile.intensity = intensity

      -- UCS Tags
      local ucs = detect_ucs_tags(entry)
      entry.profile.ucs_tags = ucs

      -- CPU Cost
      local cpu = detect_cpu_cost(entry)
      entry.profile.cpu_cost = cpu

      -- Role primary
      local role_primary = detect_role_primary(entry)
      entry.profile.role_primary = role_primary

      changed = changed + 1
    end
  end

  -- Versions-Metadaten
  tbl.version_enriched = "1.0"
  tbl.enriched_at = os.date("!%Y-%m-%dT%H:%M:%SZ")

  -- Backup original
  write_file(backup_path, content)

  -- Neuen JSON schreiben
  local new_json = json_encode(tbl)
  local ok, werr = write_file(index_path, new_json)
  if not ok then
    reaper.ShowMessageBox("Fehler beim Schreiben des angereicherten Index:\n" .. tostring(werr), "DF95 FXChains Enricher", 0)
    return
  end

  reaper.ShowMessageBox("DF95 FXChains Index angereichert.\nEinträge: " .. tostring(changed) ..
                        "\n\nOriginal wurde gesichert als:\n" .. tostring(backup_path) ..
                        "\nAktuelle Datei:\n" .. tostring(index_path),
                        "DF95 FXChains Enricher", 0)
end

-------------------------------------------------------
-- Run with Undo
-------------------------------------------------------

reaper.Undo_BeginBlock()
enrich_index()
reaper.Undo_EndBlock("DF95: Enrich FXChains Index (Artist/Intensity/UCS/CPU/Style)", -1)
reaper.UpdateArrange()
