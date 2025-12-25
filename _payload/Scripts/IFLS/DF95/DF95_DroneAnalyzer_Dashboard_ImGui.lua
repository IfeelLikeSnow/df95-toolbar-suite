
-- @description DF95 Drone Analyzer Dashboard (Phase H) – ImGui Overview for Drone/Atmos Library
-- @version 1.0
-- @author DF95
-- @about
--   Zeigt eine interaktive Übersicht über Drone/Atmos-Samples der DF95 SampleDB:
--     * Verteilung nach df95_drone_flag / df95_catid
--     * Centerfreq / Density / Form / Motion / Tension
--     * Anteil der Drone-Items an der Gesamt-Library
--   Nutzt die gleiche JSON-DB wie der DF95_V138 SampleDB Library Analyzer.
--
--   Erwartete DB-Datei:
--     <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Typische Nutzung:
--     * Überblick über HOME/EMF/IDM/GENERIC-Drones
--     * Lückenanalyse (z.B. zu wenig HIGH/TEXTURE/MOVEMENT)
--     * Kontrolle, ob AutoIngest Phase D2/G die Drone-Felder sauber setzen

local r = reaper

-- Basic ImGui bootstrap
package.path = reaper.GetResourcePath() .. "/Scripts/?.lua;" .. package.path
local ok, imgui = pcall(require, "ImGui")
if not ok or not imgui then
  r.ShowMessageBox("ReaImGui (imgui.lua) nicht gefunden. Bitte ReaImGui installieren.", "DF95 Drone Analyzer", 0)
  return
end

local ctx = imgui.CreateContext("DF95 Drone Analyzer Dashboard")

-- small helpers
local function join_path(a,b)
  if not a or a == "" then return b end
  local sep = package.config:sub(1,1)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function safe_str(v)
  if v == nil then return "" end
  return tostring(v)
end

local function upper(v)
  return safe_str(v):upper()
end

local function inc(map, key, amount)
  amount = amount or 1
  if key == nil or key == "" then
    key = "(none)"
  end
  local old = map[key] or 0
  map[key] = old + amount
end

local function get_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function load_json_file(path)
  local f = io.open(path, "r")
  if not f then return nil, "Kann Datei nicht öffnen: " .. tostring(path) end
  local txt = f:read("*a")
  f:close()
  if not txt or txt == "" then
    return nil, "Datei ist leer: " .. tostring(path)
  end
  local ok, obj = pcall(function() return r.Json_Decode(txt) end)
  if not ok or not obj then
    return nil, "JSON-Decode fehlgeschlagen für: " .. tostring(path)
  end
  return obj
end

local function analyze_drones(db, min_len)
  min_len = min_len or 0.0
  local items = db and db.items
  if type(items) ~= "table" then
    return nil, "DB.items fehlt oder ist kein Array"
  end

  local stats = {
    total_items      = 0,
    total_length     = 0.0,
    drone_items      = 0,
    drone_length     = 0.0,

    drone_flag       = {},
    drone_catid      = {},
    drone_centerfreq = {},
    drone_density    = {},
    drone_form       = {},
    drone_motion     = {},
    drone_tension    = {},

    drone_by_kind    = {}, -- kind = HOME/EMF/IDM/GENERIC/OTHER
  }

  for _, it in ipairs(items) do
    local len = tonumber(it.length_sec or it.length or 0) or 0
    if len >= min_len then
      stats.total_items  = stats.total_items + 1
      stats.total_length = stats.total_length + len

      local role        = upper(it.role)
      local flag        = upper(it.df95_drone_flag)
      local catid       = upper(it.df95_catid)
      local cf          = upper(it.df95_drone_centerfreq)
      local dens        = upper(it.df95_drone_density)
      local form        = upper(it.df95_drone_form)
      local mot         = upper(it.df95_motion_strength or it.df95_drone_motion)
      local ten         = upper(it.df95_tension)

      local is_drone = false
      if role == "DRONE" then is_drone = true end
      if flag ~= "" then is_drone = true end
      if catid:find("DRONE", 1, true) then is_drone = true end

      if is_drone then
        stats.drone_items  = stats.drone_items + 1
        stats.drone_length = stats.drone_length + len

        inc(stats.drone_flag,       flag)
        inc(stats.drone_catid,      catid)
        inc(stats.drone_centerfreq, cf)
        inc(stats.drone_density,    dens)
        inc(stats.drone_form,       form)
        inc(stats.drone_motion,     mot)
        inc(stats.drone_tension,    ten)

        local kind = flag
        if kind == "" then
          if catid:find("HOME", 1, true) then
            kind = "HOME_DRONE"
          elseif catid:find("EMF", 1, true) then
            kind = "EMF_DRONE"
          elseif catid:find("IDM", 1, true) then
            kind = "IDM_DRONE"
          elseif catid:find("DRONE", 1, true) then
            kind = "DRONE_GENERIC"
          else
            kind = "OTHER"
          end
        end
        inc(stats.drone_by_kind, kind)
      end
    end
  end

  return stats
end

local function sorted_pairs_by_count(map)
  local t = {}
  for k,v in pairs(map or {}) do
    t[#t+1] = { key = k, count = v }
  end
  table.sort(t, function(a,b)
    if a.count == b.count then
      return tostring(a.key) < tostring(b.key)
    else
      return a.count > b.count
    end
  end)
  return t
end

local state = {
  min_len = 2.0,
  last_err = "",
  last_path = "",
  stats = nil,

  -- Drilldown/Glue (Phase I)
  dd_kind       = "ALL",
  dd_catid      = "",
  dd_centerfreq = "ALL",
  dd_density    = "ALL",
  dd_form       = "ALL",
  dd_motion     = "ALL",
  dd_tension    = "ALL",

  info_msg      = "",
}

local function refresh()
  state.last_err = ""
  state.stats = nil

  local path = get_db_path()
  state.last_path = path or "(none)"

  local db, err = load_json_file(path)
  if not db then
    state.last_err = err or "Unbekannter Fehler beim Laden der DB"
    return
  end

  local stats, err2 = analyze_drones(db, state.min_len)
  if not stats then
    state.last_err = err2 or "Fehler bei analyze_drones"
    return
  end

  state.stats = stats
end

-- initial load attempt
refresh()

local function fmt_percent(num, denom)
  if not denom or denom <= 0 then return "0.0%" end
  local p = (num or 0) / denom * 100.0
  return string.format("%.1f%%", p)
end

-- Phase I: Drilldown/Glue Helpers

local function get_support_dir()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return dir
end

local function write_inspector_hotspot_from_state()
  local dir = get_support_dir()
  local ok = reaper.RecursiveCreateDirectory(dir, 0)
  if not ok then
    state.info_msg = "Konnte Support-Verzeichnis nicht anlegen: " .. tostring(dir)
    return
  end
  local path = join_path(dir, "DF95_InspectorV5_HotspotFilter.json")

  local cfg = {
    filter_drone_only      = true,
    filter_drone_kind      = state.dd_kind or "ALL",
    filter_drone_centerfreq = state.dd_centerfreq or "ALL",
    filter_drone_density    = state.dd_density or "ALL",
    filter_drone_form       = state.dd_form or "ALL",
    filter_drone_motion     = state.dd_motion or "ALL",
    filter_drone_tension    = state.dd_tension or "ALL",
  }

  local txt = nil
  if r.Json_Encode then
    txt = r.Json_Encode(cfg)
  else
    -- Minimaler Fallback-Encoder (ohne alle Felder, aber mit Kind)
    txt = string.format('{"filter_drone_only":true,"filter_drone_kind":"%s"}', tostring(cfg.filter_drone_kind):gsub('"','\"'))
  end

  local f, err = io.open(path, "w")
  if not f then
    state.info_msg = "Fehler beim Schreiben des Inspector-Hotspots: " .. tostring(err or path)
    return
  end
  f:write(txt or "")
  f:close()

  state.info_msg = "Inspector-Hotspot geschrieben: " .. tostring(path) .. " (DroneOnly=true, Kind=" .. tostring(cfg.filter_drone_kind) .. ")"
end

local function suggest_packexporter_preset()
  -- Liefert einen passenden Phase-E-Preset-Key für den PackExporter, basierend auf dd_kind / dd_catid
  if state.dd_catid and state.dd_catid ~= "" then
    return state.dd_catid
  end

  local kind = state.dd_kind or "ALL"
  if kind == "HOME_DRONE" then
    return "DRONE_HOME_ATMOS"
  elseif kind == "EMF_DRONE" then
    return "DRONE_EMF_LONG"
  elseif kind == "IDM_DRONE" then
    return "DRONE_IDM_TEXTURE"
  elseif kind == "GENERIC_DRONE" then
    return "DRONE_GENERIC"
  else
    return ""
  end
end

local function draw_stats_table(label, map, max_rows)
  max_rows = max_rows or 16
  local list = sorted_pairs_by_count(map)
  local flags = imgui.TableFlags_RowBg | imgui.TableFlags_Borders | imgui.TableFlags_SizingStretchProp
  if imgui.BeginTable(ctx, label, 3, flags) then
    imgui.TableSetupColumn(ctx, "Key", imgui.TableColumnFlags_None)
    imgui.TableSetupColumn(ctx, "Count", imgui.TableColumnFlags_WidthFixed)
    imgui.TableSetupColumn(ctx, "Percent (rel. Drone-Items)", imgui.TableColumnFlags_WidthFixed)
    imgui.TableHeadersRow(ctx)

    local total = 0
    for _, row in ipairs(list) do
      total = total + (row.count or 0)
    end

    local shown = 0
    for _, row in ipairs(list) do
      shown = shown + 1
      if shown > max_rows then break end
      imgui.TableNextRow(ctx)
      imgui.TableNextColumn(ctx)
      imgui.Text(ctx, tostring(row.key))
      imgui.TableNextColumn(ctx)
      imgui.Text(ctx, tostring(row.count))
      imgui.TableNextColumn(ctx)
      imgui.Text(ctx, fmt_percent(row.count or 0, total))
    end

    imgui.EndTable(ctx)
  end
end

local function loop()
  imgui.SetNextWindowSize(ctx, 900, 600, imgui.Cond_FirstUseEver)
  local visible, open = imgui.Begin(ctx, "DF95 Drone Analyzer Dashboard", true)
  if not visible then
    imgui.End(ctx)
    if not open then
      r.defer(function() end)
    else
      r.defer(loop)
    end
    return
  end

  if imgui.Button(ctx, "Refresh / Re-Analyze", 200, 24) then
    refresh()
  end
  imgui.SameLine(ctx)
  imgui.Text(ctx, "DB: " .. (state.last_path or "(none)"))

  local changed_minlen, new_minlen = imgui.InputDouble(ctx, "Min. Length (Sekunden)", state.min_len or 0.0, 0.5, 5.0, "%.2f")
  if changed_minlen then
    if new_minlen < 0.0 then new_minlen = 0.0 end
    if new_minlen > 60.0 then new_minlen = 60.0 end
    state.min_len = new_minlen
  end

  imgui.Separator(ctx)

  if state.last_err ~= "" then
    imgui.TextColored(ctx, 1.0, 0.2, 0.2, 1.0, "Fehler: " .. state.last_err)
    imgui.End(ctx)
    r.defer(loop)
    return
  end

  local stats = state.stats
  if not stats then
    imgui.Text(ctx, "Noch keine Statistiken geladen. Bitte 'Refresh' klicken.")
    imgui.End(ctx)
    r.defer(loop)
    return
  end

  -- Summary
  imgui.Text(ctx, string.format("Items >= %.2f s: %d", state.min_len or 0.0, stats.total_items or 0))
  imgui.Text(ctx, string.format("Gesamtspielzeit: %.1f Sekunden (%.2f Stunden)", stats.total_length or 0.0, (stats.total_length or 0.0)/3600.0))
  imgui.Separator(ctx)

  if stats.drone_items and stats.drone_items > 0 then
    imgui.Text(ctx, string.format("Drone-Items: %d (%s der Items)", stats.drone_items, fmt_percent(stats.drone_items, stats.total_items)))
    imgui.Text(ctx, string.format("Drone-Spielzeit: %.1f Sekunden (%.2f Stunden, %s der Gesamtzeit)",
      stats.drone_length or 0.0,
      (stats.drone_length or 0.0) / 3600.0,
      fmt_percent(stats.drone_length or 0.0, stats.total_length or 0.0)))
  else
    imgui.Text(ctx, "Drone-Items: 0")
  end

  imgui.Separator(ctx)

  -- Phase I: Drilldown / Glue (Inspector & PackExporter)
  imgui.Text(ctx, "Drilldown / Glue")
  imgui.Spacing(ctx)

  -- Drone-Kind Combo
  local kinds = { "ALL", "HOME_DRONE", "EMF_DRONE", "IDM_DRONE", "GENERIC_DRONE" }
  local current_kind = state.dd_kind or "ALL"
  if imgui.BeginCombo(ctx, "Drone-Kind (Inspector/PackExporter)", current_kind) then
    for _, v in ipairs(kinds) do
      local selected = (v == current_kind)
      if imgui.Selectable(ctx, v, selected) then
        state.dd_kind = v
        current_kind = v
      end
      if selected then
        imgui.SetItemDefaultFocus(ctx)
      end
    end
    imgui.EndCombo(ctx)
  end

  -- Expliziter df95_catid Override
  local changed_catid, new_catid = imgui.InputText(ctx, "df95_catid (optional, z.B. DRONE_HOME_ATMOS)", state.dd_catid or "", 256)
  if changed_catid then
    state.dd_catid = new_catid
  end

  -- PackExporter-Empfehlung anzeigen
  local sugg = suggest_packexporter_preset()
  if sugg ~= "" then
    imgui.Text(ctx, "Empfohlenes PackExporter Drone-Preset: " .. tostring(sugg))
  else
    imgui.Text(ctx, "Empfohlenes PackExporter Drone-Preset: (kein spezieller Vorschlag)")
  end

  imgui.Spacing(ctx)
  if imgui.Button(ctx, "Inspector-Hotspot schreiben (Drone-Filter setzen)", 340, 24) then
    write_inspector_hotspot_from_state()
  end

  if state.info_msg and state.info_msg ~= "" then
    imgui.Spacing(ctx)
    imgui.Text(ctx, state.info_msg)
  end

  imgui.Separator(ctx)

  -- Layout: 2 Columns for stats tables
  if imgui.BeginChild(ctx, "LeftPane", 0, 0, false, imgui.WindowFlags_None) then
    imgui.Text(ctx, "Drone-Arten (df95_drone_flag / Kind)")
    draw_stats_table("DroneKind", stats.drone_by_kind or {}, 8)
    imgui.Separator(ctx)

    imgui.Text(ctx, "Drone Kategorien (df95_catid)")
    draw_stats_table("DroneCatID", stats.drone_catid or {}, 10)
    imgui.Separator(ctx)

    imgui.Text(ctx, "Drone Centerfreq")
    draw_stats_table("DroneCF", stats.drone_centerfreq or {}, 6)

    imgui.EndChild(ctx)
  end

  imgui.SameLine(ctx)

  if imgui.BeginChild(ctx, "RightPane", 0, 0, false, imgui.WindowFlags_None) then
    imgui.Text(ctx, "Drone Density")
    draw_stats_table("DroneDensity", stats.drone_density or {}, 6)
    imgui.Separator(ctx)

    imgui.Text(ctx, "Drone Form")
    draw_stats_table("DroneForm", stats.drone_form or {}, 8)
    imgui.Separator(ctx)

    imgui.Text(ctx, "Drone Motion")
    draw_stats_table("DroneMotion", stats.drone_motion or {}, 8)
    imgui.Separator(ctx)

    imgui.Text(ctx, "Drone Tension")
    draw_stats_table("DroneTension", stats.drone_tension or {}, 8)

    imgui.EndChild(ctx)
  end

  imgui.End(ctx)
  r.defer(loop)
end

r.defer(loop)
