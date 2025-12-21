-- @description Seed-Lock Toggle (ExtState)
local r=reaper; local v=r.GetExtState("DF95","SEED_LOCK");
local nv=(v=="1") and "0" or "1"; r.SetExtState("DF95","SEED_LOCK",nv,true);
r.ShowMessageBox("Seed-Lock: "..((nv=="1") and "ON" or "OFF"),"DF95",0)
