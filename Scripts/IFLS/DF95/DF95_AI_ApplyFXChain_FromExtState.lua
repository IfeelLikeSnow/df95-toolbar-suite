-- @description DF95 AI Apply FXChain From ExtState (Chunk Loader)
-- @version 1.1
-- @author DF95
-- @about
--   Liest den von DF95_AI_ArtistFXBrain gesetzten FXChain-Pfad aus ExtState
--   und lädt die .rfxchain-Datei per Track-State-Chunk in alle selektierten Tracks.
--
--   Hinweise:
--     * Reaper bietet keine direkte API, um eine .rfxchain-Datei auf Tracks zu laden.
--       Dieses Script arbeitet daher explizit mit Track-State-Chunks.
--     * Die vorhandene FX-Kette des Tracks wird durch die FXChain aus der Datei ersetzt.
--       (Erweiterung auf "append" ist möglich, aber V1 ersetzt komplett.)

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 AI ApplyFXChain FromExtState", 0)
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local txt = f:read("*a") or ""
  f:close()
  return txt, nil
end

------------------------------------------------------------
-- FXCHAIN Chunk Handling
------------------------------------------------------------

-- Extrahiert den FXCHAIN-Block aus einem Track-State-Chunk.
-- Gibt start_index, end_index, fxchain_text zurück.
local function find_fxchain_block(chunk)
  local start_pos = chunk:find("\n<FXCHAIN")
  if not start_pos then
    -- evtl. direkt am Anfang
    start_pos = chunk:find("<FXCHAIN")
  end
  if not start_pos then return nil, nil, nil end

  -- Wir suchen das END des FXCHAIN-Blocks:
  -- Convention: FXCHAIN endet bei einer Zeile, die nur ">" enthält.
  -- Wir suchen ab start_pos nach "\n>\n" und nehmen die erste.
  local end_pos = chunk:find("\n>\n", start_pos)
  if not end_pos then
    -- Falls letzte Zeile ">" ohne nachfolgendes \n kommt
    end_pos = chunk:find("\n>$", start_pos)
    if not end_pos then
      return nil, nil, nil
    end
  end

  -- end_pos zeigt auf das \n vor ">".
  -- Wir wollen inklusive der schließenden ">\n".
  local close_line_end = end_pos + 3 -- "\n>\n"
  local fxchunk = chunk:sub(start_pos, close_line_end - 1)
  return start_pos, close_line_end - 1, fxchunk
end

-- Erzeugt einen vollständigen FXCHAIN-Block aus dem Inhalt einer .rfxchain-Datei.
local function normalize_rfxchain_text(txt)
  txt = txt or ""
  -- Wenn die Datei bereits mit <FXCHAIN beginnt, nehmen wir sie so.
  if txt:find("<FXCHAIN") then
    -- Sicherstellen, dass sie mit einer ">"-Zeile endet
    if not txt:match("\n>%s*$") then
      txt = txt .. "\n>"
    end
    return txt
  end

  -- Falls nur der Inhalt ohne Kopf/Tail vorliegt:
  return "<FXCHAIN\n" .. txt .. "\n>"
end

-- Ersetzt den FXCHAIN-Block in einem Track-Chunk durch den angegebenen FXCHAIN-Text.
local function replace_fxchain_in_chunk(chunk, new_fxchain_text)
  local s, e, old_fxchunk = find_fxchain_block(chunk)
  if not s then
    -- Wenn kein FXCHAIN vorhanden ist, versuchen wir, vor dem letzten '>' einzufügen.
    local insert_pos = chunk:find("\n>", 1, true)
    if not insert_pos then
      -- fallback: einfach anhängen
      return chunk .. "\n" .. new_fxchain_text .. "\n"
    end
    local head = chunk:sub(1, insert_pos-1)
    local tail = chunk:sub(insert_pos)
    return head .. "\n" .. new_fxchain_text .. tail
  end

  local head = chunk:sub(1, s-1)
  local tail = chunk:sub(e+1)
  return head .. new_fxchain_text .. tail
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local path = r.GetExtState("DF95_AI_ArtistFXBrain", "fxchain_path")
  if not path or path == "" then
    msg("Kein FXChain-Pfad im ExtState gefunden.\nBitte zuerst im 'DF95 AI Artist FXBrain' eine FXChain auswählen und Apply drücken.")
    return
  end

  if not file_exists(path) then
    msg("FXChain-Datei existiert nicht:\n" .. path)
    return
  end

  local fx_text, err = read_file(path)
  if not fx_text then
    msg("Fehler beim Lesen der FXChain-Datei:\n" .. tostring(err or "?"))
    return
  end

  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    msg("Keine Tracks selektiert.\nBitte wähle die Tracks aus, auf die die FXChain angewendet werden soll.")
    return
  end

  local fxchain_block = normalize_rfxchain_text(fx_text)

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local applied = 0
  for i = 0, sel_count-1 do
    local track = r.GetSelectedTrack(0, i)
    if track then
      local ok, chunk = r.GetTrackStateChunk(track, "", true)
      if ok and chunk and chunk ~= "" then
        local new_chunk = replace_fxchain_in_chunk(chunk, fxchain_block)
        if new_chunk and new_chunk ~= "" then
          r.SetTrackStateChunk(track, new_chunk, true)
          applied = applied + 1
        end
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 AI Apply FXChain From ExtState (Chunk Loader)", -1)

  msg(string.format("FXChain aus Datei:\n%s\n\nAuf %d selektierte Tracks angewendet.", path, applied))
end

main()
