-- @description Export Master Button (Target -> UCS -> Export)
-- @version 1.0
-- @author DF95

-- Ablauf:
-- 1) Fragt das Export-Target ab (ORIGINAL / ZOOM96_32F / SPLICE_44_24 / LOOPMASTERS_44_24 / ADSR_44_24 / CIRCUIT_RHYTHM_48_16)
-- 2) Aktualisiert DF95_EXPORT/wizard_tags mit dem gewählten Target
-- 3) Startet DF95_Export_UCS_ImGui.lua, wo:
--      - Mode/Category/Role/Source/FXFlavor/DestRoot/UCS-Felder einstellbar sind
--      - "Run Export" den eigentlichen Export über DF95_Export_Core.run(opts) ausführt

local r = reaper

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

local function parse_wizard(last)
  if not last or last == "" then return nil end

  local mode, target, category, role, source, fxflavor, dest_root,
        ucs_catid, ucs_fxname, ucs_creatorid, ucs_sourceid =
    last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")

  local eleven = true
  if not mode then
    eleven = false
    mode, target, category, role, source, fxflavor, dest_root =
      last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")
  end

  if not mode then return nil end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  return {
    eleven      = eleven,
    mode        = trim(mode),
    target      = trim(target),
    category    = trim(category),
    role        = trim(role),
    source      = trim(source),
    fxflavor    = trim(fxflavor),
    dest_root   = trim(dest_root or ""),
    ucs_catid   = trim(ucs_catid or ""),
    ucs_fxname  = trim(ucs_fxname or ""),
    ucs_creatorid = trim(ucs_creatorid or ""),
    ucs_sourceid  = trim(ucs_sourceid or ""),
  }
end

local function save_wizard(cfg)
  local function nz(s) return s or "" end
  local val = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",
    nz(cfg.mode), nz(cfg.target), nz(cfg.category), nz(cfg.role), nz(cfg.source),
    nz(cfg.fxflavor), nz(cfg.dest_root),
    nz(cfg.ucs_catid), nz(cfg.ucs_fxname), nz(cfg.ucs_creatorid), nz(cfg.ucs_sourceid))
  r.SetExtState("DF95_EXPORT", "wizard_tags", val, true)
end

local function ensure_default_wizard()
  local last = r.GetExtState("DF95_EXPORT", "wizard_tags")
  if last ~= "" then
    local cfg = parse_wizard(last)
    if cfg then return cfg end
  end

  local core = get_export_core()
  local role     = core and core.GetExportTag and core.GetExportTag("Role", "Any")         or "Any"
  local source   = core and core.GetExportTag and core.GetExportTag("Source", "Any")       or "Any"
  local fxflavor = core and core.GetExportTag and core.GetExportTag("FXFlavor", "Generic") or "Generic"

  local cfg = {
    mode        = "SELECTED_SLICES_SUM",
    target      = "ORIGINAL",
    category    = "Slices_Master",
    role        = role,
    source      = source,
    fxflavor    = fxflavor,
    dest_root   = "",
    ucs_catid   = "",
    ucs_fxname  = "",
    ucs_creatorid = "",
    ucs_sourceid  = "",
  }
  save_wizard(cfg)
  return cfg
end

local function pick_target(cfg)
  local title = "DF95 Export – Target wählen"
  local cap   = "Target(ORIGINAL/ZOOM96_32F/SPLICE_44_24/LOOPMASTERS_44_24/ADSR_44_24/CIRCUIT_RHYTHM_48_16)"
  local def   = cfg.target or "ORIGINAL"

  local ok, ret = r.GetUserInputs(title, 1, cap .. ",extrawidth=160", def)
  if not ok or not ret or ret == "" then return nil end

  local target = ret:match("^(.-)$") or def
  target = target:gsub("^%s+",""):gsub("%s+$","")

  if target == "" then target = def end
  cfg.target = target
  save_wizard(cfg)
  return cfg
end

local function launch_ucs_gui()
  local ok, err = pcall(dofile, df95_root() .. "DF95_Export_UCS_ImGui.lua")
  if not ok then
    r.ShowMessageBox("Fehler beim Starten von DF95_Export_UCS_ImGui.lua:\n"..tostring(err),
      "DF95 Export Master Button", 0)
  end
end

local function main()
  local cfg = ensure_default_wizard()
  local new_cfg = pick_target(cfg)
  if not new_cfg then return end

  -- UCS-GUI starten; dort können UCS-Felder und restliche Tags angepasst werden
  launch_ucs_gui()
end

main()
