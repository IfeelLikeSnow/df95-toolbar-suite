--[[
DF95 - AI FXChain BatchRequest From Selection (Lua/ReaScript)

Option 6: AI-Batching (mehrere Items/Tracks analysieren).

Dieses Script sammelt Kontext über die aktuelle Auswahl und schreibt
eine Batch-Request-JSON-Datei für deinen AI-Worker.

Konzept:
- Geht alle selektierten Media-Items durch (oder, falls keine Items selektiert sind,
  alle Tracks in der Track-Selektion).
- Für jedes Item/Track werden Metadaten gesammelt:
    * Track-Name, Track-GUID
    * Item-GUID, Position, Länge, aktiver Take-Name
    * heuristisch abgeleitete Rolle (z.B. DRUMS, BASS, SFX, DIALOG)
    * heuristische UCS-Tags (WHOOSH, IMPACT, RISE, AMBIENCE, TEXTURE, ...)
- Schreibt alles als JSON nach:
    Data/DF95/ai_fxchains_batch_request.json

Dein AI-Worker kann diese Datei einlesen, pro Entry eine passende FXChain wählen
und z.B. eine "ai_fxchains_result.json" (oder mehrere) generieren.

Das Script selbst wendet noch keine FXChains an – es bereitet nur den AI-Input vor.
]]--

-- @description DF95 - AI FXChain BatchRequest From Selection
-- @version 1.0
-- @author DF95 / Reaper DAW Ultimate Assistant
-- @about Builds a batch AI request JSON from the current selection (items/tracks) for DF95 AI-FX workflow.

local r = reaper

-------------------------------------------------------
-- Utility: Paths
-------------------------------------------------------

local sep = package.config:sub(1, 1)

local function normalize_slashes(path)
  return path:gsub("[/\\]", sep)
end

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_resource_path()
  return normalize_slashes(r.GetResourcePath())
end

local function get_data_root()
  return join_path(get_resource_path(), "Data" .. sep .. "DF95")
end

-------------------------------------------------------
-- Utility: File IO
-------------------------------------------------------

local function ensure_dir(path)
  -- Reaper hat RecursiveCreateDirectory, aber hier nur für Data/DF95
  r.RecursiveCreateDirectory(path, 0)
end

local function write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then return false, err end
  f:write(content)
  f:close()
  return true
end

-------------------------------------------------------
-- Minimal JSON-Encoder
-------------------------------------------------------

local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  str = str:gsub("\t", "\\t")
  return str
end

local function json_encode_value(v)
  local t = type(v)
  if t == "string" then
    return "\"" .. json_escape(v) .. "\""
  elseif t == "number" then
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    local isArray = true
    local maxIndex = 0
    for k, _ in pairs(v) do
      if type(k) ~= "number" then
        isArray = false
        break
      else
        if k > maxIndex then maxIndex = k end
      end
    end
    local parts = {}
    if isArray then
      for i = 1, maxIndex do
        parts[#parts+1] = json_encode_value(v[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      for k, val in pairs(v) do
        parts[#parts+1] = "\"" .. json_escape(k) .. "\":" .. json_encode_value(val)
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  elseif t == "nil" then
    return "null"
  else
    return "\"" .. json_escape(tostring(v)) .. "\""
  end
end

local function json_encode(tbl)
  return json_encode_value(tbl)
end

-------------------------------------------------------
-- Heuristiken: Rolle & UCS Tags
-------------------------------------------------------

local function detect_role(track_name, item_name)
  local s = (track_name .. " " .. item_name):lower()

  if s:find("drum") or s:find("kick") or s:find("snare") or s:find("perc") then
    return "DRUMS"
  elseif s:find("bass") then
    return "BASS"
  elseif s:find("vox") or s:find("voc") or s:find("voice") or s:find("dialog") then
    return "DIALOG"
  elseif s:find("sfx") or s:find("fx") or s:find("whoosh") or s:find("impact") then
    return "SFX"
  elseif s:find("amb") or s:find("atmo") or s:find("room") or s:find("env") then
    return "AMBIENCE"
  elseif s:find("gtr") or s:find("guitar") then
    return "GUITAR"
  elseif s:find("piano") or s:find("keys") or s:find("synth") then
    return "MUSIC"
  end

  return "GENERIC"
end

local function detect_ucs_tags(track_name, item_name)
  local s = (track_name .. " " .. item_name):lower()
  local tags = {}

  local function add(tag)
    for _, t in ipairs(tags) do
      if t == tag then return end
    end
    tags[#tags+1] = tag
  end

  if s:find("whoosh") or s:find("swoosh") then
    add("WHOOSH")
  end
  if s:find("impact") or s:find("hit") or s:find("slam") or s:find("boom") then
    add("IMPACT")
  end
  if s:find("rise") or s:find("riser") or s:find("build") then
    add("RISE")
  end
  if s:find("sweep") or s:find("sweeper") then
    add("SWEEP")
  end
  if s:find("amb") or s:find("atmo") or s:find("room") or s:find("env") then
    add("AMBIENCE")
  end
  if s:find("texture") or s:find("grain") or s:find("layer") then
    add("TEXTURE")
  end
  if s:find("whoosh") and s:find("sweet") then
    add("SWEETENER")
  end

  return tags
end

-------------------------------------------------------
-- Batch Sammlung
-------------------------------------------------------

local function collect_item_entries()
  local entries = {}
  local cnt = r.CountSelectedMediaItems(0)

  for i = 0, cnt-1 do
    local item = r.GetSelectedMediaItem(0, i)
    if item then
      local tr = r.GetMediaItem_Track(item)
      local _, track_name = r.GetTrackName(tr, "")
      local track_guid = ({r.GetSetMediaTrackInfo_String(tr, "GUID", "", false)})[2] or ""

      local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      local item_guid = r.BR_GetMediaItemGUID and r.BR_GetMediaItemGUID(item) or tostring(item)

      local take = r.GetActiveTake(item)
      local _, take_name = "", ""
      if take then
        _, take_name = r.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      end

      local role = detect_role(track_name or "", take_name or "")
      local ucs = detect_ucs_tags(track_name or "", take_name or "")

      entries[#entries+1] = {
        id            = i + 1,
        entry_type    = "item",
        track_name    = track_name or "",
        track_guid    = track_guid,
        item_guid     = item_guid,
        item_position = item_pos,
        item_length   = item_len,
        take_name     = take_name or "",
        role          = role,
        ucs_tags      = ucs,
      }
    end
  end

  return entries
end

local function collect_track_entries()
  local entries = {}
  local cnt = r.CountSelectedTracks(0)

  for i = 0, cnt-1 do
    local tr = r.GetSelectedTrack(0, i)
    if tr then
      local _, track_name = r.GetTrackName(tr, "")
      local track_guid = ({r.GetSetMediaTrackInfo_String(tr, "GUID", "", false)})[2] or ""
      local role = detect_role(track_name or "", "")
      local ucs = detect_ucs_tags(track_name or "", "")

      entries[#entries+1] = {
        id            = i + 1,
        entry_type    = "track",
        track_name    = track_name or "",
        track_guid    = track_guid,
        role          = role,
        ucs_tags      = ucs,
      }
    end
  end

  return entries
end

-------------------------------------------------------
-- Main
-------------------------------------------------------

local function main()
  local proj = 0
  local _, proj_name = r.GetProjectName(proj, "")
  local proj_path = r.GetProjectPathEx(proj, "", 0)

  local items_cnt = r.CountSelectedMediaItems(0)
  local tracks_cnt = r.CountSelectedTracks(0)

  if items_cnt == 0 and tracks_cnt == 0 then
    r.ShowMessageBox("Keine Items oder Tracks selektiert.\nBitte wähle mindestens ein Item oder eine Spur aus.", "DF95 AI BatchRequest", 0)
    return
  end

  local entries
  local mode

  if items_cnt > 0 then
    mode = "items"
    entries = collect_item_entries()
  else
    mode = "tracks"
    entries = collect_track_entries()
  end

  local data_root = get_data_root()
  ensure_dir(data_root)
  local out_path = join_path(data_root, "ai_fxchains_batch_request.json")

  local doc = {
    version      = "1.0",
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    project_name = proj_name or "",
    project_path = proj_path or "",
    selection_mode = mode,
    entry_count    = #entries,
    entries        = entries,
  }

  local json_str = json_encode(doc)
  local ok, err = write_file(out_path, json_str)
  if not ok then
    r.ShowMessageBox("Fehler beim Schreiben der Batch-Request-Datei:\n" .. tostring(err), "DF95 AI BatchRequest", 0)
    return
  end

  r.ShowMessageBox("Batch-Request geschrieben:\n" .. out_path .. "\nEinträge: " .. tostring(#entries), "DF95 AI BatchRequest", 0)
end

r.Undo_BeginBlock()
main()
r.Undo_EndBlock("DF95: AI FXChain BatchRequest From Selection", -1)
