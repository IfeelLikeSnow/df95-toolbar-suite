-- @description Parallel Dropdown (CSV-driven)
-- @version 1.2
-- @author IfeelLikeSnow
-- @about Dropdown nur für Kategorie: Parallel. Liest Data/DF95 Katalog, lädt .rfxchain.
local r = reaper
local sep = package.config:sub(1,1)
-- ChainLoader bootstrap (RootResolver, avoids require/package.path fragility)
local __df95_PR = dofile(reaper.GetResourcePath() .. "/Scripts/DF95Framework/Lib/DF95_PathResolver.lua")
local __df95_chain_path = __df95_PR.resolve_df95_script("DF95_ChainLoader.lua")
if not __df95_chain_path then
  reaper.ShowMessageBox("DF95_ChainLoader.lua nicht gefunden (RootResolver).", "DF95 Menu", 0)
  return
end
local Loader = dofile(__df95_chain_path)
if type(Loader) ~= "table" then
  reaper.ShowMessageBox("DF95_ChainLoader.lua lieferte kein Modul-Table.", "DF95 Menu", 0)
  return
end
local function read_file(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function find_catalog()
  local res = r.GetResourcePath()
  local cands = {
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog_Reclassified_SoftPass.csv",
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog_Reclassified_Strict.csv",
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog.csv"
  }
  for _,p in ipairs(cands) do local d = read_file(p); if d and #d>0 then return p, d end end
  return nil,nil
end

local function parse_csv(text)
  local rows, header = {}, nil
  rows = {}
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

local function build_items()
  local _,data = find_catalog()
  if not data then
    reaper.ShowMessageBox("Kein DF95-Katalog gefunden unter Data/DF95.","DF95 Menu",0)
    return {}
  end
  local rows = parse_csv(data)
  local wanted = "Parallel"
  local out={}
  out = {}
  for _,row in ipairs(rows) do
    local cat = (row["category"] or row["Category"] or ""):gsub("^%s+",""):gsub("%s+$","")
    local rel = (row["chain_relpath"] or row["Path"] or ""):gsub("^%s+",""):gsub("%s+$","")
    local name= (row["chain_name"] or row["Name"] or (rel:match("[^/\\]+$") or ""))
    if rel~="" and cat==wanted then
      out[#out+1] = {name=name, rel=rel}
    end
  end
  table.sort(out, function(a,b) return a.name:lower() < b.name:lower() end)
  return out
end

local items = build_items()
if #items==0 then return end

local menu, map, idx = "", {}, 0
for _,it in ipairs(items) do
  idx = idx + 1; map[idx] = it; menu = menu .. it.name .. "|"
end

local choice = reaper.ShowMenu(menu)
if choice and map[choice] then
  local it = map[choice]
  local tr = Loader.get_selected_tracks(); if #tr==0 then tr={ reaper.GetMasterTrack(0) } end; for _,t in ipairs(tr) do Loader.load_chain_on_track(it.rel, t) end
end
