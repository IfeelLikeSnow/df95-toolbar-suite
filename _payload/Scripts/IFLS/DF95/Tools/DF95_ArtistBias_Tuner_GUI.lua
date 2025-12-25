-- @description Artist Bias Tuner (weights GUI)
-- @version 1.0
-- @about Adjust weights in Data/DF95/DF95_ArtistBias.json with sliders.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local json_fn = res..sep.."Data"..sep.."DF95"..sep.."DF95_ArtistBias.json"

local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function writeall(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s); f:close(); return true end
local raw = readall(json_fn)
if not raw then r.ShowMessageBox("ArtistBias.json nicht gefunden.","DF95 Bias Tuner",0) return end
if not r.JSON_Decode then r.ShowMessageBox("JSON-API benötigt (REAPER 6.82+).","DF95 Bias Tuner",0) return end
local cfg = r.JSON_Decode(raw)
cfg.weights = cfg.weights or {}

local keys = {}
for k,_ in pairs(cfg.weights) do keys[#keys+1]=k end
table.sort(keys)

local W,H = 720, 24 + #keys*26 + 60
gfx.init("DF95 Bias Tuner", W, H)
local sliders = {}
for i,k in ipairs(keys) do sliders[i] = cfg.weights[k] or 1 end

local function draw()
  gfx.set(0.1,0.1,0.12,1); gfx.rect(0,0,W,H,1)
  gfx.set(1,1,1,1)
  gfx.x,gfx.y = 16,8; gfx.drawstr("DF95 Artist Bias Tuner  –  ENTER: speichern, ESC: abbrechen")
  local y = 32
  for i,k in ipairs(keys) do
    gfx.x,gfx.y = 16,y; gfx.drawstr(k)
    local x2 = 260
    local w = 320; local h = 16
    gfx.rect(x2,y,w,h,0)
    local v = math.max(0, math.min(10, sliders[i] or 0))
    local fill = (v/10)*w
    gfx.rect(x2,y,fill,h,1)
    gfx.x,gfx.y = x2 + w + 12, y; gfx.drawstr(string.format("%.1f", v))
    y = y + 26
  end
end

local function hit_slider(mx,my)
  local y = 32
  for i,_ in ipairs(keys) do
    local x2=260; local w=320; local h=16
    if mx>=x2 and mx<=x2+w and my>=y and my<=y+h then return i,x2,w end
    y = y + 26
  end
  return nil
end

local function loop()
  draw()
  local ch = gfx.getchar()
  if ch == 27 then return end
  if ch == 13 then
    for i,k in ipairs(keys) do cfg.weights[k] = sliders[i] end
    local out = r.JSON_Encode(cfg)
    writeall(json_fn, out)
    r.ShowMessageBox("Bias gespeichert.","DF95 Bias Tuner",0)
    return
  end
  local cap = gfx.mouse_cap
  if cap&1 == 1 then
    local i,x2,w = hit_slider(gfx.mouse_x, gfx.mouse_y)
    if i then
      local rel = math.max(0, math.min(1, (gfx.mouse_x - x2)/w))
      sliders[i] = rel*10
    end
  end
  reaper.defer(loop)
end

loop()
