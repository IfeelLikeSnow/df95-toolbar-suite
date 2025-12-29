-- DF95_Slicing_AutoPipeline.lua
-- Ein-Klick-Pipeline:
--   1) Öffnet das DF95 Weighted Slicing Menü (du wählst ein Preset).
--   2) Danach werden FXBus-, Coloring- und Master-Ketten automatisch gewählt
--      (auf Basis von DF95_FXChains_Tags.json) und angewendet.
--   3) Zum Schluss wird das DF95 Safety/Loudness-Menü aufgerufen.
--
-- Idee:
--   * Du behältst die kreative Wahl beim Slicing, aber Routing/Bussing/Safety
--     laufen automatisch hinterher.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = (res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep):gsub("\\","/")

local function safe_dofile(path, label)
  local f = io.open(path, "rb")
  if not f then return false end
  f:close()
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler in "..(label or path)..":\n"..tostring(err), "DF95 Slicing AutoPipeline", 0)
  end
  return ok
end

local function load_tags()
  local read_json = dofile(base.."DF95_ReadJSON.lua")
  local tags = read_json(base.."DF95_FXChains_Tags.json") or {}
  return tags
end

local function has_tag(meta, tag)
  if not meta or not meta.tags then return false end
  for _,t in ipairs(meta.tags) do
    if t == tag then return true end
  end
  return false
end

local function score_meta(category, meta)
  if not meta then return -1 end
  local s = 0
  local t = meta.tags or {}

  local function boost(tag, amount)
    if has_tag(meta, tag) then s = s + amount end
  end

  -- allgemeine "sicher/gut" Tags
  boost("safe", 6)
  boost("clean", 4)
  boost("neutral", 3)

  -- IDM + Glitch für FXBus/Master
  if category == "FXBus" or category == "Master" then
    boost("idm", 3)
    boost("glitch", 2)
  end

  -- warm/wide eher für Coloring/Master
  if category == "Coloring" or category == "Master" then
    boost("warm", 3)
    boost("boc", 2)
    boost("wide", 1)
  end

  -- spectral/modern bei Bedarf
  boost("spectral", 1)
  boost("modern", 1)

  return s
end

local function pick_best_chain(tags_data, category)
  local cat_tbl = tags_data[category]
  if not cat_tbl then return nil, nil end

  local best_rel, best_meta, best_score = nil, nil, -1

  for rel, meta in pairs(cat_tbl) do
    local score = score_meta(category, meta)
    if score > best_score then
      best_score = score
      best_rel = rel
      best_meta = meta
    end
  end

  return best_rel, best_meta
end

local function apply_chain_to_target(category, rel, meta)
  if not rel then return end
  local C = dofile(base.."DF95_Common_RfxChainLoader.lua")

  local fxroot = (res..sep.."FXChains"..sep.."DF95"..sep):gsub("\\","/")
  local path = fxroot..(rel:gsub("/", sep))

  local txt = C.read_file(path)
  if not txt then
    r.ShowMessageBox("FXChain nicht gefunden:\n"..tostring(path), "DF95 Slicing AutoPipeline", 0)
    return
  end

  if category == "FXBus" then
    local tr = C.ensure_track_named("[FX Bus]")
    C.write_chunk_fxchain(tr, txt, false)

  elseif category == "Coloring" then
    local tr = C.ensure_track_named("[Coloring Bus]")
    C.write_chunk_fxchain(tr, txt, false)

  elseif category == "Master" then
    local master = r.GetMasterTrack(0)
    C.write_chunk_fxchain(master, txt, false)
  end
end

local function run_safety_menu()
  local safety_path = base.."DF95_Safety_Loudness_Menu.lua"
  safe_dofile(safety_path, "DF95_Safety_Loudness_Menu.lua")
end

local function main()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  -- 1) Slicing: Weighted Menü öffnen (User wählt Preset)
  local weighted = base.."Core"..sep.."DF95_Slice_Menu_Weighted.lua"
  safe_dofile(weighted, "DF95_Slice_Menu_Weighted.lua")

  -- 2) Tags laden und passende FXBus/Coloring/Master-Ketten wählen
  local tags_data = load_tags()

  local fx_rel, fx_meta = pick_best_chain(tags_data, "FXBus")
  local col_rel, col_meta = pick_best_chain(tags_data, "Coloring")
  local m_rel, m_meta   = pick_best_chain(tags_data, "Master")

  apply_chain_to_target("FXBus",    fx_rel, fx_meta)
  apply_chain_to_target("Coloring", col_rel, col_meta)
  apply_chain_to_target("Master",   m_rel,  m_meta)

  -- 3) Safety / Loudness Menu
  run_safety_menu()

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Slicing AutoPipeline", -1)
end

main()
