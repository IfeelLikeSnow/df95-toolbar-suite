-- @description DF95 Artist IDM FXBus Selector (rfxchain suggestions per Artist)
-- @version 1.0
-- @author DF95 + ChatGPT
-- @about
--   Liest das aktuelle ArtistProfile (DF95_ArtistProfile_Loader),
--   lädt Data/DF95/DF95_Artist_FXBusProfiles_v1.json
--   und zeigt alle "idm_fxbus_variants" als Vorschläge an.
--
--   Beim Klick auf einen Vorschlag:
--     -> lädt die entsprechende FXChain aus FXChains/DF95_FXBus_Artist/<Name>.rfxchain
--     -> fügt sie zu allen selektierten Tracks hinzu.
--
--   Beispiel:
--     * Artist-Key "autechre" -> zeigt FXBus_IDM_GranularScatter, FXBus_IDM_BitPhaseWarp, ...

local r = reaper

-- ImGui laden
local ok, imgui = pcall(require, "imgui")
if not ok or not imgui then
  r.ShowMessageBox(
    "ReaImGui (ReaScript API) nicht gefunden.\n" ..
    "Bitte 'ReaImGui: ReaScript binding for Dear ImGui' über ReaPack installieren.",
    "DF95 Artist IDM FXBus Selector",
    0
  )
  return
end

local ctx = imgui.CreateContext("DF95 Artist IDM FXBus Selector")

-- ArtistProfile Loader holen
local ArtistLoader = _G.DF95_ArtistProfileLoader
if not ArtistLoader or not ArtistLoader.load then
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local script_dir = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
  package.path = package.path .. ";" .. script_dir .. sep .. "?.lua"
  local ok2, mod = pcall(require, "DF95_ArtistProfile_Loader")
  if ok2 and mod and mod.load then
    ArtistLoader = mod
  end
end

local function get_current_artist_profile()
  if not ArtistLoader or not ArtistLoader.load then
    return nil, "ArtistProfileLoader nicht verfügbar"
  end
  local profile, status = ArtistLoader.load()
  return profile, status
end

-- JSON laden
local function load_fxbus_profiles()
  if not r.JSONDecode then
    return nil, "REAPER ohne JSONDecode (v6.82+ nötig)"
  end
  local res_path = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local json_path = res_path .. sep .. "Data" .. sep .. "DF95" .. sep .. "DF95_Artist_FXBusProfiles_v1.json"
  local f = io.open(json_path, "rb")
  if not f then
    return nil, "Konnte JSON nicht öffnen: " .. json_path
  end
  local contents = f:read("*a")
  f:close()
  local ok, obj = pcall(r.JSONDecode, contents)
  if not ok or not obj then
    return nil, "JSONDecode fehlgeschlagen"
  end
  return obj, nil
end

-- FXChain anwenden
local function apply_fxchain_idm(name)
  if not name or name == "" then return end
  local res_path = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local fx_path = res_path .. sep .. "FXChains" .. sep .. "DF95_FXBus_Artist" .. sep .. name .. ".rfxchain"

  local f = io.open(fx_path, "rb")
  if not f then
    r.ShowMessageBox("Konnte FXChain nicht öffnen:\n" .. fx_path, "DF95 Artist IDM FXBus Selector", 0)
    return
  end
  local chunk = f:read("*a")
  f:close()

  local sel_cnt = r.CountSelectedTracks(0)
  if sel_cnt == 0 then
    r.ShowMessageBox("Keine Tracks selektiert.\nBitte wähle einen oder mehrere Ziel-Tracks (z.B. deinen FX-Bus).", "DF95 Artist IDM FXBus Selector", 0)
    return
  end

  r.Undo_BeginBlock()
  for i=0, sel_cnt-1 do
    local tr = r.GetSelectedTrack(0, i)
    r.TrackFX_AddByName(tr, "FXCHAIN:" .. fx_path, false, -1)
  end
  r.Undo_EndBlock("[DF95] Apply IDM FXBus rfxchain: " .. name, -1)
end

-- UI-State
local state = {
  status_msg = "",
  variants = {},
  artist_name = "",
  artist_key = "",
}

local function init_state()
  local profile, status = get_current_artist_profile()
  if not profile then
    state.status_msg = "Kein ArtistProfile geladen: " .. (status or "?")
    return
  end

  state.artist_name = profile.name or "(unknown)"
  state.artist_key  = profile.key  or ""

  local fxprof, err = load_fxbus_profiles()
  if not fxprof then
    state.status_msg = err or "Fehler beim Laden der FXBus-Profile"
    return
  end

  local artists = fxprof.artists or {}
  local art = artists[state.artist_key]
  if not art then
    state.status_msg = "Kein FXBus-Profil für Artist-Key: " .. state.artist_key
    return
  end

  local list = art.idm_fxbus_variants or {}
  state.variants = {}
  for _,name in ipairs(list) do
    state.variants[#state.variants+1] = name
  end

  if #state.variants == 0 then
    state.status_msg = "Artist '"..state.artist_name.."' hat keine idm_fxbus_variants in DF95_Artist_FXBusProfiles_v1.json."
  else
    state.status_msg = string.format("Artist '%s' (%s) – %d IDM-FXBus-Vorschläge gefunden.", state.artist_name, state.artist_key, #state.variants)
  end
end

init_state()

-- Main loop
local function loop()
  imgui.SetNextWindowSize(ctx, 640, 320, imgui.Cond_FirstUseEver())
  local visible, open = imgui.Begin(ctx, "DF95 Artist IDM FXBus Selector", true)

  if visible then
    imgui.Text(ctx, "DF95 Artist IDM FXBus Selector")
    imgui.Separator(ctx)
    imgui.Text(ctx, "Aktueller Artist: ")
    imgui.SameLine(ctx)
    imgui.TextColored(ctx, 0.8, 0.9, 1.0, 1.0, state.artist_name .. "  [" .. (state.artist_key or "?") .. "]")

    imgui.Separator(ctx)
    imgui.TextWrapped(ctx, state.status_msg or "")

    if #state.variants > 0 then
      imgui.Separator(ctx)
      imgui.Text(ctx, "IDM FXBus Variants (rfxchain):")
      imgui.BeginChild(ctx, "variants_child", -1, -60, true)

      for _,name in ipairs(state.variants) do
        if imgui.Button(ctx, name, -1, 0) then
          apply_fxchain_idm(name)
        end
      end

      imgui.EndChild(ctx)
      imgui.Text(ctx, "Hinweis: FXChain wird zu allen selektierten Tracks hinzugefügt.")
    end

    if imgui.Button(ctx, "Neu laden", 120, 0) then
      init_state()
    end

    imgui.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    imgui.DestroyContext(ctx)
  end
end

r.defer(loop)
