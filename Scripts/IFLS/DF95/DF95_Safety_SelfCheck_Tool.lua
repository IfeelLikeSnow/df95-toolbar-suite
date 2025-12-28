-- @description DF95 Safety SelfCheck Tool (Stufe 4)
-- @version 1.0
-- @author DF95
-- @about
--   Führt eine einfache Integritätsprüfung über das DF95-System aus:
--   - prüft, ob zentrale Scripts vorhanden sind
--   - prüft, ob FXChains-Verzeichnisse existieren
--   - prüft, ob SWS-Extension verfügbar ist
--   Diese Version nimmt keine Änderungen vor, sondern gibt nur einen Report aus.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function check_file_exists(rel_path)
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local full = res .. sep .. rel_path:gsub("[/\\]", sep)
  local f = io.open(full, "rb")
  if f then f:close() return true, full end
  return false, full
end

local function run_selfcheck()
  r.ShowConsoleMsg("=== DF95 Safety SelfCheck (Stufe 4) ===\n")

  -- 1) Zentrale Scripts
  local core_scripts = {
    "Scripts/IFLS/DF95/DF95_V183_PolyWAV_Toolbox_V5.lua",
    "Scripts/IFLS/DF95/DF95_Explode_AutoBus_Smart.lua",
    "Scripts/IFLS/DF95/DF95_V160_SampleDB_AIWorker_ZoomF6.lua",
    "Scripts/IFLS/DF95/DF95_V132_SampleDB_Inspector_V4_AI_Mapping.lua",
    "Scripts/IFLS/DF95/DF95_Artist_IDM_FXBus_Selector_ImGui.lua",
    "Scripts/IFLS/DF95/DF95_FX_MasterSelector_ImGui.lua"
  }

  msg("-> Prüfe Kern-Scripts:")
  for _, rel in ipairs(core_scripts) do
    local ok, full = check_file_exists(rel)
    if ok then
      msg("  [OK] " .. rel)
    else
      msg("  [FEHLT] " .. rel .. "  (erwartet: " .. full .. ")")
    end
  end

  -- 2) FXChains-Verzeichnisse
  local fx_dirs = {
    "FXChains/DF95_FXBus_Artist",
    "FXChains/DF95_MicFX",
    "FXChains/DF95_ArtistColorBus",
    "FXChains/DF95_ArtistMasterBus"
  }

  msg("\n-> Prüfe FXChains-Verzeichnisse:")
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  for _, rel in ipairs(fx_dirs) do
    local full = res .. sep .. rel:gsub("[/\\]", sep)
    local ok = r.EnumerateFiles(full, 0) ~= nil or r.EnumerateSubdirectories(full, 0) ~= nil
    if ok then
      msg("  [OK] " .. rel)
    else
      msg("  [WARNUNG] " .. rel .. " scheint leer oder fehlt.")
    end
  end

  -- 3) SWS-Extension
  msg("\n-> Prüfe SWS-Extension:")
  if r.BR_GetMouseCursorContext then
    msg("  [OK] SWS/S&M Extension gefunden.")
  else
    msg("  [WARNUNG] SWS/S&M Extension nicht gefunden – einige DF95-Funktionen benötigen SWS.")
  end

  msg("\n=== SelfCheck abgeschlossen. Diese Version nimmt keine Änderungen vor. ===\n")
end

run_selfcheck()
