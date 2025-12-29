-- @description Export UCS Helper (preset UCS CatID/FXName/Creator/Source for Export Wizard)
-- @version 1.0
-- @author DF95

-- Dieses Script hilft dabei, UCS-Felder (CatID, FXName, CreatorID, SourceID)
-- vorzubelegen und in DF95_EXPORT/wizard_tags zu speichern,
-- so dass der DF95 Export Wizard diese als Default übernimmt.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function load_ucs_defaults()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local path = (res .. sep .. "Data" .. sep .. "DF95" .. sep .. "DF95_Export_UCSDefaults_v1.json"):gsub("\\","/")
  local f = io.open(path, "rb")
  if not f then return nil end
  local txt = f:read("*a")
  f:close()
  if not txt or txt == "" or not r.JSONDecode then return nil end
  local ok, obj = pcall(function() return r.JSONDecode(txt) end)
  if not ok or type(obj) ~= "table" then return nil end
  return obj
end

local function get_project_name()
  local _, projfn = r.EnumProjects(-1, "")
  if not projfn or projfn == "" then return "DF95_Project" end
  local name = projfn:match("([^/\\]+)%.rpp$") or projfn
  return name
end

local function load_ucs_artist()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local path = (res .. sep .. "Data" .. sep .. "DF95" .. sep .. "DF95_Export_UCSArtistProfiles_v1.json"):gsub("\\","/")
  local f = io.open(path, "rb")
  if not f then return nil end
  local txt = f:read("*a")
  f:close()
  if not txt or txt == "" or not r.JSONDecode then return nil end
  local ok, obj = pcall(function() return r.JSONDecode(txt) end)
  if not ok or type(obj) ~= "table" then return nil end
  return obj
end

local function main()
  local core
  do
    local ok, mod_or_err = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
    if ok and type(mod_or_err) == "table" then
      core = mod_or_err
    end
  end

  -- hole letzte Wizard-Eingabe (Legacy-Muster)
  local last = r.GetExtState("DF95_EXPORT", "wizard_tags")
  if last == "" then
    local role     = core and core.GetExportTag and core.GetExportTag("Role", "Any")         or "Any"
    local source   = core and core.GetExportTag and core.GetExportTag("Source", "Any")       or "Any"
    local fxflavor = core and core.GetExportTag and core.GetExportTag("FXFlavor", "Generic") or "Generic"

    local mode     = "SELECTED_SLICES_SUM"
    local target   = "ORIGINAL"
    local category = "Slices_Master"
    local dest     = ""
    last = string.format("%s,%s,%s,%s,%s,%s,%s", mode, target, category, role, source, fxflavor, dest)
  end

  local mode, target, category, role, source, fxflavor, dest_root =
    last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")

  if not mode then
    r.ShowMessageBox("Konnte die bestehenden Wizard-Tags nicht parsen.\nBitte einmal den DF95 Export Wizard normal ausführen, dann erneut versuchen.",
      "DF95 Export UCS Helper", 0)
    return
  end

  local ucs_cfg = load_ucs_defaults() or {}
  local defs    = ucs_cfg.defaults or {}
  local examples= ucs_cfg.examples or {}

  local proj_name   = get_project_name()

  -- Artist-bezogene UCS-Defaults laden (falls vorhanden)
  local artist_cfg = load_ucs_artist()
  local artist_map = artist_cfg and artist_cfg.artists or {}
  local current_artist = core and core.GetExportTag and core.GetExportTag("Artist", "") or ""
  local artist_profile = current_artist ~= "" and artist_map[current_artist] or nil

  if artist_profile then
    -- Wenn Artist-spezifische Defaults existieren, Role/Source/FXFlavor überschreiben
    role     = artist_profile.role     or role
    source   = artist_profile.source   or source
    fxflavor = artist_profile.fxflavor or fxflavor
  end

  local default_cat = ""
  local suggestions = {}

  for i, ex in ipairs(examples) do
    if ex.catid and ex.category then
      suggestions[#suggestions+1] = ex.catid .. " (" .. ex.category .. (ex.subcategory and ("/"..ex.subcategory) or "") .. ")"
      if default_cat == "" then
        default_cat = ex.catid
      end
    end
  end

  local default_creator = defs.creator_id or "DF95"
  local default_source  = defs.default_source_id or proj_name

  if defs.use_artist_as_creator and core and core.GetExportTag then
    local artist = core.GetExportTag("Artist", "")
    if artist and artist ~= "" then
      default_creator = artist
    end
  end

  local ucs_catid    = default_cat
  local ucs_fxname   = category .. "_" .. (role ~= "" and role or "Any")
  local ucs_creator  = default_creator
  local ucs_sourceid = default_source

  local cap = "UCS_CatID(optional),UCS_FXName(optional),UCS_CreatorID(optional),UCS_SourceID(optional). " ..
              "CatID Vorschläge: " .. table.concat(suggestions, " | ")

  local ok, inp = r.GetUserInputs("DF95 Export UCS Helper", 4, cap .. ",extrawidth=200",
    string.format("%s,%s,%s,%s", ucs_catid, ucs_fxname, ucs_creator, ucs_sourceid))

  if not ok or not inp or inp == "" then return end

  local catid_in, fxname_in, creator_in, source_in =
    inp:match("^(.-),(.-),(.-),(.-)$")
  if not catid_in then return end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  catid_in   = trim(catid_in)
  fxname_in  = trim(fxname_in)
  creator_in = trim(creator_in)
  source_in  = trim(source_in)

  -- baue neuen Wizard-String mit 11 Feldern
  local new_wizard = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",
    trim(mode), trim(target), trim(category), trim(role), trim(source), trim(fxflavor), trim(dest_root or ""),
    catid_in, fxname_in, creator_in, source_in)

  r.SetExtState("DF95_EXPORT", "wizard_tags", new_wizard, true)

  r.ShowMessageBox("UCS-Felder gesetzt.\nStarte jetzt den DF95 Export Wizard – die Felder sind vorausgefüllt.",
    "DF95 Export UCS Helper", 0)
end

main()