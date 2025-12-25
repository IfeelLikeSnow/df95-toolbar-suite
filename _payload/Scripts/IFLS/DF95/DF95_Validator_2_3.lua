-- @description Validator 2.3 (CSV/Chains/Plugins)
-- @version 2.3
-- @author IfeelLikeSnow
-- @about Prüft Katalog (CSV), Chain-Dateien, Plugin-Verfügbarkeit per AddByName (trocken).
local r = reaper
local sep = package.config:sub(1,1)
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

local function chain_exists(rel)
  local res = r.GetResourcePath()
  local paths = {
    res..sep.."FXChains"..sep..rel,
    res..sep.."Data"..sep.."DF95"..sep.."Chains"..sep..rel
  }
  for _,p in ipairs(paths) do local f=io.open(p,"rb"); if f then f:close(); return true,p end end
  return false, nil
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

local function plugin_exists(label)
  local tr = r.GetMasterTrack(0)
  local idx = r.TrackFX_AddByName(tr, label, false, 0)
  if idx >= 0 then
    r.TrackFX_Delete(tr, idx)
    return true
  end
  local short = label:gsub("%b()", ""):gsub("^%s+",""):gsub("%s+$","")
  idx = r.TrackFX_AddByName(tr, short, false, 0)
  if idx >= 0 then
    r.TrackFX_Delete(tr, idx)
    return true
  end
  return false
end

r.ClearConsole()
log("DF95 Validator 2.3 — Start")

local cat_path, data = find_catalog()
if not cat_path then log("FEHLER: Kein Katalog CSV unter Data/DF95 gefunden."); return end
log("Katalog: "..cat_path)

local rows = parse_csv(data)
local ok_cnt, miss_chain, miss_fx = 0, 0, 0

for _,row in ipairs(rows) do
  local cat = (row["category"] or row["Category"] or ""); if cat=="Unsorted" or cat=="Mic FX" then goto continue end
  local rel = (row["chain_relpath"] or row["Path"] or "")
  local name= (row["chain_name"] or row["Name"] or rel:match("[^/\\]+$") or rel)
  if rel=="" then goto continue end
  local exists, path = chain_exists(rel)
  if not exists then
    log("[KETTE FEHLT] "..cat.." | "..name.." -> "..rel)
    miss_chain = miss_chain + 1
  else
    local f = io.open(path,"rb"); local t = f:read("*all"); f:close()
    local fx = extract_fx_labels(t or "")
    local bad = {}
    for _,lab in ipairs(fx) do if not plugin_exists(lab) then bad[#bad+1]=lab end end
    if #bad>0 then
      log("[PLUGIN FEHLT] "..cat.." | "..name.." -> "..table.concat(bad," | "))
      miss_fx = miss_fx + 1
    else
      ok_cnt = ok_cnt + 1
    end
  end
  ::continue::
end

log("---- Zusammenfassung ----")
log("OK-Ketten: "..ok_cnt)
log("Fehlende Chains: "..miss_chain)
log("Chains mit fehlenden Plugins: "..miss_fx)
log("DF95 Validator 2.3 — Ende")
