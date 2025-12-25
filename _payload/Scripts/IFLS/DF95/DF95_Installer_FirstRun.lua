-- @description Installer & First-Run Wizard
-- @version 1.0
-- @author DF95
-- Führt einen Basis-Check aus und gibt Installations-/Setup-Hinweise aus.

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

local function run_selfcheck()
  local path = join(res, "Scripts", "IfeelLikeSnow", "DF95", "DF95_SelfCheck_Toolkit.lua")
  if file_exists(path) then
    dofile(path)
  else
    r.ShowMessageBox("DF95_SelfCheck_Toolkit.lua nicht gefunden:\n" .. path,
      "DF95 Installer", 0)
  end
end

local function show_instructions()
  local msg = [[
DF95 Installer & First-Run Wizard

Was dieses Script macht:
  • Prüft, ob zentrale DF95-Bestandteile vorhanden sind (Self-Check).
  • Gibt dir die Pfade für Scripts, Menüs, Data/DF95 aus.
  • Erklärt, wie du die Hub-Toolbar importierst und Icons zuweist.

Installation (Empfohlenes Vorgehen):

1. DF95-Dateien kopieren
   • Scripts  →  ]] .. join(res, "Scripts", "IfeelLikeSnow", "DF95") .. [[
   • Menüs    →  ]] .. join(res, "Menus") .. [[
   • Data     →  ]] .. join(res, "Data", "DF95") .. [[
   • Icons    →  ]] .. join(res, "Data", "toolbar_icons") .. [[ (z.B. Unterordner DF95)

2. Hub-Toolbar importieren
   • REAPER: Options → Customize menus/toolbars…
   • Eine Toolbar auswählen (z.B. Main)
   • Import… → DF95_MainToolbar_FlowErgo_Hub.ReaperMenuSet
   • Apply / Save

3. Hub-Icons zuweisen (manuell, einmalig)
   • Im Toolbar-Editor jeden DF95-Hub-Button doppelklicken.
   • „Set icon…“ → Icon-Datei wählen, z.B.:
       DF95_bus.png   → Bus & Routing Hub
       DF95_color.png → Coloring & Audition Hub
       DF95_bias.png  → Bias & Humanize Hub
       DF95_slice.png → Slicing & Edit Hub
       DF95_lufs.png  → Input & LUFS Hub
       DF95_qa.png    → QA & Safety Hub

4. Self-Check ausführen
   • Actions → Action list…
   • DF95: Self-Check & Diagnostics
   • Report wird nach Data/DF95/DF95_SelfCheck_Report.txt geschrieben.

Dieses Installer-Script ändert NICHT automatisch deine INI-Dateien
oder importiert Menüs ohne dein Zutun. Es ist ein sicherer „Guide +
Self-Check“, der dir zeigt, ob alles dort liegt, wo es liegen soll.
]]

  r.ShowConsoleMsg(msg .. "\n")
  r.ShowMessageBox("DF95 Installer: Anleitung wurde im ReaScript-Console-Fenster ausgegeben.\n" ..
    "Bitte Console öffnen (View → ReaScript console log).",
    "DF95 Installer", 0)
end

local function main()
  show_instructions()
  run_selfcheck()
end

main()
