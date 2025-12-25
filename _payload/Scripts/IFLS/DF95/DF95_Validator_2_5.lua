-- @description Validator 2.5 (CSV/Chains/Plugins + FXName Verify, silent option)
-- @version 2.5.1
-- @author IfeelLikeSnow
-- @about Prüft Katalog (CSV), Chain-Dateien, Plugin-Verfügbarkeit per AddByName und verifiziert FX-Namen. Optionaler Silent-Mode.
-- @changelog +silent mode (no message boxes), +compact summary

local r = reaper
local sep = package.config:sub(1,1)

local ARGS = ...
local SILENT = (type(ARGS)=="table" and ARGS.silent) or (ARGS=="--silent")

local function log(s) r.ShowConsoleMsg((tostring(s) or "").."\n") end
local function read_file(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end

local function find_catalog()
  local res = r.GetResourcePath()
  local cands = {
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog_Reclassified_SoftPass.csv",
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog_Reclassified_Strict.csv",
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog.csv"
  }
  for _,p in ipairs(cands) do local d=read_file(p); if d and #d>0 then return p,d end end
  return nil,nil
end

local function parse_csv(text)
  local rows, header = {}, nil
  for line in (text.."\n"):gmatch("(.-)\r?\n") do
    if not header then header={}; for col in line:gmatch('([^,]+)') do header[#header+1]=col:gsub('^"+',''):gsub('"+$','') end
    else
      if line:match("%S") then
        local vals={}; for col in line:gmatch('([^,]+)') do vals[#vals+1]=col:gsub('^"+',''):gsub('"+$','') end
        local row={}; for i=1,math.min(#header,#vals) do row[header[i]]=vals[i] end
        rows[#rows+1]=row
      end
    end
  end
  return rows
end

local function chain_resolve(rel)
  local res = r.GetResourcePath()
  local paths = { res..sep.."FXChains"..sep..rel, res..sep.."Data"..sep.."DF95"..sep.."Chains"..sep..rel }
  for _,p in ipairs(paths) do local f=io.open(p,"rb"); if f then f:close(); return p end end
  return nil
end

local function extract_fx_labels(text)
  local labels = {}
  for tag in text:gmatch("<(VST3:%s*.-)>") do labels[#labels+1] = tag:sub(1,-2) end
  for tag in text:gmatch("<(VST:%s*.-)>")  do labels[#labels+1] = tag:sub(1,-2) end
  for tag in text:gmatch("<(JS:%s*.-)>")   do labels[#labels+1] = tag:sub(1,-2) end
  for tag in text:gmatch("<(AU:%s*.-)>")   do labels[#labels+1] = tag:sub(1,-2) end
  for tag in text:gmatch("<(DX:%s*.-)>")   do labels[#labels+1] = tag:sub(1,-2) end
  return labels
end

local function plugin_check(label)
  local tr = r.GetMasterTrack(0)
  local idx = r.TrackFX_AddByName(tr, label, false, 0)
  if idx >= 0 then
    local _, fxname = r.TrackFX_GetFXName(tr, idx, "")
    r.TrackFX_Delete(tr, idx)
    return true, fxname
  end
  local short = label:gsub("%b()", ""):gsub("^%s+",""):gsub("%s+$","")
  idx = r.TrackFX_AddByName(tr, short, false, 0)
  if idx >= 0 then
    local _, fxname = r.TrackFX_GetFXName(tr, idx, "")
    r.TrackFX_Delete(tr, idx)
    return true, fxname
  end
  return false, nil
end

if not SILENT then r.ClearConsole() end
if not SILENT then log("DF95 Validator 2.5 — Start") end

local cat_path, data = find_catalog()
if not cat_path then if not SILENT then log("FEHLER: Kein DF95-Katalog CSV unter Data/DF95 gefunden.") end return end
if not SILENT then log("Katalog: "..cat_path) end

local rows = parse_csv(data)
local ok_cnt, miss_chain, bad_fx = 0, 0, 0

for _,row in ipairs(rows) do
  local cat = (row["category"] or row["Category"] or ""); if cat=="Unsorted" or cat=="Mic FX" then goto continue end
  local rel = (row["chain_relpath"] or row["Path"] or "")
  local name= (row["chain_name"] or row["Name"] or (rel:match("[^/\\]+$") or rel))
  if rel=="" then goto continue end
  local path = chain_resolve(rel)
  if not path then
    if not SILENT then log("[KETTE FEHLT] "..cat.." | "..name.." -> "..rel) end
    miss_chain = miss_chain + 1
  else
    local f = io.open(path,"rb"); local t = f and f:read("*all") or ""; if f then f:close() end
    local fx = extract_fx_labels(t or "")
    local bad = {}
    for _,lab in ipairs(fx) do
      local ok, fxname = plugin_check(lab)
      if not ok then bad[#bad+1]=lab end
    end
    if #bad>0 then
      if not SILENT then log("[PLUGIN FEHLT] "..cat.." | "..name.." -> "..table.concat(bad," | ")) end
      bad_fx = bad_fx + 1
    else
      ok_cnt = ok_cnt + 1
    end
  end
  ::continue::
end

local summary = ("OK=%d, MISSING_CHAINS=%d, MISSING_PLUGINS=%d"):format(ok_cnt, miss_chain, bad_fx)
if not SILENT then
  log("---- Zusammenfassung ----")
  log(summary)
  log("DF95 Validator 2.5 — Ende")
else
  r.ShowConsoleMsg("[DF95 VALIDATOR 2.5] "..summary.."\n")
end
