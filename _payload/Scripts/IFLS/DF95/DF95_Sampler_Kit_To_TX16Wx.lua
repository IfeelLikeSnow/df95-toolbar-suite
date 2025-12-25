\
-- @description DF95_Sampler_Kit_To_TX16Wx
-- @version 1.0
-- @author DF95
-- @about
--   Adapter: DF95_Sampler_KitSchema -> TX16Wx via SFZ-Datei.
--   Dieses Modul erzeugt eine einfache SFZ-Datei auf Basis eines Kits,
--   die anschliessend in TX16Wx geladen werden kann.
--
--   Hinweis:
--     - Die SFZ wird in Data/DF95/KitExports abgelegt.
--     - Jede Slot-Datei wird als eigenes <region> mit key=root_note exportiert.

local r = reaper

local M = {}

local function sep()
  return package.config:sub(1,1)
end

local function join(a, b)
  local s = sep()
  if a:sub(-1) == s then
    return a .. b
  else
    return a .. s .. b
  end
end

local function normalize(path)
  local s = sep()
  if s == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function ensure_dir(path)
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(path, 0)
  end
end

local function write_file(path, txt)
  local f, err = io.open(path, "w")
  if not f then return false, err end
  f:write(txt or "")
  f:close()
  return true
end

-- Erzeugt eine SFZ-Datei fuer ein gegebenes Kit.
-- options: { subdir, filename }
function M.build_sfz_for_kit(kit, options)
  if not kit or type(kit) ~= "table" or type(kit.slots) ~= "table" then
    r.ShowMessageBox("Kit ist ungueltig oder enthaelt keine Slots.", "DF95 Kit -> TX16Wx", 0)
    return nil
  end

  options = options or {}
  local base = r.GetResourcePath()
  local data_dir = join(join(base, "Data"), "DF95")
  local export_dir = join(data_dir, options.subdir or "KitExports")
  export_dir = normalize(export_dir)
  ensure_dir(export_dir)

  local kit_name = (kit.meta and kit.meta.name) or "DF95_TX16Wx_Kit"
  -- Dateinamen etwas saeubern
  local safe_name = kit_name:gsub("[^%w_%-%s]", "_")
  local sfz_path = join(export_dir, safe_name .. ".sfz")
  sfz_path = normalize(sfz_path)

  local lines = {}
  table.insert(lines, "// DF95 Kit -> TX16Wx SFZ")
  if kit.meta then
    table.insert(lines, "// Kit: " .. (kit.meta.name or ""))
    table.insert(lines, "// Artist: " .. (kit.meta.artist or ""))
    table.insert(lines, "// Source: " .. (kit.meta.source or ""))
    table.insert(lines, "// BPM: " .. tostring(kit.meta.bpm or 0))
  end
  table.insert(lines, "")

  table.insert(lines, "<group>")
  table.insert(lines, "loop_mode=one_shot")

  for i, slot in ipairs(kit.slots) do
    local file = slot.file
    local root = tonumber(slot.root or 0) or 0
    if file and file ~= "" then
      local region = string.format('<region> sample=%s key=%d pitch_keycenter=%d', file, root, root)
      table.insert(lines, region)
    end
  end

  local txt = table.concat(lines, "\n")
  local ok, err = write_file(sfz_path, txt)
  if not ok then
    r.ShowMessageBox("Fehler beim Schreiben der SFZ-Datei:\n" .. tostring(err or "unbekannt"), "DF95 Kit -> TX16Wx", 0)
    return nil
  end

  return sfz_path
end

return M
