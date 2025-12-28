-- @description META Bulk Wizard (rule based)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res..sep.."FXChains"..sep.."DF95"
local rules = {
  { pattern="/artists/boc/", set={artist="boc", color="warm", lufs_target="-14"} },
  { pattern="/artists/autechre/", set={artist="autechre", style="glitch"} },
  { pattern="/coloring/warm/", set={color="warm"} },
  { pattern="/coloring/clean/", set={color="clean"} },
}
local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function writeall(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s); f:close(); return true end
local function list_chains(root) local t,stack={}, {root}; while #stack>0 do local dir=table.remove(stack); local i=0; while true do local d=reaper.EnumerateSubdirectories(dir,i); if not d then break end; stack[#stack+1]=dir..sep..d; i=i+1 end; local j=0; while true do local fn=reaper.EnumerateFiles(dir,j); if not fn then break end; if fn:lower():match("%.rfxchain$") then t[#t+1]=dir..sep..fn end; j=j+1 end end; table.sort(t); return t end
local function parse_meta(s) local meta={}; for k,v in s:gmatch("//%s*META:([%w_%-]+)%s*=%s*([^\r\n]+)") do meta[k]=v end; return meta end
local function inject_meta(body, m) local cleaned=body:gsub("//%s*META:[^\r\n]*\r?\n",""); local header=""; for k,v in pairs(m) do header=header..("// META:%s=%s\n"):format(k,v) end; return header..cleaned end
local function apply_rules(fp) local raw=readall(fp) or ""; local rel=fp:lower():gsub(res:lower()..sep,""); local merged=parse_meta(raw); local hit=false; for _,rul in ipairs(rules) do if rel:find(rul.pattern) then for k,v in pairs(rul.set) do merged[k]=v end; hit=true end end; if hit then writeall(fp, inject_meta(raw, merged)); reaper.ShowConsoleMsg("[DF95] META applied: "..rel.."\n") end end
reaper.ShowConsoleMsg("[DF95] META Bulk Wizard…\n"); for _,fp in ipairs(list_chains(base)) do apply_rules(fp) end; reaper.ShowConsoleMsg("[DF95] Fertig.\n")
