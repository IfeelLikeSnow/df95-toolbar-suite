-- DF95 Diagnostics: PathResolver Test
local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

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
local lib = base .. "/Scripts/DF95Framework/Lib/DF95_PathResolver.lua"

local ok, PR = pcall(dofile, lib)
if not ok then
  r.ShowMessageBox("Konnte DF95_PathResolver nicht laden:\n" .. tostring(PR) .. "\n\nPfad:\n" .. lib,
                   "DF95 PathResolver Test", 0)
  return
end

local df95_root = PR.get_df95_scripts_root()
local ifls_root = PR.get_ifls_scripts_root()
local added = PR.bootstrap_package_path()

local report_dir = base .. "/Support/DF95_Reports"
r.RecursiveCreateDirectory(report_dir, 0)
local ts = os.date("%Y%m%d_%H%M%S")
local txt = report_dir .. "/DF95_PathResolver_" .. ts .. ".txt"
local json = report_dir .. "/DF95_PathResolver_" .. ts .. ".json"

local f = io.open(txt, "w")
if f then
  f:write("DF95 PathResolver Test\n")
  f:write("Resource Path: " .. base .. "\n")
  f:write("DF95 scripts root: " .. tostring(df95_root) .. "\n")
  f:write("IFLS scripts root: " .. tostring(ifls_root) .. "\n")
  f:write("package.path entries added: " .. tostring(added) .. "\n")
  f:close()
end

local function esc(s)
  s = tostring(s or ""):gsub("\\","\\\\"):gsub("\"","\\\""):gsub("\n","\\n")
  return s
end
local jf = io.open(json, "w")
if jf then
  jf:write("{\n")
  jf:write('  "resource_path": "' .. esc(base) .. '",\n')
  jf:write('  "df95_scripts_root": "' .. esc(df95_root) .. '",\n')
  jf:write('  "ifls_scripts_root": "' .. esc(ifls_root) .. '",\n')
  jf:write('  "package_path_added": ' .. tostring(added) .. "\n")
  jf:write("}\n")
  jf:close()
end

r.ShowMessageBox(
  "DF95 PathResolver OK.\n\nDF95 root:\n" .. tostring(df95_root) ..
  "\n\nIFLS root:\n" .. tostring(ifls_root) ..
  "\n\nReport:\n" .. txt,
  "DF95 PathResolver Test", 0)
