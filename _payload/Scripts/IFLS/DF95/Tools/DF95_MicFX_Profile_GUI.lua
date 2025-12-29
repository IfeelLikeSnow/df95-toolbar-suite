-- DF95_MicFX_Profile_GUI.lua
-- GUI für Mic-Profile (benötigt ReaImGui)
-- Funktionen:
--   - Zeigt alle selektierten Tracks
--   - Erkennt Mic-Key aus Tracknamen
--   - Zeigt für jedes Mic die verfügbaren Profile (default/dialog/shout/ambience/...)
--   - Anwenden-Button legt JS Gain + ReaEQ + ReaComp an und stellt HPF/EQ/Comp gemäß Profil ein

local r = reaper

-- ReaImGui prüfen
if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui ist nicht installiert.\nBitte ReaImGui Extension installieren, um diese GUI zu nutzen.", "DF95 MicFX GUI", 0)
  return
end

-- Mic-Modul laden
local function load_mic_module()
  local res = r.GetResourcePath()
  local path = res .. "/Scripts/IFLS/DF95/Tools/DF95_MicProfiles.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("DF95_MicProfiles.lua konnte nicht geladen werden:\n" .. tostring(mod), "DF95 MicFX GUI", 0)
    return nil
  end
  return mod
end

local Mic = load_mic_module()
if not Mic then return end

------------------------------------------------------------
-- State
------------------------------------------------------------

local ctx = r.ImGui_CreateContext('DF95 MicFX Profile GUI', r.ImGui_ConfigFlags_DockingEnable())

-- Speichert pro Track-GUID die gewählte Profilauswahl
local track_profile_state = {}

local function guid_str(track)
  local guid = r.GetTrackGUID(track)
  return guid
end

local function get_selected_tracks()
  local proj = 0
  local t = {}
  local cnt = r.CountSelectedTracks(proj)
  for i = 0, cnt - 1 do
    local tr = r.GetSelectedTrack(proj, i)
    t[#t+1] = tr
  end
  return t
end

------------------------------------------------------------
-- Profil-Auswahl und Anwendung
------------------------------------------------------------

local function ensure_state_for_track(tr, mic_key)
  local guid = guid_str(tr)
  track_profile_state[guid] = track_profile_state[guid] or {}
  local st = track_profile_state[guid]
  st.mic_key = mic_key
  if not st.profile_name then
    -- default wählen
    st.profile_name = "default"
  end
  return st
end

local function apply_profiles_to_tracks()
  local tracks = get_selected_tracks()
  if #tracks == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local applied = 0

  for _, tr in ipairs(tracks) do
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    local mic_key = Mic.get_mic_key_from_trackname(name)
    if mic_key then
      local guid = guid_str(tr)
      local st = track_profile_state[guid]
      local prof_name = st and st.profile_name or "default"
      Mic.apply_profile(tr, mic_key, prof_name)

      local tag = "[Mic:" .. mic_key .. "/" .. prof_name .. "]"
      local new_name = name or ""
      if not new_name:find("%[Mic:") then
        new_name = new_name .. " " .. tag
      else
        new_name = new_name:gsub("%[Mic:[^%]]+%]", tag)
      end
      r.GetSetMediaTrackInfo_String(tr, "P_NAME", new_name, true)
      applied = applied + 1
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 MicFX Profile GUI - Apply (" .. tostring(applied) .. " Tracks)", -1)
end

------------------------------------------------------------
-- GUI-Loop
------------------------------------------------------------

local function loop()
  r.ImGui_SetNextWindowSize(ctx, 600, 400, r.ImGui_Cond_FirstUseEver())

  local visible, open = r.ImGui_Begin(ctx, "DF95 MicFX Profile GUI", true)
  if visible then
    r.ImGui_Text(ctx, "Selektierte Tracks (Zoom F6 Mic-Setup):")
    r.ImGui_Separator(ctx)

    local tracks = get_selected_tracks()
    if #tracks == 0 then
      r.ImGui_Text(ctx, "Keine Tracks selektiert.")
      r.ImGui_Text(ctx, "Bitte Tracks mit Namen wie 'XM8500', 'MD400', 'NTG4+', 'C2', 'Geofon', 'Cortado' selektieren.")
    else
      for _, tr in ipairs(tracks) do
        local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        local mic_key = Mic.get_mic_key_from_trackname(name)
        if not mic_key then
          r.ImGui_Text(ctx, name .. "  ->  (kein Mic-Profil gefunden)")
        else
          local st = ensure_state_for_track(tr, mic_key)
          local profile_names = Mic.get_profile_names(mic_key)

          -- Combo Label
          local label = name .. "  [" .. mic_key .. "]"
          r.ImGui_Text(ctx, label)

          -- Baue Anzeige-Strings
          local items = {}
          local current_index = 0
          for i, pname in ipairs(profile_names) do
            local plabel = Mic.get_profile_label(mic_key, pname)
            items[i] = pname .. "##" .. pname
            if pname == st.profile_name then
              current_index = i - 1 -- ImGui verwendet 0-based
            end
          end

          if #profile_names > 0 then
            r.ImGui_SameLine(ctx)
            r.ImGui_Text(ctx, " -> Profil: ")
            r.ImGui_SameLine(ctx)

            local combo_label = Mic.get_profile_label(mic_key, st.profile_name or "default")
            local changed, new_index = r.ImGui_Combo(ctx, "##" .. label, current_index, table.concat(items, "\0"))
            if changed then
              local chosen = profile_names[new_index + 1]
              st.profile_name = chosen or "default"
            end
          end
        end
      end

      r.ImGui_Separator(ctx)
      if r.ImGui_Button(ctx, "Profile auf selektierte Tracks anwenden") then
        apply_profiles_to_tracks()
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

loop()
