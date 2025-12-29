-- IFLS_AudioImportHub_ImGui.lua
-- Phase 27: Audio Import Hub (Zoom / Field Recorder)

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_AudioImportHub')

local function load_domain()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. '/Scripts/IFLS/IFLS/Domain/IFLS_AudioImportDomain.lua')
  if ok and type(mod) == 'table' then return mod end
  reaper.ShowMessageBox('IFLS_AudioImportDomain.lua konnte nicht geladen werden.', 'IFLS Audio Import', 0)
  return nil
end

local domain = nil
local last_analysis = nil
local last_error = nil

local function analyze()
  domain = domain or load_domain()
  if not domain or not domain.analyze_selected_item then
    last_analysis = nil
    last_error = 'Domain nicht verfügbar.'
    return
  end
  local res, err = domain.analyze_selected_item()
  if not res then
    last_analysis = nil
    last_error = err or 'Analyse fehlgeschlagen.'
  else
    last_analysis = res
    last_error = nil
  end
end

local function loop()
  domain = domain or load_domain()

  ig.SetNextWindowSize(ctx, 520, 260, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Audio Import Hub', true)
  if visible then
    ig.Text(ctx, 'IFLS Audio Import – Zoom / Field Recorder')
    ig.Separator(ctx)

    ig.TextWrapped(ctx, '1. Wähle ein Media-Item in REAPER aus (Zoom-Aufnahme oder Handy-Fieldrec).\n'
      .. '2. Klicke "Analyse" und dann den passenden Setup-Button.')

    ig.Separator(ctx)

    if ig.Button(ctx, 'Analyse selektiertes Item') then
      analyze()
    end

    ig.Separator(ctx)

    if last_error then
      ig.TextColored(ctx, 1, 0.3, 0.3, 1, 'Fehler: ' .. tostring(last_error))
    elseif last_analysis and last_analysis.info then
      local info = last_analysis.info
      ig.Text(ctx, 'Analyse-Ergebnis:')
      ig.BulletText(ctx, 'Datei: ' .. (info.file or '?'))
      ig.BulletText(ctx, string.format('Kanäle: %d (%s)', info.num_channels or -1, info.kind or '?'))
      ig.BulletText(ctx, string.format('Sample-Rate: %.0f Hz', info.sample_rate or 0))
      ig.BulletText(ctx, string.format('Länge: %.2f s', info.length or 0))
    else
      ig.Text(ctx, 'Noch keine Analyse durchgeführt.')
    end

    ig.Separator(ctx)
    ig.Text(ctx, 'Setups erzeugen:')

    if ig.Button(ctx, 'Zoom Polywave Setup (Mic + FX/Color/Master)') then
      domain = domain or load_domain()
      if domain and domain.build_zoom_setup_from_selection then
        local ok = domain.build_zoom_setup_from_selection()
        if not ok then
          last_error = 'Zoom-Setup konnte nicht erzeugt werden.'
        else
          last_error = nil
        end
      end
    end

    ig.SameLine(ctx)
    if ig.Button(ctx, 'Field Recorder Setup (Handy-App / Stereo)') then
      domain = domain or load_domain()
      if domain and domain.build_fieldrec_setup_from_selection then
        local ok = domain.build_fieldrec_setup_from_selection()
        if not ok then
          last_error = 'Fieldrec-Setup konnte nicht erzeugt werden.'
        else
          last_error = nil
        end
      end
    end

    ig.Separator(ctx)
    ig.TextWrapped(ctx, 'Hinweis: Polywave-Aufnahmen (z.B. Zoom H5/H6/H8/F-Serie) werden als Mehrkanal-Quelle behandelt. '
      .. 'Das Hub erzeugt pro Kanal eigene Mic-Tracks + gemeinsame FX/Color/Master-Busse.\n'
      .. 'Stereo/Mono-Aufnahmen (z.B. Handy-Recorder-App) erhalten ein vereinfachtes Fieldrec-Setup.')

    ig.End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
