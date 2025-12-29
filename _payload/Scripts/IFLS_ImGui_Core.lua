-- IFLS_ImGui_Core.lua
-- Compatibility shim: loads the real IFLS_ImGui_Core from the IFLS package location.
-- Intended to be required/dofiled by scripts that expect IFLS_ImGui_Core.lua in /Scripts.

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

local resource = reaper and reaper.GetResourcePath and reaper.GetResourcePath() or ""
local here = debug.getinfo(1, "S").source
if here and here:sub(1,1) == "@" then here = here:sub(2) end

local candidates = {
  resource .. "/Scripts/IFLS/IFLS/Core/IFLS_ImGui_Core.lua",
  resource .. "/Scripts/IFLS/IFLS/Core/IFLS_ImGui_Core.lua", -- same, explicit
}

for _, p in ipairs(candidates) do
  if p ~= here and file_exists(p) then
    return dofile(p)
  end
end

-- Last resort: try to locate any IFLS_ImGui_Core.lua under Scripts/IFLS
local function find_first(dir, target, depth)
  if depth <= 0 then return nil end
  local i = 0
  while true do
    local f = reaper.EnumerateFiles(dir, i)
    if not f then break end
    if f == target then return dir .. "/" .. f end
    i = i + 1
  end
  i = 0
  while true do
    local sub = reaper.EnumerateSubdirectories(dir, i)
    if not sub then break end
    local found = find_first(dir .. "/" .. sub, target, depth - 1)
    if found then return found end
    i = i + 1
  end
  return nil
end

if reaper and reaper.EnumerateSubdirectories then
  local found = find_first(resource .. "/Scripts/IFLS", "IFLS_ImGui_Core.lua", 4)
  if found and found ~= here and file_exists(found) then
    return dofile(found)
  end
end

reaper.ShowMessageBox(
  "IFLS_ImGui_Core.lua shim couldn't locate the real core file.\n\n" ..
  "Expected: " .. (resource .. "/Scripts/IFLS/IFLS/Core/IFLS_ImGui_Core.lua") .. "\n\n" ..
  "Fix: Install/copy the DF95/IFLS repo so that folder exists.",
  "IFLS_ImGui_Core missing",
  0
)

return nil
