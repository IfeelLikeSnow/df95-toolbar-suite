
-- @description Dynamic Chain Menu (Category Scanner v2)
-- @version 2.0
-- @param cat string Category folder under FXChains/DF95 (e.g., "Master","Coloring","FXBus","Mic")
local r = reaper
local function menu(str) local _,_,x,y=r.GetMousePosition(); gfx.init("DF95_Menu",1,1,0,x,y); local s=gfx.showmenu(str); gfx.quit(); return s end
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function list_chains(cat)
  local base = res..sep.."FXChains"..sep.."DF95"..sep..cat
  local t = {}
  local i = 0
  local dir = r.EnumerateFiles
  local idx = 0
  while true do
    local fn = r.EnumerateFiles(base, idx)
    if not fn then break end
    if fn:lower():match("%.rfxchain$") then
      i = i + 1
      t[#t+1] = {name = fn, path = base..sep..fn}
    end
    idx = idx + 1
  end
  return t
end
local function run(cat)
  local items = list_chains(cat)
  local labels = {}
  for _, it in ipairs(items) do labels[#labels+1] = it.name end
  if #labels == 0 then
    r.ShowConsoleMsg(("[DF95] Keine Chains in %s gefunden.\n"):format(cat))
    return
  end
  local choice = menu(table.concat(labels,"|"))
  if choice<=0 then return end
  local sel = items[choice]
  r.Main_OnCommand(40296,0) -- Track: Insert new track
  local tr = r.GetSelectedTrack(0,0)
  if tr then
    r.TrackFX_AddByName(tr, sel.path, 0, -1000) -- Load whole chain
  end
end
return run ...
