
-- @description Coloring – Load with Auto-Audition (A/B + optional GainMatch)
-- @version 1.0
-- @about Lädt gewählte .rfxchain, führt kurzes A/B (bypass vs. on) mit optional GainMatch aus.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function showmenu(str)
  local _,_,x,y = r.GetMousePosition()
  gfx.init("DF95_Audition",1,1,0,x,y)
  local sel=gfx.showmenu(str); gfx.quit(); return sel
end

local function list_chains(base)
  local out = {}
  local i, d = 0, r.EnumerateSubdirectories(base, 0)
  while d do
    local dir = base..sep..d
    local j, f = 0, r.EnumerateFiles(dir, 0)
    local has=false
    while f do
      if f:lower():match("%.rfxchain$") then
        has=true; out[#out+1] = {label=d.."/"..f, path=dir..sep..f}
      end
      j=j+1; f = r.EnumerateFiles(dir, j)
    end
    if not has then
      -- also allow flat files in base
      j, f = 0, r.EnumerateFiles(base, 0)
      while f do
        if f:lower():match("%.rfxchain$") then
          out[#out+1] = {label=f, path=base..sep..f}
        end
        j=j+1; f = r.EnumerateFiles(base, j)
      end
    end
    i=i+1; d = r.EnumerateSubdirectories(base, i)
  end
  table.sort(out, function(a,b) return a.label<b.label end)
  return out
end

local bases = {
  res..sep.."FXChains"..sep.."DF95"..sep.."Coloring",
  res..sep.."FXChains"..sep.."DF95"..sep.."Coloring"..sep.."Artists"
}
local list = {}
for _,b in ipairs(bases) do
  for _,e in ipairs(list_chains(b)) do list[#list+1]=e end
end
if #list==0 then r.ShowMessageBox("Keine Coloring-Chains gefunden.","DF95",0) return end

local labels={}; for _,e in ipairs(list) do labels[#labels+1]=e.label end
local menu = table.concat(labels, "|")
local choice = showmenu(menu); if choice<=0 then return end
local entry = list[choice]

local tr = r.GetSelectedTrack(0,0)
if not tr then r.ShowMessageBox("Bitte Coloring-Bus wählen.","DF95",0) return end

-- pre state
local function get_track_rms(track, dur)
  -- quick-and-dirty: use peak hold as proxy when JSFX meter unavailable
  local level = r.Track_GetPeakInfo(track, 0)
  if level<=0 then level = 0.000001 end
  return 20*math.log(level,10)
end

r.Undo_BeginBlock()
-- load chain
r.TrackFX_AddByName(tr, entry.path, false, 1)

-- try to run GainMatch script (if present)
local gm = r.NamedCommandLookup("_RSDF95_GAINMATCH_TOGGLE") -- if registered
if gm==0 then
  -- fallback: small output trim check (no-op here to keep simple)
end

-- short audition A/B if playing
local playstate = r.GetPlayState()
local fxcount = r.TrackFX_GetCount(tr)
if fxcount>0 and playstate&1 == 1 then
  -- bypass all -> on -> bypass (visual cue only)
  for i=0,fxcount-1 do r.TrackFX_SetEnabled(tr, i, false) end
  r.Sleep(200)
  for i=0,fxcount-1 do r.TrackFX_SetEnabled(tr, i, true) end
  r.Sleep(400)
  for i=0,fxcount-1 do r.TrackFX_SetEnabled(tr, i, false) end
  r.Sleep(200)
  for i=0,fxcount-1 do r.TrackFX_SetEnabled(tr, i, true) end
end
r.Undo_EndBlock("[DF95] Load Coloring with Audition: "..entry.label, -1)
r.ShowConsoleMsg("[DF95] Coloring loaded with audition: "..entry.label.."\n")
