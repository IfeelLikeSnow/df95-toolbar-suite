\
-- @description DF95_Slicing_HybridAI_Hub_ImGui
-- @version 2.0
-- @author DF95
-- @about
--   ImGui-Frontend fuer DF95_Slicing_HybridAI_Engine.
--   Bietet verschiedene Slicing-Modes (Drum, IDM Micro, Fieldrec, Speech, Loop, Hybrid),
--   ein kleines Preset-System fuer die wichtigsten Parameter,
--   sowie optionalen Auto-Export in die SampleDB (HybridSlices JSONL).
--
--   Hinweis: ReaImGui erforderlich (ueber ReaPack).

local r = reaper
local ImGui = r.ImGui or reaper.ImGui

if not (ImGui and (r.ImGui_CreateContext or ImGui.CreateContext)) then
  r.ShowMessageBox("ReaImGui ist nicht installiert. Bitte ueber ReaPack nachinstallieren.", "DF95 Slicing HybridAI Hub", 0)
  return
end

----------------------------------------------------------------
-- ImGui / Context
----------------------------------------------------------------

local ctx = ImGui.CreateContext("DF95 Slicing HybridAI Hub")
local FONT_SCALE = 1.0

----------------------------------------------------------------
-- Pfad- und Datei-Utilities
----------------------------------------------------------------

local function sep()
  return package.config:sub(1,1)
end

local function join(a, b)
  local s = sep()
  if a:sub(-1) == s then
    return a .. b
  else
    return a .. s .. b
  end
end

local function normalize(path)
  local s = sep()
  if s == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local txt = f:read("*a")
  f:close()
  return txt
end

local function write_file(path, txt)
  local f, err = io.open(path, "w")
  if not f then return false, err end
  f:write(txt or "")
  f:close()
  return true
end

local function get_df95_data_dir()
  local base = r.GetResourcePath()
  local d = join(join(base, "Data"), "DF95")
  return normalize(d)
end

local function ensure_dir(path)
  -- simple: rely on OS mkdir via reaper.RecursiveCreateDirectory if available
  if r.RecursiveCreateDirectory then
    r.RecursiveCreateDirectory(path, 0)
  end
end

----------------------------------------------------------------
-- JSON-Helper (DF95_Json.lua)
----------------------------------------------------------------

local function load_json_helper()
  local base = r.GetResourcePath()
  local s = sep()
  local candidates = {
    join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95") .. s .. "DF95_Json.lua",
    join(join(base, "Scripts"), "DF95_Json.lua"),
  }
  for _, p in ipairs(candidates) do
    p = normalize(p)
    local f = io.open(p, "r")
    if f then
      f:close()
      local ok, mod = pcall(dofile, p)
      if ok and mod and type(mod.decode) == "function" and type(mod.encode) == "function" then
        return mod
      elseif ok and _G.json and type(_G.json.decode) == "function" and type(_G.json.encode) == "function" then
        return _G.json
      end
    end
  end
  return nil
end

local JSON = load_json_helper()

----------------------------------------------------------------
-- Engine-Modul laden
----------------------------------------------------------------

local function load_engine()
  local base = r.GetResourcePath()
  local path = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  path = join(path, "DF95_Slicing_HybridAI_Engine.lua")
  path = normalize(path)
  if not file_exists(path) then
    r.ShowMessageBox("DF95_Slicing_HybridAI_Engine.lua wurde nicht gefunden:\n" .. path, "DF95 Slicing HybridAI Hub", 0)
    return nil
  end
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler beim Laden der Engine:\n" .. tostring(mod), "DF95 Slicing HybridAI Hub", 0)
    return nil
  end
  return mod
end

local ENGINE = load_engine()

----------------------------------------------------------------
-- Mode-Profile (UI-Seite, muss zur Engine passen)
----------------------------------------------------------------

local MODE_LIST = { "drum", "idm_micro", "fieldrec", "speech", "loop", "hybrid" }

local MODE_PROFILES_UI = {
  drum = {
    window_ms  = 3.0,
    hop_ms     = 2.0,
    threshold  = 0.15,
    min_gap_ms = 25.0,
    search_zero_ms = 4.0,
    fade_in_ms = 1.5,
    fade_out_ms = 6.0,
  },
  idm_micro = {
    window_ms  = 2.0,
    hop_ms     = 1.0,
    threshold  = 0.10,
    min_gap_ms = 10.0,
    search_zero_ms = 3.0,
    fade_in_ms = 0.8,
    fade_out_ms = 4.0,
  },
  fieldrec = {
    window_ms  = 6.0,
    hop_ms     = 4.0,
    threshold  = 0.08,
    min_gap_ms = 200.0,
    search_zero_ms = 5.0,
    fade_in_ms = 4.0,
    fade_out_ms = 12.0,
  },
  speech = {
    window_ms  = 8.0,
    hop_ms     = 4.0,
    threshold  = 0.10,
    min_gap_ms = 130.0,
    search_zero_ms = 5.0,
    fade_in_ms = 2.0,
    fade_out_ms = 8.0,
  },
  loop = {
    window_ms  = 6.0,
    hop_ms     = 3.0,
    threshold  = 0.12,
    min_gap_ms = 50.0,
    search_zero_ms = 4.0,
    fade_in_ms = 1.5,
    fade_out_ms = 6.0,
  },
  hybrid = {
    window_ms  = 4.0,
    hop_ms     = 2.0,
    threshold  = 0.13,
    min_gap_ms = 30.0,
    search_zero_ms = 4.0,
    fade_in_ms = 1.5,
    fade_out_ms = 7.0,
  }
}

local function clone_t(t)
  local c = {}
  if t then
    for k, v in pairs(t) do
      if type(v) == "table" then
        c[k] = clone_t(v)
      else
        c[k] = v
      end
    end
  end
  return c
end

----------------------------------------------------------------
-- Preset-System
----------------------------------------------------------------

local PRESET_FILE = "HybridAI_Slicing_Presets.json"

local state = {
  mode_idx        = 1,
  auto_export     = false,
  preset_idx      = 1,
  presets         = {},
  cur_profile     = clone_t(MODE_PROFILES_UI["hybrid"]),
  msg             = "",
}

local function get_preset_file_path()
  local dd = get_df95_data_dir()
  ensure_dir(dd)
  return normalize(join(dd, PRESET_FILE))
end

local function load_presets_from_disk()
  local path = get_preset_file_path()
  if not file_exists(path) then
    state.presets = {}
    return
  end
  if not JSON then
    state.msg = "Kein JSON-Helper fuer Presets verfuegbar (DF95_Json.lua fehlt?)."
    return
  end
  local txt, err = read_file(path)
  if not txt then
    state.msg = "Preset-File konnte nicht gelesen werden: " .. tostring(err or "unbekannt")
    return
  end
  local ok, obj = pcall(JSON.decode, txt)
  if not ok or type(obj) ~= "table" or type(obj.presets) ~= "table" then
    state.msg = "Preset-JSON ungueltig."
    return
  end
  state.presets = obj.presets
  if #state.presets == 0 then
    state.preset_idx = 1
  else
    state.preset_idx = math.min(state.preset_idx, #state.presets)
  end
end

local function save_presets_to_disk()
  if not JSON then
    state.msg = "Presets koennen nicht gespeichert werden (kein JSON-Helper)."
    return
  end
  local path = get_preset_file_path()
  local obj = { presets = state.presets }
  local ok, txt = pcall(JSON.encode, obj)
  if not ok then
    state.msg = "Fehler beim JSON-Encode der Presets."
    return
  end
  local ok2, err = write_file(path, txt)
  if not ok2 then
    state.msg = "Fehler beim Schreiben der Preset-Datei: " .. tostring(err or "unbekannt")
  else
    state.msg = "Presets gespeichert."
  end
end

local function init_current_profile_from_mode()
  local mode = MODE_LIST[state.mode_idx] or "hybrid"
  state.cur_profile = clone_t(MODE_PROFILES_UI[mode] or MODE_PROFILES_UI["hybrid"])
end

local function apply_preset_to_state(p)
  if not p then return end
  -- Mode setzen
  if p.mode then
    for i, name in ipairs(MODE_LIST) do
      if name == p.mode then
        state.mode_idx = i
        break
      end
    end
  end
  if p.profile and type(p.profile) == "table" then
    state.cur_profile = clone_t(p.profile)
  else
    init_current_profile_from_mode()
  end
end

local function add_preset(name)
  if not name or name == "" then return end
  local mode = MODE_LIST[state.mode_idx] or "hybrid"
  local p = {
    name    = name,
    mode    = mode,
    profile = clone_t(state.cur_profile),
  }
  table.insert(state.presets, p)
  state.preset_idx = #state.presets
  save_presets_to_disk()
end

local function delete_current_preset()
  if #state.presets == 0 then return end
  table.remove(state.presets, state.preset_idx)
  if state.preset_idx > #state.presets then
    state.preset_idx = #state.presets
  end
  save_presets_to_disk()
end

----------------------------------------------------------------
-- Auto-Export to SampleDB (HybridSlices JSONL)
----------------------------------------------------------------

local function run_auto_export_if_enabled()
  if not state.auto_export then return end
  local base = r.GetResourcePath()
  local path = join(join(join(base, "Scripts"), "IfeelLikeSnow"), "DF95")
  path = join(path, "DF95_Slicing_HybridAI_ToSampleDB.lua")
  path = normalize(path)
  if not file_exists(path) then
    r.ShowMessageBox("Auto-Export ist aktiviert, aber DF95_Slicing_HybridAI_ToSampleDB.lua wurde nicht gefunden:\n" .. path,
      "DF95 Slicing HybridAI Hub", 0)
    return
  end
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler beim Auto-Export:\n" .. tostring(err), "DF95 Slicing HybridAI Hub", 0)
  end
end

----------------------------------------------------------------
-- Slicing-Ausfuehrung
----------------------------------------------------------------

local function run_slicing()
  if not ENGINE or not ENGINE.run then
    r.ShowMessageBox("HybridAI Engine konnte nicht geladen werden.", "DF95 Slicing HybridAI Hub", 0)
    return
  end

  local mode = MODE_LIST[state.mode_idx] or "hybrid"
  local num_sel = r.CountSelectedMediaItems(0)
  if num_sel == 0 then
    r.ShowMessageBox("Bitte zunaechst ein oder mehrere Items auswaehlen.", "DF95 Slicing HybridAI Hub", 0)
    return
  end

  local opts = {
    profile_override = clone_t(state.cur_profile),
  }

  ENGINE.run(mode, opts)

  run_auto_export_if_enabled()
end

----------------------------------------------------------------
-- UI-Drawing
----------------------------------------------------------------

local function draw_mode_section()
  ImGui.Text(ctx, "Mode")
  ImGui.SameLine(ctx)
  ImGui.Text(ctx, "(Profil & Presets)")

  local current = MODE_LIST[state.mode_idx] or "hybrid"
  if ImGui.BeginCombo(ctx, "Slicing Mode", current) then
    for i, m in ipairs(MODE_LIST) do
      local selected = (i == state.mode_idx)
      if ImGui.Selectable(ctx, m, selected) then
        state.mode_idx = i
        init_current_profile_from_mode()
      end
    end
    ImGui.EndCombo(ctx)
  end

  ImGui.Separator(ctx)
end

local function draw_profile_section()
  ImGui.Text(ctx, "Mode-Profil Feintuning")
  local p = state.cur_profile

  local changed
  changed, p.window_ms = ImGui.SliderDouble(ctx, "Analyse-Fenster (ms)", p.window_ms or 4.0, 1.0, 20.0, "%.1f")
  changed, p.hop_ms    = ImGui.SliderDouble(ctx, "Hop (ms)", p.hop_ms or 2.0, 0.5, 10.0, "%.1f")
  changed, p.threshold = ImGui.SliderDouble(ctx, "Transient-Threshold", p.threshold or 0.1, 0.01, 0.5, "%.2f")
  changed, p.min_gap_ms = ImGui.SliderDouble(ctx, "Min. Abstand zwischen Slices (ms)", p.min_gap_ms or 30.0, 5.0, 600.0, "%.1f")
  changed, p.search_zero_ms = ImGui.SliderDouble(ctx, "Zero-Cross-Suche +- (ms)", p.search_zero_ms or 4.0, 0.5, 20.0, "%.1f")
  changed, p.fade_in_ms = ImGui.SliderDouble(ctx, "Fade-In (ms)", p.fade_in_ms or 2.0, 0.1, 50.0, "%.1f")
  changed, p.fade_out_ms = ImGui.SliderDouble(ctx, "Fade-Out (ms)", p.fade_out_ms or 6.0, 0.1, 200.0, "%.1f")

  state.cur_profile = p
end

local function draw_preset_section()
  ImGui.Separator(ctx)
  ImGui.Text(ctx, "Presets")

  if #state.presets == 0 then
    ImGui.TextWrapped(ctx, "Noch keine User-Presets gespeichert. Du kannst aktuelle Einstellungen als Preset speichern.")
  else
    local names = {}
    for i, p in ipairs(state.presets) do
      names[i] = string.format("%d: %s [%s]", i, p.name or ("Preset "..i), p.mode or "hybrid")
    end
    local current = names[state.preset_idx] or names[1]
    if ImGui.BeginCombo(ctx, "Preset", current or "") then
      for i, label in ipairs(names) do
        local selected = (i == state.preset_idx)
        if ImGui.Selectable(ctx, label, selected) then
          state.preset_idx = i
          apply_preset_to_state(state.presets[i])
        end
      end
      ImGui.EndCombo(ctx)
    end
  end

  if ImGui.Button(ctx, "Preset speichern (Name abfragen)", 260, 0) then
    local ok, name = r.GetUserInputs("HybridAI Preset speichern", 1, "Preset-Name:", "")
    if ok and name and name ~= "" then
      add_preset(name)
    end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, "Preset loeschen", 160, 0) then
    delete_current_preset()
  end
end

local function draw_auto_export_section()
  ImGui.Separator(ctx)
  local changed, val = ImGui.Checkbox(ctx, "Auto-Export nach SampleDB (HybridSlices JSONL)", state.auto_export)
  if changed then
    state.auto_export = val
  end
  ImGui.TextWrapped(ctx, "Wenn aktiviert, wird nach jedem Slicing-Lauf automatisch DF95_Slicing_HybridAI_ToSampleDB.lua ausgefuehrt.")
end

local function draw_footer_help()
  ImGui.Separator(ctx)
  ImGui.Text(ctx, "Hinweise:")
  ImGui.BulletText(ctx, "Drum / IDM Micro fuer Drums und Microbeats.")
  ImGui.BulletText(ctx, "Fieldrec fuer laengere Fieldrecordings / Atmosphaeren.")
  ImGui.BulletText(ctx, "Speech fuer Sprache / Dialog.")
  ImGui.BulletText(ctx, "Loop fuer musikalische Phrasen / Riffs.")
  ImGui.BulletText(ctx, "Hybrid ist ein Allround-Profil zwischen Drum und Loop.")
end

----------------------------------------------------------------
-- Main Loop
----------------------------------------------------------------

local function main_loop()
  ImGui.SetNextWindowSize(ctx, 620, 540, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "DF95 Slicing HybridAI Hub", true)
  if visible then
    if ENGINE == nil then
      ImGui.TextColored(ctx, 1.0, 0.3, 0.3, 1.0, "Engine konnte nicht geladen werden. Bitte Installation pruefen.")
    else
      draw_mode_section()
      draw_profile_section()
      draw_preset_section()
      draw_auto_export_section()

      ImGui.Separator(ctx)
      if ImGui.Button(ctx, "Slicing jetzt ausfuehren (auf selektierte Items)", 360, 0) then
        run_slicing()
      end

      if state.msg and state.msg ~= "" then
        ImGui.Spacing(ctx)
        ImGui.TextColored(ctx, 0.9, 0.8, 0.3, 1.0, state.msg)
      end

      ImGui.Spacing(ctx)
      draw_footer_help()
    end
  end
  ImGui.End(ctx)

  if open then
    r.defer(main_loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

-- Initialisierung
init_current_profile_from_mode()
load_presets_from_disk()

main_loop()
