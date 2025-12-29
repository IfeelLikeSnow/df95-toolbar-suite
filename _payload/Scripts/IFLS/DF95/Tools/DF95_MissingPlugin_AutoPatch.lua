-- @description Missing-Plugin Auto-Patch (write substitutions into .rfxchain)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res..sep.."FXChains"..sep.."DF95"
local submap_fn = res..sep.."Data"..sep.."DF95"..sep.."DF95_PluginSubstitutions.json"
local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function writeall(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s); f:close(); return true end
local function exists_fx(name) return (reaper.TrackFX_AddByName(0, name, false, 1) or -1) >= 0 end
local subs = {}; if reaper.JSON_Decode then subs = reaper.JSON_Decode(readall(submap_fn) or "{}") or {} end
local function best_available(orig) local list=subs[orig] or {}; for _,cand in ipairs(list) do if exists_fx("VST: "..cand) or exists_fx("JS: "..cand) then return cand end end end
local function list_chains(root) local t,stack={}, {root}; while #stack>0 do local dir=table.remove(stack); local i=0; while true do local d=reaper.EnumerateSubdirectories(dir,i); if not d then break end; stack[#stack+1]=dir..sep..d; i=i+1 end; local j=0; while true do local fn=reaper.EnumerateFiles(dir,j); if not fn then break end; if fn:lower():match("%.rfxchain$") then t[#t+1]=dir..sep..fn end; j=j+1 end end; table.sort(t); return t end
local function patch_file(fp) local raw=readall(fp) or ""; local changed=false; local out = raw:gsub("VST%s*:%s*([^\r\n]+)", function(name) local nm=name:gsub("^%s+",""):gsub("%s+$",""); if exists_fx("VST: "..nm) or exists_fx("JS: "..nm) then return "VST: "..nm end; local sub=best_available(nm); if sub then changed=true; return "VST: "..sub end; return "VST: "..nm end); if changed and writeall(fp,out) then reaper.ShowConsoleMsg("[DF95] Patched: "..fp:gsub(res..sep,"").."\n") end end
reaper.ShowConsoleMsg("[DF95] Auto-Patch fehlender Plugins…\n"); for _,fp in ipairs(list_chains(base)) do patch_file(fp) end; reaper.ShowConsoleMsg("[DF95] Fertig.\n")
