-- DF95_Rearrange_Menu.lua
-- Dropdown-Rearrange: Align / Shuffle / Euclid / Drill / Artist-based
-- Mit Kennzeichnung TIMING SAFE / TIMING CHANGES / MIXED

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(s, "DF95 Rearrange Menu", 0)
end

local function get_df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function run_df95_script(rel)
  local base = get_df95_root()
  local path = base .. rel
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Konnte DF95-Script nicht ausführen:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 Rearrange Menu", 0)
  end
end

local function collect_selected_items_by_track()
  local tracks = {}
  local order = {}
  local n = r.CountSelectedMediaItems(0)
  for i = 0, n-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local tr = r.GetMediaItem_Track(item)
    local key = tostring(tr)
    if not tracks[key] then
      tracks[key] = { track = tr, items = {} }
      order[#order+1] = key
    end
    table.insert(tracks[key].items, item)
  end
  return tracks, order
end

local function sort_items_by_pos(items)
  table.sort(items, function(a,b)
    local pa = r.GetMediaItemInfo_Value(a,"D_POSITION")
    local pb = r.GetMediaItemInfo_Value(b,"D_POSITION")
    if pa == pb then
      local la = r.GetMediaItemInfo_Value(a,"D_LENGTH")
      local lb = r.GetMediaItemInfo_Value(b,"D_LENGTH")
      return la < lb
    end
    return pa < pb
  end)
end

local function fisher_yates_shuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

------------------------------------------------------------
-- Rearrange Modes
------------------------------------------------------------

local function rearrange_shuffle_per_track()
  local tracks, order = collect_selected_items_by_track()
  if #order == 0 then
    msg("Keine Items selektiert.")
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for _, key in ipairs(order) do
    local pack = tracks[key]
    local items = pack.items
    if #items > 1 then
      sort_items_by_pos(items)
      local positions = {}
      for i,it in ipairs(items) do
        positions[i] = r.GetMediaItemInfo_Value(it,"D_POSITION")
      end
      local perm = {}
      for i = 1,#items do perm[i]=i end
      fisher_yates_shuffle(perm)
      for i,it in ipairs(items) do
        local newpos = positions[perm[i]]
        r.SetMediaItemInfo_Value(it,"D_POSITION", newpos)
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Rearrange – Random Shuffle (per track)", -1)
  r.UpdateArrange()
end

local function rearrange_shuffle_global()
  local tracks, order = collect_selected_items_by_track()
  if #order == 0 then
    msg("Keine Items selektiert.")
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local items_all = {}
  local positions = {}

  for _, key in ipairs(order) do
    local pack = tracks[key]
    for _,it in ipairs(pack.items) do
      items_all[#items_all+1] = it
    end
  end

  if #items_all < 2 then
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock("DF95 Rearrange – Random Shuffle (global)", -1)
    return
  end

  sort_items_by_pos(items_all)
  for i,it in ipairs(items_all) do
    positions[i] = r.GetMediaItemInfo_Value(it,"D_POSITION")
  end

  local perm = {}
  for i = 1,#items_all do perm[i]=i end
  fisher_yates_shuffle(perm)

  for i,it in ipairs(items_all) do
    r.SetMediaItemInfo_Value(it,"D_POSITION", positions[perm[i]])
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Rearrange – Random Shuffle (global)", -1)
  r.UpdateArrange()
end

local function rearrange_weighted_shuffle()
  local tracks, order = collect_selected_items_by_track()
  if #order == 0 then
    msg("Keine Items selektiert.")
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  math.randomseed(os.time())

  local range = 2.0

  for _, key in ipairs(order) do
    local pack = tracks[key]
    local items = pack.items
    if #items > 1 then
      sort_items_by_pos(items)
      local positions = {}
      for i,it in ipairs(items) do
        positions[i] = r.GetMediaItemInfo_Value(it,"D_POSITION")
      end
      local scored = {}
      for i,it in ipairs(items) do
        local jitter = (math.random() - 0.5) * 2 * range
        local score = i + jitter
        scored[#scored+1] = { item = it, score = score }
      end
      table.sort(scored, function(a,b) return a.score < b.score end)
      for i,slot in ipairs(scored) do
        local it = slot.item
        local newpos = positions[i]
        r.SetMediaItemInfo_Value(it,"D_POSITION", newpos)
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Rearrange – Weighted Shuffle", -1)
  r.UpdateArrange()
end

local function euclid_pattern(steps, pulses)
  steps = math.max(1, math.floor(steps+0.5))
  pulses = math.max(0, math.floor(pulses+0.5))
  if pulses > steps then pulses = steps end
  local pattern = {}
  if pulses <= 0 then
    for i=0,steps-1 do pattern[i]=0 end
    return pattern
  end
  local bucket = 0
  for i=0,steps-1 do
    bucket = bucket + pulses
    if bucket >= steps then
      bucket = bucket - steps
      pattern[i] = 1
    else
      pattern[i] = 0
    end
  end
  return pattern
end

local function rearrange_euclid()
  local tracks, order = collect_selected_items_by_track()
  if #order == 0 then
    msg("Keine Items selektiert.")
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  math.randomseed(os.time())

  for _, key in ipairs(order) do
    local pack = tracks[key]
    local items = pack.items
    if #items > 1 then
      sort_items_by_pos(items)
      local positions = {}
      for i,it in ipairs(items) do
        positions[i] = r.GetMediaItemInfo_Value(it,"D_POSITION")
      end
      local N = #items
      local pulses = math.max(1, math.floor(N * 0.6))
      local pat = euclid_pattern(N, pulses)
      local idx_pulse = {}
      local idx_rest = {}
      for i = 0, N-1 do
        if pat[i] == 1 then idx_pulse[#idx_pulse+1] = i+1 else idx_rest[#idx_rest+1] = i+1 end
      end
      local new_order = {}
      for _,v in ipairs(idx_pulse) do new_order[#new_order+1] = v end
      for _,v in ipairs(idx_rest) do new_order[#new_order+1] = v end
      for new_idx,old_idx in ipairs(new_order) do
        local it = items[old_idx]
        local newpos = positions[new_idx]
        r.SetMediaItemInfo_Value(it,"D_POSITION", newpos)
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Rearrange – Euclid Reorder", -1)
  r.UpdateArrange()
end

local function rearrange_drill()
  local tracks, order = collect_selected_items_by_track()
  if #order == 0 then
    msg("Keine Items selektiert.")
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  math.randomseed(os.time())

  local drill_prob = 0.35
  local max_shift_frac = 0.25
  local min_len_frac  = 0.25

  for _, key in ipairs(order) do
    local pack = tracks[key]
    local items = pack.items
    if #items > 0 then
      sort_items_by_pos(items)
      for _,it in ipairs(items) do
        if math.random() < drill_prob then
          local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
          local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
          local shrink = len * (0.5 + (math.random()-0.5)*0.4)
          shrink = math.max(len * min_len_frac, shrink)
          local shift = (math.random()-0.5) * 2 * max_shift_frac * len
          r.SetMediaItemInfo_Value(it, "D_LENGTH", shrink)
          r.SetMediaItemInfo_Value(it, "D_POSITION", pos + shift)
        end
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 Rearrange – Drill / Stutter", -1)
  r.UpdateArrange()
end

local function rearrange_artist_based()
  local _, artist = r.GetProjExtState(0, "DF95_SLICING", "ARTIST")
  local _, intensity = r.GetProjExtState(0, "DF95_SLICING", "INTENSITY")

  artist   = (artist or ""):lower()
  intensity = (intensity or "medium"):lower()

  if artist == "" then
    local ok, ret = r.GetUserInputs("DF95 Artist Rearrange", 2,
      "Artist (autechre/boc/...)", "Intensity (soft/medium/extreme)",
      "autechre,medium")
    if not ok then return end
    artist, intensity = ret:match("([^,]+),([^,]+)")
    artist = (artist or ""):lower()
    intensity = (intensity or "medium"):lower()
  end

  if artist:find("autechre") or artist:find("bogdan") then
    rearrange_euclid()
    rearrange_drill()
  elseif artist:find("squarepusher") or artist:find("aphex") or artist:find("jega") then
    rearrange_shuffle_per_track()
    rearrange_drill()
  elseif artist:find("boc") or artist:find("jan") or artist:find("jelinek") then
    rearrange_weighted_shuffle()
  elseif artist:find("fly") or artist:find("lotus") then
    rearrange_weighted_shuffle()
    rearrange_shuffle_global()
  else
    rearrange_weighted_shuffle()
  end
end

local function rearrange_align()
  run_df95_script("DF95_Rearrange_Align.lua")
end

------------------------------------------------------------
-- Menu
------------------------------------------------------------

local function main()
  gfx.init("DF95 Rearrange Menu", 0, 0, 0, 0, 0)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y

  local menu = ""
  menu = menu .. "Align slices vertically (TIMING SAFE)|"
  menu = menu .. ">Random modes|"
  menu = menu .. "Random Shuffle (per track, TIMING SAFE)|"
  menu = menu .. "Random Shuffle (global, TIMING SAFE)|"
  menu = menu .. "Weighted Shuffle (near original, TIMING SAFE)|"
  menu = menu .. "Euclid Reorder (TIMING SAFE)|"
  menu = menu .. "Drill / Stutter (TIMING CHANGES)|"
  menu = menu .. "<Artist-based Reorder (MIXED)|"
  menu = menu .. "Cancel|"

  local sel = gfx.showmenu(menu)

  if sel == 1 then
    rearrange_align()
  elseif sel == 3 then
    rearrange_shuffle_per_track()
  elseif sel == 4 then
    rearrange_shuffle_global()
  elseif sel == 5 then
    rearrange_weighted_shuffle()
  elseif sel == 6 then
    rearrange_euclid()
  elseif sel == 7 then
    rearrange_drill()
  elseif sel == 8 then
    rearrange_artist_based()
  else
  end
end

main()
