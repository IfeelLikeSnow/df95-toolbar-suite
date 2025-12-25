
-- @description Validator 2.1 (Chains + Menus + Fallback Repair)
-- @version 2.1
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local cats = {"Master","Coloring","FXBus","Mic"}
local missing = {}
local function count(cat)
  local base = res..sep.."FXChains"..sep.."DF95"..sep..cat
  local n = 0; local i = 0
  while true do
    local fn = r.EnumerateFiles(base, i)
    if not fn then break end
    if fn:lower():match("%.rfxchain$") then n = n + 1 end
    i = i + 1
  end
  return n
end
for _,c in ipairs(cats) do
  if count(c)==0 then missing[#missing+1]=c end
end
if #missing>0 then
  r.ShowMessageBox("Fehlende Chain-Kategorien: "..table.concat(missing,", ").."\nBitte Fallback-Erstellung laufen lassen.","DF95 Validator 2.1",0)
else
  r.ShowConsoleMsg("[DF95] Validator 2.1: OK (alle Kategorien vorhanden)\n")
end
