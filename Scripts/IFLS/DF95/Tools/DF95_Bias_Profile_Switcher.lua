-- @description Bias Profile Switcher
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res..sep.."Data"..sep.."DF95"
local profiles = base..sep.."BiasProfiles"

local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function writeall(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s); f:close(); return true end

local opts,files={},{}; local i=0
while true do
  local fn = reaper.EnumerateFiles(profiles, i); if not fn then break end
  if fn:lower():match("%.json$") then opts[#opts+1]=fn; files[#files+1]=profiles..sep..fn end
  i=i+1
end
if #files==0 then reaper.ShowMessageBox("Keine Profile gefunden.","DF95 Bias Switcher",0) return end

local _,_,x,y = reaper.GetMousePosition(); gfx.init("DF95 Bias Switcher",1,1,0,x,y)
local sel = gfx.showmenu(table.concat(opts,"|")); gfx.quit(); if sel<=0 then return end

local raw = readall(files[sel]); if not raw then return end
writeall(base..sep.."DF95_ArtistBias.json", raw)
reaper.ShowMessageBox("Bias Profil geladen: "..opts[sel], "DF95 Bias Switcher", 0)
