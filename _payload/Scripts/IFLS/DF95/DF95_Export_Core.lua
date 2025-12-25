-- @description Export Core (Slices & Loops, post Master, Tag-aware)
-- @version 1.2
-- @author DF95
-- @about
--   Kernfunktionen zum Exportieren von:
--     - Slices (Items) nach dem Master
--     - Loops (Time Selection) nach dem Master
--   Unterstützt verschiedene Zielformate (Targets) & Naming-Styles (incl. UCS CatID_FXName_CreatorID_SourceID):
--   Targets:
--     - ORIGINAL (Projektformat)
--     - ZOOM96_32F
--     - SPLICE_44_24
--     - LOOPMASTERS_44_24
--     - ADSR_44_24
--
--   Modus:
--     - ALL_SLICES:
--         Alle Items auf selektierten Tracks, jeweils einzeln als Master-Summe.
--     - SELECTED_SLICES:
--         Jede selektierte Slice einzeln als Master-Summe.
--     - SELECTED_SLICES_SUM:
--         Selektierte Slices werden nach Start/Ende gruppiert;
--         pro Gruppe ein Render (Summe aller Tracks/Mics über den Master).
--     - LOOP_TIMESEL:
--         Aktuelle Time Selection als Loop exportieren (Master-Summe).
--
--   Tags / Naming:
--     - Neben Category/Subtype können zusätzliche Tags gesetzt werden:
--         Role      (Kick, Snare, Hat, Perc, ClicksPops, Synth, Atmos, ...)
--         Source    (MobileFR, ZoomF6, Studio, DrumMachine, Synth, ...)
--         FXFlavor  (Clean, Safe, BusIDM, IDMGlitch, LoFiTape, Extreme, ...)
--     - Tags können über:
--         * opts.role / opts.source / opts.fxflavor
--         * oder ExtStates "DF95_EXPORT_TAGS" (Role/Source/FXFlavor)
--       gesetzt werden.
--     - Diese Tags erscheinen im Ordner- und Dateinamen.

local r = reaper
local M = {}

------------------------------------------------------------
-- Tag-Helpers (öffentlich nutzbar von anderen DF95-Scripts)
------------------------------------------------------------

function M.SetExportTag(key, value)
  if not key then return end
  r.SetExtState("DF95_EXPORT_TAGS", tostring(key), tostring(value or ""), true)
end

function M.GetExportTag(key, default)
  if not key then return default end
  local v = r.GetExtState("DF95_EXPORT_TAGS", tostring(key))
  if v == nil or v == "" then return default end
  return v
end

local function auto_guess_tags_from_context(opts)
  -- Versuche, aus Category/Subtype/anderen Infos sinnvolle Defaults abzuleiten.
  -- Nutzt DF95_Export_TagProfiles.lua, falls vorhanden.
  opts = opts or {}
  local ok, TagProfiles = pcall(function()
    local info = debug.getinfo(1, "S")
    local script_path = info and info.source:match("^@(.+)$")
    if not script_path then return nil end
    local dir = script_path:match("^(.*[\\/])") or ""
    return dofile(dir .. "DF95_Export_TagProfiles.lua")
  end)
  if not ok or not TagProfiles or type(TagProfiles.guess_from_name) ~= "function" then
    return "Any", "Generic"
  end

  local name_parts = {}
  if opts.category and opts.category ~= "" then table.insert(name_parts, opts.category) end
  if opts.subtype  and opts.subtype  ~= "" then table.insert(name_parts, opts.subtype)  end

  -- Optional: weitere kontextbezogene Namen ergänzen (z.B. erste Track-Bezeichnung)
  -- Bei Bedarf später erweiterbar.

  local query = table.concat(name_parts, "_")
  if query == "" then
    query = "DF95"
  end

  local role, fxflavor = TagProfiles.guess_from_name(query)
  if not role or role == "" then role = "Any" end
  if not fxflavor or fxflavor == "" then fxflavor = "Generic" end
  return role, fxflavor
end

local function get_effective_tags(opts)
  opts = opts or {}

  -- 1) Explizit übergebene Werte (Wizard/Pipeline)
  local role     = opts.role
  local source   = opts.source
  local fxflavor = opts.fxflavor

  -- 2) ExtStates (FXBus-Selector, DrumFX, Synth-Builder, Tag-Panel)
  if not role or role == "" then
    role = M.GetExportTag("Role", nil)
  end
  if not source or source == "" then
    source = M.GetExportTag("Source", nil)
  end
  if not fxflavor or fxflavor == "" then
    fxflavor = M.GetExportTag("FXFlavor", nil)
  end

  -- 3) Kontext-basierte Auto-Erkennung (nur Role/FXFlavor)
  if not role or role == "" or role == "Any"
     or not fxflavor or fxflavor == "" or fxflavor == "Generic" then
    local auto_role, auto_fx = auto_guess_tags_from_context(opts)
    if not role or role == "" or role == "Any" then
      role = auto_role
    end
    if not fxflavor or fxflavor == "" or fxflavor == "Generic" then
      fxflavor = auto_fx
    end
  end

  -- 4) Fallbacks
  if not role or role == "" then role = "Any" end
  if not source or source == "" then source = "Any" end
  if not fxflavor or fxflavor == "" then fxflavor = "Generic" end

  return role, source, fxflavor
end

------------------------------------------------------------
-- Helpers: Projekt-Infos &
-- Helpers: Projekt-Infos & Render-Einstellungen
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Export Core", 0)
end

local function get_project()
  return 0 -- current project
end

local function get_project_path_and_name()
  local proj = get_project()
  local buf = string.rep(" ", 512)
  r.EnumProjects(-1, buf, 512)
  local proj_path = buf:match("([^\0]+)")
  local proj_dir = r.GetProjectPath("")
  local proj_name = proj_path and proj_path:match("([^/\\]+)%.rpp$") or "Untitled"
  return proj_dir, proj_name
end

local function get_tempo_bpm()
  local bpm = r.Master_GetTempo()
  return math.floor((bpm or 120) + 0.5)
end

-- Render-Einstellungen sichern/wiederherstellen
local function save_render_settings()
  local proj = get_project()
  local s = {}

  local function gss(key)
    local _, val = r.GetSetProjectInfo_String(proj, key, "", false)
    return val
  end

  s.RENDER_FILE      = gss("RENDER_FILE")
  s.RENDER_PATTERN   = gss("RENDER_PATTERN")
  s.RENDER_BOUNDS    = gss("RENDER_BOUNDSFLAG")
  s.RENDER_SRATE     = gss("RENDER_SRATE")
  s.RENDER_SRATE_USE = gss("RENDER_SRATE_USE")
  s.RENDER_BPS       = gss("RENDER_BPS")
  s.RENDER_CHANNELS  = gss("RENDER_CHANNELS")
  s.RENDER_DITHER    = gss("RENDER_DITHER")
  s.RENDER_ADDTOPRJ  = gss("RENDER_ADDTOPROJ")
  s.RENDER_STEMS     = gss("RENDER_STEMS")

  return s
end

local function restore_render_settings(saved)
  if not saved then return end
  local proj = get_project()
  local function sss(key, val)
    r.GetSetProjectInfo_String(proj, key, val or "", true)
  end

  sss("RENDER_FILE",       saved.RENDER_FILE)
  sss("RENDER_PATTERN",    saved.RENDER_PATTERN)
  sss("RENDER_BOUNDSFLAG", saved.RENDER_BOUNDS)
  sss("RENDER_SRATE",      saved.RENDER_SRATE)
  sss("RENDER_SRATE_USE",  saved.RENDER_SRATE_USE)
  sss("RENDER_BPS",        saved.RENDER_BPS)
  sss("RENDER_CHANNELS",   saved.RENDER_CHANNELS)
  sss("RENDER_DITHER",     saved.RENDER_DITHER)
  sss("RENDER_ADDTOPROJ",  saved.RENDER_ADDTOPRJ)
  sss("RENDER_STEMS",      saved.RENDER_STEMS)
end

-- Projekt-Sample-Format
local function get_project_sample_format()
  local proj = get_project()
  local srate = r.GetSetProjectInfo(proj, "PROJECT_SRATE", 0, false)
  local srate_use = r.GetSetProjectInfo(proj, "PROJECT_SRATE_USE", 0, false)
  if srate_use == 0 or srate <= 0 then
    local _, sr_str = r.GetSetProjectInfo_String(proj, "RENDER_SRATE", "", false)
    local sr_num = tonumber(sr_str) or 0
    if sr_num > 0 then srate = sr_num end
  end
  if srate <= 0 then srate = 48000 end

  local bps_num = r.GetSetProjectInfo(proj, "RENDER_BPS", 0, false)
  if bps_num <= 0 then
    bps_num = 24
  end

  return srate, math.floor(bps_num + 0.5)
end

------------------------------------------------------------
-- Zielformate / Portale
------------------------------------------------------------

local function apply_target_format(target)
  local proj = get_project()
  local srate, bps = get_project_sample_format()

  local out_srate = srate
  local out_bps   = bps

  if target == "ZOOM96_32F" then
    out_srate = 96000
    out_bps   = 3 -- REAPER: 3 = 32-bit float
  elseif target == "SPLICE_44_24"
      or target == "LOOPMASTERS_44_24"
      or target == "ADSR_44_24" then
    out_srate = 44100
    out_bps   = 24
  elseif target == "ORIGINAL" then
    -- Projektformat beibehalten
  end

  r.GetSetProjectInfo_String(proj, "RENDER_SRATE", tostring(out_srate), true)
  r.GetSetProjectInfo_String(proj, "RENDER_SRATE_USE", "1", true)
  r.GetSetProjectInfo_String(proj, "RENDER_BPS", tostring(out_bps), true)
  r.GetSetProjectInfo_String(proj, "RENDER_CHANNELS", "2", true)
  r.GetSetProjectInfo_String(proj, "RENDER_DITHER", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_ADDTOPROJ", "0", true)
  r.GetSetProjectInfo_String(proj, "RENDER_STEMS", "0", true)
end

------------------------------------------------------------
-- Zeitbereich / Items
------------------------------------------------------------

local function set_time_selection(start_time, end_time)
  r.GetSet_LoopTimeRange(true, false, start_time, end_time, false)
end

local function get_item_bounds(item)
  local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  return pos, pos + len
end

local function get_selected_items()
  local t = {}
  local cnt = r.CountSelectedMediaItems(0)
  for i = 0, cnt-1 do
    t[#t+1] = r.GetSelectedMediaItem(0, i)
  end
  return t
end

local function get_all_items_on_selected_tracks()
  local t = {}
  local sel_tr_cnt = r.CountSelectedTracks(0)
  for ti = 0, sel_tr_cnt-1 do
    local tr = r.GetSelectedTrack(0, ti)
    local icnt = r.CountTrackMediaItems(tr)
    for ii = 0, icnt-1 do
      t[#t+1] = r.GetTrackMediaItem(tr, ii)
    end
  end
  return t
end

-- Gruppen nach Zeit (für SELECTED_SLICES_SUM)
local function group_items_by_time(items, tol)
  tol = tol or 0.001
  local groups = {}
  for _, item in ipairs(items) do
    local s, e = get_item_bounds(item)
    local placed = false
    for _, g in ipairs(groups) do
      if math.abs(g.start - s) <= tol and math.abs(g["end"] - e) <= tol then
        table.insert(g.items, item)
        placed = true
        break
      end
    end
    if not placed then
      groups[#groups+1] = { start = s, ["end"] = e, items = { item } }
    end
  end
  table.sort(groups, function(a, b) return a.start < b.start end)
  return groups
end

------------------------------------------------------------
-- Render-Call
------------------------------------------------------------

local function set_render_bounds_time_selection()
  local proj = get_project()
  r.GetSetProjectInfo_String(proj, "RENDER_BOUNDSFLAG", "1", true) -- 1 = Time selection
end

local function set_render_file_base(path_no_ext)
  local proj = get_project()
  r.GetSetProjectInfo_String(proj, "RENDER_FILE", path_no_ext, true)
end

local function trigger_render()
  r.Main_OnCommand(41824, 0) -- auto-render
end

------------------------------------------------------------
-- Naming (mit Tags)
------------------------------------------------------------

local function sanitize_filename_part(s)
  s = s or ""
  s = s:gsub("[^%w%-%_]+", "_")
  s = s:gsub("_+", "_")
  return s
end

local function build_base_path(dest_root, proj_name, category, subtype, bpm, index, tags)
  local sep = package.config:sub(1,1)
  local cat  = sanitize_filename_part(category)
  local sub  = sanitize_filename_part(subtype or "")
  local role     = sanitize_filename_part(tags.role or "Any")
  local source   = sanitize_filename_part(tags.source or "Any")
  local fxflavor = sanitize_filename_part(tags.fxflavor or "Generic")

  local base_dir = dest_root .. sep .. proj_name .. "_" .. os.date("%Y%m%d")

  local tag_str = role .. "_" .. source .. "_" .. fxflavor
  local subfolder = cat
  if sub ~= "" then
    subfolder = cat .. "_" .. sub
  end
  subfolder = subfolder .. "_" .. tag_str

  local dir = base_dir .. sep .. subfolder
  r.RecursiveCreateDirectory(dir, 0)

  local idx_str = string.format("%03d", index or 1)
  local bpm_str = tostring(bpm or get_tempo_bpm())

  -- UCS Naming override: if a CatID is provided, build name as
  --   CatID_FXName_CreatorID_SourceID
  if tags.ucs_catid and tags.ucs_catid ~= "" then
    local catid      = sanitize_filename_part(tags.ucs_catid)
    local fxname     = sanitize_filename_part(tags.ucs_fxname or (category .. "_" .. bpm_str .. "bpm_" .. idx_str))
    local creator_id = sanitize_filename_part(tags.ucs_creatorid or "DF95")
    local source_id  = sanitize_filename_part(tags.ucs_sourceid or proj_name)
    local fname      = string.format("%s_%s_%s_%s", catid, fxname, creator_id, source_id)
    return dir .. sep .. fname
  end

  -- Legacy DF95 / Splice / Loopmasters / ADSR naming-style (non-UCS)
  local style = r.GetExtState("DF95_EXPORT_NAMESTYLE", "Style")
  if not style or style == "" then style = "DF95" end
  style = string.upper(style)

  local fname
  if style == "SPLICE" then
    -- Splice-orientiertes Pattern: Category_Role_FXFlavor_<BPM>bpm_<Index>
    fname = string.format("%s_%s_%s_%sbpm_%s",
      cat, role, fxflavor, bpm_str, idx_str)
  elseif style == "LOOPMASTERS" then
    -- Loopmasters-orientiert: Role_Category_<BPM>bpm_<Index>
    fname = string.format("%s_%s_%sbpm_%s",
      role, cat, bpm_str, idx_str)
  elseif style == "ADSR" then
    -- ADSR-orientiert: DF95_Category_Role__<BPM>bpm__<Index>
    fname = string.format("DF95_%s_%s__%sbpm__%s",
      cat, role, bpm_str, idx_str)
  else
    -- DF95-Standard: Project_<BPM>bpm_Category_TagStr_<Index>
    fname = string.format("%s_%sbpm_%s_%s_%s",
      proj_name, bpm_str, cat, tag_str, idx_str)
  end

  return dir .. sep .. fname
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

-- opts:
--   mode:    "ALL_SLICES", "SELECTED_SLICES", "SELECTED_SLICES_SUM", "LOOP_TIMESEL"
--   target:  "ORIGINAL", "ZOOM96_32F", "SPLICE_44_24", "LOOPMASTERS_44_24", "ADSR_44_24"
--   ucs_catid:    optional CatID (e.g. WATRFlow, AMBRoom)
--   ucs_fxname:   optional FXName (short description, <25 chars)
--   ucs_creatorid:optional CreatorID (Designer/Company, e.g. DF95)
--   ucs_sourceid: optional SourceID (Library/Project name)
--   Artist-bezogene Defaults werden via DF95_Export_UCSArtistProfiles_v1.json / DF95_Export_UCS_Helper.lua geladen.
--   dest_root: Basis-Ordner (optional)
--   category:   z.B. "Slices_Master" / "Loops_Master"
--   subtype:    z.B. "MicroPerc", "ClicksPops", "Loop"
--   role:       Kick/Snare/Hat/Perc/ClicksPops/Synth/Atmos/Bass/...
--   source:     MobileFR/ZoomF6/Studio/DrumMachine/Synth/...
--   fxflavor:   Clean/Safe/BusIDM/IDMGlitch/LoFiTape/Extreme/...
function M.run(opts)
  opts = opts or {}
  local mode     = opts.mode or "SELECTED_SLICES"
  local target   = opts.target or "ORIGINAL"
  local dest     = opts.dest_root
  local category = opts.category or "Slices_Master"
  local subtype  = opts.subtype or ""
  local dry_run  = opts.dry_run == true

  local role, source, fxflavor = get_effective_tags{
    role     = opts.role,
    source   = opts.source,
    fxflavor = opts.fxflavor,
    category = category,
    subtype  = subtype,
  }
  local tags = { role = role, source = source, fxflavor = fxflavor,
                ucs_catid = opts.ucs_catid, ucs_fxname = opts.ucs_fxname,
                ucs_creatorid = opts.ucs_creatorid, ucs_sourceid = opts.ucs_sourceid }

  local dry_run  = opts.dry_run == true

  if not dest or dest == "" then
    local proj_dir = select(1, get_project_path_and_name())
    if not proj_dir or proj_dir == "" then
      proj_dir = r.GetProjectPath("")
    end
    dest = proj_dir .. package.config:sub(1,1) .. "DF95_EXPORT"
  end

  local proj_dir, proj_name = get_project_path_and_name()
  local bpm = get_tempo_bpm()
  local role, source, fxflavor = get_effective_tags(opts)
  local tags = { role = role, source = source, fxflavor = fxflavor,
                ucs_catid = opts.ucs_catid, ucs_fxname = opts.ucs_fxname,
                ucs_creatorid = opts.ucs_creatorid, ucs_sourceid = opts.ucs_sourceid }

  local saved = save_render_settings()

  r.Undo_BeginBlock()
  apply_target_format(target)

  if mode == "LOOP_TIMESEL" then
    local start_time, end_time = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if not start_time or not end_time or end_time <= start_time then
      msg("Kein gültiger Time Selection Bereich für Loop-Export gesetzt.")
      restore_render_settings(saved)
      return
    end

    set_render_bounds_time_selection()

    local loop_sub = (subtype ~= "" and subtype or "Loop")
    local base = build_base_path(dest, proj_name, category, loop_sub, bpm, 1, tags)
    set_render_file_base(base)
    if dry_run then
      r.ShowConsoleMsg(string.format(
        "[DF95 Export DryRun] LOOP_TIMESEL -> %s.wav | Mode=%s | Target=%s | Role=%s | Source=%s | FX=%s\n",
        base, mode, target, tags.role or "Any", tags.source or "Any", tags.fxflavor or "Generic"
      ))
    else
      trigger_render()
    end

  else
    local items = {}
    if mode == "ALL_SLICES" then
      items = get_all_items_on_selected_tracks()
    elseif mode == "SELECTED_SLICES" or mode == "SELECTED_SLICES_SUM" then
      items = get_selected_items()
    end

    if #items == 0 then
      msg("Keine Items für Slice-Export gefunden.\n" ..
          "'ALL_SLICES': Items auf selektierten Tracks,\n" ..
          "'SELECTED_SLICES'/'SELECTED_SLICES_SUM': selektierte Items.")
      restore_render_settings(saved)
      return
    end

    set_render_bounds_time_selection()

    local idx = 1

    if mode == "SELECTED_SLICES_SUM" then
      local groups = group_items_by_time(items, 0.001)
      for _, g in ipairs(groups) do
        set_time_selection(g.start, g["end"])

        local base = build_base_path(dest, proj_name, category, subtype, bpm, idx, tags)
        set_render_file_base(base)
        if dry_run then
          r.ShowConsoleMsg(string.format(
            "[DF95 Export DryRun] %s -> %s.wav | Mode=%s | Target=%s | Role=%s | Source=%s | FX=%s\n",
            mode, base, mode, target, tags.role or "Any", tags.source or "Any", tags.fxflavor or "Generic"
          ))
        else
          trigger_render()
        end

        idx = idx + 1
      end
    else
      for _, item in ipairs(items) do
        local start_time, end_time = get_item_bounds(item)
        set_time_selection(start_time, end_time)

        local base = build_base_path(dest, proj_name, category, subtype, bpm, idx, tags)
        set_render_file_base(base)
        if dry_run then
          r.ShowConsoleMsg(string.format(
            "[DF95 Export DryRun] %s -> %s.wav | Mode=%s | Target=%s | Role=%s | Source=%s | FX=%s\n",
            mode, base, mode, target, tags.role or "Any", tags.source or "Any", tags.fxflavor or "Generic"
          ))
        else
          trigger_render()
        end

        idx = idx + 1
      end
    end
  end

  restore_render_settings(saved)
  r.Undo_EndBlock("DF95 Export: " .. mode .. " ("..target..")", -1)
end



------------------------------------------------------------
-- AutoTag / NameEngine External API
------------------------------------------------------------

-- Liefert die aktuell wirksamen Tags (Role/Source/FXFlavor),
-- basierend auf:
--   * explizit übergebenen opts (role/source/fxflavor)
--   * DF95_EXPORT_TAGS ExtState
--   * Auto-Guess aus TagProfiles (Kategorie/Subtype)
function M.GetEffectiveTags(opts)
  return get_effective_tags(opts)
end

-- Kapselt die interne Namenslogik (Ordner + Basis-Filename),
-- so dass andere Module (z.B. PackWizard, SamplerSubsystem)
-- sie ebenfalls nutzen können.
function M.BuildRenderBasename(opts, index, bpm, tags)
  return build_render_basename(opts, index, bpm, tags)
end

return M
