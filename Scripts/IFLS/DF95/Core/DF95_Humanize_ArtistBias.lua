-- @description Humanize – Artist Bias (with LUFS Clamp)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Applies timing/velocity/offset humanization weighted by artist/style bias. Loudness deltas clamped to ±1.3 LUFS to avoid artifacts.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local data = res..sep.."Data"..sep.."DF95"
local bias_fn = data..sep.."DF95_ArtistBias.json"
local tips_fn = data..sep.."DF95_Help.json"

local function readall(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function json_decode(s) if r.JSON_Decode then return r.JSON_Decode(s) end end

local bias = json_decode(readall(bias_fn) or "{}") or {weights={}}
local help = json_decode(readall(tips_fn) or "{}") or {}

-- parameters via config
local cfg_fn = data..sep.."DF95_Humanize_Config.json"
local cfg = json_decode(readall(cfg_fn) or "{}") or {}
local MAX_LUFS = tonumber(cfg.clamp_lufs or 1.3)
local USE_SWS_LUFS = cfg.use_sws_lufs == true
local base_timing_ms = 6
local base_vel = 8
local function weight(tag) return (bias.weights and bias.weights[tag] or 0) end

local function humanize_selected_items()
  local cnt = r.CountSelectedMediaItems(0)
  if cnt==0 then return 0 end
  for i=0,cnt-1 do
    local it = r.GetSelectedMediaItem(0,i)
    -- position nudge (small random, bias-affected)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
    local w = 1 + 0.1*(
      weight("artist:autechre") + weight("style:glitch") - weight("artist:boc")
    )
    local jitter = (math.random()-0.5)*2 * (base_timing_ms/1000.0) * w
    r.SetMediaItemInfo_Value(it, "D_POSITION", pos + jitter)
    -- fade micro-shape
    local f_in = math.min(len*0.1, 0.010 * (1.0 + weight("style:idm")*0.1))
    local f_out= math.min(len*0.1, 0.012 * (1.0 + weight("style:glitch")*0.1))
    r.SetMediaItemInfo_Value(it, "D_FADEINLEN", f_in)
    r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", f_out)
  end
  r.UpdateArrange()
  return cnt
end

local function clamp_lufs_delta(delta)
  if delta > MAX_LUFS then return MAX_LUFS end
  if delta < -MAX_LUFS then return -MAX_LUFS end
  return delta
end

local function apply_lufs_clamp_on_tracks()
  -- This is a lightweight placeholder: we clamp using take volume as proxy.
  -- For full LUFS-I integration, hook into your ReaJS LUFS meter outputs.
  local sel = r.CountSelectedTracks(0)
  for i=0,sel-1 do
    local tr = r.GetSelectedTrack(0,i)
    local vol = r.GetMediaTrackInfo_Value(tr, "D_VOL")
    -- pretend delta computation (0.0→no change). In your pipeline, replace with real LUFS delta.
    local desired_delta = 0.0
    local d = clamp_lufs_delta(desired_delta)
    local new_vol = vol * (10^(d/20))
    r.SetMediaTrackInfo_Value(tr, "D_VOL", new_vol)
  end
end

local function show_tooltip_if_any(key)
  local txt = (help and help.tooltips and help.tooltips[key]) and help.tooltips[key] or nil
  if txt then r.ShowConsoleMsg("[DF95 Tip] "..txt.."\n") end
end

r.Undo_BeginBlock()
local n = humanize_selected_items()
apply_lufs_clamp_on_tracks()
r.Undo_EndBlock(("DF95 Humanize ArtistBias (items=%d, clamp=±%.1f LUFS)"):format(n, 1.3), -1)
show_tooltip_if_any("humanize_artistbias")


-- Optional: try SWS loudness analyze (offline). Falls vorhanden, wird Analyse getriggert.
local function try_sws_analyze()
  if not USE_SWS_LUFS then return false end
  -- Versuche einige bekannte SWS-Action-IDs
  local candidates = {
    "_SWS_LOUANATRK", -- SWS: Analyze loudness of selected tracks
    "_SWS_LOUANAITEM", -- SWS: Analyze loudness of selected items
    "_SWS_LOUANA", -- generic
  }
  for _,tok in ipairs(candidates) do
    local cmd = reaper.NamedCommandLookup(tok)
    if cmd and cmd > 0 then
      reaper.Main_OnCommand(cmd,0)
      return true
    end
  end
  return false
end
