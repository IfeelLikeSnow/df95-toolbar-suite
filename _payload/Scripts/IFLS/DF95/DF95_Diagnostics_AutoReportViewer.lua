-- DF95_Diagnostics_AutoReportViewer.lua
local sep = package.config:sub(1,1) or "/"
local function join_path(a,b) if a:sub(-1)==sep then return a..b end return a..sep..b end
local function read_file(path) local f,err=io.open(path,"r"); if not f then return nil,err end local c=f:read("*a"); f:close(); return c end
local function path_exists(path) local ok,_,code=os.rename(path,path); if ok then return true end; if code==13 then return true end; return false end
local function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end
local function main()
  reaper.ShowConsoleMsg("")
local base = reaper.GetResourcePath():gsub("\\","/")

-- Feature flag gate (V3): diagnostics can be disabled via Support/DF95_Config.json
do
  local okc, Core = pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
  if okc and type(Core) == "table" and type(Core.get_config) == "function" then
    local cfg = Core.get_config()
    if cfg and cfg.features and cfg.features.enable_diagnostics == false then
      if Core.log_info then Core.log_info("Diagnostics disabled by config: " .. (debug.getinfo(1,'S').source or '?')) end
      return
    end
  end
end
  local resource=reaper.GetResourcePath()
  msg("=== DF95 Diagnostics Auto Report Viewer ===")
  msg("Resource Path: "..resource)
  local support_root=join_path(resource,"Support")
  local d2=join_path(support_root,"DF95_Diagnostics2")
  local d3=join_path(support_root,"DF95_Diagnostics3")
  local files={
    {label="Diagnostics 2.0 TXT",  path=join_path(d2,"DF95_Diagnostics_Report.txt")},
    {label="Diagnostics 2.0 JSON", path=join_path(d2,"DF95_Diagnostics_Report.json")},
    {label="FixWave Report TXT",   path=join_path(d2,"DF95_FixWave_Report.txt")},
    {label="Diagnostics 3.0 TXT",  path=join_path(d3,"DF95_Diagnostics3_Report.txt")},
    {label="Diagnostics 3.0 JSON", path=join_path(d3,"DF95_Diagnostics3_Report.json")},
  }
  local any=false
  for _,e in ipairs(files) do
    if path_exists(e.path) then
      any=true
      local c,err=read_file(e.path)
      msg("------------------------------------------------------------")
      msg(e.label.."  ["..e.path.."]")
      msg("------------------------------------------------------------")
      if c then msg(c) else msg("!! Konnte Datei nicht lesen: "..tostring(err)) end
      msg("")
    end
  end
  if not any then
    reaper.ShowMessageBox(
      "Keine DF95 Diagnostics-Reports gefunden.\n\nErwartete Pfade z.B.:\n  "..
      d2..sep.."DF95_Diagnostics_Report.txt\n  "..d3..sep.."DF95_Diagnostics3_Report.txt",
      "DF95 Diagnostics Auto Report Viewer",0)
  else
    reaper.ShowMessageBox("Reports wurden in die REAPER-Konsole geschrieben.\nView → Show console log",
      "DF95 Diagnostics Auto Report Viewer",0)
  end
end
reaper.Undo_BeginBlock(); main(); reaper.Undo_EndBlock("DF95 Diagnostics – Auto Report Viewer", -1)
