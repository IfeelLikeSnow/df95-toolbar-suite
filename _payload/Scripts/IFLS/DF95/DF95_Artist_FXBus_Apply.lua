-- @description Artist FXBus Apply (symbolic chains, external plugins)
-- @version 1.1
-- @author DF95
-- @changelog
--   + Apply FXBus "chains" per ArtistProfile to selected tracks
--   + Uses Data/DF95/DF95_Artist_FXBusProfiles_v1.json
--   + Symbolic FXBus names mapped to concrete plugin stacks (no .rfxchain required)
--
-- Requires:
--   - DF95_ArtistProfile_Loader.lua
--   - DF95_ReadJSON.lua
--   - REAPER 6.82+ (JSONDecode)
--
-- Behavior:
--   - Reads current ArtistProfile (profile.key)
--   - Loads DF95_Artist_FXBusProfiles_v1.json
--   - Chooses fxbus_primary OR fxbus_alt (via ExtState DF95_FXBUS / VARIANT)
--   - For known FXBus names (DF95_FXBus_*), instantiates plugin stacks via TrackFX_AddByName
--   - Unknown FXBus names are ignored with a warning

local r = reaper

local function log(msg)
  r.ShowConsoleMsg(tostring(msg) .. "\\n")
end

-- Detect DF95 script root
local function df95_root()
  if _G.DF95_ROOT and type(_G.DF95_ROOT) == "string" then
    return _G.DF95_ROOT
  end
  local info = debug.getinfo(1, "S")
  local src  = info and info.source or ""
  src = src:match("^@(.+)$") or src
  local dir = src:match("^(.*[\\/])") or ""
  return dir
end

----------------------------------------------------------------
-- Artist profile loader
----------------------------------------------------------------
local function load_artist_profile()
  if _G.DF95_LoadArtistProfiles and type(_G.DF95_LoadArtistProfiles) == "function" then
    local ok, prof = pcall(_G.DF95_LoadArtistProfiles)
    if ok and prof then return prof end
  end

  local ok, mod = pcall(dofile, df95_root() .. "DF95_ArtistProfile_Loader.lua")
  if ok and mod then
    if type(mod) == "table" and type(mod.load) == "function" then
      local ok2, prof = pcall(mod.load)
      if ok2 and prof then return prof end
    elseif type(mod) == "function" then
      local ok2, prof = pcall(mod)
      if ok2 and prof then return prof end
    end
  end

  return nil
end

----------------------------------------------------------------
-- Load FXBus profile JSON
----------------------------------------------------------------
local function load_fxbus_profiles()
  if not r.JSONDecode then
    r.ShowMessageBox("This script requires REAPER with JSONDecode (v6.82+).", "DF95 Artist FXBus Apply", 0)
    return nil
  end

  local res_path = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local json_path = res_path .. sep .. "Data" .. sep .. "DF95" .. sep .. "DF95_Artist_FXBusProfiles_v1.json"

  local f = io.open(json_path, "rb")
  if not f then
    r.ShowMessageBox("Could not open:\\n" .. json_path, "DF95 Artist FXBus Apply", 0)
    return nil
  end
  local contents = f:read("*a")
  f:close()

  local ok, obj = pcall(r.JSONDecode, contents)
  if not ok or not obj then
    r.ShowMessageBox("JSONDecode failed for:\\n" .. json_path, "DF95 Artist FXBus Apply", 0)
    return nil
  end

  return obj
end

----------------------------------------------------------------
-- Determine which FXBus name to use for current artist
----------------------------------------------------------------
local function resolve_fxbus_for_artist(profile, fxbus_profiles)
  if not profile then return nil, "No artist profile loaded" end

  local artist_key = profile.key or "unknown"
  local defaults = fxbus_profiles.defaults or {}
  local artists  = fxbus_profiles.artists or {}

  local entry = artists[artist_key] or defaults
  if not entry then
    return nil, "No FXBus entry for artist '" .. tostring(artist_key) .. "' and no defaults"
  end

  -- Variant selection via ExtState: DF95_FXBUS / VARIANT = "primary" | "alt"
  local _, variant = r.GetProjExtState(0, "DF95_FXBUS", "VARIANT")
  if variant ~= "alt" then
    variant = "primary"
  end

  local fx_name
  if variant == "alt" then
    fx_name = entry.fxbus_alt or entry.fxbus_primary or defaults.fxbus_alt or defaults.fxbus_primary
  else
    fx_name = entry.fxbus_primary or entry.fxbus_alt or defaults.fxbus_primary or defaults.fxbus_alt
  end

  if not fx_name or fx_name == "" then
    return nil, "FXBus name is empty for artist '" .. tostring(artist_key) .. "'"
  end

  return fx_name, artist_key, variant
end

----------------------------------------------------------------
-- Symbolic FXBus builders (use TrackFX_AddByName)
----------------------------------------------------------------

local function safe_add_fx(track, fxname)
  local idx = r.TrackFX_AddByName(track, fxname, false, -1)
  if idx < 0 then
    log(string.format("[DF95 FXBus] Plugin not found: %s", fxname))
    return nil
  end
  return idx
end

-- GlitchSeq: ReaEQ -> Danaides -> BreadSlicer -> kHs Transient Shaper -> kHs Limiter
local function build_glitchseq_danaidesbread(track)
  safe_add_fx(track, "VST: ReaEQ (Cockos)")
  safe_add_fx(track, "VST: Danaides (x86) (Inear_Display)")
  safe_add_fx(track, "VST3: BreadSlicer (Audioblast)")
  safe_add_fx(track, "VST3: kHs Transient Shaper (Kilohearts)")
  safe_add_fx(track, "VST3: kHs Limiter (Kilohearts)")
end

-- Granular Clouds: Emergence -> Lagrange -> kHs Reverb -> kHs Limiter
local function build_granularclouds_emergencelag(track)
  safe_add_fx(track, "VST3: Emergence (Daniel Gergely)")
  safe_add_fx(track, "VST3: Lagrange (UrsaDSP)")
  safe_add_fx(track, "VST3: kHs Reverb (Kilohearts)")
  safe_add_fx(track, "VST3: kHs Limiter (Kilohearts)")
end

-- Buffer Chaos: Fracture -> Hysteresis -> kHs Limiter
local function build_bufferchaos_fracturehysteresis(track)
  safe_add_fx(track, "VST3: Fracture (Glitchmachines)")
  safe_add_fx(track, "VST3: Hysteresis (Glitchmachines)")
  safe_add_fx(track, "VST3: kHs Limiter (Kilohearts)")
end

-- KHs Modular Weave: kHs Chorus -> kHs Shaper -> kHs Reverb -> kHs Limiter
local function build_khs_modularweave(track)
  safe_add_fx(track, "VST3: kHs Chorus (Kilohearts)")
  safe_add_fx(track, "VST3: kHs Shaper (Kilohearts)")
  safe_add_fx(track, "VST3: kHs Reverb (Kilohearts)")
  safe_add_fx(track, "VST3: kHs Limiter (Kilohearts)")
end

-- (Optional) Granular IDM bus currently reuses Clouds setup
local function build_granularidm_ribsargot(track)
  -- User did not have Ribs/Argotlunar installed in the scanned config.
  -- Use a hybrid granular bus based on Emergence/Lagrange instead.
  build_granularclouds_emergencelag(track)
end

local function apply_symbolic_fxbus(track, fx_name)
  if fx_name == "DF95_FXBus_GlitchSeq_DanaidesBread" then
    build_glitchseq_danaidesbread(track)
    return true
  elseif fx_name == "DF95_FXBus_GranularClouds_EmergenceLag" then
    build_granularclouds_emergencelag(track)
    return true
  elseif fx_name == "DF95_FXBus_BufferChaos_FractureHysteresis" then
    build_bufferchaos_fracturehysteresis(track)
    return true
  elseif fx_name == "DF95_FXBus_KHs_ModularWeave" then
    build_khs_modularweave(track)
    return true
  elseif fx_name == "DF95_FXBus_GranularIDM_RibsArgot" then
    build_granularidm_ribsargot(track)
    return true
  end
  return false
end

----------------------------------------------------------------
-- Main
----------------------------------------------------------------

local function main()
  local prof = load_artist_profile()
  if not prof then
    r.ShowMessageBox("Could not load DF95 ArtistProfile.\\nIs DF95_ArtistProfile_Loader.lua accessible?", "DF95 Artist FXBus Apply", 0)
    return
  end

  local fxbus_profiles = load_fxbus_profiles()
  if not fxbus_profiles then return end

  local fx_name, artist_key, variant_or_err = resolve_fxbus_for_artist(prof, fxbus_profiles)
  if not fx_name then
    r.ShowMessageBox("FXBus resolution error:\\n" .. tostring(variant_or_err), "DF95 Artist FXBus Apply", 0)
    return
  end

  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("No tracks selected.\\nSelect one or more tracks to apply the Artist FXBus.", "DF95 Artist FXBus Apply", 0)
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local ok_any = false
  for i = 0, sel_count - 1 do
    local tr = r.GetSelectedTrack(0, i)
    if tr then
      local handled = apply_symbolic_fxbus(tr, fx_name)
      if not handled then
        log(string.format("[DF95 FXBus] No symbolic builder for '%s' (artist=%s)", fx_name, artist_key or "unknown"))
      else
        ok_any = true
      end
    end
  end

  r.PreventUIRefresh(-1)

  local undo_label = string.format("[DF95] Apply Artist FXBus: %s (%s)", fx_name, artist_key or "unknown")
  r.Undo_EndBlock(undo_label, -1)

  if not ok_any then
    r.ShowMessageBox("No FXBus built.\\nCheck that your FXBus name has a symbolic builder in DF95_Artist_FXBus_Apply.lua", "DF95 Artist FXBus Apply", 0)
  else
    log(string.format("DF95 Artist FXBus applied: %s (artist=%s)", fx_name, artist_key or "unknown"))
  end
end

main()
