-- @description Sampler: Annotate Drum Roles From RS5k Note Mapping
-- @version 1.0
-- @author DF95
-- @about
--   Analysiert auf der ausgewählten Spur alle RS5k-Instanzen,
--   liest deren Note-Range (Start/End) aus und annotiert sie
--   mit Drum-Rollen wie [KICK], [SNARE], [HAT], [TOM], [PERC].
--
--   Der Zweck:
--     - Meta-Information für DF95-/MetaCore-/Pipeline-Scripte
--     - Einfachere visuelle Orientierung im FX-Chain-Fenster
--   Diese Version erstellt KEINE Audio-Routings. Stattdessen
--   werden nur FX-Namen entsprechend erweitert.

local r = reaper

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sampler – Annotate Drum Roles", 0)
end

local function get_note_range(track, fx_idx)
  local num_params = r.TrackFX_GetNumParams(track, fx_idx)
  local start_note, end_note
  for p = 0, num_params-1 do
    local _, pname = r.TrackFX_GetParamName(track, fx_idx, p, "")
    local lname = (pname or ""):lower()
    if lname:find("note range start") or lname:find("note start") then
      local val = r.TrackFX_GetParamNormalized(track, fx_idx, p)
      start_note = math.floor(val * 127 + 0.5)
    elseif lname:find("note range end") or lname:find("note end") then
      local val = r.TrackFX_GetParamNormalized(track, fx_idx, p)
      end_note = math.floor(val * 127 + 0.5)
    end
  end
  return start_note, end_note
end

local function classify_note(note)
  if not note then return "PERC" end
  -- Grobe General-MIDI-orientierte Heuristik
  if note == 35 or note == 36 then
    return "KICK"
  elseif note == 38 or note == 40 then
    return "SNARE"
  elseif note == 37 or note == 39 then
    return "RIM"
  elseif note >= 42 and note <= 46 then
    return "HAT"
  elseif note == 41 or note == 43 or note == 45 or note == 47 or note == 48 then
    return "TOM"
  else
    return "PERC"
  end
end

local function annotate()
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    msg("Bitte eine Spur mit RS5k-Instanzen selektieren.")
    return
  end

  local fx_count = r.TrackFX_GetCount(tr)
  if fx_count == 0 then
    msg("Auf dieser Spur sind keine FX vorhanden.")
    return
  end

  r.Undo_BeginBlock()

  local changed = 0

  for fx_idx = 0, fx_count-1 do
    local retval, fx_name = r.TrackFX_GetFXName(tr, fx_idx, "")
    if retval and fx_name:lower():find("reasamplomatic5000") then
      local s_note, e_note = get_note_range(tr, fx_idx)
      local note = s_note or e_note
      local role = classify_note(note)
      local label = string.format("[%s]", role)
      local new_name

      -- aktuelle "renamed_name" holen (falls gesetzt)
      local ok, renamed = r.TrackFX_GetNamedConfigParm(tr, fx_idx, "renamed_name")
      if ok and renamed ~= "" then
        -- Doppelte Labels vermeiden
        if not renamed:find("%[KICK%]") and not renamed:find("%[SNARE%]") and not renamed:find("%[HAT%]") and not renamed:find("%[TOM%]") and not renamed:find("%[PERC%]") and not renamed:find("%[RIM%]") then
          new_name = label .. " " .. renamed
        else
          new_name = renamed
        end
      else
        new_name = label .. " " .. (fx_name or "RS5k")
      end

      r.TrackFX_SetNamedConfigParm(tr, fx_idx, "renamed_name", new_name)
      changed = changed + 1
    end
  end

  r.Undo_EndBlock(string.format("DF95 Sampler: Drum-Rollen annotiert (%d Instanzen)", changed), -1)
end

annotate()
