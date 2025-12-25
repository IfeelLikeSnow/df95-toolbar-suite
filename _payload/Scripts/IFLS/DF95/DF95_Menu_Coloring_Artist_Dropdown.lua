
-- @description Coloring – Artist Dropdown (Bias + optional chain call)
-- @version 1.0
-- @about Popup-Menü mit Artists/Substyles aus Data/DF95/Coloring_ArtistBias_v1.json; ruft Bias-Apply auf.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function showmenu(str)
  local _, _, x, y = r.GetMousePosition()
  gfx.init("DF95_ColoringArtist", 1, 1, 0, x, y)
  local sel = gfx.showmenu(str); gfx.quit(); return sel
end

local function read_json(path)
  local f=io.open(path,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
  return nil
end

local cfg = read_json(res..sep.."Data"..sep.."DF95"..sep.."Coloring_ArtistBias_v1.json") or {}
-- group by main artist (split on '_' for substyles)
local groups = {}
for k,_ in pairs(cfg) do
  local main, sub = k:match("^([^_]+)_(.+)$")
  if not main then main = k; sub = "_default" end
  groups[main] = groups[main] or {}
  table.insert(groups[main], {name=k, sub=sub})
end
-- build menu
local spec = {}
for main,subs in pairs(groups) do
  table.sort(subs, function(a,b) return a.sub < b.sub end)
  if #subs == 1 and subs[1].sub == "_default" then
    table.insert(spec, main)
  else
    table.insert(spec, ">"..main)
    for _,s in ipairs(subs) do
      local label = (s.sub == "_default") and main or s.sub
      table.insert(spec, label .. "##" .. s.name)
    end
    table.insert(spec, "<")
  end
end
table.sort(spec, function(a,b) return a:gsub("[><]","") < b:gsub("[><]","") end)
local menu = table.concat(spec, "|")

-- Help on first run
local _, seen = r.GetProjExtState(0,"DF95_UI","ARTIST_HELP_SEEN")
if seen ~= "1" then
  r.ShowConsoleMsg([[
[DF95] Coloring Artist Dropdown – Hilfe
• Wähle einen Artist/Substyle → Bias wird angewendet (ReaEQ Tilt + AO/AW Drive-Push).
• Auswahl wird in ExtState DF95_COLORING/ARTIST gespeichert.
]])
  r.SetProjExtState(0,"DF95_UI","ARTIST_HELP_SEEN","1")
end

local choice = showmenu(menu); if choice<=0 then return end

-- resolve label
local index, label = 0, nil
for token in menu:gmatch("[^|]+") do
  if not (token:sub(1,1)==">" or token:sub(-1)=="<") then
    index = index + 1
    if index == choice then label = token break end
  end
end
if not label then return end

-- substyle token might contain "##fullkey"
local fullkey = label:match("##(.+)$") or label

-- set artist and apply bias
reaper.SetProjExtState(0, "DF95_COLORING", "ARTIST", fullkey)
dofile((res.."/Scripts/IFLS/DF95/DF95_Coloring_ArtistBias_Apply.lua"):gsub("\\","/"))
