-- @description AutoColor – Tracks & Busses by Role (Input / Creative / Master / Export / QA)
-- @version 1.0
-- @author DF95
-- @about
--   Färbt Tracks und Busse anhand von Namenskonventionen und Rollen ein.
--   Ziel: schnellere Orientierung, weniger kognitive Last und bessere kreative Fokussierung.

local r = reaper

local function color(r_, g_, b_)
  return r.ColorToNative(r_, g_, b_) | 0x1000000
end

local COLORS = {
  INPUT_ZF6   = color(0x1F, 0x4F, 0xA8), -- Zoom F6 Blau
  INPUT_H5    = color(0x33, 0x66, 0xCC), -- Zoom H5 Blau
  INPUT_ANDROID = color(0x34, 0x56, 0x78), -- Android Fieldrec

  FX_GLITCH   = color(0xFF, 0x8E, 0x3C), -- Orange
  FX_FILTER   = color(0xC2, 0x55, 0xFF), -- Lila
  FX_PERC     = color(0xD9, 0x48, 0xD4), -- Magenta

  COLORING    = color(0x9E, 0x9E, 0x9E), -- Neutral-Grau
  MASTER      = color(0x00, 0xB8, 0x6C), -- Grün

  EXPORT      = color(0xFF, 0xEB, 0x3B), -- Gelb
  META        = color(0x2D, 0xC9, 0xB4), -- Türkis

  QA          = color(0x42, 0x42, 0x42), -- Anthrazit
}

local function classify_track(name)
  local lname = name:lower()

  -- Input / Recorder
  if lname:find("^in_zf6") or lname:find("zoom f6") then
    return "INPUT_ZF6"
  elseif lname:find("^in_h5") or lname:find("zoom h5") then
    return "INPUT_H5"
  elseif lname:find("^in_andr") or lname:find("android") or lname:find("fieldrec") then
    return "INPUT_ANDROID"
  end

  -- FX / Creative
  if lname:find("glitch") or lname:find("idm") or lname:find("rearrange") then
    return "FX_GLITCH"
  elseif lname:find("filtermotion") or lname:find("filter motion") then
    return "FX_FILTER"
  elseif lname:find("drumghost") or lname:find("perc") then
    return "FX_PERC"
  end

  -- Coloring / Master
  if lname:find("coloring") or lname:find("colouring") then
    return "COLORING"
  end
  if lname:find("master bus") or lname == "master" or lname:find("[master") then
    return "MASTER"
  end

  -- Export / Meta / QA
  if lname:find("export") or lname:find("render") then
    return "EXPORT"
  end
  if lname:find("meta") or lname:find("ucs") then
    return "META"
  end
  if lname:find("qa") or lname:find("safety") or lname:find("analyze") or lname:find("analyse") then
    return "QA"
  end

  return nil
end

local function main()
  local proj = 0
  local track_count = r.CountTracks(proj)
  if track_count == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i = 0, track_count-1 do
    local tr = r.GetTrack(proj, i)
    local _, name = r.GetTrackName(tr, "")
    if name and name ~= "" then
      local role = classify_track(name)
      if role and COLORS[role] then
        r.SetTrackColor(tr, COLORS[role])
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("AutoColor – Tracks & Busses by Role", -1)
end

main()
