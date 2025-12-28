-- @description DF95_Global_BeatPresetLoader_ImGui
-- @version 2.0
-- @author DF95
-- @about
--   Globaler Beat-Preset-Loader fuer das DF95-Oekosystem.
--   Laedt Presets aus Data/DF95/DF95_BeatGlobalPresets.lua
--   und wendet sie auf das aktuelle Projekt an:
--     - DF95_ARTIST / NAME
--     - DF95_AI_BEAT / BPM, TS_NUM, TS_DEN, BARS
--     - DF95_SAMPLER / ENGINE
--     - DF95_SAMPLER / SITALA_KIT (falls vorhanden)
--     - Projekt-Tempo und -Takt
--
--   Zusaetzlich:
--     - Artist-Samples aus SampleDB_Index_V2.json (AIWorker)
--     - Buttons: Build Sitala/RS5k/TX16Wx Artist Kit aus SampleDB.

local r = reaper
local ImGui = r.ImGui or reaper.ImGui

if not (ImGui and (r.ImGui_CreateContext or ImGui.CreateContext)) then
  r.ShowMessageBox("ReaImGui ist nicht installiert. Bitte ueber ReaPack nachinstallieren.", "DF95 Global Beat Preset Loader", 0)
  return
end

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

------------------------------------------------------------
-- Helper: Files / Paths
------------------------------------------------------------

local function join(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function normalize(path)
  if sep == "\\" then
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

------------------------------------------------------------
-- SampleDB Index V2 Loader (AIWorker)
------------------------------------------------------------

local function DF95_LoadSampleDB_IndexV2()
  local path = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_SampleDB_IndexV2_Loader.lua"
  path = normalize(path)
  if not file_exists(path) then return {} end
  local ok, mod = pcall(dofile, path)
  if ok and type(mod) == "table" and type(mod.index) == "table" then
    return mod.index
  end
  return {}
end

local DF95_SAMPLEDB_V2 = DF95_LoadSampleDB_IndexV2()

------------------------------------------------------------
-- Global Presets laden
------------------------------------------------------------

local function load_global_presets()
  local dd = normalize(join(join(res, "Data"), "DF95"))
  local path = join(dd, "DF95_BeatGlobalPresets.lua")
  if not file_exists(path) then
    return {}
  end
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler beim Laden von DF95_BeatGlobalPresets.lua:\n" .. tostring(mod), "DF95 Global Beat Preset Loader", 0)
    return {}
  end
  if type(mod) == "table" and mod.presets and type(mod.presets) == "table" then
    return mod.presets
  elseif type(mod) == "table" then
    return mod
  end
  return {}
end

------------------------------------------------------------
-- Preset anwenden
------------------------------------------------------------

local function apply_preset(p)
  if not p then return end

  local artist = p.artist or ""
  local name   = p.name   or ""

  local bpm   = tonumber(p.bpm)  or 120
  local ts_n  = tonumber(p.ts_n) or 4
  local ts_d  = tonumber(p.ts_d) or 4
  local bars  = tonumber(p.bars) or 4

  local engine    = p.sampler_engine or "RS5K"
  local sitala_kit = p.sitala_kit

  -- ExtStates setzen
  r.SetProjExtState(0, "DF95_ARTIST", "NAME", artist)
  r.SetProjExtState(0, "DF95_ARTIST", "PRESET_NAME", name)

  r.SetProjExtState(0, "DF95_AI_BEAT", "BPM", tostring(bpm))
  r.SetProjExtState(0, "DF95_AI_BEAT", "TS_NUM", tostring(ts_n))
  r.SetProjExtState(0, "DF95_AI_BEAT", "TS_DEN", tostring(ts_d))
  r.SetProjExtState(0, "DF95_AI_BEAT", "BARS", tostring(bars))

  r.SetProjExtState(0, "DF95_SAMPLER", "ENGINE", engine)
  if sitala_kit then
    r.SetProjExtState(0, "DF95_SAMPLER", "SITALA_KIT", tostring(sitala_kit))
  end

  -- Projekt-Tempo und -Takt setzen
  r.SetCurrentBPM(0, bpm, true)
  if r.SetProjectTimeSignature2 then
    r.SetProjectTimeSignature2(0, ts_n, ts_d, 0)
  end
end

------------------------------------------------------------
-- KitSchema + Adapter Helpers (aus SampleDB V2)
------------------------------------------------------------

local function filter_samples_by_artist(db, artist_name)
  local result = {}
  if not db or type(db) ~= "table" or not artist_name or artist_name == "" then
    return result
  end
  for _, e in ipairs(db) do
    local fits = e.artist_fit
    if type(fits) == "table" then
      for _, a in ipairs(fits) do
        if a == artist_name then
          table.insert(result, e)
          break
        end
      end
    end
  end
  return result
end

local function get_filename_from_entry(e)
  if e.file and type(e.file) == "string" and e.file ~= "" then
    local name = e.file:match("([^/\\]+)$")
    return name or e.file
  end
  if e.sample_id and type(e.sample_id) == "string" then
    return e.sample_id
  end
  return "<unnamed>"
end

local function build_artist_kit_from_sampledb_for_preset(preset, max_slots)
  if not preset or not preset.artist or preset.artist == "" then
    r.ShowMessageBox("Preset hat keinen Artist-Namen.", "DF95 Global Beat Preset Loader", 0)
    return nil
  end

  local entries = filter_samples_by_artist(DF95_SAMPLEDB_V2, preset.artist)
  if #entries == 0 then
    r.ShowMessageBox("Keine SampleDB-Eintraege fuer Artist '" .. tostring(preset.artist) .. "' gefunden.", "DF95 Global Beat Preset Loader", 0)
    return nil
  end

  if max_slots and type(max_slots) == "number" and #entries > max_slots then
    local trimmed = {}
    for i = 1, max_slots do
      trimmed[i] = entries[i]
    end
    entries = trimmed
  end

  local kit_schema_path = normalize(res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Sampler_KitSchema.lua")
  local ok, KitSchema = pcall(dofile, kit_schema_path)
  if not ok or not KitSchema or type(KitSchema.build_from_sampledb_entries) ~= "function" then
    r.ShowMessageBox("KitSchema konnte nicht geladen werden:\n" .. tostring(KitSchema), "DF95 Global Beat Preset Loader", 0)
    return nil
  end

  local bpm = tonumber(preset.bpm) or 0

  local kit = KitSchema.build_from_sampledb_entries(entries, {
    name      = string.format("DF95 %s GlobalKit", tostring(preset.artist)),
    artist    = preset.artist,
    source    = "SampleDB_V2",
    bpm       = bpm,
    base_note = 36,
  })
  return kit
end

local function build_rs5k_kit_for_preset(preset)
  local kit = build_artist_kit_from_sampledb_for_preset(preset, 32)
  if not kit then return end

  local rs5k_path = normalize(res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Sampler_Kit_To_RS5K.lua")
  local ok, RS5K = pcall(dofile, rs5k_path)
  if not ok or not RS5K or type(RS5K.build_on_new_track) ~= "function" then
    r.ShowMessageBox("RS5k-Adapter konnte nicht geladen werden:\n" .. tostring(RS5K), "DF95 Global Beat Preset Loader", 0)
    return
  end

  local track_name = (kit.meta and kit.meta.name) or "DF95_RS5K_GlobalKit"
  RS5K.build_on_new_track(kit, { track_name = track_name })
end

local function build_sitala_kit_for_preset(preset)
  local kit = build_artist_kit_from_sampledb_for_preset(preset, 16)
  if not kit then return end

  local sitala_path = normalize(res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Sampler_Kit_To_Sitala.lua")
  local ok, SITA = pcall(dofile, sitala_path)
  if not ok or not SITA or type(SITA.ensure_sitala_and_print_mapping) ~= "function" then
    r.ShowMessageBox("Sitala-Adapter konnte nicht geladen werden:\n" .. tostring(SITA), "DF95 Global Beat Preset Loader", 0)
    return
  end

  SITA.ensure_sitala_and_print_mapping(kit)
end

local function build_tx16wx_kit_for_preset(preset)
  local kit = build_artist_kit_from_sampledb_for_preset(preset, 64)
  if not kit then return end

  local tx_path = normalize(res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Sampler_Kit_To_TX16Wx.lua")
  local ok, TX = pcall(dofile, tx_path)
  if not ok or not TX or type(TX.build_sfz_for_kit) ~= "function" then
    r.ShowMessageBox("TX16Wx-Adapter konnte nicht geladen werden:\n" .. tostring(TX), "DF95 Global Beat Preset Loader", 0)
    return
  end

  local sfz_path = TX.build_sfz_for_kit(kit, nil)
  if sfz_path and sfz_path ~= "" then
    r.ShowMessageBox("TX16Wx SFZ-File fuer dieses Artist-Kit wurde erzeugt:\n" .. sfz_path .. "\n\nBitte in TX16Wx laden.", "DF95 Global Beat Preset Loader", 0)
  end
end

------------------------------------------------------------
-- ImGui / UI
------------------------------------------------------------

local ctx = ImGui.CreateContext("DF95 Global Beat Preset Loader")

local presets = load_global_presets()
local selected_index = (presets[1] and 1) or 0

local function draw_preset_list()
  ImGui.Text(ctx, "Global Beat-Presets")
  ImGui.Separator(ctx)

  if #presets == 0 then
    ImGui.TextWrapped(ctx, "Keine Global-Presets gefunden. Erwartet: Data/DF95/DF95_BeatGlobalPresets.lua")
    return
  end

  ImGui.BeginChild(ctx, "PresetList", 260, 260, true)
  for i, p in ipairs(presets) do
    local label = string.format("%2d: %s [%s] %d/%d @ %d bpm",
      i,
      p.name or (p.id or ("Preset "..i)),
      p.artist or "?",
      tonumber(p.ts_n) or 4,
      tonumber(p.ts_d) or 4,
      tonumber(p.bpm) or 120
    )
    local sel = (selected_index == i)
    if ImGui.Selectable(ctx, label, sel) then
      selected_index = i
    end
  end
  ImGui.EndChild(ctx)
end

local function draw_preset_detail()
  local p = (selected_index > 0) and presets[selected_index] or nil
  if not p then
    ImGui.TextWrapped(ctx, "Kein Preset ausgewaehlt.")
    return
  end

  ImGui.Text(ctx, "Ausgewaehltes Preset:")
  ImGui.Text(ctx, "ID: " .. (p.id or ""))
  ImGui.Text(ctx, "Artist: " .. (p.artist or ""))
  ImGui.Text(ctx, "Name: " .. (p.name or ""))
  ImGui.Text(ctx, string.format("Beat: %d Bars, %d/%d @ %d BPM",
    tonumber(p.bars) or 4,
    tonumber(p.ts_n) or 4,
    tonumber(p.ts_d) or 4,
    tonumber(p.bpm) or 120
  ))
  ImGui.Text(ctx, "Sampler Engine: " .. (p.sampler_engine or "RS5K"))
  if p.sitala_kit then
    ImGui.Text(ctx, "Sitala Kit: " .. tostring(p.sitala_kit))
  end

  if ImGui.Button(ctx, "Preset anwenden (Artist + Beat + Sampler)", 320, 0) then
    r.Undo_BeginBlock()
    apply_preset(p)
    r.Undo_EndBlock("DF95 Global Beat Preset Loader: Apply Preset", -1)
  end

  ImGui.Separator(ctx)

  -- SampleDB / Artist-Kits Panel
  ImGui.Text(ctx, "SampleDB / Artist-Kits")
  if not DF95_SAMPLEDB_V2 or #DF95_SAMPLEDB_V2 == 0 then
    ImGui.TextColored(ctx, 1.0, 0.6, 0.3, 1.0, "SampleDB_Index_V2 ist leer oder nicht geladen.")
    ImGui.TextWrapped(ctx, "Bitte AIWorker Ingest ausfuehren (DF95_AIWorker_Hub_ImGui).")
    return
  end

  local artist = p.artist or ""
  ImGui.Text(ctx, "Artist: " .. artist)

  local entries = filter_samples_by_artist(DF95_SAMPLEDB_V2, artist)
  local count = #entries
  ImGui.Text(ctx, string.format("SampleDB-Eintraege fuer Artist: %d", count))

  if count > 0 and ImGui.CollapsingHeader(ctx, "Beispiel-Samples", ImGui.TreeNodeFlags_None or 0) then
    local max_show = math.min(count, 12)
    for i = 1, max_show do
      local e = entries[i]
      ImGui.BulletText(ctx, "%s", get_filename_from_entry(e))
    end
    if count > max_show then
      ImGui.Text(ctx, string.format("... (%d weitere)", count - max_show))
    end
  end

  ImGui.Spacing(ctx)
  ImGui.Text(ctx, "Artist-Kits bauen:")

  if ImGui.Button(ctx, "Build Sitala Artist Kit", 260, 0) then
    build_sitala_kit_for_preset(p)
  end
  if ImGui.Button(ctx, "Build RS5k Artist Kit", 260, 0) then
    build_rs5k_kit_for_preset(p)
  end
  if ImGui.Button(ctx, "Build TX16Wx Artist Kit (SFZ)", 260, 0) then
    build_tx16wx_kit_for_preset(p)
  end
end

local function main_loop()
  ImGui.SetNextWindowSize(ctx, 780, 420, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "DF95 Global Beat Preset Loader", true)
  if visible then
    if ImGui.Button(ctx, "Presets neu laden", 180, 0) then
      presets = load_global_presets()
      selected_index = (presets[1] and 1) or 0
    end

    ImGui.SameLine(ctx)
    ImGui.Text(ctx, string.format("Presets: %d  |  SampleDB V2: %d Eintraege", #presets, #(DF95_SAMPLEDB_V2 or {})))

    ImGui.Separator(ctx)

    ImGui.Columns(ctx, 2)
    draw_preset_list()
    ImGui.NextColumn()
    draw_preset_detail()
    ImGui.Columns(ctx, 1)

  end
  ImGui.End(ctx)

  if open then
    r.defer(main_loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

main_loop()
