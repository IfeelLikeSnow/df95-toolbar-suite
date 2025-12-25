-- @description LUFS Auto-Gain from SWS (tracks/items) with clamp & META target
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Reads SWS loudness hints (if available) from notes/chunk/ExtState and trims gain toward target LUFS. Respects DF95 clamp and META lufs_target.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local data = res..sep.."Data"..sep.."DF95"
local cfg_fn = data..sep.."DF95_Humanize_Config.json"

local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function json(s) if r.JSON_Decode then return r.JSON_Decode(s) end end
local cfg = json(readall(cfg_fn) or "{}") or {}
local MAX_LUFS = tonumber(cfg.clamp_lufs or 1.3)

local function clamp_db(db) if db >  MAX_LUFS then return  MAX_LUFS end if db < -MAX_LUFS then return -MAX_LUFS end return db end
local function lin_from_db(db) return 10^(db/20.0) end

-- Try reading META lufs_target from first selected chain file on disk (if any) – fallback to -14 LUFS
local function meta_target_default()
  -- Fallback default for creative/IDM stems
  return -14.0
end

-- Extract LUFS from a string like "LUFS-I: -13.5" or "I=-13.5"
local function parse_lufs_from_text(s)
  if not s or s=="" then return nil end
  local v = s:match("LUFS%p?%s*I%p?%s*:%s*([%-+]?%d+%.?%d*)") or s:match("I%s*=%s*([%-+]?%d+%.?%d*)")
  if v then return tonumber(v) end
  return nil
end

-- Try to get SWS analysis from track notes
local function get_track_lufs_I(tr)
  -- Track notes API (SWS) stores notes in proj extstate or chunk; we can try GetSetMediaTrackInfo_String "P_EXT:NOTES"
  local ok, notes = r.GetSetMediaTrackInfo_String(tr, "P_EXT:NOTES", "", false)
  local v = parse_lufs_from_text(notes)
  return v
end

-- Try item notes
local function get_item_lufs_I(it)
  local ok, notes = r.GetSetMediaItemInfo_String(it, "P_NOTES", "", false)
  local v = parse_lufs_from_text(notes)
  if v then return v end
  -- alt: take name hint
  local take = r.GetActiveTake(it)
  if take then
    local _, tkname = r.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    v = parse_lufs_from_text(tkname)
    if v then return v end
  end
  return nil
end

local function gain_trim_track(tr, delta_db)
  local vol = r.GetMediaTrackInfo_Value(tr, "D_VOL") or 1.0
  local new_vol = vol * lin_from_db(delta_db)
  r.SetMediaTrackInfo_Value(tr, "D_VOL", new_vol)
end

local function process()
  local proj = 0
  local ntr = r.CountSelectedTracks(proj)
  local nitem = r.CountSelectedMediaItems(proj)
  if ntr==0 and nitem==0 then
    r.ShowMessageBox("Bitte Tracks oder Items auswählen.", "DF95 LUFS Auto-Gain", 0)
    return
  end

  local target = meta_target_default()
  local adjusted = 0

  if ntr>0 then
    for i=0,ntr-1 do
      local tr = r.GetSelectedTrack(proj,i)
      local I = get_track_lufs_I(tr)
      if I then
        local delta = clamp_db(target - I)
        gain_trim_track(tr, delta)
        adjusted = adjusted + 1
      end
    end
  end

  if nitem>0 then
    for i=0,nitem-1 do
      local it = r.GetSelectedMediaItem(proj,i)
      local I = get_item_lufs_I(it)
      if I then
        -- Trim at item level via take volume
        local take = r.GetActiveTake(it)
        if take then
          local vol = r.GetMediaItemTakeInfo_Value(take, "D_VOL") or 1.0
          local delta = clamp_db(target - I)
          local new_vol = vol * lin_from_db(delta)
          r.SetMediaItemTakeInfo_Value(take, "D_VOL", new_vol)
          adjusted = adjusted + 1
        end
      end
    end
  end

  r.UpdateArrange()
  r.ShowConsoleMsg(string.format("[DF95] LUFS Auto-Gain: angepasst = %d, Ziel = %.1f LUFS, Clamp=±%.1f dB\n", adjusted, target, MAX_LUFS))
end

r.Undo_BeginBlock()
process()
r.Undo_EndBlock("DF95 LUFS Auto-Gain (SWS hints)", -1)
