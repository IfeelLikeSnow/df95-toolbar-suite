-- DF95_BusChain_Inspector_ImGui.lua
-- -----------------------------------------------------------------------------
-- DF95 Bus-Chain Inspector (FX Bus / Coloring Bus / Master Bus)
-- -----------------------------------------------------------------------------
-- Zeigt für das aktuelle Projekt:
--   * Welche Bus-Tracks existieren (FX BUS, COLOR BUS, MASTER BUS, MAIN BUS ...)
--   * Welche FX auf den jeweiligen Bussen liegen (inkl. Slot-Index + Kategorie-Heuristik)
--   * Schnelles Refreshen + optional: aktuelle Track-Auswahl als Bus interpretieren
--
-- Design:
--   * ReaImGui-Fenster im DF95-Stil ("DF95 BusChain Inspector")
--   * Auto-Erkennung von Bus-Typen anhand Tracknamen
--   * Kategorien für einzelne FX-Slots (Limiter, Tape, Saturation, Filter, Glitch, EQ, etc.)
--
-- Integration:
--   * Speichern unter Scripts/IFLS/DF95
--   * In Reaper als ReaScript (Lua) laden
--   * Optional auf eine DF95-Toolbar legen ("Bus Inspector")
--
-- -----------------------------------------------------------------------------

local r = reaper

-- ReaImGui Setup
local ok, imgui = pcall(require, "imgui")
if not ok or not imgui then
  r.ShowMessageBox("ReaImGui (ReaScript API) nicht gefunden.\nBitte 'ReaImGui: ReaScript binding for Dear ImGui' über ReaPack installieren.", "DF95 BusChain Inspector", 0)
  return
end

local ctx = imgui.CreateContext("DF95 BusChain Inspector")
local FONT_SCALE = 1.0

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function tolower(s)
  return (s or ""):lower()
end

local function classify_fx_slot(name)
  local lname = tolower(name)
  if lname:find("limit") or lname:find("brickwall") or lname:find("maxim") then
    return "Limiter / Safety"
  elseif lname:find("tape") or lname:find("cassette") or lname:find("vhs") then
    return "Tape / Vintage"
  elseif lname:find("saturat") or lname:find("saturn") or lname:find("drive") then
    return "Saturation"
  elseif lname:find("comp") or lname:find("compressor") or lname:find("glue") then
    return "Compressor / Glue"
  elseif lname:find("eq") or lname:find("equal") or lname:find("filter") then
    return "EQ / Filter"
  elseif lname:find("exciter") or lname:find("enhanc") then
    return "Exciter / Enhancer"
  elseif lname:find("reverb") or lname:find("hall") or lname:find("room") then
    return "Reverb"
  elseif lname:find("delay") or lname:find("echo") then
    return "Delay"
  elseif lname:find("stereo") or lname:find("width") or lname:find("widen") then
    return "Stereo / Width"
  elseif lname:find("id m") or lname:find("idm") or lname:find("glitch") or lname:find("stutter") or lname:find("gran") then
    return "IDM / Glitch / Granular"
  elseif lname:find("master") or lname:find("bus") then
    return "Bus / Master"
  end
  return "Other"
end

local function classify_bus_type(track_name)
  local lname = tolower(track_name or "")
  if lname:find("fx bus") or lname == "fx" or lname:find("fxbus") then
    return "FX BUS"
  elseif lname:find("color bus") or lname:find("colour bus") or lname:find("coloring") or lname:find("tone bus") then
    return "COLORING BUS"
  elseif lname:find("master bus") or lname:find("mix bus") or lname == "master" or lname == "mix" then
    return "MASTER BUS"
  else
    return "OTHER"
  end
end

local function get_track_fx_list(tr)
  local fx_list = {}
  if not tr then return fx_list end
  local fx_count = r.TrackFX_GetCount(tr)
  for i = 0, fx_count-1 do
    local rv, name = r.TrackFX_GetFXName(tr, i, "")
    name = name or ("FX " .. tostring(i))
    table.insert(fx_list, {
      index = i,
      name = name,
      category = classify_fx_slot(name)
    })
  end
  return fx_list
end

local function collect_bus_tracks()
  local buses = {
    fx_bus       = {},
    coloring_bus = {},
    master_bus   = {},
    other        = {},
  }

  local track_count = r.CountTracks(0)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(0, i)
    local _, name = r.GetTrackName(tr, "")
    local bus_type = classify_bus_type(name)
    local fx_list = get_track_fx_list(tr)

    local entry = {
      track = tr,
      index = i,
      name  = name,
      bus_type = bus_type,
      fx     = fx_list,
    }

    if bus_type == "FX BUS" then
      table.insert(buses.fx_bus, entry)
    elseif bus_type == "COLORING BUS" then
      table.insert(buses.coloring_bus, entry)
    elseif bus_type == "MASTER BUS" then
      table.insert(buses.master_bus, entry)
    else
      table.insert(buses.other, entry)
    end
  end

  -- Auch eventuell selektierten Track als "Focus" anzeigen
  local sel = {}
  local sel_count = r.CountSelectedTracks(0)
  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    local _, name = r.GetTrackName(tr, "")
    table.insert(sel, {
      track = tr,
      name  = name,
      index = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") - 1,
      fx    = get_track_fx_list(tr),
      bus_type = classify_bus_type(name),
    })
  end

  return buses, sel
end

-- -----------------------------------------------------------------------------
-- GUI Loop
-- -----------------------------------------------------------------------------

local function draw_fx_table(ctx, list)
  local flags = imgui.TableFlags_Borders()
  if imgui.BeginTable(ctx, "fx_table", 3, flags) then
    imgui.TableSetupColumn(ctx, "Slot", imgui.TableColumnFlags_WidthFixed(), 40)
    imgui.TableSetupColumn(ctx, "FX-Name", imgui.TableColumnFlags_WidthStretch(), 260)
    imgui.TableSetupColumn(ctx, "Kategorie", imgui.TableColumnFlags_WidthStretch(), 160)
    imgui.TableHeadersRow(ctx)

    for _, fx in ipairs(list or {}) do
      imgui.TableNextRow(ctx)
      imgui.TableSetColumnIndex(ctx, 0)
      imgui.Text(ctx, tostring(fx.index))
      imgui.TableSetColumnIndex(ctx, 1)
      imgui.Text(ctx, fx.name or "?")
      imgui.TableSetColumnIndex(ctx, 2)
      imgui.Text(ctx, fx.category or "Other")
    end

    imgui.EndTable(ctx)
  end
end

local last_scan_time = 0
local buses_cache = nil
local sel_cache   = nil

local function refresh_bus_data()
  buses_cache, sel_cache = collect_bus_tracks()
  last_scan_time = r.time_precise()
end

local function loop()
  imgui.SetNextWindowSize(ctx, 900, 520, imgui.Cond_FirstUseEver())
  local visible, open = imgui.Begin(ctx, "DF95 BusChain Inspector", true)
  if visible then
    if not buses_cache then
      refresh_bus_data()
    end

    imgui.Text(ctx, "DF95 Bus-Chain Inspector")
    imgui.Separator(ctx)

    if imgui.Button(ctx, "Refresh (Scan Projekt)", 180, 0) then
      refresh_bus_data()
    end
    imgui.SameLine(ctx)
    imgui.Text(ctx, string.format("Letzter Scan: %.2f s", last_scan_time or 0))

    imgui.Dummy(ctx, 0, 6)

    if buses_cache then
      -- FX BUS
      if imgui.CollapsingHeader(ctx, "FX BUS Tracks", true) then
        if #buses_cache.fx_bus == 0 then
          imgui.Text(ctx, "Keine FX BUS Tracks gefunden (Suche nach 'FX BUS', 'FXBUS', etc.).")
        else
          for _, e in ipairs(buses_cache.fx_bus) do
            imgui.Separator(ctx)
            imgui.Text(ctx, string.format("Track %d: %s", (e.index or 0) + 1, e.name or "(unbenannt)"))
            draw_fx_table(ctx, e.fx)
          end
        end
      end

      -- COLORING BUS
      if imgui.CollapsingHeader(ctx, "COLORING BUS Tracks", true) then
        if #buses_cache.coloring_bus == 0 then
          imgui.Text(ctx, "Keine Coloring/Color BUS Tracks gefunden (Suche nach 'COLOR BUS', 'COLORING', 'TONE BUS').")
        else
          for _, e in ipairs(buses_cache.coloring_bus) do
            imgui.Separator(ctx)
            imgui.Text(ctx, string.format("Track %d: %s", (e.index or 0) + 1, e.name or "(unbenannt)"))
            draw_fx_table(ctx, e.fx)
          end
        end
      end

      -- MASTER BUS
      if imgui.CollapsingHeader(ctx, "MASTER BUS Tracks", true) then
        if #buses_cache.master_bus == 0 then
          imgui.Text(ctx, "Keine Master/Mix BUS Tracks gefunden (Suche nach 'MASTER BUS', 'MIX BUS', 'MASTER').")
        else
          for _, e in ipairs(buses_cache.master_bus) do
            imgui.Separator(ctx)
            imgui.Text(ctx, string.format("Track %d: %s", (e.index or 0) + 1, e.name or "(unbenannt)"))
            draw_fx_table(ctx, e.fx)
          end
        end
      end

      -- Optional: Selektierte Tracks
      if sel_cache and #sel_cache > 0 and imgui.CollapsingHeader(ctx, "Selektierte Tracks (Focus)", true) then
        for _, e in ipairs(sel_cache) do
          imgui.Separator(ctx)
          imgui.Text(ctx, string.format("Track %d: %s  [%s]", (e.index or 0) + 1, e.name or "(unbenannt)", e.bus_type or "OTHER"))
          draw_fx_table(ctx, e.fx)
        end
      end
    end

    imgui.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    imgui.DestroyContext(ctx)
  end
end

-- Start
refresh_bus_data()
r.defer(loop)
