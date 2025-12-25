-- @description DF95 Safety Routing Guard (Stufe 3)
-- @version 1.0
-- @author DF95
-- @about
--   Führt einfache Integritätsprüfungen für Sends und Busse durch.
--   Diese Version arbeitet nur lesend und schreibt Warnungen ins Log.

local r = reaper

local SafetyRoute = {}

local function dbg(msg)
  if _G.DF95_DEBUG_SAFETY then
    r.ShowConsoleMsg("[DF95 Routing Safety] " .. tostring(msg) .. "\n")
  end
end

local function collect_sends_for_track(tr)
  local sends = {}
  local send_cnt = r.GetTrackNumSends(tr, 0) -- 0 = normal sends
  for si = 0, send_cnt-1 do
    local dest = r.BR_GetMediaTrackSendInfo_Track(tr, 0, si, 1) -- 1 = dest track
    if dest then
      sends[#sends+1] = dest
    end
  end
  return sends
end

function SafetyRoute.scan_for_duplicate_sends_on_selected()
  local num_sel_tr = r.CountSelectedTracks(0)
  if num_sel_tr == 0 then
    dbg("Keine selektierten Tracks für Routing-Analyse.")
    return
  end

  for ti = 0, num_sel_tr-1 do
    local tr = r.GetSelectedTrack(0, ti)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    local sends = collect_sends_for_track(tr)
    local seen = {}
    local duplicates = 0

    for _, dst in ipairs(sends) do
      local key = tostring(dst)
      seen[key] = (seen[key] or 0) + 1
      if seen[key] > 1 then
        duplicates = duplicates + 1
      end
    end

    if duplicates > 0 then
      dbg(string.format("Track '%s' hat %d doppelte Sends – bitte Routing prüfen.", name or "unnamed", duplicates))
    end
  end
end

return SafetyRoute
