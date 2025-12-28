-- DF95 Runtime Utils
local M = {}
local r = reaper

function M.find_fx_indices(tr, predicates)
  local hits = {}
  local cnt = r.TrackFX_GetCount(tr)
  for i=0, cnt-1 do
    local rv, name = r.TrackFX_GetFXName(tr, i, "")
    local lname = (name or ""):lower()
    for _,pred in ipairs(predicates) do
      if lname:find(pred) then table.insert(hits, i) break end
    end
  end
  return hits
end

function M.insert_js_volume(tr, pos)
  -- Try to add JS: Volume adjustment (stock)
  -- Fallback to ReaEQ as gain stage if JS not found (set output gain = 0 dB, we adjust via parameter later if needed)
  local fxname = "JS: Volume adjustment"
  local fx = r.TrackFX_AddByName(tr, fxname, false, -1000) -- instantiate new
  if fx >= 0 then
    if pos and pos >=0 then r.TrackFX_CopyToTrack(tr, fx, tr, pos, true) end
    return pos or fx
  else
    -- Fallback: ReaEQ
    local feq = r.TrackFX_AddByName(tr, "VST: ReaEQ (Cockos)", false, -1000)
    if feq >= 0 then
      if pos and pos >=0 then r.TrackFX_CopyToTrack(tr, feq, tr, pos, true) end
      return pos or feq
    end
  end
  return -1
end

return M