-- DF95_RequireRules.lua
-- Action-based dependency inference (NamedCommandLookup string IDs).
-- This file is designed to be required by DF95_Hubs.lua at runtime.
--
-- Supported dependencies:
--   sws          : SWS Extension (e.g. _SWS_* , _S&M_* )
--   js_reascriptapi : js_ReaScriptAPI (e.g. _JS_* )
--   reapack      : ReaPack extension (e.g. _REAPACK_* )
--   reaimgui     : ReaImGui (typically detected via API usage, not actions)

local M = {}

-- Normalize to lower-case dependency keys used throughout DF95
local DEP_KEYS = {
  sws = "sws",
  js = "js_reascriptapi",
  reapack = "reapack",
  reaimgui = "reaimgui",
}

-- Detect dependency from a single action string ID (string command ID)
-- Examples:
--   "_SWS_ABOUT" => sws
--   "_S&M_CYCLEACTION_131" => sws
--   "_JS_Window_Find" => js_reascriptapi (commonly _JS_* actions)
--   "_REAPACK_BROWSE" => reapack
function M.infer_from_action_string(action_str)
  if type(action_str) ~= "string" then return nil end
  local s = action_str
  -- Trim whitespace
  s = s:match("^%s*(.-)%s*$")
  if s == "" then return nil end

  -- Only string IDs (portable) start with "_"
  if s:sub(1,1) ~= "_" then return nil end

  local up = s:upper()

  if up:find("^_SWS") or up:find("^_S&M") then
    return DEP_KEYS.sws
  end

  if up:find("^_JS_") then
    return DEP_KEYS.js
  end

  if up:find("^_REAPACK") then
    return DEP_KEYS.reapack
  end

  -- Many custom actions or scripts also start with "_" but are not extensions.
  -- We don't infer anything else here.
  return nil
end

-- Infer dependencies from a list of action strings.
-- Returns a set-like table: { sws=true, js_reascriptapi=true, ... }
function M.infer_from_action_list(action_list)
  local out = {}
  if type(action_list) ~= "table" then return out end
  for _, a in ipairs(action_list) do
    local dep = M.infer_from_action_string(a)
    if dep then out[dep] = true end
  end
  return out
end

-- Merge inferred requires into item.requires (array of strings), without duplicates.
function M.merge_requires(item, inferred_set)
  if type(item) ~= "table" then return end
  if type(inferred_set) ~= "table" then return end

  -- Build existing set
  local set = {}
  if type(item.requires) == "table" then
    for _, dep in ipairs(item.requires) do
      if type(dep) == "string" then
        set[dep] = true
      end
    end
  else
    item.requires = {}
  end

  for dep, v in pairs(inferred_set) do
    if v and not set[dep] then
      table.insert(item.requires, dep)
      set[dep] = true
    end
  end
end

-- Convenience: If item has action string fields, infer and merge.
-- Supported fields:
--   item.action   (string)   -- NamedCommandLookup string ID
--   item.command  (string)
--   item.actions  (table)    -- list of string IDs
function M.apply_action_inference(item)
  if type(item) ~= "table" then return end

  local inferred = {}

  if type(item.action) == "string" then
    local dep = M.infer_from_action_string(item.action)
    if dep then inferred[dep] = true end
  end

  if type(item.command) == "string" then
    local dep = M.infer_from_action_string(item.command)
    if dep then inferred[dep] = true end
  end

  if type(item.actions) == "table" then
    local set2 = M.infer_from_action_list(item.actions)
    for k,v in pairs(set2) do inferred[k] = v end
  end

  M.merge_requires(item, inferred)
end

return M
