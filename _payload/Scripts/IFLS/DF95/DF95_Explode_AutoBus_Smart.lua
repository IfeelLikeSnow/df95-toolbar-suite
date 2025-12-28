-- @description Explode AutoBus Smart (create FX/Coloring/Master bus + polywav explode)
-- @version 1.0
-- @author DF95
-- @about
--   Wenn aufgerufen:
--     * stellt sicher, dass FX-Bus, Coloring-Bus und Master-Bus existieren
--     * wenn auf selektierten Tracks Polywav-/Multichannel-Items liegen:
--         -> explodiert diese in Einzelspuren (1 Kanal pro Track)
--     * bei normalen Handy-/Mono-/Stereo-Aufnahmen:
--         -> nur Busse anlegen, nichts zerstören
--
--   Die Bussnamen sind unten konfigurierbar.
--   Routing ist bewusst minimal, damit es sich sauber in dein DF95-System einpasst.
--   Wenn du bereits DF95-spezifische Bus-Selector-Scripts nutzt, kannst du sie
--   optional aus diesem Script heraus aufrufen.

local r = reaper

------------------------------------------------------------
-- USER CONFIG
------------------------------------------------------------

local FX_BUS_NAME       = "DF95 FX Bus"
local COLORING_BUS_NAME = "DF95 Coloring Bus"
local MASTER_BUS_NAME   = "DF95 Master Bus"

-- Wenn du nach dem Anlegen der Busse automatisch deine DF95-Selector-Scripts
-- starten willst, kannst du hier die Action-Kommandos eintragen.
-- Beispiel: local CMD_DF95_MASTER_SELECTOR = r.NamedCommandLookup("_DF95_MASTERBUS_SELECTOR")
local CMD_DF95_MASTER_SELECTOR   = 0 -- 0 = aus
local CMD_DF95_FXBUS_SELECTOR    = 0 -- 0 = aus
local CMD_DF95_COLORING_SELECTOR = 0 -- 0 = aus

------------------------------------------------------------
-- HELPERS: tracks & sources
------------------------------------------------------------

local function dbg(msg)
  -- r.ShowConsoleMsg(tostring(msg) .. "\n")
end

local function find_track_by_name_exact(name)
  local num = r.CountTracks(0)
  for i = 0, num-1 do
    local tr = r.GetTrack(0, i)
    local retval, tr_name = r.GetTrackName(tr, "")
    if retval and tr_name == name then
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
  if tr then
    return tr, idx, false
  end
  local new_tr, new_idx = create_track_at_end(name)
  return new_tr, new_idx, true
end

local function ensure_all_busses()
  local fx_tr, fx_idx, fx_new       = ensure_bus_track(FX_BUS_NAME)
  local col_tr, col_idx, col_new    = ensure_bus_track(COLORING_BUS_NAME)
  local master_tr, master_idx, mnew = ensure_bus_track(MASTER_BUS_NAME)

  dbg(string.format("[DF95] FXBus=%d (new=%s) | Coloring=%d (new=%s) | MasterBus=%d (new=%s)",
    fx_idx, tostring(fx_new), col_idx, tostring(col_new), master_idx, tostring(mnew)))

  -- Optional: DF95-Selector-Scripts starten
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

------------------------------------------------------------
-- MAIN
------------------------------------------------------------


-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
-- DF95 Safety System – Stufe 3
-- MicFX / AIWorker / Routing Safety Helpers
-------------------------------------------------------------------------------
local function df95_load_safety_module(mod_name)
  local ok, mod = pcall(require, mod_name)
  if ok and mod then return mod end

  -- Fallback: versuchen, relativ zum Script-Pfad zu laden
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source or ""
  local script_dir = script_path:match("^@(.+[\/])")
  if script_dir then
    local chunk, err = loadfile(script_dir .. mod_name .. ".lua")
    if chunk then
      local ok2, res = pcall(chunk)
      if ok2 then return res end
    end
  end
  return nil
end

local SafetyMicFX   = df95_load_safety_module("DF95_Safety_MicFX")
local SafetyAI      = df95_load_safety_module("DF95_Safety_AIWorker")
local SafetyRouting = df95_load_safety_module("DF95_Safety_RoutingGuard")

local function DF95_Explode_Safety_Stufe3()
  if SafetyAI and SafetyAI.check_zoom_aiworker_present then
    SafetyAI.check_zoom_aiworker_present()
  end
  if SafetyMicFX and SafetyMicFX.run_for_selected_tracks then
    SafetyMicFX.run_for_selected_tracks()
  end
  if SafetyRouting and SafetyRouting.scan_for_duplicate_sends_on_selected then
    SafetyRouting.scan_for_duplicate_sends_on_selected()
  end
end
-------------------------------------------------------------------------------

DF95 Safety System – Stufe 2
-- Mic/Device/Channel Preflight Analyzer for Explode_AutoBus_Smart
-------------------------------------------------------------------------------

local function dbg(msg)
  if DEBUG then
    r.ShowConsoleMsg("[DF95 Explode Safety] " .. tostring(msg) .. "\n")
  end
end

local function detect_device_from_source(src)
  if not src then return "unknown" end
  local _, fn = r.GetMediaSourceFileName(src, "")
  local lfn = (fn or ""):lower()
  if lfn:find("zoom") and lfn:find("f6") then
    return "zoom_f6"
  elseif lfn:find("zoom") and (lfn:find("h5") or lfn:find("h4")) then
    return "zoom_h_series"
  elseif lfn:find("fieldrec") or lfn:find("recorder") or lfn:find("phon") then
    return "fieldrec_app"
  elseif lfn:find(".wav") or lfn:find(".flac") or lfn:find(".aiff") then
    return "generic_audio"
  end
  return "unknown"
end

local function analyze_selected_items_multichannel()
  local num_sel_tr = r.CountSelectedTracks(0)
  local total_items = 0
  local max_ch = 0
  local device_kinds = {}
  for ti = 0, num_sel_tr-1 do
    local tr = r.GetSelectedTrack(0, ti)
    local item_cnt = r.CountTrackMediaItems(tr)
    for ii = 0, item_cnt-1 do
      local it = r.GetTrackMediaItem(tr, ii)
      if r.IsMediaItemSelected(it) then
        total_items = total_items + 1
        local take = r.GetActiveTake(it)
        if take and not r.TakeIsMIDI(take) then
          local src = r.GetMediaItemTake_Source(take)
          local ch  = r.GetMediaSourceNumChannels(src)
          if ch and ch > max_ch then max_ch = ch end
          local dev = detect_device_from_source(src)
          device_kinds[dev] = (device_kinds[dev] or 0) + 1
        end
      end
    end
  end
  return {
    total_items = total_items,
    max_channels = max_ch,
    device_kinds = device_kinds
  }
end

local function DF95_Explode_PreflightSafety()
  local info = analyze_selected_items_multichannel()

  if info.total_items == 0 then
    dbg("Preflight: keine selektierten Items – nur Busses werden erstellt.")
    return
  end

  local msg = string.format(
    "Preflight: %d selektierte Items, max %d Kanäle.\n",
    info.total_items, info.max_channels or 0
  )

  local dev_list = {}
  for k, v in pairs(info.device_kinds or {}) do
    dev_list[#dev_list+1] = string.format("%s x%d", k, v)
  end
  if #dev_list > 0 then
    msg = msg .. "Erkannte Quellen: " .. table.concat(dev_list, ", ") .. "\n"
  end

  if info.max_channels and info.max_channels >= 6 and (info.device_kinds["zoom_f6"] or 0) > 0 then
    msg = msg .. "Hinweis: Zoom F6 Multichannel erkannt – Explode sollte Kanal-zu-Track sauber mappen.\n"
  end

  if info.device_kinds["zoom_f6"] and info.device_kinds["fieldrec_app"] then
    msg = msg .. "Warnung: Mischung aus Zoom F6 und Fieldrec-App – prüfe nachher dein Routing.\n"
  end

  dbg(msg)
end

-------------------------------------------------------------------------------

local function main()
  r.Undo_BeginBlock()

  -- Safety System Stufe 2: Preflight-Analyse
  DF95_Explode_PreflightSafety()

  -- 1) Erst Busses sicherstellen
  ensure_all_busses()

  -- 2) Check, ob selektierte Tracks Multichannel-Items (Polywav etc.) enthalten
  local num_sel_tr = r.CountSelectedTracks(0)
  if num_sel_tr == 0 then
    -- Nichts selektiert -> nur Busse angelegt, fertig
    r.Undo_EndBlock("DF95 Explode AutoBus Smart (only ensured busses)", -1)
    return
  end

  local has_multi, channels = any_selected_track_has_multichannel()
  if not has_multi then
    -- Keine Polywav/Multichannel -> nur Busse angelegt, nichts explodieren
    r.Undo_EndBlock("DF95 Explode AutoBus Smart (busses, no explode)", -1)
    return
  end

  -- 3) Multichannel/Polywav: Explode ausführen
  -- WICHTIG: Die Command-ID hier ggf. in REAPER verifizieren!
  -- Standard: "Item: Explode multichannel audio or MIDI items to new one-channel items"
  -- Üblicherweise Command-ID 40224, bitte in deiner Action-List checken.
  local CMD_EXPLODE_MULTI = 40224 -- ggf. anpassen!

  r.Main_OnCommand(CMD_EXPLODE_MULTI, 0)

  r.Undo_EndBlock("DF95 Explode AutoBus Smart (busses + polywav explode)", -1)
end

main()
