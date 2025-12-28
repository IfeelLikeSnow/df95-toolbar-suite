-- @description LUFS Auto-Gain (SWS CSV/Notes) with per-Chain target & Auto Report
-- @version 2.0
-- @author IfeelLikeSnow
-- @about Reads SWS Loudness from CSV (preferred) or Notes; uses META lufs_target (track extstate / chain meta); writes before/after report.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local data = res..sep.."Data"..sep.."DF95"
local cfg_fn = data..sep.."DF95_Humanize_Config.json"
local report_dir = data..sep.."Reports"

local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function writeall(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s); f:close(); return true end
local function json(s) if r.JSON_Decode then return r.JSON_Decode(s) end end

local cfg = json(readall(cfg_fn) or "{}") or {}
local MAX_LUFS = tonumber(cfg.clamp_lufs or 1.3)

local function clamp_db(db) if db >  MAX_LUFS then return  MAX_LUFS end if db < -MAX_LUFS then return -MAX_LUFS end return db end
local function lin_from_db(db) return 10^(db/20.0) end
local function safe_mkdir(p) r.RecursiveCreateDirectory(p, 0) end

local function default_target() return -14.0 end

-- META target priority:
-- 1) Track extstate "DF95_META_lufs_target"
-- 2) Track notes "lufs_target=…"
-- 3) Chain extstate "DF95_CHAIN_META_lufs_target"
-- 4) Fallback: default_target()
local function parse_number(s) local v = s and tostring(s):match("([%-+]?%d+%.?%d*)"); return v and tonumber(v) or nil end
local function get_track_meta_target(tr)
  local ok, v = r.GetSetMediaTrackInfo_String(tr, "P_EXT:DF95_META_lufs_target", "", false); if ok and v ~= "" then return parse_number(v) end
  local ok2, notes = r.GetSetMediaTrackInfo_String(tr, "P_EXT:NOTES", "", false)
  if ok2 and notes and notes ~= "" then
    local m = notes:match("[Ll][Uu][Ff][Ss]%_?[Tt][Aa][Rr][Gg][Ee][Tt]%s*=%s*([%-+]?%d+%.?%d*)")
    if m then return tonumber(m) end
  end
  local ok3, v3 = r.GetSetMediaTrackInfo_String(tr, "P_EXT:DF95_CHAIN_META_lufs_target", "", false); if ok3 and v3 ~= "" then return parse_number(v3) end
  return nil
end

-- CSV Parser: look in project dir for recent SWS loudness CSVs; map "Track Name" or item identifiers to LUFS-I
local function get_project_dir()
  local _, projfn = r.EnumProjects(-1, "", 0)
  if projfn and projfn ~= "" then
    return projfn:match("^(.*"..sep..")") or (r.GetProjectPath("")..sep)
  end
  return r.GetProjectPath("")..sep
end

local function list_csv_candidates(dir)
  local t = {}
  local i = 0
  while true do
    local f = r.EnumerateFiles(dir, i)
    if not f then break end
    if f:lower():match("%.csv$") and f:lower():match("loudness") then
      t[#t+1] = dir .. f
    end
    i = i + 1
  end
  table.sort(t)
  return t
end

local function parse_csv(fp)
  local s = readall(fp); if not s then return {} end
  local rows = {}
  for line in s:gmatch("[^\r\n]+") do
    local cols = {}
    for cell in line:gmatch('"(.-)"%s*[,;]?') do cols[#cols+1] = cell end
    if #cols == 0 then
      -- try simple split
      for cell in line:gmatch("([^,;]+)") do cols[#cols+1]=cell end
    end
    rows[#rows+1] = cols
  end
  -- find headers
  local map = {}
  if #rows > 1 then
    local hdr = rows[1]
    local idx_name, idx_I = nil, nil
    for i,c in ipairs(hdr) do
      local lc = c:lower()
      if lc:find("track") or lc:find("item") or lc:find("name") then idx_name = i end
      if lc:find("lufs") and (lc:find("i") or lc:find("integrated")) then idx_I = i end
    end
    if idx_name and idx_I then
      for r_i = 2, #rows do
        local row = rows[r_i]
        local name = row[idx_name]
        local lufs = tonumber(row[idx_I]) or parse_number(row[idx_I])
        if name and lufs then
          map[name] = lufs
        end
      end
    end
  end
  return map
end

local function best_csv_map()
  local dir = get_project_dir()
  local list = list_csv_candidates(dir)
  for i = #list, 1, -1 do
    local m = parse_csv(list[i])
    if next(m) then return m, list[i] end
  end
  return {}, nil
end

local function parse_lufs_from_notes_text(s)
  if not s or s=="" then return nil end
  local v = s:match("LUFS%p?%s*I%p?%s*:%s*([%-+]?%d+%.?%d*)") or s:match("I%s*=%s*([%-+]?%d+%.?%d*)")
  return v and tonumber(v) or nil
end

local function get_track_lufs_from_notes(tr)
  local ok, notes = r.GetSetMediaTrackInfo_String(tr, "P_EXT:NOTES", "", false)
  return parse_lufs_from_notes_text(notes)
end

local function get_item_lufs_from_notes(it)
  local ok, notes = r.GetSetMediaItemInfo_String(it, "P_NOTES", "", false)
  if ok then
    local v = parse_lufs_from_notes_text(notes)
    if v then return v end
  end
  local take = r.GetActiveTake(it)
  if take then
    local _, tkname = r.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    local v = parse_lufs_from_notes_text(tkname)
    if v then return v end
  end
  return nil
end

local function gain_trim_track(tr, delta_db)
  local vol = r.GetMediaTrackInfo_Value(tr, "D_VOL") or 1.0
  local new_vol = vol * lin_from_db(delta_db)
  r.SetMediaTrackInfo_Value(tr, "D_VOL", new_vol)
end

local function gain_trim_item(it, delta_db)
  local take = r.GetActiveTake(it); if not take then return end
  local vol = r.GetMediaItemTakeInfo_Value(take, "D_VOL") or 1.0
  local new_vol = vol * lin_from_db(delta_db)
  r.SetMediaItemTakeInfo_Value(take, "D_VOL", new_vol)
end

local function track_name(tr) local _, n = r.GetTrackName(tr, "") return n end
local function item_name(it)
  local take = r.GetActiveTake(it)
  if take then local _, tn = r.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false); return tn end
  return "(item)"
end

local function process()
  safe_mkdir(report_dir)
  local report = {}
  local proj = 0
  local ntr = r.CountSelectedTracks(proj)
  local nitem = r.CountSelectedMediaItems(proj)

  if ntr==0 and nitem==0 then
    r.ShowMessageBox("Bitte Tracks oder Items auswählen.", "DF95 LUFS Auto-Gain CSV", 0)
    return
  end

  local csv_map, csv_file = best_csv_map()
  local csv_note = csv_file and ("CSV="..csv_file) or "CSV=none"

  local adjusted = 0

  if ntr>0 then
    for i=0,ntr-1 do
      local tr = r.GetSelectedTrack(proj,i)
      local name = track_name(tr)
      -- target resolve
      local tgt = get_track_meta_target(tr) or default_target()
      -- source LUFS
      local I = csv_map[name] or get_track_lufs_from_notes(tr)
      if I then
        local before = r.GetMediaTrackInfo_Value(tr, "D_VOL")
        local delta = clamp_db(tgt - I)
        gain_trim_track(tr, delta)
        local after = r.GetMediaTrackInfo_Value(tr, "D_VOL")
        adjusted = adjusted + 1
        report[#report+1] = string.format("Track: %-24s I=%.2f → target=%.2f | Δ=%.2f dB | vol %.3f→%.3f", name, I, tgt, delta, before, after)
      end
    end
  end

  if nitem>0 then
    for i=0,nitem-1 do
      local it = r.GetSelectedMediaItem(proj,i)
      local name = item_name(it)
      local tr = r.GetMediaItem_Track(it)
      local tgt = get_track_meta_target(tr) or default_target()
      local I = csv_map[name] or get_item_lufs_from_notes(it)
      if I then
        local take = r.GetActiveTake(it)
        if take then
          local before = r.GetMediaItemTakeInfo_Value(take, "D_VOL")
          local delta = clamp_db(tgt - I)
          gain_trim_item(it, delta)
          local after = r.GetMediaItemTakeInfo_Value(take, "D_VOL")
          adjusted = adjusted + 1
          report[#report+1] = string.format("Item : %-24s I=%.2f → target=%.2f | Δ=%.2f dB | take %.3f→%.3f", name, I, tgt, delta, before, after)
        end
      end
    end
  end

  local header = string.format("[DF95] Auto-Gain CSV (%s) adjusted=%d, clamp=±%.1f dB\n", csv_note, adjusted, MAX_LUFS)
  r.ShowConsoleMsg(header .. table.concat(report, "\n") .. "\n")

  -- write report file
  local time_stamp = os.date("!%Y%m%d_%H%M%S")
  local rep_fn = report_dir..sep.."AutoGain_"..time_stamp..".txt"
  writeall(rep_fn, header .. table.concat(report, "\n") .. "\n")

  return adjusted
end

r.Undo_BeginBlock()
local n = process()
r.Undo_EndBlock(string.format("DF95 LUFS Auto-Gain CSV (adjusted=%d)", n or 0), -1)
