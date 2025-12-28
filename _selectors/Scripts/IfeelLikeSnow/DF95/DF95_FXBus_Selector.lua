if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD

-- @description DF95: FX Bus Selector (Drop-down + Parallel; loads .rfxchain)
-- @version 2.0
-- @author IfeelLikeSnow
local r = reaper
local sep = package.config:sub(1,1)

-- require common (inline load via dofile on saved path)
local info = debug.getinfo(1,'S').source:sub(2)
local base = info:match("^(.*"..sep..")") or ""
local common = dofile(base.."DF95_Common_RfxChainLoader.lua")

local function add_parallel_fx_bus()
  r.Undo_BeginBlock()
  local fxbus = common.ensure_track_named("[FX Bus]")
  local new_name = "[FX Bus 2]"
  local idx=2
  while true do
    local t = nil
    for i=0,r.CountTracks(0)-1 do
      local tr = r.GetTrack(0,i)
      local _, nm = r.GetSetMediaTrackInfo_String(tr,"P_NAME","",false)
      if nm == new_name then t=tr break end
    end
    if not t then break end
    idx=idx+1; new_name="[FX Bus "..idx.."]"
  end
  local tr_new = common.ensure_track_named(new_name)
  local sel_cnt = r.CountSelectedTracks(0)
  for s=0, sel_cnt-1 do
    local tr = r.GetSelectedTrack(0,s)
    r.CreateTrackSend(tr, tr_new)
  end
  local color = common.ensure_track_named("[Coloring Bus]")
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

local chains = {
  {"Glitch – Light (CPU)",          "FXBus/Glitch_Light.rfxchain"},
  {"Granular – Classic",            "FXBus/Granular_Classic.rfxchain"},
  {"Spectral – Crumble",            "FXBus/Spectral_Crumble.rfxchain"},
  {"Stutter – Tight",               "FXBus/Stutter_Tight.rfxchain"},
  {"Time – SlowWarp",               "FXBus/Time_SlowWarp.rfxchain"}
}

local function apply_chain_to_fxbus(relpath, append)
  local tr = common.ensure_track_named("[FX Bus]")
  local path = common.chains_root(relpath)
  local txt = common.read_file(path)
  if not txt then r.ShowMessageBox("Kette nicht gefunden:\n"..path,"DF95 FXBus",0) return end
  local ok, err = common.write_chunk_fxchain(tr, txt, append)
  if not ok then r.ShowMessageBox("Fehler beim Laden:\n"..(err or "?"),"DF95 FXBus",0) end
end

local function show_menu()
  local items = {"# DF95 FX Bus","Add Parallel FX Bus",">FX Chains"}
  for _,c in ipairs(chains) do table.insert(items, c[0] or c[1]) end
  table.insert(items,"<")
  local menu = table.concat(items, "|")
  gfx.init("DF95 FX Bus",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx == 1 then add_parallel_fx_bus(); return end
  if idx >= 3 and idx <= 2+#chains then
    local rel = chains[idx-2][2]
    apply_chain_to_fxbus(rel, false)
  end
end

-- Mod key quick add
local function mod_pressed()
  if r.JS_VKeys_GetState then
    local s = r.JS_VKeys_GetState(0)
    if s then
      local function p(vk) return s:byte(vk+1)~=0 end
      return p(0x10) or p(0x12) -- SHIFT or ALT
    end
  end
  return false
end

r.PreventUIRefresh(1)
if mod_pressed() then add_parallel_fx_bus() else show_menu() end
r.PreventUIRefresh(-1)
