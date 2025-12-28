-- @description Export DryRun Wizard (Preview only, no render)
-- @version 1.0
-- @author DF95
-- @about
--   Nutzt DF95_Export_Core im DryRun-Modus, um alle geplanten Exporte
--   (Dateipfade, Tags, Modus) in der REAPER-Konsole zu zeigen,
--   ohne tatsächlich zu rendern.

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
  r.ShowMessageBox(tostring(s), "DF95 Export DryRun Wizard", 0)
end

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_export_core()
  local path = df95_root() .. "DF95_Export_Core.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Laden von DF95_Export_Core.lua:\n"..tostring(mod))
    return nil
  end
  return mod
end

local function main()
  local core = load_export_core()
  if not core or not core.run then return end

  -- letzte Eingabe oder aktuelle Tags als Startpunkt
  local last = r.GetExtState("DF95_EXPORT", "wizard_tags_dryrun")
if last == "" then
  local role     = core.GetExportTag and core.GetExportTag("Role", "Any")         or "Any"
  local source   = core.GetExportTag and core.GetExportTag("Source", "Any")       or "Any"
  local fxflavor = core.GetExportTag and core.GetExportTag("FXFlavor", "Generic") or "Generic"

  local mode      = "SELECTED_SLICES_SUM"
  local target    = "ORIGINAL"
  local category  = "Slices_Master"
  local subtype   = ""
  local dest_root = ""

  local presets = nil
  local okP, modP = pcall(dofile, df95_root() .. "DF95_Export_Presets.lua")
  if okP and modP and modP.get_list then
    presets = modP
  end

  local preset_id   = reaper.GetExtState("DF95_EXPORT", "current_preset_id")
  local preset_opts = nil
  if presets and presets.get_by_id and preset_id ~= "" then
    local p = presets.get_by_id(preset_id)
    if p and p.opts then
      preset_opts = p.opts
    end
  end

  if preset_opts then
    mode      = preset_opts.mode     or mode
    target    = preset_opts.target   or target
    category  = preset_opts.category or category
    subtype   = preset_opts.subtype  or subtype

    if (role == "Any" or role == "" or not role) and preset_opts.role then
      role = preset_opts.role
    end
    if (source == "Any" or source == "" or not source) and preset_opts.source then
      source = preset_opts.source
    end
    if (fxflavor == "Generic" or fxflavor == "" or not fxflavor) and preset_opts.fxflavor then
      fxflavor = preset_opts.fxflavor
    end
  end

  last = string.format("%s,%s,%s,%s,%s,%s,%s,%s",
                       mode, target, category, role, source, fxflavor, subtype, dest_root)
end

  local cap = table.concat({
    "Mode(ALL_SLICES/SELECTED_SLICES/SELECTED_SLICES_SUM/LOOP_TIMESEL)",
    "Target(ORIGINAL/ZOOM96_32F/SPLICE_44_24/LOOPMASTERS_44_24/ADSR_44_24)",
    "Category",
    "Role",
    "Source",
    "FXFlavor",
    "Subtype(optional)",
    "DestRoot(empty=DF95_EXPORT in project)"
  }, ",")

  local ok, ret = r.GetUserInputs("DF95 Export DryRun Wizard (Preview)", 1, cap..":", last)
  if not ok or not ret or ret == "" then return end
  r.SetExtState("DF95_EXPORT", "wizard_tags_dryrun", ret, true)

  local mode, target, category, role, source, fxflavor, subtype, dest_root =
    ret:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")

  if not mode then
    msg("Eingabe nicht erkannt.\nErwartet: Mode,Target,Category,Role,Source,FXFlavor,Subtype,DestRoot")
    return
  end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  mode      = trim(mode)
  target    = trim(target)
  category  = trim(category)
  role      = trim(role)
  source    = trim(source)
  fxflavor  = trim(fxflavor)
  subtype   = trim(subtype)
  dest_root = trim(dest_root)

  local opts = {
    mode      = mode,
    target    = target,
    category  = category,
    role      = role ~= "" and role or nil,
    source    = source ~= "" and source or nil,
    fxflavor  = fxflavor ~= "" and fxflavor or nil,
    subtype   = subtype ~= "" and subtype or nil,
    dest_root = dest_root ~= "" and dest_root or nil,
    dry_run   = true,
  }

  r.ShowConsoleMsg("\n===== DF95 Export DryRun Preview =====\n")
  core.run(opts)
  r.ShowConsoleMsg("===== DF95 Export DryRun Ende =====\n\n")
end

main()
