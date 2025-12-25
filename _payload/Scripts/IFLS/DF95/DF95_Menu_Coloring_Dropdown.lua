
-- @description Coloring Chains Dropdown (Auto + Artists)
-- @version 1.1
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function showmenu(str)
  local _,_,x,y = r.GetMousePosition()
  gfx.init("DF95_Coloring",1,1,0,x,y)
  local sel=gfx.showmenu(str); gfx.quit(); return sel
end

local function list_dirs(base)
  local t,i={},0
  local d=r.EnumerateSubdirectories(base,i)
  while d do t[#t+1]=base..sep..d; i=i+1; d=r.EnumerateSubdirectories(base,i) end
  return t
end
local function list_chains(dir)
  local out,i={},0
  local f=r.EnumerateFiles(dir,i)
  while f do if f:lower():match("%.rfxchain$") then out[#out+1]={name=f,path=dir..sep..f} end
    i=i+1; f=r.EnumerateFiles(dir,i) end
  table.sort(out,function(a,b) return a.name<b.name end)
  return out
end

local roots = {
  res..sep.."FXChains"..sep.."DF95"..sep.."Coloring",
  res..sep.."FXChains"..sep.."DF95_Coloring",
  res..sep.."FXChains"..sep.."Coloring"
}

local cats, artists = {}, {}
for _,root in ipairs(roots) do
  for _,d in ipairs(list_dirs(root)) do
    local cname = d:match("([^"..sep.."]+)$") or d
    if cname:lower()=="artists" then
      artists[cname] = {dir=d, chains=list_chains(d)}
      for _,sub in ipairs(list_dirs(d)) do
        local aname = sub:match("([^"..sep.."]+)$") or sub
        artists[aname] = {dir=sub, chains=list_chains(sub)}
      end
    else
      cats[cname] = {dir=d, chains=list_chains(d)}
    end
  end
end

local parts = {}
if next(artists) then
  parts[#parts+1] = ">Artists"
  for aname,info in pairs(artists) do
    if #info.chains>0 then
      parts[#parts+1] = ">"..aname
      for _,c in ipairs(info.chains) do parts[#parts+1]=c.name.."##ART:"..aname end
      parts[#parts+1] = "<"
    end
  end
  parts[#parts+1] = "<|"
end
for cname,info in pairs(cats) do
  if #info.chains>0 then
    parts[#parts+1] = ">"..cname
    for _,c in ipairs(info.chains) do parts[#parts+1]=c.name end
    parts[#parts+1] = "<|"
  end
end
local menu = table.concat(parts,"|")
if menu=="" then reaper.ShowMessageBox("Keine Coloring-Chains gefunden.","DF95 Coloring",0) return end

local choice = showmenu(menu); if choice<=0 then return end
local idx,label = 0,nil
for token in menu:gmatch("[^|]+") do
  if not (token:sub(1,1)==">" or token:sub(-1)=="<") then
    idx = idx + 1; if idx==choice then label = token break end
  end
end
if not label then return end

local artist_ctx = label:match("##ART:(.+)$")
local clean = label:gsub("##ART:.+$","")

local tr = reaper.GetSelectedTrack(0,0)
if not tr then reaper.ShowMessageBox("Bitte einen Coloring-Bus wählen.","DF95",0) return end

local function load_from(map, name)
  for _,info in pairs(map) do
    for _,c in ipairs(info.chains or {}) do
      if c.name == name then
        reaper.TrackFX_AddByName(tr, c.path, false, 1)
        return true
      end
    end
  end
end

local ok = load_from(artists, clean) or load_from(cats, clean)
if ok then
  if artist_ctx and artist_ctx~="" then
    reaper.SetProjExtState(0,"DF95_COLORING","ARTIST", artist_ctx)
    local bias = (res.."/Scripts/IFLS/DF95/DF95_Coloring_ArtistBias_Apply.lua"):gsub("\\","/")
    local f=io.open(bias,"rb"); if f then f:close(); dofile(bias) end
  end
  reaper.ShowConsoleMsg(string.format("[DF95] Coloring preset geladen: %s\n", clean))
else
  reaper.ShowMessageBox("Preset nicht gefunden: "..clean, "DF95", 0)
end
