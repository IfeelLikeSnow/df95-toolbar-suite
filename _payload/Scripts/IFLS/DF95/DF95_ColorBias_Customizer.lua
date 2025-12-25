if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Color Bias Customizer (create/edit artist bias profiles)
-- @version 1.0
-- @author DF95
-- @about Simple editor for DF95_ColorBias_Profiles.json (EQ tilt + saturation string)
local r = reaper
local sep = package.config:sub(1,1)
local base = (debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")") or ""
local readjson = dofile(base.."DF95_ReadJSON.lua")
local prof_path = base.."DF95_ColorBias_Profiles.json"

local profiles = readjson(prof_path)
if type(profiles)~="table" then profiles = {} end

local keys = {}
for k,_ in pairs(profiles) do table.insert(keys, k) end
table.sort(keys)
if #keys == 0 then table.insert(keys, "None") profiles["None"] = {eq={}, saturation="", description="Neutral"} end

local idx = 1
local sel_key = keys[idx]
local function ensure_key(k)
  profiles[k] = profiles[k] or {eq={}, saturation="", description=""}
end

-- Editable fields (simple: 5 common frequencies)
local freqs = {60, 200, 500, 3000, 12000, 14000}
local gains = {}
local sat = ""
local desc = ""

local function load_profile(k)
  ensure_key(k)
  local p = profiles[k]
  for i,f in ipairs(freqs) do
    local val = 0.0
    if p.eq and p.eq[tostring(f)] then val = tonumber(p.eq[tostring(f)]) or 0.0 end
    gains[i] = val
  end
  sat  = p.saturation or ""
  desc = p.description or ""
end

local function save_profile(k)
  ensure_key(k)
  local p = profiles[k]
  p.eq = {}
  for i,f in ipairs(freqs) do
    if gains[i] and math.abs(gains[i])>0.0001 then
      p.eq[tostring(f)] = gains[i]
    end
  end
  p.saturation = sat
  p.description = desc
  -- write file
  local f = io.open(prof_path, "wb")
  if f then
    -- simple JSON serializer
    local function esc(s) return (s:gsub('\\','\\\\'):gsub('"','\\"')) end
    f:write('{\n')
    local firstP = true
    for name,prof in pairs(profiles) do
      if not firstP then f:write(',\n') end
      firstP = false
      f:write(string.format('  "%s": {', esc(name)))
      -- eq
      f:write('\n    "eq": {')
      local firstE = True
      for fk,gv in pairs(prof.eq or {}) do
        if not firstE then f:write(',') end
        firstE = false
        f:write(string.format('\n      "%s": %g', fk, gv))
      end
      if not firstE then f:write('\n    }') else f:write('}') end
      -- saturation
      f:write(string.format(',\n    "saturation": "%s"', esc(prof.saturation or "")))
      f:write(string.format(',\n    "description": "%s"', esc(prof.description or "")))
      f:write('\n  }')
    end
    f:write('\n}\n')
    f:close()
  end
end

load_profile(sel_key)

-- GUI
local W,H = 520, 280
gfx.init("DF95 Color Bias Customizer", W, H, 0)
local function draw()
  gfx.setfont(1, "Arial", 16)
  gfx.x, gfx.y = 12, 10; gfx.drawstr("Profile: "..sel_key)
  gfx.setfont(1, "Arial", 13)
  gfx.x, gfx.y = 12, 40; gfx.drawstr("Saturation (plugin name): "..sat)
  gfx.x, gfx.y = 12, 65; gfx.drawstr("Description: "..desc)

  gfx.x, gfx.y = 12, 95; gfx.drawstr("EQ Gains (dB):")
  for i,f in ipairs(freqs) do
    local x = 12 + (i-1)*80
    gfx.x, gfx.y = x, 120; gfx.drawstr(string.format("%5d Hz: %+4.1f", f, gains[i] or 0.0))
  end
  gfx.x, gfx.y = 12, 200; gfx.drawstr("[Up/Down] select profile  |  [E/D] edit saturation/description  |  [1..6] adjust EQ (Shift=+0.5, no Shift=+0.1)  |  [S] save  |  [N] new | [Esc] quit")
end

local function main()
  local ch = gfx.getchar()
  if ch == 27 then return end -- Esc
  if ch == 0 then
    draw(); r.defer(main); return
  end

  if ch == 30064 then -- Up
    idx = (idx - 2) % #keys + 1; sel_key = keys[idx]; load_profile(sel_key)
  elseif ch == 1685026670 or ch == 1685026671 then -- Down (varies OS)
    idx = (idx) % #keys + 1; sel_key = keys[idx]; load_profile(sel_key)
  elseif ch == string.byte('E') or ch == string.byte('e') then
    local rv, s = r.GetUserInputs("Saturation", 1, "Plugin name (e.g. VST3: ToTape8 (Airwindows))", sat or "")
    if rv then sat = s end
  elif ch == string.byte('D') or ch == string.byte('d') then
    local rv, s = r.GetUserInputs("Description", 1, "Describe this bias", desc or "")
    if rv then desc = s end
  elseif ch >= string.byte('1') and ch <= string.byte('6') then
    local i = ch - string.byte('0')
    local step = r.JS_Mouse_GetState and (r.JS_Mouse_GetState(16) ~= 0 and 0.5 or 0.1) or 0.1 -- Shift=0.5
    gains[i] = (gains[i] or 0.0) + step
  elseif ch == string.byte('S') or ch == string.byte('s') then
    save_profile(sel_key)
    r.ShowMessageBox("Saved profile: "..sel_key, "DF95", 0)
  elseif ch == string.byte('N') or ch == string.byte('n') then
    local rv, name = r.GetUserInputs("New Profile", 1, "Profile name", "")
    if rv and name ~= "" then
      profiles[name] = {eq={}, saturation="", description=""}
      keys[#keys+1] = name; table.sort(keys)
      for i,k in ipairs(keys) do if k==name then idx=i end end
      sel_key = name; load_profile(sel_key)
    end
  end

  draw(); r.defer(main)
end

draw(); r.defer(main)