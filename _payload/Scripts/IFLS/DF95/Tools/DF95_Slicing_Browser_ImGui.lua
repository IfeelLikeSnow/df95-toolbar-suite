-- DF95_Bus + Slicing System
-- DF95_Slicing_Browser_ImGui.lua
-- ImGui-Browser für Slicing-FXChains mit Tag-/Artist-Filterung
--
-- Annahmen:
--   * Slicing-FXChains liegen unter FXChains/DF95/Slicing* (Unterordner nach Geschmack)
--   * Tags werden heuristisch aus Dateinamen/Ordnern abgeleitet (idm, glitch, autechre, boc, ...)
--   * Chains werden auf die selektierten Tracks angewendet (als Track-FXChain)
--
-- Abhängigkeiten:
--   * ReaImGui (ReaPack: ReaImGui)
--   * DF95_Common_RfxChainLoader.lua

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui ist nicht installiert.\nBitte ReaImGui Extension via ReaPack installieren.", "DF95 Slicing Browser", 0)
  return
end

local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""

local C = dofile(base.."DF95_Common_RfxChainLoader.lua")

------------------------------------------------------------
-- Discovery: Slicing-FXChains suchen
------------------------------------------------------------

local function infer_tags_from_name(name)
  local n = name:lower()
  local tags = {}

  local function add(tag)
    for _,t in ipairs(tags) do if t == tag then return end end
    table.insert(tags, tag)
  end

  if n:find("idm") then add("idm") end
  if n:find("glitch") then add("glitch") end
  if n:find("euclid") or n:find("euclidian") then add("euclid") end
  if n:find("amen") then add("amen") end
  if n:find("gran") then add("granular") end
  if n:find("stutter") or n:find("stut") then add("stutter") end
  if n:find("click") or n:find("clicks") then add("clicks") end
  if n:find("pop") or n:find("pops") then add("pops") end

  -- Artists: Aphex / Autechre / BoC / Squarepusher / µ-ziq / Plaid / Arovane / Moderat / Proem
  if n:find("aphex") or n:find("druk") then add("aphex") end
  if n:find("autechre") or n:find("ae_") then add("autechre") end
  if n:find("boc") or n:find("boardsofcanada") then add("boc") end
  if n:find("sqpr") or n:find("squarepusher") then add("squarepusher") end
  if n:find("uziq") or n:find("u%-ziq") then add("uziq") end
  if n:find("plaid") then add("plaid") end
  if n:find("arovane") then add("arovane") end
  if n:find("moderat") then add("moderat") end
  if n:find("proem") then add("proem") end

  -- Intensity / Charakter
  local intensity = "medium"
  if n:find("extreme") or n:find("xtrm") then intensity = "extreme" end
  if n:find("soft") then intensity = "soft" end
  if n:find("clean") then add("clean") end
  if n:find("safe") then add("safe") end

  return tags, intensity
end

local function discover_slicing_chains()
  local entries = {}

  local res = r.GetResourcePath()
  local fxroot = (res..sep.."FXChains"..sep.."DF95"):gsub("\\","/")
  local function scan_dir(sub)
    local root = fxroot..sep..sub
    local ok, files = r.EnumerateFiles or nil, nil
  end

  -- Nutzen die Common-Funktion: wir erwarten einen Unterordner "Slicing" (oder mehrere)
  -- Falls nicht vorhanden, gibt es einfach keine Treffer.
  local cats = C.list_by_category("Slicing")
  if cats then
    for cat, list in pairs(cats) do
      for _,e in ipairs(list) do
        local rel = e.rel or e.relpath or (e.subdir and (e.subdir.."/"..e.name)) or e.name
        local tags, intensity = infer_tags_from_name(rel)
        table.insert(entries, {
          folder    = cat,
          name      = e.label or e.name,
          rel       = rel,
          path      = e.path,
          tags      = tags,
          intensity = intensity,
        })
      end
    end
  end

  table.sort(entries, function(a,b)
    if (a.folder or "") ~= (b.folder or "") then
      return (a.folder or "") < (b.folder or "")
    end
    return a.name:lower() < b.name:lower()
  end)

  return entries
end

local entries = discover_slicing_chains()

------------------------------------------------------------
-- ImGui Setup
------------------------------------------------------------

local ctx = r.ImGui_CreateContext("DF95 Slicing Browser")
local FONT = r.ImGui_CreateFont('sans-serif', 14)
r.ImGui_Attach(ctx, FONT)

local search_text = ""
local tag_filter_idm = false
local tag_filter_glitch = false
local tag_filter_euclid = false
local tag_filter_gran = false
local tag_filter_artist = false
local intensity_extreme = false
local selected_index = -1

------------------------------------------------------------
-- Filterfunktionen
------------------------------------------------------------

local function has_tag(entry, tag)
  if not entry.tags then return false end
  for _,t in ipairs(entry.tags) do
    if t == tag then return true end
  end
  return false
end

local function is_artist_tag(t)
  return (t=="aphex" or t=="autechre" or t=="boc" or t=="squarepusher"
       or t=="uziq" or t=="plaid" or t=="arovane" or t=="moderat" or t=="proem")
end

local function passes_filters(entry)
  if search_text ~= "" then
    local q = search_text:lower()
    local blob = (entry.name.." "..entry.rel):lower()
    local hit = blob:find(q, 1, true)
    if not hit then
      local hit_tag = false
      for _,t in ipairs(entry.tags or {}) do
        if t:lower():find(q,1,true) then hit_tag = true break end
      end
      if not hit_tag then return false end
    end
  end

  if tag_filter_idm and not has_tag(entry, "idm") then return false end
  if tag_filter_glitch and not has_tag(entry, "glitch") then return false end
  if tag_filter_euclid and not has_tag(entry, "euclid") then return false end
  if tag_filter_gran and not has_tag(entry, "granular") then return false end

  if tag_filter_artist then
    local any_artist = false
    for _,t in ipairs(entry.tags or {}) do
      if is_artist_tag(t) then any_artist = true break end
    end
    if not any_artist then return false end
  end

  if intensity_extreme and entry.intensity ~= "extreme" then
    return false
  end

  return true
end

------------------------------------------------------------
-- Anwenden der Chain
------------------------------------------------------------

local function apply_to_selected_tracks(entry)
  if not entry then return end
  local txt = C.read_file(entry.path)
  if not txt then
    r.ShowMessageBox("Slicing-FXChain nicht gefunden:\n"..tostring(entry.path), "DF95 Slicing Browser", 0)
    return
  end

  local cnt = r.CountSelectedTracks(0)
  if cnt == 0 then
    r.ShowMessageBox("Keine Tracks selektiert.\nBitte einen oder mehrere Tracks auswählen, auf die die Slicing-Kette gelegt werden soll.", "DF95 Slicing Browser", 0)
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, cnt-1 do
    local tr = r.GetSelectedTrack(0, i)
    C.write_chunk_fxchain(tr, txt, false)
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Slicing Browser – Apply "..(entry.name or ""), -1)
end

------------------------------------------------------------
-- GUI Loop
------------------------------------------------------------

local function loop()
  r.ImGui_PushFont(ctx, FONT)
  r.ImGui_SetNextWindowSize(ctx, 900, 500, r.ImGui_Cond_FirstUseEver())

  local visible, open = r.ImGui_Begin(ctx, "DF95 Slicing Browser", true)
  if visible then
    r.ImGui_Text(ctx, "DF95 Slicing Browser – FXChains/DF95/Slicing* (Tag/Artist-Filter)")
    r.ImGui_Separator(ctx)

    -- Hinweis, falls es noch keine Slicing-Chains gibt
    if #entries == 0 then
      r.ImGui_Text(ctx, "Keine Slicing-FXChains unter FXChains/DF95/Slicing gefunden.")
      r.ImGui_Text(ctx, "Du kannst eigene RFX-Chains in Ordnern wie 'Slicing_IDM', 'Slicing_Euclid' anlegen,")
      r.ImGui_Text(ctx, "und der Browser taggt sie automatisch anhand des Namens (idm, glitch, euclid, Artists, ...).")
    end

    -- Filterzeile
    local changed
    changed, search_text = r.ImGui_InputText(ctx, "Search", search_text, 128)
    if changed then selected_index = -1 end

    _, tag_filter_idm = r.ImGui_Checkbox(ctx, "IDM", tag_filter_idm); r.ImGui_SameLine(ctx)
    _, tag_filter_glitch = r.ImGui_Checkbox(ctx, "Glitch", tag_filter_glitch); r.ImGui_SameLine(ctx)
    _, tag_filter_euclid = r.ImGui_Checkbox(ctx, "Euclid", tag_filter_euclid); r.ImGui_SameLine(ctx)
    _, tag_filter_gran = r.ImGui_Checkbox(ctx, "Granular", tag_filter_gran); r.ImGui_SameLine(ctx)
    _, tag_filter_artist = r.ImGui_Checkbox(ctx, "Artist-based", tag_filter_artist); r.ImGui_SameLine(ctx)
    _, intensity_extreme = r.ImGui_Checkbox(ctx, "Extreme only", intensity_extreme)

    r.ImGui_Separator(ctx)

    r.ImGui_BeginChild(ctx, "list", -1, -80, true)

    local visible_rows = 0
    for i, e in ipairs(entries) do
      if passes_filters(e) then
        local is_selected = (i == selected_index)
        local tag_str = ""
        if e.tags and #e.tags>0 then
          tag_str = table.concat(e.tags, ", ")
        end
        if e.intensity and e.intensity ~= "medium" then
          if tag_str == "" then tag_str = e.intensity else tag_str = tag_str..", "..e.intensity end
        end
        local label = string.format("%s  |  %s", e.folder or "-", e.name or e.rel)
        if tag_str ~= "" then
          label = label .. "  ["..tag_str.."]"
        end
        if r.ImGui_Selectable(ctx, label, is_selected) then
          selected_index = i
        end
        visible_rows = visible_rows + 1
      end
    end

    if visible_rows == 0 then
      r.ImGui_Text(ctx, "Keine Chains für aktuelle Filter gefunden.")
    end

    r.ImGui_EndChild(ctx)

    r.ImGui_Separator(ctx)

    local disabled = (selected_index < 0)
    if r.ImGui_BeginDisabled(ctx, disabled) then end
    if r.ImGui_Button(ctx, "Apply auf selektierte Tracks") and selected_index > 0 then
      apply_to_selected_tracks(entries[selected_index])
    end
    r.ImGui_EndDisabled(ctx)

    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Close") then
      open = false
    end

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
