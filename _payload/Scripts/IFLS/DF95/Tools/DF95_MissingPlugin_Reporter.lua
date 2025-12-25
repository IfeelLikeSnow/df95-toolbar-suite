-- @description Missing-Plugin Reporter (with substitutions)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res..sep.."FXChains"..sep.."DF95"
local submap_fn = res..sep.."Data"..sep.."DF95"..sep.."DF95_PluginSubstitutions.json"

local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function json(s) if reaper.JSON_Decode then return reaper.JSON_Decode(s) end end
local subs = json(readall(submap_fn) or "{}") or {}

local function list_chains(root)
  local t, stack = {}, {root}
  while #stack>0 do
    local dir = table.remove(stack)
    local i=0
    while true do local d=reaper.EnumerateSubdirectories(dir,i); if not d then break end; stack[#stack+1]=dir..sep..d; i=i+1 end
    local j=0
    while true do local fn=reaper.EnumerateFiles(dir,j); if not fn then break end; if fn:lower():match("%.rfxchain$") then t[#t+1]=dir..sep..fn end; j=j+1 end
  end
  table.sort(t); return t
end

local function parse_fx_list(raw)
  local fx = {}
  for line in (raw.."\n"):gmatch("([^\r\n]+)\r?\n") do
    local nm = line:match('VST%s*:%s*([^\"]+)') or line:match('JS%s*:%s*([^\"]+)')
    if nm and not nm:lower():match("%.rfxchain$") then fx[#fx+1]=nm end
  end
  return fx
end

local function fx_exists(name)
  local tr = reaper.GetSelectedTrack(0,0)
  local idx = reaper.TrackFX_AddByName(tr or 0, name, false, 1)
  return idx >= 0
end

local function best_sub(name)
  return subs[name] or {}
end

local function run()
  local L = list_chains(base)
  reaper.ShowConsoleMsg("[DF95] Missing-Plugin Reporter\n")
  local total_missing = 0
  for _,fp in ipairs(L) do
    local raw = readall(fp) or ""
    local fx = parse_fx_list(raw)
    local miss = {}
    for _,nm in ipairs(fx) do
      if not fx_exists("VST: "..nm) and not fx_exists("JS: "..nm) then miss[#miss+1]=nm end
    end
    if #miss>0 then
      total_missing = total_missing + #miss
      reaper.ShowConsoleMsg((" - %s\n"):format(fp:gsub(res..sep,"")))
      for _,m in ipairs(miss) do
        local alt = best_sub(m); reaper.ShowConsoleMsg(("   * missing: %s  →  substitute: %s\n"):format(m, alt[1] or "n/a"))
      end
    end
  end
  if total_missing==0 then reaper.ShowConsoleMsg("[DF95] OK: keine fehlenden Plugins.\n") end
end

run()
