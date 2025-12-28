-- DF95_IDM_DrumAutopilot_Light.lua
-- "Light" Autopilot:
--  * Ein Dialog für: Artist, Intensity (auto/soft/medium/extreme), Explode?, Rearrange?, Humanize?
--  * Schritte:
--    1) optional Explode auf Items der selektierten Tracks (Platzhalter)
--    2) DF95_Physical_Slicer.lua
--    3) Artist-Slicing-FXChain (FXChains/DF95/Slicing_Artists_Granular)
--    4) optional Rearrange (Align)
--    5) optional Humanize (Artist+Intensity -> Preset)
--    6) DF95_IDM_DrumSetup.lua (klassischer Dialog; kein AUTO-Mode, um Stabilität zu wahren)

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(s, "DF95 IDM Drum Autopilot (Light)", 0)
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function load_common()
  local ok, C = pcall(dofile, df95_root() .. "DF95_Common_RfxChainLoader.lua")
  if not ok or not C then
    msg("Konnte DF95_Common_RfxChainLoader.lua nicht laden:\n"..tostring(C))
    return nil
  end
  return C
end

local function find_artist_fxchain(artist)
  local res = r.GetResourcePath():gsub("\\","/")
  local base_dir = res.."/FXChains/DF95/Slicing_Artists_Granular"
  local ok = r.EnumerateFiles(base_dir, 0)
  if not ok then return nil end
  local target = "slicing_"..artist:lower()
  local i = 0
  local best
  while true do
    local fn = r.EnumerateFiles(base_dir, i)
    if not fn then break end
    local lower = fn:lower()
    if lower:find(target, 1, true) then
      best = base_dir.."/"..fn
      break
    end
    i = i + 1
  end
  return best
end

local function apply_fxchain_to_selected(path)
  if not path then return end
  local C = load_common()
  if not C then return end
  local txt = C.read_file(path)
  if not txt then
    msg("Konnte FXChain nicht lesen:\n"..tostring(path))
    return
  end
  local num = r.CountSelectedTracks(0)
  for i = 0, num-1 do
    local tr = r.GetSelectedTrack(0, i)
    C.write_chunk_fxchain(tr, txt, true)
  end
end

local function run_df95(rel)
  local ok, err = pcall(dofile, df95_root() .. rel)
  if not ok then
    msg("Fehler beim Ausführen von "..rel..":\n"..tostring(err))
  end
end

------------------------------------------------------------
-- Autopilot
------------------------------------------------------------

local function main()
  local num_tracks = r.CountSelectedTracks(0)
  if num_tracks == 0 then
    msg("Bitte zuerst mindestens einen Track mit Drum-/Loop-Material selektieren.")
    return
  end

  local ok, ret = r.GetUserInputs("DF95 IDM Drum Autopilot (Light)", 5,
    "Artist (z.B. autechre),Intensity (auto/soft/medium/extreme),Explode before slicing? (yes/no),Rearrange after? (yes/no),Apply Humanize? (yes/no)",
    "autechre,auto,yes,yes,yes")
  if not ok then return end

  local artist, intensity_mode, do_explode, do_rearr, do_hum =
    ret:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
  artist = (artist or ""):lower():gsub("%s+","")
  intensity_mode = (intensity_mode or "auto"):lower()
  do_explode = (do_explode or "yes"):lower()
  do_rearr = (do_rearr or "yes"):lower()
  do_hum = (do_hum or "yes"):lower()

  if artist == "" then
    msg("Artist darf nicht leer sein.")
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  --------------------------------------------------
  -- Artist-Intensity-Mapping
  --------------------------------------------------
  local slicing_intensity = "medium"
  do
    local ok_ai, AI = pcall(dofile, df95_root() .. "DF95_ArtistIntensity.lua")
    if ok_ai and AI then
      slicing_intensity = AI.slicing_intensity_for(artist, intensity_mode)
    else
      slicing_intensity = (intensity_mode == "soft" or intensity_mode == "extreme") and intensity_mode or "medium"
    end
  end

  -- ExtStates für andere DF95-Module (z.B. Humanize)
  r.SetProjExtState(0, "DF95_SLICING", "ARTIST", artist)
  r.SetProjExtState(0, "DF95_SLICING", "INTENSITY", slicing_intensity)

  --------------------------------------------------
  -- 1) optional Explode (Platzhalter)
  --------------------------------------------------
  if do_explode == "yes" or do_explode == "y" then
    -- Hier könntest du deine eigene "Explode items across tracks"-Action einsetzen
    -- Beispiel (nur wenn du sie gemappt hast):
    -- r.Main_OnCommand(40838, 0)
  end

  --------------------------------------------------
  -- 2) Physical Slicer
  --------------------------------------------------
  run_df95("DF95_Physical_Slicer.lua")

  --------------------------------------------------
  -- 3) Artist-Slicing-FXChain
  --------------------------------------------------
  local fx_path = find_artist_fxchain(artist)
  if fx_path then
    apply_fxchain_to_selected(fx_path)
  end

  --------------------------------------------------
  -- 4) optional Rearrange
  --------------------------------------------------
  if do_rearr == "yes" or do_rearr == "y" then
    -- hier könntest du alternativ ein Weighted/Pattern-Rearrange einhängen
    run_df95("DF95_Rearrange_Align.lua")
  end

  --------------------------------------------------
  -- 5) optional Humanize (Artist+Intensity -> Preset)
  --------------------------------------------------
  if do_hum == "yes" or do_hum == "y" then
    local preset_name = artist .. "_" .. slicing_intensity
    r.SetProjExtState(0, "DF95_HUMANIZE", "PRESET_NAME", preset_name)
    run_df95("DF95_Humanize_Preset_Apply.lua")
  end

  --------------------------------------------------
  -- 6) IDM DrumSetup klassisch (User wählt Intensity selbst)
  --------------------------------------------------
  -- kein AUTO-Mode Patch, um DF95_IDM_DrumSetup.lua unangetastet/stabil zu lassen
  do
    local sep = package.config:sub(1,1)
    local res = r.GetResourcePath()
    local script_path = (res .. sep .. "_selectors" .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_IDM_DrumSetup.lua"):gsub("\\","/")
    local ok_ds, err_ds = pcall(dofile, script_path)
    if not ok_ds then
      msg("Fehler beim Ausführen von DF95_IDM_DrumSetup.lua:\n"..tostring(err_ds).."\nPfad: "..script_path)
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 IDM Drum Autopilot (Light) - "..artist.." / "..slicing_intensity, -1)
  r.UpdateArrange()
end

main()
