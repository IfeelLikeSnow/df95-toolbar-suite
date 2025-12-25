if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Parallel FX Presets – Menu
-- @version 1.1
-- @author DF95
-- @about Create prewired parallel buses with typical IDM/creative setups.

local r = reaper
local sep = package.config:sub(1,1)

local function create_bus(name)
  r.Main_OnCommand(40001, 0) -- new track
  local tr = r.GetSelectedTrack(0,0)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function send_100(src, dst)
  local sid = r.CreateTrackSend(src, dst)
  r.SetTrackSendInfo_Value(src, 0, sid, "I_SENDMODE", 0) -- post
  r.SetTrackSendInfo_Value(src, 0, sid, "D_VOL", 1.0)
end

local function fx_available(name)
  local q = reaper.TrackFX_AddByName(reaper.GetMasterTrack(0), name, false, 1)
  return q >= 0
end
local function add_fx_fallback(tr, primary, fallback)
  local fx = reaper.TrackFX_AddByName(tr, primary, false, -1000)
  if fx < 0 and fallback and fallback ~= "" then
    fx = reaper.TrackFX_AddByName(tr, fallback, false, -1000)
  end
  return fx
end
local function phase_autocheck(bus)
  -- Insert Scope if not present and remind user to flip if large phase error observed (UI side)
  reaper.TrackFX_AddByName(bus, "JS: Phase Meter/Scope", false, -1000)
end

local function add_fx(tr, name)
  return r.TrackFX_AddByName(tr, name, false, -1000)
end

local function build_idm_split(bus)
  add_fx(bus, "VST3: ReaEQ (Cockos)")
  add_fx(bus, "VST3: Pressure4 (Airwindows)")
  add_fx(bus, "VST3: ToTape8 (Airwindows)")
  add_fx(bus, "JS: Phase Meter/Scope")
end

local function build_analog_glue(bus)
  add_fx(bus, "VST3: ToTape8 (Airwindows)")
  add_fx(bus, "VST3: BussColors4 (Airwindows)")
  add_fx(bus, "VST3: Pressure4 (Airwindows)")
end

local function build_granular_parallel(bus)
  add_fx_fallback(bus, "VST3: PaulXStretch (PaulXStretch)", "JS: LOSER/time_frequency_stretch")
  add_fx_fallback(bus, "VST3: Spaced Out (BABY Audio)", "JS: Delay/varying_delay")
  add_fx(bus, "JS: Phase Meter/Scope")
end

local function build_creative_fx(bus)
  add_fx_fallback(bus, "VST3: Magic Dice (BABY Audio)", "JS: Delay/pingpong_pan")
  add_fx_fallback(bus, "VST3: Warp (BABY Audio)", "JS: chorus")
  add_fx(bus, "VST3: PurestDrive (Airwindows)")
end

local items = {
  "# DF95 Parallel FX Presets",
  "Create: IDM Split",
  "Create: Analog Glue",
  "Create: Granular Parallel",
  "Create: Creative FX",
  "-",
  "Create: Empty Parallel Bus"
}

gfx.init("DF95 Parallel FX Presets",0,0,0,0,0)
local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
local idx = gfx.showmenu(table.concat(items,"|")); gfx.quit()
if idx <= 1 then return end

local sel = r.CountSelectedTracks(0); if sel == 0 then r.ShowMessageBox("Bitte Quell-Tracks auswählen.", "DF95", 0) return end
r.Undo_BeginBlock()
local bus = create_bus("[DF95 Parallel FX]")
for i=0, sel-1 do send_100(r.GetSelectedTrack(0,i), bus) end

if idx == 2 then build_idm_split(bus)
elseif idx == 3 then build_analog_glue(bus)
elseif idx == 4 then build_granular_parallel(bus)
elseif idx == 5 then build_creative_fx(bus)
end
r.Undo_EndBlock("DF95 Parallel FX Preset created", -1)