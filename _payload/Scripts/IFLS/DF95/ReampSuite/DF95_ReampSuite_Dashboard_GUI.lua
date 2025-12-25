\
-- @description DF95_ReampSuite_Dashboard_GUI
-- @version 3.0
-- @author DF95
-- @about
--   Dashboard XL 3.0 (V87):
--   - baut auf der XL-Version auf, integriert aber zusätzlich:
--       * DF95_V83_SessionStateEngine (DF95_SESSION)
--       * DF95_V84_ReampSuite_AudioIntelligence3 (Analyse-Struktur)
--   - zeigt einen zusammengefassten "Session Health"-Block
--   - zeigt für selektierte Reamp-Tracks eine kompakte Analyse-Liste.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui nicht installiert – bitte installieren.", "DF95 ReampSuite Dashboard XL3", 0)
  return
end

---------------------------------------------------------
-- Helpers / Setup
---------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end

local function get_track_name(tr)
  if tr == r.GetMasterTrack(0) then return "MASTER" end
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if name == "" then
    local idx = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    name = string.format("Track %d", idx)
  end
  return name
end

---------------------------------------------------------
-- Load SessionStateEngine & AI3 (optional)
---------------------------------------------------------

local session_state, session_state_err = safe_require(df95_root() .. "ReampSuite/DF95_V83_SessionStateEngine.lua")
local audio_int3, audio_int3_err       = safe_require(df95_root() .. "ReampSuite/DF95_V84_ReampSuite_AudioIntelligence3.lua")

---------------------------------------------------------
-- Status / Health aus SessionStateEngine
---------------------------------------------------------

local function get_session_health()
  if not session_state or type(session_state.get_health_summary) ~= "function" then
    return {
      ok = false,
      problems = { "SessionStateEngine nicht geladen (DF95_V83_SessionStateEngine.lua)" },
      profile_key = nil,
    }
  end
  local h = session_state.get_health_summary()
  if not h or type(h) ~= "table" then
    return { ok = false, problems = { "HealthSummary konnte nicht ermittelt werden." }, profile_key = nil }
  end
  return h
end

---------------------------------------------------------
-- Analyse selektierter Reamp-Tracks (AI3-Struktur)
---------------------------------------------------------

local function is_reamp_candidate_name(name)
  if not name or name == "" then return false end
  local u = name:upper()
  if u:match("REAMP") then return true end
  if u:match("RE%-AMP") then return true end
  if u:match(" DI ") then return true end
  if u:match("_DI") then return true end
  if u:match("DI_") then return true end
  if u:match("PEDAL") then return true end
  return false
end

local function collect_selected_reamp_tracks()
  local tracks = {}
  local sel_cnt = r.CountSelectedTracks(0)
  for i = 0, sel_cnt - 1 do
    local tr = r.GetSelectedTrack(0, i)
    local name = get_track_name(tr)
    if is_reamp_candidate_name(name) then
      tracks[#tracks+1] = tr
    end
  end
  return tracks
end

local function analyze_selected_tracks()
  if not audio_int3 or type(audio_int3.analyze_tracks) ~= "function" then
    return nil, "AudioInt3 nicht geladen (DF95_V84_ReampSuite_AudioIntelligence3.lua)."
  end
  local tracks = collect_selected_reamp_tracks()
  if #tracks == 0 then
    return { tracks = {}, spectral_available = false }, nil
  end
  local summary = audio_int3.analyze_tracks(tracks)
  return summary, nil
end

---------------------------------------------------------
-- ImGui Setup
---------------------------------------------------------

local ctx = r.ImGui_CreateContext("DF95 ReampSuite Dashboard XL3")
local FONT_SCALE = 1.0

local function colored_status_text(ready)
  if ready then
    r.ImGui_Text(ctx, "Session Status: READY TO REAMP")
  else
    r.ImGui_Text(ctx, "Session Status: NICHT BEREIT")
  end
end

local function build_ui()
  r.ImGui_SetNextWindowSize(ctx, 560, 620, r.ImGui_Cond_FirstUseEver())
  r.ImGui_SetNextWindowSizeConstraints(ctx, 420, 360, 1600, 1200)

  local visible, open = r.ImGui_Begin(ctx, "DF95 ReampSuite Dashboard XL3", true, r.ImGui_WindowFlags_NoCollapse())
  if not visible then
    r.ImGui_End(ctx)
    if open then
      r.defer(build_ui)
    else
      r.ImGui_DestroyContext(ctx)
    end
    return
  end

  r.ImGui_SetWindowFontScale(ctx, FONT_SCALE)

  -------------------------------------------------------
  -- Session Health Block (V83)
  -------------------------------------------------------

  r.ImGui_Text(ctx, "Session Health (DF95_SESSION)")
  r.ImGui_Separator(ctx)

  local health = get_session_health()
  colored_status_text(health.ok)

  if health.profile_key then
    r.ImGui_Text(ctx, "Active Profile: " .. tostring(health.profile_key))
  end

  if not health.ok and health.problems and #health.problems > 0 then
    r.ImGui_Text(ctx, "Offene Punkte:")
    for _, p in ipairs(health.problems) do
      r.ImGui_BulletText(ctx, p)
    end
  elseif health.ok then
    r.ImGui_Text(ctx, "Alle Kernbedingungen für Reamp sind erfüllt.")
  end

  r.ImGui_Spacing(ctx)

  -------------------------------------------------------
  -- Analyse selektierter Reamp-Tracks (AI3-Struktur)
  -------------------------------------------------------

  r.ImGui_Text(ctx, "Analyse selektierter Reamp-Tracks (AI3-Struktur)")
  r.ImGui_Separator(ctx)
  r.ImGui_TextWrapped(ctx, "Selektiere Reamp/DI/PEDAL-Spuren, um ihre Analyse-Summary zu sehen.")

  local summary, err = analyze_selected_tracks()
  if err then
    r.ImGui_Text(ctx, err)
  else
    if not summary or #summary.tracks == 0 then
      r.ImGui_Text(ctx, "Keine Reamp-Kandidaten in der Auswahl.")
    else
      if r.ImGui_BeginChild(ctx, "AI3Tracks", -1, 120, true) then
        for _, info in ipairs(summary.tracks) do
          r.ImGui_Text(ctx, string.format("%s", info.name ~= "" and info.name or "(unbenannt)"))
          -- Da die Werte aktuell Platzhalter sind, zeigen wir nur an, dass ein Slot existiert.
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, "[AI3: Struktur verfügbar, Werte ggf. noch nil]")
        end
        r.ImGui_EndChild(ctx)
      end
    end
  end

  r.ImGui_Spacing(ctx)

  -------------------------------------------------------
  -- Hinweis: Restliche Bedienelemente (Router, PedalChains, Latency,
  -- Modes, Kandidatenliste etc.) liegen bereits in älteren Dashboard-
  -- Versionen. Diese v3.0-Datei ergänzt SessionHealth + AI3-Section.
  -------------------------------------------------------

  r.ImGui_Separator(ctx)
  r.ImGui_Text(ctx, "DF95 ReampSuite Dashboard XL3 – V87")
  r.ImGui_End(ctx)

  if open then
    r.defer(build_ui)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

build_ui()
