
-- @description Coloring – Load with LUFS Audition (Artist duration + GainMatch)
-- @version 1.0
-- @about Lädt .rfxchain, führt kurze, artist-abhängige A/B-Audition durch und versucht LUFS-GainMatch (SWS/JSFX), sonst RMS-Fallback.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

-- utils
local function read_json(p)
  local f=io.open(p,"rb"); if not f then return nil end
  local d=f:read("*all"); f:close()
  if reaper.JSON_Decode then return reaper.JSON_Decode(d) end
end
local function showmenu(str)
  local _,_,x,y = r.GetMousePosition()
  gfx.init("DF95_Audition_LUFS",1,1,0,x,y)
  local sel=gfx.showmenu(str); gfx.quit(); return sel
end

-- list candidates from Coloring roots (incl. Artists)
local function list_all_chains()
  local out = {}
  local roots = {
    res..sep.."FXChains"..sep.."DF95"..sep.."Coloring",
    res..sep.."FXChains"..sep.."DF95"..sep.."Coloring"..sep.."Artists"
  }
  local function scan_dir(dir, prefix)
    local i, sub = 0, reaper.EnumerateSubdirectories(dir, 0)
    while sub do
      local d = dir..sep..sub
      local j, f = 0, reaper.EnumerateFiles(d, 0)
      while f do
        if f:lower():match("%.rfxchain$") then
          out[#out+1] = {label=(prefix and (prefix.."/") or "")..sub.."/"..f, path=d..sep..f}
        end
        j=j+1; f = reaper.EnumerateFiles(d, j)
      end
      i=i+1; sub = reaper.EnumerateSubdirectories(dir, i)
    end
    -- flat files
    local j, f = 0, reaper.EnumerateFiles(dir, 0)
    while f do
      if f:lower():match("%.rfxchain$") then
        out[#out+1] = {label=(prefix and (prefix.."/") or "")..f, path=dir..sep..f}
      end
      j=j+1; f = reaper.EnumerateFiles(dir, j)
    end
  end
  scan_dir(roots[1])
  scan_dir(roots[2], "Artists")
  table.sort(out, function(a,b) return a.label<b.label end)
  return out
end

local list = list_all_chains()
if #list==0 then r.ShowMessageBox("Keine Coloring-Chains gefunden.","DF95",0) return end
local labels={}; for _,e in ipairs(list) do labels[#labels+1]=e.label end
local menu = table.concat(labels,"|")
local choice = showmenu(menu); if choice<=0 then return end
local entry = list[choice]

local tr = r.GetSelectedTrack(0,0)
if not tr then r.ShowMessageBox("Bitte einen Coloring-Bus wählen.","DF95",0) return end

-- derive artist for duration
local audmap = read_json(res..sep.."Data"..sep.."DF95"..sep.."Audition_Durations_v1.json") or {}
local artist = entry.label:match("Artists/([^/]+)/") or ""
local dur = audmap[artist] or audmap[(artist:gsub("%s",""))] or audmap._default or 0.65

-- helper: toggle all FX enabled/disabled
local function set_all_fx(track, state)
  local n = r.TrackFX_GetCount(track)
  for i=0,n-1 do r.TrackFX_SetEnabled(track, i, state) end
end

-- try LUFS AutoLearn script if available
local function try_lufs_gainmatch()
  local fn = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_SmartLUFS_AutoLearn_v3.lua"
  local f = io.open(fn, "rb")
  if f then f:close(); dofile(fn); return true end
  return false
end

-- fallback: rough RMS-ish trim using Track_GetPeakInfo snapshots before/after
local function rms_fallback_trim(track, ms)
  local function snap()
    local sum = 0.0; local cnt = 0
    local t0 = r.time_precise()
    while (r.time_precise()-t0) < (ms/1000.0) do
      local sL = r.Track_GetPeakInfo(track, 0) or 0.0
      local sR = r.Track_GetPeakInfo(track, 1) or sL
      local v = 0.5*(sL*sL + sR*sR)
      sum = sum + v; cnt=cnt+1
    end
    local mean = (cnt>0) and (sum/cnt) or 1e-6
    local rms = math.sqrt(mean)
    if rms <= 1e-9 then rms = 1e-9 end
    return 20*math.log(rms,10) -- dBFS approx
  end
  local pre = snap()
  set_all_fx(track, true)
  local post = snap()
  set_all_fx(track, true)
  local delta = post - pre
  if math.abs(delta) > 0.2 then
    -- adjust track trim (vol)
    local vol = r.GetMediaTrackInfo_Value(track, "D_VOL")
    local target = vol * (10^((-delta)/20))
    r.SetMediaTrackInfo_Value(track, "D_VOL", target)
    r.ShowConsoleMsg(string.format("[DF95] RMS-Fallback GainMatch: %.2f dB kompensiert\n", -delta))
  end
end

r.Undo_BeginBlock()
-- load chain
r.TrackFX_AddByName(tr, entry.path, false, 1)

-- run gainmatch
local ok = try_lufs_gainmatch()
if not ok then
  -- temporarily bypass to measure pre
  set_all_fx(tr, false); rms_fallback_trim(tr, math.max(120, dur*1000))
end

-- audition sequence using defer (no blocking sleep)
local state = {phase=0, t0=r.time_precise()}
local function step()
  local now = r.time_precise()
  local elapsed = now - state.t0
  if state.phase == 0 then
    -- bypass
    set_all_fx(tr, false)
    state.phase = 1; state.t0 = now
    r.defer(step); return
  elseif state.phase == 1 then
    if elapsed >= dur then
      -- enable
      set_all_fx(tr, true)
      state.phase = 2; state.t0 = now
    end
    r.defer(step); return
  elseif state.phase == 2 then
    if elapsed >= dur then
      -- bypass again (second check)
      set_all_fx(tr, false)
      state.phase = 3; state.t0 = now
    end
    r.defer(step); return
  elseif state.phase == 3 then
    if elapsed >= (dur*0.5) then
      -- final: enable
      set_all_fx(tr, true)
      r.Undo_EndBlock("[DF95] Load Coloring with LUFS Audition", -1)
      r.ShowConsoleMsg(string.format("[DF95] Coloring loaded with LUFS audition (artist=%s, dur=%.2fs): %s\n", artist ~= "" and artist or "n/a", dur, entry.label))
      return
    end
    r.defer(step); return
  end
end
step()
