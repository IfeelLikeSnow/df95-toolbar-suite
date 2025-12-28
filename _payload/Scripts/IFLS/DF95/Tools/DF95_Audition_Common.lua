-- @description Audition Runner (common)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function readjson(fp)
  local f = io.open(fp,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if not reaper.JSON_Decode then return nil end
  return reaper.JSON_Decode(d)
end
local function list_from_index(index_path, subdir)
  local t = readjson(index_path) or {}
  local list = {}
  for cat, arr in pairs(t) do
    for _,rel in ipairs(arr) do
      list[#list+1] = res..sep.."FXChains"..sep.."DF95"..sep..subdir..sep..rel:gsub("/", sep)
    end
  end
  table.sort(list)
  return list
end
return { list_from_index = list_from_index }
