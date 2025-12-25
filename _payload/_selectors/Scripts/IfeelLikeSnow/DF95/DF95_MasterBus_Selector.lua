if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD

-- @description DF95: Master Bus Selector (loads .rfxchain)
-- @version 2.0
-- @author IfeelLikeSnow
local r = reaper
local sep = package.config:sub(1,1)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""
local common = dofile(base.."DF95_Common_RfxChainLoader.lua")

local chains = {
  {"Standard – SafeGain + ReaLimit", "Master/Standard_Safe_ReaLimit.rfxchain"},
  {"Artist – Neutral (AW)",          "Master/Artist_Neutral_AW.rfxchain"},
  {"Punch – BusComp + Tape",         "Master/Punch_Bus_Tape.rfxchain"},
  {"Clean – LUFS Monitor",           "Master/Clean_LUFS.rfxchain"}
}

local function apply_chain(relpath, append)
  -- Master bus is REAPER's master track; we modify its chunk
  local proj = 0
  local master = r.GetMasterTrack(proj)
  local path = common.chains_root(relpath)
  local txt = common.read_file(path)
  if not txt then r.ShowMessageBox("Kette nicht gefunden:\n"..path,"DF95 Master",0) return end
  local ok, err = common.write_chunk_fxchain(master, txt, false)
  if not ok then r.ShowMessageBox("Fehler beim Laden:\n"..(err or "?"),"DF95 Master",0) end
end

local function show_menu()
  local items = {"# DF95 Master Bus",">Chains"}
  for _,c in ipairs(chains) do table.insert(items, c[0] or c[1]) end
  table.insert(items,"<")
  local menu = table.concat(items, "|")
  gfx.init("DF95 Master",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx >= 2 and idx <= 1+#chains then
    local rel = chains[idx-1][2]
    apply_chain(rel, false)
  end
end

show_menu()
