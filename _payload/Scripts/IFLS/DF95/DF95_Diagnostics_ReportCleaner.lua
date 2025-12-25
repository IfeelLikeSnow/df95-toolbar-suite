-- DF95_Diagnostics_ReportCleaner.lua
local sep = package.config:sub(1,1) or "/"
local function join_path(a,b) if a:sub(-1)==sep then return a..b end return a..sep..b end
local function path_exists(path) local ok,_,code=os.rename(path,path); if ok then return true end; if code==13 then return true end; return false end
local function delete_files_in_dir(dir)
  if not path_exists(dir) then return 0 end
  local n,i=0,0
  while true do
    local f=reaper.EnumerateFiles(dir,i); if not f then break end
    os.remove(join_path(dir,f)); n=n+1; i=i+1
  end
  return n
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
  local confirm=reaper.ShowMessageBox(
    "DF95 Diagnostics Report Cleaner\n\nDies wird ALLE Dateien in folgenden Ordnern löschen:\n\n  "..
    d2.."\n  "..d3.."\n  "..bundle..
    "\n\nScripte/JSFX werden nicht gelöscht.\nFortfahren?",
    "DF95 Diagnostics – Report Cleaner",4)
  if confirm~=6 then return end
  local c2,c3,cb = delete_files_in_dir(d2), delete_files_in_dir(d3), delete_files_in_dir(bundle)
  local m="DF95 Diagnostics – Report Cleaner abgeschlossen.\n\nGelöschte Dateien:\n"..
          "  DF95_Diagnostics2 : "..tostring(c2).."\n"..
          "  DF95_Diagnostics3 : "..tostring(c3).."\n"..
          "  UploadBundle      : "..tostring(cb).."\n\nOrdner bleiben erhalten."
  reaper.ShowMessageBox(m,"DF95 Diagnostics – Report Cleaner",0)
end
reaper.Undo_BeginBlock(); main(); reaper.Undo_EndBlock("DF95 Diagnostics – Report Cleaner", -1)
