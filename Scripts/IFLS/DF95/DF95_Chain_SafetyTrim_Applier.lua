-- @description Chain Safety-Trim Applier (create *_safe.rfxchain variants)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Erzeugt sichere Varianten (mit Trim + optional ReaLimit) für riskante Ketten in Data/DF95/Chains und FXChains.
--        Originale bleiben unverändert. Nutzt SmartCeiling für Ceiling-Vorschlag.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function read_text(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function write_text(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end
local function list(dir)
  local t,i={},0; while true do local fn=reaper.EnumerateFiles(dir,i); if not fn then break end t[#t+1]=fn; i=i+1 end; return t
end
local function ensure_dir(p) return reaper.RecursiveCreateDirectory(p,0)~=0 end

local C = dofile((debug.getinfo(1,"S").source:match("(.+[\\/])") or "").."DF95_SmartCeiling_Helper.lua")

local roots = {
  res..sep.."Data"..sep.."DF95"..sep.."Chains"..sep,
  res..sep.."FXChains"..sep
}

local function needs_safety(text)
  -- risk flags: no ReaLimit, has distortion/granular terms
  if text:match("ReaLimit") then return false end
  if text:match("[Gg]ranular") or text:match("[Gg]litch") or text:match("[Pp]arallel") or text:match("[Gg]enerative") then
    return true
  end
  -- default heuristic: if more than 6 FX and no limiter, add safety
  local fx_count = 0
  for _ in text:gmatch("<.-:") do fx_count=fx_count+1 end
  return (fx_count>=6)
end

local function inject_safety(text, category)
  local ceiling = C.get(category or "Default")
  local trim = string.format('<JS: Utility/volume>\nFLOATPARAM 0 -0.30\n')
  local limit = string.format('<VST: ReaLimit (Cockos)>\nFLOATPARAM 0 %.2f\n', ceiling)
  return text .. "\n" .. trim .. limit .. "\n"
end

local function category_from_path(path)
  path = path:gsub("\\","/")
  local m = path:match("/Chains/([^/]+)/")
  return m or "Default"
end

local created = 0
for _,root in ipairs(roots) do
  local files = list(root)
  for _,fn in ipairs(files) do
    if fn:match("%.rfxchain$") and not fn:match("_safe%.rfxchain$") then
      local p = root..fn
      local t = read_text(p)
      if t and needs_safety(t) then
        local cat = category_from_path(p)
        local safe = inject_safety(t, cat)
        local outp = p:gsub("%.rfxchain$", "_safe.rfxchain")
        write_text(outp, safe)
        created = created + 1
      end
    end
  end
end

reaper.ShowMessageBox(("DF95 Safety-Trim Applier: %d sichere Varianten erzeugt (*_safe.rfxchain)."):format(created), "DF95 Safety", 0)