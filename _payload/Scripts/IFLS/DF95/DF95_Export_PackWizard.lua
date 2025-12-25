-- @description Export PackWizard (Preset-basiert)
-- @version 1.0
-- @author DF95
-- @about
--   Erstellt auf Basis der DF95 Export Presets komplette Sample-Packs
--   (Drum Packs, MicroPerc, Clicks/Pops, Mobile Foley usw.).
--   Nutzt DF95_Export_Core.run(opts) mit passenden Presets und Zielordnern.
--
--   V1: Arbeitet auf den aktuell selektierten Slices/Items und nutzt die
--       Preset-Einstellungen (Mode=SELECTED_SLICES_SUM etc.).
--       Spätere Versionen können Items zusätzlich nach Rollen/Kategorien
--       filtern, wenn Role-Metadaten pro Slice verfügbar sind.

local r = reaper
local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

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


local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Export PackWizard", 0)
end

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_modules()
  local root = df95_root()
  if root == "" then
    msg("Konnte DF95 Root nicht bestimmen.")
    return nil, nil
  end

  local okC, core = pcall(dofile, root .. "DF95_Export_Core.lua")
  if not okC or not core or not core.run then
    msg("Konnte DF95_Export_Core.lua nicht laden:\n" .. tostring(core))
    return nil, nil
  end

  local okP, presets = pcall(dofile, root .. "DF95_Export_Presets.lua")
  if not okP or not presets or not presets.get_by_id then
    msg("Konnte DF95_Export_Presets.lua nicht laden:\n" .. tostring(presets))
    return nil, nil
  end

  return core, presets
end

-- Definition der Pack-Typen auf Basis von vorhandenen Export-Presets
local PACKS = {
  {
    id         = "IDM_DRUM_PACK",
    label      = "IDM Drum Pack (FullKit)",
    preset_id  = "IDM_DRUM_PACK",
    subfolder  = "IDM_DrumPack",
    desc       = "Drum Pack mit FullKit (Kicks/Snares/Hats/Perc)",
  },
  {
    id         = "IDM_MICROPERC_PACK",
    label      = "IDM MicroPerc Pack",
    preset_id  = "IDM_MICROPERC",
    subfolder  = "IDM_MicroPerc",
    desc       = "Kleine percussive Snips / MicroPerc-Glitches",
  },
  {
    id         = "IDM_CLICKPOPS_PACK",
    label      = "IDM Clicks & Pops Pack",
    preset_id  = "IDM_CLICKPOPS",
    subfolder  = "IDM_ClicksPops",
    desc       = "Kurz, klickig, noisig – ideal für Clicks/Pops-Libraries.",
  },
  {
    id         = "MOBILE_FOLEY_PACK",
    label      = "Mobile FR Foley Pack",
    preset_id  = "MOBILE_FOLEY",
    subfolder  = "MobileFR_Foley",
    desc       = "Field Recorder (MobileFR) Aufnahmen als Foley-Pack.",
  },
  {
    id         = "SYNTH_ONESHOT_PACK",
    label      = "Synth OneShot Pack",
    preset_id  = "SYNTH_ONESHOTS",
    subfolder  = "Synth_OneShots",
    desc       = "Synth-OneShots (Stabs, Hits, Plucks) als Pack.",
  },
  {
    id         = "ARTIST_BASED_PACK",
    label      = "Artist-Based (Auto) Pack",
    preset_id  = "ARTIST_BASED",
    subfolder  = "Artist_Auto",
    desc       = "Nutzt Artist-/Tag-basierte Auto-Logik.",
  },
}

local function get_pack_by_label(label)
  for _, p in ipairs(PACKS) do
    if p.label == label then return p end
  end
  return nil
end

local function get_pack_labels()
  local parts = {}
  for _, p in ipairs(PACKS) do
    parts[#parts+1] = p.label
  end
  return table.concat(parts, "|")
end

local function get_project_base_export_folder()
  local _, proj_path = r.EnumProjects(-1, "")
  if not proj_path or proj_path == "" then
    local resource = r.GetResourcePath()
    return resource .. r.GetOS():match("Win") and "\\DF95_EXPORT" or "/DF95_EXPORT"
  end
  local dir = proj_path:match("^(.*[\\/])")
  if not dir or dir == "" then
    local resource = r.GetResourcePath()
    dir = resource .. (r.GetOS():match("Win") and "\\DF95_EXPORT" or "/DF95_EXPORT")
  else
    dir = dir .. "DF95_EXPORT"
  end
  return dir
end

local function main()
  local core, presets = load_modules()
  if not core or not presets then return end

  local labels = get_pack_labels()
  local default_pack = r.GetExtState("DF95_EXPORT", "packwizard_last_label")
  if default_pack == "" then
    default_pack = "IDM Drum Pack (FullKit)"
  end

  local default_dest_root = r.GetExtState("DF95_EXPORT", "packwizard_last_dest")
  if default_dest_root == "" then
    default_dest_root = "" -- leer = automatisch aus Projekt
  end

  local default_dryrun = r.GetExtState("DF95_EXPORT", "packwizard_last_dryrun")
  if default_dryrun == "" then
    default_dryrun = "true"
  end

  local caption = table.concat({
    "PackType (" .. labels .. ")",
    "DestRoot (leer = DF95_EXPORT im Projekt)",
    "DryRun? (true/false)"
  }, ",")

  local defaults = table.concat({default_pack, default_dest_root, default_dryrun}, ",")

  local ok, ret = r.GetUserInputs("DF95 Export PackWizard", 3, caption .. ":", defaults)
  if not ok or not ret or ret == "" then return end

  local pack_label, dest_root, dryrun_str = ret:match("^(.-),(.-),(.-)$")
  if not pack_label then
    msg("Eingabe nicht erkannt.\nErwartet: PackType,DestRoot,DryRun")
    return
  end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end
  pack_label = trim(pack_label)
  dest_root  = trim(dest_root)
  dryrun_str = trim(dryrun_str)

  r.SetExtState("DF95_EXPORT", "packwizard_last_label", pack_label, true)
  r.SetExtState("DF95_EXPORT", "packwizard_last_dest", dest_root, true)
  r.SetExtState("DF95_EXPORT", "packwizard_last_dryrun", dryrun_str, true)

  local pack = get_pack_by_label(pack_label)
  if not pack then
    msg("Unbekannter PackType: " .. pack_label)
    return
  end

  local preset = presets.get_by_id and presets.get_by_id(pack.preset_id)
  if not preset or not preset.opts then
    msg("Preset für PackType nicht gefunden: " .. tostring(pack.preset_id))
    return
  end

  local dest = dest_root
  if dest == "" then
    dest = get_project_base_export_folder()
  end

  -- Unterordner für den Pack-Typ hinzufügen
  local sep = r.GetOS():match("Win") and "\\" or "/"
  dest = dest .. sep .. (pack.subfolder or pack.id)

  -- opts aus Preset kopieren
  local opts = {}
  for k, v in pairs(preset.opts) do
    opts[k] = v
  end
  opts.dest_root = dest
  opts.dry_run   = (dryrun_str == "true" or dryrun_str == "1" or dryrun_str == "yes")

  -- core.run kümmert sich um Tags (Role/Source/FXFlavor) via get_effective_tags
  r.ShowConsoleMsg(string.format(
    "\n[DF95 PackWizard] Starte Pack-Export '%s' -> %s\n  Preset=%s | DryRun=%s\n",
    pack.label, dest, pack.preset_id, tostring(opts.dry_run)
  ))
  core.run(opts)
  r.ShowConsoleMsg("[DF95 PackWizard] Fertig.\n")
end

main()
