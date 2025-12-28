
-- @description Export – UCS Mic/Recorder From Trackname (AutoMicTagger)
-- @version 1.0
-- @author DF95
--
-- Nutzt DF95_Auto_MicTagger.lua, um aus Track-Namen
-- MicModel und RecMedium für die Export-Pipeline (UCS) vorzubelegen.
--
-- Erwartet:
-- - mindestens einen selektierten Track
-- - DF95_Export_Core.lua im gleichen Ordner
-- - DF95_Auto_MicTagger.lua im gleichen Ordner
--
-- Schreibt:
-- - ExportTag "MicModel"
-- - ExportTag "RecMedium"
--
-- Diese Tags können von DF95 Export Wizard / UCS-Tools weiterverwendet werden.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function main()
  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("Keine selektierten Tracks.\nBitte mindestens einen Track auswählen, dessen Name Recorder/Mic enthält (z.B. ZF6_MD400).",
                     "DF95 UCS Mic/Recorder (AutoMicTagger)", 0)
    return
  end

  local ok_core, core_or_err = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  local core = (ok_core and type(core_or_err) == "table") and core_or_err or nil

  local ok_tag, tagger_or_err = pcall(dofile, df95_root() .. "DF95_Auto_MicTagger.lua")
  if not ok_tag or type(tagger_or_err) ~= "table" then
    r.ShowMessageBox("DF95_Auto_MicTagger.lua konnte nicht geladen werden.\nAbbruch.",
                     "DF95 UCS Mic/Recorder (AutoMicTagger)", 0)
    return
  end
  local tagger = tagger_or_err

  local best = nil

  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    local _, name = r.GetTrackName(tr)
    local rec = tagger.detect_recorder(name or "")
    local model, pattern, ch = tagger.detect_model(name or "")
    local chain_name = tagger.build_name(rec, model, pattern, ch)

    best = {
      name = name or "",
      rec  = rec,
      model = model,
      pattern = pattern,
      ch = ch,
      chain = chain_name,
    }

    -- derzeit: erster Track reicht; könnte später erweitert werden
    break
  end

  if not best then
    r.ShowMessageBox("Keine verwertbaren Track-Namen gefunden.",
                     "DF95 UCS Mic/Recorder (AutoMicTagger)", 0)
    return
  end

  -- Vorschlag vorbereiten
  local mic_suggestion = best.model
  local rec_suggestion = best.rec

  -- Vorhandene Export-Tags als Default lesen (falls vorhanden)
  if core and core.GetExportTag then
    local prev_mic = core.GetExportTag("MicModel", "")
    local prev_rec = core.GetExportTag("RecMedium", "")
    if prev_mic ~= "" then mic_suggestion = prev_mic end
    if prev_rec ~= "" then rec_suggestion = prev_rec end
  end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  local cap = "MicModel(Leer=ignorieren),RecMedium(Recorder Name/Model)"
  local def = string.format("%s,%s", mic_suggestion or "", rec_suggestion or "")
  local ok, ret = r.GetUserInputs("DF95 UCS Mic/Recorder (AutoMicTagger)", 2,
                                  cap .. ",extrawidth=260", def)
  if not ok or not ret or ret == "" then return end

  local mic_in, rec_in = ret:match("^(.-),(.-)$")
  mic_in = trim(mic_in or mic_suggestion or "")
  rec_in = trim(rec_in or rec_suggestion or "")

  if core and core.SetExportTag then
    if mic_in ~= "" then core.SetExportTag("MicModel", mic_in) end
    if rec_in ~= "" then core.SetExportTag("RecMedium", rec_in) end
  end

  r.ShowMessageBox(
    string.format("UCS-Metadaten vorbereitet:\nMicModel: %s\nRecMedium: %s\n\nDiese Werte werden als DF95 ExportTags gespeichert\nund können von Export Wizard / UCS-Tools genutzt werden.",
      mic_in ~= "" and mic_in or "(leer)", rec_in ~= "" and rec_in or "(leer)"),
    "DF95 UCS Mic/Recorder (AutoMicTagger)", 0)
end

main()
