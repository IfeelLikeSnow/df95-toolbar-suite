-- IFLS_SampleHub_ImGui.lua
-- IFLS Sample Hub (ImGui) - Phase 5
-- ----------------------------------

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_ui,        ui_core   = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
local ok_sample,    sampledom = pcall(dofile, domain_path .. "IFLS_SampleDBDomain.lua")
local ok_artist,    artistdom = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")

if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox(
    "IFLS Sample Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.\nBitte ReaImGui installieren und IFLS/Core prüfen.",
    "IFLS Sample Hub",
    0
  )
  return
end

if not ok_sample or type(sampledom) ~= "table" then
  r.ShowMessageBox(
    "IFLS Sample Hub: IFLS_SampleDBDomain.lua konnte nicht geladen werden.",
    "IFLS Sample Hub",
    0
  )
  return
end

local initialized = false
local s_state = {
  active_library = "",
  tag_filter     = "",
  loop_tag       = "loop",
  speech_tag     = "speech",
  category_hint  = "",
  filter_hint    = "",
}

local function reload_state()
  local st = sampledom.get_state()
  s_state.active_library = st.active_library or ""
  s_state.tag_filter     = st.tag_filter or ""
  s_state.loop_tag       = st.loop_tag or "loop"
  s_state.speech_tag     = st.speech_tag or "speech"
  s_state.category_hint  = st.category_hint or ""
  s_state.filter_hint    = st.filter_hint or ""
end

local function write_state()
  sampledom.set_state({
    active_library = s_state.active_library,
    tag_filter     = s_state.tag_filter,
    loop_tag       = s_state.loop_tag,
    speech_tag     = s_state.speech_tag,
    category_hint  = s_state.category_hint,
    filter_hint    = s_state.filter_hint,
  })
end

local function apply_artist_hints()
  if not ok_artist or not artistdom or not artistdom.get_artist_state then
    r.ShowConsoleMsg("IFLS Sample Hub: ArtistDomain nicht verfügbar (get_artist_state fehlt).\n")
    return
  end
  local a_state = artistdom.get_artist_state()
  sampledom.apply_artist_hints_to_sampledb(a_state)
  reload_state()
end

local function draw(ctx)
  if not initialized then
    reload_state()
    ui_core.set_default_window_size(ctx, 640, 360)
    initialized = true
  end

  if ig.Button(ctx, "Reload SampleDB state") then
    reload_state()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Write SampleDB state") then
    write_state()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Apply Artist Hints") then
    apply_artist_hints()
  end

  ig.Separator(ctx)
  ig.Text(ctx, "SampleDB Core")
  ig.Separator(ctx)

  local changed

  ig.PushItemWidth(ctx, 260)
  local lib = s_state.active_library or ""
  changed, lib = ig.InputText(ctx, "Active Library", lib)
  if changed then
    s_state.active_library = lib
  end

  local tags = s_state.tag_filter or ""
  changed, tags = ig.InputText(ctx, "Global Tag Filter", tags)
  if changed then
    s_state.tag_filter = tags
  end

  local ltag = s_state.loop_tag or "loop"
  changed, ltag = ig.InputText(ctx, "Loop Tag", ltag)
  if changed then
    s_state.loop_tag = ltag
  end

  local stag = s_state.speech_tag or "speech"
  changed, stag = ig.InputText(ctx, "Speech Tag", stag)
  if changed then
    s_state.speech_tag = stag
  end

  local cat = s_state.category_hint or ""
  changed, cat = ig.InputText(ctx, "Category Hint (from Artist)", cat)
  if changed then
    s_state.category_hint = cat
  end

  local filt = s_state.filter_hint or ""
  changed, filt = ig.InputText(ctx, "Filter Hint (from Artist)", filt)
  if changed then
    s_state.filter_hint = filt
  end

  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "SampleDB Tools")
  ig.Separator(ctx)

  if ig.Button(ctx, "Open SampleDB Browser") then
    write_state()
    sampledom.open_browser()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Rebuild Index") then
    write_state()
    sampledom.rebuild_index()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Analyze Library") then
    write_state()
    sampledom.analyze_library()
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Loop / Speech Layers (V198)")
  ig.Separator(ctx)

  if ig.Button(ctx, "Build Loop Layers (V198)") then
    write_state()
    sampledom.build_loop_layers()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Build Speech Layers (V198)") then
    write_state()
    sampledom.build_speech_layers()
  end
end

local ctx = ui_core.create_context("IFLS_SampleHub")
if ctx then
  ui_core.run_mainloop(ctx, "IFLS Sample Hub", draw)
end
