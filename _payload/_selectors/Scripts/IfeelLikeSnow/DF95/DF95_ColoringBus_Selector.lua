if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD

-- @description DF95: Coloring Bus Selector (loads .rfxchain)
-- @version 2.0
-- @author IfeelLikeSnow
local r = reaper
local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""
local common = dofile(base.."DF95_Common_RfxChainLoader.lua")

local chains = {
  {"Warm – Tape (AW)",          "Coloring/Warm_Tape_AW.rfxchain"},
  {"Warm – AO Console",         "Coloring/Warm_AO_Console.rfxchain"},
  {"Light – Subtle Glue",       "Coloring/Light_SubtleGlue.rfxchain"},
  {"Neutral – Clean Color",     "Coloring/Neutral_Clean.rfxchain"},
  {"Rich – AW Stack",           "Coloring/Rich_AW_Stack.rfxchain"}
}

local function apply_chain(relpath, append)
  local tr = common.ensure_track_named("[Coloring Bus]")
  local path = common.chains_root(relpath)
  local txt = common.read_file(path)
  if not txt then r.ShowMessageBox("Kette nicht gefunden:\n"..path,"DF95 Coloring",0) return end
  local ok, err = common.write_chunk_fxchain(tr, txt, append)
  if not ok then r.ShowMessageBox("Fehler beim Laden:\n"..(err or "?"),"DF95 Coloring",0) end
end

local function show_menu()
  local items = {"# DF95 Coloring Bus",">Chains"}
  for _,c in ipairs(chains) do table.insert(items, c[0] or c[1]) end
  table.insert(items,"<")
  local menu = table.concat(items, "|")
  gfx.init("DF95 Coloring",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx >= 2 and idx <= 1+#chains then
    local rel = chains[idx-1][2]
    apply_chain(rel, false)
  end
end

show_menu()
