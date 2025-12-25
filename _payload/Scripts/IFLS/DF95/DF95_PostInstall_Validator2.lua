-- @description Post-Install Validator 2.0 (CSV-aware)
-- @version 2.0
-- @author DF95
-- @about Checks presence of critical scripts, chains, and (if CSVs found) required plugins. Writes DF95_Validation_Report.txt.

local r   = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function exists(p)
  local f = io.open(p, "rb")
  if f then f:close(); return true end
  return false
end

local function wln(fh, s)
  fh:write(s .. "\n")
end

local out = res..sep.."DF95_Validation_Report.txt"
local f = io.open(out, "wb")
if not f then
  r.ShowMessageBox("Kann Report nicht schreiben:\n"..out, "DF95 Validator", 0)
  return
end

wln(f, "DF95 Validator 2.0 Report")

-- Core paths
local must_scripts = {
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_SmartCeiling.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ColorBias_Manager.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_StatusOverlay.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_ParallelFX_AutoRoute.lua",
  "Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_GainMatch_LUFS_Manual.lua",
}

local must_chains = {
  "Chains"..sep.."Master",
  "Chains"..sep.."Coloring",
  "Chains"..sep.."FXBus",
}

wln(f, "\n[CORE FILES]")
for _, rel in ipairs(must_scripts) do
  local p = res..sep..rel
  wln(f, (exists(p) and "[OK] " or "[MISS] ") .. rel)
end

for _, rel in ipairs(must_chains) do
  local p = res..sep..rel
  wln(f, (exists(p) and "[OK] " or "[MISS] ") .. rel)
end

-- CSV scan
wln(f, "\n[PLUGIN INVENTORY CSV]")
local csvs = {}

local function add_if_exists(name)
  local p = res..sep..name
  if exists(p) then
    table.insert(csvs, p)
    wln(f, "[FOUND] " .. name)
  end
end

add_if_exists("Plugins_Variants_Pivot_x86.csv")
add_if_exists("RC41_Cleanup_KeepDisable.csv")
add_if_exists("RC41_Cleanup_KeepDisable_20251109_1620.csv")

if #csvs > 0 then
  wln(f, "\n[PLUGIN VENDOR CHECK]")
  local vendors = {
    "FabFilter",
    "SoundToys",
    "iZotope",
    "Waves",
    "Native Instruments",
    "UAD",
  }
  for _, v in ipairs(vendors) do
    local found = false
    for _, p in ipairs(csvs) do
      local t = io.open(p, "rb")
      if t then
        local s = t:read("*all")
        t:close()
        if s:lower():find(v:lower(), 1, true) then
          found = true
          break
        end
      end
    end
    wln(f, (found and "[OK] " or "[WARN] ") .. v)
  end
else
  wln(f, "[INFO] Keine CSV gefunden – Vendor-Check übersprungen.")
end

-- Critical Plugins (minimal)
wln(f, "\n[CRITICAL PLUGINS]")
local crit = {
  "VST3: ReaLimit (Cockos)",
  "VST3: ReaEQ (Cockos)",
  "JS: Volume adjustment",
}

for _, nm in ipairs(crit) do
  local fx = reaper.TrackFX_AddByName(reaper.GetMasterTrack(0), nm, false, 1) -- query only
  wln(f, (fx >= 0 and "[OK] " or "[MISS] ") .. nm)
end

wln(f, "\nReport: " .. out)
f:close()
reaper.ShowMessageBox("DF95 Validator 2.0 abgeschlossen.\nReport:\n"..out, "DF95", 0)
