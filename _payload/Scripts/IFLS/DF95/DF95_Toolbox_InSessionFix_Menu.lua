if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Toolbox – In-Session Fix Menu
-- @version 1.0
-- @author DF95
local r = reaper
local sep = package.config:sub(1,1)
local base = (debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")") or ""
local function run(name)
  local cmd = r.NamedCommandLookup(("_RS")..name) -- this is placeholder for ReaPack IDs; fallback next:
  if cmd == 0 then
    -- try direct load
    dofile(base..name..".lua")
  else
    r.Main_OnCommand(cmd, 0)
  end
end
local menu = "|DF95 In-Session Fixes||SafetyLast (Limiter → End)|GainStage (Pre/Post Gain)|LiveMode (Toggle Heavy)||"
gfx.init("DF95 Fix", 0,0,0,0,0)
local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
local idx = gfx.showmenu(menu); gfx.quit()
if idx == 2 then dofile(base.."DF95_InSessionFix_SafetyLast.lua")
elseif idx == 3 then dofile(base.."DF95_InSessionFix_GainStage.lua")
elseif idx == 4 then dofile(base.."DF95_InSessionFix_LiveMode.lua")
end