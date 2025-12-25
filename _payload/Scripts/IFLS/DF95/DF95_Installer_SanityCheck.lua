-- @description DF95 Installer / Sanity Check
-- @version 1.0
-- @author DF95
-- @about
--   Prüft, ob die wichtigsten DF95-Komponenten vorhanden sind:
--     * ControlCenter ImGui
--     * AutoIngest Master V3
--     * SampleDB Inspector V5
--     * AI QA Center
--     * Validator / Migration
--   und ob der Support/DF95_SampleDB-Ordner angelegt ist.
--
--   Dieses Script ändert nichts an der DB – es zeigt nur Statusmeldungen.

local r = reaper

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function check_file(label, rel_path)
  local res = r.GetResourcePath()
  local base = join_path(res, "Scripts")
  base = join_path(base, "IfeelLikeSnow")
  base = join_path(base, "DF95")
  local full = join_path(base, rel_path)
  local ok = exists(full)
  return ok, full
end

local function check_support_folder()
  local res = r.GetResourcePath()
  local base = join_path(res, "Support")
  base = join_path(base, "DF95_SampleDB")
  local f = io.open(join_path(base, "dummy.tmp"), "w")
  if f then
    f:close()
    os.remove(join_path(base, "dummy.tmp"))
    return true, base
  else
    return false, base
  end
end

local function main()
  local msg = {}
  msg[#msg+1] = "DF95 Installer / Sanity Check"
  msg[#msg+1] = ""

  local checks = {
    {"ControlCenter ImGui",          "Tools/DF95_ControlCenter_ImGui.lua"},
    {"AutoIngest Master V3",        "DF95_AutoIngest_Master_V3.lua"},
    {"AutoIngest Undo Last Run",    "DF95_AutoIngest_Undo_LastRun.lua"},
    {"SampleDB Inspector V5",       "DF95_SampleDB_Inspector_V5_AI_Review_ImGui.lua"},
    {"AI QA Center",                "DF95_AI_QA_Center_ImGui.lua"},
    {"SampleDB Validator V3",       "DF95_SampleDB_Validator_V3.lua"},
    {"SampleDB Migration V2->V3",   "DF95_SampleDB_Migrate_V2_to_V3.lua"},
    {"DeviceProfiles",              "DF95_DeviceProfiles.lua"},
  }

  for _, c in ipairs(checks) do
    local label, rel = c[1], c[2]
    local ok, full = check_file(label, rel)
    msg[#msg+1] = string.format("%-32s : %s", label, ok and "OK" or "FEHLT")
    if not ok then
      msg[#msg+1] = "  -> erwartet unter: " .. full
    end
  end

  msg[#msg+1] = ""
  msg[#msg+1] = "Support / DB-Ordner:"

  local ok_support, base = check_support_folder()
  msg[#msg+1] = string.format("DF95_SampleDB Folder    : %s", ok_support and "OK" or "NICHT BESCHREIBBAR")
  msg[#msg+1] = "  Pfad: " .. base
  msg[#msg+1] = ""
  msg[#msg+1] = "Hinweis:"
  msg[#msg+1] = "  * Wenn Dateien als 'FEHLT' markiert sind, pruefe die Installation des DF95-Pakets."
  msg[#msg+1] = "  * Wenn der DF95_SampleDB-Folder nicht beschreibbar ist, muessen Rechte / Pfade geprueft werden."
  msg[#msg+1] = ""
  msg[#msg+1] = "Dieses Script nimmt keine Aenderungen vor – es ist nur eine Diagnoseseite."

  r.ShowMessageBox(table.concat(msg, "\n"), "DF95 Installer / Sanity Check", 0)
end

main()
