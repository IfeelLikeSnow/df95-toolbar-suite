-- @description LoopBuilder2 (Design Wrapper)
-- @version 1.0
-- @author DF95
-- @about
--   Wrapper, der DF95_LoopBuilder2.lua aus dem DF95-Hauptordner lädt.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local path = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_LoopBuilder2.lua"):gsub("\\","/")

local ok, err = pcall(dofile, path)
if not ok then
  r.ShowMessageBox("Fehler beim Laden von DF95_LoopBuilder2:\n"..tostring(err).."\nPfad: "..path, "DF95 LoopBuilder2", 0)
end
