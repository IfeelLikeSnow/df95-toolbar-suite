-- @description DF95_Sampler_SitalaKitBuilder_v1
-- @version 1.0
-- @author DF95
-- @about
--   Richtet eine Sitala 2.0 Drum-Sampler-Instanz für die DF95-IDM-Beatwelt ein.
--   Features:
--     - Erzeugt (oder findet) einen Track "DF95_SITALA_KIT"
--     - Fügt Sitala-Plugin ein (Name konfigurierbar, Standard "Sitala")
--     - Schaltet optional auf Multi-Out-Routing per Reaper-Action um
--     - Routet DF95_IDM_* MIDI-Tracks zur Sitala-Instanz
--
--   Hinweis:
--     - Das Script lädt keine Samples direkt in Sitala (kein offizielles API).
--       Du kannst aber:
--         * Samples aus deiner SampleDB / Media Explorer in die Pads ziehen
--         * Das Routing / Multi-Out-Setup bleibt dabei bestehen.

local r = reaper

local CFG = {
  track_name      = "DF95_SITALA_KIT",
  plugin_search   = "Sitala",
  use_multi_out   = true,
}

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sitala Kit Builder", 0)
end

local function ensure_track(name)
  local proj = 0
  local track_count = r.CountTracks(proj)
  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, tr_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if tr_name == name then
      return tr
    end
  end
  r.InsertTrackAtIndex(track_count, true)
  local tr = r.GetTrack(proj, track_count)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function find_or_insert_sitala_fx(track, search)
  search = search or "Sitala"
  local fx_count = r.TrackFX_GetCount(track)
  for i = 0, fx_count-1 do
    local rv, fx_name = r.TrackFX_GetFXName(track, i, "")
    if rv then
      local lname = fx_name:lower()
      if lname:match(search:lower()) then
        return i
      end
    end
  end

  local fx_index = r.TrackFX_AddByName(track, search, false, 1)
  if fx_index < 0 then
    msg("Konnte Sitala-Plugin nicht finden.\nBitte stelle sicher, dass es installiert ist und der Name '" .. search .. "' passt.")
    return -1
  end
  return fx_index
end

local function build_multi_out_routing(track, fx_index)
  if not CFG.use_multi_out then return end
  local proj = 0
  r.Main_OnCommand(40297, 0)
  r.SetOnlyTrackSelected(track)
  r.TrackFX_SetOpen(track, fx_index, true)
  local CMD_BUILD_MULTI = 40359
  r.Main_OnCommand(CMD_BUILD_MULTI, 0)
end

local function route_idm_tracks_to_sitala(sitala_tr)
  local proj = 0
  local track_count = r.CountTracks(proj)

  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    if tr ~= sitala_tr then
      local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      if name:match("^DF95_IDM_") then
        local send_count = r.GetTrackNumSends(tr, 0)
        local has_send = false
        for s = 0, send_count-1 do
          local dest = r.BR_GetMediaTrackSendInfo_Track and r.BR_GetMediaTrackSendInfo_Track(tr, 0, s, 1) or nil
          if dest == sitala_tr then
            has_send = true
            break
          end
        end

        if not has_send then
          local send_idx = r.CreateTrackSend(tr, sitala_tr)
          r.SetTrackSendInfo_Value(tr, 0, send_idx, "I_SRCCHAN", -1)
          r.SetTrackSendInfo_Value(tr, 0, send_idx, "I_DSTCHAN", 0)
          r.SetTrackSendInfo_Value(tr, 0, send_idx, "I_MIDIFLAGS", 0)
        end
      end
    end
  end
end

local function main()
  local ok, res = r.GetUserInputs("DF95 Sitala Kit Builder", 2,
                                  "Sitala Plugin-Name (z.B. 'Sitala'),Multi-Out Routing aktivieren? (y/n),extrawidth=220",
                                  CFG.plugin_search .. ",y")
  if not ok then return end
  local search, multi = res:match("([^,]*),([^,]*)")
  if search and search ~= "" then
    CFG.plugin_search = search
  end
  CFG.use_multi_out = (multi or ""):lower():match("^y") and true or false

  r.Undo_BeginBlock()

  local sitala_tr = ensure_track(CFG.track_name)
  local fx_index = find_or_insert_sitala_fx(sitala_tr, CFG.plugin_search)
  if fx_index >= 0 then
    build_multi_out_routing(sitala_tr, fx_index)
    route_idm_tracks_to_sitala(sitala_tr)
  end

  r.Undo_EndBlock("DF95 Sitala Kit Builder", -1)
end

main()
