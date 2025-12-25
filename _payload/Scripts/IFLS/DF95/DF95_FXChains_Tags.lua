-- DF95_FXChains_Tags.lua
-- Lightweight tag system for DF95 FXChains (FXBus / Coloring / Master)
-- Uses DF95_FXChains_Tags.json + DF95_ReadJSON.lua

local r = reaper
local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""

local read_json = dofile(base.."DF95_ReadJSON.lua")
local data = read_json(base.."DF95_FXChains_Tags.json") or {}

local M = {}

function M.get_tags(category, relpath)
  if not (category and relpath) then return nil end
  local cat = data[category]
  return cat and cat[relpath] or nil
end

-- returns short "idm, warm, safe" string for display
function M.get_tag_string(category, relpath, max_tags)
  local meta = M.get_tags(category, relpath)
  if not meta then return "" end
  local tags = meta.tags or {}
  max_tags = max_tags or 3
  local t = {}
  for i,tag in ipairs(tags) do
    if #t >= max_tags then break end
    table.insert(t, tag)
  end
  if meta.safe and not vim then
    -- ensure 'safe' appears if set
    local has_safe = false
    for _,tg in ipairs(t) do if tg=="safe" then has_safe=true break end end
    if not has_safe and (max_tags == nil or #t < max_tags) then
      table.insert(t, "safe")
    end
  end
  if #t == 0 then return "" end
  return table.concat(t, ", ")
end

return M
