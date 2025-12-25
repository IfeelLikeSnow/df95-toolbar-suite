-- @description Master Snapshot (save/restore)
-- @version 1.1
-- @author DF95
-- Speichert den Zustand des Mastertracks im Projekt (ProjExtState) und kann ihn wiederherstellen.

local r = reaper
local EXT_SECTION = "DF95_MASTER_SNAPSHOT"
local EXT_KEY     = "CHUNK"

local function get_chunk(tr)
  local ok, chunk = r.GetTrackStateChunk(tr, "", false)
  if not ok then return nil end
  return chunk
end

local function set_chunk(tr, chunk)
  if not chunk or chunk == "" then return false end
  return r.SetTrackStateChunk(tr, chunk, true)
end

local function main()
  local mst = r.GetMasterTrack(0)
  if not mst then
    r.ShowMessageBox("Kein Master-Track gefunden.", "DF95 Master Snapshot", 0)
    return
  end

  local has, chunk = r.GetProjExtState(0, EXT_SECTION, EXT_KEY)

  if has == 1 and chunk ~= "" then
    local ret = r.ShowMessageBox(
      "Es existiert bereits ein Master-Snapshot.\n\nYes = Wiederherstellen\nNo = Neuen Snapshot speichern\nCancel = Abbrechen",
      "DF95 Master Snapshot", 3
    )

    if ret == 6 then
      r.Undo_BeginBlock()
      set_chunk(mst, chunk)
      r.Undo_EndBlock("DF95: Master Snapshot – Restore", -1)
      return
    elseif ret == 7 then
      r.Undo_BeginBlock()
      local new_chunk = get_chunk(mst)
      if new_chunk then
        r.SetProjExtState(0, EXT_SECTION, EXT_KEY, new_chunk)
      end
      r.Undo_EndBlock("DF95: Master Snapshot – Overwrite", -1)
      return
    else
      return
    end
  else
    r.Undo_BeginBlock()
    local new_chunk = get_chunk(mst)
    if new_chunk then
      r.SetProjExtState(0, EXT_SECTION, EXT_KEY, new_chunk)
      r.ShowConsoleMsg("[DF95] Master Snapshot gespeichert.\n")
    end
    r.Undo_EndBlock("DF95: Master Snapshot – Save", -1)
  end
end

main()
