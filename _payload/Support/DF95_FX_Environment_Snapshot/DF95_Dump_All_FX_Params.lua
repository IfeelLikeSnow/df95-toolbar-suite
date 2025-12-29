-- DF95_Dump_All_FX_Params.lua
-- Scannt (bestmöglich) alle installierten VST/VST3-Plugins + alle FX im aktuellen Projekt
-- und schreibt eine komplette Parameterliste pro Plugin in eine Textdatei.
--
-- Ausgabe:
--   <REAPER-ResourcePath>/Scripts/IFLS/DF95/DF95_AllFX_ParamDump.txt

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

------------------------------------------------------------
-- Pfade & Output-Datei vorbereiten
------------------------------------------------------------

local resource_path = r.GetResourcePath()
local df95_dir = resource_path .. "/Scripts/IFLS/DF95"
local dump_path = df95_dir .. "/DF95_AllFX_ParamDump.txt"
local vst_ini_path = resource_path .. "/reaper-vstplugins64.ini"

r.RecursiveCreateDirectory(df95_dir, 0)

local out, err = io.open(dump_path, "w")
if not out then
  r.ShowMessageBox("Konnte Output-Datei nicht erstellen:\n" .. tostring(err), "DF95 Dump All FX Params", 0)
  return
end

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

local seen_keys = {}  -- key = fx_ident oder fx_name

local function dump_fx_params(track, fx, source)
  if not track or fx < 0 then return end

  local retval, fx_name = r.TrackFX_GetFXName(track, fx, "")
  if not retval then return end

  local ok_ident, ident = r.TrackFX_GetNamedConfigParm(track, fx, "fx_ident")
  local key = ident or fx_name
  if seen_keys[key] then return end
  seen_keys[key] = true

  local num_params = r.TrackFX_GetNumParams(track, fx)

  out:write("================================================================\n")
  out:write("Parameter Dump for FX: " .. fx_name .. "\n")
  out:write("Source: " .. (source or "UNKNOWN") .. "\n")
  if ident then out:write("FX Ident: " .. ident .. "\n") end
  out:write("Num Params: " .. tostring(num_params) .. "\n\n")

  for p = 0, num_params - 1 do
    local _, pname = r.TrackFX_GetParamName(track, fx, p, "")
    local val, minval, maxval = r.TrackFX_GetParamEx(track, fx, p)
    out:write(string.format("  Param %03d: %s | value=%.6f | min=%.6f | max=%.6f\n", p, pname, val or 0, minval or 0, maxval or 1))
  end

  out:write("\n\n")
end

------------------------------------------------------------
-- Pass 1: Installed VST/VST3 from INI
------------------------------------------------------------

local function scan_installed_vst_from_ini()
  local f = io.open(vst_ini_path, "r")
  if not f then msg("INI nicht gefunden, überspringe Installed-Scan.") return end

  msg("Starte Scan installierter VST/VST3...")

  for line in f:lines() do
    if line:find("!!!VST") then
      local left, right = line:match("^(.-)=(.+)$")
      if right then
        local namePart, flags = right:match("^(.-)!!!(.-)$")
        local browser_name = (namePart or right):match("^%s*(.-)%s*$")
        local flag = flags or ""

        if browser_name and browser_name ~= "" then
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
    local fx_cnt = r.TrackFX_GetCount(tr)
    for fx = 0, fx_cnt - 1 do dump_fx_params(tr, fx, "PROJECT_TRACKS") end
  end

  local master = r.GetMasterTrack(proj)
  if master then
    local mfx = r.TrackFX_GetCount(master)
    for fx = 0, mfx - 1 do dump_fx_params(master, fx, "PROJECT_MASTER") end
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

scan_installed_vst_from_ini()
scan_project_fx()

r.DeleteTrack(temp_track)

r.PreventUIRefresh(-1)
r.Undo_EndBlock("DF95 Dump All FX Params", -1)

out:close()

r.ShowMessageBox("Fertig! Dump gespeichert unter:\n" .. dump_path, "DF95 Dump All FX Params", 0)
