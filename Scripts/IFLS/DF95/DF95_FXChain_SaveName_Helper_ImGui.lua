-- @description Save FX Chain Name Helper (with Category Prefix)
-- @version 1.0
-- @author DF95
-- @about
--   Dieses Script hilft dabei, beim Speichern neuer FX-Chains
--   konsistente Dateinamen mit Kategorie-Präfixen zu verwenden.
--
--   Workflow-Vorschlag:
--   1. Track mit gewünschter FX-Kette auswählen.
--   2. Dieses Script ausführen.
--   3. Kategorie und Basisnamen wählen.
--   4. Den vorgeschlagenen Dateinamen in Reapers "Save FX Chain" Dialog
--      verwenden (manuell kopieren).
--
--   Hinweis:
--   Reaper bietet derzeit keine direkte API, um FX-Chains aus einem Script
--   ohne Nutzerinteraktion zu speichern. Dieses Script ist daher ein
--   Naming-Helper, kein Auto-Speicher.

local r = reaper

local ctx = r.ImGui_CreateContext("Save FX Chain Name Helper", 0)
local base_name = ""
local categories = {
  "MicFX (MIC_...)",
  "Glitch / IDM (FX_GLITCH_...)",
  "Perc / DrumGhost (FX_PERC_...)",
  "Filter / Motion (FX_FILTER_...)",
  "Coloring / Tone (COLOR_...)",
  "Master / Safety (MASTER_...)",
  "Other (kein Präfix)",
}
local current_cat = 1

local function get_prefix()
  if current_cat == 1 then return "MIC_"
  elseif current_cat == 2 then return "FX_GLITCH_"
  elseif current_cat == 3 then return "FX_PERC_"
  elseif current_cat == 4 then return "FX_FILTER_"
  elseif current_cat == 5 then return "COLOR_"
  elseif current_cat == 6 then return "MASTER_"
  else return "" end
end

local function sanitize_name(s)
  s = s:gsub("[^%w_%-%s]", "")
  s = s:gsub("%s+", "_")
  return s
end

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "Save FX Chain Name Helper", true)
  if visible then
    r.ImGui_TextWrapped(ctx, "Wähle eine Kategorie und gib einen Basisnamen für deine FX-Chain ein. Den vorgeschlagenen Dateinamen kannst du im \"Save FX Chain\" Dialog von Reaper verwenden.")
    r.ImGui_Separator(ctx)

    if r.ImGui_BeginCombo(ctx, "Kategorie", categories[current_cat]) then
      for i, label in ipairs(categories) do
        local selected = (i == current_cat)
        if r.ImGui_Selectable(ctx, label, selected) then
          current_cat = i
        end
        if selected then
          r.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      r.ImGui_EndCombo(ctx)
    end

    local changed
    changed, base_name = r.ImGui_InputText(ctx, "Basisname", base_name, 256)

    local prefix = get_prefix()
    local suggested = prefix .. sanitize_name(base_name or "")
    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "Vorgeschlagener Dateiname:")
    r.ImGui_TextWrapped(ctx, suggested ~= "" and suggested .. ".RfxChain" or "(Bitte Basisname eingeben)")

    r.ImGui_Separator(ctx)
    local sep = package.config:sub(1,1)
    local res = r.GetResourcePath()
    local fxdir = res .. sep .. "FXChains"
    r.ImGui_TextWrapped(ctx, "Zielordner für FX-Chains:")
    r.ImGui_Text(ctx, fxdir)

    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx, "Vorgehen:")
    r.ImGui_BulletText(ctx, "Im Track- oder FX-Fenster: FX-Kette speichern (Save FX Chain...).")
    r.ImGui_BulletText(ctx, "Den oben vorgeschlagenen Namen als Dateinamen verwenden.")
    r.ImGui_BulletText(ctx, "Die ImGui-Browser (MicFX / FXBus / Coloring / Master) sortieren die Chain dann automatisch in die passende Kategorie.")

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
