
-- @description DF95_ReampSuite_MainGUI
-- @version 1.0
-- @author DF95
-- @about
--   ImGui-Hub für ReampSuite:
--   - zeigt aktives Reamp-Profil
--   - listet Reamp-Kandidaten (Track-Namen mit REAMP/DI/PEDAL)
--   - Buttons:
--       * Profil wählen (ReampSuite_Router)
--       * HW Routing (DF95_V71_ReampRouter)
--       * Latenz-Helper

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui nicht installiert – bitte nachrüsten.",
                   "DF95 ReampSuite GUI", 0)
  return
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil end
  return mod
end

local profiles = safe_require(df95_root() .. "ReampSuite/DF95_ReampSuite_Profiles.lua")
local ctx = r.ImGui_CreateContext("DF95 ReampSuite")

local function is_reamp_candidate(name)
  if not name or name == "" then return false end
  local u = name:upper()
  if u:match("REAMP") or u:match("RE%-AMP") or u:match(" DI ") or u:match("_DI") or u:match("PEDAL") then
    return true
  end
  return false
end

local tracks = {}

local function refresh_tracks()
  tracks = {}
  local sel = r.CountSelectedTracks(0)
  for i = 0, sel-1 do
    local tr = r.GetSelectedTrack(0, i)
    local _, name = r.GetTrackName(tr)
    if is_reamp_candidate(name) then
      tracks[#tracks+1] = {
        track = tr,
        name  = name or "(unbenannt)",
        idx   = r.CSurf_TrackToID(tr, false),
      }
    end
  end
end

local function call_script(rel_path)
  local path = df95_root() .. rel_path
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Script konnte nicht ausgeführt werden:\\n" .. tostring(err or "?") ..
                     "\\nPfad: " .. path, "DF95 ReampSuite", 0)
  end
end

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 ReampSuite", true, r.ImGui_WindowFlags_AlwaysAutoResize())
  if visible then
    r.ImGui_Text(ctx, "ReampSuite – Profil, Routing, Latenz")
    r.ImGui_Separator(ctx)

    if profiles then
      local key = profiles.get_active_key()
      local p = profiles.get_active_profile()
      r.ImGui_Text(ctx, "Aktives Profil: " .. (p.name or key))
      r.ImGui_Text(ctx, string.format("Interface: %s | Out: %d | In: %d",
        p.interface or "n/a", p.out_ch or 3, p.in_ch or 1))
    else
      r.ImGui_Text(ctx, "Profile-Modul nicht geladen.")
    end

    if r.ImGui_Button(ctx, "Profil wählen / anwenden") then
      call_script("ReampSuite/DF95_ReampSuite_Router.lua")
    end

    r.ImGui_Separator(ctx)

    local sel = r.CountSelectedTracks(0)
    r.ImGui_Text(ctx, "Selektierte Tracks: " .. tostring(sel))
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Reamp-Kandidaten aktualisieren") then
      refresh_tracks()
    end

    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "Reamp-Kandidaten (Name enthält z.B. REAMP/DI/PEDAL):")
    if #tracks == 0 then
      r.ImGui_Text(ctx, "Keine gefunden – Tracknamen prüfen & Refresh drücken.")
    else
      for _, t in ipairs(tracks) do
        r.ImGui_Text(ctx, string.format("Track %d: %s", t.idx, t.name))
      end
    end

    r.ImGui_Separator(ctx)
    if r.ImGui_Button(ctx, "HW Routing anlegen (V71 ReampRouter)") then
      call_script("DF95_V71_ReampRouter.lua")
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Latenz-Helper") then
      call_script("ReampSuite/DF95_ReampSuite_LatencyHelper.lua")
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
