-- @description DF95 Export Preset Picker (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Ein kleiner ImGui-Dialog zum Auswaehlen von DF95 Export Presets
--   (inkl. Drone/Atmos Presets). Setzt die ExtState DF95_EXPORT.current_preset_id,
--   so dass DF95_Export_Wizard.lua dieses Preset uebernimmt.

local r = reaper

----------------------------------------------------------------
-- Preset-Module laden
----------------------------------------------------------------

local function df95_load_export_presets()
  local ok, mod, err = pcall(function()
    local info = debug.getinfo(1, "S")
    local script_path = info and info.source:match("^@(.+)$")
    if not script_path then
      error("Script-Pfad konnte nicht ermittelt werden.")
    end
    local dir = script_path:match("^(.*[\\/])") or ""
    local core_path = dir .. "DF95_Export_Presets.lua"
    local chunk, load_err = loadfile(core_path)
    if not chunk then
      error("DF95_Export_Presets.lua konnte nicht geladen werden: " .. tostring(load_err))
    end
    local m = chunk()
    return m
  end)
  if not ok or not mod then
    return nil, "Export Presets konnten nicht geladen werden: " .. tostring(mod or err)
  end
  if type(mod.get_list) ~= "function" then
    return nil, "Export Presets Modul enthaelt keine get_list()-Funktion."
  end
  return mod, nil
end

----------------------------------------------------------------
-- State
----------------------------------------------------------------

local ctx = nil
local open_flag = true

local state = {
  presets = {},
  last_msg = "",
  filter_text = "",
  show_only_drone = true,
  current_id = "",
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function is_drone_preset(p)
  if not p or type(p) ~= "table" then return false end
  if p.id and tostring(p.id):match("^DRONE_") then
    return true
  end
  local opts = p.opts
  if type(opts) == "table" and opts.role and tostring(opts.role):lower() == "drone" then
    return true
  end
  return false
end

local function load_presets()
  local mod, err = df95_load_export_presets()
  if not mod then
    state.presets = {}
    state.last_msg = err or "Unbekannter Fehler beim Laden der Presets."
    return
  end
  local ok, list = pcall(function() return mod.get_list() end)
  if not ok or type(list) ~= "table" then
    state.presets = {}
    state.last_msg = "Preset-Liste konnte nicht abgefragt werden."
    return
  end
  state.presets = list
  local cur = r.GetExtState("DF95_EXPORT", "current_preset_id") or ""
  state.current_id = cur
  state.last_msg = string.format("Presets geladen: %d Eintraege. Aktuelles Preset: %s", #list, cur ~= "" and cur or "<kein>")
end

local function passes_filters(p)
  if state.show_only_drone and not is_drone_preset(p) then
    return false
  end
  local ft = state.filter_text
  if ft and ft ~= "" then
    local needle = ft:lower()
    local label = (p.label or ""):lower()
    local id = (p.id or ""):lower()
    if (not label:find(needle, 1, true)) and (not id:find(needle, 1, true)) then
      return false
    end
  end
  return true
end

local function set_current_preset(id)
  if not id or id == "" then
    return
  end
  r.SetExtState("DF95_EXPORT", "current_preset_id", tostring(id), true)
  state.current_id = tostring(id)
  state.last_msg = "Aktuelles Export-Preset gesetzt: " .. tostring(id)
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------

local function render_gui()
  r.ImGui_Text(ctx, "DF95 Export Preset Picker")
  r.ImGui_Separator(ctx)

  if r.ImGui_Button(ctx, "Presets neu laden") then
    load_presets()
  end

  r.ImGui_SameLine(ctx)
  local changed_filter, new_filter = r.ImGui_InputText(ctx, "Filter (Label/ID)", state.filter_text or "", 256)
  if changed_filter then
    state.filter_text = new_filter
  end

  local changed_drone, new_drone = r.ImGui_Checkbox(ctx, "Nur Drone/Atmos Presets anzeigen", state.show_only_drone)
  if changed_drone then
    state.show_only_drone = new_drone and true or false
  end

  if state.last_msg ~= "" then
    r.ImGui_TextWrapped(ctx, state.last_msg)
  end

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Aktuelles Preset: " .. (state.current_id ~= "" and state.current_id or "<kein>"))
  r.ImGui_Separator(ctx)

  if r.ImGui_BeginChild(ctx, "preset_list", -1, 260, true) then
    for _, p in ipairs(state.presets or {}) do
      if passes_filters(p) then
        local is_current = (state.current_id == p.id)
        local label = p.label or (p.id or "<ohne ID>")
        local line = label .. "  [" .. (p.id or "?") .. "]"
        if is_current then
          line = line .. "  (AKTIV)"
        end

        if r.ImGui_Selectable(ctx, line, is_current) then
          set_current_preset(p.id)
        end

        -- Kurzinfo zum Preset
        local opts = p.opts or {}
        local mode  = opts.mode or ""
        local target = opts.target or ""
        local cat   = opts.category or ""
        local role  = opts.role or ""
        local src   = opts.source or ""
        local flavor = opts.fxflavor or ""
        r.ImGui_Text(ctx, string.format("   Mode=%s  Target=%s  Cat=%s  Role=%s  Src=%s  FX=%s", mode, target, cat, role, src, flavor))
      end
    end
    r.ImGui_EndChild(ctx)
  end

  r.ImGui_Separator(ctx)
  r.ImGui_TextWrapped(ctx, "Hinweis: Nach der Auswahl hier einfach DF95_Export_Wizard.lua starten – dieser uebernimmt das aktuell gesetzte Preset automatisch ueber DF95_EXPORT.current_preset_id.")
end

local function loop()
  if not ctx then
    ctx = r.ImGui_CreateContext("DF95 Export Preset Picker")
    load_presets()
  end

  if not open_flag then
    return
  end

  local visible, open = r.ImGui_Begin(ctx, "DF95 Export Preset Picker", true)
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
