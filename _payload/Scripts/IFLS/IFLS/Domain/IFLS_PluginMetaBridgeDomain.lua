-- IFLS_PluginMetaBridgeDomain.lua
-- Bridge from IFLS to DF95_PluginMetaDomain (Threepo plugin meta)
-- Allows IFLS domains (ArtistFX, BeatControlCenter, KitBuilder) to query IDM groups.

local r = reaper
local M = {}

local df95_meta = nil

local function try_load_df95_meta()
  if df95_meta ~= nil then
    return df95_meta

local df95_flavors = nil

local function try_load_df95_flavors()
  if df95_flavors ~= nil then return df95_flavors end
  local res = r.GetResourcePath()
  local path = res .. "/Scripts/IFLS/DF95/DF95_PluginFlavors.lua"
  local ok, mod = pcall(dofile, path)
  if not ok or type(mod) ~= "table" then
    df95_flavors = false
    return nil
  end
  df95_flavors = mod
  return df95_flavors
end

  end

  local res = r.GetResourcePath()
  local path = res .. "/Scripts/IFLS/DF95/DF95_PluginMetaDomain.lua"
  local ok, mod = pcall(dofile, path)
  if not ok or type(mod) ~= "table" then
    df95_meta = false
  else
    df95_meta = mod
  end
  return df95_meta
end

function M.is_available()
  local m = try_load_df95_meta()
  return m and true or false
end

function M.get_all()
  local m = try_load_df95_meta()
  if not m or not m.get_all then return {} end
  return m.get_all()
end

function M.get_by_group(group)
  local m = try_load_df95_meta()
  if not m then return {} end
  if m.filter_by_group then
    return m.filter_by_group(group)
  end
  -- fallback: manual filter via get_all()
  local all = m.get_all and m.get_all() or {}
  local out = {}
  group = tostring(group or ""):lower()
  for name, meta in pairs(all) do
    local g = tostring(meta.idm_group or ""):lower()
    if g == group then
      out[#out+1] = meta
    end
  end
  return out
end

function M.get_by_category(cat)
  local m = try_load_df95_meta()
  if not m then return {} end
  if m.filter_by_category then
    return m.filter_by_category(cat)
  end
  local all = m.get_all and m.get_all() or {}
  local out = {}
  cat = tostring(cat or ""):lower()
  for name, meta in pairs(all) do
    local c = tostring(meta.category or ""):lower()
    if c == cat then
      out[#out+1] = meta
    end
  end
  return out
end

local function pick_random(list, seed)
  if not list or #list == 0 then return nil end
  if not seed then seed = os.time() end
  local idx = (seed % #list) + 1
  return list[idx]
end

-- Convenience: pick a random FX name from IDM group
function M.pick_name_from_group(group, seed)
  local list = M.get_by_group(group)
  if not list or #list == 0 then return nil end
  local meta = pick_random(list, seed)
  if not meta then return nil end
  -- meta.name is the FX Name as in DF95 dump
  return meta.name
end



----------------------------------------------------------------
-- Flavor-Bridge (Phase 83/84)
----------------------------------------------------------------

function M.get_flavors_for_plugin(name)
  local meta_mod = try_load_df95_meta()
  local flavor_mod = try_load_df95_flavors()
  if not meta_mod or not flavor_mod then return {} end
  local all = meta_mod.get_all and meta_mod.get_all() or meta_mod.PLUGIN_META or {}
  local meta = all[name]
  return flavor_mod.get_flavors(name, meta)
end

function M.filter_by_flavor(flavor)
  local meta_mod = try_load_df95_meta()
  local flavor_mod = try_load_df95_flavors()
  if not meta_mod or not flavor_mod then return {} end
  local all = meta_mod.get_all and meta_mod.get_all() or meta_mod.PLUGIN_META or {}
  return flavor_mod.filter_meta_by_flavor(all, flavor)
end

return M
