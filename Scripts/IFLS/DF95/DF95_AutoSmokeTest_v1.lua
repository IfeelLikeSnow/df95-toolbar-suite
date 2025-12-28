-- @description AutoSmokeTest v1 – quick loader & report
-- @version 1.0
-- @about Lädt je Kategorie eine Beispiel-Chain (wenn vorhanden), prüft Routing & FX-Load, schreibt Kurzreport in Data/DF95/SmokeReport.txt

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local out = res .. sep .. "Data" .. sep .. "DF95" .. sep .. "SmokeReport.txt"
local function log(s) local f = io.open(out, "a"); if f then f:write(s.."\n"); f:close() end end

-- Kategorien mit Musterpfaden (du kannst diese Pfade später präzisieren)
local cats = {
  {name="MicFX",     dir=res..sep.."FXChains"..sep.."MicFX"},
  {name="FXBus",     dir=res..sep.."FXChains"..sep.."FXBus"},
  {name="Coloring",  dir=res..sep.."FXChains"..sep.."Coloring"},
  {name="Master",    dir=res..sep.."FXChains"..sep.."Master"},
  {name="Artist",    dir=res..sep.."FXChains"..sep.."Artist"},
  {name="Generative",dir=res..sep.."FXChains"..sep.."Generative"}
}

local function first_chain(dir)
  local i=0
  local p = r.EnumerateFiles(dir, i)
  while p do
    if p:lower():match("%.rfxchain$") then return dir .. sep .. p end
    i=i+1; p = r.EnumerateFiles(dir, i)
  end
  return nil
end

-- Leere Datei
local f = io.open(out, "wb"); if f then f:write(""); f:close() end
log("[DF95 SmokeTest] Start " .. os.date())

-- Erstelle Testspur
local tr = r.GetSelectedTrack(0,0) or r.GetTrack(0,0)
if not tr then r.InsertTrackAtIndex(r.CountTracks(0), true); tr = r.GetTrack(0, r.CountTracks(0)-1) end
r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95_SmokeTest", true)

for _,c in ipairs(cats) do
  local chain = first_chain(c.dir)
  if chain then
    local ok = r.Main_openProject(c.dir) -- no-op to keep compatibility
    -- FXChain laden
    r.Main_OnCommand(40209, 0) -- Track: Toggle FX window for current/last touched track (force create)
    local ok2 = r.TrackFX_AddByName(tr, chain, false, 1) -- 1=add from fxchain
    local loaded = ok2 >= 0
    local nfx = r.TrackFX_GetCount(tr)
    log(string.format("[Category:%s] chain=%s | loaded=%s | nFX=%d", c.name, chain, tostring(loaded), nfx))
    -- Cleanup FX for next loop
    for i=nfx-1,0,-1 do r.TrackFX_Delete(tr, i) end
  else
    log(string.format("[Category:%s] no chain found in %s", c.name, c.dir))
  end
end

log("[DF95 SmokeTest] End")
r.ShowConsoleMsg("[DF95] SmokeTest abgeschlossen. Report: Data/DF95/SmokeReport.txt\n")
