-- @description DF95_V136 SampleDB – UCS Rename Revert Helper
-- @version 1.0
-- @author DF95
-- @about
--   Liest ein DF95 UCS-Rename-Log (JSON) und macht die darin protokollierten
--   Umbenennungen optional rückgängig:
--
--     * new_path -> old_path (per os.rename)
--     * Aktualisiert die DF95 SampleDB Multi-UCS JSON (path wieder auf old_path)
--     * Schreibt ein eigenes Revert-Log (JSON)
--
--   Typischer Workflow:
--     1. DF95_V134_UCS_Renamer.lua im Mode=RENAME verwenden.
--     2. Falls die Umbenennung nicht gefällt:
--          DF95_V136_UCS_RenameRevert_Helper.lua ausführen.
--     3. Im Dialog den Log-Dateinamen der Rename-Session angeben.
--
--   Hinweis:
--     * Dieser Helper geht davon aus, dass das Log im Format:
--         DF95_SampleDB_UCS_RenameLog_YYYYMMDD_HHMMSS.json
--       im <REAPER>/Support Verzeichnis liegt.

local r = reaper

------------------------------------------------------------
-- JSON Decoder / Encoder (wie im Renamer)
------------------------------------------------------------

local function decode_json(text)
  if type(text) ~= "string" then return nil, "no text" end

  local lua_text = text
  lua_text = lua_text:gsub('"(.-)"%s*:', '["%1"] =')
  lua_text = lua_text:gsub("%[", "{")
  lua_text = lua_text:gsub("%]", "}")
  lua_text = lua_text:gsub("null", "nil")

  lua_text = "return " .. lua_text

  local f, err = load(lua_text)
  if not f then return nil, err end

  local ok, res = pcall(f)
  if not ok then return nil, res end
  return res
end

local function encode_json_table(t, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)
  local parts = {}

  if type(t) ~= "table" then
    if type(t) == "string" then
      return string.format("%q", t)
    elseif type(t) == "number" then
      return tostring(t)
    elseif type(t) == "boolean" then
      return t and "true" or "false"
    else
      return "null"
    end
  end

  local is_array = true
  local max_index = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then
      is_array = false
      break
    else
      if k > max_index then max_index = k end
    end
  end

  if is_array then
    table.insert(parts, "[\n")
    for i = 1, max_index do
      local v = t[i]
      table.insert(parts, pad .. "  " .. encode_json_table(v, indent+1))
      if i < max_index then table.insert(parts, ",") end
      table.insert(parts, "\n")
    end
    table.insert(parts, pad .. "]")
  else
    table.insert(parts, "{\n")
    local first = true
    for k, v in pairs(t) do
      if not first then
        table.insert(parts, ",\n")
      end
      first = false
      table.insert(parts, pad .. "  " .. string.format("%q", tostring(k)) .. ": " .. encode_json_table(v, indent+1))
    end
    table.insert(parts, "\n" .. pad .. "}")
  end

  return table.concat(parts)
end

------------------------------------------------------------
-- Helper: Pfad
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function get_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function dirname(path)
  if not path then return "" end
  local dir = path:match("^(.*[\\/])")
  if dir then
    if dir:sub(-1) == "\\" or dir:sub(-1) == "/" then
      dir = dir:sub(1, -2)
    end
    return dir
  end
  return ""
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local res = r.GetResourcePath()
  local support_dir = join_path(res, "Support")

  local ok, vals = r.GetUserInputs(
    "DF95 UCS Rename Revert Helper",
    2,
    "Rename-Log-Dateiname (relativ zu /Support),Mode (DRY oder REVERT)",
    "DF95_SampleDB_UCS_RenameLog_YYYYMMDD_HHMMSS.json,DRY"
  )
  if not ok then return end

  local s_log, s_mode = vals:match("([^,]*),([^,]*)")
  s_log  = (s_log  or ""):gsub("^%s+", ""):gsub("%s+$", "")
  s_mode = (s_mode or ""):upper()

  local dry_run = (s_mode ~= "REVERT")

  if s_log == "" then
    r.ShowMessageBox(
      "Bitte einen Log-Dateinamen angeben (z.B. DF95_SampleDB_UCS_RenameLog_20251125_153000.json).",
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  local log_path = join_path(support_dir, s_log)

  local f = io.open(log_path, "r")
  if not f then
    r.ShowMessageBox(
      "Rename-Log nicht gefunden:\n"..log_path,
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end
  local text = f:read("*all")
  f:close()

  local log_tbl, err = decode_json(text)
  if not log_tbl then
    r.ShowMessageBox(
      "Fehler beim Lesen des Rename-Logs:\n"..tostring(err),
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  local entries = log_tbl.entries or {}
  if #entries == 0 then
    r.ShowMessageBox(
      "Das gewählte Log enthält keine Einträge.",
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  -- DB laden (entweder aus Log, oder per Default-Pfad)
  local db_path = log_tbl.db_path or get_db_path()
  local fdb = io.open(db_path, "r")
  if not fdb then
    r.ShowMessageBox(
      "SampleDB JSON nicht gefunden:\n"..db_path,
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end
  local db_text = fdb:read("*all")
  fdb:close()

  local db, err2 = decode_json(db_text)
  if not db then
    r.ShowMessageBox(
      "Fehler beim Lesen der SampleDB:\n"..tostring(err2),
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die SampleDB enthält keine Items.\n"..db_path,
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  -- Relevante Einträge: nur solche mit status="RENAMED"
  local plan = {}
  for _, e in ipairs(entries) do
    if e.status == "RENAMED" and e.old_path and e.new_path then
      plan[#plan+1] = {
        old_path = e.old_path,
        new_path = e.new_path
      }
    end
  end

  if #plan == 0 then
    r.ShowMessageBox(
      "Im ausgewählten Log gibt es keine Einträge mit status=\"RENAMED\".",
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  -- Preview
  local preview = {}
  local max_preview = 50
  for i = 1, math.min(max_preview, #plan) do
    local p = plan[i]
    preview[#preview+1] = string.format("%4d: %s\n      <- %s\n", i, p.old_path, p.new_path)
  end
  if #plan > max_preview then
    preview[#preview+1] = string.format("... (%d weitere Einträge)\n", #plan - max_preview)
  end

  local summary = string.format(
    "Mode: %s\nRename-Log: %s\nSampleDB: %s\nRevert-Kandidaten: %d\n\nBEISPIELE:\n\n%s",
    dry_run and "DRY (nur Vorschau)" or "REVERT (Dateien werden zurückbenannt)",
    log_path,
    db_path,
    #plan,
    table.concat(preview)
  )

  local btn = r.ShowMessageBox(
    summary .. "\n\nFortfahren?",
    "DF95 UCS Rename Revert Helper",
    3 -- Yes/No/Cancel
  )
  if btn ~= 6 then
    return
  end

  -- Revert-Log vorbereiten
  local revert_log_name = os.date("DF95_SampleDB_UCS_RenameRevertLog_%Y%m%d_%H%M%S.json")
  local revert_log_path = join_path(support_dir, revert_log_name)

  local revert_log = {
    source_log = log_path,
    db_path    = db_path,
    timestamp  = os.date("%Y-%m-%d %H:%M:%S"),
    mode       = dry_run and "DRY" or "REVERT",
    entries    = {}
  }

  if dry_run then
    for _, p in ipairs(plan) do
      revert_log.entries[#revert_log.entries+1] = {
        old_path = p.old_path,
        new_path = p.new_path,
        status   = "PLANNED_REVERT"
      }
    end

    local rf = io.open(revert_log_path, "w")
    if rf then
      rf:write(encode_json_table(revert_log, 0))
      rf:close()
    end

    r.ShowMessageBox(
      "DRY-RUN (Revert) abgeschlossen.\nRevert-Log geschrieben:\n"..revert_log_path,
      "DF95 UCS Rename Revert Helper",
      0
    )
    return
  end

  -- REVERT-Modus
  r.Undo_BeginBlock()

  local reverted = 0

  for _, p in ipairs(plan) do
    local old_path = p.old_path
    local new_path = p.new_path

    local ok_rev = os.rename(new_path, old_path)
    if ok_rev then
      reverted = reverted + 1

      -- DB wieder auf old_path setzen
      for _, it in ipairs(items) do
        if it.path == new_path then
          it.path = old_path
          it.ucs_reverted = true
          it.ucs_revert_log = revert_log_path
        end
      end

      revert_log.entries[#revert_log.entries+1] = {
        old_path = old_path,
        new_path = new_path,
        status   = "REVERTED"
      }
    else
      revert_log.entries[#revert_log.entries+1] = {
        old_path = old_path,
        new_path = new_path,
        status   = "REVERT_FAILED"
      }
    end
  end

  -- SampleDB zurückschreiben
  local fdbw = io.open(db_path, "w")
  if fdbw then
    fdbw:write(encode_json_table(db, 0))
    fdbw:close()
  end

  -- Revert-Log schreiben
  local rf = io.open(revert_log_path, "w")
  if rf then
    rf:write(encode_json_table(revert_log, 0))
    rf:close()
  end

  r.Undo_EndBlock("DF95 UCS Rename Revert Helper", -1)

  r.ShowMessageBox(
    string.format("Revert abgeschlossen.\nErfolgreich zurückbenannt: %d\nRevert-Log: %s", reverted, revert_log_path),
    "DF95 UCS Rename Revert Helper",
    0
  )
end

main()
