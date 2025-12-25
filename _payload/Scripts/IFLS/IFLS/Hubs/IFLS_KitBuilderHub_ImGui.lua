-- IFLS_KitBuilderHub_ImGui.lua
-- Phase 30: Kit Builder Hub – verbindet Slices/Items mit KitSchemaDomain (RS5k Export)

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_KitBuilderHub')

local function load_domain()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. '/Scripts/IFLS/IFLS/Domain/IFLS_KitSchemaDomain.lua')
  if ok and type(mod) == 'table' then return mod end
  r.ShowMessageBox('IFLS_KitSchemaDomain.lua konnte nicht geladen werden.', 'IFLS Kit Builder', 0)
  return nil
end

local domain = nil
local kit_name = "IFLS Kit RS5k"
local last_msg = ""

local function set_msg(m)
  last_msg = m or ""
end

local function loop()
  domain = domain or load_domain()

  ig.SetNextWindowSize(ctx, 480, 260, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Kit Builder Hub', true)
  if visible then
    ig.Text(ctx, 'IFLS Kit Builder Hub')
    ig.Separator(ctx)

    ig.TextWrapped(ctx, 'Dieser Hub baut Kits aus selektierten Items (z.B. Slices) '
      .. 'und exportiert sie als RS5k-Drumkit auf einer neuen Spur.')

    ig.Separator(ctx)
    ig.Text(ctx, 'Kit-Name (Trackname bei RS5k-Export)')
    local changed
    changed, kit_name = ig.InputText(ctx, "Kit Name", kit_name, 128)
    if changed then end

    ig.Separator(ctx)
    if ig.Button(ctx, 'Kit aus selektierten Items aufbauen') then
      domain = domain or load_domain()
      if domain and domain.build_kit_from_selected_items then
        domain.build_kit_from_selected_items()
        set_msg('Kit aus selektierten Items aufgebaut.')
      else
        set_msg('KitSchemaDomain nicht verfügbar.')
      end
    end

    ig.SameLine(ctx)
    if ig.Button(ctx, 'Kit nach RS5k exportieren') then
      domain = domain or load_domain()
      if domain and domain.export_to_rs5k then
        domain.export_to_rs5k(kit_name)
        set_msg('Kit nach RS5k exportiert.')
      else
        set_msg('KitSchemaDomain nicht verfügbar.')
      end
    end

    ig.Separator(ctx)
    ig.Text(ctx, 'Hinweis zu Slices:')
    ig.TextWrapped(ctx, 'In Kombination mit dem IFLS Slice Hub kannst du zunächst einen Audio-Loop '
      .. 'in Slices zerschneiden, dann im Arrange-Fenster die Slice-Items selektieren und hieraus '
      .. 'ein RS5k-Kit bauen.')

    ig.Separator(ctx)
    if last_msg ~= "" then
      ig.Text(ctx, 'Status:')
      ig.TextWrapped(ctx, last_msg)
    else
      ig.Text(ctx, 'Status: bereit.')
    end

    ig.End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
