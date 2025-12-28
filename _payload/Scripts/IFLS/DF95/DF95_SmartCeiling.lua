if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description SmartCeiling 2.0 (robust ceiling + LA/Release + FlowBus)
-- @version 2.1
-- @author DF95
-- Sets ReaLimit ceiling robustly (VST2/VST3), adjusts Lookahead/Release per mode, publishes state via FlowBus.
local r = reaper
local sep = package.config:sub(1,1)
local FB = dofile((debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")").."DF95_FlowBus.lua")

-- Modes: { ceiling_dBTP, lookahead_ms, release_ms }
local modes = {
  ["Release (-0.1 dBTP)"]       = { -0.1, 1.0, 100 },
  ["Sample/Loop (-0.3 dBTP)"]   = { -0.3, 2.0, 140 },
  ["Generative (-0.5 dBTP)"]    = { -0.5, 2.5, 160 },
  ["Live (-0.8 dBTP)"]          = { -0.8, 1.5, 120 },
  ["Streaming (-1.0 dBTP)"]     = { -1.0, 2.0, 200 }
}

local function ensure_realimit_on_master()
  local mst = r.GetMasterTrack(0)
  local idx = -1
  for i=0, r.TrackFX_GetCount(mst)-1 do
    local _, nm = r.TrackFX_GetFXName(mst, i, "")
    if (nm or ""):lower():find("realimit") then idx = i end
  end
  if idx < 0 then
    idx = r.TrackFX_AddByName(mst, "VST3: ReaLimit (Cockos)", false, -1000)
    if idx < 0 then idx = r.TrackFX_AddByName(mst, "VST: ReaLimit (Cockos)", false, -1000) end
  end
  return mst, idx
end

-- True Peak estimate helper
local function get_true_peak_dbfs(mst)
  local ch0 = reaper.Track_GetPeakInfo and reaper.Track_GetPeakInfo(mst, 0) or 0.0
  local ch1 = reaper.Track_GetPeakInfo and reaper.Track_GetPeakInfo(mst, 1) or ch0
  local peak = math.max(ch0 or 0.0, ch1 or 0.0)
  if peak <= 0 then return -120.0 end
  return 20*math.log(peak,10)

end

local function set_param_db(track, fx, contains, dB, defaultMin, defaultMax)
  local pc = r.TrackFX_GetNumParams(track, fx)
  for p=0, pc-1 do
    local _, pn = r.TrackFX_GetParamName(track, fx, p, "")
    if (pn or ""):lower():find(contains) then
      local _, minV, maxV = r.TrackFX_GetParamEx(track, fx, p)
      local min = minV or (defaultMin or -12.0)
      local max = maxV or (defaultMax or 0.0)
      local norm = (dB - min) / (max - min)
      if norm < 0 then norm = 0 elseif norm > 1 then norm = 1 end
      r.TrackFX_SetParamNormalized(track, fx, p, norm)
      return true
    end
  end
  return false
end

local function set_param_ms(track, fx, contains, ms, defaultMin, defaultMax)
  local pc = r.TrackFX_GetNumParams(track, fx)
  for p=0, pc-1 do
    local _, pn = r.TrackFX_GetParamName(track, fx, p, "")
    if (pn or ""):lower():find(contains) then
      local _, minV, maxV = r.TrackFX_GetParamEx(track, fx, p)
      local min = minV or (defaultMin or 0.0)
      local max = maxV or (defaultMax or 50.0)
      local norm = (ms - min) / (max - min)
      if norm < 0 then norm = 0 elseif norm > 1 then norm = 1 end
      r.TrackFX_SetParamNormalized(track, fx, p, norm)
      return true
    end
  end
  return false
end

local function show_menu()
  local items = {"# DF95 SmartCeiling 2.0"}
  for k,_ in pairs(modes) do table.insert(items, k) end
  local menu = table.concat(items, "|")
  gfx.init("DF95 SmartCeiling",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx <= 1 then return end
  local key = items[idx]
  local cfg = modes[key]
  if not cfg then return end
  local tp, la, rel = cfg[1], cfg[2], cfg[3]

  r.Undo_BeginBlock()
  local mst, fx = ensure_realimit_on_master()
  if fx >= 0 then
    set_param_db(mst, fx, "ceil", tp, -18, 0)          -- Ceiling (dBTP)
    set_param_ms(mst, fx, "look", la, 0.0, 20.0)       -- Lookahead (ms)
    set_param_ms(mst, fx, "release", rel, 10.0, 1000)  -- Release (ms)
  end
  FB.set("Ceiling", key)
-- TP_SAFETY
local TP_HARD = (FB.get("TP_HARD","0")=="1") -- TP_HARD_MODE
local tp = get_true_peak_dbfs(mst)
if tp > -0.3 then
  local step = TP_HARD and 0.3 or math.min(0.3, tp + 0.3)
  set_param_db(mst, fx, "ceil", -step, -18, 0)
  local tp2 = get_true_peak_dbfs(mst)
  FB.set("TP_Status", (tp2 <= -0.3) and "OK" or string.format("WARN (%.1f dBFS)", tp2))
end
-- PROFILE_BIND_APPLIED
local cat = FB.get("BiasCategory", "")
if cat=="Artists" then
  set_param_db(mst, fx, "ceil", -0.5, -18, 0)
elseif cat=="Neutral" then
  set_param_db(mst, fx, "ceil", -0.1, -18, 0)
end
  r.Undo_EndBlock("DF95 SmartCeiling: "..key, -1)
end

show_menu()