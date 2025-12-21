-- IFLS_AudioPatternBridgeHub_ImGui.lua
-- Phase 31: Audio Pattern Bridge Hub – Slices → MIDI-Pattern

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_AudioPatternBridgeHub')

local function load_domain()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. '/Scripts/IFLS/IFLS/Domain/IFLS_AudioPatternBridgeDomain.lua')
  if ok and type(mod) == 'table' then return mod end
  r.ShowMessageBox('IFLS_AudioPatternBridgeDomain.lua konnte nicht geladen werden.', 'IFLS Audio Pattern Bridge', 0)
  return nil
end

local domain = nil
local cfg = nil
local step_divisions = { "1/8", "1/16", "1/32" }

local function load_cfg()
  domain = domain or load_domain()
  if domain and domain.read_cfg then
    cfg = domain.read_cfg()
  else
    cfg = {
      step_div     = "1/16",
      base_note    = 36,
      note_span    = 16,
      note_len_mul = 0.5,
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

  ig.SetNextWindowSize(ctx, 520, 260, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Audio Pattern Bridge Hub', true)
  if visible then
    ig.Text(ctx, 'IFLS Audio Pattern Bridge – Slices → MIDI')
    ig.Separator(ctx)

    ig.TextWrapped(ctx, 'Workflow: Wähle Slices oder Audio-Items, stelle das Pattern-Grid ein und '
      .. 'erzeuge daraus ein MIDI-Pattern (z.B. für RS5k-Kits oder Beat-Engines).')

    ig.Separator(ctx)
    ig.Text(ctx, 'Step-Gitter (Step-Division)')
    local current_idx = 2
    for i, v in ipairs(step_divisions) do
      if v == (cfg.step_div or "1/16") then
        current_idx = i
        break
      end
    end

    if ig.BeginCombo(ctx, "StepDivCombo", step_divisions[current_idx]) then
      for i, v in ipairs(step_divisions) do
        local selected = (i == current_idx)
        if ig.Selectable(ctx, v, selected) then
          cfg.step_div = v
          current_idx = i
        end
      end
      ig.EndCombo(ctx)
    end

    local changed
    ig.Separator(ctx)
    ig.Text(ctx, 'MIDI-Notenbereich')
    changed, cfg.base_note = ig.SliderInt(ctx, "Base Note (MIDI)", cfg.base_note or 36, 24, 84)
    changed, cfg.note_span = ig.SliderInt(ctx, "Note Span", cfg.note_span or 16, 1, 32)
    changed, cfg.note_len_mul = ig.SliderDouble(ctx, "Note-Length Faktor (0..1)", cfg.note_len_mul or 0.5, 0.1, 1.0)

    ig.Separator(ctx)
    if ig.Button(ctx, 'Create Pattern from selected Items') then
      save_cfg()
      domain = domain or load_domain()
      if domain and domain.create_pattern_from_selected_items then
        domain.create_pattern_from_selected_items()
      else
        r.ShowMessageBox("AudioPatternBridgeDomain nicht verfügbar.", "IFLS Audio Pattern Bridge", 0)
      end
    end

    ig.Spacing(ctx)
    ig.TextWrapped(ctx, 'Tipp: In Kombination mit Slice Hub und Kit Builder Hub:\n'
      .. '1) Audio-Loop slicen (Slice Hub)\n'
      .. '2) Slices selektieren\n'
      .. '3) Kit aus Slices bauen (Kit Builder Hub → RS5k)\n'
      .. '4) Audio Pattern Bridge Hub → MIDI-Pattern erzeugen → PatternDomain/Beat-Domain nutzen.')

    ig.End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
