-- @description DF95_ReampSuite_Dashboard_Analyzer
-- @version 1.0
-- @author DF95
local r = reaper
if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui nicht installiert – bitte installieren.", "DF95 ReampSuite Analyzer", 0)
  return
end
local ctx = r.ImGui_CreateContext("DF95 ReampSuite Analyzer")
local FONT_SCALE = 1.0
local function get_tracks_to_monitor()
  local tracks = {}
  local sel_cnt = r.CountSelectedTracks(0)
  if sel_cnt > 0 then
    for i = 0, sel_cnt - 1 do
      tracks[#tracks+1] = r.GetSelectedTrack(0, i)
    end
  else
    tracks[#tracks+1] = r.GetMasterTrack(0)
  end
  return tracks
end
local function get_track_name(tr)
  if r.GetMasterTrack(0) == tr then return "MASTER" end
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if name == "" then
    local idx = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    name = string.format("Track %d", idx)
  end
  return name
end
local function build_ui()
  r.ImGui_SetNextWindowSize(ctx, 360, 260, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 ReampSuite Analyzer", true)
  if not visible then
    r.ImGui_End(ctx)
    if open then r.defer(build_ui) else r.ImGui_DestroyContext(ctx) end
    return
  end
  r.ImGui_SetWindowFontScale(ctx, FONT_SCALE)
  r.ImGui_Text(ctx, "Realtime Analyzer (Peak)")
  r.ImGui_Separator(ctx)
  r.ImGui_TextWrapped(ctx, "Selektierte Tracks werden überwacht. Ohne Auswahl: MASTER.")
  local tracks = get_tracks_to_monitor()
  r.ImGui_Spacing(ctx)
  if r.ImGui_BeginChild(ctx, "AnalyzerChild", -1, -40, true) then
    for _, tr in ipairs(tracks) do
      local name = get_track_name(tr)
      local pk_l = r.Track_GetPeakInfo(tr, 0) or 0.0
      local pk_r = r.Track_GetPeakInfo(tr, 1) or pk_l
      local pk   = math.max(pk_l, pk_r)
      if pk < 0 then pk = 0 end
      if pk > 1 then pk = 1 end
      local db = -120.0
      if pk > 0 then db = 20*math.log(pk, 10) end
      r.ImGui_Text(ctx, name)
      r.ImGui_SameLine(ctx)
      local avail = r.ImGui_GetContentRegionAvail(ctx)
      r.ImGui_ProgressBar(ctx, pk, avail, 0, string.format("%.1f dBFS", db))
    end
    r.ImGui_EndChild(ctx)
  end
  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "Tipp: ReampReturn-Tracks selektieren, um deren Pegel zu sehen.")
  r.ImGui_End(ctx)
  if open then r.defer(build_ui) else r.ImGui_DestroyContext(ctx) end
end
build_ui()
