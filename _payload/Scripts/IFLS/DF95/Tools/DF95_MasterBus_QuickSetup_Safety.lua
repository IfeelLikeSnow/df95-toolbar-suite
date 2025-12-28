-- DF95_MasterBus_QuickSetup_Safety.lua
-- Master-Bus-Auswahl + direkt danach DF95 Safety/Loudness-Menu ausführen.
-- Idee:
--   1. Nutzt den bestehenden DF95_MasterBus_Selector (Kontextmenü, Tags, Kategorien).
--   2. Danach wird automatisch DF95_Safety_Loudness_Menu.lua aufgerufen (falls vorhanden).

local r = reaper

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = (res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep):gsub("\\","/")

local function run_master_selector()
  local ok, err = pcall(dofile, base.."DF95_MasterBus_Selector.lua")
  if not ok then
    r.ShowMessageBox("DF95_MasterBus_Selector.lua Fehler:\n"..tostring(err), "DF95 Master + Safety QuickSetup", 0)
  end
end

local function run_safety_menu()
  local safety_path = base.."DF95_Safety_Loudness_Menu.lua"
  local f = io.open(safety_path, "rb")
  if not f then return end
  f:close()
  local ok, err = pcall(dofile, safety_path)
  if not ok then
    r.ShowMessageBox("DF95_Safety_Loudness_Menu.lua Fehler:\n"..tostring(err), "DF95 Master + Safety QuickSetup", 0)
  end
end

local function main()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  -- 1) Master-Bus-Chain auswählen (zeigt Menü wie gewohnt)
  run_master_selector()

  -- 2) Direkt danach Safety/Loudness-Menü ausführen
  run_safety_menu()

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Master + Safety QuickSetup", -1)
end

main()
