-- @description Menu Helper (gfx.showmenu)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function readjson(fp)
  local f = io.open(fp,"rb"); if not f then return {} end
  local d=f:read("*all"); f:close()
  if not reaper.JSON_Decode then return {} end
  local ok, t = pcall(reaper.JSON_Decode, d)
  if ok and type(t)=="table" then return t end
  return {}
end

local function flat_menu_from_index(index_tbl)
  local entries, paths, menu = {}, {}, {}
  local cats = {}
  for cat, _ in pairs(index_tbl) do cats[#cats+1]=cat end
  table.sort(cats)
  for _,cat in ipairs(cats) do
    menu[#menu+1] = ">"..cat
    table.sort(index_tbl[cat])
    for _,rel in ipairs(index_tbl[cat]) do
      local name = (rel:match(".+/(.+)%.rfxchain$") or rel):gsub("_"," ")
      entries[#entries+1] = name
      paths[#paths+1] = {cat=cat, rel=rel}
      menu[#menu+1] = name
    end
    menu[#menu+1] = "<"
  end
  return table.concat(menu, "|"), entries, paths
end

return { readjson = readjson, flat_menu_from_index = flat_menu_from_index }
