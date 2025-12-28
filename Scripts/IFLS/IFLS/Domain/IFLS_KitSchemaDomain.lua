-- IFLS_KitSchemaDomain.lua
-- Phase 30: Kit Schema Domain (generic drum kit representation)

local r = reaper
local M = {}

local NS = "IFLS_KITSCHEMA"

local function get_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function kit_to_string(kit)
  if not kit or type(kit) ~= "table" then return "return {}" end
  local lines = {}
  table.insert(lines, "return {")
  table.insert(lines, string.format("  name = %q,", kit.name or "IFLS Kit"))
  table.insert(lines, "  slots = {")
  if kit.slots then
    for i, slot in ipairs(kit.slots) do
      if slot.sample_path then
        table.insert(lines, string.format("    { name = %q, sample_path = %q, midi_note = %d },",
          slot.name or ("Slot " .. i), slot.sample_path or "", slot.midi_note or (35 + i)))
      end
    end
  end
  table.insert(lines, "  },")
  table.insert(lines, "}")
  return table.concat(lines, "\n")
end

local function string_to_kit(s)
  if not s or s == "" then return nil end
  local f, err = load(s)
  if not f then return nil end
  local ok, tbl = pcall(f)
  if not ok or type(tbl) ~= "table" then return nil end
  return tbl
end

function M.default_kit()
  return { name = "IFLS Kit", slots = {} }
end

function M.read_kit()
  local s = get_ext("KIT", "")
  local kit = string_to_kit(s)
  if not kit then
    kit = M.default_kit()
  end
  return kit
end

function M.write_kit(kit)
  local s = kit_to_string(kit)
  set_ext("KIT", s)
end

local function get_sample_path_from_item(item)
  local take = r.GetActiveTake(item)
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  if not src then return nil end
  local rv, path = r.GetMediaSourceFileName(src, "")
  return path
end

function M.build_kit_from_selected_items()
  local sel_cnt = r.CountSelectedMediaItems(0)
  if sel_cnt == 0 then
    r.ShowMessageBox("Keine Items selektiert.", "IFLS KitSchemaDomain", 0)
    return
  end

  local kit = M.default_kit()
  local note = 36 -- C1
  for i = 0, sel_cnt-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local path = get_sample_path_from_item(item)
    if path and path ~= "" then
      local _, name = r.GetSetMediaItemInfo_String(item, "P_NAME", "", false)
      if name == "" then
        name = string.format("Slice %d", i+1)
      end
      table.insert(kit.slots, {
        name = name,
        sample_path = path,
        midi_note = note,
      })
      note = note + 1
    end
  end

  M.write_kit(kit)
  r.ShowMessageBox("Kit aus selektierten Items aufgebaut (" .. tostring(#kit.slots) .. " Slots).", "IFLS KitSchemaDomain", 0)
end

local function add_rs5k_instance(track, sample_path, midi_note)
  if not track or not sample_path or sample_path == "" then return end

  local fx_idx = r.TrackFX_AddByName(track, "ReaSamplOmatic5000", false, -1)
  if fx_idx < 0 then
    r.ShowMessageBox("Konnte ReaSamplOmatic5000 nicht einfügen.", "IFLS KitSchemaDomain", 0)
    return
  end

  r.TrackFX_SetNamedConfigParm(track, fx_idx, "FILE0", sample_path)
  r.TrackFX_SetParam(track, fx_idx, 3, midi_note / 127.0)
  r.TrackFX_SetParam(track, fx_idx, 4, midi_note / 127.0)
  r.TrackFX_SetParam(track, fx_idx, 5, midi_note / 127.0)
end

function M.export_to_rs5k(new_track_name)
  local kit = M.read_kit()
  if not kit or not kit.slots or #kit.slots == 0 then
    r.ShowMessageBox("Kein Kit definiert.", "IFLS KitSchemaDomain", 0)
    return
  end

  r.Undo_BeginBlock2(0)

  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", new_track_name or kit.name or "IFLS Kit RS5k", true)

  for _, slot in ipairs(kit.slots) do
    add_rs5k_instance(tr, slot.sample_path, slot.midi_note or 36)
  end

  r.TrackList_AdjustWindows(false)
  r.Undo_EndBlock2(0, "IFLS: Export kit to RS5k", -1)
end

return M
