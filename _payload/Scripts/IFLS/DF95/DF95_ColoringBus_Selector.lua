if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD

-- @description Coloring Bus Selector (categories + auto-mapping to filenames)
-- @version 2.2
-- @author IfeelLikeSnow
local r = reaper
local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""
local C = dofile(base.."DF95_Common_RfxChainLoader.lua")
local TAGS = dofile(base.."DF95_FXChains_Tags.lua")

local function apply_chain(path, append)
  local tr = C.ensure_track_named("[Coloring Bus]")
  local txt = C.read_file(path)
  if not txt then r.ShowMessageBox("Kette nicht gefunden:\n"..path,"DF95 Coloring",0) return end
  local ok, err = C.write_chunk_fxchain(tr, txt, append)
  if not ok then r.ShowMessageBox("Fehler beim Laden:\n"..(err or "?"),"DF95 Coloring",0) end
end

local function build_and_show_menu()
  local cats = C.list_by_category("Coloring")
  local items = {"# DF95 Coloring Bus"}
  local index_to_path = {}
  if cats[""] and #cats[""]>0 then
    table.insert(items, ">Uncategorized")
    for _,e in ipairs(cats[""]) do
      local rel = e.rel or e.relpath or (e.subdir and (e.subdir.."/"..e.name)) or e.name
      local taginfo = TAGS.get_tag_string("Coloring", rel)
      local label = e.label or e.name
      if taginfo ~= "" then label = label .. " ["..taginfo.."]" end
      table.insert(items, label)
      index_to_path[#items] = e.path
    end
    table.insert(items, "<")
  end
  for cat, list in pairs(cats) do
    if cat ~= "" and #list>0 then
      table.insert(items, ">"..cat)
      for _,e in ipairs(list) do
        local rel = e.rel or e.relpath or (e.subdir and (e.subdir.."/"..e.name)) or e.name
        local taginfo = TAGS.get_tag_string("Coloring", rel)
        local label = e.label or e.name
        if taginfo ~= "" then label = label .. " ["..taginfo.."]" end
        table.insert(items, label)
        index_to_path[#items] = e.path
      end
      table.insert(items, "<")
    end
  end
  local menu = table.concat(items, "|")
  gfx.init("DF95 Coloring",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  local path = index_to_path[idx]
  if path then apply_chain(path, false) end
end

build_and_show_menu()
