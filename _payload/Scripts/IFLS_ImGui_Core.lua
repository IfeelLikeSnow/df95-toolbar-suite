(
echo -- Root shim: IFLS_ImGui_Core.lua
echo local ok, mod = pcall(require, "IFLS.IFLS.Core.IFLS_ImGui_Core")
echo if ok then return mod end
echo return dofile(reaper.GetResourcePath() .. "\\Scripts\\IFLS\\IFLS\\Core\\IFLS_ImGui_Core.lua")
) > IFLS_ImGui_Core.lua
