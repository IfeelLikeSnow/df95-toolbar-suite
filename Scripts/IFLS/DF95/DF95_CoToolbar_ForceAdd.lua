\
-- @description Force-Add Co-Toolbar (Toolbar 2) with Backup
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Schreibt DF95-CoToolbar in [Toolbar 2] der reaper-menu.ini (Backup wird erstellt).
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function read_text(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function write_text(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end
local function norm(s) return (s or ""):gsub("\r\n","\n") end

local menus = res..sep.."Menus"..sep
local tb = read_text(menus.."DF95_CoToolbar_FlowErgo_Pro.ReaperMenuSet")
if not tb then r.ShowMessageBox("DF95 Co-Toolbar-Datei nicht gefunden.\nBitte erst DF95 entpacken.", "DF95 Co-Toolbar", 0) return end
tb = norm(tb)

local payload = {}
for line in tb:gmatch("([^\n]+)") do
  if line:match("^Item%d+%s*=") or line:match("^%s*SCRIPT:") or line:match("^%s*$") then
    table.insert(payload, line)
  end
end
if #payload==0 then for line in tb:gmatch("([^\n]+)") do table.insert(payload,line) end end
local block = table.concat(payload,"\n")

local ini = res..sep.."reaper-menu.ini"
local ini_t = read_text(ini); if not ini_t then r.ShowMessageBox("reaper-menu.ini nicht gefunden.", "DF95 Co-Toolbar", 0) return end
ini_t = norm(ini_t)

local bak = ini..".DF95_cotoolbar_backup_"..os.date("!%Y%m%d_%H%M%S")
write_text(bak, ini_t)

-- Replace or insert [Toolbar 2]
local out, in_section, seen = {}, false, false
for line in ini_t:gmatch("([^\n]*)\n?") do
  local sec = line:match("^%[(.-)%]")
  if sec then
    if in_section then in_section=false end
    table.insert(out, line)
    if sec == "Toolbar 2" then
      table.insert(out, block)
      seen = true
      in_section = true
    end
  else
    if not in_section then table.insert(out, line) end
  end
end
if not seen then
  table.insert(out, "[Toolbar 2]")
  table.insert(out, block)
end

local ok = write_text(ini, table.concat(out,"\n"))
if ok then
  r.ShowMessageBox("DF95 Co-Toolbar in [Toolbar 2] geschrieben.\nBackup:\n"..bak.."\nBitte Toolbars neu laden (Customize → OK) oder REAPER neu starten.", "DF95 Co-Toolbar", 0)
else
  r.ShowMessageBox("Schreiben der reaper-menu.ini fehlgeschlagen.", "DF95 Co-Toolbar", 0)
end
