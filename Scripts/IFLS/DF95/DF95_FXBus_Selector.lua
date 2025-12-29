if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD

-- @description FX Bus Selector (categories + auto-mapping to filenames)
-- @version 1.1
-- @author IfeelLikeSnow
local r = reaper
-- Weighted choice utility
local function weighted_choice(items)
  -- items = { {name="musical", w=0.80}, {name="gritty", w=0.15}, {name="extreme", w=0.05} }
  local sum=0; for _,it in ipairs(items) do sum = sum + (it.w or 0) end
  local rdm = math.random() * sum
  local acc=0
  for _,it in ipairs(items) do acc = acc + (it.w or 0); if rdm <= acc then return it.name end end
  return items[#items].name
end
local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""
local C = dofile(base.."DF95_Common_RfxChainLoader.lua")
local TAGS = dofile(base.."DF95_FXChains_Tags.lua")

local function add_parallel_fx_bus()
  r.Undo_BeginBlock()
  local fxbus = C.ensure_track_named("[FX Bus]")
  local idx=1; local final="[FX Bus]"
  while true do
    local exists=false
    for i=0, r.CountTracks(0)-1 do
      local tr = r.GetTrack(0,i)
      local _, nm = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      if nm == final then exists=true break end
    end
    if not exists then break end
    idx=idx+1; final="[FX Bus "..idx.."]"
  end
  local tr_new = C.ensure_track_named(final)
  for s=0, r.CountSelectedTracks(0)-1 do
    local tr = r.GetSelectedTrack(0,s)
    r.CreateTrackSend(tr, tr_new)
  end
  local color = C.ensure_track_named("[Coloring Bus]")
  local function ensure_send(src,dst)
    local sends = r.GetTrackNumSends(src, 0)
    for i=0, sends-1 do
      local dest = r.BR_GetSetTrackSendInfo(src, 0, i, "P_DESTTRACK", false, 0)
      if dest == dst then return end
    end
    r.CreateTrackSend(src,dst)
  end
  ensure_send(fxbus,color); ensure_send(tr_new,color)
  r.Undo_EndBlock("DF95: Add Parallel FX Bus & Route", -1)
end

local function apply_chain(path, append)
  local tr = C.ensure_track_named("[FX Bus]")
  local txt = C.read_file(path)
  if not txt then r.ShowMessageBox("Kette nicht gefunden:\n"..path,"DF95 FXBus",0) return end
  local ok, err = C.write_chunk_fxchain(tr, txt, append)
  if not ok then r.ShowMessageBox("Fehler beim Laden:\n"..(err or "?"),"DF95 FXBus",0) end
end

local function build_and_show_menu()
  local cats = C.list_by_category("FXBus")
  local items = {"# DF95 FX Bus","Add Parallel FX Bus"}
  local index_to_path = {}
  -- top-level (uncategorized) first
  if cats[""] and #cats[""]>0 then
    table.insert(items, ">Uncategorized")
    for _,e in ipairs(cats[""]) do
      local rel = e.rel or e.relpath or (e.subdir and (e.subdir.."/"..e.name)) or e.name
      local taginfo = TAGS.get_tag_string("FXBus", rel)
      local label = e.label or e.name
      if taginfo ~= "" then label = label .. " ["..taginfo.."]" end
      table.insert(items, label)
      index_to_path[#items] = e.path
    end
    table.insert(items, "<")
  end
  -- then subcategories
  for cat, list in pairs(cats) do
    if cat ~= "" and #list>0 then
      table.insert(items, ">"..cat)
      for _,e in ipairs(list) do
        local rel = e.rel or e.relpath or (e.subdir and (e.subdir.."/"..e.name)) or e.name
        local taginfo = TAGS.get_tag_string("FXBus", rel)
        local label = e.label or e.name
        if taginfo ~= "" then label = label .. " ["..taginfo.."]" end
        table.insert(items, label)
        index_to_path[#items] = e.path
      end
      table.insert(items, "<")
    end
  end
  local menu = table.concat(items, "|")
  gfx.init("DF95 FX Bus",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx == 2 then add_parallel_fx_bus(); return end
  local path = index_to_path[idx]
  if path then apply_chain(path, false) end
end

local function mod_pressed()
  if r.JS_VKeys_GetState then
    local s = r.JS_VKeys_GetState(0); if s then
      local function p(vk) return s:byte(vk+1)~=0 end
      return p(0x10) or p(0x12)
    end
  end
  return false
end

r.PreventUIRefresh(1)
if mod_pressed() then add_parallel_fx_bus() else build_and_show_menu() end
r.PreventUIRefresh(-1)

-- DF95_WEIGHTING_APPLIED
local cat = weighted_choice({{name='musical',w=0.80},{name='gritty',w=0.15},{name='extreme',w=0.05}})
reaper.SetExtState('DF95_FLOW','FXSeedCategory',cat,false)
