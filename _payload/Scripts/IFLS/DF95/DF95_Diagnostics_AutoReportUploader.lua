-- DF95_Diagnostics_AutoReportUploader.lua
local sep = package.config:sub(1,1) or "/"
local function join_path(a,b) if a:sub(-1)==sep then return a..b end return a..sep..b end
local function path_exists(path) local ok,_,code=os.rename(path,path); if ok then return true end; if code==13 then return true end; return false end
local function ensure_dir(path) reaper.RecursiveCreateDirectory(path,0) end
local function copy_file(src,dst)
  local f_in,err=io.open(src,"rb"); if not f_in then return false,"cannot open src:"..tostring(err) end
  local data=f_in:read("*a"); f_in:close()
  local dst_dir=dst:match("^(.*"..sep..")"); if dst_dir then ensure_dir(dst_dir) end
  local f_out,err2=io.open(dst,"wb"); if not f_out then return false,"cannot open dst:"..tostring(err2) end
  f_out:write(data); f_out:close(); return true
end
local function main()
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
  local res=reaper.GetResourcePath()
  local support_root=join_path(res,"Support")
  local d2=join_path(support_root,"DF95_Diagnostics2")
  local d3=join_path(support_root,"DF95_Diagnostics3")
  local bundle=join_path(support_root,"DF95_Diagnostics_UploadBundle")
  ensure_dir(bundle)
  local cand={
    {src=join_path(d2,"DF95_Diagnostics_Report.txt"),  name="Diag2_Report.txt"},
    {src=join_path(d2,"DF95_Diagnostics_Report.json"), name="Diag2_Report.json"},
    {src=join_path(d2,"DF95_FixWave_Report.txt"),      name="FixWave_Report.txt"},
    {src=join_path(d3,"DF95_Diagnostics3_Report.txt"), name="Diag3_Report.txt"},
    {src=join_path(d3,"DF95_Diagnostics3_Report.json"),name="Diag3_Report.json"},
  }
  local copied,missing={},{}
  for _,e in ipairs(cand) do
    if path_exists(e.src) then
      local dst=join_path(bundle,e.name)
      local ok,err=copy_file(e.src,dst)
      if ok then table.insert(copied,dst) else table.insert(missing,e.src.." ("..tostring(err)..")") end
    else
      table.insert(missing,e.src.." (nicht gefunden)")
    end
  end
  local m="DF95 Diagnostics – Auto Report Uploader\n\nZielordner:\n  "..bundle.."\n\n"
  if #copied>0 then
    m=m.."Kopierte Dateien:\n"; for _,p in ipairs(copied) do m=m.."  - "..p.."\n" end; m=m.."\n"
  else
    m=m.."Es konnten keine Diagnostics-Dateien kopiert werden.\n\n"
  end
  if #missing>0 then
    m=m.."Fehlende/Problem-Dateien:\n"; for _,p in ipairs(missing) do m=m.."  - "..p.."\n" end
  end
  reaper.ShowMessageBox(m,"DF95 Diagnostics – Auto Report Uploader",0)
end
reaper.Undo_BeginBlock(); main(); reaper.Undo_EndBlock("DF95 Diagnostics – Auto Report Uploader", -1)
