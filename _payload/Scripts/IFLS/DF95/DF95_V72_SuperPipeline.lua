
-- @description DF95 V72 SuperPipeline – AutoMic + ExportTags + Reamp Router
-- @version 1.0
-- @author DF95
--
-- High-level orchestrator:
--  - Für Fieldrec/Dialog/FX-Tracks: ruft die bestehende DF95 Auto SuperPipeline auf (MicFX + ExportTags)
--  - Für "Reamp-Kandidaten": ruft den V71-ReampRouter auf
--
-- Heuristik:
--  - Trackname enthält "REAMP", "DI", "RE-AMP", "PEDAL" → Reamp-Kandidat
--  - Sonst: normaler AutoMic/Export-Pfad
--
-- Voraussetzungen:
--  - DF95_Auto_SuperPipeline.lua (V69)
--  - DF95_V71_ReampRouter.lua (dieses Repo)
--
-- Hinweis:
--  - Diese Implementierung ist bewusst konservativ. Sie stellt die Calls bereit, ohne
--    harte Annahmen über dein Audio-Interface erzwingen zu wollen.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local root = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep
  return (root:gsub("\\","/"))
end

local function safe_load(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end

local function is_reamp_candidate(name)
  if not name or name == "" then return false end
  local u = name:upper()
  if u:match("REAMP") or u:match("RE%-AMP") or u:match(" DI ") or u:match("_DI") or u:match("PEDAL") then
    return true
  end
  return false
end

local function collect_tracks()
  local fieldrec = {}
  local reamp = {}
  local sel_count = r.CountSelectedTracks(0)
  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    local _, name = r.GetTrackName(tr)
    if is_reamp_candidate(name) then
      reamp[#reamp+1] = tr
    else
      fieldrec[#fieldrec+1] = tr
    end
  end
  return fieldrec, reamp
end

local function run_fieldrec_pipeline(tracks)
  if #tracks == 0 then return end
  local core_path = df95_root() .. "DF95_Auto_SuperPipeline.lua"
  local ok, err = pcall(dofile, core_path)
  if not ok then
    r.ShowMessageBox("DF95_Auto_SuperPipeline.lua konnte nicht geladen werden:\n" ..
                     tostring(err) .. "\n\nBitte sicherstellen, dass V69 installiert ist.",
                     "DF95 V72 SuperPipeline", 0)
  end
end

local function run_reamp_router(reamp_tracks)
  if #reamp_tracks == 0 then return end
  -- Wir legen die Track-Indices in eine ExtState, damit der ReampRouter sie lesen kann.
  local idx_list = {}
  for _, tr in ipairs(reamp_tracks) do
    local idx = r.CSurf_TrackToID(tr, false)
    idx_list[#idx_list+1] = tostring(idx)
  end
  local joined = table.concat(idx_list, ",")
  r.SetExtState("DF95_REAMP", "TRACK_IDS", joined, false)

  local router_path = df95_root() .. "DF95_V71_ReampRouter.lua"
  local ok, err = pcall(dofile, router_path)
  if not ok then
    r.ShowMessageBox("DF95_V71_ReampRouter.lua konnte nicht geladen werden:\n" ..
                     tostring(err),
                     "DF95 V72 SuperPipeline", 0)
  end
end

local function main()
  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("Keine selektierten Tracks.\nBitte ein oder mehrere Tracks auswählen.",
                     "DF95 V72 SuperPipeline", 0)
    return
  end

  local fieldrec, reamp = collect_tracks()

  r.Undo_BeginBlock()

  if #fieldrec > 0 then
    run_fieldrec_pipeline(fieldrec)
  end

  if #reamp > 0 then
    run_reamp_router(reamp)
  end

  r.Undo_EndBlock("DF95 V72 SuperPipeline – Fieldrec + Reamp Fusion", -1)
end

main()
