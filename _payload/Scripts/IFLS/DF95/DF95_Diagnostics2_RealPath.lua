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
-- DF95_Diagnostics2_RealPath.lua
-- Diagnostics 2.0 (RealPath-Version) für IFLS / DF95
-- Fester Resource Path:
--   C:\Users\ifeel\AppData\Roaming\REAPER

local REAL_RESOURCE_PATH = "C:\\Users\\ifeel\\AppData\\Roaming\\REAPER"

local sep = package.config:sub(1,1) or "\\"

local function join_path(a,b)
  if a:sub(-1) == sep then return a .. b end
  return a .. sep .. b
end

local function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

local function path_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end
  if code == 13 then return true end
  return false
end

local function ensure_dir(path)
  reaper.RecursiveCreateDirectory(path, 0)
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local c = f:read("*a"); f:close(); return c
end

local function file_size(path)
  local f = io.open(path,"rb"); if not f then return 0 end
  local cur = f:seek(); local sz = f:seek("end"); f:seek("set",cur or 0); f:close()
  return sz or 0
end

local function check_lua(path)
  local chunk, err = loadfile(path)
  if chunk then return true,nil else return false,tostring(err or "unknown") end
end

local function check_jsfx(path)
  local content, err = read_file(path)
  if not content then return false, "cannot_read_file:"..tostring(err) end
  local first = content:match("([^\r\n]*)") or ""
  if first:match("^%s*desc:") then return true,nil end
  return false,"missing_or_invalid_desc_header"
end

local function check_eel(path)
  local sz = file_size(path)
  if sz>0 then return true,nil else return false,"empty_file" end
end

local function scan_tree(root, results)
  if not path_exists(root) then return end
  local function recurse(dir)
    local i=0
    while true do
      local sub = reaper.EnumerateSubdirectories(dir,i)
      if not sub then break end
      recurse(join_path(dir,sub)); i=i+1
    end
    local j=0
    while true do
      local fname = reaper.EnumerateFiles(dir,j)
      if not fname then break end
      local full = join_path(dir,fname)
      local lower = fname:lower()
      local ext = lower:match("%.([^.]+)$") or ""
      local rel = full
      if ext=="lua" then
        local ok,err = check_lua(full)
        if ok then table.insert(results.lua_ok,rel)
        else table.insert(results.lua_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="jsfx" or ext=="jsfx-inc" then
        local ok,err = check_jsfx(full)
        if ok then table.insert(results.jsfx_ok,rel)
        else table.insert(results.jsfx_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="eel" or ext=="eel2" then
        local ok,err = check_eel(full)
        table.insert(results.eel_files,{path=rel,error=err or ""})
      end
      j=j+1
    end
  end
  recurse(root)
end

local function json_escape(str)
  str = tostring(str or "")
  str = str:gsub("\\","\\\\"):gsub("\"","\\\"")
  str = str:gsub("\b","\\b"):gsub("\f","\\f")
  str = str:gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
  return str
end

local function json_kv_str(k,v) return "\"" .. json_escape(k) .. "\":\"" .. json_escape(v) .. "\"" end
local function json_kv_num(k,n) return "\"" .. json_escape(k) .. "\":" .. tostring(n or 0) end

local function json_array_of_strings(name,arr)
  local parts={}
  for _,v in ipairs(arr) do parts[#parts+1] = "\"" .. json_escape(v) .. "\"" end
  return "\"" .. json_escape(name) .. "\":[" .. table.concat(parts,",") .. "]"
end

local function json_array_of_objects(name,list)
  local parts={}
  for _,obj in ipairs(list) do
    local fields={}
    for k,v in pairs(obj) do fields[#fields+1]=json_kv_str(k,v) end
    parts[#parts+1]="{"..table.concat(fields,",").."}"
  end
  return "\"" .. json_escape(name) .. "\":[" .. table.concat(parts,",") .. "]"
end

local function main()
  reaper.ShowConsoleMsg("")
  msg("=== DF95 Diagnostics 2.0 – RealPath Version ===")
  msg("Resource Path (fix): "..REAL_RESOURCE_PATH)

  local scripts_root = join_path(REAL_RESOURCE_PATH,"Scripts"..sep.."IfeelLikeSnow")
  local effects_root = join_path(REAL_RESOURCE_PATH,"Effects"..sep.."IfeelLikeSnow")

  local results = { lua_ok={}, lua_err={}, jsfx_ok={}, jsfx_err={}, eel_files={} }

  scan_tree(scripts_root, results)
  scan_tree(effects_root, results)

  local counts = {}
  counts.lua_ok  = #results.lua_ok
  counts.lua_err = #results.lua_err
  counts.lua     = counts.lua_ok + counts.lua_err
  counts.jsfx_ok = #results.jsfx_ok
  counts.jsfx_err= #results.jsfx_err
  counts.jsfx    = counts.jsfx_ok + counts.jsfx_err
  counts.eel     = #results.eel_files

  local support_root = join_path(REAL_RESOURCE_PATH,"Support")
  local diag_dir = join_path(support_root,"DF95_Diagnostics2")
  ensure_dir(diag_dir)

  local txt_path = join_path(diag_dir,"DF95_Diagnostics_Report.txt")
  local f_txt = io.open(txt_path,"w")
  if f_txt then
    f_txt:write("DF95 Diagnostics 2.0 – RealPath Version\n")
    f_txt:write("Repo Root (REAL_RESOURCE_PATH): "..REAL_RESOURCE_PATH.."\n\n")
    f_txt:write("Lua Files:\n  Total: "..tostring(counts.lua)..
                "\n  OK   : "..tostring(counts.lua_ok)..
                "\n  ERR  : "..tostring(counts.lua_err).."\n\n")
    f_txt:write("JSFX Files:\n  Total: "..tostring(counts.jsfx)..
                "\n  OK   : "..tostring(counts.jsfx_ok)..
                "\n  ERR  : "..tostring(counts.jsfx_err).."\n\n")
    f_txt:write("EEL Files:\n  Total: "..tostring(counts.eel).."\n\n")

    local function w_err_list(title,list)
      f_txt:write(title..":\n")
      if #list==0 then f_txt:write("  (none)\n\n"); return end
      for _,e in ipairs(list) do
        f_txt:write("  "..tostring(e.path).."  -- "..tostring(e.error or "").."\n")
      end
      f_txt:write("\n")
    end
    w_err_list("Lua Errors", results.lua_err)
    w_err_list("JSFX Errors", results.jsfx_err)
    f_txt:close()
  end

  local json_path = join_path(diag_dir,"DF95_Diagnostics_Report.json")
  local f_json = io.open(json_path,"w")
  if f_json then
    local parts={}
    parts[#parts+1]="{"
    parts[#parts+1]=json_kv_str("repo_root",REAL_RESOURCE_PATH)..","
    parts[#parts+1]="\"roots\":{"..
        json_kv_str("scripts",scripts_root)..","..
        json_kv_str("effects",effects_root)..
      "},"
    local cparts={}
    cparts[#cparts+1]=json_kv_num("lua",counts.lua)
    cparts[#cparts+1]=json_kv_num("lua_ok",counts.lua_ok)
    cparts[#cparts+1]=json_kv_num("lua_err",counts.lua_err)
    cparts[#cparts+1]=json_kv_num("jsfx",counts.jsfx)
    cparts[#cparts+1]=json_kv_num("jsfx_ok",counts.jsfx_ok)
    cparts[#cparts+1]=json_kv_num("jsfx_err",counts.jsfx_err)
    cparts[#cparts+1]=json_kv_num("eel",counts.eel)
    parts[#parts+1]="\"counts\":{"..table.concat(cparts,",").."},"
    parts[#parts+1]=json_array_of_strings("lua_ok",results.lua_ok)..","
    parts[#parts+1]=json_array_of_objects("lua_err",results.lua_err)..","
    parts[#parts+1]=json_array_of_strings("jsfx_ok",results.jsfx_ok)..","
    parts[#parts+1]=json_array_of_objects("jsfx_err",results.jsfx_err)..","
    parts[#parts+1]=json_array_of_objects("eel_files",results.eel_files)
    parts[#parts+1]="}"
    f_json:write(table.concat(parts,"\n")); f_json:close()
  end

  msg("Diagnostics 2.0 (RealPath) abgeschlossen.")
  msg("TXT Report : "..txt_path)
  msg("JSON Report: "..json_path)
  reaper.ShowMessageBox(
    "Diagnostics 2.0 (RealPath) abgeschlossen.\n\nTXT: "..txt_path.."\nJSON: "..json_path,
    "DF95 Diagnostics 2.0 – RealPath",0)
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("DF95 Diagnostics 2.0 – RealPath", -1)
