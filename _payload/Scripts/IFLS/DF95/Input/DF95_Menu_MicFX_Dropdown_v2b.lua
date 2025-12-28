
-- @description Dynamic Chain Menu v2b (Index + Weighted Random + Tooltips)
-- @version 2.1
-- @param cat string Category ("Master","Coloring","FXBus","Mic")
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function readjson(p)
  local f = io.open(p,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close()
  if r.JSON_Decode then return r.JSON_Decode(d) end
end
local index = readjson(res..sep.."Data"..sep.."DF95"..sep.."DF95_ChainIndex.json")
local function filter_cat(cat)
  local t = {}
  if type(index)~="table" then return t end
  for _,e in ipairs(index) do if e.category==cat then t[#t+1]=e end end
  table.sort(t, function(a,b) return (a.name or "") < (b.name or "") end)
  return t
end
local function menu(str) local _,_,x,y=r.GetMousePosition(); gfx.init("DF95_Menu",1,1,0,x,y); local s=gfx.showmenu(str); gfx.quit(); return s end

local function readjson2(p)
  local f = io.open(p,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
end
local bias = readjson2(res..sep.."Data"..sep.."DF95"..sep.."DF95_ArtistBias.json") or {weights={}, random_profile={musical=0.8,gritty=0.15,extreme=0.05}}
local function weight_for(e)
  local w = 1
  if e.tags then
    for _,t in ipairs(e.tags) do w = w + (bias.weights[t] or 0) end
  end
  return math.max(1,w)
end
local function weighted_random(list)
  local bag = {}
  math.randomseed(os.time())
  for _,e in ipairs(list) do local w = weight_for(e); for i=1,w do bag[#bag+1]=e end end
  if #bag==0 then return nil end
  return bag[math.random(1,#bag)]
end

local function run(cat)
  local items = filter_cat(cat)
  if #items==0 then
    r.ShowConsoleMsg(("[DF95] Keine Index-Einträge für Kategorie: %s\n"):format(cat))
    return
  end
  local labels = {}
  labels[#labels+1] = ">Random"
  labels[#labels+1] = "Random (weighted)"
  labels[#labels+1] = "Random (neutral)"
  labels[#labels+1] = "<|>Chains"
  for _,e in ipairs(items) do labels[#labels+1] = e.name end
  local choice = menu(table.concat(labels,"|"))
  if choice<=0 then return end
  local sel
  if choice==2 then sel = weighted_random(items)
  elseif choice==3 then sel = items[math.random(1,#items)]
  else
    local idx = choice - 4
    sel = items[idx]
  end
  if not sel then return end
  r.ShowConsoleMsg(("[DF95] Load %s  [%s]\n"):format(sel.name, sel.relpath))
  local fn = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Core"..sep.."DF95_ChainLoader_WithSubstitutions.lua"
  local f = loadfile(fn); if not f then r.ShowConsoleMsg("[DF95] Loader nicht gefunden.\n"); return end
  local loader = f()
  loader(sel.relpath)
end

return run ...
