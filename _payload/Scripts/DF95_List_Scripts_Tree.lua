-- DF95_List_Scripts_Tree.lua
-- Scans %APPDATA%\REAPER\Scripts and exports a full folder/file inventory.
-- Outputs:
--   %APPDATA%\REAPER\DF95_ScriptsTree.jsonl  (one JSON object per line)
--   %APPDATA%\REAPER\DF95_ScriptsTree.csv    (CSV table)

local sep = package.config:sub(1,1)
local scripts_root = reaper.GetResourcePath() .. sep .. "Scripts"
local out_jsonl = reaper.GetResourcePath() .. sep .. "DF95_ScriptsTree.jsonl"
local out_csv   = reaper.GetResourcePath() .. sep .. "DF95_ScriptsTree.csv"

-- Optional: skip some huge/vendor folders by substring match (edit if you want)
local SKIP_SUBSTR = {
  -- "node_modules",
  -- ".git",
}

local function should_skip(fullpath)
  for _, s in ipairs(SKIP_SUBSTR) do
    if fullpath:find(s, 1, true) then return true end
  end
  return false
end

local function json_escape(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub("\"", "\\\"")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\n", "\\n")
  s = s:gsub("\t", "\\t")
  return s
end

local function to_unix_path(p)
  return (p:gsub("\\", "/"))
end

local function csv_escape(s)
  s = tostring(s or "")
  if s:find('[,"\n]') then
    s = '"' .. s:gsub('"', '""') .. '"'
  end
  return s
end

local function write_line(f, line)
  f:write(line)
  f:write("\n")
end

local function get_file_size(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local size = f:seek("end")
  f:close()
  return size
end

local function list_dir(path)
  -- returns array of names (files+dirs) excluding . and ..
  local t = {}
  local i = 0
  while true do
    local fn = reaper.EnumerateFiles(path, i)
    if not fn then break end
    t[#t+1] = {name=fn, is_dir=false}
    i = i + 1
  end
  i = 0
  while true do
    local dn = reaper.EnumerateSubdirectories(path, i)
    if not dn then break end
    t[#t+1] = {name=dn, is_dir=true}
    i = i + 1
  end
  return t
end

local jsonf = assert(io.open(out_jsonl, "wb"))
local csvf  = assert(io.open(out_csv, "wb"))

-- CSV header
write_line(csvf, table.concat({
  "type","rel_path","name","ext","bytes","abs_path"
}, ","))

local file_count, dir_count = 0, 0

local function scan_dir(abs_dir, rel_dir)
  if should_skip(abs_dir) then return end

  dir_count = dir_count + 1

  local items = list_dir(abs_dir)
  for _, it in ipairs(items) do
    local abs = abs_dir .. sep .. it.name
    local rel = rel_dir ~= "" and (rel_dir .. "/" .. it.name) or it.name
    rel = to_unix_path(rel)

    if it.is_dir then
      -- JSONL record for dir
      write_line(jsonf, string.format(
        '{"type":"dir","rel_path":"%s","name":"%s","abs_path":"%s"}',
        json_escape(rel), json_escape(it.name), json_escape(abs)
      ))
      -- CSV record for dir
      write_line(csvf, table.concat({
        "dir",
        csv_escape(rel),
        csv_escape(it.name),
        "",
        "",
        csv_escape(abs)
      }, ","))

      scan_dir(abs, rel)

    else
      file_count = file_count + 1
      local ext = it.name:match("%.([^.]+)$") or ""
      local bytes = get_file_size(abs)

      write_line(jsonf, string.format(
        '{"type":"file","rel_path":"%s","name":"%s","ext":"%s","bytes":%s,"abs_path":"%s"}',
        json_escape(rel),
        json_escape(it.name),
        json_escape(ext),
        bytes and tostring(bytes) or "null",
        json_escape(abs)
      ))

      write_line(csvf, table.concat({
        "file",
        csv_escape(rel),
        csv_escape(it.name),
        csv_escape(ext),
        bytes and tostring(bytes) or "",
        csv_escape(abs)
      }, ","))
    end
  end
end

reaper.ShowConsoleMsg("DF95 scan start: " .. scripts_root .. "\n")
scan_dir(scripts_root, "")
jsonf:close()
csvf:close()

reaper.ShowConsoleMsg(string.format(
  "DF95 scan done. dirs=%d files=%d\nWrote:\n%s\n%s\n",
  dir_count, file_count, out_jsonl, out_csv
))
reaper.MB("Scan fertig!\n\nAusgabe:\n" .. out_jsonl .. "\n" .. out_csv, "DF95", 0)
