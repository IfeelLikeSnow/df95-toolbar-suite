-- IFLS_UCS_ExportEngine.lua
-- Phase 100: UCS-based Sample Export Engine for IFLS / DF95
--
-- GOAL
-- ----
-- * Exportiert Samples in einen vom User gewählten Root-Folder.
-- * Legt/benutzt automatisch Unterordner pro Kategorie (Kick, Snare, etc.).
-- * Bennennt Dateien in vereinfachtem UCS-Style:
--       <PREFIX><NNN>_<Desc1>_<Desc2>_<Desc3>.wav
-- * Achtet darauf, dass Nummern fortlaufend sind:
--       Wenn KIC001 existiert, wird die nächste Kick zu KIC002 usw.
--
-- Dieses Modul sliced NICHT selbst. Es erwartet eine Liste an Samples
-- (mit src_path + Kategorie + optionalen Deskriptoren) und kopiert
-- die Files in die Zielstruktur.

local M = {}
local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function strip_trailing_sep(path)
  local sep = package.config:sub(1,1)
  if not path or path == "" then return "" end
  if path:sub(-1) == sep then
    return path:sub(1, -2)
  end
  return path
end

local function join(a, b)
  local sep = package.config:sub(1,1)
  a = strip_trailing_sep(a or "")
  if a == "" then return b end
  return a .. sep .. b
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function ensure_dir(path)
  if not path or path == "" then return end
  local sep = package.config:sub(1,1)
  local accum = ""
  for part in string.gmatch(path, "[^" .. sep .. "]+") do
    if accum == "" then
      accum = part
    else
      accum = accum .. sep .. part
    end
    if not file_exists(accum) then
      os.execute(string.format('mkdir "%s"', accum))
    end
  end
end

local function list_files(dir)
  local sep = package.config:sub(1,1)
  if not file_exists(dir) then return {} end

  local cmd
  if sep == "\\" then
    cmd = string.format('dir /B "%s"', dir)
  else
    cmd = string.format('ls "%s"', dir)
  end
  local p = io.popen(cmd)
  if not p then return {} end
  local t = {}
  for line in p:lines() do
    if line ~= "" then
      table.insert(t, line)
    end
  end
  p:close()
  return t
end

local function sanitize_descriptor(s)
  if not s or s == "" then return "UNK" end
  s = s:gsub("[/\\]", "-")
  s = s:gsub("%s+", "")
  return s
end

------------------------------------------------------------
-- Kategorie → UCS Prefix / Unterordner
------------------------------------------------------------

M.category_map = {
  Kick         = { prefix = "KIC", subfolder = "Kick" },
  Snare        = { prefix = "SNR", subfolder = "Snare" },
  HihatClosed  = { prefix = "HHC", subfolder = "HihatClosed" },
  HihatOpen    = { prefix = "HHO", subfolder = "HihatOpen" },
  Clap         = { prefix = "CLP", subfolder = "Clap" },
  Tom          = { prefix = "TOM", subfolder = "Tom" },
  Perc         = { prefix = "PRC", subfolder = "Perc" },
  Shaker       = { prefix = "SHK", subfolder = "Shaker" },
  FX           = { prefix = "FX",  subfolder = "FX" },
  Noise        = { prefix = "NOI", subfolder = "Noise" },
  Misc         = { prefix = "MSC", subfolder = "Misc" },
}

M.default_category = "Misc"

------------------------------------------------------------
-- Nächsten Index für ein Prefix im Zielordner finden
------------------------------------------------------------

local function find_next_index_for_prefix(dir, prefix)
  ensure_dir(dir)
  local files = list_files(dir)
  local max_idx = 0

  for _, fname in ipairs(files) do
    local num = fname:match("^" .. prefix .. "(%d%d%d)")
    if num then
      local n = tonumber(num)
      if n and n > max_idx then
        max_idx = n
      end
    end
  end

  return max_idx + 1
end

------------------------------------------------------------
-- UCS-Pfad bauen
------------------------------------------------------------

function M.build_ucs_path(export_root, sample)
  local category = sample.category or M.default_category
  local map = M.category_map[category] or M.category_map[M.default_category]

  local prefix    = map.prefix or "MSC"
  local subfolder = map.subfolder or "Misc"

  local base_dir = strip_trailing_sep(export_root or "")
  local dst_dir  = join(base_dir, subfolder)
  ensure_dir(dst_dir)

  local descriptors = sample.descriptors or {}
  local d1 = sanitize_descriptor(descriptors[1] or "UNK")
  local d2 = sanitize_descriptor(descriptors[2] or "UNK")
  local d3 = sanitize_descriptor(descriptors[3] or "UNK")

  local ext = sample.ext or "wav"
  ext = ext:gsub("^%.", "")

  local next_idx = find_next_index_for_prefix(dst_dir, prefix)
  local idx_str  = string.format("%03d", next_idx)

  local filename = string.format("%s%s_%s_%s_%s.%s",
    prefix, idx_str, d1, d2, d3, ext)

  return dst_dir, filename
end

------------------------------------------------------------
-- Datei kopieren
------------------------------------------------------------

local function copy_file(src, dst)
  local fi, err = io.open(src, "rb")
  if not fi then
    return false, "open src failed: " .. tostring(err)
  end
  local fo, err2 = io.open(dst, "wb")
  if not fo then
    fi:close()
    return false, "open dst failed: " .. tostring(err2)
  end

  while true do
    local block = fi:read(8192)
    if not block then break end
    fo:write(block)
  end

  fi:close()
  fo:close()
  return true
end

------------------------------------------------------------
-- Haupt-Exportfunktion
------------------------------------------------------------

function M.export_samples(export_root, samples)
  local results = {}
  if not export_root or export_root == "" then
    return results
  end

  export_root = strip_trailing_sep(export_root)

  for _, sample in ipairs(samples or {}) do
    local res = {
      ok       = false,
      src_path = sample.src_path,
      category = sample.category or M.default_category,
      error    = nil,
    }
    table.insert(results, res)

    if not sample.src_path or sample.src_path == "" then
      res.error = "src_path missing"
      goto continue
    end
    if not file_exists(sample.src_path) then
      res.error = "src_path does not exist"
      goto continue
    end

    local dst_dir, filename = M.build_ucs_path(export_root, sample)
    local dst_path = join(dst_dir, filename)
    res.filename = filename
    res.dst_path = dst_path

    local ok, err = copy_file(sample.src_path, dst_path)
    if not ok then
      res.error = err
      goto continue
    end

    res.ok = true

    ::continue::
  end

  return results
end

return M
