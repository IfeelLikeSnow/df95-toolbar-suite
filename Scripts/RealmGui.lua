-- RealmGui.lua
-- Compatibility shim: returns the REAPER ReaImGui API table when available.
-- This file is intended to be *required* by other scripts, not run directly.

local r = reaper
if not r then return nil end

-- ReaImGui functions live on the global 'reaper' table (e.g. reaper.ImGui_CreateContext)
if type(r.ImGui_CreateContext) ~= "function" then
  return nil
end

return r
