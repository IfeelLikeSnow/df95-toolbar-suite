-- @description Post-Install v1.54f (Setup + Run Validator once)
-- @version 1.54f
-- @author IfeelLikeSnow
-- @about Legt Ordner an, kopiert optionale Ressourcen, startet Validator 2.3 einmalig.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function ensure_dir(p) return r.RecursiveCreateDirectory(p,0) ~= 0 end
local function copy(src,dst)
  local f=io.open(src,"rb"); if not f then return false end
  local d=f:read("*all"); f:close()
  local g=io.open(dst,"wb"); if not g then return false end
  g:write(d); g:close(); return true
end

-- Targets
local d_data = res..sep.."Data"..sep.."DF95"
local d_chains = d_data..sep.."Chains"
ensure_dir(d_data); ensure_dir(d_chains)

-- Optional: if pack ships CSV under Scripts/IFLS/DF95/Data, copy to Data/DF95
local base = (debug.getinfo(1,'S').source:sub(2) or ""):match("^(.*"..sep..")") or ""
local cand_csv = {
  base.."Data"..sep.."DF95_FXChains_Catalog_Reclassified_SoftPass.csv",
  base.."Data"..sep.."DF95_FXChains_Catalog_Reclassified_Strict.csv",
  base.."Data"..sep.."DF95_FXChains_Catalog.csv",
}
for _,p in ipairs(cand_csv) do
  local f=io.open(p,"rb")
  if f then f:close(); copy(p, d_data..sep..p:match("([^"..sep.."]+)$")) end
end

-- Run Validator once (if present)
local validator = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_Validator_2_3.lua"
if reaper.file_exists(validator) then
  reaper.Main_OnCommand(40297,0) -- Show console
  dofile(validator)
  reaper.ShowMessageBox("DF95 v1.54f Post-Install: Validator 2.3 ausgeführt (siehe ReaScript Console).","DF95 v1.54f",0)
else
  reaper.ShowMessageBox("DF95 v1.54f Post-Install: Validator-Script nicht gefunden.","DF95 v1.54f",0)
end
