
-- @description Chain Indexer v1 (builds Data/DF95/DF95_ChainIndex.json)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function listdir(path)
  local files = {}
  local i=0
  while true do
    local f = r.EnumerateFiles(path, i)
    if not f then break end
    files[#files+1] = {type="file", name=f, path=path..sep..f}
    i=i+1
  end
  local j=0
  while true do
    local d = r.EnumerateSubdirectories(path, j)
    if not d then break end
    files[#files+1] = {type="dir", name=d, path=path..sep..d}
    j=j+1
  end
  return files
end

local function readfile(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end



-- Autofill from path segments (folder names)
local function infer_tags_from_rel(relpath_lower)
  local tags = {}
  local function add(t) tags[#tags+1]=t end
  if relpath_lower:find("/autechre/") then add("artist:autechre") end
  if relpath_lower:find("/aphex") then add("artist:aphex") end
  if relpath_lower:find("/boc/") or relpath_lower:find("boards%-?of%-?canada") then add("artist:boc") end
  if relpath_lower:find("/squarepusher/") then add("artist:squarepusher") end
  if relpath_lower:find("/plaid/") then add("artist:plaid") end
  if relpath_lower:find("/arovane/") then add("artist:arovane") end
  if relpath_lower:find("/proem/") then add("artist:proem") end
  if relpath_lower:find("/mu%-?ziq/") then add("artist:muziq") end
  if relpath_lower:find("/bola/") then add("artist:bola") end
  if relpath_lower:find("/mouseonmars/") then add("artist:mouseonmars") end
  if relpath_lower:find("/jan%-?jelinek/") then add("artist:janjelinek") end
  if relpath_lower:find("/four%-?tet/") then add("artist:fourtet") end
  if relpath_lower:find("/idm/") then add("style:idm") end
  if relpath_lower:find("/glitch/") then add("style:glitch") end
  if relpath_lower:find("/granular/") then add("style:granular") end
  if relpath_lower:find("/euclid/") then add("style:euclid") end
  if relpath_lower:find("/warm/") then add("color:warm") end
  if relpath_lower:find("/clean/") then add("color:clean") end
  if relpath_lower:find("/tape/") then add("color:tape") end
  if relpath_lower:find("/console/") then add("color:console") end
  return tags
end

local function scan_category(cat)
  local base = res..sep.."FXChains"..sep.."DF95"..sep..cat
  local out = {}
  local function walk(dir, rel)
    local items = listdir(dir)
    for _, it in ipairs(items) do
      if it.type=="file" and it.name:lower():match("%.rfxchain$") then
        local relpath = (rel~="" and rel.."/" or "")..it.name
        local raw = readfile(it.path) or ""
        local meta = {}
        for mkey, mval in raw:gmatch("//%s*META:([%w_%-]+)%s*=%s*([^\r\n]+)") do
          meta[mkey] = mval
        end
        local tags = {}
        local namelow = it.name:lower()
        if namelow:find("boc") then tags[#tags+1]="artist:boc" end
        if namelow:find("autechre") then tags[#tags+1]="artist:autechre" end
        if namelow:find("aphex") then tags[#tags+1]="artist:aphex" end
        if namelow:find("squarepusher") then tags[#tags+1]="artist:squarepusher" end
        if namelow:find("warm") then tags[#tags+1]="color:warm" end
        if namelow:find("clean") then tags[#tags+1]="color:clean" end
        if namelow:find("tape") then tags[#tags+1]="color:tape" end
        local inferred = infer_tags_from_rel(("/"..(rel or "").."/"..it.name):lower())
        local alltags = {}
        for _,t in ipairs(tags) do alltags[#alltags+1]=t end
        for _,t in ipairs(inferred) do alltags[#alltags+1]=t end
        out[#out+1] = {
          category = cat,
          name = it.name,
          relpath = "FXChains/DF95/"..cat.."/"..relpath,
          tags = alltags,
          meta = meta
        }
      elseif it.type=="dir" then
        walk(it.path, (rel~="" and rel.."/" or "")..it.name)
      end
    end
  end
  walk(base, "")
  return out
end

local cats = {"Master","Coloring","FXBus","Mic"}
local index = {}
for _, c in ipairs(cats) do
  local part = scan_category(c)
  for _, e in ipairs(part) do index[#index+1] = e end
end

if not reaper.JSON_Encode then
  reaper.ShowMessageBox("JSON-API nicht verfügbar (REAPER 6.82+ erforderlich).","DF95 Indexer",0)
  return
end
local out = reaper.JSON_Encode(index)
local outpath = res..sep.."Data"..sep.."DF95"..sep.."DF95_ChainIndex.json"
local f = io.open(outpath, "wb"); if f then f:write(out); f:close() end
reaper.ShowConsoleMsg(("[DF95] ChainIndex geschrieben: %s (Einträge: %d)\n"):format(outpath, #index))


        if namelow:find("aphex") then tags[#tags+1]="artist:aphex" end
        if namelow:find("plaid") then tags[#tags+1]="artist:plaid" end
        if namelow:find("arovane") then tags[#tags+1]="artist:arovane" end
        if namelow:find("proem") then tags[#tags+1]="artist:proem" end
        if namelow:find("mu%-?ziq") or namelow:find("muziq") then tags[#tags+1]="artist:muziq" end
        if namelow:find("bola") then tags[#tags+1]="artist:bola" end
        if namelow:find("mouseonmars") then tags[#tags+1]="artist:mouseonmars" end
        if namelow:find("janjelinek") or namelow:find("jan%-?jelinek") then tags[#tags+1]="artist:janjelinek" end
        if namelow:find("four%-?tet") then tags[#tags+1]="artist:fourtet" end
        if namelow:find("idm") then tags[#tags+1]="style:idm" end
        if namelow:find("glitch") then tags[#tags+1]="style:glitch" end
        if namelow:find("granular") then tags[#tags+1]="style:granular" end
        if namelow:find("euclid") then tags[#tags+1]="style:euclid" end
        if namelow:find("warm") then tags[#tags+1]="color:warm" end
        if namelow:find("clean") then tags[#tags+1]="color:clean" end
        if namelow:find("tape") then tags[#tags+1]="color:tape" end
