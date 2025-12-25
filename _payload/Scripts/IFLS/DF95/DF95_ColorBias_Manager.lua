if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Color Bias Manager (manual dropdown)
-- @version 2.1
-- @author DF95
-- @about Loads EQ tilt and optional saturation on [Coloring Bus] or Master (manual).
local r = reaper
local sep = package.config:sub(1,1)
local base = (debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")") or ""
local profiles = dofile(base.."DF95_ReadJSON.lua")((base.."DF95_ColorBias_Profiles.json"))
local FB = dofile(base.."DF95_FlowBus.lua")
-- Bias history (last 5)
local hist_path = base.."DF95_ColorBias_History.json"
local function load_hist()
  local f=io.open(hist_path,"rb"); if not f then return {} end; local s=f:read("*all"); f:close()
  local ok,t = pcall(function() return assert(load("return "..s))() end); if ok and type(t)=="table" then return t end; return {}
end
local function save_hist(h)
  local f=io.open(hist_path,"wb"); if not f then return end; f:write("{" )
  local first=true
  for i,name in ipairs(h) do
    if not first then f:write(",") end; first=false; f:write(string.format('["%d"]="%s"',i,name))
  end
  f:write("}"); f:close()
end
local function push_hist(name)
  local h = load_hist()
  table.insert(h,1,name); while #h>5 do table.remove(h) end; save_hist(h)
end
local function export_user_profiles()
  local src = base.."DF95_ColorBias_Profiles.json"
  local ok, dest = reaper.GetUserInputs("Export Profiles", 1, "Export to path (.json)", src)
  if ok and dest and dest ~= "" then
    local a=io.open(src,"rb"); if not a then return end; local d=a:read("*all"); a:close()
    local b=io.open(dest,"wb"); if not b then return end; b:write(d); b:close()
    reaper.ShowMessageBox("Exported to:\n"..dest, "DF95", 0)
  end
end
local function import_user_profiles()
  local ok, src = reaper.GetUserInputs("Import Profiles", 1, "Import from path (.json)", "")
  if ok and src and src ~= "" then
    local a=io.open(src,"rb"); if not a then return end; local d=a:read("*all"); a:close()
    local b=io.open(base.."DF95_ColorBias_Profiles.json","wb"); if not b then return end; b:write(d); b:close()
    reaper.ShowMessageBox("Imported profiles from:\n"..src, "DF95", 0)
  end
end

-- DF95 BiasEngine v2 helpers
local function remove_existing_bias_fx(tr)
  for i=reaper.TrackFX_GetCount(tr)-1,0,-1 do
    local _, nm = reaper.TrackFX_GetFXName(tr, i, "")
    if (nm or ""):find("%[DF95 Bias%]") then reaper.TrackFX_Delete(tr, i) end
  end
end

local function ensure_reaEQ(tr)
  for i=0,reaper.TrackFX_GetCount(tr)-1 do
    local _,nm = reaper.TrackFX_GetFXName(tr,i,"")
    if (nm or ""):lower():find("reaeq") then return i end
  end
  local fx = reaper.TrackFX_AddByName(tr, "VST3: ReaEQ (Cockos)", false, -1000)
  if fx < 0 then fx = reaper.TrackFX_AddByName(tr, "VST: ReaEQ (Cockos)", false, -1000) end
  return fx
end

local function set_peak_band(tr, fx, bandIndex, freq, gain_db, q)
  -- ReaEQ uses 5 params per band: Enable, Freq, Gain, Q, Type
  local o = bandIndex*5
  reaper.TrackFX_SetParamNormalized(tr, fx, o+0, 1)        -- Enable
  reaper.TrackFX_SetParam(tr, fx, o+1, freq)               -- Freq Hz
  reaper.TrackFX_SetParam(tr, fx, o+2, gain_db)            -- Gain dB
  reaper.TrackFX_SetParam(tr, fx, o+3, q or 0.7)           -- Q
  reaper.TrackFX_SetParamNormalized(tr, fx, o+4, 0.25)     -- Type≈Peak
end

local function add_tag_to_last_fx(tr)
  local last = reaper.TrackFX_GetCount(tr)-1
  if last >= 0 then
    local rv, nm = reaper.TrackFX_GetFXName(tr, last, "")
    reaper.TrackFX_SetNamedConfigParm(tr, last, "renamed_name", (nm or "").." [DF95 Bias]")
  end
end

local function adaptive_q(gain_db)
  local a = math.abs(gain_db or 0)
  if a <= 0.8 then return 0.5
  elseif a <= 1.5 then return 0.7
  elseif a <= 3.0 then return 0.9
  else return 1.1 end
end

local function ensure_track(name)
  for i=0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0,i)
    local _, nm = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if nm == name then return tr end
  end
  return r.GetMasterTrack(0)
end

local function add_eq(tr, freq, gain_db)
  -- ReaEQ instance; last slot
  local fx = r.TrackFX_AddByName(tr, "VST: ReaEQ (Cockos)", false, -1000)
  if fx < 0 then fx = r.TrackFX_AddByName(tr, "VST3: ReaEQ (Cockos)", false, -1000) end
  if fx < 0 then return end
  -- Create a single band (peak) and set Freq/Gain/Q
  -- Parameter mapping differs; we set via named params when available
  local pcount = r.TrackFX_GetNumParams(tr, fx)
  for p=0, pcount-1 do
    local _, pn = r.TrackFX_GetParamName(tr, fx, p, "")
    local pl = (pn or ""):lower()
    if pl:find("band") and pl:find("gain") then r.TrackFX_SetParam(tr, fx, p, gain_db) end
    if pl:find("band") and (pl:find("freq") or pl:find("frequency")) then r.TrackFX_SetParam(tr, fx, p, freq) end
  end
end

local function add_saturation(tr, name)
  if name == "" then return end
  local fx = r.TrackFX_AddByName(tr, name, false, -1000)
  if fx < 0 then
    -- try Airwindows common variants
    local alt = "VST: "..name.replace("VST3: ","")
    fx = r.TrackFX_AddByName(tr, alt, false, -1000)
  end
end

local function show_menu()
  -- build category maps
  local cats = { Neutral={}, Artists={}, User={} }
  for name,p in pairs(profiles) do
    local c = (p.category or "Artists")
    if not cats[c] then cats[c] = {} end
    table.insert(cats[c], name)
  end
  for _,arr in pairs(cats) do table.sort(arr) end

  local items = {"# DF95 Color Bias","Target: Coloring Bus","Target: Master","-"}
  local map = {}

  local function push_cat(label, arr)
    table.insert(items, ">"..label)
    for _,n in ipairs(arr) do
      table.insert(items, n); map[#items] = n
    end
    table.insert(items, "<") -- close submenu
  end

  push_cat("Neutral", cats.Neutral or {})
  push_cat("Artists", cats.Artists or {})
  push_cat("User", cats.User or {})
  table.insert(items, "-"); table.insert(items, "Open Customizer…"); table.insert(items, "Export Profiles…"); table.insert(items, "Import Profiles…")

  local menu = table.concat(items, "|")
  gfx.init("DF95 Color Bias",0,0,0,0,0)
  local x,y = reaper.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx <= 1 then return end
  local target = "[Coloring Bus]"
  if idx == 2 then target = "[Coloring Bus]" elseif idx == 3 else target = "MASTER" end
  local sel = items[idx]
  if sel == "Open Customizer…" then dofile(base.."DF95_ColorBias_Customizer.lua"); return end
  if sel == "-" or sel:sub(1,1) == ">" or sel == "<" then return end

  local tr = target == "MASTER" and reaper.GetMasterTrack(0) or ensure_track(target)
  reaper.Undo_BeginBlock()
  local prof = profiles[sel]
  for f,g in pairs(prof.eq or {}) do add_eq(tr, tonumber(f), g) end
  add_saturation(tr, prof.saturation or "")
  FB.set("Bias", sel)
  FB.set("BiasCategory", tostring(profiles[sel] and profiles[sel].category or ""))
  reaper.Undo_EndBlock(("DF95 Color Bias: "..sel.." on "..target), -1)
end
  local items = {"# DF95 Color Bias","Target: Coloring Bus","Target: Master","","None (Neutral)","-"}
  local keys = {}
  for k,_ in pairs(profiles) do
    if k ~= "None" then table.insert(keys, k) end
  end
  table.sort(keys)
  for _,k in ipairs(keys) do table.insert(items, k) end
  local menu = table.concat(items, "|")
  gfx.init("DF95 Color Bias",0,0,0,0,0)
  local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
  local idx = gfx.showmenu(menu); gfx.quit()
  if idx <= 1 then return end
  local target = "[Coloring Bus]"
  if idx == 2 then target = "[Coloring Bus]"
  elseif idx == 3 then target = "MASTER" end

  local sel = items[idx]
  if sel == "None (Neutral)" then return end
  if sel == "-" then return end

  local tr = target == "MASTER" and r.GetMasterTrack(0) or ensure_track(target)
  r.Undo_BeginBlock()
  local prof = profiles[sel]
  -- EQ
  for f,g in pairs(prof.eq or {}) do add_eq(tr, tonumber(f), g) end
  -- Saturation
  add_saturation(tr, prof.saturation or "")
  r.Undo_EndBlock(("DF95 Color Bias: "..sel.." on "..target), -1)
end

show_menu()