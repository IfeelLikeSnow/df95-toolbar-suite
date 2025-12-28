
-- @description DF95: Auto SuperPipeline – MicFX + ExportTags
-- @version 1.0
-- @author DF95
-- @about
--   Führt in einem Schritt aus:
--   - AutoMic-Analyse der ausgewählten Tracks (Name → Recorder/Mic/Pattern/Channels)
--   - Einfügen der passenden Mic-FXChain (Mic_*.RfxChain)
--   - Setzen von ExportTags (MicModel, RecMedium, MicPattern, MicChannels) via DF95_Export_Core
--
--   Kann auf 1..N selektierten Tracks ausgeführt werden.
--
--   Erfordert:
--   - DF95_Auto_MicTagger.lua
--   - optional DF95_Export_Core.lua (für ExportTag-Integration)
--
--   Hinweis:
--   - Die FXChain-Datei muss im FXChains-Pfad vorhanden sein.
--   - Namen der Chains folgen der DF95_Chain_Naming_Policy.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local root = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep
  return (root:gsub("\\","/"))
end

local function load_tagger()
  local ok, mod = pcall(dofile, df95_root() .. "DF95_Auto_MicTagger.lua")
  if not ok or type(mod) ~= "table" then
    r.ShowMessageBox("DF95_Auto_MicTagger.lua konnte nicht geladen werden.\nAbbruch.",
                     "DF95 Auto SuperPipeline", 0)
    return nil
  end
  return mod
end

local function load_export_core()
  local ok, mod = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  if not ok or type(mod) ~= "table" then
    return nil
  end
  return mod
end

local function insert_mic_chain_for_track(tr, info)
  if not tr or not info then return end
  local chain = info.chain
  if not chain or chain == "" then return end

  local idx = r.TrackFX_AddByName(tr, chain, false, -1)
  if idx < 0 then
    -- Versuch mit Pfad relativ zum FXChains-Ordner
    local fxroot = r.GetResourcePath() .. "/FXChains/"
    local alt = fxroot .. info.chain
    -- REAPER lädt FXChains nicht direkt per Pfad mit TrackFX_AddByName, daher nur Hinweis:
    r.ShowMessageBox(
      "FXChain '" .. chain .. "' konnte nicht automatisch geladen werden.\n" ..
      "Bitte prüfe, ob die Datei existiert (FXChains/…) und mit der DF95_Chain_Naming_Policy übereinstimmt.\n\n" ..
      "Erwarteter Name:\n" .. chain,
      "DF95 Auto SuperPipeline – MicFX", 0)
  end
end

local function set_export_tags_for(info, core)
  if not core or type(core.SetExportTag) ~= "function" then return end
  if not info then return end

  if info.model and info.model ~= "" then
    core.SetExportTag("MicModel", info.model)
  end
  if info.rec and info.rec ~= "" then
    core.SetExportTag("RecMedium", info.rec)
  end
  if info.pattern and info.pattern ~= "" then
    core.SetExportTag("MicPattern", info.pattern)
  end
  if info.ch and info.ch ~= "" then
    core.SetExportTag("MicChannels", info.ch)
  end
end

local function build_track_info(tr, tagger)
  local _, name = r.GetTrackName(tr)
  name = name or ""
  local rec = tagger.detect_recorder(name)
  local model, pattern, ch = tagger.detect_model(name)
  local chain = tagger.build_name(rec, model, pattern, ch)

  return {
    name = name,
    rec = rec,
    model = model,
    pattern = pattern,
    ch = ch,
    chain = chain,
  }
end

local function main()
  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("Keine selektierten Tracks.\nBitte 1–N Tracks auswählen, deren Namen Recorder/Mic enthalten (z.B. ZF6_MD400_Dialog).",
                     "DF95 Auto SuperPipeline", 0)
    return
  end

  local tagger = load_tagger()
  if not tagger then return end

  local export_core = load_export_core() -- optional

  local infos = {}

  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    local info = build_track_info(tr, tagger)
    infos[#infos+1] = { track = tr, info = info }
  end

  r.Undo_BeginBlock()

  -- Schritt 1: Mic-FXChains einfügen
  for _, t in ipairs(infos) do
    insert_mic_chain_for_track(t.track, t.info)
  end

  -- Schritt 2: ExportTags (MicModel/RecMedium/Pattern/Channels) setzen
  -- Hier verwenden wir das erste Track-Info-Objekt als Referenz für Projekt-weite ExportTags.
  if export_core and infos[1] then
    set_export_tags_for(infos[1].info, export_core)
  end

  r.Undo_EndBlock("DF95 Auto SuperPipeline – MicFX + ExportTags", -1)
end

main()
