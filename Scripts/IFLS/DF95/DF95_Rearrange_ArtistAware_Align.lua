-- @description Rearrange Artist-Aware Align+Glitch (uses DF95_REARRANGE profile)
-- @version 1.1
-- @author DF95

local r = reaper

------------------------------------------------------------
-- Profile Loader
------------------------------------------------------------

local function DF95_LoadProfileFromExtState(ns, default_tbl)
  if not r.JSONDecode then
    return default_tbl
  end
  local rv, json_str = r.GetProjExtState(0, ns, "PROFILE_JSON")
  if rv == 0 or not json_str or json_str == "" then
    return default_tbl
  end
  local ok, tbl = pcall(function() return r.JSONDecode(json_str) end)
  if not ok or type(tbl) ~= "table" then
    return default_tbl
  end
  for k, v in pairs(default_tbl or {}) do
    if tbl[k] == nil then
      tbl[k] = v
    end
  end
  return tbl
end

-- Artist-Rearrange-Profil mit sinnvollen Default-Werten
local rearr_profile = DF95_LoadProfileFromExtState("DF95_REARRANGE", {
  mutation_amount   = 0.35,   -- 0..1: Anteil der Slices, die permutiert werden
  glitch_intensity  = 0.25,   -- 0..1: Stärke der Mikro-Glitches
  reverse_probability = 0.1,  -- 0..1: Wahrscheinlichkeit, ein Item zu reversen
  window_items      = 4       -- wie weit darf eine Slice in der Nachbarschaft "springen"
})

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function get_selected_items_sorted()
  local t = {}
  local cnt = r.CountSelectedMediaItems(0)
  for i = 0, cnt-1 do
    local it = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    t[#t+1] = { item = it, pos = pos }
  end
  table.sort(t, function(a,b) return a.pos < b.pos end)
  return t
end

local function clamp01(x)
  if x < 0 then return 0 end
  if x > 1 then return 1 end
  return x
end

------------------------------------------------------------
-- Glitch-/Permutation-Engine
------------------------------------------------------------

local function apply_rearrange_permutation(items, profile)
  local n = #items
  if n < 2 then return end

  local mut = clamp01(profile.mutation_amount or 0.0)
  local win = tonumber(profile.window_items) or 4
  if win < 1 then win = 1 end

  local indices = {}
  for i = 1, n do indices[i] = i end

  local num_mut = math.floor(n * mut + 0.5)
  if num_mut < 1 then return end

  math.randomseed(os.time())

  for k = 1, num_mut do
    local i = math.random(1, n)
    local jmin = math.max(1, i - win)
    local jmax = math.min(n, i + win)
    local j = math.random(jmin, jmax)
    if j ~= i then
      local it_i = items[i].item
      local it_j = items[j].item
      local pos_i = r.GetMediaItemInfo_Value(it_i, "D_POSITION")
      local pos_j = r.GetMediaItemInfo_Value(it_j, "D_POSITION")
      r.SetMediaItemInfo_Value(it_i, "D_POSITION", pos_j)
      r.SetMediaItemInfo_Value(it_j, "D_POSITION", pos_i)
    end
  end
end

local function apply_glitch_variation(items, profile)
  local n = #items
  if n == 0 then return end

  local g = clamp01(profile.glitch_intensity or 0.0)
  local rev_p = clamp01(profile.reverse_probability or 0.0)
  if g == 0 and rev_p == 0 then return end

  math.randomseed(os.time() + 1337)

  for i = 1, n do
    local it = items[i].item
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")

    -- Optional: Reverse mit reverse_probability
    if rev_p > 0 and math.random() < rev_p then
      local take = r.GetActiveTake(it)
      if take and not r.TakeIsMIDI(take) then
        local rev_flag = r.GetMediaItemTakeInfo_Value(take, "B_REVERSE")
        r.SetMediaItemTakeInfo_Value(take, "B_REVERSE", rev_flag > 0 and 0 or 1)
      end
    end

    if g > 0 then
      -- Mikro-Offset und Längenänderung
      local max_offset = len * 0.3 * g
      local off = (math.random()*2 - 1) * max_offset
      local new_pos = math.max(0, pos + off)

      local len_factor_min = 0.5
      local len_factor_max = 1.2
      local f = len_factor_min + (len_factor_max - len_factor_min) * (0.3 + 0.7 * g)
      local len_factor = 1.0 + (math.random()*2 - 1) * (f - 1.0)

      local new_len = math.max(0.01, len * len_factor)

      r.SetMediaItemInfo_Value(it, "D_POSITION", new_pos)
      r.SetMediaItemInfo_Value(it, "D_LENGTH", new_len)
    end
  end
end

------------------------------------------------------------
-- Align + Artist-basiertes Rearrangement
------------------------------------------------------------

local function run_align()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local script_path = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep ..
    "DF95" .. sep .. "DF95_Rearrange_Align.lua"):gsub("\\","/")
  local ok, err = pcall(dofile, script_path)
  if not ok then
    r.ShowMessageBox("Fehler beim Ausführen von DF95_Rearrange_Align.lua:\n"..tostring(err).."\nPfad: "..script_path,
      "DF95 Rearrange Artist-Aware Align", 0)
  end
end

local function main()
  -- Schritt 1: klassisches Align
  run_align()

  -- Schritt 2: Items holen (nach Align)
  local items = get_selected_items_sorted()
  if #items == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  -- Schritt 3: Permutation gemäß Artist-Profil
  apply_rearrange_permutation(items, rearr_profile)

  -- Schritt 4: Mikro-Glitches / Reverse gemäß Artist-Profil
  apply_glitch_variation(items, rearr_profile)

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("[DF95] Rearrange Artist-Aware Align+Glitch", -1)
end

main()
