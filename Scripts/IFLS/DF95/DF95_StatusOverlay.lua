if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Status Overlay (dezent, auto-hide, clickable)
-- @version 2.1
-- @author DF95
local r = reaper
local sep = package.config:sub(1,1)
local FB = dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")").."DF95_FlowBus.lua")

local W, H = 420, 110
local ALPHA = 0.78
local FPS = 15
local pin = false
local last_interact = r.time_precise()

local rects = { bias={x=12,y=10,w=280,h=20}, ceil={x=12,y=34,w=280,h=20}, gm={x=12,y=58,w=180,h=20}, pinbtn={x=340,y=10,w=24,h=24} }

local function get_theme()
  local f = r.GetLastColorThemeFile and r.GetLastColorThemeFile() or ""
  return (f:match("([^"..sep.."]+)%.ReaperTheme") or f:match("([^"..sep.."]+)%.ReaperThemeZip") or "Default")
end

local function inside(mx,my, rct) return mx>=rct.x and mx<=rct.x+rct.w and my>=rct.y and my<=rct.y+rct.h end

local function draw()
  gfx.set(0,0,0,0); gfx.rect(0,0,W,H,1)
  gfx.set(0.12,0.12,0.12,ALPHA); gfx.rect(0,0,W,H,1)
  gfx.set(1,1,1,1); gfx.setfont(1,"Arial",14)
  local bias = FB.get("Bias","None"); local ceil=FB.get("Ceiling","None"); local gm=FB.get("GainMatch","Off")
  local theme = get_theme()
  gfx.x,gfx.y=12,10; gfx.drawstr("🎨 Bias: "..bias)
  gfx.x,gfx.y=12,34; gfx.drawstr("🎧 Ceiling: "..ceil)
  local lufs_cur = FB.get("LUFS_Current","")
  local lufs_tgt = FB.get("LUFS_Target","")
  local lufs_dlt = FB.get("LUFS_Delta","")
  gfx.x,gfx.y=12,58; gfx.drawstr("⚖️ GainMatch: "..gm.."   •  Theme: "..theme..(lufs_tgt~="" and ("  •  LUFS: "..lufs_cur.." → "..lufs_tgt.." ("..lufs_dlt..")") or ""))
  local fxcat = FB.get("FXSeedCategory","")
  local seed = FB.get("Seed","")
  if fxcat ~= "" or seed ~= "" then gfx.y = 78; gfx.x = 12; gfx.drawstr("🧬 Seed: "..(seed~="" and seed or "-")..(fxcat~="" and ("  •  Cat: "..fxcat) or "")) end
  -- pin button
  gfx.x,gfx.y=rects.pinbtn.x, rects.pinbtn.y; gfx.drawstr(pin and "📌" or "📍")
end

local function open_menu(script)
  dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")")..script)
end

-- Responsive & positions
local POS = reaper.GetExtState("DF95_FLOW","OverlayPos")
if POS=="" then POS="BL" end -- BL, BR, TL, TR
local function place()
  local _,_,sw,sh = reaper.my_getViewport(0,0,0,0,0,0,0,0,0)
  local x,y = 16, sh - H - 48
  if POS=="BR" then x,y = sw - W - 24, sh - H - 48
  elseif POS=="TL" then x,y = 16, 16
  elseif POS=="TR" then x,y = sw - W - 24, 16 end
  gfx.x,gfx.y = x,y
end
-- Accents & Minimal Mode
local minimal = (reaper.GetExtState("DF95_FLOW","OverlayMinimal")=="1")
local dragging=false, dx=0, dy=0

local function loop()
  local ch=gfx.getchar()
  if ch==string.byte("H") or ch==string.byte("h") then
    minimal = not minimal; reaper.SetExtState("DF95_FLOW","OverlayMinimal", minimal and "1" or "0", false)
  end -- HOTKEYS_H_MINIMAL
  -- Right-drag move
  if (gfx.mouse_cap & 2) == 2 then
    if not dragging then dragging=true; dx=gfx.mouse_x-gfx.x; dy=gfx.mouse_y-gfx.y end
    gfx.x = gfx.mouse_x - dx; gfx.y = gfx.mouse_y - dy
  else dragging=false end
  local now = r.time_precise()
  local ch = gfx.getchar()
  if ch == 27 then gfx.quit() return end

  local mx,my = gfx.mouse_x, gfx.mouse_y
  if gfx.mouse_cap & 1 == 1 then
    last_interact = now
    if inside(mx,my, rects.pinbtn) then pin = not pin end
    if inside(mx,my, rects.bias) then open_menu("DF95_ColorBias_Manager.lua") end
    if inside(mx,my, rects.ceil) then open_menu("DF95_SmartCeiling.lua") end
    if inside(mx,my, rects.gm) then FB.set("GainMatch", FB.get("GainMatch","Off")=="Off" and "ON" or "Off") end
  end

  if (not pin) and (now - last_interact > 8.0) then
    gfx.quit(); return
  end

  draw(); gfx.update()
  r.defer(loop)
end

gfx.init("DF95 Status", W, H, 0)
place()
loop()