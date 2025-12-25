
-- DF95_AutoMic_Inserter_GUI.lua
-- ImGui-Frontend für den Auto Mic Inserter (V68)

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui nicht installiert – verwende stattdessen das einfache AutoMic-Inserter Script (DF95_AutoMic_Inserter.lua).",
                   "DF95 Auto Mic Inserter GUI", 0)
  return
end

package.path = package.path .. ";../?.lua"
local ok, tagger = pcall(dofile, "DF95_Auto_MicTagger.lua")
if not ok or type(tagger) ~= "table" then
  r.ShowMessageBox("DF95_Auto_MicTagger.lua konnte nicht geladen werden.\nBitte prüfen, ob die Datei im gleichen Ordner liegt.",
                   "DF95 Auto Mic Inserter GUI", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Auto Mic Inserter')

local tracks = {}

local function refresh_tracks()
  tracks = {}
  local sel_count = r.CountSelectedTracks(0)
  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    local _, name = r.GetTrackName(tr)
    local rec = tagger.detect_recorder(name or "")
    local model, pattern, ch = tagger.detect_model(name or "")
    local chain = tagger.build_name(rec, model, pattern, ch)
    tracks[#tracks+1] = {
      track = tr,
      index = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER"),
      name = name,
      rec = rec,
      model = model,
      pattern = pattern,
      ch = ch,
      chain = chain,
    }
  end
end

local function insert_chain_for(track_info)
  if not track_info or not track_info.track then return end
  local chain = track_info.chain
  if not chain or chain == "" then return end
  local idx = r.TrackFX_AddByName(track_info.track, chain, false, -1)
  if idx < 0 then
    r.ShowMessageBox("FXChain '" .. chain .. "' konnte nicht geladen werden.\n" ..
                     "Stelle sicher, dass die Datei unter FXChains/ liegt.\n\n" ..
                     "Erzeugter Name:\n" .. chain,
                     "DF95 Auto Mic Inserter", 0)
  end
end

local function insert_all()
  for _, t in ipairs(tracks) do
    insert_chain_for(t)
  end
end

local function loop()
  local visible, open = r.ImGui_Begin(ctx, 'DF95 Auto Mic Inserter', true,
    r.ImGui_WindowFlags_AlwaysAutoResize())

  if visible then
    if #tracks == 0 then
      refresh_tracks()
    end

    r.ImGui_Text(ctx, "Auto Mic Inserter – basierend auf Track-Namen")
    r.ImGui_Separator(ctx)

    local sel_count = r.CountSelectedTracks(0)
    r.ImGui_Text(ctx, "Ausgewählte Tracks: " .. tostring(sel_count))
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Refresh") then
      refresh_tracks()
    end

    r.ImGui_Separator(ctx)

    if #tracks == 0 then
      r.ImGui_Text(ctx, "Keine ausgewählten Tracks.")
    else
      if r.ImGui_Button(ctx, "Auf alle Tracks Mic-Chain einfügen") then
        r.Undo_BeginBlock()
        insert_all()
        r.Undo_EndBlock("DF95 Auto Mic Inserter – All", -1)
      end

      r.ImGui_Separator(ctx)

      for _, t in ipairs(tracks) do
        r.ImGui_Text(ctx, string.format("Track %d: %s", t.index, t.name or "(unbenannt)"))
        r.ImGui_Text(ctx, string.format("  Recorder: %s | Mic: %s | Pattern: %s | Ch: %s",
          t.rec, t.model, t.pattern, t.ch))
        r.ImGui_Text(ctx, "  FXChain: " .. (t.chain or "?"))
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Insert##" .. tostring(t.index)) then
          r.Undo_BeginBlock()
          insert_chain_for(t)
          r.Undo_EndBlock("DF95 Auto Mic Inserter – Single", -1)
        end
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
