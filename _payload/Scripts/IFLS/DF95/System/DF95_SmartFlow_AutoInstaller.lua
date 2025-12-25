
-- @description SmartFlow AutoInstaller (v1.56)
-- @version 1.0
local r = reaper; local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function copy(src,dst) local f=io.open(src,"rb"); if not f then return false end local d=f:read("*all"); f:close(); local g=io.open(dst,"wb"); if not g then return false end g:write(d); g:close(); return true end
local function ensure(p) local ok = r.RecursiveCreateDirectory(p,0); return ok~=0 end
-- Guess pack root = script folder - /Scripts/IFLS/DF95/System
local here = debug.getinfo(1,'S').source:sub(2)
local pack = here:gsub("(.*"..sep.."Scripts"..sep.."IFLS"..sep.."DF95)"..sep.."System"..sep..".-$","%1")
if pack==here then r.ShowMessageBox("Pack root nicht gefunden.","DF95 Installer",0) return end
-- Copy Menus
ensure(res..sep.."Menus")
for _,f in ipairs({"DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet","DF95_CoToolbar_Context.ReaperMenuSet","DF95_MicToolbar_Input.ReaperMenuSet","DF95_EditToolbar_Arrange.ReaperMenuSet","DF95_QA_Toolbar_Safety.ReaperMenuSet"}) do
  copy(pack..sep.."Menus"..sep..f, res..sep.."Menus"..sep..f)
end
-- Copy Data & Config
ensure(res..sep.."Data"..sep.."DF95"); ensure(res..sep.."Config")
copy(pack..sep.."Config"..sep.."DF95_MenuRegistry_v156.json", res..sep.."Config"..sep.."DF95_MenuRegistry_v156.json")
-- Done
r.ShowMessageBox("DF95 SmartFlow installiert.\nMenu -> Customize -> Importiere die DF95_* Toolbars.","DF95 Installer",0)

reaper.ShowMessageBox('Hinweis: Bitte einmal DF95_Chain_Indexer_v1.lua ausführen (Chains indizieren).','DF95 Installer',0)
