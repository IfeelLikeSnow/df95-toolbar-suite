-- @description DF95 Drone/Atmos Builder from SampleDB View (ImGui)
-- @version 1.1
-- @author DF95
-- @about
--   Baut aus der aktuellen AutoIngest-Subset-View (Inspector V5: "View -> AutoIngest Subset schreiben")
--   ein Set von laengeren Drone/Atmos-Kandidaten:
--     * Liest DF95_AutoIngest_Subset.json (Liste von Filepaths)
--     * Filtert nach Mindestlaenge und optional Namens-Substring
--     * Erzeugt pro ausgewaehltem File ein Item im aktuellen Projekt
--       (entweder ein Track pro Drone oder ein Stack auf einem Track)
--     * Optional: haengt das DF95_DroneFX_Rack_V1 an jeden erzeugten Track an.

local r = reaper

----------------------------------------------------------------
-- JSON + Subset-Helpers
----------------------------------------------------------------

local function df95_load_json_core()
  local ok, mod = pcall(function()
    local info = debug.getinfo(1, "S")
    local script_path = info and info.source:match("^@(.+)$")
    if not script_path then return nil end
    local dir = script_path:match("^(.*[\\/])") or ""
    local core_path = dir .. "Core/DF95_JSON.lua"
    local chunk, err = loadfile(core_path)
    if not chunk then
      error("DF95_JSON.lua konnte nicht geladen werden: " .. tostring(err))
    end
    local m = chunk()
    return m
  end)
  if not ok or not mod or type(mod.decode) ~= "function" then
    return nil, "DF95_JSON konnte nicht geladen werden oder decode() fehlt."
  end
  return mod, nil
end

local function get_autoingest_subset_path()
  local res = r.GetResourcePath()
  local dir = res .. "/Support/DF95_SampleDB"
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(dir, 0)
  end
  return dir .. "/DF95_AutoIngest_Subset.json"
end

local function get_file_name(path)
  if not path then return "" end
  local name = path:match("([^/\\]+)$") or path
  return name
end

local function load_subset_with_lengths(min_length)
  local path = get_autoingest_subset_path()
  local f = io.open(path, "r")
  if not f then
    return nil, "Konnte AutoIngest-Subset nicht lesen: Datei existiert nicht.\nErzeuge zuerst ein Subset im Inspector (View -> AutoIngest Subset schreiben)."
  end
  local txt = f:read("*a")
  f:close()

  local json, errJ = df95_load_json_core()
  if not json then
    return nil, errJ or "JSON-Core konnte nicht geladen werden."
  end

  local ok, data = pcall(function() return json.decode(txt) end)
  if not ok or type(data) ~= "table" then
    return nil, "AutoIngest-Subset ist keine gueltige JSON-Liste."
  end

  local min_len = min_length or 20.0
  if min_len < 1.0 then min_len = 1.0 end

  local candidates = {}
  local total = 0

  for _, v in ipairs(data) do
    if type(v) == "string" and v ~= "" then
      total = total + 1
      local src = r.PCM_Source_CreateFromFile(v)
      if src then
        local len = r.GetMediaSourceLength(src)
        if len >= min_len then
          local name = get_file_name(v)
          candidates[#candidates+1] = {
            path = v,
            name = name,
            length = len,
            use = true,
          }
        end
        -- Source ist jetzt dem Projekt nicht zugeordnet; REAPER entsorgt ihn spaeter, kein explizites Destroy notwendig.
      end
    end
  end

  if #candidates == 0 then
    return {}, string.format("Subset geladen (%d Eintraege), aber keine Files laenger als %.1f s gefunden.", total, min_len)
  end

  return candidates, string.format("Subset geladen: %d Eintraege, %d Kandidaten >= %.1f s.", total, #candidates, min_len)
end

----------------------------------------------------------------
-- Drone/Atmos Layout-Erzeugung
----------------------------------------------------------------

local function ensure_track_by_name(name)
  local num_tracks = r.CountTracks(0)
  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(0, i)
    local _, tr_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if tr_name == name then
      return tr
    end
  end
  r.InsertTrackAtIndex(num_tracks, false)
  local tr = r.GetTrack(0, num_tracks)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function add_item_on_track(track, filepath, pos, fade_in, fade_out)
  local src = r.PCM_Source_CreateFromFile(filepath)
  if not src then return false end
  local item = r.AddMediaItemToTrack(track)
  local take = r.AddTakeToMediaItem(item)
  r.SetMediaItemTake_Source(take, src)
  r.SetMediaItemInfo_Value(item, "D_POSITION", pos or 0.0)
  -- Fades
  local fi = fade_in or 0.5
  local fo = fade_out or 0.5
  if fi > 0 then
    r.SetMediaItemInfo_Value(item, "D_FADEINLEN", fi)
  end
  if fo > 0 then
    r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fo)
  end
  return true
end

local function apply_drone_fx_to_track(track)
  if not track then return end
  -- Versuche zuerst, das JSFX DF95_Drone_Granular zu laden
  local idx = r.TrackFX_AddByName(track, "DF95_Drone_Granular", false, -1)
  -- Optional: wenn vorhanden, kann der User im Anschluss die FXChain DF95_DroneFX_Rack_V1 laden
  -- oder Coloring/Master-Chains ergaenzen. Hier wird nur der Kern-GranularFX garantiert.
end

local function build_drones(candidates, layout_mode, base_time, offset_step, fade_in, fade_out, apply_fx)
  local count = 0
  local cursor = base_time or r.GetCursorPosition()
  local mode = layout_mode or "TRACKS"
  local step = offset_step or 2.0
  if step < 0.1 then step = 0.1 end
  local fi = fade_in or 0.5
  local fo = fade_out or 0.5

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  if mode == "STACK" then
    local tr = ensure_track_by_name("DRONE_STACK")
    local pos = cursor
    for _, c in ipairs(candidates) do
      if c.use then
        if add_item_on_track(tr, c.path, pos, fi, fo) then
          count = count + 1
          pos = pos + step
        end
      end
    end
    if apply_fx then
      apply_drone_fx_to_track(tr)
    end
  else
    local pos = cursor
    for _, c in ipairs(candidates) do
      if c.use then
        local base_name = c.name or "DRONE"
        local tr = ensure_track_by_name("DRONE_" .. base_name)
        if add_item_on_track(tr, c.path, pos, fi, fo) then
          count = count + 1
          if apply_fx then
            apply_drone_fx_to_track(tr)
          end
          pos = pos + step
        end
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 Drone/Atmos Builder from View", -1)

  return count
end

----------------------------------------------------------------
-- ImGui Setup
----------------------------------------------------------------

local ctx = nil
local open_flag = true

local state = {
  candidates = {},
  last_msg = "",
  min_len = 20.0,
  name_filter = "",
  layout_mode = "TRACKS", -- or "STACK"
  offset_step = 4.0,
  fade_in = 1.0,
  fade_out = 1.0,
  apply_fx = true,
  auto_launch_wizard = false,
}


local function run_named_command(cmd_name)
  if not cmd_name or cmd_name == "" then return end
  local cmd = r.NamedCommandLookup(cmd_name)
  if cmd and cmd ~= 0 then
    r.Main_OnCommand(cmd, 0)
  end
end

local function set_export_preset(preset_id)
  if not preset_id or preset_id == "" then return end
  r.SetExtState("DF95_EXPORT", "current_preset_id", tostring(preset_id), true)
end

local function auto_export_with_preset(preset_id)
  if not preset_id or preset_id == "" then return end
  set_export_preset(preset_id)
  state.last_msg = "Export-Preset gesetzt: " .. tostring(preset_id) .. " (TimeSelection + DF95_Export_Wizard verwenden)."
  if state.auto_launch_wizard then
    run_named_command("_DF95_EXPORT_WIZARD")
  end
end


local function apply_name_filter(cands, filter_str)
  if not filter_str or filter_str == "" then
    return cands
  end
  local out = {}
  local needle = filter_str:lower()
  for _, c in ipairs(cands or {}) do
    if c.name and c.name:lower():find(needle, 1, true) then
      out[#out+1] = c
    end
  end
  return out
end

local function render_gui()
  r.ImGui_Text(ctx, "DF95 Drone/Atmos Builder from SampleDB View")
  r.ImGui_Separator(ctx)

  if r.ImGui_Button(ctx, "Subset laden (DF95_AutoIngest_Subset.json)") then
    local cands, msg = load_subset_with_lengths(state.min_len or 20.0)
    state.candidates = cands or {}
    state.last_msg = msg or ""
  end

  r.ImGui_SameLine(ctx)
  local changed_min, new_min = r.ImGui_InputDouble(ctx, "Mindestlaenge (s)", state.min_len or 20.0, 1.0, 5.0, "%.1f")
  if changed_min then
    if new_min < 1.0 then new_min = 1.0 end
    state.min_len = new_min
  end

  if state.last_msg ~= "" then
    r.ImGui_TextWrapped(ctx, state.last_msg)
  end

  r.ImGui_Separator(ctx)

  local changed_filter, new_filter = r.ImGui_InputText(ctx, "Name-Filter (z.B. amb, room, emf, night)", state.name_filter or "", 256)
  if changed_filter then
    state.name_filter = new_filter
  end

  local layout_tracks = (state.layout_mode == "TRACKS")
  if r.ImGui_RadioButton(ctx, "ein Track pro Drone", layout_tracks) then
    state.layout_mode = "TRACKS"
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_RadioButton(ctx, "alles auf DRONE_STACK", not layout_tracks) then
    state.layout_mode = "STACK"
  end

  local changed_step, new_step = r.ImGui_InputDouble(ctx, "Zeitabstand zwischen Items (s)", state.offset_step or 4.0, 0.5, 2.0, "%.1f")
  if changed_step then
    if new_step < 0.1 then new_step = 0.1 end
    state.offset_step = new_step
  end

  local changed_fi, new_fi = r.ImGui_InputDouble(ctx, "Fade-in (s)", state.fade_in or 1.0, 0.1, 0.5, "%.2f")
  if changed_fi then
    if new_fi < 0.0 then new_fi = 0.0 end
    state.fade_in = new_fi
  end

  local changed_fo, new_fo = r.ImGui_InputDouble(ctx, "Fade-out (s)", state.fade_out or 1.0, 0.1, 0.5, "%.2f")
  if changed_fo then
    if new_fo < 0.0 then new_fo = 0.0 end
    state.fade_out = new_fo
  end

  local changed_fx, new_fx = r.ImGui_Checkbox(ctx, "DroneFX V1 (DF95_Drone_Granular) automatisch auf Tracks anwenden", state.apply_fx)
  if changed_fx then
    state.apply_fx = new_fx and true or false
  end

  r.ImGui_Separator(ctx)

  local filtered = apply_name_filter(state.candidates or {}, state.name_filter)
  local total = #state.candidates
  local shown = #filtered

  r.ImGui_Text(ctx, string.format("Kandidaten: %d gesamt, %d angezeigt (Filter).", total, shown))

  if r.ImGui_Button(ctx, "Alle markieren") then
    for _, c in ipairs(state.candidates or {}) do
      c.use = true
    end
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Alle abwaehlen") then
    for _, c in ipairs(state.candidates or {}) do
      c.use = false
    end
  end

  r.ImGui_Separator(ctx)

  if r.ImGui_BeginChild(ctx, "drone_list_scroller", -1, 200, true) then
    for _, c in ipairs(filtered) do
      local use = c.use ~= false
      local changed_use, new_use = r.ImGui_Checkbox(ctx, c.name .. string.format(" (%.1f s)", c.length or 0.0), use)
      if changed_use then
        c.use = new_use
      end
    end
    r.ImGui_EndChild(ctx)
  end

  r.ImGui_Separator(ctx)

  if r.ImGui_Button(ctx, "Drones/Atmos im Projekt anlegen (ab Cursor)") then
    local count = build_drones(state.candidates or {}, state.layout_mode, nil, state.offset_step, state.fade_in, state.fade_out, state.apply_fx)
    if count > 0 then
      state.last_msg = string.format("%d Drone/Atmos-Items im Projekt erzeugt.", count)
    else
      state.last_msg = "Keine Items erzeugt (evtl. keine Kandidaten oder alle abwaehlt)."
    end
  end

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Export-Schnellzugriff (setzt Export-Preset):")

  local changed_auto, new_auto = r.ImGui_Checkbox(ctx, "Export Wizard nach Preset-Auswahl automatisch starten", state.auto_launch_wizard)
  if changed_auto then
    state.auto_launch_wizard = new_auto and true or false
  end

  if r.ImGui_Button(ctx, "Home Drone Atmos (Loop) Preset setzen") then
    auto_export_with_preset("DRONE_HOME_ATMOS_LOOP")
  end

  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "EMF Drone Longform Preset setzen") then
    auto_export_with_preset("DRONE_EMF_DRONE_LONG")
  end

  if r.ImGui_Button(ctx, "IDM Drone Texture (Loop) Preset setzen") then
    auto_export_with_preset("DRONE_IDM_TEXTURE_LONG")
  end

end

local function loop()
  if not ctx then
    ctx = r.ImGui_CreateContext("DF95 Drone/Atmos Builder from View")
  end

  if not open_flag then
    return
  end

  local visible, open = r.ImGui_Begin(ctx, "DF95 Drone/Atmos Builder from View", true)
  if visible then
    render_gui()
    r.ImGui_End(ctx)
  end

  open_flag = open
  if open_flag then
    r.defer(loop)
  else
    if ctx then
      r.ImGui_DestroyContext(ctx)
      ctx = nil
    end
  end
end

loop()
