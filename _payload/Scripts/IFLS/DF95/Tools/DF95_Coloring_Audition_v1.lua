-- @description Coloring Audition (cycle & report)
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local loader = dofile(res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_FXChain_Loader.lua")
local common = dofile(res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."Tools"..sep.."DF95_Audition_Common.lua")
local index_json = res..sep.."Data"..sep.."DF95"..sep.."DF95_Coloring_Index.json"
local list = common.list_from_index(index_json, "Coloring")
local report_dir = res..sep.."Data"..sep.."DF95"..sep.."Reports"
reaper.RecursiveCreateDirectory(report_dir,0)
local rep = {}
rep[#rep+1] = "[DF95] Coloring Audition Report"
if #list==0 then r.ShowMessageBox("Keine Coloring-Chains gefunden.","DF95",0) return end
if r.CountSelectedTracks(0)==0 then r.Main_OnCommand(40296,0) end
for _,fp in ipairs(list) do
  loader(fp, true)
  if r.GetPlayState()==0 then r.OnPlayButton() end
  reaper.Sleep(350)
  rep[#rep+1] = ("Loaded: %s"):format(fp:gsub(res..sep,""))
end
local out = report_dir..sep.."Coloring_Audition_"..os.date("!%Y%m%d_%H%M%S")..".txt"
local f=io.open(out,"wb"); f:write(table.concat(rep,"\n")); f:close()
r.ShowMessageBox("Audition fertig.\nReport: "..out, "DF95", 0)
