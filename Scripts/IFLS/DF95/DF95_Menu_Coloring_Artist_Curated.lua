
-- @description Coloring – Artist Chains (Curated)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function showmenu(str)
  local _,_,x,y = r.GetMousePosition()
  gfx.init("DF95_ArtistChains",1,1,0,x,y)
  local sel=gfx.showmenu(str); gfx.quit(); return sel
end
local function read_json(p)
  local f=io.open(p,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
end

local cfg = read_json(res..sep.."Data"..sep.."DF95"..sep.."Coloring_ArtistChains_curated.json") or {}
local parts, map = {}, {}
for artist,items in pairs(cfg) do
  table.insert(parts, ">"..artist)
  for _,it in ipairs(items) do
    table.insert(parts, it.label.."##"..artist.."::"..it.chain)
  end
  table.insert(parts, "<|")
end
local menu = table.concat(parts,"|")
if menu=="" then reaper.ShowMessageBox("Keine kuratierten Artist Chains gefunden.","DF95",0) return end

local choice = showmenu(menu); if choice<=0 then return end

local idx, label = 0, nil
for token in menu:gmatch("[^|]+") do
  if not (token:sub(1,1)==">" or token:sub(-1)=="<") then
    idx = idx + 1; if idx==choice then label = token break end
  end
end
if not label then return end

local artist, chain = label:match("##(.+)::(.+)$")
local tr = reaper.GetSelectedTrack(0,0)
if not tr then reaper.ShowMessageBox("Bitte einen Coloring-Bus wählen.","DF95",0) return end

local chain_path = table.concat({res,"FXChains","DF95","Coloring","Artists",artist,chain}, sep)
reaper.TrackFX_AddByName(tr, chain_path, false, 1)
reaper.SetProjExtState(0,"DF95_COLORING","ARTIST", artist)
-- optional Bias-Apply
local bias = (res.."/Scripts/IFLS/DF95/DF95_Coloring_ArtistBias_Apply.lua"):gsub("\\","/")
local f=io.open(bias,"rb"); if f then f:close(); dofile(bias) end
reaper.ShowConsoleMsg(string.format("[DF95] Artist Chain geladen: %s / %s\n", artist, chain))
