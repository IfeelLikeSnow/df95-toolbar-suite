-- @description Explode AutoBus MobileFR (Field Recorder App, S24 Ultra)
-- @version 1.0
-- @author DF95
-- @about
--   Spezieller Workflow für Field Recorder App (Pfitzinger, Samsung S24 Ultra):
--     * stellt DF95 FX/Coloring/Master-Busse sicher
--     * explodiert bei Bedarf Polywav/Multichannel-Items
--     * routet Quelltracks -> FX Bus -> Coloring Bus -> Master Bus
--     * setzt Export-Tags: Source=MobileFR, FXFlavor=FieldRec
--     * lädt optional FieldRecorder-spezifische FX-Ketten auf den FX-Bus
--
--   Hinweis: Die verwendeten FXChains sind:
--     * Effects/DF95/DF95_FXBus_FieldRecorder_S24U_Clean_01.RfxChain
--     * Effects/DF95/DF95_FXBus_FieldRecorder_S24U_Atmos_01.RfxChain
--
--   Wähle im Code unten, welche FXChain standardmäßig geladen werden soll.

local r = reaper

------------------------------------------------------------
-- USER CONFIG
------------------------------------------------------------

local FX_BUS_NAME       = "DF95 FX Bus"
local COLORING_BUS_NAME = "DF95 Coloring Bus"
local MASTER_BUS_NAME   = "DF95 Master Bus"

local CMD_DF95_MASTER_SELECTOR   = 0 -- 0 = aus
local CMD_DF95_FXBUS_SELECTOR    = 0 -- 0 = aus
local CMD_DF95_COLORING_SELECTOR = 0 -- 0 = aus

local CMD_EXPLODE_MULTI = 40224 -- bitte bei Bedarf anpassen

-- Welche FXChain soll auf den FX-Bus geladen werden?
-- "clean"  -> DF95_FXBus_FieldRecorder_S24U_Clean_01
-- "atmos"  -> DF95_FXBus_FieldRecorder_S24U_Atmos_01
local MOBILEFR_PROFILE = "clean"

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function dbg(msg)
  -- r.ShowConsoleMsg(tostring(msg) .. "\n")
end


local function get_mobilefr_profile()
  local p = reaper.GetExtState("DF95_MOBILEFR", "profile")
  if p == nil or p == "" then
    p = MOBILEFR_DEFAULT_PROFILE or "Clean"
  end
  -- normalisieren
  p = tostring(p)
  if p:lower() == "atmos" then
    return "Atmos"
  else
    return "Clean"
  end
end


local function is_mobilefr_qa_enabled()
  local v = r.GetExtState("DF95_MOBILEFR", "qa_enabled")
  if v == "1" or v == "true" or v == "yes" then return true end
  return false
end

local function is_mobilefr_autotag_enabled()
  local v = r.GetExtState("DF95_MOBILEFR", "autotag_enabled")
  if v == "1" or v == "true" or v == "yes" then return true end
  return false
end

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function find_track_by_name_exact(name)
  local num = r.CountTracks(0)
  for i = 0, num-1 do
    local tr = r.GetTrack(0, i)
    local ok, tr_name = r.GetTrackName(tr, "")
    if ok and tr_name == name then
      return tr, i
    end
  end
  return nil, -1
end

local function create_track_at_end(name)
  local num = r.CountTracks(0)
  r.InsertTrackAtIndex(num, true)
  local tr = r.GetTrack(0, num)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr, num
end

local function ensure_bus_track(name)
  local tr, idx = find_track_by_name_exact(name)
  if tr then return tr, idx, false end
  local new_tr, new_idx = create_track_at_end(name)
  return new_tr, new_idx, true
end

local function ensure_all_busses()
  local fx_tr, fx_idx, fx_new       = ensure_bus_track(FX_BUS_NAME)
  local col_tr, col_idx, col_new    = ensure_bus_track(COLORING_BUS_NAME)
  local master_tr, master_idx, mnew = ensure_bus_track(MASTER_BUS_NAME)

  if CMD_DF95_MASTER_SELECTOR ~= 0 then
    r.Main_OnCommand(CMD_DF95_MASTER_SELECTOR, 0)
  end
  if CMD_DF95_FXBUS_SELECTOR ~= 0 then
    r.Main_OnCommand(CMD_DF95_FXBUS_SELECTOR, 0)
  end
  if CMD_DF95_COLORING_SELECTOR ~= 0 then
    r.Main_OnCommand(CMD_DF95_COLORING_SELECTOR, 0)
  end

  return fx_tr, col_tr, master_tr
end

local function track_has_multichannel_item(tr)
  local item_count = r.CountTrackMediaItems(tr)
  for i = 0, item_count-1 do
    local item = r.GetTrackMediaItem(tr, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local src = r.GetMediaItemTake_Source(take)
      if src then
        local ch = r.GetMediaSourceNumChannels(src)
        if ch and ch > 2 then
          return true, ch
        end
      end
    end
  end
  return false, 0
end

local function any_selected_track_has_multichannel()
  local num_sel_tr = r.CountSelectedTracks(0)
  for i = 0, num_sel_tr-1 do
    local tr = r.GetSelectedTrack(0, i)
    local has, ch = track_has_multichannel_item(tr)
    if has then
      return true, ch
    end
  end
  return false, 0
end

local function route_sources_to_busses(fx_tr, col_tr, master_tr)
  if not fx_tr or not col_tr or not master_tr then return end

  local proj = 0
  local num_tracks = r.CountTracks(proj)

  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(proj, i)
    if tr ~= fx_tr and tr ~= col_tr and tr ~= master_tr then
      r.SetMediaTrackInfo_Value(tr, "B_MAINSEND", 0)
      local send_idx = r.CreateTrackSend(tr, fx_tr)
      r.SetTrackSendInfo_Value(tr, 0, send_idx, "D_VOL", 1.0)
      r.SetTrackSendInfo_Value(tr, 0, send_idx, "I_SENDMODE", 0)
    end
  end

  local send_fx_col = r.CreateTrackSend(fx_tr, col_tr)
  r.SetTrackSendInfo_Value(fx_tr, 0, send_fx_col, "D_VOL", 1.0)
  r.SetTrackSendInfo_Value(fx_tr, 0, send_fx_col, "I_SENDMODE", 0)

  local send_col_master = r.CreateTrackSend(col_tr, master_tr)
  r.SetTrackSendInfo_Value(col_tr, 0, send_col_master, "D_VOL", 1.0)
  r.SetTrackSendInfo_Value(col_tr, 0, send_col_master, "I_SENDMODE", 0)

  r.SetMediaTrackInfo_Value(master_tr, "B_MAINSEND", 1)
end

local function load_mobilefr_fxchain_on_fxbus(fx_tr)
  if not fx_tr then return end
  local root = df95_root()
  if root == "" then return end

  local resource = r.GetResourcePath()
  local sep = package.config:sub(1,1)

  local profile = get_mobilefr_profile()
  local chain_rel = nil
  if profile == "Atmos" then
    chain_rel = "Effects" .. sep .. "DF95" .. sep .. "DF95_FXBus_FieldRecorder_S24U_Atmos_01.RfxChain"
  else
    chain_rel = "Effects" .. sep .. "DF95" .. sep .. "DF95_FXBus_FieldRecorder_S24U_Clean_01.RfxChain"
  end

  local chain_path = resource .. sep .. chain_rel

  dbg("Lade MobileFR FXChain (" .. tostring(profile) .. "): " .. tostring(chain_path))
  -- FXChain direkt in den FX-Bus laden
  -- -1000: FX-Chain laden
  r.TrackFX_AddByName(fx_tr, chain_path, false, -1000)
end

local function set_export_tags_mobilefr
()
  -- DF95_Export_Core SetExportTag verwenden, falls vorhanden
  local ok, core = pcall(function()
    local root = df95_root()
    return dofile(root .. "DF95_Export_Core.lua")
  end)
  if ok and core and core.SetExportTag then
    core.SetExportTag("Source", "MobileFR")
    core.SetExportTag("FXFlavor", "FieldRec")
  else
    -- Fallback via ExtState direkt
    r.SetExtState("DF95_EXPORT_TAGS", "Source", "MobileFR", true)
    r.SetExtState("DF95_EXPORT_TAGS", "FXFlavor", "FieldRec", true)
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  local fx_tr, col_tr, master_tr = ensure_all_busses()

  local num_sel_tr = r.CountSelectedTracks(0)
  if num_sel_tr > 0 then
    local has_multi, ch = any_selected_track_has_multichannel()
    if has_multi and CMD_EXPLODE_MULTI ~= 0 then
      r.Main_OnCommand(CMD_EXPLODE_MULTI, 0)
    end
  end


route_sources_to_busses(fx_tr, col_tr, master_tr)
load_mobilefr_fxchain_on_fxbus(fx_tr)
set_export_tags_mobilefr()

if is_mobilefr_qa_enabled() then
  -- QA-Analyser starten (arbeitet auf selektierten Tracks/Items)
  local root = df95_root()
  pcall(dofile, root .. "DF95_MobileFR_QA.lua")
end

  r.Undo_EndBlock("DF95 Explode AutoBus MobileFR", -1)
end

main()
