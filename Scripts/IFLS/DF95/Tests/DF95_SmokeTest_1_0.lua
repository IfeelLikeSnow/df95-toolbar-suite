-- @description Smoke-Test 1.0 (per Kategorie 3 Chains laden + Log)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Lädt pro Kategorie (Master/Coloring/FX Bus/Artist/Generative/Parallel/Safety) die ersten 3 Ketten aus dem CSV-Katalog,
--        prüft Ladefähigkeit, misst Zeit, säubert wieder. Ergebnis im ReaScript-Console-Log.

local r = reaper
local sep = package.config:sub(1,1)
local function log(s) r.ShowConsoleMsg((tostring(s) or "").."\n") end

local function load_chain_on_track(chain_relpath, track)
  if not chain_relpath or chain_relpath == "" or not track then return false end
  local bases = {
    r.GetResourcePath() .. sep .. "FXChains" .. sep,
    r.GetResourcePath() .. sep .. "Data" .. sep .. "DF95" .. sep .. "Chains" .. sep
  }
  local path = nil
  for _,b in ipairs(bases) do
    local p = b .. chain_relpath
    local f = io.open(p,"rb")
    if f then f:close(); path = p; break end
  end
  if not path then return false, "Chain not found" end
  local idx = r.TrackFX_AddByName(track, "Chain: " .. path, false, -1000)
  if idx < 0 then return false, "AddByName failed" end
  return true
end

local function ensure_temp_tracks(n)
  local list = {}
  for i=1,n do
    r.InsertTrackAtIndex(r.CountTracks(0), true)
    local tr = r.GetTrack(0, r.CountTracks(0)-1)
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", "DF95_SMOKE_"..i, true)
    list[#list+1] = tr
  end
  return list
end

local function remove_tracks(list)
  for i=#list,1,-1 do
    r.DeleteTrack(list[i])
  end
end

local function read_file(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function find_catalog()
  local res = r.GetResourcePath()
  local cands = {
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog_Reclassified_SoftPass.csv",
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog_Reclassified_Strict.csv",
    res..sep.."Data"..sep.."DF95"..sep.."DF95_FXChains_Catalog.csv"
  }
  for _,p in ipairs(cands) do local d=read_file(p); if d and #d>0 then return p, d end end
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

local function pick_first_n(rows, cat, n)
  local list = {}
  for _,row in ipairs(rows) do
    local c = (row["category"] or row["Category"] or "")
    if c == cat then
      list[#list+1] = {
        rel = (row["chain_relpath"] or row["Path"] or ""),
        name= (row["chain_name"] or row["Name"] or (row["Path"] or ""))
      }
      if #list >= n then break end
    end
  end
  return list
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
r.ClearConsole()
log("DF95 Smoke-Test 1.0 — Start")

local cat_path, data = find_catalog()
if not cat_path then log("FEHLER: Kein DF95-Katalog CSV unter Data/DF95 gefunden."); return end
log("Katalog: "..cat_path)

local rows = parse_csv(data)
local categories = {"Master","Coloring","FX Bus","Artist","Generative","Parallel","Safety/QA"}

local master = r.GetMasterTrack(0)
local temp_tracks = ensure_temp_tracks(3)

for _,cat in ipairs(categories) do
  log("-- Kategorie: "..cat.." --")
  local picks = pick_first_n(rows, cat, 3)
  if #picks == 0 then log("  (keine Einträge)") goto cont end

  for i,p in ipairs(picks) do
    local t0 = r.time_precise()
    local ok,err
    if cat == "Master" then
      ok,err = load_chain_on_track(p.rel, master)
      if ok then
        for fx = r.TrackFX_GetCount(master)-1,0,-1 do r.TrackFX_Delete(master, fx) end
      end
    else
      local tr = temp_tracks[((i-1)%#temp_tracks)+1]
      ok,err = load_chain_on_track(p.rel, tr)
      if ok then
        for fx = r.TrackFX_GetCount(tr)-1,0,-1 do r.TrackFX_Delete(tr, fx) end
      end
    end
    local dt = string.format("%.2f ms", (r.time_precise()-t0)*1000.0)
    if ok then
      log(string.format("  OK  | %s | %s | %s", cat, p.name, dt))
    else
      log(string.format("  ERR | %s | %s | %s", cat, p.name, err or "unknown"))
    end
  end
  ::cont::
end

remove_tracks(temp_tracks)
r.PreventUIRefresh(-1)
r.Undo_EndBlock("DF95 Smoke-Test 1.0", -1)
log("DF95 Smoke-Test 1.0 — Ende")
