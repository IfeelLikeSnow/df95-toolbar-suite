-- @description DF95: Reamp Hub (Routing + Tools, flexible Out/In)
-- @version 1.1
-- @author DF95
-- @about
--   ImGui-Hub für Reamping mit Palmer DACCAPO + Effektpedalen:
--   - Auswahl: Interface (PreSonus 1824c / Steinberg UR22mkII / Generic)
--   - Auswahl: Modus (Single Track oder Summe aus mehreren Tracks)
--   - Konfigurierbarer Hardware-Out (Paar) und Mono-Input für den Return
--   - Option: Sends als Pre-/Post-Fader, Dry-Master-Send für Summen-Bus deaktivieren
--   - Automatisches Anlegen von:
--       * REAMP_SEND_* Track-Routing (Hardware-Out)
--       * REAMP_RETURN_* Track (Record-Arm, Input-Monitoring)
--   - Buttons für SafetyCheck, Testimpuls, Latenz-Analyse und Test&Align-Wizard.

local r = reaper

local ctx = r.ImGui_CreateContext("DF95 Reamp Hub", 0)

local cur_interface = 0 -- 0=PreSonus, 1=UR22, 2=Generic
local cur_mode = 0      -- 0=Single, 1=Sum from selection
local send_mode = 0     -- 0=Post-Fader, 1=Pre-Fader
local disable_master_on_bus = true

-- Out-Pair Auswahl: 1/2, 3/4, 5/6, 7/8
local outpair_idx = 1   -- default 3/4
local outpair_labels = "Out 1/2\0Out 3/4\0Out 5/6\0Out 7/8\0"

-- Return-Input (Mono) Kanalnummer (1-basiert, wie in REAPERs Mono Input 1,2,...)
local return_input_chan = 1

-- ExtState helpers
local EXT_SECTION = "DF95_REAMP"

local function load_extstate()
  local v_iface = tonumber(r.GetExtState(EXT_SECTION, "IFACE") or "") or 0
  local v_mode  = tonumber(r.GetExtState(EXT_SECTION, "MODE") or "") or 0
  local v_sm    = tonumber(r.GetExtState(EXT_SECTION, "SENDMODE") or "") or 0
  local v_dm    = tonumber(r.GetExtState(EXT_SECTION, "DISABLE_MASTER_BUS") or "") or 1
  local v_op    = tonumber(r.GetExtState(EXT_SECTION, "OUTPAIR") or "") or 1
  local v_in    = tonumber(r.GetExtState(EXT_SECTION, "RETURN_IN") or "") or 1

  if v_iface >=0 and v_iface <=2 then cur_interface = v_iface end
  if v_mode >=0 and v_mode <=1 then cur_mode = v_mode end
  if v_sm >=0 and v_sm <=1 then send_mode = v_sm end
  disable_master_on_bus = (v_dm ~= 0)
  if v_op >=0 and v_op <=3 then outpair_idx = v_op end
  if v_in >=1 and v_in <=32 then return_input_chan = v_in end
end

local function save_extstate()
  r.SetExtState(EXT_SECTION, "IFACE", tostring(cur_interface), true)
  r.SetExtState(EXT_SECTION, "MODE", tostring(cur_mode), true)
  r.SetExtState(EXT_SECTION, "SENDMODE", tostring(send_mode), true)
  r.SetExtState(EXT_SECTION, "DISABLE_MASTER_BUS", disable_master_on_bus and "1" or "0", true)
  r.SetExtState(EXT_SECTION, "OUTPAIR", tostring(outpair_idx), true)
  r.SetExtState(EXT_SECTION, "RETURN_IN", tostring(return_input_chan), true)
end

load_extstate()

local function find_track_by_name_exact(name)
  local num = r.CountTracks(0)
  for i=0,num-1 do
    local tr = r.GetTrack(0,i)
    local ok, nm = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if ok and nm == name then return tr end
  end
  return nil
end

local function create_track_with_name(name, pos_index)
  r.InsertTrackAtIndex(pos_index, true)
  local tr = r.GetTrack(0, pos_index)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function outpair_idx_to_dstchan(idx)
  -- 0 -> Out 1/2 (0), 1 -> Out 3/4 (2), 2 -> 5/6 (4), 3 -> 7/8 (6)
  if idx == 0 then return 0 end
  if idx == 1 then return 2 end
  if idx == 2 then return 4 end
  if idx == 3 then return 6 end
  return 0
end

local function sendmode_val()
  -- REAPER I_SENDMODE: 0=post-fader, 3=pre-fader
  if send_mode == 1 then return 3 else return 0 end
end

local function launch_tool_script(rel_path)
  -- Versucht, ein anderes DF95-Script per dofile zu starten.
  local _, script_path = r.get_action_context()
  -- script_path zeigt auf DF95_Reamp_Hub_ImGui.lua
  local dir = script_path:match("(.+[\\/])")
  if not dir then return end
  local root = dir:gsub("[\\/]+$", "")
  local up = root:match("(.+[\\/])") or root
  local base = up .. "DF95" .. package.config:sub(1,1)
  local full = base .. rel_path
  local ok, err = pcall(dofile, full)
  if not ok then
    r.ShowMessageBox("Konnte Tool-Script nicht starten:\n"..full.."\n\nFehler: "..tostring(err), "DF95 Reamp Hub", 0)
  end
end

local function setup_reamp_routing()
  local sel_cnt = r.CountSelectedTracks(0)
  if sel_cnt == 0 then
    r.ShowMessageBox("Bitte wähle mindestens einen Track (Dry-Quelle) aus.", "DF95 Reamp Hub", 0)
    return
  end

  r.Undo_BeginBlock()

  -- Bestimme Send-Track
  local send_track = nil
  local description = ""

  if cur_mode == 0 or sel_cnt == 1 then
    send_track = r.GetSelectedTrack(0, 0)
    local ok, nm = r.GetSetMediaTrackInfo_String(send_track, "P_NAME", "", false)
    description = "Send-Track: " .. (ok and nm or "<unnamed>")
  else
    local last_sel = r.GetSelectedTrack(0, sel_cnt-1)
    local last_idx = r.GetMediaTrackInfo_Value(last_sel, "IP_TRACKNUMBER") - 1
    local bus_name = (cur_interface == 0) and "REAMP_SUM_1824C"
                  or (cur_interface == 1) and "REAMP_SUM_UR22"
                  or "REAMP_SUM_GENERIC"
    send_track = create_track_with_name(bus_name, last_idx+1)
    description = "Send-Track (Summe): " .. bus_name

    -- Optional Master-Send aus für Bus
    if disable_master_on_bus then
      r.SetMediaTrackInfo_Value(send_track, "B_MAINSEND", 0)
    end

    -- Sends von selektierten Tracks zum Bus
    for i=0, sel_cnt-1 do
      local src = r.GetSelectedTrack(0, i)
      if src ~= send_track then
        local send_idx = r.CreateTrackSend(src, send_track)
        r.SetTrackSendInfo_Value(src, 0, send_idx, "I_SRCCHAN", 0) -- 1/2
        r.SetTrackSendInfo_Value(src, 0, send_idx, "I_DSTCHAN", 0) -- 1/2
        r.SetTrackSendInfo_Value(src, 0, send_idx, "D_VOL", 1.0)
        r.SetTrackSendInfo_Value(src, 0, send_idx, "I_SENDMODE", sendmode_val())
      end
    end
  end

  -- Return-Track auswählen/erzeugen
  local ret_name = (cur_interface == 0) and "REAMP_RETURN_1824C_DACCAPO"
                or (cur_interface == 1) and "REAMP_RETURN_UR22_DACCAPO"
                or "REAMP_RETURN_GENERIC"
  local return_track = find_track_by_name_exact(ret_name)
  if not return_track then
    local num_tracks = r.CountTracks(0)
    return_track = create_track_with_name(ret_name, num_tracks)
  end

  -- Hardware-Out auf Send-Track
  if cur_interface == 0 or cur_interface == 2 then
    -- 1824c oder Generic: Out-Pair laut Auswahl
    local dstchan = outpair_idx_to_dstchan(outpair_idx)
    local hw_send_idx = r.CreateTrackSend(send_track, nil)
    r.SetTrackSendInfo_Value(send_track, 1, hw_send_idx, "I_DSTCHAN", dstchan)
    r.SetTrackSendInfo_Value(send_track, 1, hw_send_idx, "D_VOL", 1.0)
  elseif cur_interface == 1 then
    -- UR22mkII: Out 1/2, per Pan L nur linken Kanal nutzen
    local hw_send_idx = r.CreateTrackSend(send_track, nil)
    r.SetTrackSendInfo_Value(send_track, 1, hw_send_idx, "I_DSTCHAN", 0) -- 1/2
    r.SetTrackSendInfo_Value(send_track, 1, hw_send_idx, "D_VOL", 1.0)
    r.SetMediaTrackInfo_Value(send_track, "D_PAN", -1.0) -- nur L
  end

  -- Return-Track: Input/RecArm/Monitor
  if cur_interface == 0 or cur_interface == 2 then
    local rec_idx = math.max(1, math.min(32, return_input_chan))
    r.SetMediaTrackInfo_Value(return_track, "I_RECINPUT", rec_idx)
  elseif cur_interface == 1 then
    r.SetMediaTrackInfo_Value(return_track, "I_RECINPUT", 2) -- UR22: Input 2
  end

  r.SetMediaTrackInfo_Value(return_track, "I_RECARM", 1)
  r.SetMediaTrackInfo_Value(return_track, "I_RECMON", 1)

  r.Undo_EndBlock("DF95 Reamp Hub – Routing Setup", -1)

  save_extstate()

  local int_name = (cur_interface == 0) and "PreSonus 1824c" or ((cur_interface == 1) and "Steinberg UR22mkII" or "Generic")
  r.ShowMessageBox("Reamp-Routing erstellt.\n\nInterface: "..int_name.."\n"..description.."\nReturn-Track: "..ret_name.."\n\nBitte überprüfe im Interface-Control-Panel, dass:\n- der gewählte Hardware-Out wirklich auf den DACCAPO-Eingang geht\n- der gewählte Input mit der DI-Box/Pedal-Return verbunden ist.\n\nWICHTIG: Hardware-Out und -In dürfen nie denselben physikalischen Anschluss verwenden (Out 3 ≠ In 3 etc.).", "DF95 Reamp Hub", 0)
end

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 Reamp Hub", true)
  if visible then
    r.ImGui_TextWrapped(ctx, "Reamp-Hub für DACCAPO + Effektpedale. Richtet Send/Return-Routing für das gewählte Interface ein.")

    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "Interface:")
    local changed_iface
    changed_iface, cur_interface = r.ImGui_Combo(ctx, "##iface", cur_interface, "PreSonus Studio 1824c\0Steinberg UR22mkII\0Generic / Manuell\0")

    r.ImGui_Text(ctx, "Modus:")
    local changed_mode
    changed_mode, cur_mode = r.ImGui_Combo(ctx, "##mode", cur_mode, "Single Track (direkt)\0Summe aus selektierten Tracks\0")

    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "Routing-Optionen:")
    r.ImGui_Text(ctx, "Hardware-Out Paar:")
    local changed_out
    changed_out, outpair_idx = r.ImGui_Combo(ctx, "##outpair", outpair_idx, outpair_labels)

    r.ImGui_Text(ctx, "Return-Input (Mono-Kanalnummer, z.B. 1 = Mono Input 1):")
    local changed_in, new_in = r.ImGui_InputInt(ctx, "##returnin", return_input_chan)
    if changed_in then
      return_input_chan = math.max(1, math.min(32, new_in))
    end

    r.ImGui_Text(ctx, "Send-Modus:")
    local changed_sm
    changed_sm, send_mode = r.ImGui_Combo(ctx, "##sendmode", send_mode, "Post-Fader\0Pre-Fader\0")

    local changed_dm, dm_val = r.ImGui_Checkbox(ctx, "Master-Send auf Reamp-Summenbus deaktivieren", disable_master_on_bus)
    if changed_dm then
      disable_master_on_bus = dm_val
    end

    r.ImGui_Separator(ctx)
    if r.ImGui_Button(ctx, "Reamp-Routing für Auswahl erstellen") then
      setup_reamp_routing()
    end

    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx, "Tools:")

    if r.ImGui_Button(ctx, "Safety Check") then
      launch_tool_script("DF95_Reamp_SafetyCheck_ImGui.lua")
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Testimpuls erzeugen") then
      launch_tool_script("DF95_Reamp_TestImpulse_Generate.lua")
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, "Latenz Analysieren") then
      launch_tool_script("DF95_Reamp_Latency_Analyze_And_Align.lua")
    end
    if r.ImGui_Button(ctx, "Test & Align Wizard") then
      launch_tool_script("DF95_Reamp_TestAndAlign_Wizard.lua")
    end

    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx,
      "Hinweise:\n" ..
      "- Hardware-Out und -In dürfen nie denselben physikalischen Anschluss nutzen (Out 3 ≠ In 3 etc.).\n" ..
      "- Für UR22: Da nur Out 1/2 existiert, wird der Send-Track hart nach links gepannt, damit nur L den Reamp-Loop speist.\n" ..
      "- Für andere Interfaces 'Generic' wählen und Pair/Input passend einstellen.\n" ..
      "- Pre-Fader-Sends sind ideal, wenn du den Reamp-Pegel stabil halten willst, unabhängig vom Mix-Fader.")

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
