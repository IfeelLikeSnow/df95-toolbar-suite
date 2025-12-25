
-- @description Humanize Dropdown (Levels + Artist/Substyles)
-- @version 1.1
local r = reaper
local function showmenu(str)
  local _,_,x,y = r.GetMousePosition()
  gfx.init("DF95_Humanize",1,1,0,x,y)
  local sel = gfx.showmenu(str); gfx.quit(); return sel
end

local function read_json(p)
  local f=io.open(p,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
  return nil
end

local res = reaper.GetResourcePath()
local prof = read_json(res.."/Data/DF95/Humanize_Profiles_v1.json") or {}
local levels = {"Light","Medium","Heavy"}

local parts = {">Levels"}
for _,L in ipairs(levels) do parts[#parts+1]=L end
parts[#parts+1]="<|>Artists/Substyles"
local keys = {}
if prof.artists then for k,_ in pairs(prof.artists) do keys[#keys+1]=k end end
table.sort(keys)
for _,k in ipairs(keys) do parts[#parts+1]=k end
parts[#parts+1]="<|>Presets|IDM_Tight|IDM_ClassicGroove|Generative_Loose|Glitch_Microstagger|BoC_TapeLilt|<|Apply Now"
local menu = table.concat(parts,"|")

local choice = showmenu(menu); if choice<=0 then return end
local idx, label = 0, nil
for token in menu:gmatch("[^|]+") do
  if not (token:sub(1,1)==">" or token:sub(-1)=="<") then
    idx = idx + 1; if idx==choice then label = token break end
  end
end
if not label then return end

if label=="Apply Now" then
  dofile((res.."/Scripts/IFLS/DF95/DF95_Humanize_Apply.lua"):gsub("\\","/"))
  return
end

if label=="Light" or label=="Medium" or label=="Heavy" then
  reaper.SetProjExtState(0,"DF95_HUMANIZE","LEVEL", label)
  reaper.SetProjExtState(0,"DF95_HUMANIZE","ARTIST_PROFILE", "")
  reaper.ShowConsoleMsg("[DF95] Humanize Level gesetzt: "..label.."\n")
else
  reaper.SetProjExtState(0,"DF95_HUMANIZE","ARTIST_PROFILE", label)
  reaper.ShowConsoleMsg("[DF95] Humanize Artist-Profil gesetzt: "..label.."\n")
end


-- handle preset selection
local presets = {IDM_Tight=true, IDM_ClassicGroove=true, Generative_Loose=true, Glitch_Microstagger=true, BoC_TapeLilt=true}
if presets[label] then
  reaper.SetProjExtState(0,"DF95_HUMANIZE","PRESET_NAME", label)
  dofile((reaper.GetResourcePath().."/Scripts/IFLS/DF95/DF95_Humanize_Preset_Apply.lua"):gsub("\\","/"))
  return
end
