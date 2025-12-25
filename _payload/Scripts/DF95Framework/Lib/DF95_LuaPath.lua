-- DF95_LuaPath.lua
-- Zentraler Bootstrap für package.path in REAPER (Lua).
-- Ziel: require() zuverlässig machen für DF95Framework + IFLS.

local r = reaper
local M = {}

local function norm(s)
  return (s or ""):gsub("\\","/"):lower()
end

local function contains_path(haystack, needle)
  return norm(haystack):find(norm(needle), 1, true) ~= nil
end

local function add_to_package_path(pattern)
  if not contains_path(package.path, pattern) then
    package.path = package.path .. ";" .. pattern
    return true
  end
  return false
end

-- opts = { include_ifls=true/false, include_df95framework=true/false, include_lib=true/false }
function M.bootstrap(opts)
  opts = opts or {}
  if opts.include_ifls == nil then opts.include_ifls = true end
  if opts.include_df95framework == nil then opts.include_df95framework = true end
  if opts.include_lib == nil then opts.include_lib = true end

  local base = r.GetResourcePath():gsub("\\","/")
  local added = {}

  if opts.include_ifls then
    table.insert(added, add_to_package_path(base .. "/Scripts/IFLS/?.lua"))
    table.insert(added, add_to_package_path(base .. "/Scripts/IFLS/?/init.lua"))

    -- DF95/IFLS sub-root (V2) + legacy compatibility
    table.insert(added, add_to_package_path(base .. "/Scripts/IFLS/DF95/?.lua"))
    table.insert(added, add_to_package_path(base .. "/Scripts/IFLS/DF95/?/init.lua"))
    table.insert(added, add_to_package_path(base .. "/Scripts/IfeelLikeSnow/DF95/?.lua"))
    table.insert(added, add_to_package_path(base .. "/Scripts/IfeelLikeSnow/DF95/?/init.lua"))
  end

  if opts.include_df95framework then
    table.insert(added, add_to_package_path(base .. "/Scripts/DF95Framework/?.lua"))
    table.insert(added, add_to_package_path(base .. "/Scripts/DF95Framework/?/init.lua"))
  end

  if opts.include_lib then
    table.insert(added, add_to_package_path(base .. "/Scripts/DF95Framework/Lib/?.lua"))
    table.insert(added, add_to_package_path(base .. "/Scripts/DF95Framework/Lib/?/init.lua"))
  end

  local count = 0
  for _, v in ipairs(added) do if v then count = count + 1 end end
  return count
end

return M
