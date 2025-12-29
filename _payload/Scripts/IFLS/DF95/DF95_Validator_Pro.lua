-- @description Validator Pro (Deep System Check)
-- @version 1.1
-- @author DF95
-- Führt einen erweiterten DF95-Check durch: Menüs, Scripts, JSON,
-- BiasProfiles, SmartCeiling, Chains, Platzhalter-Skripte und
-- prüft zusätzlich Extension-Actions (SWS) sowie zentrale JSFX.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function join(...)
  local t = { ... }
  return table.concat(t, sep)
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local report = {}
local function log(line)
  report[#report+1] = line
end

----------------------------------------------------------------------
-- Hilfsfunktionen für Directory-Scans
----------------------------------------------------------------------

local function scandir_files(dir)
  local out = {}
  local i = 0
  while true do
    local name = r.EnumerateFiles(dir, i)
    if not name then break end
    out[#out+1] = join(dir, name)
    i = i + 1
  end
  return out
end

local function scandir_dirs(dir)
  local out = {}
  local i = 0
  while true do
    local name = r.EnumerateSubdirectories(dir, i)
    if not name then break end
    out[#out+1] = join(dir, name)
    i = i + 1
  end
  return out
end

----------------------------------------------------------------------
-- 1) Optional: SelfCheck aufrufen, wenn vorhanden
----------------------------------------------------------------------

local function run_selfcheck_if_available()
  local sc_path = join(res, "Scripts", "IfeelLikeSnow", "DF95", "DF95_SelfCheck_Toolkit.lua")
  log("=== DF95 Validator Pro – SelfCheck Hook ===")
  if file_exists(sc_path) then
    log("SelfCheck gefunden, führe ihn zuerst aus...")
    dofile(sc_path)
    log("SelfCheck abgeschlossen.\n")
  else
    log("WARN – DF95_SelfCheck_Toolkit.lua nicht gefunden: " .. sc_path .. "\n")
  end
end

----------------------------------------------------------------------
-- 2) Platzhalter-Skripte finden
----------------------------------------------------------------------

local function scan_placeholders()
  log("=== DF95 Validator Pro – Platzhalter-Skripte ===")
  local base = join(res, "Scripts", "IfeelLikeSnow", "DF95")
  if not file_exists(base) then
    log("ERR  – DF95-Script-Basis fehlt: " .. base)
    log("")
    return
  end
  local count = 0

  local function recurse(dir)
    local i = 0
    while true do
      local f_name = r.EnumerateFiles(dir, i)
      if not f_name then break end
      if f_name:lower():match("%.lua$") then
        local full = join(dir, f_name)
        local fh = io.open(full, "r")
        if fh then
          local txt = fh:read("*all")
          fh:close()
          if txt:match("placeholder") or txt:match("PLACEHOLDER") then
            count = count + 1
            log("FOUND placeholder in: " .. full:sub(#res+2))
          end
        end
      end
      i = i + 1
    end
    local j = 0
    while true do
      local d = r.EnumerateSubdirectories(dir, j)
      if not d then break end
      recurse(join(dir, d))
      j = j + 1
    end
  end

  recurse(base)
  if count == 0 then
    log("OK   – keine Platzhalter-Skripte gefunden.")
  end
  log("")
end

----------------------------------------------------------------------
-- 3) BiasProfiles prüfen
----------------------------------------------------------------------

local function scan_biasprofiles()
  log("=== DF95 Validator Pro – BiasProfiles ===")
  local bp_dir = join(res, "Data", "DF95", "BiasProfiles")
  if not file_exists(bp_dir) then
    log("WARN – BiasProfiles-Verzeichnis fehlt: " .. bp_dir)
    log("")
    return
  end

  local has_decode = r.JSON_Decode ~= nil
  local i = 0
  local any = false
  while true do
    local fname = r.EnumerateFiles(bp_dir, i)
    if not fname then break end
    if fname:lower():match("%.json$") then
      any = true
      local full = join(bp_dir, fname)
      local fh = io.open(full, "rb")
      if fh then
        local txt = fh:read("*all")
        fh:close()
        if has_decode then
          local ok, obj = pcall(r.JSON_Decode, txt)
          if ok and type(obj) == "table" then
            if type(obj.weights) == "table" and type(obj.random_profile) == "table" then
              log("OK   – BiasProfile: " .. fname)
            else
              log("ERR  – BiasProfile ohne 'weights' und 'random_profile': " .. fname)
            end
          else
            log("ERR  – JSON ungültig: " .. fname)
          end
        else
          if txt:match("weights") and txt:match("random_profile") then
            log("OK?  – BiasProfile (oberflächlich): " .. fname)
          else
            log("WARN – BiasProfile-Struktur fraglich: " .. fname)
          end
        end
      else
        log("ERR  – kann BiasProfile nicht lesen: " .. fname)
      end
    end
    i = i + 1
  end

  if not any then
    log("WARN – keine BiasProfiles-JSONs unter: " .. bp_dir)
  end
  log("")
end

----------------------------------------------------------------------
-- 4) SmartCeiling.json prüfen
----------------------------------------------------------------------

local function scan_smartceiling()
  log("=== DF95 Validator Pro – SmartCeiling.json ===")
  local path = join(res, "Data", "DF95", "SmartCeiling.json")
  if not file_exists(path) then
    log("WARN – SmartCeiling.json nicht gefunden: " .. path)
    log("")
    return
  end

  local fh = io.open(path, "rb")
  if not fh then
    log("ERR  – kann SmartCeiling.json nicht öffnen.")
    log("")
    return
  end
  local txt = fh:read("*all")
  fh:close()

  if not r.JSON_Decode then
    if txt:match("Default") then
      log("OK?  – SmartCeiling.json vorhanden (oberflächlich geprüft).")
    else
      log("WARN – SmartCeiling.json könnte ungültig sein (kein JSON-Parser verfügbar).")
    end
    log("")
    return
  end

  local ok, obj = pcall(r.JSON_Decode, txt)
  if not ok or type(obj) ~= "table" then
    log("ERR  – SmartCeiling.json ist kein gültiges JSON-Objekt.")
    log("")
    return
  end

  local required_keys = { "Default", "Master", "FXBus", "Coloring", "Artists", "Neutral" }
  local good = true
  for _, key in ipairs(required_keys) do
    local v = obj[key]
    if type(v) ~= "number" then
      log("ERR  – SmartCeiling[" .. key .. "] fehlt oder ist kein number.")
      good = false
    end
  end
  if good then
    log("OK   – SmartCeiling.json vollständig und gültig.")
  end
  log("")
end

----------------------------------------------------------------------
-- 5) Chains grob prüfen (.RfxChain)
----------------------------------------------------------------------

local function scan_chains()
  log("=== DF95 Validator Pro – Chains (.RfxChain) ===")
  local chains_root = join(res, "Data", "DF95", "Chains")
  if not file_exists(chains_root) then
    log("WARN – Chains-Root (Data/DF95/Chains) nicht gefunden: " .. chains_root)
    log("")
    return
  end

  local function check_chain_file(path)
    local fh = io.open(path, "r")
    if not fh then
      log("ERR  – kann Chain nicht lesen: " .. path:sub(#res+2))
      return
    end
    local first = fh:read("*line") or ""
    local content = fh:read("*all") or ""
    fh:close()
    if not first:match("<FXCHAIN") and not content:match("<FXCHAIN") then
      log("WARN – .RfxChain ohne '<FXCHAIN' Header: " .. path:sub(#res+2))
    end
    if content == "" or #content < 10 then
      log("WARN – .RfxChain scheint leer/zu kurz: " .. path:sub(#res+2))
    end
  end

  local function recurse(dir)
    local i = 0
    while true do
      local name = r.EnumerateFiles(dir, i)
      if not name then break end
      if name:lower():match("%.rfxchain$") then
        local full = join(dir, name)
        check_chain_file(full)
      end
      i = i + 1
    end
    local j = 0
    while true do
      local d = r.EnumerateSubdirectories(dir, j)
      if not d then break end
      recurse(join(dir, d))
      j = j + 1
    end
  end

  recurse(chains_root)
  log("")
end

----------------------------------------------------------------------
-- 6) Extension-Actions (SWS etc.) prüfen
----------------------------------------------------------------------

local function scan_extension_actions()
  log("=== DF95 Validator Pro – Extension-Actions (SWS etc.) ===")
  local menus_dir = join(res, "Menus")
  if not file_exists(menus_dir) then
    log("WARN – Menüs-Verzeichnis fehlt: " .. menus_dir)
    log("")
    return
  end

  local actions = {}

  local function collect_ids_from_file(path)
    local fh = io.open(path, "r")
    if not fh then return end
    for line in fh:lines() do
      -- einfache Heuristik: _SWS... oder _RS.... etc.
      for id in line:gmatch("(_[A-Z0-9_]+)") do
        if id:match("^_SWS") or id:match("^_RS") then
          actions[id] = true
        end
      end
    end
    fh:close()
  end

  -- nur DF95-bezogene Menüs scannen
  local i = 0
  while true do
    local fname = r.EnumerateFiles(menus_dir, i)
    if not fname then break end
    if fname:match("^DF95_") and fname:match("%.ReaperMenuSet$") then
      collect_ids_from_file(join(menus_dir, fname))
    end
    i = i + 1
  end

  local any = false
  for id,_ in pairs(actions) do any = true break end
  if not any then
    log("OK   – keine expliziten Extension-Actions (_SWS, _RS) in DF95-Menüs gefunden (oder sie werden nur indirekt genutzt).")
    log("")
    return
  end

  for id,_ in pairs(actions) do
    local cmd = r.NamedCommandLookup(id)
    if cmd == 0 then
      log("ERR  – Extension-Action unbekannt oder nicht verfügbar: " .. id)
    else
      log("OK   – Extension-Action vorhanden: " .. id .. " (CommandID=" .. tostring(cmd) .. ")")
    end
  end
  log("")
end

----------------------------------------------------------------------
-- 7) Zentrale JSFX prüfen
----------------------------------------------------------------------

local function scan_jsfx()
  log("=== DF95 Validator Pro – JSFX ===")
  local effects_root = join(res, "Effects")
  if not file_exists(effects_root) then
    log("WARN – Effects-Verzeichnis nicht gefunden: " .. effects_root)
    log("")
    return
  end

  -- Prüfe DF95-eigenes JSFX
  local df95_meter = join(effects_root, "DF95", "DF95_Dynamic_Meter_v1.jsfx")
  if file_exists(df95_meter) then
    log("OK   – DF95 JSFX gefunden: Effects/DF95/DF95_Dynamic_Meter_v1.jsfx")
  else
    log("WARN – DF95 JSFX fehlt: Effects/DF95/DF95_Dynamic_Meter_v1.jsfx")
  end

  -- Optional: JS: Volume grob testen (Existenz der Datei ist nicht trivial,
  -- daher nur ein Hinweis, dass REAPER-Standard-JS sinnvoll sind)
  log("HINWEIS – Standard-JSFX wie 'JS: Volume' werden vorausgesetzt. " ..
      "Falls REAPER ohne JSFX installiert wurde, können einige DF95-Funktionen eingeschränkt sein.")
  log("")
end

----------------------------------------------------------------------
-- 8) Zusammenfassung und Report schreiben
----------------------------------------------------------------------

local function write_report()
  local out_dir = join(res, "Data", "DF95")
  r.RecursiveCreateDirectory(out_dir, 0)
  local out_path = join(out_dir, "DF95_ValidatorPro_Report.txt")
  local fh = io.open(out_path, "w")
  if fh then
    for _, line in ipairs(report) do
      fh:write(line .. "\n")
    end
    fh:close()
    r.ShowMessageBox("DF95 Validator Pro abgeschlossen.\nReport: " .. out_path,
      "DF95 Validator Pro", 0)
  else
    r.ShowMessageBox("DF95 Validator Pro: konnte Report nicht schreiben:\n" .. out_path,
      "DF95 Validator Pro", 0)
  end
  r.ShowConsoleMsg(table.concat(report, "\n") .. "\n")
end

----------------------------------------------------------------------
-- Main
----------------------------------------------------------------------

local function main()
  run_selfcheck_if_available()
  scan_placeholders()
  scan_biasprofiles()
  scan_smartceiling()
  scan_chains()
  scan_extension_actions()
  scan_jsfx()
  write_report()
end

main()
