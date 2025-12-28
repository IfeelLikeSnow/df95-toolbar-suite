-- @description DF95: Reamp Safety Check (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Prüft typische Reamp-Fallstricke:
--   - REAMP_SEND_*-Tracks sollten NICHT aufnahmebewaffnet sein.
--   - REAMP_RETURN_*-Tracks sollten KEINE Hardware-Outs haben.
--   - Erinnerung, dass Hardware-Out und -In niemals denselben physikalischen Kanal nutzen sollten.

local r = reaper
local ctx = r.ImGui_CreateContext("DF95 Reamp Safety Check", 0)

local function collect_info()
  local info = {}
  local warnings = {}
  local num_tracks = r.CountTracks(0)
  for i = 0, num_tracks-1 do
    local tr = r.GetTrack(0, i)
    local ok, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if not ok then name = "" end
    local is_reamp_send = name:match("^REAMP_SEND")
    local is_reamp_ret  = name:match("^REAMP_RETURN")

    if is_reamp_send or is_reamp_ret then
      local armed = r.GetMediaTrackInfo_Value(tr, "I_RECARM") == 1
      local rec_in = r.GetMediaTrackInfo_Value(tr, "I_RECINPUT")
      local hw_sends = {}
      local num_hw = r.GetTrackNumSends(tr, 1) -- 1 = hardware out
      for s = 0, num_hw-1 do
        local dest = r.GetTrackSendInfo_Value(tr, 1, s, "I_DSTCHAN")
        table.insert(hw_sends, dest)
      end

      table.insert(info, {
        name = name,
        is_send = is_reamp_send,
        is_ret  = is_reamp_ret,
        armed = armed,
        rec_in = rec_in,
        hw = hw_sends,
      })

      if is_reamp_send and armed then
        table.insert(warnings, "REAMP_SEND-Track '"..name.."' ist aufnahmebewaffnet. Normalerweise sollte nur der REAMP_RETURN-Track aufnehmen.")
      end
      if is_reamp_ret and #hw_sends > 0 then
        table.insert(warnings, "REAMP_RETURN-Track '"..name.."' hat Hardware-Outs gesetzt. Rückwege sollten in der Regel keinen Hardware-Out haben.")
      end
    end
  end

  return info, warnings
end

local info, warnings = collect_info()

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 Reamp Safety Check", true)
  if visible then
    r.ImGui_TextWrapped(ctx, "Überprüft REAMP_SEND_*/REAMP_RETURN_* Tracks auf typische Routing-Fehler.")
    r.ImGui_Separator(ctx)

    if r.ImGui_Button(ctx, "Neu scannen") then
      info, warnings = collect_info()
    end

    r.ImGui_Separator(ctx)

    if #warnings == 0 then
      r.ImGui_Text(ctx, "✔ Keine offensichtlichen Reamp-Probleme gefunden.")
    else
      r.ImGui_Text(ctx, "⚠ Warnungen:")
      for _, w in ipairs(warnings) do
        r.ImGui_BulletText(ctx, w)
      end
    end

    r.ImGui_Separator(ctx)
    r.ImGui_Text(ctx, "Reamp-Track-Übersicht:")
    for _, t in ipairs(info) do
      local role = t.is_send and "SEND" or (t.is_ret and "RETURN" or "?")
      local armed = t.armed and "REC_ARM=ON" or "REC_ARM=off"
      local hw_desc = (#t.hw == 0) and "keine HW-Outs" or ("HW-Out Slots: " .. table.concat(t.hw, ","))
      r.ImGui_BulletText(ctx, string.format("%s (%s) – %s, RecIn=%d, %s", t.name, role, armed, t.rec_in or -1, hw_desc))
    end

    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx,
      "WICHTIG:\n" ..
      "- Hardware-Out (z.B. Out 3) und Hardware-In (z.B. In 3) dürfen nie denselben physikalischen Anschluss belegen.\n" ..
      "- Empfohlen: REAMP_SEND → Out 3/4, REAMP_RETURN → In 1/2 oder andere getrennte Kanäle.\n" ..
      "- Stelle sicher, dass dein Interface-Routing dies im Control Panel respektiert.")

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
