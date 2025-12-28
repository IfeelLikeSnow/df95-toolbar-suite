-- @description Export UCS Browser (ImGui)
-- @version 1.0
-- @author DF95

-- Ein einfacher UCS-Browser:
-- - Listet CatID / Category / Subcategory / Description aus DF95_Export_UCSDefaults_v1.json
-- - Suchfeld (Filter)
-- - Klick auf eine Zeile schreibt:
--     DF95_EXPORT/UCS_CatID_SELECTED
--   und aktualisiert DF95_EXPORT/wizard_tags (falls vorhanden)
-- - So kann der DF95 Export Wizard und DF95_Export_UCS_ImGui die Auswahl übernehmen.

local r = reaper

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

local function apply_catid_to_wizard(catid)
  if not catid or catid == "" then return end
  local last = r.GetExtState("DF95_EXPORT", "wizard_tags")
  if last == "" then return end

  -- Versuche sowohl 11-Feld (mit UCS) als auch 7-Feld (legacy) zu parsen
  local mode, target, category, role, source, fxflavor, dest_root,
        ucs_catid, ucs_fxname, ucs_creatorid, ucs_sourceid =
    last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")

  local eleven = true
  if not mode then
    eleven = false
    mode, target, category, role, source, fxflavor, dest_root =
      last:match("^(.-),(.-),(.-),(.-),(.-),(.-),(.-)$")
  end
  if not mode then return end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  mode      = trim(mode)
  target    = trim(target)
  category  = trim(category)
  role      = trim(role)
  source    = trim(source)
  fxflavor  = trim(fxflavor)
  dest_root = trim(dest_root or "")

  if eleven then
    ucs_catid    = trim(catid)
    ucs_fxname   = trim(ucs_fxname or "")
    ucs_creatorid= trim(ucs_creatorid or "")
    ucs_sourceid = trim(ucs_sourceid or "")
  else
    ucs_catid    = trim(catid)
    ucs_fxname   = ""
    ucs_creatorid= ""
    ucs_sourceid = ""
  end

  local new_val = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",
    mode, target, category, role, source, fxflavor, dest_root,
    ucs_catid, ucs_fxname, ucs_creatorid, ucs_sourceid)

  r.SetExtState("DF95_EXPORT", "wizard_tags", new_val, true)
  r.SetExtState("DF95_EXPORT", "UCS_CatID_SELECTED", catid, true)
end

------------------------------------------------------------
-- ImGui
------------------------------------------------------------

local ctx = r.ImGui_CreateContext("DF95 UCS Browser", 0)
local ucs_cfg = load_ucs_defaults() or {}
local ucs_examples = ucs_cfg.examples or {}

local filter_text = ""
local open = true

local function loop()
  if not r.ImGui_ValidatePtr(ctx, "ImGui_Context*") then return end

  r.ImGui_SetNextWindowSize(ctx, 640, 480, r.ImGui_Cond_FirstUseEver())
  local visible
  visible, open = r.ImGui_Begin(ctx, "DF95 UCS Browser", true, 0)

  if visible then
    r.ImGui_Text(ctx, "DF95 UCS Browser")
    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Filter:")
    r.ImGui_SameLine(ctx)
    local changed
    changed, filter_text = r.ImGui_InputText(ctx, "##filter", filter_text)

    r.ImGui_Separator(ctx)

    r.ImGui_Columns(ctx, 4, "ucs_cols", true)
    r.ImGui_Text(ctx, "CatID");       r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, "Category");    r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, "Subcategory"); r.ImGui_NextColumn(ctx)
    r.ImGui_Text(ctx, "Description"); r.ImGui_NextColumn(ctx)
    r.ImGui_Separator(ctx)

    local filter = (filter_text or ""):lower()

    for _, ex in ipairs(ucs_examples) do
      local catid = ex.catid or ""
      local cat   = ex.category or ""
      local sub   = ex.subcategory or ""
      local desc  = ex.description or ""

      local row = (catid .. " " .. cat .. " " .. sub .. " " .. desc):lower()
      if filter == "" or row:find(filter, 1, true) then
        if r.ImGui_Selectable(ctx, catid, false, r.ImGui_SelectableFlags_SpanAllColumns() or 0) then
          apply_catid_to_wizard(catid)
        end
        r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, cat);  r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, sub);  r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, desc); r.ImGui_NextColumn(ctx)
      end
    end

    r.ImGui_Columns(ctx, 1)
    r.ImGui_Separator(ctx)

    if r.ImGui_Button(ctx, "Close", 80, 24) then
      open = false
    end

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
