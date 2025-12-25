-- IFLS_ExtState.lua
local M = {}
local r = reaper

local function tostr(v)
  if v == nil then return "" end
  return tostring(v)
end

function M.get(ns, key, default)
  local v = r.GetExtState(ns, key)
  if not v or v == "" then return default end
  return v
end

function M.set(ns, key, value, persist)
  r.SetExtState(ns, key, tostr(value), persist ~= false)
end

function M.get_proj(ns, key, default, proj)
  proj = proj or 0
  local _, v = r.GetProjExtState(proj, ns, key)
  if not v or v == "" then return default end
  return v
end

function M.set_proj(ns, key, value, proj)
  proj = proj or 0
  r.SetProjExtState(proj, ns, key, tostr(value))
end

function M.get_proj_number(ns, key, default, proj)
  local v = M.get_proj(ns, key, nil, proj)
  if not v or v == "" then return default end
  local n = tonumber(v)
  if n == nil then return default end
  return n
end

function M.set_proj_number(ns, key, value, proj)
  if value == nil then
    M.set_proj(ns, key, "", proj)
  else
    M.set_proj(ns, key, tostring(value), proj)
  end
end

return M
