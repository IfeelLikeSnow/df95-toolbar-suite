-- IFLS_Diagnostics.lua
-- Compatibility shim: loads IFLS_Diagnostics from the IFLS package.

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

local resource = reaper and reaper.GetResourcePath and reaper.GetResourcePath() or ""
local here = debug.getinfo(1, "S").source
if here and here:sub(1,1) == "@" then here = here:sub(2) end

local candidates = {
  resource .. "/Scripts/IFLS/IFLS/Domain/IFLS_Diagnostics.lua",
  resource .. "/Scripts/IFLS/IFLS/Domain/IFLS_Diagnostics.lua",
}

for _, p in ipairs(candidates) do
  if p ~= here and file_exists(p) then
    return dofile(p)
  end
end

return nil
