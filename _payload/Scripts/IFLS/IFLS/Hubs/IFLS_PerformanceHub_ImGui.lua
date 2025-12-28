-- IFLS_PerformanceHub_ImGui.lua
-- Phase 25: Performance Macros Hub (SceneEvolution)
-- Steuerung von SceneEvolutionDomain-Makros:
--   - Variation Intensity
--   - Melody Motion
--   - Groove Loose/Tight
--   - Chaos / Energy

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_PerformanceHub')

local function load_sceneevo()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. '/Scripts/IFLS/IFLS/Domain/IFLS_SceneEvolutionDomain.lua')
  if ok and type(mod) == 'table' then return mod end
  r.ShowMessageBox('IFLS_SceneEvolutionDomain.lua konnte nicht geladen werden.', 'IFLS PerformanceHub', 0)
  return nil
end

local evo = nil
local cfg = nil

local function load_cfg()
  if not evo then evo = load_sceneevo() end
  if evo and evo.read_cfg then
    cfg = evo.read_cfg()
  end
end

local function save_and_apply()
  if evo and evo.write_cfg and evo.apply_to_domains and cfg then
    evo.write_cfg(cfg)
    evo.apply_to_domains(cfg)
  end
end

local function loop()
  if not cfg then load_cfg() end

  ig.SetNextWindowSize(ctx, 420, 260, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Performance Macros', true)
  if visible then
    ig.Text(ctx, 'IFLS Performance – Scene Evolution Macros')
    ig.Separator(ctx)

    if cfg then
      local changed
      changed, cfg.enabled = ig.Checkbox(ctx, 'SceneEvolution aktiviert', cfg.enabled)

      ig.Spacing(ctx)
      ig.Text(ctx, 'Makros (0 = wenig, 1 = viel)')
      cfg.macro_variation = select(2, ig.SliderDouble(ctx, 'Variation Intensity', cfg.macro_variation or 0.5, 0.0, 1.0, '%.2f'))
      cfg.macro_melody    = select(2, ig.SliderDouble(ctx, 'Melody Motion',      cfg.macro_melody or 0.5,    0.0, 1.0, '%.2f'))
      cfg.macro_groove    = select(2, ig.SliderDouble(ctx, 'Groove Loose/Tight', cfg.macro_groove or 0.5,    0.0, 1.0, '%.2f'))
      cfg.macro_chaos     = select(2, ig.SliderDouble(ctx, 'Chaos / Energy',     cfg.macro_chaos or 0.0,     0.0, 1.0, '%.2f'))

      ig.Separator(ctx)
      if ig.Button(ctx, 'Apply Macros to Domains') then
        save_and_apply()
      end
      ig.SameLine(ctx)
      if ig.Button(ctx, 'Reload from ExtState') then
        load_cfg()
      end

      ig.Spacing(ctx)
      ig.TextWrapped(ctx, 'Tipp: Nutze diese Makros zusammen mit dem Scene-Sequencer.
'
        .. 'Scenes können die IFLS_SCENEEVO-ExtState mitspeichern; beim Szenenwechsel '
        .. 'werden Variation/Groove/Melody passend zur Szene mitbewegt.')
    else
      ig.Text(ctx, 'Keine SceneEvolution-Konfiguration geladen.')
    end

    ig.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
