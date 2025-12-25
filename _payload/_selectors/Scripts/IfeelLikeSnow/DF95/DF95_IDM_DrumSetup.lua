-- DF95_IDM_DrumSetup.lua
-- Auto-Setup for IDM Drum Project:
-- - erkennt Tracks per Name (Kick/Snare/Hats)
-- - legt passende Slicing-Presets (IDM_Kicks/Snares/Hats) auf die Drumtracks
-- - erzeugt / verwendet passende FXBusse (IDM Kick/Snare/Hats Bus)
-- - routet die Drumtracks auf die jeweiligen Busse
--
-- Nutzt Chains/Slicing/IDM und Chains/FXBus/IDM_* Strukturen.

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(s, "DF95 IDM DrumSetup", 0)
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function load_common()
  local base = df95_root()
  local path = base .. "DF95_Common_RfxChainLoader.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Konnte DF95_Common_RfxChainLoader.lua nicht laden:\n"..tostring(mod),
      "DF95 IDM DrumSetup", 0)
    return nil
  end
  return mod
end

local function chains_root(sub)
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Chains" .. sep .. (sub or "")):gsub("\\","/")
end

local function read_file(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

local function apply_rfxchain_to_track(track, abs_path)
  local C = load_common()
  if not C then return end
  local txt = read_file(abs_path)
  if not txt then
    r.ShowMessageBox("Konnte FXChain nicht lesen:\n"..abs_path, "DF95 IDM DrumSetup", 0)
    return
  end
  local ok, err = C.write_chunk_fxchain(track, txt, true)
  if not ok then
    r.ShowMessageBox("Fehler beim Anwenden der FXChain:\n"..tostring(err), "DF95 IDM DrumSetup", 0)
  end
end

local function ensure_bus_track(name)
  local C = load_common()
  if not C then return nil end
  local bus = C.ensure_track_named(name)
  return bus
end

local function create_send(src, dst)
  if not src or not dst then return end
  -- avoid duplicate sends
  local num_sends = reaper.GetTrackNumSends(src, 0)
  for i = 0, num_sends-1 do
    local send_dst = reaper.BR_GetMediaTrackSendInfo_Track(src, 0, i, 1)
    if send_dst == dst then
      return -- already routed
    end
  end
  local send_idx = reaper.CreateTrackSend(src, dst)
  if send_idx >= 0 then
    reaper.SetTrackSendInfo_Value(src, 0, send_idx, "D_VOL", 1.0)
    reaper.SetTrackSendInfo_Value(src, 0, send_idx, "I_SENDMODE", 0) -- post-fader
  end
end

  local send_idx = r.CreateTrackSend(src, dst)
  if send_idx >= 0 then
    r.SetTrackSendInfo_Value(src, 0, send_idx, "D_VOL", 1.0)
    r.SetTrackSendInfo_Value(src, 0, send_idx, "I_SENDMODE", 0) -- post-fader
  end
end

local function classify_role(name)
  local n = (name or ""):lower()
  if n:find("kick") or n:find(" bd") or n:find("bd ") or n:find("kik") or n:find("bassdrum") then
    return "kick"
  end
  if n:find("snare") or n:find("snr") or n:find("sd") or n:find("rim") or n:find("clap") then
    return "snare"
  end
  if n:find("hat") or n:find("hh") or n:find("hihat") or n:find("ride") or n:find("cym") then
    return "hats"
  end
  return nil
end

  if n:find("snare") or n:find("snr") or n:find("sd") or n:find("rim") or n:find("clap") then
    return "snare"
  end
  if n:find("hat") or n:find("hh") or n:find("hihat") or n:find("ride") or n:find("cym") then
    return "hats"
  end
  return nil
end

local function choose_bus_chain(role, intensity)
  intensity = intensity or "medium"
  if role == "kick" then
    if intensity == "safe" then
      return "FXBus/IDM_Kicks/Bus_IDM_Kicks_Punch_Safe_01.rfxchain"
    elseif intensity == "extreme" then
      return "FXBus/IDM_Kicks/Bus_IDM_Kicks_Punch_Extreme_01.rfxchain"
    else
      return "FXBus/IDM_Kicks/Bus_IDM_Kicks_Punch_01.rfxchain"
    end
  elseif role == "snare" then
    if intensity == "safe" then
      return "FXBus/IDM_Snares/Bus_IDM_Snares_Snap_Safe_01.rfxchain"
    elseif intensity == "extreme" then
      return "FXBus/IDM_Snares/Bus_IDM_Snares_Snap_Extreme_01.rfxchain"
    else
      return "FXBus/IDM_Snares/Bus_IDM_Snares_Snap_01.rfxchain"
    end
  elseif role == "hats" then
    if intensity == "safe" then
      return "FXBus/IDM_Hats/Bus_IDM_Hats_Air_Safe_01.rfxchain"
    elseif intensity == "extreme" then
      return "FXBus/IDM_Hats/Bus_IDM_Hats_Air_Extreme_01.rfxchain"
    else
      return "FXBus/IDM_Hats/Bus_IDM_Hats_Air_01.rfxchain"
    end
  end
  return nil
end

local function choose_slicing_chain(role)
  if role == "kick" then
    return "Slicing/IDM/Slicing_IDM_Kicks_01.rfxchain"
  elseif role == "snare" then
    return "Slicing/IDM/Slicing_IDM_Snares_01.rfxchain"
  elseif role == "hats" then
    return "Slicing/IDM/Slicing_IDM_Hats_01.rfxchain"
  end
  return nil
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
  local num_tracks = r.CountTracks(0)
  if num_tracks == 0 then
    msg("Keine Tracks im Projekt.")
    return
  end

  local ok, ret = r.GetUserInputs("DF95 IDM DrumSetup", 2,
    "Bus Intensity (safe/medium/extreme),Include slicing FX on tracks? (yes/no)",
    "medium,yes")
  if not ok then return end
  local intensity, do_slicing = ret:match("([^,]+),([^,]+)")
  intensity = (intensity or "medium"):lower()
  if intensity ~= "safe" and intensity ~= "medium" and intensity ~= "extreme" then
    intensity = "medium"
  end
  do_slicing = (do_slicing or "yes"):lower()

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local bus_kick  = nil
  local bus_snare = nil
  local bus_hats  = nil

  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(0, i)
    local _, name = r.GetTrackName(tr, "")
    local role = classify_role(name or "")
    if role then
      -- Slicing-FXChain auf dem Drum-Track
      if do_slicing == "yes" or do_slicing == "y" then
        local slice_rel = choose_slicing_chain(role)
        if slice_rel then
          local slice_path = chains_root(slice_rel)
          apply_rfxchain_to_track(tr, slice_path)
        end
      end

      -- Bus erzeugen + BusChain anwenden + Routing
      local bus
      if role == "kick" then
        if not bus_kick then
          bus_kick = ensure_bus_track("IDM Kick Bus")
          local bus_chain_key = choose_bus_chain("kick", intensity)
          if bus_chain_key then
            local bus_chain_path = chains_root(bus_chain_key)
            apply_rfxchain_to_track(bus_kick, bus_chain_path)
          end
        end
        bus = bus_kick
      elseif role == "snare" then
        if not bus_snare then
          bus_snare = ensure_bus_track("IDM Snare Bus")
          local bus_chain_key = choose_bus_chain("snare", intensity)
          if bus_chain_key then
            local bus_chain_path = chains_root(bus_chain_key)
            apply_rfxchain_to_track(bus_snare, bus_chain_path)
          end
        end
        bus = bus_snare
      elseif role == "hats" then
        if not bus_hats then
          bus_hats = ensure_bus_track("IDM Hats Bus")
          local bus_chain_key = choose_bus_chain("hats", intensity)
          if bus_chain_key then
            local bus_chain_path = chains_root(bus_chain_key)
            apply_rfxchain_to_track(bus_hats, bus_chain_path)
          end
        end
        bus = bus_hats
      end

      if bus then
        create_send(tr, bus)
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 IDM DrumSetup ("..intensity..")", -1)
  r.UpdateArrange()
end

main()
