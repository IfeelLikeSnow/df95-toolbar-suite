-- IFLS_ArtistHub_ImGui.lua
-- IFLS Artist Hub (ImGui)
-- Zentrale Oberfläche für Artist-/Style-Parameter, die über IFLS_ArtistDomain
-- und optional IFLS_BeatDomain auf deinen Beat- und FX-Workflow wirken.
--
-- Abhängigkeiten:
--   Scripts/IFLS/IFLS/Core/IFLS_Contracts.lua
--   Scripts/IFLS/IFLS/Core/IFLS_ExtState.lua
--   Scripts/IFLS/IFLS/Core/IFLS_ImGui_Core.lua
--   Scripts/IFLS/IFLS/Domain/IFLS_ArtistDomain.lua
--   (optional) Scripts/IFLS/IFLS/Domain/IFLS_BeatDomain.lua

local r  = reaper
local ig = r.ImGui

local resource_path = r.GetResourcePath()
local core_path     = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local domain_path   = resource_path .. "/Scripts/IFLS/IFLS/Domain/"

local ok_contracts, contracts = pcall(dofile, core_path .. "IFLS_Contracts.lua")
local ok_ext,       ext       = pcall(dofile, core_path .. "IFLS_ExtState.lua")
local ok_ui,        ui_core   = pcall(dofile, core_path .. "IFLS_ImGui_Core.lua")
local ok_artist,    artist    = pcall(dofile, domain_path .. "IFLS_ArtistDomain.lua")
local ok_beat,      beat      = pcall(dofile, domain_path .. "IFLS_BeatDomain.lua")
local ok_idm_flavors, IDM_FLAVORS = pcall(dofile, domain_path .. "IFLS_IDMFlavorProfiles.lua")

if not ok_ui or not ui_core or not ig then
  r.ShowMessageBox(
    "IFLS Artist Hub: ReaImGui oder IFLS_ImGui_Core.lua nicht verfügbar.\nBitte ReaImGui installieren und IFLS/Core prüfen.",
    "IFLS Artist Hub",
    0
  )
  return
end

if not ok_artist or type(artist) ~= "table" then
  r.ShowMessageBox(
    "IFLS Artist Hub: IFLS_ArtistDomain.lua konnte nicht geladen werden.\nPrüfe Pfad: Scripts/IFLS/IFLS/Domain/",
    "IFLS Artist Hub",
    0
  )
  return
end

----------------------------------------------------------------
-- Lokaler Artist-State
----------------------------------------------------------------

local AK      = (ok_contracts and contracts.ARTIST_KEYS) or {}
local ns_art  = (ok_contracts and contracts.NS_ARTIST) or "DF95_ARTIST"
local ns_beat_cc = (ok_contracts and contracts.NS_BEAT_CC) or "DF95_BEAT_CC"

local FLAVOR_KEY = (ok_contracts and contracts.ARTIST_KEYS and contracts.ARTIST_KEYS.IDM_FLAVOR_PROFILE) or "IDM_FLAVOR_PROFILE"

local initialized = false

-- Wir halten einen einfachen Artist-State im Hub:
local a_state = {
  name        = artist.get_current_artist and artist.get_current_artist() or "",
  style       = "",
  humanize    = "",
  microtiming = "",
  idm_flavor  = "",
}

-- Rohwerte aus ExtState holen (falls vorhanden)
local function reload_state_from_ext()
  a_state.name        = artist.get_current_artist and artist.get_current_artist() or a_state.name or ""
  a_state.style       = ext.get_proj(ns_art, AK.STYLE_PRESET        or "STYLE_PRESET",        a_state.style or "")
  a_state.humanize    = ext.get_proj(ns_art, AK.HUMANIZE_DEPTH      or "HUMANIZE_DEPTH",      a_state.humanize or "")
  a_state.microtiming = ext.get_proj(ns_art, AK.MICROTIMING_VARIANT or "MICROTIMING_VARIANT", a_state.microtiming or "")
  a_state.idm_flavor  = ext.get_proj(ns_art, FLAVOR_KEY,                                a_state.idm_flavor or "")
end

local function write_state_to_ext()
  if artist.set_current_artist then
    artist.set_current_artist(a_state.name or "")
  end
  ext.set_proj(ns_art, AK.STYLE_PRESET        or "STYLE_PRESET",        a_state.style or "")
  ext.set_proj(ns_art, AK.HUMANIZE_DEPTH      or "HUMANIZE_DEPTH",      a_state.humanize or "")
  ext.set_proj(ns_art, AK.MICROTIMING_VARIANT or "MICROTIMING_VARIANT", a_state.microtiming or "")
  ext.set_proj(ns_art, FLAVOR_KEY,                                      a_state.idm_flavor or "")

  -- zusätzlich im Beat-CC-Namespace Artist spiegeln (für Beat UIs)
  local BCCK = (ok_contracts and contracts.BEAT_CC_KEYS) or {}
  ext.set_proj(ns_beat_cc, BCCK.ARTIST_PROFILE or "ARTIST_PROFILE", a_state.name or "")
end

----------------------------------------------------------------
-- Artist → Beat anwenden
----------------------------------------------------------------

local function apply_artist_to_beat()
  if not ok_beat or not beat or not beat.get_state or not beat.set_state then
    r.ShowConsoleMsg("IFLS Artist Hub: BeatDomain nicht verfügbar, kann Artist nicht auf Beat anwenden.\n")
    return
  end
  local bs = beat.get_state()
  if artist.apply_artist_to_beat then
    bs = artist.apply_artist_to_beat(a_state.name or "", bs)
  else
    -- Minimale Anwendung: Artist-Name in Beat-State spiegeln
    bs.artist_profile = a_state.name or ""
  end
  beat.set_state(bs)
end

----------------------------------------------------------------
-- Aktionen für vorhandene DF95 Artist-/Kit-/FX-Skripte
-- (symbolische NamedCommand-Strings, wie bei BeatDomain)
----------------------------------------------------------------

local ARTIST_CMDS = {
  -- Diese Strings sind PLATZHALTER. Du kannst sie 1:1 durch die
  -- echten Command-IDs ersetzen (z.B. _RSa1b2c3d4e5f6) oder deine
  -- DF95-Skripte so benennen, dass du sie leichter findest.
  --
  -- Beispiele:
  --   DF95_ArtistPanel_ImGui
  --   DF95_ArtistKitButtons
  --   DF95_ArtistFXBrain
  --
  ARTIST_PANEL      = "_RS_DF95_ArtistPanel_ImGui",
  ARTIST_KIT_BUTTONS= "_RS_DF95_ArtistKitButtons",
  ARTIST_FX_BRAIN   = "_RS_DF95_ArtistFXBrain",
}

local function run_artist_cmd(key)
  local named = ARTIST_CMDS[key]
  if not named or named == "" then return end
  local cmd_id = r.NamedCommandLookup(named)
  if cmd_id == 0 then
    r.ShowConsoleMsg("IFLS Artist Hub: NamedCommandLookup fehlgeschlagen für " .. tostring(named) .. "\n")
    return
  end
  r.Main_OnCommand(cmd_id, 0)
end

----------------------------------------------------------------
-- UI-Zeichnen
----------------------------------------------------------------

local function draw(ctx)
  if not initialized then
    reload_state_from_ext()
    ui_core.set_default_window_size(ctx, 620, 360)
    initialized = true
  end

  if ig.Button(ctx, "Reload Artist state") then
    reload_state_from_ext()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Write Artist state") then
    write_state_to_ext()
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Artist")
  ig.Separator(ctx)

  local changed

  ig.PushItemWidth(ctx, 260)
  local name = a_state.name or ""
  changed, name = ig.InputText(ctx, "Artist Name", name)
  if changed then
    a_state.name = name
  end

  local style = a_state.style or ""
  changed, style = ig.InputText(ctx, "Style Preset", style)
  if changed then
    a_state.style = style
  end

  local humanize = a_state.humanize or ""
  changed, humanize = ig.InputText(ctx, "Humanize Depth", humanize)
  if changed then
    a_state.humanize = humanize
  end

  local micro = a_state.microtiming or ""
  changed, micro = ig.InputText(ctx, "Microtiming Variant", micro)
  if changed then
    a_state.microtiming = micro
  end
  ig.PopItemWidth(ctx)

  ig.Separator(ctx)
  ig.Text(ctx, "IDM Flavor Profile")
  ig.Separator(ctx)

  if ok_idm_flavors and IDM_FLAVORS and type(IDM_FLAVORS) == "table" then
    local ids = {}
    for id, prof in pairs(IDM_FLAVORS) do
      ids[#ids+1] = id
    end
    table.sort(ids)

    local current_id = a_state.idm_flavor or ""
    local preview = "None"
    if current_id ~= "" and IDM_FLAVORS[current_id] then
      preview = IDM_FLAVORS[current_id].name or current_id
    end

    if ig.BeginCombo(ctx, "Flavor Profile", preview) then
      local is_sel = (current_id == "" or current_id == nil)
      if ig.Selectable(ctx, "None", is_sel) then
        a_state.idm_flavor = ""
      end
      for _, id in ipairs(ids) do
        local prof = IDM_FLAVORS[id]
        local label = prof and (prof.name or id) or id
        local selected = (id == current_id)
        if ig.Selectable(ctx, label, selected) then
          a_state.idm_flavor = id
        end
      end
      ig.EndCombo(ctx)
    end
  else
    ig.Text(ctx, "IDM Flavor Profiles: Modul nicht geladen.")
  end


  ig.Separator(ctx)
  ig.Text(ctx, "Apply")
  ig.Separator(ctx)

  if ig.Button(ctx, "Apply Artist to Beat") then
    write_state_to_ext()
    apply_artist_to_beat()
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Sync to Beat CC only") then
    write_state_to_ext()
  end

  ig.Separator(ctx)
  ig.Text(ctx, "Artist Tools (DF95)")
  ig.Separator(ctx)

  if ig.Button(ctx, "Open Artist Panel") then
    write_state_to_ext()
    run_artist_cmd("ARTIST_PANEL")
  end
  ig.SameLine(ctx)
  if ig.Button(ctx, "Open Artist Kit Buttons") then
    write_state_to_ext()
    run_artist_cmd("ARTIST_KIT_BUTTONS")
  end

  if ig.Button(ctx, "Open Artist FX Brain") then
    write_state_to_ext()
    run_artist_cmd("ARTIST_FX_BRAIN")
  end
end

----------------------------------------------------------------
-- Kontext & Mainloop
----------------------------------------------------------------

local ctx = ui_core.create_context("IFLS_ArtistHub")
if ctx then
  ui_core.run_mainloop(ctx, "IFLS Artist Hub", draw)
end
