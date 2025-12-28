
-- @description MetaCore Drum-Synth + MIDI + Kick Bus Setup (IDM)
-- @author You + Reaper DAW Ultimate Assistant
-- @version 1.0
-- @changelog
--   Initial version: Auswahl aller Drum-/Kick-/Percussion-Synths aus DF95 MetaCore VSTi,
--   erstellt einen separaten MIDI-Track zur Ansteuerung und baut Kick FX / Coloring / Master Bus.
-- @about
--   Voraussetzungen:
--     - DF95_MetaCore_VST_All_Modular_v15_WITH_ALL installiert unter:
--       <REAPER Resource Path>/Scripts/IFLS/DF95/
--     - DF95_SynthMetaCore_v2_7.lua im selben Ordner
--     - DF95_MetaUnified_Core.lua vorhanden (wird von diesem Script geladen)
--
--   Workflow:
--     1. Spur auswählen (diese wird der Drum-Synth/Kick-Track)
--     2. Script ausführen
--     3. Drum-Synth aus Liste wählen (z.B. ChowKick, Drumatic3, BucketPops, Bong, adc Clap, ...)
--     4. Script:
--        • fügt den gewählten Drum-Synth als FX auf der Spur ein (falls noch nicht vorhanden)
--        • erstellt einen separaten MIDI-Track davor (MIDI-All, Rec-Arm, Monitoring an)
--        • legt Kick FX Bus, Kick Color Bus, Kick Master Bus dahinter an
--        • baut Routing: MIDI → Drum-Synth → FX Bus → Color Bus → Kick Master → Master
--        • füllt FX/Color/Master-Busse mit passenden IDM-orientierten Chains

local r = reaper

----------------------------------------------------------------------
-- MetaCore laden (VST_All_Flat)
----------------------------------------------------------------------
local function load_meta_core_flat()
  local resource = r.GetResourcePath()
  local path = resource .. "/Scripts/IFLS/DF95/DF95_MetaCore_VST_All_Flat.lua"

  local ok, MetaCore = pcall(dofile, path)
  if not ok or type(MetaCore) ~= "table" then
    r.ShowMessageBox(
      "Konnte DF95_MetaCore_VST_All_Flat.lua nicht laden:\n" ..
      path ..
      "\n\nStelle sicher, dass DF95_MetaCore_VST_All_Modular_v15_WITH_ALL korrekt entpackt ist.",
      "MetaCore Fehler",
      0
    )
    return nil
  end

  if MetaCore._build_indices then
    MetaCore._build_indices()
  end

  -- Fallback: is_drum_synth, falls nicht schon vorhanden
  if not MetaCore.is_drum_synth then
    function MetaCore.is_drum_synth(def)
      if not def or type(def) ~= "table" then return false end
      local t = (def.type or ""):lower()
      if t:find("drum") or t:find("kick") or t:find("clap") then
        return true
      end
      if def.roles and type(def.roles) == "table" then
        for _, r in ipairs(def.roles) do
          local rl = r:lower()
          if rl == "drums"
             or rl == "kick"
             or rl == "bass-drum"
             or rl == "percussion"
             or rl == "clap"
          then
            return true
          end
        end
      end
      return false
    end
  end

  return MetaCore
end

----------------------------------------------------------------------
-- MetaCore-Helper
----------------------------------------------------------------------
local function mc_pick(MC, opts)
  if not (MC and MC.search) then return nil end
  local results = MC.search(opts or {})
  if results and results[1] and results[1].def then
    return results[1].def
  end
  return nil
end

local function mc_pick_by_role(MC, roles)
  if not MC or not MC.by_role then return nil end
  roles = roles or {}
  for _, role in ipairs(roles) do
    local lst = MC.by_role[role]
    if lst and lst[1] then
      return lst[1]
    end
  end
  return nil
end

-- FX-Name zu MetaCore-Def matchen (für vorhandene Instrumente)
local function find_vsti_def_for_fxname(MC, fxname)
  if not (MC and MC.vsti and fxname) then return nil end
  local fx_l = fxname:lower()
  local fx_clean = fx_l:gsub("%b()", "")
  fx_clean = fx_clean:gsub("%s+", " "):match("^%s*(.-)%s*$")

  for id, def in pairs(MC.vsti) do
    if type(def) == "table" and def.display then
      local disp = def.display:lower()
      disp = disp:gsub("%b()", "")
      disp = disp:gsub("%s+", " "):match("^%s*(.-)%s*$")
      if disp ~= "" and fx_clean:find(disp, 1, true) then
        return def
      end
    end
  end
  return nil
end

----------------------------------------------------------------------
-- Drum-Synth-Liste aus MetaCore.vsti
----------------------------------------------------------------------
local function get_drum_synth_list(MC)
  local list = {}
  if not MC or not MC.vsti then return list end

  for id, def in pairs(MC.vsti) do
    if type(def) == "table" and def.id and (MC.is_drum_synth(def) == true) then
      list[#list+1] = def
    end
  end

  table.sort(list, function(a,b)
    local da = (a.display or a.id or ""):lower()
    local db = (b.display or b.id or ""):lower()
    return da < db
  end)

  return list
end

----------------------------------------------------------------------
-- Drum-Synth-Auswahl-UI
----------------------------------------------------------------------
local function choose_drum_synth(MC, list)
  if #list == 0 then
    r.ShowMessageBox(
      "In MetaCore wurden keine Drum-/Kick-/Percussion-Synths gefunden.\n" ..
      "Bitte prüfe DF95_MetaCore_VST_All_vsti.lua.",
      "MetaCore Drum-Synth Setup",
      0
    )
    return nil
  end

  r.ClearConsole()
  r.ShowConsoleMsg("DF95 MetaCore – Drum-Synth Auswahl\n")
  r.ShowConsoleMsg("Gefundene Drum-/Kick-/Percussion-Instrumente:\n\n")
  for i, def in ipairs(list) do
    local line = string.format(
      "%2d) %s",
      i,
      (def.display or def.id or "?")
    )
    if def.vendor and def.vendor ~= "" then
      line = line .. "  [" .. def.vendor .. "]"
    end
    if def.type then
      line = line .. "  {type=" .. def.type .. "}"
    end
    line = line .. "\n"
    r.ShowConsoleMsg(line)
  end
  r.ShowConsoleMsg("\nBitte Index eingeben und mit OK bestätigen.\n")

  local title = "MetaCore Drum-Synth wählen"
  local prompt = "Index (1-" .. tostring(#list) .. ")"
  local ok, ret = r.GetUserInputs(title, 1, prompt, "1")
  if not ok then return nil end

  local idx = tonumber(ret)
  if not idx or idx < 1 or idx > #list then
    r.ShowMessageBox("Ungültiger Index: " .. tostring(ret), "MetaCore Drum-Synth Setup", 0)
    return nil
  end

  return list[idx]
end

----------------------------------------------------------------------
-- Bestehenden Drum-Synth auf Spur finden
----------------------------------------------------------------------
local function find_existing_drum_synth_on_track(MC, tr)
  local fx_count = r.TrackFX_GetCount(tr)
  for i = 0, fx_count-1 do
    local ok, fxname = r.TrackFX_GetFXName(tr, i, "")
    if ok then
      local def = find_vsti_def_for_fxname(MC, fxname)
      if def and MC.is_drum_synth(def) then
        return def, i
      end
    end
  end
  return nil, -1
end

----------------------------------------------------------------------
-- Drum-Synth gemäß Auswahl sicherstellen
----------------------------------------------------------------------
local function ensure_drum_synth_on_track(MC, tr, drum_def)
  local existing_def, existing_idx = find_existing_drum_synth_on_track(MC, tr)
  if existing_def and existing_idx >= 0 then
    return existing_def, existing_idx
  end

  local name = drum_def.display or drum_def.name or drum_def.id
  if not name or name == "" then
    return nil, -1
  end

  local idx = r.TrackFX_AddByName(tr, name, false, -1)
  if idx < 0 then
    idx = r.TrackFX_AddByName(tr, drum_def.id, false, -1)
  end

  if idx < 0 then
    r.ShowMessageBox(
      "Konnte den Drum-Synth '" .. (name or drum_def.id or "?") .. "' nicht einfügen.\n" ..
      "Bitte prüfe, ob das Plugin installiert und in REAPER gescannt ist.",
      "MetaCore Drum-Synth Setup",
      0
    )
    return nil, -1
  end

  return drum_def, idx
end

----------------------------------------------------------------------
-- MIDI-Track erstellen, der den Drum-Synth steuert
----------------------------------------------------------------------
local function create_midi_track_for_instrument(instr_track, instr_def)
  local proj = 0
  local tr_num = math.floor(r.GetMediaTrackInfo_Value(instr_track, "IP_TRACKNUMBER"))
  local insert_idx = tr_num - 1 -- vor Instrument einfügen

  r.InsertTrackInProject(insert_idx, 1)
  local midi_tr = r.GetTrack(proj, insert_idx)

  local name = "[DRUM MIDI]"
  if instr_def and instr_def.display then
    name = "[MIDI → " .. instr_def.display .. "]"
  end
  r.GetSetMediaTrackInfo_String(midi_tr, "P_NAME", name, true)

  -- Input: MIDI All Channels
  r.SetMediaTrackInfo_Value(midi_tr, "I_RECINPUT", 4096) -- 4096 = MIDI alle Kanäle
  r.SetMediaTrackInfo_Value(midi_tr, "I_RECMODE", 0)     -- Record: input
  r.SetMediaTrackInfo_Value(midi_tr, "I_RECARM", 1)      -- Rec-Arm ON
  r.SetMediaTrackInfo_Value(midi_tr, "I_RECMON", 1)      -- Monitoring ON

  -- Send: nur MIDI zum Instrument-Track
  local send_idx = r.CreateTrackSend(midi_tr, instr_track)
  -- Audio aus
  r.SetTrackSendInfo_Value(midi_tr, 0, send_idx, "I_SRCCHAN", -1)
  r.SetTrackSendInfo_Value(midi_tr, 0, send_idx, "I_DSTCHAN", 0)
  -- MIDI: alle Kanäle
  r.SetTrackSendInfo_Value(midi_tr, 0, send_idx, "I_MIDIFLAGS", 0)

  return midi_tr
end

----------------------------------------------------------------------
-- Bus-Erzeugung & Routing
----------------------------------------------------------------------
local function create_bus_after(track, name)
  local proj = 0
  local idx = math.floor(r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))
  r.InsertTrackInProject(idx, 1)
  local bus = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(bus, "P_NAME", name, true)
  return bus
end

local function clear_master_send(track)
  r.SetMediaTrackInfo_Value(track, "B_MAINSEND", 0)
end

local function set_master_send_on(track, on)
  r.SetMediaTrackInfo_Value(track, "B_MAINSEND", on and 1 or 0)
end

local function create_send(src, dest)
  return r.CreateTrackSend(src, dest)
end

----------------------------------------------------------------------
-- Chains: Kick FX / Coloring / Master
----------------------------------------------------------------------
local function build_kick_fx_bus_chain(MC)
  local chain = {}

  -- Transient / Punch
  local trans = mc_pick_by_role(MC, {"Transient","Drums","Shaper"})
             or mc_pick(MC, { query = "transperc", roles = {"Transient"} })
  if trans then chain[#chain+1] = trans end

  -- Glitch / Distortion / Chaos
  local glitch = mc_pick(MC, { query = "glitch", roles = {"Glitch","Rhythmic"} })
              or mc_pick(MC, { query = "breadslicer" })
              or mc_pick(MC, { query = "tantra", roles = {"Rhythmic"} })
  if glitch then chain[#chain+1] = glitch end

  local dist = mc_pick_by_role(MC, {"Distortion","Drive","LoFi"})
            or mc_pick(MC, { query = "fire", roles = {"Distortion"} })
            or mc_pick(MC, { query = "crusher" })
  if dist then chain[#chain+1] = dist end

  -- Optional kurzer Raum
  local space = mc_pick(MC, { query = "room", roles = {"Reverb","Space"} })
             or mc_pick(MC, { query = "reaverbate (cockos)" })
  if space then chain[#chain+1] = space end

  return chain
end

local function build_kick_coloring_bus_chain(MC)
  local chain = {}

  local eq = mc_pick_by_role(MC, {"Tone","CleanEQ"})
         or mc_pick(MC, { query = "reaeq (cockos)", type = "eq" })
         or mc_pick(MC, { query = "teote" })
  if eq then chain[#chain+1] = eq end

  local sat = mc_pick_by_role(MC, {"Saturation","Color","Tape","Console"})
          or mc_pick(MC, { query = "tape" })
          or mc_pick(MC, { query = "oven" })
  if sat then chain[#chain+1] = sat end

  local bass = mc_pick_by_role(MC, {"Bass","LowEnd","Enhancer"})
           or mc_pick(MC, { query = "bass mint" })
  if bass then chain[#chain+1] = bass end

  return chain
end

local function build_kick_master_bus_chain(MC)
  local chain = {}

  local comp = mc_pick_by_role(MC, {"Bus","Glue","BusCompressor"})
            or mc_pick(MC, { query = "mu", roles = {"Vari-Mu"} })
  if comp then chain[#chain+1] = comp end

  local lim = mc_pick_by_role(MC, {"Limiter","TruePeak","Safety"})
          or mc_pick(MC, { query = "limiter", type = "limiter" })
  if lim then chain[#chain+1] = lim end

  local meter = mc_pick_by_role(MC, {"Meter","Loudness"})
            or mc_pick(MC, { query = "youlean", roles = {"Meter"} })
  if meter then chain[#chain+1] = meter end

  return chain
end

local function apply_chain_to_track(MC, track, chain_defs)
  for _, def in ipairs(chain_defs or {}) do
    local name = def.display or def.name or def.id
    if name and name ~= "" then
      r.TrackFX_AddByName(track, name, false, -1)
    end
  end
end

----------------------------------------------------------------------
-- MAIN
----------------------------------------------------------------------
local function main()
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox(
      "Bitte zuerst eine Spur auswählen (diese wird der Drum-Synth/Kick-Track).",
      "MetaCore Drum-Synth + Kick Bus Setup",
      0
    )
    return
  end

  local MC, SynthCore = load_meta_core_flat()
  if not MC then return end

  local drum_list = get_drum_synth_list(MC)
  local chosen_def = choose_drum_synth(MC, drum_list)
  if not chosen_def then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local _, old_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if not old_name or old_name == "" then
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", "[DRUM SYNTH]", true)
  end

  local instr_def, fx_idx = ensure_drum_synth_on_track(MC, tr, chosen_def)
  if not instr_def then
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock("MetaCore Drum-Synth + Kick Bus Setup (abgebrochen)", -1)
    return
  end

  local midi_tr = create_midi_track_for_instrument(tr, instr_def)

  -- Kick-Bus-Struktur hinter dem Instrument-Track
  local bus_fx     = create_bus_after(tr, "[KICK FX BUS]")
  local bus_color  = create_bus_after(bus_fx, "[KICK COLOR BUS]")
  local bus_master = create_bus_after(bus_color, "[KICK MASTER BUS]")

  clear_master_send(tr)
  clear_master_send(bus_fx)
  clear_master_send(bus_color)
  set_master_send_on(bus_master, true)

  create_send(tr,       bus_fx)
  create_send(bus_fx,   bus_color)
  create_send(bus_color,bus_master)

  local chain_fx     = build_kick_fx_bus_chain(MC)
  local chain_color  = build_kick_coloring_bus_chain(MC)
  local chain_master = build_kick_master_bus_chain(MC)

  apply_chain_to_track(MC, bus_fx,     chain_fx)
  apply_chain_to_track(MC, bus_color,  chain_color)
  apply_chain_to_track(MC, bus_master, chain_master)

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock("MetaCore Drum-Synth + Kick Bus Setup (" .. (instr_def.display or instr_def.id or "?") .. ")", -1)
end

main()
