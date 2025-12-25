-- @description DF95_V97_Fieldrec_BeatEngine_Audio
-- @version 1.0
-- @author DF95
-- @about
--   Erzeugt einen Audio-Beat aus den von V95/V95.1 erzeugten Fieldrec-Slices.
--   Arbeitsschritte:
--     - Sucht in der Session nach Tracks, deren Namen V95-Klassen enthalten:
--         * V95_LOW_PERC   -> Kick/Tom-Rolle
--         * V95_SNARE_PERC -> Snare-Rolle
--         * V95_HAT_CYMBAL -> HiHat/Cymbal-Rolle
--     - Sammelt alle Items pro Klasse als mögliche Hits.
--     - Fragt dich nach:
--         * Beat-Stil (Basic / Tegra / Squarepusher-ish)
--         * Anzahl Takte
--     - Erzeugt einen neuen Folder "V97_Beat_Audio" mit Child-Tracks:
--         * V97_Kick_Audio
--         * V97_Snare_Audio
--         * V97_Hat_Audio
--     - Platziert Kopien der Slices gemäß Pattern (Random-Selection aus den verfügbaren Hits).
--   Hinweis:
--     - Dieses Script arbeitet rein mit Audio-Items, kein Sampler/MIDI.
--     - V95/V95.1 sollten vorher auf dein Fieldrec-Material angewandt worden sein.

local r = reaper

------------------------------------------------------------
local function msg(s) r.ShowMessageBox(s, "DF95 V97 BeatEngine Audio", 0) end

local function get_project_tempo_timesig()
  local proj = 0
  local _, tempo, num, denom, _ = r.GetProjectTimeSignature2(proj)
  return tempo, num, denom
end

local function collect_class_items()
  local proj = 0
  local n_tr = r.CountTracks(proj)
  local classes = {
    LOW_PERC   = {},
    SNARE_PERC = {},
    HAT_CYMBAL = {},
  }

  for i = 0, n_tr-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if name and name ~= "" then
      local upper = name:upper()
      local class_key = nil
      if upper:find("V95_LOW_PERC") then
        class_key = "LOW_PERC"
      elseif upper:find("V95_SNARE_PERC") then
        class_key = "SNARE_PERC"
      elseif upper:find("V95_HAT_CYMBAL") then
        class_key = "HAT_CYMBAL"
      end
      if class_key then
        local item_count = r.CountTrackMediaItems(tr)
        for it = 0, item_count-1 do
          local item = r.GetTrackMediaItem(tr, it)
          local take = r.GetActiveTake(item)
          if take and not r.TakeIsMIDI(take) then
            table.insert(classes[class_key], { item = item, take = take })
          end
        end
      end
    end
  end

  return classes
end

local function random_choice(tbl)
  local n = #tbl
  if n == 0 then return nil end
  local idx = math.random(1, n)
  return tbl[idx]
end

local function create_beat_folder()
  local proj = 0
  local idx = r.CountTracks(proj)
  r.InsertTrackAtIndex(idx, true)
  local folder = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(folder, "P_NAME", "V97_Beat_Audio", true)
  r.SetMediaTrackInfo_Value(folder, "I_FOLDERDEPTH", 1)

  local function make_child(name, depth)
    r.InsertTrackAtIndex(idx+1, true)
    local tr = r.GetTrack(proj, idx+1)
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
    r.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", depth or 0)
    idx = idx + 1
    return tr
  end

  local kick  = make_child("V97_Kick_Audio", 0)
  local snare = make_child("V97_Snare_Audio", 0)
  local hat   = make_child("V97_Hat_Audio", -1) -- letzter Child schließt Folder

  return {
    folder = folder,
    kick   = kick,
    snare  = snare,
    hat    = hat,
  }
end

local function copy_slice_to_track(slice, dest_track, position)
  local src_item = slice.item
  local src_take = slice.take

  local src_len = r.GetMediaItemInfo_Value(src_item, "D_LENGTH")
  local src_vol = r.GetMediaItemInfo_Value(src_item, "D_VOL")
  local src_color = r.GetMediaItemInfo_Value(src_item, "I_CUSTOMCOLOR")

  local src_take_src = r.GetMediaItemTake_Source(src_take)
  local start_offs = r.GetMediaItemTakeInfo_Value(src_take, "D_STARTOFFS")
  local playrate  = r.GetMediaItemTakeInfo_Value(src_take, "D_PLAYRATE")
  if playrate <= 0 then playrate = 1.0 end

  local new_item = r.AddMediaItemToTrack(dest_track)
  r.SetMediaItemInfo_Value(new_item, "D_POSITION", position)
  r.SetMediaItemInfo_Value(new_item, "D_LENGTH",  src_len)
  r.SetMediaItemInfo_Value(new_item, "D_VOL",     src_vol)
  r.SetMediaItemInfo_Value(new_item, "I_CUSTOMCOLOR", src_color)

  local new_take = r.AddTakeToMediaItem(new_item)
  r.SetMediaItemTake_Source(new_take, src_take_src)
  r.SetMediaItemTakeInfo_Value(new_take, "D_STARTOFFS", start_offs)
  r.SetMediaItemTakeInfo_Value(new_take, "D_PLAYRATE",  playrate)

  -- kleine Safety-Fades
  local fade_len = math.min(0.005, src_len * 0.25)
  r.SetMediaItemInfo_Value(new_item, "D_FADEINLEN",  fade_len)
  r.SetMediaItemInfo_Value(new_item, "D_FADEOUTLEN", fade_len)
end

------------------------------------------------------------
-- Beat-Patterns je Style (in Beats relativ zu Taktbeginn)
------------------------------------------------------------
local function get_patterns(style, beats_per_bar)
  -- Basis: wir gehen von 4/4 aus, beats_per_bar typischerweise 4
  local K, S, H = {}, {}, {}

  if style == "1" then
    -- Basic: 4/4 Backbeat, 8tel-Hihat
    K = {0, 2}
    S = {1, 3}
    H = {}
    local step = 0.5
    local t = 0.0
    while t < beats_per_bar do
      table.insert(H, t)
      t = t + step
    end
  elseif style == "2" then
    -- Tegra-ish: etwas mehr Syncopation
    K = {0, 1.75, 2.5}
    S = {1, 3.25}
    H = {}
    local steps = {0,0.5,1,1.5,2,2.5,3,3.5}
    for _,t in ipairs(steps) do
      if t ~= 2 then  -- kleine Lücke
        table.insert(H, t)
      end
    end
  else
    -- Squarepusher-ish: dichter, randomisierte Hats + Ghosts
    K = {0, 2.25}
    S = {1, 1.75, 3}
    H = {}
    local step = 0.25
    local t = 0.0
    while t < beats_per_bar do
      -- probabilistische Hats
      local p = 0.6
      if math.random() < p then
        table.insert(H, t)
      end
      t = t + step
    end
  end

  return K, S, H
end

------------------------------------------------------------
local function main()
  math.randomseed(os.time())

  local tempo, num, denom = get_project_tempo_timesig()
  local beats_per_bar = num -- vereinfachend

  local classes = collect_class_items()
  if #classes.LOW_PERC == 0 and #classes.SNARE_PERC == 0 and #classes.HAT_CYMBAL == 0 then
    msg("Keine V95-Klassentracks mit Items gefunden.
Bitte zuerst V95/V95.1 auf dein Material anwenden.")
    return
  end

  local default_vals = "2,4" -- Style 2 (Tegra-ish), 4 Takte
  local ret, vals = r.GetUserInputs("DF95 V97 BeatEngine Audio", 2,
    "Style (1=Basic,2=Tegra,3=Square),Bars (Anzahl Takte)", default_vals)
  if not ret then return end
  local style, bars = vals:match("([^,]+),([^,]+)")
  style = style or "2"
  bars = tonumber(bars) or 4
  if bars < 1 then bars = 1 end

  local tracks = create_beat_folder()

  r.Undo_BeginBlock()

  local proj = 0
  local start_time = r.GetCursorPosition()
  local _, _, _, _ = r.GetProjectTimeSignature2(proj)
  local K_pattern, S_pattern, H_pattern = get_patterns(style, beats_per_bar)

  local function barbeat_to_time(bar_index, beat_in_bar)
    -- bar_index: 0-basiert
    local beat_pos = bar_index * beats_per_bar + beat_in_bar
    local time = r.TimeMap2_beatsToTime(proj, beat_pos, 0)
    return time
  end

  for bar = 0, bars-1 do
    -- Kick
    for _, beat in ipairs(K_pattern) do
      if #classes.LOW_PERC > 0 then
        local slice = random_choice(classes.LOW_PERC)
        if slice then
          local t = barbeat_to_time(bar, beat)
          copy_slice_to_track(slice, tracks.kick, t)
        end
      end
    end
    -- Snare
    for _, beat in ipairs(S_pattern) do
      if #classes.SNARE_PERC > 0 then
        local slice = random_choice(classes.SNARE_PERC)
        if slice then
          local t = barbeat_to_time(bar, beat)
          copy_slice_to_track(slice, tracks.snare, t)
        end
      end
    end
    -- Hat
    for _, beat in ipairs(H_pattern) do
      if #classes.HAT_CYMBAL > 0 then
        local slice = random_choice(classes.HAT_CYMBAL)
        if slice then
          local t = barbeat_to_time(bar, beat)
          copy_slice_to_track(slice, tracks.hat, t)
        end
      end
    end
  end

  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V97 BeatEngine Audio", -1)
end

main()
