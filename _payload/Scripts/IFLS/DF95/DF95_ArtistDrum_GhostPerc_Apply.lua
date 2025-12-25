-- @description Artist Drum Ghost & Perc Density Apply (SamplerProfile-aware)
-- @version 1.0
-- @author DF95

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function load_artist_profile()
  local ok, M = pcall(dofile, df95_root() .. "DF95_ArtistProfile_Loader.lua")
  if not ok or not M or type(M.load) ~= "function" then
    return nil
  end
  local prof, status = M.load()
  if status ~= "ok" then
    return nil
  end
  return prof
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

------------------------------------------------------------
-- Ghost Notes & Perc Dichte auf MIDI anwenden
------------------------------------------------------------

local function apply_ghost_and_perc_on_take(take, sampler_cfg)
  local ghost = sampler_cfg.ghost_notes
  if ghost == nil then
    ghost = true
  end

  local density = sampler_cfg.perc_density or "medium"
  local density_prob = 0.25
  if density == "low" then
    density_prob = 0.12
  elseif density == "medium_high" then
    density_prob = 0.35
  elseif density == "high" then
    density_prob = 0.45
  end

  local _, note_count, _, _ = r.MIDI_CountEvts(take)
  if note_count == 0 then return end

  local notes = {}
  for i = 0, note_count-1 do
    local ok, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
    if ok then
      notes[#notes+1] = {idx=i, sel=sel, muted=muted, startppq=startppq, endppq=endppq,
                         chan=chan, pitch=pitch, vel=vel}
    end
  end

  local _, qn_div, _, _ = r.GetSetProjectGrid(0, false)
  local grid_ppq = nil
  if qn_div and qn_div > 0 then
    local proj = 0
    local tempo = r.Master_GetTempo()
    local sec_per_qn = 60.0 / tempo
    local sec_per_div = sec_per_qn * qn_div
    local ppq_per_sec = r.MIDI_GetPPQPosFromProjTime(take, 1.0) - r.MIDI_GetPPQPosFromProjTime(take, 0.0)
    grid_ppq = sec_per_div * ppq_per_sec
  end

  math.randomseed(os.time() + 2025)

  -- Ghost-Snares
  if ghost then
    for _, n in ipairs(notes) do
      if n.pitch == 38 or n.pitch == 40 then
        local offset = grid_ppq and (grid_ppq * 0.25) or (60.0)
        local ghost_ppq = n.startppq - offset
        if ghost_ppq > 0 then
          local gvel = clamp(math.floor(n.vel * 0.45), 8, 72)
          r.MIDI_InsertNote(take, true, false,
            ghost_ppq, n.startppq,
            n.chan, n.pitch, gvel, false)
        end
      end
    end
  end

  -- Perc Dichte / Micro-Hats: Hihat-Lanes 42/46 und Perc-Lanes 39/43/47
  local function is_hat_or_perc(p)
    return p == 42 or p == 46 or p == 39 or p == 43 or p == 47
  end

  for _, n in ipairs(notes) do
    if is_hat_or_perc(n.pitch) then
      if math.random() < density_prob then
        local off = 0
        if grid_ppq then
          off = (math.random()*2 - 1) * (grid_ppq * 0.3)
        else
          off = (math.random()*2 - 1) * 40.0
        end
        local start2 = n.startppq + off
        local end2 = start2 + (n.endppq - n.startppq) * 0.75
        if end2 > start2 then
          local v2 = clamp(math.floor(n.vel * (0.5 + math.random()*0.4)), 1, 110)
          r.MIDI_InsertNote(take, true, false,
            start2, end2,
            n.chan, n.pitch, v2, false)
        end
      end
    end
  end
end

local function main()
  local prof = load_artist_profile()
  if not prof or not prof.sampler then
    return
  end
  local sampler_cfg = prof.sampler or {}

  local item_count = r.CountSelectedMediaItems(0)
  if item_count == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, item_count-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(it)
    if take and r.TakeIsMIDI(take) then
      apply_ghost_and_perc_on_take(take, sampler_cfg)
      r.MIDI_Sort(take)
    end
  end

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 Artist Drum Ghost & Perc Density Apply", -1)
end

main()
