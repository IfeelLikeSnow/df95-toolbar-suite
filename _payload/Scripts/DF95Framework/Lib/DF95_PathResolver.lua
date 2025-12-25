-- DF95_PathResolver.lua
-- Root Resolver für DF95/IFLS (V2 + Legacy)
-- Ziel: Ein zentraler Ort, der entscheidet, ob DF95 unter Scripts/IFLS/DF95
-- oder legacy unter Scripts/IfeelLikeSnow/DF95 liegt.
--
-- Benutzung:
--   local PR = dofile(reaper.GetResourcePath() .. "/Scripts/DF95Framework/Lib/DF95_PathResolver.lua")
--   local df95_root = PR.get_df95_scripts_root()  -- absolut
--   local path = PR.resolve_df95_script("DF95_ChainLoader.lua") -- absolut oder nil

local r = reaper
local M = {}

local function norm(s) return (s or ""):gsub("\\","/") end
local function join(a,b,c,d,e)
  local parts = {a,b,c,d,e}
  local out = {}
  for _,p in ipairs(parts) do
    if p and p ~= "" then table.insert(out, tostring(p)) end
  end
  local s = table.concat(out, "/")
  s = s:gsub("//+","/")
  return s
end

local function dir_exists(path)
  path = norm(path)
  -- EnumerateFiles/Subdirectories return nil if none; but directory might still exist empty.
  -- So we check by trying to create a directory entry via io.open on a sentinel file (not safe),
  -- and fall back to EnumerateSubdirectories/Files heuristics.
  local ok = (r.EnumerateFiles(path, 0) ~= nil) or (r.EnumerateSubdirectories(path, 0) ~= nil)
  if ok then return true end
  -- As last resort: try opening the directory as file (will fail), but os.rename can indicate existence on Windows.
  local renamed = os.rename(path, path)
  if renamed then return true end
  return false
end

local function file_exists(path)
  local f = io.open(norm(path), "rb")
  if f then f:close(); return true end
  return false
end

local base_cached = nil
local function base()
  if not base_cached then base_cached = norm(r.GetResourcePath()) end
  return base_cached
end

-- Returns absolute folder path
function M.get_df95_scripts_root()
  local b = base()
  local v2 = join(b, "Scripts", "IFLS", "DF95")
  local legacy = join(b, "Scripts", "IfeelLikeSnow", "DF95")
  if dir_exists(v2) then return v2 end
  if dir_exists(legacy) then return legacy end
  -- fallback: IFLS root if exists
  local ifls = join(b, "Scripts", "IFLS")
  if dir_exists(ifls) then return ifls end
  return join(b, "Scripts")
end

function M.get_ifls_scripts_root()
  local b = base()
  local ifls = join(b, "Scripts", "IFLS")
  if dir_exists(ifls) then return ifls end
  -- legacy IFLS namespace (rare)
  local legacy = join(b, "Scripts", "IfeelLikeSnow")
  if dir_exists(legacy) then return legacy end
  return join(b, "Scripts")
end

-- Resolve a DF95 script file by filename (e.g. "DF95_ChainLoader.lua") or relative path under DF95 root
function M.resolve_df95_script(rel)
  rel = norm(rel or "")
  if rel == "" then return nil end
  local root = M.get_df95_scripts_root()
  local cand1 = join(root, rel)
  if file_exists(cand1) then return cand1 end
  -- if rel already contains DF95/..., try under Scripts
  local cand2 = join(base(), "Scripts", rel)
  if file_exists(cand2) then return cand2 end
  return nil
end

-- Resolve an IFLS script under Scripts/IFLS
function M.resolve_ifls_script(rel)
  rel = norm(rel or "")
  if rel == "" then return nil end
  local root = M.get_ifls_scripts_root()
  local cand1 = join(root, rel)
  if file_exists(cand1) then return cand1 end
  local cand2 = join(base(), "Scripts", rel)
  if file_exists(cand2) then return cand2 end
  return nil
end

-- Optional helper: add module search paths for require()
function M.bootstrap_package_path()
  local b = base()
  local df95 = M.get_df95_scripts_root()
  local ifls = M.get_ifls_scripts_root()

  local function add(pat)
    local cur = norm(package.path)
    local n = norm(pat)
    if not cur:lower():find(n:lower(), 1, true) then
      package.path = package.path .. ";" .. pat
      return true
    end
    return false
  end

  local added = 0
  added = added + (add(join(ifls, "?.lua")) and 1 or 0)
  added = added + (add(join(ifls, "?/init.lua")) and 1 or 0)
  added = added + (add(join(df95, "?.lua")) and 1 or 0)
  added = added + (add(join(df95, "?/init.lua")) and 1 or 0)
  -- DF95Framework Lib
  added = added + (add(join(b, "Scripts/DF95Framework/Lib/?.lua")) and 1 or 0)
  added = added + (add(join(b, "Scripts/DF95Framework/Lib/?/init.lua")) and 1 or 0)
  return added
end

return M
