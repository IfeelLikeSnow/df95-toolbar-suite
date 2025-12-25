-- @description Export – UCS Metadata CSV From Tags
-- @version 1.0
-- @author DF95

-- Erzeugt eine CSV-Datei mit UCS-bezogenen Metadaten
-- für alle WAV-Dateien in einem Export-Ordner.
--
-- Nutzt:
--   - Dateiname (CatID_FXName_CreatorID_SourceID)
--   - DF95 Export Tags (Artist, Role, Source, FXFlavor, MicModel, RecMedium, etc.)
--
-- CSV kann in externe UCS-/Library-Tools (Soundminer, Basehead, etc.)
-- importiert werden, um BWF/ID3-Metadaten zu setzen.

local r = reaper

local function split(str, sep)
  local t = {}
  for part in string.gmatch(str, "([^"..sep.."]+)") do
    t[#t+1] = part
  end
  return t
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function get_export_core()
  local ok, mod_or_err = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  if not ok then return nil end
  if type(mod_or_err) ~= "table" then return nil end
  return mod_or_err
end

local function get_default_export_dir()
  local proj, projfn = r.EnumProjects(-1, "")
  local proj_dir = projfn:match("^(.*)[/\\][^/\\]+$") or r.GetProjectPath("")
  local base = proj_dir or r.GetProjectPath("")
  if not base or base == "" then base = r.GetProjectPath("") end
  local sep = package.config:sub(1,1)
  return (base .. sep .. "DF95_EXPORT"):gsub("\\","/")
end

local function main()
  local core = get_export_core()
  local default_dir = get_default_export_dir()

  -- Auto-Modus: falls EXTSTATE "DF95_EXPORT / AUTO_CSV_DEFAULTFOLDER" == "1"
  -- wird der Default-Exportordner ohne Dialog benutzt.
  local auto = r.GetExtState("DF95_EXPORT", "AUTO_CSV_DEFAULTFOLDER") or ""
  local ok, ret

  if auto == "1" then
    ok, ret = true, default_dir
    -- Auto-Flag zurücksetzen, damit nicht der nächste Run auch "silent" ist
    r.SetExtState("DF95_EXPORT", "AUTO_CSV_DEFAULTFOLDER", "", false)
  else
    ok, ret = r.GetUserInputs("DF95 Export Metadata CSV", 1,
      "ExportFolder (leer = DF95_EXPORT im Projekt)", default_dir)
  end

  if not ok or not ret or ret == "" then return end

  local folder = ret:match("^(.-)$") or default_dir
  folder = folder:gsub("%s+$","")
  if folder == "" then folder = default_dir end

  local sep = package.config:sub(1,1)
  folder = folder:gsub("[/\\]+$", "")

  local files = {}
  local i = 0
  while true do
    local fn = r.EnumerateFiles(folder, i)
    if not fn then break end
    if fn:lower():match("%.wav$") then
      files[#files+1] = fn
    end
    i = i + 1
  end

  if #files == 0 then
    r.ShowMessageBox("Keine WAV-Dateien im Export-Ordner gefunden:\n"..folder, "DF95 Export Metadata CSV", 0)
    return
  end

  -- Hole aktuelle Export-Tags
  local function get_tag(key, default)
    if core and core.GetExportTag then
      return core.GetExportTag(key, default)
    end
    return default
  end

  local artist     = get_tag("Artist", "")
  local role_tag   = get_tag("Role", "")
  local source_tag = get_tag("Source", "")
  local fxflavor   = get_tag("FXFlavor", "")
  local mic_model  = get_tag("MicModel", "")
  local rec_medium = get_tag("RecMedium", "")

  local csv_path = folder .. sep .. "DF95_UCS_Metadata.csv"
  local f = io.open(csv_path, "w")
  if not f then
    r.ShowMessageBox("Konnte CSV nicht schreiben:\n"..csv_path, "DF95 Export Metadata CSV", 0)
    return
  end

  -- einfache CSV-Header:
  -- Filename,CatID,FXName,CreatorID,SourceID,Description,Artist,Role,Source,FXFlavor,MicModel,RecMedium
  f:write("Filename,CatID,FXName,CreatorID,SourceID,Description,Artist,Role,Source,FXFlavor,MicModel,RecMedium\n")

  local function csv_escape(s)
    s = s or ""
    if s:find("[,\"\n]") then
      s = '"' .. s:gsub('"','""') .. '"'
    end
    return s
  end

  for _, fn in ipairs(files) do
    local base = fn:gsub("%.wav$","")
    local parts = split(base, "_")
    local catid, fxname, creatorid, sourceid = "", "", "", ""
    if #parts >= 4 then
      catid = parts[1] or ""
      fxname = parts[2] or ""
      creatorid = parts[3] or ""
      -- Rest zusammensetzen als SourceID (falls weitere Unterstriche)
      local rest = {}
      for i = 4, #parts do rest[#rest+1] = parts[i] end
      sourceid = table.concat(rest, "_")
    end

    local desc = fxname:gsub("_"," ")
    if desc == "" then
      desc = base
    end

    local row = table.concat({
      csv_escape(fn),
      csv_escape(catid),
      csv_escape(fxname),
      csv_escape(creatorid),
      csv_escape(sourceid),
      csv_escape(desc),
      csv_escape(artist),
      csv_escape(role_tag),
      csv_escape(source_tag),
      csv_escape(fxflavor),
      csv_escape(mic_model),
      csv_escape(rec_medium)
    }, ",")

    f:write(row .. "\n")
  end

  f:close()

  r.ShowMessageBox("CSV erzeugt:\n"..csv_path.."\n\nDiese Datei kannst du in ein UCS-/Metadata-Tool importieren,\num BWF/ID3-Metadaten zu schreiben.", "DF95 Export Metadata CSV", 0)
end

main()
