-- DF95_Autopilot_ArtistDynamicSlice.lua
-- Voller Artist-Flow:
--   1) Artist + Intensity + Slice-Length-Modus aus ExtStates (GUI) ODER Dialog
--   2) ExtStates für DF95_SLICING + DF95_DYN setzen
--   3) DF95_Dynamic_Slicer.lua ausführen (Transient/Gate + Länge)
--   4) optional Rearrange
--   5) optional Humanize
--   6) DF95_IDM_DrumSetup.lua (klassischer Dialog) ausführen
--
-- Ziel: Ein Klick → kompletter IDM-Drum-Slicing-Flow nach Artist.
-- ExtStates vom GUI:
--   DF95_SLICING / ARTIST
--   DF95_SLICING / INTENSITY
--   DF95_DYN     / LENGTH_MODE
--   DF95_AUTOPILOT / REARR ("yes"/"no")
--   DF95_AUTOPILOT / HUM   ("yes"/"no")

local r = reaper

local function msg(s)
  r.ShowMessageBox(s, "DF95 Artist Dynamic Slice Autopilot", 0)
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

------------------------------------------------------------
-- Artist-Key Normalisierung + Artist-Core/Profiles setzen
------------------------------------------------------------

local function df95_normalize_artist_key(name)
  if not name or name == "" then return "" end
  local s = name:lower()
  if s:find("µ%-ziq") or s:find("mu%-ziq") then
    return "mu_ziq"
  end
  if s:find("future sound of london") then
    return "fsold"
  end
  s = s:gsub("[^%w]+", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_", ""):gsub("_$", "")
  return s
end

local function df95_set_current_artist_core(artist_raw)
  local art = artist_raw or ""
  if art == "" then return end
  local key = df95_normalize_artist_key(art)
  reaper.SetProjExtState(0, "DF95", "CurrentArtist", art)
  reaper.SetProjExtState(0, "DF95", "CurrentArtistKey", key)
end

local function df95_ensure_profiles_for_current_artist()
  local root = df95_root()
  pcall(dofile, root .. "DF95_Slicing_Menu_V2.lua")
  pcall(dofile, root .. "DF95_Humanize_Menu_V2.lua")
  pcall(dofile, root .. "DF95_Rearrange_Menu_V2.lua")
  pcall(dofile, root .. "DF95_CreateLoop_Menu_V2.lua")
  pcall(dofile, root .. "DF95_Sampler_Menu_V2.lua")
end



------------------------------------------------------------
-- ArtistIntensity-Modul laden (falls vorhanden)
------------------------------------------------------------

local function get_slicing_intensity(artist, intensity_mode)
  local slicing_intensity = "medium"
  local ok_ai, AI = pcall(dofile, df95_root() .. "DF95_ArtistIntensity.lua")
  if ok_ai and AI and type(AI.slicing_intensity_for) == "function" then
    slicing_intensity = AI.slicing_intensity_for(artist, intensity_mode)
  else
    -- Fallback: intensity_mode direkt benutzen
    intensity_mode = (intensity_mode or "medium"):lower()
    if intensity_mode == "soft" or intensity_mode == "extreme" then
      slicing_intensity = intensity_mode
    else
      slicing_intensity = "medium"
    end
  end
  return slicing_intensity
end

------------------------------------------------------------
-- Config aus ExtStates (GUI) lesen
------------------------------------------------------------

local function get_config_from_extstate()
  local _, art = r.GetProjExtState(0, "DF95_SLICING", "ARTIST")
  if not art or art == "" then
    return nil
  end

  local _, inten = r.GetProjExtState(0, "DF95_SLICING", "INTENSITY")
  local _, length_mode = r.GetProjExtState(0, "DF95_DYN", "LENGTH_MODE")
  local _, rearr = r.GetProjExtState(0, "DF95_AUTOPILOT", "REARR")
  local _, hum = r.GetProjExtState(0, "DF95_AUTOPILOT", "HUM")

  local cfg = {
    artist = (art or ""):lower():gsub("%s+",""),
    intensity_mode = (inten or "auto"):lower(),
    length_mode = (length_mode or "medium"):lower(),
    do_rearr = (rearr or "yes"):lower(),
    do_humanize = (hum or "yes"):lower(),
  }
  return cfg
end

------------------------------------------------------------
-- Dynamic Slicer / Rearrange / Humanize / DrumSetup
------------------------------------------------------------

local function run_dynamic_slicer()
  local ok, err = pcall(dofile, df95_root() .. "DF95_Dynamic_Slicer.lua")
  if not ok then
    msg("Fehler beim Ausführen von DF95_Dynamic_Slicer.lua:\n"..tostring(err))
  end
end

local function run_rearrange()
  local ok, err = pcall(dofile, df95_root() .. "DF95_Rearrange_ArtistAware_Align.lua")
  if not ok then
    msg("Fehler beim Ausführen von DF95_Rearrange_ArtistAware_Align.lua:\n"..tostring(err))
  end
end

local function run_humanize()
  -- Humanize-Profil ist bereits über df95_ensure_profiles_for_current_artist()
  -- in DF95_HUMANIZE / PROFILE_JSON geschrieben worden.
  local ok, err = pcall(dofile, df95_root() .. "DF95_Humanize_Apply.lua")
  if not ok then
    msg("Fehler beim Ausführen von DF95_Humanize_Apply.lua:\n"..tostring(err))
  end
end

local function run_drumsetup()
  -- DrumSetup liegt im _selectors-Ordner
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local script_path = (res .. sep .. "_selectors" .. sep .. "Scripts" .. sep ..
    "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_IDM_DrumSetup.lua"):gsub("\\","/")
  local ok, err = pcall(dofile, script_path)
  if not ok then
    msg("Fehler beim Ausführen von DF95_IDM_DrumSetup.lua:\n"..tostring(err).."\nPfad: "..script_path)
  end

  -- Danach Artist-basierte KickEngine auf den Kick-Bus anwenden
  local ok2, err2 = pcall(dofile, df95_root() .. "DF95_ArtistDrum_KickEngine_Apply.lua")
  if not ok2 then
    msg("Fehler beim Ausführen von DF95_ArtistDrum_KickEngine_Apply.lua:\n"..tostring(err2))
  end

  -- Optional: Ghost Notes & Percussion-Dichte gemäß Artist-SamplerProfil
  local ok3, err3 = pcall(dofile, df95_root() .. "DF95_ArtistDrum_GhostPerc_Apply.lua")
  if not ok3 then
    msg("Fehler beim Ausführen von DF95_ArtistDrum_GhostPerc_Apply.lua:\n"..tostring(err3))
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local num_items = r.CountSelectedMediaItems(0)
  if num_items == 0 then
    msg("Bitte zuerst ein oder mehrere Audio-Items selektieren (z.B. Drumloop, Breakbeat, Field Recording).")
    return
  end

  -- 1) Versuche, Config aus ExtStates (GUI) zu lesen
  local cfg = get_config_from_extstate()
  local use_ext = (cfg ~= nil)

  if not use_ext then
    -- 2) Fallback: klassischer Dialog
    local ok, ret = r.GetUserInputs("DF95 Artist Dynamic Slice Autopilot", 5,
      "Artist (z.B. autechre),Intensity (auto/soft/medium/extreme),Slice Length (ultra/short/medium/long),Rearrange after? (yes/no),Apply Humanize? (yes/no)",
      "autechre,auto,medium,yes,yes")
    if not ok then return end

    local artist, intensity_mode, length_mode, do_rearr, do_hum =
      ret:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

    cfg = {
      artist = (artist or ""):lower():gsub("%s+",""),
      intensity_mode = (intensity_mode or "auto"):lower(),
      length_mode = (length_mode or "medium"):lower(),
      do_rearr = (do_rearr or "yes"):lower(),
      do_humanize = (do_hum or "yes"):lower(),
    }
  end

  if cfg.artist == "" then
    msg("Artist darf nicht leer sein.")
    return
  end

  -- Artist-Core setzen und Profile (Slicing/Humanize/Rearrange/Loop/Sampler) vorbereiten
  df95_set_current_artist_core(cfg.artist)
  df95_ensure_profiles_for_current_artist()

  -- Export-Tags / UCS: Artist als ExportTag setzen, Artist-Profile für Role/Source/FXFlavor laden
  local ok_core, Core = pcall(dofile, df95_root() .. "DF95_Export_Core.lua")
  if ok_core and type(Core) == "table" and Core.SetExportTag then
    if cfg.artist and cfg.artist ~= "" then
      Core.SetExportTag("Artist", cfg.artist)
    end

    -- Artist-basierte UCS-Profile nutzen (falls vorhanden)
    local sep = package.config:sub(1,1)
    local res = r.GetResourcePath()
    local ucs_artist_path = (res .. sep .. "Data" .. sep .. "DF95" .. sep .. "DF95_Export_UCSArtistProfiles_v1.json"):gsub("\\","/")
    local f = io.open(ucs_artist_path, "rb")
    if f and r.JSONDecode then
      local txt = f:read("*a"); f:close()
      local ok_json, obj = pcall(function() return r.JSONDecode(txt) end)
      if ok_json and type(obj) == "table" and type(obj.artists) == "table" then
        local prof = obj.artists[cfg.artist]
        if prof then
          if prof.role then      Core.SetExportTag("Role", prof.role) end
          if prof.source then    Core.SetExportTag("Source", prof.source) end
          if prof.fxflavor then  Core.SetExportTag("FXFlavor", prof.fxflavor) end
          if prof.ucs_catid then Core.SetExportTag("UCS_CatID_Default", prof.ucs_catid) end
        end
      end
    end
  end


  -- Slicing-Intensity ermitteln
  local slicing_intensity = get_slicing_intensity(cfg.artist, cfg.intensity_mode)

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  --------------------------------------------------
  -- ExtStates setzen (für Dynamic Slicer + Humanize)
  --------------------------------------------------
  r.SetProjExtState(0, "DF95_SLICING", "ARTIST", cfg.artist)
  r.SetProjExtState(0, "DF95_SLICING", "INTENSITY", slicing_intensity)
  r.SetProjExtState(0, "DF95_DYN", "LENGTH_MODE", cfg.length_mode)

  --------------------------------------------------
  -- 1) Dynamic Slice (Transient/Gate + Länge)
  --------------------------------------------------
  run_dynamic_slicer()

  --------------------------------------------------
  -- 2) optional Rearrange
  --------------------------------------------------
  if cfg.do_rearr == "yes" or cfg.do_rearr == "y" then
    run_rearrange()
  end

  --------------------------------------------------
  -- 3) optional Humanize
  --------------------------------------------------
  if cfg.do_humanize == "yes" or cfg.do_humanize == "y" then
    run_humanize()
  end

  --------------------------------------------------
  -- 4) DrumSetup (Bus-Routing + FXBus-Ketten)
  --------------------------------------------------
  run_drumsetup()

  -- Aufräumen: GUI-spezifische ExtStates leeren
  r.SetProjExtState(0, "DF95_AUTOPILOT", "REARR", "")
  r.SetProjExtState(0, "DF95_AUTOPILOT", "HUM", "")

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Artist Dynamic Slice Autopilot - "..cfg.artist.." / "..slicing_intensity.." / "..cfg.length_mode, -1)
  r.UpdateArrange()
end

main()