-- @description PackWizard from KitMeta (C2 SamplerSubsystem)
-- @version 1.0
-- @author DF95
-- @about
--   Liest die vom C2-SamplerSubsystem geschriebenen Kit-Metadaten
--   (ExtState "DF95_SAMPLER_KIT_META" / "last_kit"), zeigt eine kurze
--   Zusammenfassung der belegten Rollen (Kick/Snare/Hats/etc.) an
--   und setzt Export-Tags (Role/Source/FXFlavor) passend zum DrumKit.
--
--   Optional kann direkt der DF95_Export_PackWizard gestartet werden,
--   so dass aus dem aktuell vorbereiteten Projekt (Bus-Routing + Selektion)
--   ein konsistenter Sample-Pack mit NameEngine/AutoTag-Struktur erzeugt wird.
--
--   Dies ist die "Bridge" zwischen:
--     * C2 KitWizard / Sampler_Core
--     * AutoTag_Core / Export_Core / PackWizard
--
--   Workflow:
--     1. Mit DF95_Sampler_KitWizard ein C2-Kit bauen.
--     2. Sicherstellen, dass deine Slices/Busse so selektiert sind,
--        wie du sie für das Pack exportieren willst.
--     3. Dieses Script ausführen.
--     4. Tags für Export werden gesetzt (Role=DrumKit, Source=SamplerKit, FXFlavor=C2Kit),
--        und optional der DF95_Export_PackWizard direkt gestartet.
--
--   Hinweis:
--     Diese Version erzeugt noch keine pro-Role-Subpacks (Kicks/Snares/...)
--     sondern markiert das gesamte Set zunächst als DrumKit-basiertes Pack.
--     Die pro-Role-Aufteilung kann in einer späteren Version zusätzlich
--     über die in ExtState gespeicherten Slot-Rollen umgesetzt werden.

local r = reaper

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_last_kit_meta()
  local json = r.GetExtState("DF95_SAMPLER_KIT_META", "last_kit")
  if not json or json == "" then return nil end
  return json
end

local function parse_roles_from_json(json)
  local roles = {}
  for role in json:gmatch('"role"%s*:%s*"([^"]-)"') do
    if role ~= nil and role ~= "" and role ~= "null" then
      roles[role] = (roles[role] or 0) + 1
    end
  end
  return roles
end

local function build_roles_summary(roles)
  local parts = {}
  for role, count in pairs(roles) do
    parts[#parts+1] = string.format("%s: %d Slots", role, count)
  end
  if #parts == 0 then
    return "Keine Rollen im KitMeta gefunden (evtl. alte Kits ohne Annotation?)."
  end
  table.sort(parts)
  return table.concat(parts, "\\n")
end

local function set_drumkit_export_tags()
  -- Wir überschreiben Role/Source/FXFlavor gezielt für DrumKit-Packs
  r.SetExtState("DF95_EXPORT_TAGS", "Role", "DrumKit", true)
  r.SetExtState("DF95_EXPORT_TAGS", "Source", "SamplerKit", true)
  r.SetExtState("DF95_EXPORT_TAGS", "FXFlavor", "C2Kit", true)
end

local function run_packwizard()
  local dir = df95_root()
  if dir == "" then
    r.ShowMessageBox("DF95_PackWizard_From_KitMeta: Konnte Script-Ordner nicht bestimmen.", "DF95 PackWizard from KitMeta", 0)
    return
  end
  local ok, err = pcall(dofile, dir .. "DF95_Export_PackWizard.lua")
  if not ok then
    r.ShowMessageBox("Fehler beim Start von DF95_Export_PackWizard.lua:\\n" .. tostring(err), "DF95 PackWizard from KitMeta", 0)
  end
end

local function main()
  local json = load_last_kit_meta()
  if not json then
    r.ShowMessageBox(
      "Keine Kit-Metadaten gefunden.\\n" ..
      "Bitte zuerst mit DF95_Sampler_KitWizard ein C2-Kit bauen,\\n" ..
      "dann dieses Script erneut ausführen.",
      "DF95 PackWizard from KitMeta",
      0
    )
    return
  end

  local roles = parse_roles_from_json(json)
  local summary = build_roles_summary(roles)

  local msg = "Gefundene Rollen im letzten C2-Kit:\\n\\n" .. summary ..
              "\\n\\nExport-Tags werden auf Role=DrumKit, Source=SamplerKit, FXFlavor=C2Kit gesetzt." ..
              "\\n\\nMöchtest du jetzt direkt den DF95_Export_PackWizard starten?"

  local ret = r.ShowMessageBox(msg, "DF95 PackWizard from KitMeta", 6) -- 6 = Yes/No
  -- Korrigieren: 6 ist Yes/No, aber hier nehmen wir 6, damit wir Yes/No unterscheiden
  if ret == 2 then
    -- Cancel
    return
  end

  -- In REAPER Doku: MB type=6 -> Yes=6, No=7
  if ret == 6 then
    set_drumkit_export_tags()
    run_packwizard()
  else
    -- Nur Tags setzen, keinen Auto-Start
    set_drumkit_export_tags()
  end
end

main()
