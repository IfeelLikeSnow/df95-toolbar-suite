
-- @description Validator 2.0 (Smoke Test)
-- @version 1.0
local r = reaper
local function ok(p) local f=io.open(p,"rb"); if f then f:close(); return true end end
local res = r.GetResourcePath()
local missing = {}
local function check(path) if not ok(path) then missing[#missing+1]=path end end
-- Simple checks
check(res.."/Menus/DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet")
check(res.."/Menus/DF95_CoToolbar_Context.ReaperMenuSet")
check(res.."/Scripts/IFLS/DF95/Design/DF95_Slice_Menu.lua")
if #missing>0 then
  r.ShowMessageBox("Missing files:\n"..table.concat(missing,"\n"),"DF95 Validator",0)
else
  r.ShowConsoleMsg("[DF95] Validator: OK\n")
end
