-- IFLS_SliceHub_ImGui.lua
-- Phase 28+32: Slice Hub (Grid / Transient Slicing)

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_SliceHub')

local function load_domain()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. '/Scripts/IFLS/IFLS/Domain/IFLS_SliceDomain.lua')
  if ok and type(mod) == 'table' then return mod end
  reaper.ShowMessageBox('IFLS_SliceDomain.lua konnte nicht geladen werden.', 'IFLS SliceHub', 0)
  return nil
end

local domain = nil
local cfg = nil

local note_divisions = { "1/4", "1/8", "1/16", "1/32" }
local modes = { "GRID", "TRANSIENT", "TRANSIENT_ZC" }

local function load_cfg()
  domain = domain or load_domain()
  if domain and domain.read_cfg then
    cfg = domain.read_cfg()
  else
    cfg = {
      mode           = "GRID",
      note_div       = "1/16",
      bars_per_slice = 0,
      create_regions = false,
      snap_to_grid   = true,
      peakrate       = 1000,
      min_gap_ms     = 25,
      thr_rel        = 30,
      fadein_ms      = 2,
      fadeout_ms     = 5,
    }
  end
end

local function save_cfg()
  if domain and domain.write_cfg and cfg then
    domain.write_cfg(cfg)
  end
end

local function loop()
  if not cfg then load_cfg() end

  ig.SetNextWindowSize(ctx, 480, 360, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Slice Hub', true)
  if visible then
    ig.Text(ctx, 'IFLS Slice Hub – Grid & Transient')
    ig.Separator(ctx)

    if not cfg then
      ig.Text(ctx, 'Konfiguration konnte nicht geladen werden.')
    else
      -------------------------
      -- Mode Auswahl
      -------------------------
      ig.Text(ctx, 'Slice Mode')
      local current_mode_idx = 1
      for i, m in ipairs(modes) do
        if m == (cfg.mode or "GRID") then
          current_mode_idx = i
          break
        end
      end

      if ig.BeginCombo(ctx, "ModeCombo", modes[current_mode_idx]) then
        for i, m in ipairs(modes) do
          local selected = (i == current_mode_idx)
          if ig.Selectable(ctx, m, selected) then
            cfg.mode = m
            current_mode_idx = i
          end
        end
        ig.EndCombo(ctx)
      end

      if cfg.mode == "GRID" then
        ig.TextWrapped(ctx, "GRID: klassisches musikalisches Slicing nach Notenwert/Bars – ideal für "
          .. "sauber quantisierte Loops.")
      elseif cfg.mode == "TRANSIENT" then
        ig.TextWrapped(ctx, "TRANSIENT: Slicing nach Lautstärke-Transienten (Peaks), mit kurzen Fades "
          .. "gegen Klicks. Gut für Drum/Fieldrec-Loops.")
      else
        ig.TextWrapped(ctx, "TRANSIENT_ZC: wie TRANSIENT, aber mit lokaler Zero-Cross-Suche + stärkeren Fades – "
          .. "für besonders robuste, klickfreie Slices.")
      end

      ig.Separator(ctx)

      -------------------------
      -- GRID-Einstellungen
      -------------------------
      if cfg.mode == "GRID" then
        ig.Text(ctx, 'Grid-Einstellungen')

        ig.Text(ctx, 'Notenwert pro Slice')
        local current_idx = 1
        for i, v in ipairs(note_divisions) do
          if v == (cfg.note_div or "1/16") then
            current_idx = i
            break
          end
        end

        if ig.BeginCombo(ctx, "NoteDivCombo", note_divisions[current_idx]) then
          for i, v in ipairs(note_divisions) do
            local selected = (i == current_idx)
            if ig.Selectable(ctx, v, selected) then
              cfg.note_div = v
              current_idx = i
            end
          end
          ig.EndCombo(ctx)
        end

        local changed
        local bars = cfg.bars_per_slice or 0
        changed, bars = ig.SliderInt(ctx, "Bars pro Slice (0 = ignorieren)", bars, 0, 16)
        if changed then cfg.bars_per_slice = bars end

        changed, cfg.create_regions = ig.Checkbox(ctx, "Regions für Slices erzeugen", cfg.create_regions)

      else
        -------------------------
        -- TRANSIENT-Einstellungen
        -------------------------
        ig.Text(ctx, 'Transienten-Einstellungen')

        local changed
        local peakrate = cfg.peakrate or 1000
        changed, peakrate = ig.SliderInt(ctx, "Analyse-Auflösung (Peaks/s)", peakrate, 200, 4000)
        if changed then cfg.peakrate = peakrate end

        local min_gap = cfg.min_gap_ms or 25
        changed, min_gap = ig.SliderInt(ctx, "Minimalabstand Transienten (ms)", min_gap, 5, 200)
        if changed then cfg.min_gap_ms = min_gap end

        local thr_rel = cfg.thr_rel or 30
        changed, thr_rel = ig.SliderInt(ctx, "Threshold Rel. zum MaxPeak (dB)", thr_rel, 6, 60)
        if changed then cfg.thr_rel = thr_rel end

        ig.Separator(ctx)
        ig.Text(ctx, "Fade-Einstellungen (De-Click)")

        local fi = cfg.fadein_ms or 2
        local fo = cfg.fadeout_ms or 5
        changed, fi = ig.SliderInt(ctx, "Fade-In (ms)", fi, 0, 20)
        if changed then cfg.fadein_ms = fi end
        changed, fo = ig.SliderInt(ctx, "Fade-Out (ms)", fo, 0, 50)
        if changed then cfg.fadeout_ms = fo end
      end

      ig.Separator(ctx)
      if ig.Button(ctx, "Slice selected items") then
        save_cfg()
        domain = domain or load_domain()
        if domain and domain.slice_selected_items then
          domain.slice_selected_items()
        else
          reaper.ShowMessageBox("SliceDomain nicht verfügbar.", "IFLS SliceHub", 0)
        end
      end

      ig.Spacing(ctx)
      ig.TextWrapped(ctx, "Workflow:\n"
        .. "1) Audio-Item(s) wählen (z.B. Drumloop, Fieldrecording).\n"
        .. "2) Slice-Mode auswählen: GRID oder TRANSIENT.\n"
        .. "3) Parameter einstellen (Notenwert/Bars oder Transienten-Threshold/Fades).\n"
        .. "4) 'Slice selected items' klicken.")
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
