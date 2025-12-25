(
echo -- Root shim: IFLS_Diagnostics.lua
echo local ok, mod = pcall(require, "IFLS.IFLS.Domain.IFLS_Diagnostics")
echo if ok then return mod end
echo return dofile(reaper.GetResourcePath() .. "\\Scripts\\IFLS\\IFLS\\Domain\\IFLS_Diagnostics.lua")
) > IFLS_Diagnostics.lua
