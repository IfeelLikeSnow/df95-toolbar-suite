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
-- DF95_Diagnostics3_RealPath.lua
-- Diagnostics 3.0 (RealPath-Version) für IFLS / DF95

local REAL_RESOURCE_PATH = "C:\\Users\\ifeel\\AppData\\Roaming\\REAPER"
local sep = package.config:sub(1,1) or "\\"

local function join_path(a,b)
  if a:sub(-1)==sep then return a..b end
  return a..sep..b
end

local function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

local function path_exists(path)
  local ok, _, code = os.rename(path,path)
  if ok then return true end
  if code==13 then return true end
  return false
end

local function ensure_dir(path) reaper.RecursiveCreateDirectory(path,0) end

local function read_file(path,bin)
  local f,err = io.open(path, bin and "rb" or "r")
  if not f then return nil,err end
  local c=f:read("*a"); f:close(); return c
end

local function file_size(path)
  local f=io.open(path,"rb"); if not f then return 0 end
  local cur=f:seek(); local sz=f:seek("end"); f:seek("set",cur or 0); f:close()
  return sz or 0
end

local function first_non_ws_char(str)
  local i,len=1,#str
  while i<=len do local ch=str:sub(i,i); if not ch:match("%s") then return ch end; i=i+1 end
  return nil
end
local function last_non_ws_char(str)
  local i=#str
  while i>=1 do local ch=str:sub(i,i); if not ch:match("%s") then return ch end; i=i-1 end
  return nil
end

local function check_lua(path)
  local c,err=loadfile(path); if c then return true,nil else return false,tostring(err or "unknown") end
end

local function check_jsfx(path)
  local content,err=read_file(path,false)
  if not content then return false,"cannot_read:"..tostring(err) end
  local first=content:match("([^\r\n]*)") or ""
  if first:match("^%s*desc:") then return true,nil end
  return false,"missing_desc_header"
end

local function check_eel(path)
  if file_size(path)>0 then return true,nil end
  return false,"empty_file"
end

local function check_json(path)
  local content,err=read_file(path,false)
  if not content then return false,"cannot_read:"..tostring(err) end
  if content:sub(1,3)=="\239\187\191" then content=content:sub(4) end
  local first,last = first_non_ws_char(content), last_non_ws_char(content)
  if not first or not last then return false,"empty_or_ws" end
  if not ((first=="{" or first=="[") and (last=="}" or last=="]")) then
    return false,"json_brace_mismatch"
  end
  local dc,ds=0,0
  for ch in content:gmatch(".") do
    if ch=="{" then dc=dc+1 elseif ch=="}" then dc=dc-1
    elseif ch=="[" then ds=ds+1 elseif ch=="]" then ds=ds-1 end
    if dc<0 or ds<0 then return false,"json_unbalanced" end
  end
  if dc~=0 or ds~=0 then return false,"json_unbalanced" end
  return true,nil
end

local function check_text(path)
  local c,err=read_file(path,false)
  if not c then return false,"cannot_read:"..tostring(err) end
  if c=="" then return false,"empty_file" end
  return true,nil
end

local function check_config(path)
  local c,err=read_file(path,false)
  if not c then return false,"cannot_read:"..tostring(err) end
  if c:match("%S") then return true,nil end
  return false,"empty_config"
end

local function check_audio(path)
  local sz=file_size(path); if sz==0 then return false,"empty_file" end
  local hdr,err=read_file(path,true); if not hdr then return false,"cannot_read:"..tostring(err) end
  hdr=hdr:sub(1,12)
  local ext=path:lower():match("%.([^.]+)$") or ""
  if ext=="wav" and hdr:sub(1,4)~="RIFF" then return false,"wav_header" end
  if ext=="flac" and hdr:sub(1,4)~="fLaC" then return false,"flac_header" end
  if ext=="ogg" and hdr:sub(1,4)~="OggS" then return false,"ogg_header" end
  return true,nil
end

local function check_image(path)
  local sz=file_size(path); if sz==0 then return false,"empty_file" end
  local ext=path:lower():match("%.([^.]+)$") or ""
  if ext=="png" then
    local hdr,err=read_file(path,true); if not hdr then return false,"cannot_read:"..tostring(err) end
    hdr=hdr:sub(1,8); local sig="\137\080\078\071\013\010\026\010"
    if hdr~=sig then return false,"png_sig" end
    return true,nil
  elseif ext=="jpg" or ext=="jpeg" then
    local hdr,err=read_file(path,true); if not hdr then return false,"cannot_read:"..tostring(err) end
    hdr=hdr:sub(1,2); local b1,b2=hdr:byte(1,2)
    if b1~=0xFF or b2~=0xD8 then return false,"jpg_sig" end
    return true,nil
  elseif ext=="svg" then
    local c,err=read_file(path,false); if not c then return false,"cannot_read:"..tostring(err) end
    if c:lower():match("<%s*svg") then return true,nil end
    return false,"svg_root"
  end
  return true,nil
end

local function check_rpl(path)
  return check_text(path)
end

local function scan_tree(root, results)
  if not path_exists(root) then return end
  local function recurse(dir)
    local i=0
    while true do
      local sub=reaper.EnumerateSubdirectories(dir,i)
      if not sub then break end
      recurse(join_path(dir,sub)); i=i+1
    end
    local j=0
    while true do
      local fname=reaper.EnumerateFiles(dir,j)
      if not fname then break end
      local full=join_path(dir,fname)
      local lower=fname:lower()
      local ext=lower:match("%.([^.]+)$") or ""
      local rel=full
      if ext=="lua" then
        local ok,err=check_lua(full)
        if ok then table.insert(results.lua_ok,rel)
        else table.insert(results.lua_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="jsfx" or ext=="jsfx-inc" then
        local ok,err=check_jsfx(full)
        if ok then table.insert(results.jsfx_ok,rel)
        else table.insert(results.jsfx_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="eel" or ext=="eel2" then
        local ok,err=check_eel(full)
        table.insert(results.eel_files,{path=rel,error=err or ""})
      elseif ext=="json" then
        local ok,err=check_json(full)
        if ok then table.insert(results.json_ok,rel)
        else table.insert(results.json_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="cfg" or ext=="ini" or ext=="conf" then
        local ok,err=check_config(full)
        if ok then table.insert(results.cfg_ok,rel)
        else table.insert(results.cfg_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="txt" or ext=="md" then
        local ok,err=check_text(full)
        if ok then table.insert(results.txt_ok,rel)
        else table.insert(results.txt_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="wav" or ext=="flac" or ext=="ogg" then
        local ok,err=check_audio(full)
        if ok then table.insert(results.audio_ok,rel)
        else table.insert(results.audio_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="png" or ext=="jpg" or ext=="jpeg" or ext=="svg" then
        local ok,err=check_image(full)
        if ok then table.insert(results.image_ok,rel)
        else table.insert(results.image_err,{path=rel,error=err or "unknown"}) end
      elseif ext=="rpl" then
        local ok,err=check_rpl(full)
        if ok then table.insert(results.rpl_ok,rel)
        else table.insert(results.rpl_err,{path=rel,error=err or "unknown"}) end
      end
      j=j+1
    end
  end
  recurse(root)
end

local function json_escape(str)
  str=tostring(str)
  str=str:gsub("\\","\\\\"):gsub("\"","\\\"")
  str=str:gsub("\b","\\b"):gsub("\f","\\f")
  str=str:gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
  return str
end
local function json_kv_str(k,v) return "\"" .. json_escape(k) .. "\":\"" .. json_escape(v) .. "\"" end
local function json_kv_num(k,n) return "\"" .. json_escape(k) .. "\":" .. tostring(n) end

local function json_array_of_strings(name,arr)
  local parts={} for _,v in ipairs(arr) do parts[#parts+1]="\"" .. json_escape(v) .. "\"" end
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
  msg("=== DF95 Diagnostics 3.0 – RealPath Version ===")
  msg("Resource Path (fix): "..REAL_RESOURCE_PATH)

  local repo_root   = REAL_RESOURCE_PATH
  local scripts_root= join_path(REAL_RESOURCE_PATH,"Scripts"..sep.."IfeelLikeSnow")
  local effects_root= join_path(REAL_RESOURCE_PATH,"Effects"..sep.."IfeelLikeSnow")
  local support_root= join_path(REAL_RESOURCE_PATH,"Support")

  local results = {
    lua_ok={}, lua_err={},
    jsfx_ok={}, jsfx_err={},
    eel_files={},
    json_ok={}, json_err={},
    cfg_ok={}, cfg_err={},
    txt_ok={}, txt_err={},
    audio_ok={}, audio_err={},
    image_ok={}, image_err={},
    rpl_ok={}, rpl_err={}
  }

  scan_tree(scripts_root,results)
  scan_tree(effects_root,results)
  scan_tree(support_root,results)

  local counts={}
  counts.lua_ok=#results.lua_ok; counts.lua_err=#results.lua_err; counts.lua=counts.lua_ok+counts.lua_err
  counts.jsfx_ok=#results.jsfx_ok; counts.jsfx_err=#results.jsfx_err; counts.jsfx=counts.jsfx_ok+counts.jsfx_err
  counts.eel=#results.eel_files
  counts.json_ok=#results.json_ok; counts.json_err=#results.json_err; counts.json=counts.json_ok+counts.json_err
  counts.cfg_ok=#results.cfg_ok; counts.cfg_err=#results.cfg_err; counts.cfg=counts.cfg_ok+counts.cfg_err
  counts.txt_ok=#results.txt_ok; counts.txt_err=#results.txt_err; counts.txt=counts.txt_ok+counts.txt_err
  counts.audio_ok=#results.audio_ok; counts.audio_err=#results.audio_err; counts.audio=counts.audio_ok+counts.audio_err
  counts.image_ok=#results.image_ok; counts.image_err=#results.image_err; counts.image=counts.image_ok+counts.image_err
  counts.rpl_ok=#results.rpl_ok; counts.rpl_err=#results.rpl_err; counts.rpl=counts.rpl_ok+counts.rpl_err

  local diag_dir = join_path(support_root,"DF95_Diagnostics3"); ensure_dir(diag_dir)
  local txt_path = join_path(diag_dir,"DF95_Diagnostics3_Report.txt")
  local f_txt=io.open(txt_path,"w")
  if f_txt then
    local function w_counts(label, key_total,key_ok,key_err)
      f_txt:write(label..":\n")
      f_txt:write("  Total: "..tostring(counts[key_total] or 0).."\n")
      if key_ok then f_txt:write("  OK   : "..tostring(counts[key_ok] or 0).."\n") end
      if key_err then f_txt:write("  ERR  : "..tostring(counts[key_err] or 0).."\n") end
      f_txt:write("\n")
    end
    f_txt:write("DF95 Diagnostics 3.0 – RealPath Version\n")
    f_txt:write("Repo Root (REAL_RESOURCE_PATH): "..repo_root.."\n\n")
    w_counts("Lua Files","lua","lua_ok","lua_err")
    w_counts("JSFX Files","jsfx","jsfx_ok","jsfx_err")
    w_counts("EEL Files","eel",nil,nil)
    w_counts("JSON Files","json","json_ok","json_err")
    w_counts("Config Files","cfg","cfg_ok","cfg_err")
    w_counts("Text Files","txt","txt_ok","txt_err")
    w_counts("Audio Files","audio","audio_ok","audio_err")
    w_counts("Image Files","image","image_ok","image_err")
    w_counts("RPL Files","rpl","rpl_ok","rpl_err")
    local function w_err_list(title,list)
      f_txt:write(title..":\n")
      if #list==0 then f_txt:write("  (none)\n\n"); return end
      for _,e in ipairs(list) do
        f_txt:write("  "..tostring(e.path).."  -- "..tostring(e.error or "").."\n")
      end
      f_txt:write("\n")
    end
    w_err_list("Lua Errors",results.lua_err)
    w_err_list("JSFX Errors",results.jsfx_err)
    w_err_list("JSON Errors",results.json_err)
    w_err_list("Config Errors",results.cfg_err)
    w_err_list("Text Errors",results.txt_err)
    w_err_list("Audio Errors",results.audio_err)
    w_err_list("Image Errors",results.image_err)
    w_err_list("RPL Errors",results.rpl_err)
    f_txt:close()
  end

  local json_path=join_path(diag_dir,"DF95_Diagnostics3_Report.json")
  local f_json=io.open(json_path,"w")
  if f_json then
    local jp={}
    jp[#jp+1]="{"
    jp[#jp+1]=json_kv_str("repo_root",repo_root)..","
    jp[#jp+1]=json_kv_str("scope","IfeelLikeSnow only (RealPath)")..","
    jp[#jp+1]="\"roots\":{"..
        json_kv_str("scripts",scripts_root)..","..
        json_kv_str("effects",effects_root)..","..
        json_kv_str("support",support_root)..
      "},"
    local cp={}
    cp[#cp+1]=json_kv_num("lua",counts.lua)
    cp[#cp+1]=json_kv_num("lua_ok",counts.lua_ok)
    cp[#cp+1]=json_kv_num("lua_err",counts.lua_err)
    cp[#cp+1]=json_kv_num("jsfx",counts.jsfx)
    cp[#cp+1]=json_kv_num("jsfx_ok",counts.jsfx_ok)
    cp[#cp+1]=json_kv_num("jsfx_err",counts.jsfx_err)
    cp[#cp+1]=json_kv_num("eel",counts.eel)
    cp[#cp+1]=json_kv_num("json",counts.json)
    cp[#cp+1]=json_kv_num("json_ok",counts.json_ok)
    cp[#cp+1]=json_kv_num("json_err",counts.json_err)
    cp[#cp+1]=json_kv_num("cfg",counts.cfg)
    cp[#cp+1]=json_kv_num("cfg_ok",counts.cfg_ok)
    cp[#cp+1]=json_kv_num("cfg_err",counts.cfg_err)
    cp[#cp+1]=json_kv_num("txt",counts.txt)
    cp[#cp+1]=json_kv_num("txt_ok",counts.txt_ok)
    cp[#cp+1]=json_kv_num("txt_err",counts.txt_err)
    cp[#cp+1]=json_kv_num("audio",counts.audio)
    cp[#cp+1]=json_kv_num("audio_ok",counts.audio_ok)
    cp[#cp+1]=json_kv_num("audio_err",counts.audio_err)
    cp[#cp+1]=json_kv_num("image",counts.image)
    cp[#cp+1]=json_kv_num("image_ok",counts.image_ok)
    cp[#cp+1]=json_kv_num("image_err",counts.image_err)
    cp[#cp+1]=json_kv_num("rpl",counts.rpl)
    cp[#cp+1]=json_kv_num("rpl_ok",counts.rpl_ok)
    cp[#cp+1]=json_kv_num("rpl_err",counts.rpl_err)
    jp[#jp+1]="\"counts\":{"..table.concat(cp,",").."},"
    jp[#jp+1]=json_array_of_strings("lua_ok",results.lua_ok)..","
    jp[#jp+1]=json_array_of_objects("lua_err",results.lua_err)..","
    jp[#jp+1]=json_array_of_strings("jsfx_ok",results.jsfx_ok)..","
    jp[#jp+1]=json_array_of_objects("jsfx_err",results.jsfx_err)..","
    jp[#jp+1]=json_array_of_objects("eel_files",results.eel_files)..","
    jp[#jp+1]=json_array_of_strings("json_ok",results.json_ok)..","
    jp[#jp+1]=json_array_of_objects("json_err",results.json_err)..","
    jp[#jp+1]=json_array_of_strings("cfg_ok",results.cfg_ok)..","
    jp[#jp+1]=json_array_of_objects("cfg_err",results.cfg_err)..","
    jp[#jp+1]=json_array_of_strings("txt_ok",results.txt_ok)..","
    jp[#jp+1]=json_array_of_objects("txt_err",results.txt_err)..","
    jp[#jp+1]=json_array_of_strings("audio_ok",results.audio_ok)..","
    jp[#jp+1]=json_array_of_objects("audio_err",results.audio_err)..","
    jp[#jp+1]=json_array_of_strings("image_ok",results.image_ok)..","
    jp[#jp+1]=json_array_of_objects("image_err",results.image_err)..","
    jp[#jp+1]=json_array_of_strings("rpl_ok",results.rpl_ok)..","
    jp[#jp+1]=json_array_of_objects("rpl_err",results.rpl_err)
    jp[#jp+1]="}"
    f_json:write(table.concat(jp,"\n")); f_json:close()
  end

  msg("Diagnostics 3.0 (RealPath) complete.")
  msg("TXT report : "..txt_path)
  msg("JSON report: "..json_path)
  reaper.ShowMessageBox(
    "Diagnostics 3.0 (RealPath) Scan abgeschlossen.\n\nTXT: "..txt_path.."\nJSON: "..json_path,
    "DF95 Diagnostics 3.0 – RealPath",0)
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("DF95 Diagnostics 3.0 – RealPath", -1)
