-- @description Self-Check & Diagnostics
-- @version 1.0
-- @author DF95
-- Prüft DF95-Installation: Menüs, Scripts, JSON, wichtige Abhängigkeiten.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local report_lines = {}
local function log(line)
  report_lines[#report_lines+1] = line
end

local function join(...)
  local t = { ... }
  return table.concat(t, sep)
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

----------------------------------------------------------------------
-- 1) Menü-Dateien scannen und SCRIPT-Ziele prüfen
----------------------------------------------------------------------

local function scan_menus()
  local menus_path = join(res, "Menus")
  log("=== DF95 Self-Check – Menüs ===")
  local any = false

  local i = 0
  while true do
    local fname = r.EnumerateFiles(menus_path, i)
    if not fname then break end
    if fname:match("^DF95_") and fname:match("%.ReaperMenuSet$") then
      any = true
      local full = join(menus_path, fname)
      log("Menü: " .. fname)
      local fh = io.open(full, "r")
      if fh then
        for line in fh:lines() do
          local s = line:match("SCRIPT:%s*(.+)")
          if s then
            local rel = s:gsub("[\/
]+","/"):gsub("^/+", "")
            local full_script = join(res, rel:gsub("/", sep))
            if file_exists(full_script) then
              log("  OK  – " .. rel)
            else
              log("  ERR – Script fehlt: " .. rel)
            end
          end
        end
        fh:close()
      else
        log("  ERR – konnte Datei nicht öffnen")
      end
    end
    i = i + 1
  end

  if not any then
    log("Keine DF95_* Menüdateien in " .. menus_path .. " gefunden.")
  end
  log("")
end

----------------------------------------------------------------------
-- 2) Wichtige JSON-Dateien unter Data/DF95 prüfen
----------------------------------------------------------------------

local function scan_json()
  local data_path = join(res, "Data", "DF95")
  log("=== DF95 Self-Check – JSON-Konfiguration ===")
  if not file_exists(data_path) then
    log("WARN – Data/DF95 existiert nicht: " .. data_path)
    log("")
    return
  end

  local function is_json(name)
    return name:lower():match("%.json$")
  end

  local i = 0
  while true do
    local fname = r.EnumerateFiles(data_path, i)
    if not fname then break end
    if is_json(fname) then
      local full = join(data_path, fname)
      local fh = io.open(full, "rb")
      if fh then
        local txt = fh:read("*all")
        fh:close()
        if r.JSON_Decode then
          local ok, obj = pcall(r.JSON_Decode, txt)
          if ok and type(obj) == "table" then
            log("OK   – JSON: " .. fname)
          else
            log("ERR  – JSON ungültig: " .. fname)
          end
        else
          -- Kein JSON-Parser verfügbar, minimale Prüfung
          if txt:match("{") and txt:match("}") then
            log("OK?  – JSON (oberflächlich): " .. fname)
          else
            log("WARN – JSON sieht komisch aus: " .. fname)
          end
        end
      else
        log("ERR  – kann JSON-Datei nicht öffnen: " .. fname)
      end
    end
    i = i + 1
  end
  log("")
end

----------------------------------------------------------------------
-- 3) Hub-Skripte & zentrale DF95-Funktionen prüfen
----------------------------------------------------------------------

local function scan_core_scripts()
  log("=== DF95 Self-Check – Kernskripte & Hubs ===")
  local mandatory = {
    "Scripts/IFLS/DF95/DF95_Menu_BusRouting_Hub.lua",
    "Scripts/IFLS/DF95/DF95_Menu_ColoringAudition_Hub.lua",
    "Scripts/IFLS/DF95/DF95_Menu_BiasHumanize_Hub.lua",
    "Scripts/IFLS/DF95/DF95_Menu_SlicingEdit_Hub.lua",
    "Scripts/IFLS/DF95/DF95_Menu_InputLUFS_Hub.lua",
    "Scripts/IFLS/DF95/DF95_Menu_QASafety_Hub.lua",
    "Scripts/IFLS/DF95/DF95_Explode_AutoBus.lua",
    "Scripts/IFLS/DF95/DF95_FXBus_Selector.lua",
    "Scripts/IFLS/DF95/DF95_ColoringBus_Selector.lua",
    "Scripts/IFLS/DF95/DF95_MasterBus_Selector.lua",
    "Scripts/IFLS/DF95/DF95_MicFX_Manager.lua",
    "Scripts/IFLS/DF95/DF95_GainMatch_AB.lua",
    "Scripts/IFLS/DF95/DF95_Menu_Humanize_Dropdown.lua",
    "Scripts/IFLS/DF95/DF95_Coloring_Load_Audition.lua",
    "Scripts/IFLS/DF95/DF95_Coloring_Load_Audition_LUFS.lua",
    "Scripts/IFLS/DF95/DF95_LoopBuilder.lua",
    "Scripts/IFLS/DF95/Edit/DF95_Slice_Direct.lua",
    "Scripts/IFLS/DF95/Edit/DF95_Rearrange_Align.lua",
    "Scripts/IFLS/DF95/Edit/DF95_Fades_Timing_Helper.lua",
    "Scripts/IFLS/DF95/Input/DF95_LUFS_AutoTarget.lua",
    "Scripts/IFLS/DF95/QA/DF95_Safety_Loudness_Menu.lua",
    "Scripts/IFLS/DF95/QA/DF95_Master_Snapshot.lua",
    "Scripts/IFLS/DF95/QA/DF95_FirstRun_LiveCheck.lua"
  }

  for _, rel in ipairs(mandatory) do
    local full = rel:gsub("/", sep)
    local fp = join(res, full)
    if not file_exists(fp) then
      log("ERR  – fehlt: " .. rel)
    else
      -- Syntax grob prüfen
      local f, err = loadfile(fp)
      if f then
        log("OK   – " .. rel)
      else
        log("ERR  – Lua-Syntaxfehler in: " .. rel .. " :: " .. tostring(err))
      end
    end
  end
  log("")
end

----------------------------------------------------------------------
-- 4) SWS-Extension checken (optional, aber empfohlen)
----------------------------------------------------------------------

local function scan_sws()
  log("=== DF95 Self-Check – SWS Extension ===")
  if r.CF_GetSWSVersion then
    local v = r.CF_GetSWSVersion()
    log("OK   – SWS gefunden, Version: " .. tostring(v))
  else
    log("WARN – SWS Extension nicht gefunden. Einige DF95-Funktionen (LUFS, Loudness-Analyse) benötigen SWS.")
  end
  log("")
end

----------------------------------------------------------------------
-- Main
----------------------------------------------------------------------

local function main()
  scan_menus()
  scan_json()
  scan_core_scripts()
  scan_sws()

  local out_dir = join(res, "Data", "DF95")
  reaper.RecursiveCreateDirectory(out_dir, 0)
  local out_path = join(out_dir, "DF95_SelfCheck_Report.txt")
  local fh = io.open(out_path, "w")
  if fh then
    for _, line in ipairs(report_lines) do
      fh:write(line .. "\n")
    end
    fh:close()
    r.ShowMessageBox("DF95 Self-Check abgeschlossen.\nReport: " .. out_path,
      "DF95 Self-Check", 0)
  else
    r.ShowMessageBox("DF95 Self-Check: konnte Report nicht schreiben:\n" .. out_path,
      "DF95 Self-Check", 0)
  end

  -- Zusätzlich im ReaScript-Console ausgeben
  r.ShowConsoleMsg(table.concat(report_lines, "\n") .. "\n")
end

main()
