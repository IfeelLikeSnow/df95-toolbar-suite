-- @description Sampler Core (helpers)
-- @version 1.2
-- @author DF95
-- @about
--   Zentrale Helper-Funktionen für die DF95 Sampler-Integration.
--   Diese Datei wird von Pipeline-/ArtistConsole-Scripten verwendet,
--   um RS5k-Kits zu bauen, aus Items zu mappen etc.

local r = reaper
local M = {}
local DF95_AutoTag = nil
do
  local dir = df95_root()
  if dir ~= "" then
    local ok, mod = pcall(dofile, dir .. "DF95_AutoTag_Core.lua")
    if ok and mod then
      DF95_AutoTag = mod
    end
  end
end


local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function safe_dofile(rel)
  local path = df95_root() .. rel
  local ok, res = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("DF95_Sampler_Core: Fehler beim Laden von "..rel..":\n"..tostring(res), "DF95 Sampler Core", 0)
    return nil
  end
  return res
end

-- Convenience-Wrapper auf die eigenständigen Scripts
function M.build_rs5k_from_folder()
  safe_dofile("DF95_Sampler_Build_RS5K_Kit_From_Folder.lua")
end

function M.build_rs5k_from_items()
  safe_dofile("DF95_Sampler_Map_Selected_Items_To_RS5K.lua")
end

function M.build_roundrobin_from_folder()
  safe_dofile("DF95_Sampler_Build_RoundRobin_Kit.lua")
end

function M.build_layered_from_two_folders()
  safe_dofile("DF95_Sampler_Build_Layered_Kit_From_FolderPair.lua")
end

function M.annotate_drum_roles()
  safe_dofile("DF95_Sampler_Annotate_DrumRoles_From_Notes.lua")
end

-- Hook für Pipeline-Core-Integration.
-- stage_options:
--   { mode = "folder" | "items" | "roundrobin",
--     layered = false,
--     annotate_roles = true/false }
function M.pipeline_sampler_build(stage_options)
  stage_options = stage_options or {}
  local mode    = stage_options.mode or "folder"
  local layered = stage_options.layered and (mode == "folder")

  if layered then
    M.build_layered_from_two_folders()
  else
    if mode == "folder" then
      M.build_rs5k_from_folder()
    elseif mode == "items" then
      M.build_rs5k_from_items()
    elseif mode == "roundrobin" then
      M.build_roundrobin_from_folder()
    end
  end

  if stage_options.annotate_roles then
    M.annotate_drum_roles()
  end
end

----------------------------------------------------------------------
-- Multi-Slot Builder
--   Ermöglicht es, mehrere Kits hintereinander zu bauen, z.B.:
--   slots = {
--     { track_name = "MicroPerc", mode = "folder", build = "plain",
--       annotate_roles = true, layers = 1 },
--     { track_name = "Clicks&Pops", mode = "folder", build = "roundrobin",
--       annotate_roles = true, layers = 1 },
--   }
--
--   Aktuell:
--     - "mode"       : "folder" | "items" | "roundrobin"
--     - "build"      : "plain" | "roundrobin" | "layered"
--     - "layers"     : 1 (Single-Layer) oder 2 (Layered-Kit via zwei Ordnern)
--     - "track_name" : Optionaler Trackname, falls das Builder-Script eine neue
--                      Spur erzeugt (keine harte Garantie, aber in DF95-Standard
--                      der Fall, wenn keine Spur selektiert ist).
----------------------------------------------------------------------

local function export_kit_metadata(slots)
  if not slots or type(slots) ~= "table" then return end
  -- Baue eine einfache Metastruktur (Note -> Role/TrackName/Folder etc.)
  local meta = { slots = {} }
  for _, slot in ipairs(slots) do
    local entry = {
      note       = slot.note,
      role       = slot.role,
      track_name = slot.track_name,
      folder     = slot.folder,
      layers     = slot.layers and #slot.layers or nil,
    }
    table.insert(meta.slots, entry)
  end

  -- Sehr einfache JSON-Serialisierung
  local parts = {"{"}
  parts[#parts+1] = '"slots":['
  for i, s in ipairs(meta.slots) do
    if i > 1 then parts[#parts+1] = "," end
    local function esc(v)
      if not v then return 'null' end
      if type(v) == "number" then return tostring(v) end
      v = tostring(v):gsub("\\\\", "\\\\\\\\"):gsub('"', '\\"')
      return '"' .. v .. '"'
    end
    parts[#parts+1] = string.format('{ "note":%s,"role":%s,"track_name":%s,"folder":%s,"layers":%s }',
                                    esc(s.note), esc(s.role), esc(s.track_name), esc(s.folder), esc(s.layers))
  end
  parts[#parts+1] = "]}"
  local json = table.concat(parts)

  -- In ExtState ablegen, damit Export-/Pack-Wizard und andere Module sie nutzen können
  r.SetExtState("DF95_SAMPLER_KIT_META", "last_kit", json, true)

  -- Optional: globale Role auf "DrumKit" setzen, wenn AutoTag-Core verfügbar ist
  if DF95_AutoTag then
    -- Wir überschreiben Role im Export-Kontext nur, wenn noch nichts gesetzt ist
    local existing_role = r.GetExtState("DF95_EXPORT_TAGS", "Role")
    if not existing_role or existing_role == "" or existing_role == "Any" then
      r.SetExtState("DF95_EXPORT_TAGS", "Role", "DrumKit", true)
    end
  end
end


local function build_single_slot(slot)
  if not slot or type(slot) ~= "table" then return end
  local mode   = slot.mode or slot.build or "folder"
  local build  = slot.build or "plain"
  local layers = tonumber(slot.layers or 1) or 1

  if mode == "folder" then
    if layers >= 2 or build == "layered" then
      -- Layered-Kit: zwei Ordner, jeweils ein Layer
      M.build_layered_from_two_folders()
    elseif build == "roundrobin" then
      -- RoundRobin-Kit aus Ordner
      M.build_roundrobin_from_folder()
    else
      -- Plain Kit aus Ordner
      M.build_rs5k_from_folder()
    end
  elseif mode == "items" then
    -- Items-basiertes Kit (Layered-Variante wäre hier deutlich komplexer;
    -- vorerst nur Single-Layer)
    M.build_rs5k_from_items()
  elseif mode == "roundrobin" then
    M.build_roundrobin_from_folder()
  end

  if slot.annotate_roles then
    M.annotate_drum_roles()
  end

  if slot.track_name and slot.track_name ~= "" then
    local proj = 0
    local tr_count = r.CountTracks(proj)
    if tr_count > 0 then
      local tr = r.GetTrack(proj, tr_count-1)
      r.GetSetMediaTrackInfo_String(tr, "P_NAME", slot.track_name, true)
    end
  end
end

function M.build_multi_slots(slots)
  if type(slots) ~= "table" then return end
  for _, slot in ipairs(slots) do
    build_single_slot(slot)
  end
end

return M