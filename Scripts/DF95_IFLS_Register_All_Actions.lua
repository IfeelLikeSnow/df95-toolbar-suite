-- @description DF95/IFLS: Register all DF95/IFLS actions (first run)
-- @version 1.0.0
-- @author DF95 / IFLS
-- @about
--   Registers DF95/IFLS scripts as actions. Safe to re-run.

local function msg(s) reaper.ShowMessageBox(tostring(s), "DF95/IFLS Register Actions", 0) end
local function norm(p) return (p or ""):gsub('\\','/') end
local function join(a,b) if a:sub(-1)=='/' then return a..b end return a..'/'..b end

local function read_head(path)
  local f=io.open(path,'rb'); if not f then return '' end
  local d=f:read(4096) or ''; f:close(); return d
end

local function is_df95_ifls_script(path)
  if not path:lower():match('%.lua$') then return false end
  local fn = path:match("([^/]+)$") or path
  -- Only likely DF95/IFLS scripts:
  if not (fn:match("^DF95_") or fn:match("^IFLS_") or fn:match("^DF95IFLS_")) then return false end
  local head = read_head(path)
  -- Require either a ReaPack-style header or actual reaper API usage to avoid registering libs:
  if head:find("@description", 1, true) then return true end
  if head:find("reaper%.", 1, true) then return true end
  return false
end

local function scan_dir(dir, out)
  local i=0
  while true do
    local f=reaper.EnumerateFiles(dir,i); if not f then break end
    local full=norm(join(dir,f))
    if is_df95_ifls_script(full) then out[#out+1]=full end
    i=i+1
  end
  local j=0
  while true do
    local s=reaper.EnumerateSubdirectories(dir,j); if not s then break end
    scan_dir(norm(join(dir,s)), out)
    j=j+1
  end
end

local rp = norm(reaper.GetResourcePath())
local roots = {
  norm(join(rp, "Scripts")),
}

local found = {}
for _,d in ipairs(roots) do
  if reaper.EnumerateFiles(d,0) or reaper.EnumerateSubdirectories(d,0) then
    scan_dir(d, found)
  end
end

-- Unique
local uniq, seen = {}, {}
for _,x in ipairs(found) do if not seen[x] then seen[x]=true; uniq[#uniq+1]=x end end

if #uniq == 0 then
  msg("No DF95/IFLS scripts found under ResourcePath/Scripts.\n\nCheck installation first.")
  return
end

local ok, fail = 0, 0
reaper.Undo_BeginBlock()
for _,path in ipairs(uniq) do
  local rv = reaper.AddRemoveReaScript(true, 0, path, true)
  if rv ~= 0 then ok = ok + 1 else fail = fail + 1 end
end
reaper.Undo_EndBlock("DF95/IFLS: Register all actions", -1)

msg(("Registered: %d\nFailed: %d\n\nSearch Action List for DF95/IFLS."):format(ok, fail))
