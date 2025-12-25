-- @description LiveMode – Bypass high-latency suspects
-- @version 1.1
-- @author DF95
-- Schaltet verdächtige High-Latency-FX (Linear Phase, Spektral, Master-Limiter etc.) auf ausgewählten Tracks stumm/aktiv.

local r = reaper

local suspects = {
  "paulxstretch",
  "spectral",
  "linear phase",
  "linear-phase",
  "lin phase",
  "loudness",
  "limiter",
  "maximizer",
  "ozone",
  "fabfilter pro-l",
  "fir",
}

local function is_suspect(name)
  local ln = (name or ""):lower()
  for _, s in ipairs(suspects) do
    if ln:find(s, 1, true) then return true end
  end
  return false
end

local function toggle_on_track(tr)
  local changed = 0
  for i = 0, r.TrackFX_GetCount(tr)-1 do
    local _, nm = r.TrackFX_GetFXName(tr, i, "")
    if is_suspect(nm) then
      local enabled = r.TrackFX_GetEnabled(tr, i)
      r.TrackFX_SetEnabled(tr, i, not enabled)
      changed = changed + 1
    end
  end
  return changed
end

local function main()
  local sel = r.CountSelectedTracks(0)
  if sel == 0 then
    r.ShowMessageBox("Keine Tracks ausgewählt.", "DF95 LiveMode", 0)
    return
  end

  r.Undo_BeginBlock()
  local total = 0
  for i = 0, sel-1 do
    local tr = r.GetSelectedTrack(0, i)
    total = total + toggle_on_track(tr)
  end
  r.Undo_EndBlock("DF95: LiveMode – toggle high-latency FX", -1)

  r.ShowConsoleMsg(string.format("[DF95] LiveMode: %d FX umgeschaltet.\n", total))
end

main()
