-- DF95_BusChain_Browser_ImGui.lua
-- ImGui-Browser für DF95-Bus-Chains (FXBus / Coloring / Master) mit Tag-Filterung.
--
-- Features:
--   * Kategorie-Wahl: FXBus, Coloring, Master, oder Alle
--   * Tag-Filter: Safe-only, Extreme-only
--   * Textsuche nach Name/Tags (z.B. "idm warm")
--   * Anwendung:
--       - FXBus: erzeugt/verwendet [FX Bus]-Track und lädt Chain
--       - Coloring: erzeugt/verwendet [Coloring Bus]-Track
--       - Master: lädt Chain auf Master; optional direkt Safety/Loudness danach
--
-- Benötigt:
--   * ReaImGui (SWS/ReaPack: ReaImGui: ReaScript binding for Dear ImGui)
--   * DF95_Common_RfxChainLoader.lua
--   * DF95_FXChains_Tags.lua

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui ist nicht installiert.\nBitte ReaImGui Extension via ReaPack installieren.", "DF95 BusChain Browser", 0)
  return
end

local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""

local C = dofile(base.."DF95_Common_RfxChainLoader.lua")
local TAGS = dofile(base.."DF95_FXChains_Tags.lua")

------------------------------------------------------------
-- Daten einsammeln
------------------------------------------------------------

local entries = {}  -- flat list: {category, name, rel, path, tags, safe, intensity}

local function add_entries_for_category(category)
  local cats = C.list_by_category(category)
  for cat, list in pairs(cats) do
    for _, e in ipairs(list) do
      local rel = e.rel or e.relpath or (e.subdir and (e.subdir.."/"..e.name)) or e.name
      local meta = TAGS.get_tags(category, rel) or {}
      local tags = meta.tags or {}
      local safe = meta.safe or false
      local intensity = meta.intensity or "medium"
      local label = e.name
      table.insert(entries, {
        category = category,
        folder   = cat,
        name     = label,
        rel      = rel,
        path     = e.path,
        tags     = tags,
        safe     = safe,
        intensity = intensity,
      })
    end
  end
end

add_entries_for_category("FXBus")
add_entries_for_category("Coloring")
add_entries_for_category("Master")

table.sort(entries, function(a,b)
  if a.category ~= b.category then return a.category < b.category end
  if a.folder ~= b.folder then return (a.folder or "") < (b.folder or "") end
  return a.name < b.name
end)

------------------------------------------------------------
-- ImGui State
------------------------------------------------------------

local ctx = r.ImGui_CreateContext('DF95 BusChain Browser')
local FONT = r.ImGui_CreateFont('sans-serif', 14)
r.ImGui_Attach(ctx, FONT)

local category_filter = "All" -- "All", "FXBus", "Coloring", "Master"
local safe_only = false
local extreme_only = false
local run_safety_master = true
local search_text = ""
local selected_index = -1

------------------------------------------------------------
-- Helper: Filterlogik
------------------------------------------------------------

local function match_text(entry, query)
  if not query or query == "" then return true end
  local q = query:lower()
  if entry.name:lower():find(q, 1, true) then return true end
  if entry.rel:lower():find(q, 1, true) then return true end
  for _, t in ipairs(entry.tags or {}) do
    if t:lower():find(q, 1, true) then return true end
  end
  return false
end

local function passes_filters(entry)
  if category_filter ~= "All" and entry.category ~= category_filter then
    return false
  end
  if safe_only and not entry.safe then
    return false
  end
  if extreme_only and entry.intensity ~= "extreme" then
    return false
  end
  if not match_text(entry, search_text) then
    return false
  end
  return true
end

------------------------------------------------------------
-- Helper: Chain anwenden
------------------------------------------------------------

local function apply_entry(entry)
  if not entry then return end

  if entry.category == "Master" then
    local master = r.GetMasterTrack(0)
    local txt = C.read_file(entry.path)
    C.write_chunk_fxchain(master, txt, false)

    if run_safety_master then
      local res = r.GetResourcePath()
      local safety_path = (res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Safety_Loudness_Menu.lua"):gsub("\\","/")
      local f = io.open(safety_path, "rb")
      if f then
        f:close()
        local ok, err = pcall(dofile, safety_path)
        if not ok then
          r.ShowMessageBox("Fehler in DF95_Safety_Loudness_Menu.lua:\n"..tostring(err), "DF95 BusChain Browser", 0)
        end
      end
    end

  elseif entry.category == "FXBus" then
    local tr = C.ensure_track_named("[FX Bus]")
    local txt = C.read_file(entry.path)
    C.write_chunk_fxchain(tr, txt, false)

  elseif entry.category == "Coloring" then
    local tr = C.ensure_track_named("[Coloring Bus]")
    local txt = C.read_file(entry.path)
    C.write_chunk_fxchain(tr, txt, false)
  end
end

------------------------------------------------------------
-- GUI Loop
------------------------------------------------------------

local function loop()
  r.ImGui_PushFont(ctx, FONT)
  r.ImGui_SetNextWindowSize(ctx, 900, 500, r.ImGui_Cond_FirstUseEver())

  local visible, open = r.ImGui_Begin(ctx, "DF95 BusChain Browser", true)
  if visible then
    r.ImGui_Text(ctx, "DF95 Bus-Chains (FXBus / Coloring / Master) mit Tag-Filterung")
    r.ImGui_Separator(ctx)

    -- Filterzeile
    r.ImGui_Text(ctx, "Kategorie:")
    r.ImGui_SameLine(ctx)

    if r.ImGui_BeginCombo(ctx, "##cat", category_filter) then
      local cats = {"All","FXBus","Coloring","Master"}
      for _,c in ipairs(cats) do
        local selected = (c == category_filter)
        if r.ImGui_Selectable(ctx, c, selected) then
          category_filter = c
          selected_index = -1
        end
      end
      r.ImGui_EndCombo(ctx)
    end

    r.ImGui_SameLine(ctx)
    _, safe_only = r.ImGui_Checkbox(ctx, "Safe only", safe_only)
    r.ImGui_SameLine(ctx)
    _, extreme_only = r.ImGui_Checkbox(ctx, "Extreme only", extreme_only)

    r.ImGui_SameLine(ctx)
    r.ImGui_Text(ctx, "Search:")
    r.ImGui_SameLine(ctx)
    local changed, new_text = r.ImGui_InputText(ctx, "##search", search_text, 128)
    if changed then
      search_text = new_text
      selected_index = -1
    end

    r.ImGui_Separator(ctx)

    -- Liste
    r.ImGui_BeginChild(ctx, "list", -1, -80, true)

    local row_index = 0
    for i, e in ipairs(entries) do
      if passes_filters(e) then
        local is_selected = (i == selected_index)
        local label = string.format("%s / %s  |  %s", e.category, e.folder or "-", e.name)
        local tag_str = ""
        if e.tags and #e.tags>0 then
          tag_str = table.concat(e.tags, ", ")
        end
        if e.safe then
          if tag_str == "" then tag_str = "safe" else tag_str = tag_str..", safe" end
        end
        label = label .. "  ["..tag_str.."]"

        if r.ImGui_Selectable(ctx, label, is_selected) then
          selected_index = i
        end
        row_index = row_index + 1
      end
    end

    if row_index == 0 then
      r.ImGui_Text(ctx, "Keine Chains für aktuelle Filter gefunden.")
    end

    r.ImGui_EndChild(ctx)

    r.ImGui_Separator(ctx)

    -- Footer / Apply
    if r.ImGui_BeginDisabled(ctx, selected_index < 0) then end
    if r.ImGui_Button(ctx, "Apply auf Ziel (Master/FXBus/Coloring)") and selected_index > 0 then
      r.Undo_BeginBlock()
      r.PreventUIRefresh(1)
      apply_entry(entries[selected_index])
      r.PreventUIRefresh(-1)
      r.Undo_EndBlock("DF95 BusChain Browser – Apply", -1)
    end
    r.ImGui_EndDisabled(ctx)

    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Close") then
      open = false
    end

    r.ImGui_SameLine(ctx)
    if r.ImGui_BeginDisabled(ctx, category_filter ~= "Master") then end
    _, run_safety_master = r.ImGui_Checkbox(ctx, "Run Safety/Loudness nach Master-Apply", run_safety_master)
    r.ImGui_EndDisabled(ctx)

    r.ImGui_End(ctx)
  end

  r.ImGui_PopFont(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
