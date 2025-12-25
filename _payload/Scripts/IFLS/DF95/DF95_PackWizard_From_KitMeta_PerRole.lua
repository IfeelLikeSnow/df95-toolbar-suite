-- @description PackWizard from KitMeta (Per-Role MultiPack)
-- @version 1.0
-- @author DF95
-- @about
--   Nutzt die vom C2-SamplerSubsystem geschriebenen Kit-Metadaten
--   (ExtState "DF95_SAMPLER_KIT_META" / "last_kit"), um für jede
--   gefundene Rolle (Kick/Snare/Hats/MicroPerc/ClicksPops/...) nacheinander
--   einen Export-Pack-Lauf zu starten.
--
--   Jeder Lauf setzt:
--     * Role   = <konkrete Rolle>  (z.B. "Kick", "Snare", "Hats", ...)
--     * Source = "SamplerKit"
--     * FXFlavor = "C2Kit"
--
--   und ruft dann DF95_Export_PackWizard.lua auf.
--
--   WICHTIG:
--     Dieses Script verändert NICHT automatisch die Track/Item-Selektion.
--     Es geht davon aus, dass deine aktuelle Selektion bereits so vorbereitet ist,
--     dass ein Export pro Rolle sinnvoll ist (z.B. durch Mute/Solo, Folder-Struktur,
--     manuelle Pre-Selection).
--
--   Workflow-Empfehlung:
--     1. Mit DF95_Sampler_KitWizard ein C2-Kit bauen.
--     2. Projekt / Routing / Selektion so aufsetzen, dass ein Export aller relevanten
--        Drums/Slices sinnvoll ist.
--     3. Dieses Script ausführen.
--     4. Für jede gefundene Rolle wird der PackWizard mit passenden Tags gestartet.
--
--   Hinweis:
--     Die Rollen stammen aus den Slot-Metadaten (slot.role), die vom KitWizard
--     und Sampler_Core gesetzt wurden. Falls ältere Kits keine Rollen haben, wird
--     die Liste entsprechend leer oder generisch ausfallen.

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
    if role ~= nil and role ~= "" and role ~= "null" and role ~= "Any" then
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
    return "Keine spezifischen Rollen im KitMeta gefunden (evtl. alte Kits ohne Annotation?)."
  end
  table.sort(parts)
  return table.concat(parts, "\\n")
end

local function set_export_tags_for_role(role)
  -- Role auf die konkrete Slot-Rolle setzen,
  -- Source/FXFlavor bleiben auf SamplerKit/C2Kit
  r.SetExtState("DF95_EXPORT_TAGS", "Role", role, true)
  r.SetExtState("DF95_EXPORT_TAGS", "Source", "SamplerKit", true)
  r.SetExtState("DF95_EXPORT_TAGS", "FXFlavor", "C2Kit", true)
  -- Optional: Detail-Tag für Downstream-Tools
  r.SetExtState("DF95_EXPORT_TAGS", "KitRole", role, true)
end

local function run_packwizard()
  local dir = df95_root()
  if dir == "" then
    r.ShowMessageBox("DF95_PackWizard_From_KitMeta_PerRole: Konnte Script-Ordner nicht bestimmen.", "DF95 PackWizard from KitMeta (PerRole)", 0)
    return false
  end
  local ok, err = pcall(dofile, dir .. "DF95_Export_PackWizard.lua")
  if not ok then
    r.ShowMessageBox("Fehler beim Start von DF95_Export_PackWizard.lua:\\n" .. tostring(err), "DF95 PackWizard from KitMeta (PerRole)", 0)
    return false
  end
  return true
end

local function main()
  local json = load_last_kit_meta()
  if not json then
    r.ShowMessageBox(
      "Keine Kit-Metadaten gefunden.\\n" ..
      "Bitte zuerst mit DF95_Sampler_KitWizard ein C2-Kit bauen,\\n" ..
      "dann dieses Script erneut ausführen.",
      "DF95 PackWizard from KitMeta (PerRole)",
      0
    )
    return
  end

  local roles = parse_roles_from_json(json)
  local summary = build_roles_summary(roles)

  if not next(roles) then
    r.ShowMessageBox(summary, "DF95 PackWizard from KitMeta (PerRole)", 0)
    return
  end

  local msg = "Gefundene Rollen im letzten C2-Kit:\\n\\n" .. summary ..
              "\\n\\nFür JEDE dieser Rollen wird nacheinander ein PackWizard-Lauf gestartet." ..
              "\\nDie Export-Tags werden jeweils auf Role=<Rolle>, Source=SamplerKit, FXFlavor=C2Kit gesetzt." ..
              "\\n\\nHinweis: Die aktuelle Track/Item-Selektion wird NICHT automatisch angepasst." ..
              "\\n\\nFortfahren?"

  local ret = r.ShowMessageBox(msg, "DF95 PackWizard from KitMeta (PerRole)", 6) -- Yes/No
  if ret ~= 6 then
    return
  end

  -- Iteration über Rollen: Reihenfolge deterministisch machen
  local role_list = {}
  for role, _ in pairs(roles) do
    role_list[#role_list+1] = role
  end
  table.sort(role_list)

  for _, role in ipairs(role_list) do
    set_export_tags_for_role(role)
    local ok = run_packwizard()
    if not ok then
      -- Bei Fehler abbrechen
      break
    end
  end
end

main()
