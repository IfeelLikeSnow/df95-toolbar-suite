-- @description Export Wizard (Slices & Loops, post Master, Tag-aware)
-- @version 1.2
-- @author DF95

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
  r.ShowMessageBox(tostring(s), "DF95 Export Wizard", 0)
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

  local last = r.GetExtState("DF95_EXPORT", "wizard_tags")
if last == "" then
  local role     = core.GetExportTag and core.GetExportTag("Role", "Any")         or "Any"
  local source   = core.GetExportTag and core.GetExportTag("Source", "Any")       or "Any"
  local fxflavor = core.GetExportTag and core.GetExportTag("FXFlavor", "Generic") or "Generic"

  local mode     = "SELECTED_SLICES_SUM"
  local target   = "ORIGINAL"
  local category = "Slices_Master"
  local dest     = ""

  local presets_ok, presets_mod = pcall(dofile, df95_root() .. "DF95_Export_Presets.lua")
  local presets = presets_ok and presets_mod or nil
  local preset_id   = r.GetExtState("DF95_EXPORT", "current_preset_id")
  local preset_opts = nil
  if presets and presets.get_by_id and preset_id ~= "" then
    local p = presets.get_by_id(preset_id)
    if p and p.opts then
      preset_opts = p.opts
    end
  end

  if preset_opts then
    mode     = preset_opts.mode     or mode
    target   = preset_opts.target   or target
    category = preset_opts.category or category

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

  last = string.format("%s,%s,%s,%s,%s,%s,%s",
                       mode, target, category, role, source, fxflavor, dest)
end

  local cap = "Mode(ALL_SLICES/SELECTED_SLICES/SELECTED_SLICES_SUM/LOOP_TIMESEL)," ..
              "Target(ORIGINAL/ZOOM96_32F/SPLICE_44_24/LOOPMASTERS_44_24/ADSR_44_24)," ..
              "Category,Role,Source,FXFlavor,DestRoot(empty=DF95_EXPORT in project)," ..\
              "UCS_CatID(optional),UCS_FXName(optional),UCS_CreatorID(optional),UCS_SourceID(optional)"

  local ok, ret = r.GetUserInputs("DF95 Export Wizard (Tag-aware)", 1, cap..":", last)
  if not ok or not ret or ret == "" then return end
  r.SetExtState("DF95_EXPORT", "wizard_tags", ret, true)

  -- Versuche zuerst, alle UCS-Felder mitzulesen (11 Felder)
  local mode, target, category, role, source, fxflavor, dest_root,
        ucs_catid, ucs_fxname, ucs_creatorid, ucs_sourceid =
    ret:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")

  -- Fallback auf Legacy-Format (7 Felder), wenn kein vollständiges Match
  if not mode then
    mode, target, category, role, source, fxflavor, dest_root =
      ret:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")
  end

  if not mode or not target or not category or not role or not source or not fxflavor or dest_root == nil then
    msg("Eingabe nicht erkannt.\nErwartet: Mode,Target,Category,Role,Source,FXFlavor,DestRoot[,UCS_CatID,UCS_FXName,UCS_CreatorID,UCS_SourceID]")
    return
  end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  mode         = trim(mode)
  target       = trim(target)
  category     = trim(category)
  role         = trim(role)
  source       = trim(source)
  fxflavor     = trim(fxflavor)
  dest_root    = trim(dest_root)
  ucs_catid    = trim(ucs_catid or "")
  ucs_fxname   = trim(ucs_fxname or "")
  ucs_creatorid= trim(ucs_creatorid or "")
  ucs_sourceid = trim(ucs_sourceid or "")

  local opts = {
    mode         = mode,
    target       = target,
    category     = category,
    role         = role,
    source       = source,
    fxflavor     = fxflavor,
    dest_root    = dest_root ~= "" and dest_root or nil,
    ucs_catid    = ucs_catid ~= "" and ucs_catid or nil,
    ucs_fxname   = ucs_fxname ~= "" and ucs_fxname or nil,
    ucs_creatorid= ucs_creatorid ~= "" and ucs_creatorid or nil,
    ucs_sourceid = ucs_sourceid ~= "" and ucs_sourceid or nil,
  }

  core.run(opts)
end

main()
