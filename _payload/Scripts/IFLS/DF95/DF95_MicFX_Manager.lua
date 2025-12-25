if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Mic FX – CPU‑light loader (expects .fxlist in Scripts/IFLS/MicFX)
-- @version 1.44.0
local r = reaper; local sep=package.config:sub(1,1); local res=r.GetResourcePath(); local base=res..sep.."Scripts"..sep.."IFLS"..sep.."MicFX"..sep
local MICS={"NTG4+","C2","Cortado MK3","Geofon","B1","XM8500","TG-V35S","MD400","CM300","SOMA Ether V2","MCM Telecoil"}
local function menu() local t={"||Mic FX:"}; for _,m in ipairs(MICS) do t[#t+1]=m end; return table.concat(t,"|") end
local function add_chain(tr,name) local f=io.open(base..name..".fxlist","r"); if not f then return false end; for l in f:lines() do if l:match("%S") then r.TrackFX_AddByName(tr,l,false,-1) end end; f:close(); return true end
gfx.init("DF95 Mic FX",0,0); gfx.x,gfx.y=gfx.mouse_x,gfx.mouse_y; local idx=gfx.showmenu(menu()); gfx.quit(); if idx<=0 then return end; local mic=MICS[idx]
r.Undo_BeginBlock(); for i=0,r.CountSelectedTracks(0)-1 do add_chain(r.GetSelectedTrack(0,i), mic) end; r.Undo_EndBlock("DF95 Mic FX: "..mic,-1)
