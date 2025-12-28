--[[
DF95 - FXChains Index Builder (Lua/ReaScript)

Voll implementierte Version:

- Scannt REAPER_RESOURCE_PATH/FXChains/DF95 rekursiv
- Findet alle .rfxchain-Dateien
- Erzeugt Data/DF95/fxchains_index.json mit einer strukturierten Liste aller Chains

Jeder Eintrag enthält u.a.:
  id        : eindeutige ID (aus Pfad/Filename abgeleitet)
  path      : relativer Pfad ab REAPER-Resource-Root (z.B. "FXChains/DF95/SFX/Whoosh/Whoosh01.rfxchain")
  filename  : Dateiname
  category  : Unterordner relativ zu FXChains/DF95 (z.B. "SFX/Whoosh")
  tags      : einfache Heuristik-Tags (drum/sfx/whoosh ...)
  roles     : einfache Rollenheuristik (item/bus/master)
  meta      : Generator-Info

Top-Level-JSON:
{
  "version": "1.0",
  "generated_at": "...",
  "base_path": "FXChains/DF95",
  "count": <Anzahl>,
  "fxchains": [ ... ]
}

Dieses Format ist kompatibel mit:
- DF95_FXChains_Index_Enricher.lua
- DF95_AI_FXChain_From_AIResult.lua
- DF95_AI_FXChain_FullAuto_From_AIResult.lua
- DF95_AI_ArtistFXBrain_ImGui.lua
]]--

-- @description DF95 - Build FXChains Index (FXChains/DF95 -> Data/DF95/fxchains_index.json)
-- @version 1.1
-- @changelog Voll implementierte Scan-/JSON-Variante (ersetzt Placeholder).
-- @author DF95 / Reaper DAW Ultimate Assistant
-- @about Scans all .rfxchain files under FXChains/DF95 and writes a JSON index for AI / workflow brains.

local r = reaper

-------------------------------------------------------
-- Utility: JSON-Encoder (minimal, aber ausreichend)
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
    -- Unterscheide Array- vs. Map-Table
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
        parts[#parts+1] = json_encode_value(v[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      for k, val in pairs(v) do
        parts[#parts+1] = "\"" .. json_escape(k) .. "\":" .. json_encode_value(val)
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
-- Utility: Pfade
-------------------------------------------------------

local sep = package.config:sub(1, 1)  -- OS-spezifisches Trennzeichen

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

-------------------------------------------------------
-- Reaper Resource Paths
-------------------------------------------------------

local resource_path = normalize_slashes(r.GetResourcePath())

local fx_root = join_path(resource_path, "FXChains")
fx_root = join_path(fx_root, "DF95")      -- REAPER_RESOURCE_PATH/FXChains/DF95

local data_root = join_path(resource_path, "Data")
data_root = join_path(data_root, "DF95")  -- REAPER_RESOURCE_PATH/Data/DF95

-- Data/DF95 sicherstellen
r.RecursiveCreateDirectory(data_root, 0)

local index_path = join_path(data_root, "fxchains_index.json")

-------------------------------------------------------
-- Directory Scanner
-------------------------------------------------------

local function scan_fxchains_dir(base_path, current_rel, out_list)
  -- base_path : absoluter Pfad zu FXChains/DF95
  -- current_rel : Unterordner relativ zu FXChains/DF95 (z.B. "SFX/Whoosh")
  -- out_list : Tabelle für Ergebnisse

  local full_path = base_path
  if current_rel ~= "" then
    full_path = join_path(base_path, current_rel)
  end

  -- Dateien
  local file_idx = 0
  while true do
    local filename = r.EnumerateFiles(full_path, file_idx)
    if not filename then break end
    file_idx = file_idx + 1

    if filename:lower():sub(-9) == ".rfxchain" then
      local rel_path
      if current_rel ~= "" then
        rel_path = join_path(current_rel, filename)
      else
        rel_path = filename
      end

      local category = current_rel ~= "" and current_rel or "ROOT"

      -- einfache ID: relativer Pfad (ohne Extension), Slashes -> Unterstriche
      local id = rel_path:gsub("[/\\]", "_")
      id = id:gsub("%.rfxchain$", "")

      local entry = {
        id = id,
        -- Pfad relativ zum REAPER-Resource-Root (für andere Scripte lesbar)
        path = "FXChains/DF95/" .. rel_path:gsub("[\\]", "/"),
        filename = filename,
        category = category:gsub("[\\]", "/"),
        tags = {},
        roles = {},
        meta = {
          created_by = "DF95_FXChains_Index_Builder",
          version = "1.1"
        }
      }

      out_list[#out_list+1] = entry
    end
  end

  -- Unterordner
  local dir_idx = 0
  while true do
    local dirname = r.EnumerateSubdirectories(full_path, dir_idx)
    if not dirname then break end
    dir_idx = dir_idx + 1

    if dirname ~= "." and dirname ~= ".." then
      local new_rel
      if current_rel ~= "" then
        new_rel = join_path(current_rel, dirname)
      else
        new_rel = dirname
      end
      scan_fxchains_dir(base_path, new_rel, out_list)
    end
  end
end

-------------------------------------------------------
-- Heuristiken für Tags / Rollen
-------------------------------------------------------

local function enrich_basic_tags_and_roles(entry)
  local cat_lower = (entry.category or ""):lower()
  local name_lower = (entry.filename or ""):lower()

  -- Basic Tags
  if cat_lower:find("drum") or name_lower:find("drum") then
    entry.tags[#entry.tags+1] = "drum"
  end
  if cat_lower:find("sfx") or name_lower:find("sfx") then
    entry.tags[#entry.tags+1] = "sfx"
  end
  if cat_lower:find("whoosh") or name_lower:find("whoosh") then
    entry.tags[#entry.tags+1] = "whoosh"
  end
  if cat_lower:find("impact") or name_lower:find("impact") then
    entry.tags[#entry.tags+1] = "impact"
  end
  if cat_lower:find("master") or name_lower:find("master") then
    entry.tags[#entry.tags+1] = "master"
  end

  -- Basic Roles
  if cat_lower:find("master") then
    entry.roles[#entry.roles+1] = "master"
  elseif cat_lower:find("bus") or cat_lower:find("stem") then
    entry.roles[#entry.roles+1] = "bus"
  else
    entry.roles[#entry.roles+1] = "item"
  end
end

-------------------------------------------------------
-- Main Logic
-------------------------------------------------------

local function build_fxchains_index()
  local fxchains = {}

  -- Scannen ab FXChains/DF95
  scan_fxchains_dir(fx_root, "", fxchains)

  -- Heuristiken anwenden
  for _, entry in ipairs(fxchains) do
    enrich_basic_tags_and_roles(entry)
  end

  -- Top-Level JSON
  local json_tbl = {
    version = "1.0",
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    base_path = "FXChains/DF95",
    count = #fxchains,
    fxchains = fxchains
  }

  local json_str = json_encode(json_tbl)

  local f, err = io.open(index_path, "w")
  if not f then
    r.ShowMessageBox("Konnte Index-Datei nicht schreiben:\n" .. tostring(index_path) ..
                     "\nFehler: " .. tostring(err),
                     "DF95 FXChains Index Builder", 0)
    return
  end
  f:write(json_str)
  f:close()

  r.ShowMessageBox("FXChains Index erstellt:\n" .. index_path ..
                   "\nEinträge: " .. tostring(#fxchains),
                   "DF95 FXChains Index Builder", 0)
end

-------------------------------------------------------
-- Run with Undo
-------------------------------------------------------

r.Undo_BeginBlock()
build_fxchains_index()
r.Undo_EndBlock("DF95: Build FXChains Index", -1)
r.UpdateArrange()
