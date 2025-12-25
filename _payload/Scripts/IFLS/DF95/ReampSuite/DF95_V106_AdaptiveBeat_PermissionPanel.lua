-- @description DF95_V106_AdaptiveBeat_PermissionPanel
-- @version 1.0
-- @author DF95
-- @about
--   Adaptive Beat Permission Panel für das DF95 Artist+Style / Euclid / Adaptive Sample System.
--
--   Dieses Script:
--     * liest die von V105 erzeugten Adaptive-Sample-Daten (DF95_ADAPTIVE/*),
--     * zeigt dir an, wie viele Kicks/Snares/Hats/Perc/Other vorhanden sind,
--     * lässt dich festlegen, ob die Engine
--         - fehlende Elemente rekonstruieren darf (Kick/Snare/Hat),
--         - virtuelle Duplikate (Varianten) verwenden darf,
--       oder nur mit dem vorhandenen Material arbeiten soll,
--     * speichert diese Entscheidungen in DF95_ADAPTIVE_CONFIG/*,
--     * bietet Buttons, um anschließend V102 (Artist+Style BeatEngine) oder
--       V104 (Euclid Multi-Lane) zu starten.
--
--   WICHTIG:
--     - V106 baut bewusst NICHT ungefragt komplette Beats,
--       sondern holt explizit deine Zustimmung über das Panel ein.
--     - V102/V104 werden aktuell noch nicht im Detail an `DF95_ADAPTIVE_CONFIG`
--       angepasst, aber das Config-Layer ist vorbereitet, damit spätere Versionen
--       (V107+) diese Policies auswerten können.
--

local r = reaper
local ImGui = r.ImGui
if not ImGui then
  r.ShowMessageBox("ReaImGui ist nicht verfügbar. Bitte Extension installieren.", "DF95 V106", 0)
  return
end

local ctx = ImGui.CreateContext('DF95 V106 Adaptive Beat Permission Panel')

------------------------------------------------------------
-- ExtState Helpers
------------------------------------------------------------

local ADAPTIVE_SECTION = "DF95_ADAPTIVE"
local CONFIG_SECTION   = "DF95_ADAPTIVE_CONFIG"

local function get_ext_str(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if not v or v == "" then return default end
  return v
end

local function get_ext_num(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  local n = tonumber(v)
  if not n then return default end
  return n
end

local function set_ext(section, key, val)
  r.SetProjExtState(0, section, key, tostring(val or ""))
end

local function get_ext_bool(section, key, default)
  local _, v = r.GetProjExtState(0, section, key)
  if v == "1" then return true end
  if v == "0" then return false end
  return default
end

------------------------------------------------------------
-- Read Adaptive Sample Info (from V105)
------------------------------------------------------------

local function read_adaptive_info()
  local info = {}

  info.kick_count  = get_ext_num(ADAPTIVE_SECTION, "KICK_REAL_COUNT", 0)
  info.snare_count = get_ext_num(ADAPTIVE_SECTION, "SNARE_REAL_COUNT", 0)
  info.hat_count   = get_ext_num(ADAPTIVE_SECTION, "HAT_REAL_COUNT", 0)
  info.perc_count  = get_ext_num(ADAPTIVE_SECTION, "PERC_REAL_COUNT", 0)
  info.other_count = get_ext_num(ADAPTIVE_SECTION, "OTHER_COUNT", 0)

  info.kick_fb  = get_ext_str(ADAPTIVE_SECTION, "KICK_FALLBACK", "")
  info.snare_fb = get_ext_str(ADAPTIVE_SECTION, "SNARE_FALLBACK", "")
  info.hat_fb   = get_ext_str(ADAPTIVE_SECTION, "HAT_FALLBACK", "")
  info.perc_fb  = get_ext_str(ADAPTIVE_SECTION, "PERC_FALLBACK", "")

  info.kick_virt  = get_ext_num(ADAPTIVE_SECTION, "KICK_VIRTUAL_COUNT", 0)
  info.snare_virt = get_ext_num(ADAPTIVE_SECTION, "SNARE_VIRTUAL_COUNT", 0)
  info.hat_virt   = get_ext_num(ADAPTIVE_SECTION, "HAT_VIRTUAL_COUNT", 0)
  info.perc_virt  = get_ext_num(ADAPTIVE_SECTION, "PERC_VIRTUAL_COUNT", 0)

  local has_any = (info.kick_count + info.snare_count + info.hat_count + info.perc_count + info.other_count) > 0
  info.valid = has_any

  return info
end

------------------------------------------------------------
-- Read / Write Policy Config
------------------------------------------------------------

local policy = {
  allow_reconstruct_kick  = get_ext_bool(CONFIG_SECTION, "ALLOW_RECONSTRUCT_KICK", false),
  allow_reconstruct_snare = get_ext_bool(CONFIG_SECTION, "ALLOW_RECONSTRUCT_SNARE", false),
  allow_reconstruct_hat   = get_ext_bool(CONFIG_SECTION, "ALLOW_RECONSTRUCT_HAT", false),
  allow_virtual_dupes     = get_ext_bool(CONFIG_SECTION, "ALLOW_VIRTUAL_DUPES", false),
  prefer_minimal_beat     = get_ext_bool(CONFIG_SECTION, "PREFER_MINIMAL_BEAT", true),
  prefer_full_beat        = get_ext_bool(CONFIG_SECTION, "PREFER_FULL_BEAT", false),
}

local function save_policy()
  set_ext(CONFIG_SECTION, "ALLOW_RECONSTRUCT_KICK", policy.allow_reconstruct_kick and "1" or "0")
  set_ext(CONFIG_SECTION, "ALLOW_RECONSTRUCT_SNARE", policy.allow_reconstruct_snare and "1" or "0")
  set_ext(CONFIG_SECTION, "ALLOW_RECONSTRUCT_HAT", policy.allow_reconstruct_hat and "1" or "0")
  set_ext(CONFIG_SECTION, "ALLOW_VIRTUAL_DUPES", policy.allow_virtual_dupes and "1" or "0")
  set_ext(CONFIG_SECTION, "PREFER_MINIMAL_BEAT", policy.prefer_minimal_beat and "1" or "0")
  set_ext(CONFIG_SECTION, "PREFER_FULL_BEAT", policy.prefer_full_beat and "1" or "0")
end

------------------------------------------------------------
-- Helpers: Run Child Scripts (V102 / V104)
------------------------------------------------------------

local function get_script_dir()
  local info = debug.getinfo(1, "S")
  local script_path = info.source:match("^@(.+)$")
  return script_path:match("^(.*[\\/])") or ""
end

local function run_child_script(name, title)
  local base_dir = get_script_dir()
  local path = base_dir .. name
  local f = io.open(path, "r")
  if not f then
    r.ShowMessageBox("Konnte Script nicht finden:\n" .. path, title or "DF95 V106", 0)
    return
  end
  f:close()
  dofile(path)
end

------------------------------------------------------------
-- Main ImGui Loop
------------------------------------------------------------

local function loop()
  ImGui.SetNextWindowSize(ctx, 640, 520, ImGui.Cond_FirstUseEver())
  local visible, open = ImGui.Begin(ctx, 'DF95 V106 Adaptive Beat Permission Panel', true)
  if visible then
    local info = read_adaptive_info()

    if not info.valid then
      ImGui.TextColored(ctx, 1, 0.3, 0.3, 1, "Hinweis: Noch keine Adaptive Sample Infos gefunden (DF95_ADAPTIVE).")
      ImGui.Text(ctx, "Bitte zuerst:")
      ImGui.BulletText(ctx, "Slices/Samples selektieren (z.B. Fieldrec-Kit).")
      ImGui.BulletText(ctx, "DF95_V105_AdaptiveSampleEngine_FieldrecKit ausführen.")
      ImGui.Separator(ctx)
    else
      ImGui.Text(ctx, "Adaptive Sample Pool (aus V105)")
      if ImGui.BeginTable(ctx, "adaptive_table", 4, ImGui.TableFlags_Borders() | ImGui.TableFlags_RowBg()) then
        ImGui.TableSetupColumn(ctx, "Kategorie")
        ImGui.TableSetupColumn(ctx, "Real Count")
        ImGui.TableSetupColumn(ctx, "Fallback")
        ImGui.TableSetupColumn(ctx, "Virtuelle Duplikate")
        ImGui.TableHeadersRow(ctx)

        local function row(label, real, fb, virt)
          ImGui.TableNextRow(ctx)
          ImGui.TableSetColumnIndex(ctx, 0); ImGui.Text(ctx, label)
          ImGui.TableSetColumnIndex(ctx, 1); ImGui.Text(ctx, tostring(real))
          ImGui.TableSetColumnIndex(ctx, 2); ImGui.Text(ctx, fb ~= "" and fb or "-")
          ImGui.TableSetColumnIndex(ctx, 3); ImGui.Text(ctx, tostring(virt))
        end

        row("KICK",  info.kick_count,  info.kick_fb,  info.kick_virt)
        row("SNARE", info.snare_count, info.snare_fb, info.snare_virt)
        row("HAT",   info.hat_count,   info.hat_fb,   info.hat_virt)
        row("PERC",  info.perc_count,  info.perc_fb,  info.perc_virt)

        ImGui.EndTable(ctx)
      end

      ImGui.Text(ctx, "OTHER-Elemente (z.B. FX, Toms, Tonal Perc): " .. tostring(info.other_count))
      ImGui.Separator(ctx)
    end

    ImGui.Text(ctx, "Permission / Policy: Was darf die BeatEngine tun?")
    local changed

    changed, policy.allow_reconstruct_kick = ImGui.Checkbox(ctx, "Kick rekonstruieren, wenn keine/zu wenige Kicks vorhanden sind", policy.allow_reconstruct_kick)
    changed, policy.allow_reconstruct_snare = ImGui.Checkbox(ctx, "Snare rekonstruieren (z.B. aus Perc/Hat/FX)", policy.allow_reconstruct_snare)
    changed, policy.allow_reconstruct_hat = ImGui.Checkbox(ctx, "Hat rekonstruieren (z.B. aus Perc/Noise)", policy.allow_reconstruct_hat)
    changed, policy.allow_virtual_dupes = ImGui.Checkbox(ctx, "Virtuelle Duplikate verwenden (Microvarianten aus wenigen Slices)", policy.allow_virtual_dupes)

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Bevorzugter Beat-Typ (für künftige Engine-Logik):")
    changed, policy.prefer_minimal_beat = ImGui.RadioButton(ctx, "Minimal (nur vorhandenes Material, so wenig Rekonstruktion wie möglich)", policy.prefer_minimal_beat)
    if changed and policy.prefer_minimal_beat then
      policy.prefer_full_beat = false
    end
    changed, policy.prefer_full_beat = ImGui.RadioButton(ctx, "Voll (kann rekonstruktieren, um kompletten Artist-Beat zu ermöglichen)", policy.prefer_full_beat)
    if changed and policy.prefer_full_beat then
      policy.prefer_minimal_beat = false
    end

    if ImGui.Button(ctx, "Policy speichern (ohne Beat erzeugen)") then
      save_policy()
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Aktionen (explizit, nichts passiert automatisch):")

    if ImGui.Button(ctx, "Minimalen Artist-Beat (V102) erzeugen") then
      policy.prefer_minimal_beat = true
      policy.prefer_full_beat    = false
      save_policy()
      run_child_script("DF95_V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist.lua", "DF95 V106 / V102")
    end

    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Vollständigen Artist-Beat (V102) zulassen & erzeugen") then
      policy.prefer_minimal_beat = false
      policy.prefer_full_beat    = true
      policy.allow_reconstruct_kick  = true
      policy.allow_reconstruct_snare = true
      policy.allow_reconstruct_hat   = true
      policy.allow_virtual_dupes     = true
      save_policy()
      run_child_script("DF95_V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist.lua", "DF95 V106 / V102")
    end

    if ImGui.Button(ctx, "Nur Euclid Multi-Lane Pattern (V104) öffnen") then
      run_child_script("DF95_V104_ArtistStyle_EuclidControlPanel_MultiLane.lua", "DF95 V106 / V104")
    end

    ImGui.Separator(ctx)
    ImGui.TextWrapped(ctx,
      "Hinweis: V106 erzeugt selbst noch keine Audio-Duplikate oder RS5k-Zuweisungen. " ..
      "Es definiert aber klar, was die Engine in Zukunft tun DARF (Rekonstruktion, " ..
      "Duplikate, minimal vs. voll). Dadurch bleiben alle Schritte transparent und " ..
      "opt-in, nichts passiert ohne deine Zustimmung.")

    ImGui.End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ImGui.DestroyContext(ctx)
  end
end

r.defer(loop)
