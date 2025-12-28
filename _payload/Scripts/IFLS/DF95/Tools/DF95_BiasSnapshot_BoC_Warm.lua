-- @description Bias Snapshot – BoC Warm
-- @version 1.0
-- @about Applies BoC_Warm.json into DF95_ArtistBias.json
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res..sep.."Data"..sep.."DF95"
local fn = base..sep.."BiasProfiles"..sep.."BoC_Warm.json"
local out = base..sep.."DF95_ArtistBias.json"
local f=io.open(fn,"rb"); if not f then r.ShowMessageBox("Bias-Profil nicht gefunden: "..fn,"DF95",0) return end
local d=f:read("*all"); f:close()
local g=io.open(out,"wb"); if not g then r.ShowMessageBox("Kann ArtistBias.json nicht schreiben.","DF95",0) return end
g:write(d); g:close()
r.ShowMessageBox("Bias-Profil geladen: BoC Warm","DF95",0)
