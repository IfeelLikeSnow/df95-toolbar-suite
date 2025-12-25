-- @description Dashboard Center
-- @version 1.3
-- @author DF95
-- Zentrales Dashboard: Self-Check, Validator, Auto-Installer, Hubs & IDM Tools.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function join(...) local t={...}; return table.concat(t, sep) end
local function file_exists(path) local f=io.open(path,"rb"); if f then f:close() return true end return false end

local function run_script(rel_path)
  local path = join(res, rel_path:gsub("/", sep))
  if not file_exists(path) then
    r.ShowMessageBox("DF95 Dashboard: Script nicht gefunden:\n" .. path,
      "DF95 Dashboard", 0)
    return
  end
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox("DF95 Dashboard: Fehler beim Laden von:\n" .. path ..
      "\n\n" .. tostring(err), "DF95 Dashboard", 0)
    return
  end
  f()
end

local function open_report(filename)
  local p = join(res, "Data", "DF95", filename)
  if not file_exists(p) then
    r.ShowMessageBox("Report existiert noch nicht:\n" .. p ..
      "\nBitte zuerst das entsprechende Tool ausführen.", "DF95 Dashboard", 0)
    return
  end
  if r.CF_ShellExecute then
    r.CF_ShellExecute(p)
  else
    r.ShowMessageBox("Report liegt hier:\n" .. p ..
      "\nOhne SWS kann er nicht automatisch geöffnet werden.", "DF95 Dashboard", 0)
  end
end

local function main()
  local menu =
    "DF95 – Dashboard Center (Full v10 IDM Edition)||" ..
    "Self-Check & Diagnostics|" ..             -- 2
    "Validator Pro (Deep System Check)|" ..    -- 3
    "Auto-Installer / Setup-Helper|" ..        -- 4
    "Öffne SelfCheck-Report|" ..               -- 5
    "Öffne ValidatorPro-Report|" ..            -- 6
    "|IDM & Metadata|" ..                      -- 7
    "IDM FXChain Generator PRO v2|" ..         -- 8
    "Erzeuge Metadata Report (IDM/Tape)|" ..   -- 9
    "|QA & Safety Hub|" ..                     -- 10
    "Bus & Routing Hub|" ..                    -- 11
    "Coloring & Audition Hub|" ..              -- 12
    "Bias & Humanize Hub|" ..                  -- 13
    "Slicing & Edit Hub|" ..                   -- 14
    "Input & LUFS Hub|"                        -- 15

  local mx, my = r.GetMousePosition()
  gfx.init("DF95 Dashboard", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx == 0 then return end

  if idx == 2 then
    run_script("Scripts/IFLS/DF95/DF95_SelfCheck_Toolkit.lua")
  elseif idx == 3 then
    run_script("Scripts/IFLS/DF95/DF95_Validator_Pro.lua")
  elseif idx == 4 then
    run_script("Scripts/IFLS/DF95/DF95_AutoInstaller.lua")
  elseif idx == 5 then
    open_report("DF95_SelfCheck_Report.txt")
  elseif idx == 6 then
    open_report("DF95_ValidatorPro_Report.txt")
  elseif idx == 8 then
    run_script("Scripts/IFLS/DF95/DF95_IDM_FXChain_Generator_Pro.lua")
  elseif idx == 9 then
    run_script("Scripts/IFLS/DF95/DF95_Metadata_Report_IDM.lua")
  elseif idx == 10 then
    run_script("Scripts/IFLS/DF95/DF95_Menu_QASafety_Hub.lua")
  elseif idx == 11 then
    run_script("Scripts/IFLS/DF95/DF95_Menu_BusRouting_Hub.lua")
  elseif idx == 12 then
    run_script("Scripts/IFLS/DF95/DF95_Menu_ColoringAudition_Hub.lua")
  elseif idx == 13 then
    run_script("Scripts/IFLS/DF95/DF95_Menu_BiasHumanize_Hub.lua")
  elseif idx == 14 then
    run_script("Scripts/IFLS/DF95/DF95_Menu_SlicingEdit_Hub.lua")
  elseif idx == 15 then
    run_script("Scripts/IFLS/DF95/DF95_Menu_InputLUFS_Hub.lua")
  end
end

main()
