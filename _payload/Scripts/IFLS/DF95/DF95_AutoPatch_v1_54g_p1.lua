-- @description Auto-Patch v1.54g p1 (Undo/Refresh + dofile guards)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Sucht in Scripts/IFLS/DF95 nach Lua-Dateien und patcht fehlende Undo/Refresh-Blöcke
--        sowie ersetzt blanke dofile(...) durch guard_dofile(...). Erstellt .bak-Dateien.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local root = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep

local function read_text(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function write_text(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end
local function list(dir)
  local t,i={},0; while true do local fn=reaper.EnumerateFiles(dir,i); if not fn then break end t[#t+1]=fn; i=i+1 end; return t
end

local function ensure_guard_block(txt)
  local has_begin = txt:match("Undo_BeginBlock")
  local has_end   = txt:match("Undo_EndBlock")
  local has_refresh= txt:match("PreventUIRefresh")
  if has_begin and has_end and has_refresh then return txt end
  -- naive wrap: add at top and bottom if missing
  local head = "reaper.Undo_BeginBlock(); reaper.PreventUIRefresh(1)\n"
  local tail = "\nreaper.PreventUIRefresh(-1); reaper.Undo_EndBlock(\"DF95 Action\", -1)\n"
  -- avoid double wrap for files that return a table (helpers)
  if txt:match("^%s*return%s+") then return txt end
  return head .. txt .. tail
end

local function replace_dofile(txt)
  -- replace raw dofile( ... ) with guard_dofile(...)
  if not txt:match("dofile%(") then return txt end
  if not txt:match("DF95_Common_Guards") then
    local dir = (debug.getinfo(1,"S").source:match("(.+[\\/])") or "")
    local rel = "DF95_Common_Guards.lua"
    txt = 'local DF95_G = dofile((debug.getinfo(1,"S").source:match("(.+[\\/])") or "").."DF95_Common_Guards.lua")\n' .. txt
  end
  txt = txt:gsub("dofile%(", "DF95_G.guard_dofile(")
  return txt
end

local patched, skipped = 0, 0
for _,fn in ipairs(list(root)) do
  if fn:match("%.lua$") and not fn:match("Common_Guards") and not fn:match("Auto%-Patch") then
    local p = root..fn
    local src = read_text(p)
    if src and #src>0 then
      local dst = src
      dst = ensure_guard_block(dst)
      dst = replace_dofile(dst)
      if dst ~= src then
        write_text(p..".bak", src)
        write_text(p, dst)
        patched = patched + 1
      else
        skipped = skipped + 1
      end
    end
  end
end

reaper.ShowMessageBox(("DF95 Auto-Patch v1.54g p1:\nPatched: %d\nUnchanged: %d\n(Backups: .bak)"):format(patched, skipped), "DF95 Auto-Patch", 0)