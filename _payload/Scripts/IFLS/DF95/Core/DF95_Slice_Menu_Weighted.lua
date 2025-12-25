-- @description Slicing Menu – Weighted (Artist/Style Bias)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local data = res..sep.."Data"..sep.."DF95"
local preset_dirs = {
  res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Slicing"..sep.."Presets",
  res..sep.."Data"..sep.."DF95"..sep.."SlicingPresets"
}
local function readjson(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); if reaper.JSON_Decode then return reaper.JSON_Decode(d) end end
local bias = readjson(data..sep.."DF95_ArtistBias.json") or {weights={}}
local function list_presets() local t={}; for _,dir in ipairs(preset_dirs) do local j=0; while true do local fn=reaper.EnumerateFiles(dir,j); if not fn then break end; if fn:lower():match("%.lua$") or fn:lower():match("%.rcfg$") then t[#t+1]={name=fn,path=dir..sep..fn} end; j=j+1 end end; table.sort(t,function(a,b) return a.name<b.name end); return t end
local function infer_tags(nm) local n=nm:lower(); local tags={}; local function add(t) tags[#tags+1]=t end; if n:find("autechre") then add("artist:autechre") end; if n:find("aphex") then add("artist:aphex") end; if n:find("boc") or n:find("boards") then add("artist:boc") end; if n:find("glitch") then add("style:glitch") end; if n:find("idm") then add("style:idm") end; if n:find("euclid") then add("style:euclid") end; return tags end
local function weight(tags) local w=1; for _,t in ipairs(tags) do w=w+(bias.weights[t] or 0) end; return math.max(1,w) end
local function showmenu(items) local labels={">Random","Random (weighted)","Random (neutral)","<|>Presets"}; for _,e in ipairs(items) do labels[#labels+1]=e.name end; local _,_,x,y=reaper.GetMousePosition(); gfx.init("DF95 Slice",1,1,0,x,y); local s=gfx.showmenu(table.concat(labels,"|")); gfx.quit(); return s end
local function run() local items=list_presets(); if #items==0 then reaper.ShowMessageBox("Keine Slicing-Presets gefunden.","DF95 Slice",0) return end; for _,e in ipairs(items) do e.tags=infer_tags(e.name); e.w=weight(e.tags) end; local choice=showmenu(items); if choice<=0 then return end; local sel; if choice==2 then local bag={}; for _,e in ipairs(items) do for i=1,e.w do bag[#bag+1]=e end end; sel=bag[math.random(1,#bag)] elseif choice==3 then sel=items[math.random(1,#items)] else sel=items[choice-4] end; if not sel then return end; if sel.path:lower():match("%.lua$") then dofile(sel.path) else reaper.ShowMessageBox("RCFG-Preset ausgewählt:\n"..sel.name.."\nImport-Action ggf. separat mappen.","DF95 Slice",0) end end
run()
