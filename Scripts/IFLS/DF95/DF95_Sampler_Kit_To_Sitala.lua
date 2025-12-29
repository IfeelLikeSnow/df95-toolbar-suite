\
-- @description DF95_Sampler_Kit_To_Sitala
-- @version 1.0
-- @author DF95
-- @about
--   Adapter: DF95_Sampler_KitSchema -> Sitala-Kit-Umgebung.
--   Da Sitala kein offizielles API fuer das Laden von Samples pro Pad bietet,
--   richtet dieses Modul die Sitala-Instanz ein (via DF95_Sampler_SitalaKitBuilder_v1)
--   und zeigt eine Zuordnungstabelle (Slot -> Datei) im ReaScript-Console-Log an.
--
--   So kannst du schnell sehen, welche Samples auf welche Pads/Noten gemappt werden sollen.

local r = reaper

local M = {}

local function run_sitala_kit_builder()
  local res = r.GetResourcePath()
  local sep = package.config:sub(1,1)
  local path = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep .. "DF95_Sampler_SitalaKitBuilder_v1.lua"
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox("Konnte DF95_Sampler_SitalaKitBuilder_v1.lua nicht laden:\n" .. tostring(err) .. "\nPfad: " .. path, "DF95 Kit -> Sitala", 0)
    return
  end
  f()
end

local function msg(line)
  r.ShowConsoleMsg(tostring(line) .. "\\n")
end

-- Baut die Sitala-Umgebung auf und zeigt die Slot-Mapping-Tabelle an.
function M.ensure_sitala_and_print_mapping(kit)
  if not kit or type(kit) ~= "table" or type(kit.slots) ~= "table" then
    r.ShowMessageBox("Kit ist ungueltig oder enthaelt keine Slots.", "DF95 Kit -> Sitala", 0)
    return
  end

  run_sitala_kit_builder()

  r.ShowConsoleMsg("==== DF95 Kit -> Sitala Mapping ====" .. "\\n")
  if kit.meta then
    msg("Kit: " .. (kit.meta.name or ""))
    msg("Artist: " .. (kit.meta.artist or ""))
    msg("Source: " .. (kit.meta.source or ""))
    msg("BPM: " .. tostring(kit.meta.bpm or 0))
  end
  msg("Slots:")
  for i, slot in ipairs(kit.slots) do
    local line = string.format("%02d  [%s]  note=%d  file=%s",
      i,
      tostring(slot.id or ("SLOT_"..i)),
      tonumber(slot.root or 0) or 0,
      tostring(slot.file or ""))
    msg(line)
  end
  msg("Hinweis: Ziehe die oben gelisteten Dateien in Sitala-Pads und verwende die angegebenen Noten als Referenz.")
end

return M
