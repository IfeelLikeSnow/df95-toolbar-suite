-- DF95_Slicing_AutoArtist_Pipeline.lua
-- Explode -> Physical Slicer (Artist/Intensity) -> Slicing-FXChain (Artist)
-- + optional Rearrange + auto-Humanize (Artist+Intensity)

local r = reaper

------------------------------------------------------------
-- USER CONFIG
------------------------------------------------------------

local NATIVE_EXPLODE_CMD = 0     -- z.B. 40838 (Explode), falls genutzt
local CUSTOM_EXPLODE_CMDID = ""  -- z.B. "_RS1234...", wenn du eine Custom-Action hast

local FXCHAINS_SUBDIR = "FXChains/DF95/Slicing_Artists_Granular"

local ENABLE_REARRANGE_ALIGN = true
local ENABLE_REARRANGE_ARTIST = false   -- optional: zusätzlich Artist-based Rearrange

local ENABLE_HUMANIZE_AUTO = true

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s) r.ShowMessageBox(s,"DF95 Auto Slicing Pipeline",0) end

local function run_command_id(cmd)
  if not cmd or cmd == "" then return end
  local id = r.NamedCommandLookup(cmd)
  if id ~= 0 then
    r.Main_OnCommand(id, 0)
  end
end

local function run_native(cmd_id)
  if cmd_id and cmd_id > 0 then
    r.Main_OnCommand(cmd_id, 0)
  end
end

local function get_resource_path()
  return r.GetResourcePath():gsub("\\","/")
end

local function build_fxchain_path(artist)
  local root = get_resource_path()
  local sub  = FXCHAINS_SUBDIR:gsub("\\","/")
  local base = root.."/"..sub
  return base, base.."/Slicing_"..artist.."_"
end

local function find_fxchain_for_artist(artist)
  local base_dir, prefix = build_fxchain_path(artist)
  local ok, _ = reaper.EnumerateFiles(base_dir, 0)
  if not ok then return nil end
  local idx = 0
  local best
  while true do
    local fn = reaper.EnumerateFiles(base_dir, idx)
    if not fn then break end
    if fn:lower():find("slicing_"..artist:lower(), 1, true) then
      best = base_dir.."/"..fn
      break
    end
    idx = idx + 1
  end
  return best
end


local function df95_root()
  local sep = package.config:sub(1,1)
  local res = reaper.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end


local function df95_root()
  local sep = package.config:sub(1,1)
  local res = reaper.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function load_fxchain_on_selected_tracks(path)
  if not path then return end
  local ok, C = pcall(dofile, df95_root() .. "DF95_Common_RfxChainLoader.lua")
  if not ok or not C then
    reaper.ShowMessageBox("Konnte DF95_Common_RfxChainLoader.lua nicht laden:\n"..tostring(C),
      "DF95 Auto Slicing Pipeline", 0)
    return
  end
  local txt = C.read_file(path)
  if not txt then
    reaper.ShowMessageBox("Konnte FXChain nicht lesen:\n"..tostring(path),
      "DF95 Auto Slicing Pipeline", 0)
    return
  end
  local num = reaper.CountSelectedTracks(0)
  for i = 0, num-1 do
    local tr = reaper.GetSelectedTrack(0, i)
    C.write_chunk_fxchain(tr, txt, true)
  end
end

  local ok, C = pcall(dofile, df95_root() .. "DF95_Common_RfxChainLoader.lua")
  if not ok or not C then
    reaper.ShowMessageBox("Konnte DF95_Common_RfxChainLoader.lua nicht laden:\n"..tostring(C),
      "DF95 Auto Slicing Pipeline", 0)
    return
  end
  local txt = C.read_file(path)
  if not txt then
    reaper.ShowMessageBox("Konnte FXChain nicht lesen:\n"..tostring(path),
      "DF95 Auto Slicing Pipeline", 0)
    return
  end
  local num = reaper.CountSelectedTracks(0)
  for i = 0, num-1 do
    local tr = reaper.GetSelectedTrack(0, i)
    C.write_chunk_fxchain(tr, txt, true)
  end
end

  local CMD_APPLY_FXCHAIN = 40492 -- FX: Apply FX chain to selected tracks
  run_native(CMD_APPLY_FXCHAIN)
end

local function run_df95_script(rel)
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  local path = base .. rel
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Konnte DF95-Script nicht ausführen:\n"..path.."\n\n"..tostring(err),
      "DF95 Auto Slicing Pipeline", 0)
  end
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local num_tracks = r.CountSelectedTracks(0)
  if num_tracks == 0 then
    msg("Bitte zuerst mindestens einen Track mit Items selektieren.")
    return
  end

  local ok, ret = r.GetUserInputs("DF95 Auto Slicing Pipeline", 3,
    "Artist (z.B. autechre),Intensity (auto/soft/medium/extreme),Explode? (yes/no)",
    "autechre,auto,yes")
  if not ok then return end

  local artist, intensity, do_explode = ret:match("([^,]+),([^,]+),([^,]+)")
  artist   = (artist or ""):lower():gsub("%s+","")
  intensity = (intensity or "auto"):lower()
  do_explode = (do_explode or "yes"):lower()

  -- Artist-Intensity-Mapping (auto -> soft/medium/extreme)
  do
    local ok_ai, AI = pcall(dofile, df95_root() .. "DF95_ArtistIntensity.lua")
    if ok_ai and AI then
      intensity = AI.slicing_intensity_for(artist, intensity)
    end
  end
  if intensity ~= "soft" and intensity ~= "medium" and intensity ~= "extreme" then
    intensity = "medium"
  end

  if artist == "" then
    msg("Artist darf nicht leer sein.")
    return
  end

  -- ExtStates für andere DF95-Module
  r.SetProjExtState(0, "DF95_SLICING", "ARTIST", artist)
  r.SetProjExtState(0, "DF95_SLICING", "INTENSITY", intensity)

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  --------------------------------------------------
  -- 1) Explode
  --------------------------------------------------
  if do_explode == "yes" or do_explode == "y" then
    if CUSTOM_EXPLODE_CMDID ~= "" then
      run_command_id(CUSTOM_EXPLODE_CMDID)
    elseif NATIVE_EXPLODE_CMD > 0 then
      run_native(NATIVE_EXPLODE_CMD)
    end
  end

  --------------------------------------------------
  -- 2) DF95_Physical_Slicer im Artist-Modus
  --------------------------------------------------
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  local slicer_path = base .. "DF95_Physical_Slicer.lua"

  local ok2, err2 = pcall(dofile, slicer_path)
  if not ok2 then
    r.ShowMessageBox("Konnte DF95_Physical_Slicer.lua nicht ausführen:\n"..tostring(err2),
      "DF95 Auto Slicing Pipeline", 0)
  end

  --------------------------------------------------
  -- 3) Artist-Slicing-FXChain anwenden
  --------------------------------------------------
  local fx_path = find_fxchain_for_artist(artist)
  if fx_path then
    load_fxchain_on_selected_tracks(fx_path)
  end

  --------------------------------------------------
  -- 3b) Rearrange Align / Artist (optional)
  --------------------------------------------------
  if ENABLE_REARRANGE_ALIGN then
    run_df95_script("DF95_Rearrange_Align.lua")
  end
  if ENABLE_REARRANGE_ARTIST then
    run_df95_script("DF95_Rearrange_Menu.lua")
  end

  --------------------------------------------------
  -- 4) Auto-Humanize (Artist+Intensity -> Preset)
  --------------------------------------------------
  if ENABLE_HUMANIZE_AUTO then
    local preset_name = artist .. "_" .. intensity
    r.SetProjExtState(0, "DF95_HUMANIZE", "PRESET_NAME", preset_name)
    run_df95_script("DF95_Humanize_Preset_Apply.lua")
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Auto Slicing Pipeline ("..artist.." / "..intensity..")", -1)
  r.UpdateArrange()
end

main()
