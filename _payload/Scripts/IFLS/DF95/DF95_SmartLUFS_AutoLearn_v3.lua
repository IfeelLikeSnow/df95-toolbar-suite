-- @description SmartLUFS AutoLearn v3 (Mic-aware Targets + Ceilings)
-- @version 1.0
local r = reaper
local function setp(k,v) r.SetProjExtState(0,"DF95_SMARTCEILING",k,tostring(v)) end
local _, mic = r.GetProjExtState(0,"DF95_MICFX","PROFILE_KEY"); mic = (mic or ""):lower()

local target = -14
if mic:find("geofon") or mic:find("mcm") or mic:find("cm300") then target = -18
elseif mic:find("c2") or mic:find("b1") or mic:find("ntg4") or mic:find("cortado") then target = -14
elseif mic:find("xm8500") or mic:find("tg_v35") or mic:find("md400") then target = -13 end

r.SetProjExtState(0,"DF95_SMARTLUFS","TARGET_LUFS", tostring(target))
setp("Artist","-0.6"); setp("Neutral","-0.2"); setp("FXBus","-0.3")
if target == -18 then setp("Deep","-1.2") end
r.ShowConsoleMsg(string.format("[DF95] SmartLUFS AutoLearn v3 → target %d LUFS for %s\n", target, mic))
