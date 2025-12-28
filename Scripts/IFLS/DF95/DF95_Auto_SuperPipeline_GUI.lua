
-- @description DF95: Auto SuperPipeline GUI (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   GUI-Frontend für die DF95 Auto SuperPipeline:
--   - Zeigt alle selektierten Tracks mit AutoMic-Analyse
--   - Optionen:
--       [x] Mic-FXChains einfügen
--       [x] ExportTags (MicModel/RecMedium/…) setzen
--       [ ] AutoChainFix (MicChains normalisieren) – optional
--   - Button: "Run" – führt die gewählten Schritte aus.
--
--   Erfordert:
--   - ReaImGui
--   - DF95_Auto_MicTagger.lua
--   - optional DF95_Export_Core.lua
--   - optional DF95_AutoChain_Fixer.lua

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui nicht installiert.\nBitte ReaImGui nachrüsten oder das non-GUI Script 'DF95_Auto_SuperPipeline.lua' verwenden.",
                   "DF95 Auto SuperPipeline GUI", 0)
  return
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local root = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep
  return (root:gsub("\\","/"))
end

local function safe_load(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil end
  return mod
end

local tagger = safe_load(df95_root() .. "DF95_Auto_MicTagger.lua")
if not tagger then
  r.ShowMessageBox("DF95_Auto_MicTagger.lua konnte nicht geladen werden.\nAbbruch.",
                   "DF95 Auto SuperPipeline GUI", 0)
  return
end

local export_core = safe_load(df95_root() .. "DF95_Export_Core.lua") -- optional
local has_export  = (type(export_core) == "table" and type(export_core.SetExportTag) == "function")

local ctx = r.ImGui_CreateContext("DF95 Auto SuperPipeline")

local do_micfx = true
local do_exporttags = true
local do_chainfix = false

local tracks = {}

local function build_track_info(tr)
  local _, name = r.GetTrackName(tr)
  name = name or ""
  local rec = tagger.detect_recorder(name)
  local model, pattern, ch = tagger.detect_model(name)
  local chain = tagger.build_name(rec, model, pattern, ch)
  return {
    track = tr,
    name = name,
    rec = rec,
    model = model,
    pattern = pattern,
    ch = ch,
    chain = chain,
    index = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER"),
  }
end

local function refresh_tracks()
  tracks = {}
  local sel_count = r.CountSelectedTracks(0)
  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    tracks[#tracks+1] = build_track_info(tr)
  end
end

local function insert_mic_chain(tinfo)
  if not tinfo or not tinfo.track or not tinfo.chain or tinfo.chain == "" then return end
  local idx = r.TrackFX_AddByName(tinfo.track, tinfo.chain, false, -1)
  if idx < 0 then
    r.ShowMessageBox("FXChain '" .. tinfo.chain .. "' konnte nicht geladen werden.\n" ..
                     "Bitte prüfen, ob die Datei im FXChains-Pfad liegt.",
                     "DF95 Auto SuperPipeline – MicFX", 0)
  end
end

local function set_export_tags_from(info)
  if not has_export or not info then return end
  if info.model and info.model ~= "" then
    export_core.SetExportTag("MicModel", info.model)
  end
  if info.rec and info.rec ~= "" then
    export_core.SetExportTag("RecMedium", info.rec)
  end
  if info.pattern and info.pattern ~= "" then
    export_core.SetExportTag("MicPattern", info.pattern)
  end
  if info.ch and info.ch ~= "" then
    export_core.SetExportTag("MicChannels", info.ch)
  end
end

local function run_chainfix()
  -- optionaler Hook: DF95_AutoChain_Fixer.lua
  local fixer = safe_load(df95_root() .. "DF95_AutoChain_Fixer.lua")
  -- Das Script führt sich beim Laden selbst aus, daher hier kein weiterer Aufruf nötig.
end

local function run_pipeline()
  if #tracks == 0 then
    r.ShowMessageBox("Keine Tracks selektiert. Bitte 1–N Tracks auswählen.",
                     "DF95 Auto SuperPipeline", 0)
    return
  end

  r.Undo_BeginBlock()

  if do_micfx then
    for _, t in ipairs(tracks) do
      insert_mic_chain(t)
    end
  end

  if do_exporttags and has_export then
    -- erstes Track-Info-Objekt als Referenz
    set_export_tags_from(tracks[1])
  end

  if do_chainfix then
    run_chainfix()
  end

  r.Undo_EndBlock("DF95 Auto SuperPipeline (GUI)", -1)
end

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 Auto SuperPipeline", true,
    r.ImGui_WindowFlags_AlwaysAutoResize())

  if visible then
    r.ImGui_Text(ctx, "AutoMic → MicFX → ExportTags")
    r.ImGui_Separator(ctx)

    local sel_count = r.CountSelectedTracks(0)
    r.ImGui_Text(ctx, "Selektierte Tracks: " .. tostring(sel_count))
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Refresh") then
      refresh_tracks()
    end

    r.ImGui_Separator(ctx)
    _, do_micfx = r.ImGui_Checkbox(ctx, "Mic-FXChains einfügen", do_micfx)
    _, do_exporttags = r.ImGui_Checkbox(ctx, "ExportTags (MicModel/RecMedium/Pattern/Channels) setzen", do_exporttags)
    if not has_export then
      r.ImGui_SameLine(ctx)
      r.ImGui_Text(ctx, "(DF95_Export_Core.lua nicht gefunden)")
    end
    _, do_chainfix = r.ImGui_Checkbox(ctx, "AutoChainFix (MicChains normalisieren)", do_chainfix)

    r.ImGui_Separator(ctx)
    if r.ImGui_Button(ctx, "Run") then
      run_pipeline()
    end

    r.ImGui_Separator(ctx)

    if #tracks == 0 then
      r.ImGui_Text(ctx, "Keine Tracks in Liste. 'Refresh' drücken.")
    else
      for _, t in ipairs(tracks) do
        r.ImGui_Text(ctx, string.format("Track %d: %s", t.index, t.name or "(unbenannt)"))
        r.ImGui_Text(ctx, string.format("  Recorder: %s | Mic: %s | Pattern: %s | Ch: %s",
          t.rec, t.model, t.pattern, t.ch))
        r.ImGui_Text(ctx, "  FXChain: " .. (t.chain or "?"))
        r.ImGui_Separator(ctx)
      end
    end

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

refresh_tracks()
r.defer(loop)
