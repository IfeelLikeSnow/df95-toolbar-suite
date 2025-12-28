if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Validator 2.1 (GUI – Ampel + Fix)
-- @version 2.2
-- @author DF95
-- @about Visual dashboard for system validation; can run Validator 2.0 and show status.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local report = res..sep.."DF95_Validation_Report.txt"

local function run_scan()
  dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")").."DF95_PostInstall_Validator2.lua")
end

local status = {core="?", chains="?", plugins="?"}
local lines = {}
local f = io.open(report,"rb")
if f then
  for l in f:lines() do lines[#lines+1] = l end
  f:close()
end

for _,l in ipairs(lines):
  if l:find("%[OK%] Scripts") then status.core = "OK" end
  if l:find("Chains"..sep) then status.chains = (l:find("%[OK%]") and "OK" or (status.chains or "?")) end
  if l:find("%[CRITICAL PLUGINS%]") then status.plugins = "?" end

-- simple GUI
local W,H=520,240
gfx.init("DF95 Validator 2.1", W,H, 0)
local function lamp(x,y,color)
  if color=="OK" then gfx.set(0.2,0.8,0.2,1)
  elseif color=="WARN" then gfx.set(1.0,0.8,0.2,1)
  elseif color=="MISS" then gfx.set(0.9,0.2,0.2,1)
  else gfx.set(0.5,0.5,0.5,1) end
  gfx.circle(x,y,10,1,1)
end

local function draw()
  gfx.set(0.12,0.12,0.12,1); gfx.rect(0,0,W,H,1)
  gfx.set(1,1,1,1); gfx.setfont(1,"Arial",16)
  gfx.x,gfx.y=20,20; gfx.drawstr("DF95 System Validation")
  gfx.setfont(1,"Arial",13)
  gfx.x,gfx.y=40,70; gfx.drawstr("Core Scripts:"); lamp(160,75,status.core)
  gfx.x,gfx.y=40,110; gfx.drawstr("Chains:"); lamp(160,115,status.chains)
  gfx.x,gfx.y=40,150; gfx.drawstr("Critical Plugins:"); lamp(160,155,status.plugins)
  gfx.x,gfx.y=300,70; gfx.drawstr("[R] Run Scan  |  [O] Open Report  |  [F] Fix (open links) |  [W] Write Fallbacks  | [Esc] Close")
end

local function loop()
  local ch=gfx.getchar()
  if ch==27 then return end
  if ch==string.byte('R') or ch==string.byte('r') then run_scan() end
  if ch==string.byte('O') or ch==string.byte('o') then reaper.CF_ShellExecute(report) end
  draw(); gfx.update(); reaper.defer(loop)
end

draw(); reaper.defer(loop)

-- fix: open vendor pages (placeholder links)
local function open_links()
  reaper.CF_ShellExecute("https://www.tbproaudio.de/products/dpmeter5")
  reaper.CF_ShellExecute("https://youlean.co/youlean-loudness-meter/")
  reaper.CF_ShellExecute("https://www.airwindows.com/")
end
local function loop2()
  local ch=gfx.getchar()
  if ch==27 then return end
  if ch==string.byte('F') or ch==string.byte('f') then open_links() end
  draw(); gfx.update(); reaper.defer(loop2)
end
gfx.quit(); gfx.init("DF95 Validator 2.2", 520,240,0); draw(); reaper.defer(loop2)


-- hook W
local function loop3()
  local ch=gfx.getchar()
  if ch==27 then return end
  if ch==string.byte('W') or ch==string.byte('w') then dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..package.config:sub(1,1)..")").."DF95_Validator_FallbackRebuilder.lua") end
  if ch==string.byte('R') or ch==string.byte('r') then run_scan() end
  if ch==string.byte('O') or ch==string.byte('o') then reaper.CF_ShellExecute(report) end
  draw(); gfx.update(); reaper.defer(loop3)
end
gfx.quit(); gfx.init("DF95 Validator 2.3", 520,240,0); draw(); reaper.defer(loop3)
