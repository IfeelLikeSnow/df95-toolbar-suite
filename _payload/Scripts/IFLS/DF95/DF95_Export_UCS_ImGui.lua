-- @description Export UCS ImGui (UCS-aware Export Frontend)
-- @version 1.0
-- @author DF95

-- Ein kleiner ImGui-Frontend für DF95_Export_Core:
-- - Mode / Target / Category / Role / Source / FXFlavor / DestRoot
-- - UCS-CatID / FXName / CreatorID / SourceID
-- - Dropdown von Beispielen aus DF95_Export_UCSDefaults_v1.json
-- - Live-Preview des UCS-Dateinamens
-- - "Run Export" ruft DF95_Export_Core.run(opts) direkt auf.

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

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


local function load_ucs_artist()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local path = (res .. sep .. "Data" .. "DF95" .. sep .. "DF95_Export_UCSArtistProfiles_v1.json"):gsub("\\","/")
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

local function get_export_core()
  local ok, mod_or_err = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  if not ok then
    r.ShowMessageBox("Fehler beim Laden von DF95_Export_Core.lua:\n"..tostring(mod_or_err),
      "DF95 Export UCS ImGui", 0)
    return nil
  end
  if type(mod_or_err) ~= "table" or type(mod_or_err.run) ~= "function" then
    r.ShowMessageBox("DF95_Export_Core.lua liefert kein Modul mit .run(opts).",
      "DF95 Export UCS ImGui", 0)
    return nil
  end
  return mod_or_err
end

local function sanitize_filename_part(s)
  if not s or s == "" then return "" end
  s = s:gsub("[%^%/%\\%:%*%?%\"%<%>%|]", "_")
  s = s:gsub("%s+", "_")
  return s
end

local function build_ucs_preview(opts, proj_name)
  local catid      = sanitize_filename_part(opts.ucs_catid or "")
  local fxname     = sanitize_filename_part(opts.ucs_fxname or "")
  local creator_id = sanitize_filename_part(opts.ucs_creatorid or "")
  local source_id  = sanitize_filename_part(opts.ucs_sourceid or proj_name)

  if catid == "" then return "(kein UCS-CatID gesetzt – Legacy-DF95-Naming wird genutzt)" end

  if fxname == "" then
    fxname = sanitize_filename_part((opts.category or "FX") .. "_" .. (opts.role or "Any"))
  end
  if creator_id == "" then creator_id = "DF95" end
  if source_id == "" then source_id = proj_name end

  local fname = string.format("%s_%s_%s_%s", catid, fxname, creator_id, source_id)
  return fname .. ".wav"
end

------------------------------------------------------------
-- ImGui State
------------------------------------------------------------

local ctx = r.ImGui_CreateContext("DF95 Export UCS ImGui", r.ImGui_ConfigFlags_DockingEnable() or 0)

local state = {
  mode      = "SELECTED_SLICES_SUM",
  target    = "SPLICE_44_24",
  category  = "Slices_Master",
  role      = "Any",
  source    = "Any",
  fxflavor  = "Generic",
  dest_root = "",
  ucs_catid    = "",
  ucs_fxname   = "",
  ucs_creatorid= "",
  ucs_sourceid = "",
  example_idx  = 1,
}

local ucs_cfg = load_ucs_defaults() or {}
local ucs_defs = ucs_cfg.defaults or {}
local ucs_examples = ucs_cfg.examples or {}

do
  local proj_name = get_project_name()
  state.ucs_creatorid = ucs_defs.creator_id or "DF95"
  state.ucs_sourceid  = ucs_defs.default_source_id or proj_name

  local core = get_export_core()
  local artist = ""
  if core and core.GetExportTag then
    artist = core.GetExportTag("Artist", "") or ""
  end

  -- Artist-bezogene UCS-Defaults
  local artist_cfg = load_ucs_artist()
  local artist_map = artist_cfg and artist_cfg.artists or {}
  local artist_profile = artist ~= "" and artist_map[artist] or nil
  if artist_profile then
    state.role     = artist_profile.role     or state.role
    state.source   = artist_profile.source   or state.source
    state.fxflavor = artist_profile.fxflavor or state.fxflavor
    state.ucs_catid= artist_profile.ucs_catid or state.ucs_catid
  end

  if ucs_defs.use_artist_as_creator and artist ~= "" then
    state.ucs_creatorid = artist
  end

  if #ucs_examples > 0 and (state.ucs_catid == "" or not state.ucs_catid) then
    state.ucs_catid = ucs_examples[1].catid or ""
  end
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------

local function loop()
  if not r.ImGui_ValidatePtr(ctx, "ImGui_Context*") then return end

  r.ImGui_SetNextWindowSize(ctx, 520, 420, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 Export UCS", true,
    r.ImGui_WindowFlags_NoCollapse() or 0)

  if visible then
    local proj_name = get_project_name()

    r.ImGui_Text(ctx, "DF95 Export – UCS Frontend")
    r.ImGui_Separator(ctx)

    -- Mode & Target
    r.ImGui_Text(ctx, "Mode / Target")
    r.ImGui_SameLine(ctx)
    _, state.mode = r.ImGui_InputText(ctx, "Mode", state.mode)
    _, state.target = r.ImGui_InputText(ctx, "Target", state.target)

    -- Category / Role / Source / FXFlavor
    r.ImGui_Text(ctx, "Tags")
    _, state.category  = r.ImGui_InputText(ctx, "Category", state.category)
    _, state.role      = r.ImGui_InputText(ctx, "Role", state.role)
    _, state.source    = r.ImGui_InputText(ctx, "Source", state.source)
    _, state.fxflavor  = r.ImGui_InputText(ctx, "FXFlavor", state.fxflavor)
    _, state.dest_root = r.ImGui_InputText(ctx, "DestRoot (empty=DF95_EXPORT in project)", state.dest_root)

    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "UCS-Felder")

    -- UCS Example dropdown
    if #ucs_examples > 0 then
      local current = ucs_examples[state.example_idx] or ucs_examples[1]
      local preview = string.format("%s (%s/%s)", current.catid or "?", current.category or "?", current.subcategory or "?")
      if r.ImGui_BeginCombo(ctx, "UCS CatID Presets", preview) then
        for i, ex in ipairs(ucs_examples) do
          local label = string.format("%s (%s/%s)", ex.catid or "?", ex.category or "?", ex.subcategory or "?")
          local selected = (i == state.example_idx)
          if r.ImGui_Selectable(ctx, label, selected) then
            state.example_idx = i
            state.ucs_catid = ex.catid or state.ucs_catid
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end
    end

    _, state.ucs_catid     = r.ImGui_InputText(ctx, "UCS CatID", state.ucs_catid)
    _, state.ucs_fxname    = r.ImGui_InputText(ctx, "UCS FXName", state.ucs_fxname)
    _, state.ucs_creatorid = r.ImGui_InputText(ctx, "UCS CreatorID", state.ucs_creatorid)
    _, state.ucs_sourceid  = r.ImGui_InputText(ctx, "UCS SourceID", state.ucs_sourceid)

    r.ImGui_Separator(ctx)

    local preview = build_ucs_preview(state, proj_name)
    r.ImGui_Text(ctx, "Filename Preview (UCS):")
    r.ImGui_BulletText(ctx, preview)

    r.ImGui_Separator(ctx)

    if r.ImGui_Button(ctx, "Run Export", 120, 24) then
      local core = get_export_core()
      if core then
        local opts = {
          mode         = state.mode,
          target       = state.target,
          category     = state.category,
          role         = state.role,
          source       = state.source,
          fxflavor     = state.fxflavor,
          dest_root    = state.dest_root ~= "" and state.dest_root or nil,
          ucs_catid    = state.ucs_catid ~= "" and state.ucs_catid or nil,
          ucs_fxname   = state.ucs_fxname ~= "" and state.ucs_fxname or nil,
          ucs_creatorid= state.ucs_creatorid ~= "" and state.ucs_creatorid or nil,
          ucs_sourceid = state.ucs_sourceid ~= "" and state.ucs_sourceid or nil,
        }

        -- auch Wizard-ExtState aktualisieren, damit Export Wizard synchron ist
        local wiz_str = string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",
          opts.mode or "",
          opts.target or "",
          opts.category or "",
          opts.role or "",
          opts.source or "",
          opts.fxflavor or "",
          opts.dest_root or "",
          opts.ucs_catid or "",
          opts.ucs_fxname or "",
          opts.ucs_creatorid or "",
          opts.ucs_sourceid or "")

        r.SetExtState("DF95_EXPORT", "wizard_tags", wiz_str, true)

        core.run(opts)

        -- Auto-Post-Export: Metadata-CSV im Default-Exportordner erzeugen
        r.SetExtState("DF95_EXPORT", "AUTO_CSV_DEFAULTFOLDER", "1", false)
        pcall(dofile, df95_root() .. "DF95_Export_Metadata_CSV_FromTags.lua")
      end
    end

    r.ImGui_SameLine(ctx)
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
