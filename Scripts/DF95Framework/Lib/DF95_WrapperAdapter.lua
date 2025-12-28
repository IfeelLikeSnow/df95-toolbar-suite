-- DF95_WrapperAdapter.lua
-- Purpose: normalize wrapper-loaded entries (CSV/JSON/FolderScan) so RequireRules can infer dependencies
-- Strategy:
--  1) Normalize action fields: action/actions/cmd/command/command_id -> item.actions[]
--  2) If item.kind=="script" and item.path exists: scan script for NamedCommandLookup("_SWS_...") etc -> item.actions[]
--  3) Keep adapter side-effect-free apart from adding normalized fields (item.action_strings, item.actions)

local M = {}

local function tostring_safe(x) if x==nil then return "" end return tostring(x) end

local function norm_path(p)
  if not p then return nil end
  return (tostring(p):gsub("\\","/"))
end

local function push_unique(list, val, seen)
  if not val or val == "" then return end
  seen = seen or {}
  if not seen[val] then
    list[#list+1] = val
    seen[val] = true
  end
  return seen
end

-- Extract underscore command IDs used with NamedCommandLookup("...") / ('...')
-- This covers SWS/JS/ReaPack/custom action string IDs.
local function extract_action_strings_from_text(text)
  local out, seen = {}, {}
  if type(text) ~= "string" then return out end

  -- NamedCommandLookup("...") or NamedCommandLookup('...')
  for s in text:gmatch("NamedCommandLookup%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
    if s:sub(1,1) == "_" then
      seen = push_unique(out, s, seen) or seen
    end
  end

  -- Sometimes action string IDs appear as literals passed to Main_OnCommand directly (rare but possible)
  for s in text:gmatch("Main_OnCommand%s*%(%s*reaper%.NamedCommandLookup%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
    if s:sub(1,1) == "_" then
      seen = push_unique(out, s, seen) or seen
    end
  end

  return out
end

local _scan_cache = {} -- path -> {mtime=number or nil, actions={...}}

local function file_mtime(path)
  -- No reliable cross-platform mtime in pure Lua here; keep simple:
  return nil
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function scan_script_for_actions(abs_path)
  abs_path = norm_path(abs_path)
  if not abs_path then return {} end

  local cached = _scan_cache[abs_path]
  if cached then return cached.actions or {} end

  local text = read_file(abs_path)
  local actions = extract_action_strings_from_text(text or "")
  _scan_cache[abs_path] = { mtime = file_mtime(abs_path), actions = actions }
  return actions
end

-- Normalize various possible wrapper fields into item.actions
function M.normalize_actions(item)
  if type(item) ~= "table" then return item end

  local actions, seen = {}, {}

  local function add(v)
    if type(v) == "number" then v = tostring(v) end
    if type(v) == "string" then
      v = v:match("^%s*(.-)%s*$") or v
      if v ~= "" then seen = push_unique(actions, v, seen) or seen end
    end
  end

  -- Common field names across CSV/JSON wrappers
  add(item.action)
  add(item.cmd)
  add(item.command)
  add(item.command_id)
  add(item.commandId)
  add(item.action_id)
  add(item.actionId)

  if type(item.actions) == "table" then
    for _,v in ipairs(item.actions) do add(v) end
  elseif type(item.actions) == "string" then
    -- allow "a;b;c" or "a|b|c"
    for v in item.actions:gmatch("[^;|]+") do add(v) end
  end

  item.actions = actions
  item.action_strings = actions -- explicit alias for RequireRules
  return item
end

-- Enrich hub/wrapper items:
-- - normalize actions fields
-- - if script path exists, extract action string IDs used in script (NamedCommandLookup)
function M.enrich_item(item, opts)
  if type(item) ~= "table" then return item end
  opts = opts or {}

  M.normalize_actions(item)

  local p = item.path or item.script or item.script_path or item.file
  p = norm_path(p)

  -- Only auto-scan scripts if we can resolve a filesystem path
  if (item.kind == "script" or item.kind == "file" or item.kind == nil) and p and p:match("%.lua$") then
    local extra = scan_script_for_actions(p)
    if extra and #extra > 0 then
      local merged, seen = {}, {}
      -- existing first (so explicit fields win ordering)
      if type(item.actions) == "table" then
        for _,v in ipairs(item.actions) do seen = push_unique(merged, v, seen) or seen end
      end
      for _,v in ipairs(extra) do seen = push_unique(merged, v, seen) or seen end
      item.actions = merged
      item.action_strings = merged
      item._df95_actions_from_script = true
    end
  end

  return item
end

return M
