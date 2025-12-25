-- DF95_Dump_All_FX_Params_Advanced.lua
-- Vollständiger Parameter-Dump für alle Plugins (bestmöglich):
--   - Scannt installierte VST/VST3 aus reaper-vstplugins64.ini
--   - Scannt alle FX im aktuellen Projekt (Tracks + Master)
--   - Speichert alle Parameter (Name, Index, Min/Max, aktueller Wert)
--   - Schreibt:
--       1) Textdump: DF95_AllFX_ParamDump.txt
--       2) JSON-ähnliche Struktur: DF95_AllFX_ParamDump.json
--
-- Hinweis:
--   Monitoring-FX werden hier NICHT explizit behandelt, weil der Zugriff
--   je nach REAPER-Version etwas anders ist. Falls du sie brauchst,
--   kann man sie später gezielt ergänzen.
--
-- Verwendung:
--   1. Datei in REAPER-Scripts-Ordner legen (z.B. Scripts/IFLS/DF95/)
--   2. In REAPER: Actions -> Show Action List -> Load ReaScript...
--   3. Skript auswählen und ausführen.
--   4. Dump-Dateien an ChatGPT geben für ParamMaps / FX-Ketten / Preset-System.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

------------------------------------------------------------
-- Konfiguration
------------------------------------------------------------

local DO_SCAN_INSTALLED_VST = true    -- aus reaper-vstplugins64.ini
local DO_SCAN_PROJECT_FX    = true    -- alle FX im aktuellen Projekt

------------------------------------------------------------
-- Pfade & Output-Dateien vorbereiten
------------------------------------------------------------

local resource_path = r.GetResourcePath()
local df95_dir = resource_path .. "/Scripts/IFLS/DF95"
local txt_path = df95_dir .. "/DF95_AllFX_ParamDump.txt"
local json_path = df95_dir .. "/DF95_AllFX_ParamDump.json"
local vst_ini_path = resource_path .. "/reaper-vstplugins64.ini"

r.RecursiveCreateDirectory(df95_dir, 0)

local out_txt, err_txt = io.open(txt_path, "w")
if not out_txt then
  r.ShowMessageBox("Konnte Text-Output-Datei nicht erstellen:\n" .. tostring(err_txt), "DF95 Dump All FX Params Advanced", 0)
  return
end

local out_json, err_json = io.open(json_path, "w")
if not out_json then
  out_txt:close()
  r.ShowMessageBox("Konnte JSON-Output-Datei nicht erstellen:\n" .. tostring(err_json), "DF95 Dump All FX Params Advanced", 0)
  return
end

-- JSON-Grundstruktur beginnen
out_json:write("{\n")
out_json:write('  "fx": [\n')

------------------------------------------------------------
-- Temp-Track zum instanziieren von Plugins
------------------------------------------------------------

local proj = 0
local temp_track_idx = r.CountTracks(proj)
r.InsertTrackAtIndex(temp_track_idx, true)
local temp_track = r.GetTrack(proj, temp_track_idx)
r.GetSetMediaTrackInfo_String(temp_track, "P_NAME", "__DF95_PARAMSCAN_TMP__", true)

------------------------------------------------------------
-- Helper: FX-Parameter dumpen
------------------------------------------------------------

local seen_keys = {}      -- pro FX-Typ (fx_ident oder fx_name)
local total_fx_types = 0  -- Anzahl unterschiedlicher FX-Typen
local total_params = 0    -- Gesamtanzahl Parameterzeilen

local function escape_json_str(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  return s
end

local function dump_fx_params(track, fx, source, instance_info)
  if not track or fx < 0 then return end

  local retval, fx_name = r.TrackFX_GetFXName(track, fx, "")
  if not retval then return end

  local ok_ident, ident = r.TrackFX_GetNamedConfigParm(track, fx, "fx_ident")
  local key = ident or fx_name

  local is_new_type = false
  if not seen_keys[key] then
    seen_keys[key] = true
    is_new_type = true
    total_fx_types = total_fx_types + 1
  end

  local num_params = r.TrackFX_GetNumParams(track, fx)

  -- TEXT-DUMP: pro neuem FX-Typ volles Listing
  if is_new_type then
    out_txt:write("================================================================\n")
    out_txt:write("Parameter Dump for FX: " .. fx_name .. "\n")
    out_txt:write("Source: " .. (source or "UNKNOWN") .. "\n")
    if ident then
      out_txt:write("FX Ident: " .. ident .. "\n")
    end
    out_txt:write("Num Params: " .. tostring(num_params) .. "\n\n")

    for p = 0, num_params - 1 do
      local _, pname = r.TrackFX_GetParamName(track, fx, p, "")
      local val, minval, maxval = r.TrackFX_GetParamEx(track, fx, p)
      val = val or 0.0
      minval = minval or 0.0
      maxval = maxval or 1.0

      out_txt:write(string.format(
        "  Param %03d: %s | value=%.6f | min=%.6f | max=%.6f\n",
        p, pname, val, minval, maxval
      ))

      total_params = total_params + 1
    end

    out_txt:write("\n\n")
  end

  -- JSON: für JEDE Instanz (auch im Projekt) ein Eintrag
  -- Damit kann man z.B. auch FX-Ketten exakt nachbauen.
  out_json:write("    {\n")
  out_json:write('      "fx_name": "' .. escape_json_str(fx_name) .. '",\n')
  if ident then
    out_json:write('      "fx_ident": "' .. escape_json_str(ident) .. '",\n')
  else
    out_json:write('      "fx_ident": null,\n')
  end
  out_json:write('      "source": "' .. escape_json_str(source or "UNKNOWN") .. '",\n')

  if instance_info then
    out_json:write('      "instance": {\n')
    out_json:write('        "track_name": "' .. escape_json_str(instance_info.track_name or "") .. '",\n')
    out_json:write('        "track_index": ' .. tostring(instance_info.track_index or -1) .. ',\n')
    out_json:write('        "fx_index": ' .. tostring(instance_info.fx_index or -1) .. ',\n')
    out_json:write('        "is_master": ' .. (instance_info.is_master and "true" or "false") .. '\n')
    out_json:write("      },\n")
  else
    out_json:write('      "instance": null,\n')
  end

  out_json:write('      "num_params": ' .. tostring(num_params) .. ",\n")
  out_json:write('      "params": [\n')

  for p = 0, num_params - 1 do
    local _, pname = r.TrackFX_GetParamName(track, fx, p, "")
    local val, minval, maxval = r.TrackFX_GetParamEx(track, fx, p)
    val = val or 0.0
    minval = minval or 0.0
    maxval = maxval or 1.0

    out_json:write("        {\n")
    out_json:write('          "index": ' .. tostring(p) .. ',\n')
    out_json:write('          "name": "' .. escape_json_str(pname) .. '",\n')
    out_json:write('          "value": ' .. string.format("%.6f", val) .. ',\n')
    out_json:write('          "min": ' .. string.format("%.6f", minval) .. ',\n')
    out_json:write('          "max": ' .. string.format("%.6f", maxval) .. "\n")
    out_json:write("        }")
    if p < num_params - 1 then
      out_json:write(",\n")
    else
      out_json:write("\n")
    end
  end

  out_json:write("      ]\n")
  out_json:write("    },\n")
end

------------------------------------------------------------
-- Pass 1: Installed VST/VST3 from INI
------------------------------------------------------------

local function scan_installed_vst_from_ini()
  local f = io.open(vst_ini_path, "r")
  if not f then
    msg("Hinweis: reaper-vstplugins64.ini nicht gefunden, überspringe Installed-Scan.")
    return
  end

  msg("Starte Scan installierter VST/VST3...")

  for line in f:lines() do
    line = line:gsub("\r", "")
    line = line:gsub("\n", "")
    line = line:match("^%s*(.-)%s*$")

    if line ~= "" and line:find("!!!VST") then
      local left, right = line:match("^(.-)=(.+)$")
      if right then
        local namePart, flags = right:match("^(.-)!!!(.-)$")
        local browser_name = (namePart or right):match("^%s*(.-)%s*$")
        local flag = flags or ""

        if browser_name and browser_name ~= "" then
          msg("  -> Versuche Plugin zu laden: " .. browser_name .. " (" .. flag .. ")")
          local fx = r.TrackFX_AddByName(temp_track, browser_name, false, -1000)
          if fx >= 0 then
            dump_fx_params(temp_track, fx, "INSTALLED_SCAN")
            r.TrackFX_Delete(temp_track, fx)
          else
            local prefix = flag:find("VST3") and "VST3:" or "VST:"
            local fx2 = r.TrackFX_AddByName(temp_track, prefix .. " " .. browser_name, false, -1000)
            if fx2 >= 0 then
              dump_fx_params(temp_track, fx2, "INSTALLED_SCAN")
              r.TrackFX_Delete(temp_track, fx2)
            else
              msg("  !! Konnte Plugin nicht instanziieren: " .. browser_name .. " (" .. flag .. ")")
            end
          end
        end
      end
    end
  end

  f:close()
end

------------------------------------------------------------
-- Pass 2: Projekt-FX (JSFX, etc)
------------------------------------------------------------

local function scan_project_fx()
  msg("Scanne FX im aktuellen Projekt...")

  local proj = 0
  local track_cnt = r.CountTracks(proj)

  for i = 0, track_cnt - 1 do
    local tr = r.GetTrack(proj, i)
    local _, tr_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    local fx_cnt = r.TrackFX_GetCount(tr)
    for fx = 0, fx_cnt - 1 do
      dump_fx_params(tr, fx, "PROJECT_TRACKS", {
        track_name  = tr_name,
        track_index = i,
        fx_index    = fx,
        is_master   = false,
      })
    end
  end

  local master = r.GetMasterTrack(proj)
  if master then
    local _, m_name = r.GetSetMediaTrackInfo_String(master, "P_NAME", "", false)
    local mfx = r.TrackFX_GetCount(master)
    for fx = 0, mfx - 1 do
      dump_fx_params(master, fx, "PROJECT_MASTER", {
        track_name  = m_name ~= "" and m_name or "MASTER",
        track_index = -1,
        fx_index    = fx,
        is_master   = true,
      })
    end
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

r.ClearConsole()
r.Undo_BeginBlock()
r.PreventUIRefresh(1)

if DO_SCAN_INSTALLED_VST then
  scan_installed_vst_from_ini()
end

if DO_SCAN_PROJECT_FX then
  scan_project_fx()
end

-- Temp-Track entfernen
r.DeleteTrack(temp_track)

r.PreventUIRefresh(-1)
r.Undo_EndBlock("DF95 Dump All FX Params Advanced", -1)

-- JSON schließen: letztes Element ggf. mit Komma, aber JSON-Parser sollte tolerant sein.
out_json:write("    null\n") -- Dummy-Eintrag, um das letzte Komma zu "entschärfen"
out_json:write("  ]\n}\n")

out_txt:close()
out_json:close()

local summary = string.format(
  "Fertig!\n\nFX-Typen: %d\nGesamt-Parameter-Zeilen (Text): ~%d\n\nTextdump:\n%s\n\nJSON-Struktur:\n%s",
  total_fx_types, total_params, txt_path, json_path
)

r.ShowMessageBox(summary, "DF95 Dump All FX Params Advanced", 0)
