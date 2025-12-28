-- DF95_Resolve_Toolbar_Templates.lua
-- Converts Phase-94/V8_A3 *.Toolbar.ReaperMenu templates (with _RS_PLACEHOLDER tokens)
-- into real importable *.ReaperMenuSet files by replacing placeholders using a map file.
--
-- 1) Put DF95_Toolbar_ID_Map.lua in: %APPDATA%\REAPER\Scripts\
--    (start from the provided TEMPLATE and fill real _RSxxxx IDs from Actions list)
-- 2) Run this script and pick one or more *.Toolbar.ReaperMenu files
--
-- Output: %APPDATA%\REAPER\MenuSets\<same name>.ReaperMenuSet
--
-- Notes:
-- - REAPER will import an empty toolbar if command IDs are missing. This script prevents that.
-- - You can re-run anytime after updating the map.

local r = reaper

local function readfile(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

local function writefile(p, s)
  local f = io.open(p, "wb"); if not f then return false end
  f:write(s); f:close()
  return true
end

local function splitlines(s)
  s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
  local t = {}
  for line in s:gmatch("([^\n]*)\n?") do
    if line == nil then break end
    t[#t+1] = line
  end
  return t
end

local function load_map()
  local ok, map = pcall(dofile, r.GetResourcePath() .. "/Scripts/DF95_Toolbar_ID_Map.lua")
  if ok and type(map) == "table" then return map end
  r.MB("Missing map file:\n\n%APPDATA%\\REAPER\\Scripts\\DF95_Toolbar_ID_Map.lua\n\nCreate it from the provided TEMPLATE and fill real _RSxxxx IDs.", "DF95", 0)
  return nil
end

local function pick_files()
  -- Reaper has single-file picker; allow multiple by re-running or by selecting a folder
  local ok, fn = r.GetUserFileNameForRead("", "Select *.Toolbar.ReaperMenu (template)", ".ReaperMenu")
  if not ok or not fn or fn == "" then return nil end
  return { fn }
end

local function basename(p)
  return p:match("([^/\\]+)$") or p
end

local function replace_placeholders(text, map, missing)
  -- Replace any token that looks like _RS_SOMETHING (all-caps/underscore) if it's in map and non-empty.
  -- Keep original if missing.
  local function repl(tok)
    local v = map[tok]
    if type(v) == "string" and v ~= "" then
      return v
    end
    missing[tok] = true
    return tok
  end
  return (text:gsub("(_RS_[A-Z0-9_]+)", repl))
end

local function to_menuset_syntax(lines)
  -- The template is already close to menuset syntax; REAPER accepts a .ReaperMenuSet
  -- that starts with [toolbar] blocks. We'll preserve content and just ensure header exists.
  -- If your template already begins with [toolbar], we can output as-is.
  return table.concat(lines, "\r\n") .. "\r\n"
end

local map = load_map()
if not map then return end

local files = pick_files()
if not files then return end

for _, f in ipairs(files) do
  local src = readfile(f)
  if not src then
    r.MB("Could not read:\n" .. f, "DF95", 0)
    goto continue
  end

  local missing = {}
  local replaced = replace_placeholders(src, map, missing)

  -- Build output name: <original>.ReaperMenuSet
  local out_name = basename(f):gsub("%.ReaperMenu$", ".ReaperMenuSet")
  local out_path = r.GetResourcePath() .. "/MenuSets/" .. out_name

  local ok = writefile(out_path, to_menuset_syntax(splitlines(replaced)))
  if not ok then
    r.MB("Could not write:\n" .. out_path, "DF95", 0)
    goto continue
  end

  local miss_list = {}
  for k,_ in pairs(missing) do miss_list[#miss_list+1] = k end
  table.sort(miss_list)

  if #miss_list > 0 then
    r.MB(
      "Wrote MenuSet:\n" .. out_path ..
      "\n\nBUT these placeholders are still unresolved (toolbar may import partially/empty):\n- " ..
      table.concat(miss_list, "\n- ") ..
      "\n\nFill them in DF95_Toolbar_ID_Map.lua (Actions list shows real _RSxxxx IDs).",
      "DF95",
      0
    )
  else
    r.MB("Wrote MenuSet:\n" .. out_path .. "\n\nAll placeholders resolved. Import it via:\nOptions > Customize menus/toolbars > Import.", "DF95", 0)
  end

  ::continue::
end
