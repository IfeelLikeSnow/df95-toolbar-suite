-- @description Post-Install Validator
-- @version 1.44.1
-- @author DF95
-- @about Simple post-install check that verifies presence of core DF95 scripts and chains.

local r    = reaper
local sep  = package.config:sub(1,1)
local res  = r.GetResourcePath()
local base = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep

local list = {
  -- Core FXChain setup scripts
  "FXChains_IDM",
  "FXChains_Coloring",
  "FXChains_Master",

  -- Bus selectors
  "DF95_ColoringBus_Selector.lua",
  "DF95_MasterBus_Selector.lua",
}

local missing = {}

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

for _, rel in ipairs(list) do
  local p = base..rel
  local ok = false

  if rel:match("%.lua$") then
    -- Lua scripts
    ok = file_exists(p)
  else
    -- chains or directories: accept either the directory or matching .RTrackTemplate/.RfxChain in subfolders
    if file_exists(p) then
      ok = true
    else
      local as_chain = base..rel..sep
      if file_exists(as_chain) then
        ok = true
      end
    end
  end

  if not ok then
    missing[#missing+1] = rel
  end
end

if #missing == 0 then
  r.ShowMessageBox("DF95 v1.44 – Post-Install Validator: OK\nAlle Kernskripte vorhanden.", "DF95", 0)
else
  r.ShowMessageBox("DF95 v1.44 – Post-Install Validator: PROBLEME\nFehlend:\n"..table.concat(missing, "\n"), "DF95", 0)
end
