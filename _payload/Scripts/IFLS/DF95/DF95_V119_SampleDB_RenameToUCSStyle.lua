-- @description DF95_V119 SampleDB – Rename to UCS-style Filenames
-- @version 1.0
-- @author DF95
-- @about
--   Nimmt die DF95 SampleDB (DF95_SampleDB_ZoomF6.json) und benennt die
--   darin enthaltenen WAV-Dateien nach einem UCS-inspirierten Schema um:
--
--     CatID_FXName_CreatorID_SourceID.wav
--
--   WICHTIGER HINWEIS:
--   * Die verwendeten CatIDs sind DF95-interne Platzhalter (z.B. DRMKick, DRMSnare)
--     und NICHT die offiziellen UCS CatIDs.
--   * Sie sind so gewählt, dass du sie später sehr leicht durch echte UCS-CatIDs
--     ersetzen kannst (z.B. via Suchen/Ersetzen oder externen UCS-Tools).
--   * Dieses Script soll dir eine konsistente Struktur liefern, ohne die UCS-Spezifikation
--     zu verletzen oder vorzutäuschen, dass dies „offiziell“ ist.
--
--   Verwendung:
--   * Vorher: DF95_V119_SampleDB_ScanFolder_ZoomF6.lua ausführen.
--   * Dann dieses Script starten.
--   * Es wird nach Bestätigung die Dateien physisch umbenennen.
--   * Die JSON-DB wird aktualisiert.

local r = reaper
local sep = package.config:sub(1,1)

local function msg(s)
  r.ShowConsoleMsg(tostring(s).."\n")
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

------------------------------------------------------------
-- Minimal JSON decoder (für unser DB-Format)
------------------------------------------------------------

local function json_decode(str)
  -- Sehr einfache Implementierung – wir erwarten ein Array von Objekten
  -- und vertrauen auf korrektes JSON aus unserem eigenen Encoder.
  local ok, res = pcall(function() return load("return " .. str, "json", "t", {})() end)
  if ok then return res end
  return nil
end

------------------------------------------------------------
-- Helper
------------------------------------------------------------

local UCS_CATID = {
  KICK    = "DRMKick",
  SNARE   = "DRMSnre",
  HAT     = "DRMHat",
  PERC    = "DRMPerc",
  FX      = "FXMisc",
  DRONE   = "TXTRDrne",
  TEXTURE = "TXTRGen",
  NOISE   = "NOISE",
  UNKNOWN = "MISC",
}

local function sanitize_fxname(src_name)
  src_name = src_name or ""
  src_name = src_name:gsub("[_%s]+", " ")
  src_name = src_name:gsub("[^%w%s%-]", "")
  src_name = src_name:gsub("^%s+",""):gsub("%s+$","")
  if #src_name > 25 then
    src_name = src_name:sub(1,25)
  end
  if src_name == "" then src_name = "OneShot" end
  return src_name
end

local function load_db()
  local res = get_resource_path()
  local db_path = join_path(res, "Support"..sep.."DF95_SampleDB"..sep.."DF95_SampleDB_ZoomF6.json")
  local f = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox("DB-Datei nicht gefunden:\n"..db_path.."\nBitte zuerst den Scan ausführen.", "DF95 SampleDB Rename", 0)
    return nil, db_path
  end
  local content = f:read("*a")
  f:close()
  local db = json_decode(content)
  if type(db) ~= "table" then
    r.ShowMessageBox("Konnte DB-Datei nicht parsen:\n"..db_path, "DF95 SampleDB Rename", 0)
    return nil, db_path
  end
  return db, db_path
end

local function write_db(db, db_path)
  local function json_escape(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\"):gsub("\"","\\\""):gsub("\n","\\n")
    return s
  end
  local function encode_any(v, indent)
    indent = indent or ""
    local next_indent = indent.."  "
    if type(v) == "table" then
      if #v > 0 then
        local parts = {"[\n"}
        for i, item in ipairs(v) do
          table.insert(parts, next_indent .. encode_any(item, next_indent))
          if i < #v then table.insert(parts, ",") end
          table.insert(parts, "\n")
        end
        table.insert(parts, indent .. "]")
        return table.concat(parts)
      else
        local parts = {"{\n"}
        local first = true
        for k, item in pairs(v) do
          if not first then table.insert(parts, ",\n") end
          first = false
          table.insert(parts, next_indent.."\""..json_escape(k).."\": "..encode_any(item, next_indent))
        end
        table.insert(parts, "\n"..indent.."}")
        return table.concat(parts)
      end
    elseif type(v) == "string" then
      return "\"" .. json_escape(v) .. "\""
    elseif type(v) == "number" then
      return tostring(v)
    elseif type(v) == "boolean" then
      return v and "true" or "false"
    else
      return "null"
    end
  end

  local f = io.open(db_path, "w")
  if not f then
    r.ShowMessageBox("Konnte DB-Datei nicht schreiben:\n"..db_path, "DF95 SampleDB Rename", 0)
    return false
  end
  f:write(encode_any(db, ""))
  f:close()
  return true
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local db, db_path = load_db()
  if not db then return end

  local res = get_resource_path()

  local ok, creator = r.GetUserInputs("DF95 SampleDB Rename", 1,
    "CreatorID (z.B. DF95, Initialen)", "DF95")
  if not ok then return end
  creator = creator:gsub("[^%w]", "")

  local ok2, source = r.GetUserInputs("DF95 SampleDB Rename", 1,
    "SourceID (z.B. ZoomF6, FieldrecLib1)", "ZoomF6")
  if not ok2 then return end
  source = source:gsub("[^%w]", "")

  local confirm = r.ShowMessageBox(
    "Achtung:\nDies wird alle in der DB gelisteten WAV-Dateien physisch umbenennen.\n\n" ..
    "DB: "..db_path.."\n\nFortfahren?", "DF95 SampleDB Rename", 4)
  if confirm ~= 6 then return end -- 6 = Yes

  local renamed = 0
  for i, entry in ipairs(db) do
    local old_path = entry.path
    if old_path and old_path:lower():match("%.wav$") then
      local catid = UCS_CATID[entry.type or "UNKNOWN"] or "MISC"
      local base_name = old_path:match("([^"..sep.."]+)$") or "Sample"
      local name_no_ext = base_name:gsub("%.wav$", "", 1)
      local fxname = sanitize_fxname(name_no_ext)

      local new_filename = string.format("%s_%s_%s_%s.wav", catid, fxname, creator, source)
      local dir = old_path:match("^(.*["..sep.."])") or ""
      local new_path = dir .. new_filename

      if new_path ~= old_path then
        local ok_rename, err = os.rename(old_path, new_path)
        if ok_rename then
          entry.path = new_path
          renamed = renamed + 1
          msg("Renamed: "..old_path.." -> "..new_path)
        else
          msg("Fehler beim Umbenennen: "..tostring(old_path).." ("..tostring(err)..")")
        end
      end
    end
  end

  local okw = write_db(db, db_path)
  if okw then
    r.ShowMessageBox("Umbenennen abgeschlossen.\nRenamed: "..renamed.."\nDB aktualisiert:\n"..db_path,
      "DF95 SampleDB Rename", 0)
  end
end

main()
