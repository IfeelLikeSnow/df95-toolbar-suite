-- @description DF95_V86_ReampSuite_BatchReampEngine
-- @version 1.0
-- @author DF95
local r = reaper
local EXT_NS = "DF95_BATCH"
local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\","/")
end
local function is_reamp_candidate_name(name)
  if not name or name == "" then return false end
  local u = name:upper()
  if u:match("REAMP") then return true end
  if u:match("RE%-AMP") then return true end
  if u:match(" DI ") then return true end
  if u:match("_DI") then return true end
  if u:match("DI_") then return true end
  if u:match("PEDAL") then return true end
  return false
end
local function get_track_name(tr)
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if name == "" then
    local num = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    name = string.format("Track %d", num)
  end
  return name
end
local function build_job_queue()
  local jobs = {}
  local cnt = r.CountTracks(0)
  for i = 0, cnt - 1 do
    local tr = r.GetTrack(0, i)
    local name = get_track_name(tr)
    if is_reamp_candidate_name(name) then
      jobs[#jobs+1] = i+1
    end
  end
  return jobs
end
local function load_jobs()
  local queue   = r.GetExtState(EXT_NS, "JOB_QUEUE")
  local idx_str = r.GetExtState(EXT_NS, "JOB_INDEX")
  if queue == "" then return nil, nil end
  local jobs = {}
  for part in string.gmatch(queue, "([^,]+)") do
    local n = tonumber(part)
    if n then jobs[#jobs+1] = n end
  end
  local idx = tonumber(idx_str) or 1
  return jobs, idx
end
local function save_jobs(jobs, idx)
  local parts = {}
  for _, n in ipairs(jobs) do parts[#parts+1] = tostring(n) end
  r.SetExtState(EXT_NS, "JOB_QUEUE", table.concat(parts, ","), true)
  r.SetExtState(EXT_NS, "JOB_INDEX", tostring(idx or 1), true)
end
local function run_autosession_for_trackindex(track_idx)
  local tr = r.GetTrack(0, track_idx-1)
  if not tr then
    r.ShowMessageBox("Trackindex " .. tostring(track_idx) .. " ist ungültig.", "DF95 BatchReamp", 0)
    return
  end
  r.Main_OnCommand(40297, 0)
  r.SetTrackSelected(tr, true)
  local autos_path = df95_root() .. "ReampSuite/DF95_V80_ReampSuite_AutoSession.lua"
  local ok, err = pcall(dofile, autos_path)
  if not ok then
    r.ShowMessageBox("Fehler in AutoSession:
" .. tostring(err or "?"), "DF95 BatchReamp", 0)
  end
end
local function main()
  local jobs, idx = load_jobs()
  if not jobs or #jobs == 0 then
    jobs = build_job_queue()
    if #jobs == 0 then
      r.ShowMessageBox("Keine Reamp-Kandidaten gefunden (REAMP/DI/PEDAL).", "DF95 BatchReamp", 0)
      return
    end
    idx = 1
    save_jobs(jobs, idx)
    local lines = {}
    lines[#lines+1] = string.format("Batch-Queue erstellt (%d Jobs):", #jobs)
    for i, track_idx in ipairs(jobs) do
      local tr = r.GetTrack(0, track_idx-1)
      local name = tr and get_track_name(tr) or "(unbekannt)"
      lines[#lines+1] = string.format("%2d) #%d – %s", i, track_idx, name)
    end
    lines[#lines+1] = ""
    lines[#lines+1] = "Rufe diese Action erneut auf, um Job 1 mit AutoSession zu starten."
    r.ShowMessageBox(table.concat(lines, "\n"), "DF95 BatchReamp – Queue erstellt", 0)
    return
  end
  if idx > #jobs then
    r.ShowMessageBox("Alle Batch-Jobs verarbeitet. Neue Queue per erneutem Start.", "DF95 BatchReamp", 0)
    return
  end
  local track_idx = jobs[idx]
  local tr = r.GetTrack(0, track_idx-1)
  local name = tr and get_track_name(tr) or "(unbekannt)"
  r.ShowMessageBox(string.format("Starte Batch-Job %d von %d:\n#%d – %s", idx, #jobs, track_idx, name), "DF95 BatchReamp", 0)
  run_autosession_for_trackindex(track_idx)
  save_jobs(jobs, idx+1)
end
main()
