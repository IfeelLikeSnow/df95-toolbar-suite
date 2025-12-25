-- @description DF95 AI Artist FXBrain (ImGui)
-- @version 1.1
-- @author DF95
-- @about
--   Liest ein AI-Result-JSON (z.B. aus AIWorker), extrahiert Artist-Vorschläge
--   und zeigt passende Artist-/IDM-FXChains aus FXChains/DF95 an.
--
--   V1.1:
--     * JSON-Pfad manuell eingeben
--     * Artist-Candidates (key + Score) anzeigen
--     * FXChains per Verzeichnis-Scan finden:
--         FXChains/DF95/Coloring/Artists/<ArtistFolder>/*.rfxchain
--     * Apply-Button:
--         - schreibt den absoluten FXChain-Pfad in ExtState:
--           section="DF95_AI_ArtistFXBrain", key="fxchain_path"
--         - zeigt dir an, welcher Pfad gesetzt wurde
--         - von dort kannst du ein zweites Script starten,
--           das diesen Pfad nimmt und die Chain auf selektierte Tracks lädt.

local r = reaper

------------------------------------------------------------
-- ImGui Setup
------------------------------------------------------------

if not r.ImGui_CreateContext then
  r.ShowMessageBox("Dieses Script benötigt ReaImGui (ReaScript-API).", "DF95 AI Artist FXBrain", 0)
  return
end

local ctx = r.ImGui_CreateContext("DF95 AI Artist FXBrain")
local FONT = r.ImGui_CreateFont("sans-serif", 14)
r.ImGui_AttachFont(ctx, FONT)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 AI Artist FXBrain", 0)
end

local function trim(s)
  if not s then return "" end
  return (s:gsub("^%s+",""):gsub("%s+$",""))
end


------------------------------------------------------------
-- FullAuto-Anbindung (Option 3)
-- Hier kann optional eine FullAuto-Action aus dem DF95-Repo angebunden werden.
-- Idee:
--   * In Reaper: "DF95_AI_FXChain_FullAuto_From_AIResult.lua" installieren
--   * In der Actions-Liste dessen Command-ID kopieren
--   * Unten in FULLAUTO_ACTION_COMMAND_ID eintragen
------------------------------------------------------------

local FULLAUTO_ACTION_COMMAND_ID = ""  -- z.B. "_RS1234567890abcdef"


------------------------------------------------------------
-- Index/Enricher-Anbindung
-- Hier können optional Actions für:
--   * DF95_FXChains_Index_Builder.lua
--   * DF95_FXChains_Index_Enricher.lua
-- hinterlegt werden, damit sie direkt aus dem FXBrain-UI
-- gestartet werden können.
------------------------------------------------------------

local INDEX_BUILDER_ACTION_COMMAND_ID  = ""  -- z.B. "_RSxxxxxxxxxxxxxxxxx"
local INDEX_ENRICHER_ACTION_COMMAND_ID = ""  -- z.B. "_RSyyyyyyyyyyyyyyyyy"

local function trigger_index_builder()
  if not INDEX_BUILDER_ACTION_COMMAND_ID or INDEX_BUILDER_ACTION_COMMAND_ID == "" then
    msg("INDEX_BUILDER_ACTION_COMMAND_ID ist nicht gesetzt.\n\nBitte im Script 'DF95 AI Artist FXBrain (ImGui)' oben im Abschnitt 'Index/Enricher-Anbindung' die Command-ID deiner 'DF95_FXChains_Index_Builder.lua'-Action eintragen.")
    return
  end
  local cmd = r.NamedCommandLookup(INDEX_BUILDER_ACTION_COMMAND_ID)
  if cmd == 0 then
    msg("Konnte Index-Builder-Action nicht auflösen.\n\nGeprüft wurde:\n" .. tostring(INDEX_BUILDER_ACTION_COMMAND_ID) .. "\n\nBitte in der Actions-Liste nach 'DF95_FXChains_Index_Builder.lua' suchen und die Command-ID neu eintragen.")
    return
  end
  r.Main_OnCommand(cmd, 0)
end

local function trigger_index_enricher()
  if not INDEX_ENRICHER_ACTION_COMMAND_ID or INDEX_ENRICHER_ACTION_COMMAND_ID == "" then
    msg("INDEX_ENRICHER_ACTION_COMMAND_ID ist nicht gesetzt.\n\nBitte im Script 'DF95 AI Artist FXBrain (ImGui)' oben im Abschnitt 'Index/Enricher-Anbindung' die Command-ID deiner 'DF95_FXChains_Index_Enricher.lua'-Action eintragen.")
    return
  end
  local cmd = r.NamedCommandLookup(INDEX_ENRICHER_ACTION_COMMAND_ID)
  if cmd == 0 then
    msg("Konnte Index-Enricher-Action nicht auflösen.\n\nGeprüft wurde:\n" .. tostring(INDEX_ENRICHER_ACTION_COMMAND_ID) .. "\n\nBitte in der Actions-Liste nach 'DF95_FXChains_Index_Enricher.lua' suchen und die Command-ID neu eintragen.")
    return
  end
  r.Main_OnCommand(cmd, 0)
end

------------------------------------------------------------
-- BatchRequest / FXMacros-Anbindung
-- Optional: Actions für
--   * DF95_AI_FXChain_BatchRequest_FromSelection.lua
--   * DF95_AI_FXMacro_Apply_From_AIResult.lua
-- werden hier hinterlegt, damit sie direkt aus dem FXBrain-UI
-- aufrufbar sind.
------------------------------------------------------------

local BATCHREQUEST_ACTION_COMMAND_ID = ""  -- z.B. "_RSaaaaaaaaaaaaaaaaa"
local FXMACROS_ACTION_COMMAND_ID    = ""  -- z.B. "_RSbbbbbbbbbbbbbbbbb"

local function trigger_batchrequest()
  if not BATCHREQUEST_ACTION_COMMAND_ID or BATCHREQUEST_ACTION_COMMAND_ID == "" then
    msg("BATCHREQUEST_ACTION_COMMAND_ID ist nicht gesetzt.\n\nBitte im Script 'DF95 AI Artist FXBrain (ImGui)' oben im Abschnitt 'BatchRequest / FXMacros-Anbindung' die Command-ID deiner 'DF95_AI_FXChain_BatchRequest_FromSelection.lua'-Action eintragen.")
    return
  end
  local cmd = r.NamedCommandLookup(BATCHREQUEST_ACTION_COMMAND_ID)
  if cmd == 0 then
    msg("Konnte BatchRequest-Action nicht auflösen.\n\nGeprüft wurde:\n" .. tostring(BATCHREQUEST_ACTION_COMMAND_ID) .. "\n\nBitte in der Actions-Liste nach 'DF95_AI_FXChain_BatchRequest_FromSelection.lua' suchen und die Command-ID neu eintragen.")
    return
  end
  r.Main_OnCommand(cmd, 0)
end

local function trigger_fxmacros_apply()
  if not FXMACROS_ACTION_COMMAND_ID or FXMACROS_ACTION_COMMAND_ID == "" then
    msg("FXMACROS_ACTION_COMMAND_ID ist nicht gesetzt.\n\nBitte im Script 'DF95 AI Artist FXBrain (ImGui)' oben im Abschnitt 'BatchRequest / FXMacros-Anbindung' die Command-ID deiner 'DF95_AI_FXMacro_Apply_From_AIResult.lua'-Action eintragen.")
    return
  end
  local cmd = r.NamedCommandLookup(FXMACROS_ACTION_COMMAND_ID)
  if cmd == 0 then
    msg("Konnte FXMacros-Action nicht auflösen.\n\nGeprüft wurde:\n" .. tostring(FXMACROS_ACTION_COMMAND_ID) .. "\n\nBitte in der Actions-Liste nach 'DF95_AI_FXMacro_Apply_From_AIResult.lua' suchen und die Command-ID neu eintragen.")
    return
  end
  r.Main_OnCommand(cmd, 0)
end


local function trigger_fullauto_ai_fxchain()
  if not FULLAUTO_ACTION_COMMAND_ID or FULLAUTO_ACTION_COMMAND_ID == "" then
    msg("FULLAUTO_ACTION_COMMAND_ID ist nicht gesetzt.\n\nBitte in 'DF95 AI Artist FXBrain (ImGui)' oben im Script bearbeiten und die Command-ID deiner 'DF95_AI_FXChain_FullAuto_From_AIResult'-Action eintragen.")
    return
  end

  local cmd = r.NamedCommandLookup(FULLAUTO_ACTION_COMMAND_ID)
  if cmd == 0 then
    msg("Konnte FullAuto-Action nicht auflösen.\n\nGeprüft wurde:\n" .. tostring(FULLAUTO_ACTION_COMMAND_ID) .. "\n\nBitte in der Actions-Liste nach 'DF95_AI_FXChain_FullAuto_From_AIResult' suchen und die Command-ID neu eintragen.")
    return
  end

  -- FullAuto-Action ausführen (arbeitet auf aktuelle Track-Selection + ai_fxchains_result.json)
  r.Main_OnCommand(cmd, 0)

------------------------------------------------------------
-- Option 4: Selftest / Diagnostics für die AI-FX-Kette
------------------------------------------------------------

local function run_selftest()
  local lines = {}

  local function add(line)
    lines[#lines+1] = tostring(line)
  end

  add("DF95 AI Artist FXBrain - Selftest")
  add("----------------------------------")

  -- Resource Path
  local respath = get_resource_path()
  add("ResourcePath: " .. tostring(respath))

  -- Data/DF95 Ordner
  local data_root = join_path(respath, "Data/DF95")
  add("Data/DF95: " .. data_root)

  -- fxchains_index.json
  local index_path = join_path(data_root, "fxchains_index.json")
  if r.file_exists and r.file_exists(index_path) or (os and os.remove and io.open(index_path, "r") ~= nil) then
    add("Index: fxchains_index.json gefunden.")
    local content, err = read_file(index_path)
    if content then
      local ok, decoded = pcall(loadstring("return " .. content))
      -- NICHT JSON: der Index ist JSON, wir haben in diesem Script keinen JSON-Parser;
      -- daher testen wir nur grob auf Nicht-Leer / plausibel.
      if content:match("\"fxchains\"") then
        add("Index: scheint gültig (enthält Feld \"fxchains\").")
      else
        add("Index: WARNUNG - Datei enthält kein \"fxchains\"-Feld (bitte mit Index-Builder erneut erzeugen).")
      end
    else
      add("Index: FEHLER - konnte fxchains_index.json nicht lesen: " .. tostring(err))
    end
  else
    add("Index: NICHT GEFUNDEN - bitte zuerst 'DF95_FXChains_Index_Builder.lua' ausführen.")
  end

  -- AI-Result-Datei (optional, aber praktisch)
  local ai_result_path = join_path(data_root, "ai_fxchains_result.json")
  if r.file_exists and r.file_exists(ai_result_path) or (io.open(ai_result_path, "r") ~= nil) then
    add("AI-Result: ai_fxchains_result.json gefunden.")
  else
    add("AI-Result: NICHT GEFUNDEN - FullAuto/Resolver können noch nichts anwenden.")
  end

  -- FullAuto-Action ID
  if FULLAUTO_ACTION_COMMAND_ID and FULLAUTO_ACTION_COMMAND_ID ~= "" then
    local cmd_full = r.NamedCommandLookup(FULLAUTO_ACTION_COMMAND_ID)
    if cmd_full ~= 0 then
      add("FullAuto-Action: OK (Command-ID auflösbar).")
    else
      add("FullAuto-Action: FEHLER - Command-ID nicht auflösbar. Bitte in diesem Script FULLAUTO_ACTION_COMMAND_ID prüfen.")
    end
  else
    add("FullAuto-Action: NICHT KONFIGURIERT - FULLAUTO_ACTION_COMMAND_ID ist leer.")
  end

  -- ApplyFXChain_FromExtState-Action (indirekt über Hinweis)
  add("")
  add("Hinweis:")
  add("  * Index-Builder:  DF95_FXChains_Index_Builder.lua")
  add("  * Enricher:       DF95_FXChains_Index_Enricher.lua")
  add("  * Resolver:       DF95_AI_FXChain_From_AIResult.lua")
  add("  * FullAuto:       DF95_AI_FXChain_FullAuto_From_AIResult.lua")
  add("  * Chunk-Loader:   DF95_AI_ApplyFXChain_FromExtState.lua")

  msg(table.concat(lines, "\n"))
end

end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local txt = f:read("*a") or ""
  f:close()
  return txt, nil
end

-- ⚠️ Minimal JSON-Decoder für kontrollierte eigene Files.
-- Wenn du bereits eine json.lua im DF95-Stack hast,
-- ersetze diese Funktion durch deinen Decoder.
local function decode_json(txt)
  local ok, res = pcall(function()
    txt = "return " .. txt
      :gsub("null", "nil")
      :gsub("true", "true")
      :gsub("false", "false")
    local fn = load(txt)
    return fn()
  end)
  if not ok then
    return nil, "JSON decode error: " .. tostring(res)
  end
  return res, nil
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function join_path(a, b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then
    return a .. b
  end
  return a .. "/" .. b
end

local function get_fxchains_root()
  return join_path(get_resource_path(), "FXChains/DF95")
end

-- Map interne Artist-Keys (aus AI-JSON) auf Ordnernamen unter FXChains/DF95/Coloring/Artists
local artist_folder_map = {
  autechre         = "Autechre",
  aphex_twin       = "AphexTwin",
  boards_of_canada = "BoardsOfCanada",
  venetian_snares  = "VenetianSnares",
  squarepusher     = "Squarepusher",
  boc              = "BoardsOfCanada",
  burial           = "Burial",
  flying_lotus     = "FlyingLotus",
  -- hier kannst du beliebig erweitern
}

------------------------------------------------------------
-- Filescan
------------------------------------------------------------

-- Liste alle .rfxchain Dateien in einem Verzeichnis (nicht rekursiv)
local function list_rfxchains_in_dir(dir)
  local results = {}
  local i = 0
  while true do
    local fn = r.EnumerateFiles(dir, i)
    if not fn then break end
    if fn:lower():sub(-9) == ".rfxchain" then
      results[#results+1] = {
        label    = fn,
        rel_path = fn, -- relativ zum dir
      }
    end
    i = i + 1
  end
  return results
end

-- FXChains für einen Artist-Key scannen
local function scan_fxchains_for_artist(artist_key)
  local fx_root = get_fxchains_root()
  local folder_name = artist_folder_map[artist_key] or artist_key
  local artist_dir = join_path(fx_root, "Coloring/Artists/" .. folder_name)

  local results = {}

  -- 1) direkter Ordner: Coloring/Artists/<Folder>
  local exists = (r.EnumerateFiles(artist_dir, 0) ~= nil)
  if exists then
    local chains = list_rfxchains_in_dir(artist_dir)
    for _, c in ipairs(chains) do
      c.rel_path = "Coloring/Artists/" .. folder_name .. "/" .. c.rel_path
      results[#results+1] = c
    end
  end

  -- 2) Fallback: alle Artists-Ordner durchsuchen und fuzzy matchen
  if #results == 0 then
    local base_dir = join_path(fx_root, "Coloring/Artists")
    local i = 0
    local key_l = artist_key:lower()
    while true do
      local sub = r.EnumerateSubdirectories(base_dir, i)
      if not sub then break end
      local sub_l = sub:lower()
      if sub_l:find(key_l, 1, true) then
        local full_sub = join_path(base_dir, sub)
        local chains = list_rfxchains_in_dir(full_sub)
        for _, c in ipairs(chains) do
          c.rel_path = "Coloring/Artists/" .. sub .. "/" .. c.rel_path
          results[#results+1] = c
        end
      end
      i = i + 1
    end
  end

  return results
end

------------------------------------------------------------
-- State
------------------------------------------------------------

local state = {
  ai_json_path        = "",
  ai_payload          = nil,
  load_error          = nil,
  artist_candidates   = {},
  selected_artist_ix  = 1,
  fxchains_for_artist = {},
  selected_fxchain_ix = 1,
}

------------------------------------------------------------
-- Load AI JSON
------------------------------------------------------------

local function load_ai_json()
  state.load_error          = nil
  state.ai_payload          = nil
  state.artist_candidates   = {}
  state.fxchains_for_artist = {}
  state.selected_artist_ix  = 1
  state.selected_fxchain_ix = 1

  local path = trim(state.ai_json_path)
  if path == "" then
    state.load_error = "Kein AI-Result-JSON-Pfad angegeben."
    return
  end

  local txt, err = read_file(path)
  if not txt then
    state.load_error = "Fehler beim Lesen: " .. tostring(err or "?")
    return
  end

  local obj, jerr = decode_json(txt)
  if not obj then
    state.load_error = jerr
    return
  end

  state.ai_payload = obj

  local candidates = {}
  if obj.artist_candidates and type(obj.artist_candidates) == "table" then
    for _, cand in ipairs(obj.artist_candidates) do
      if cand.key then
        candidates[#candidates+1] = {
          key   = cand.key,
          score = cand.score or 0,
        }
      end
    end
  end

  if #candidates == 0 then
    state.load_error = "Keine artist_candidates im JSON gefunden."
    return
  end

  table.sort(candidates, function(a, b) return (a.score or 0) > (b.score or 0) end)
  state.artist_candidates  = candidates
  state.selected_artist_ix = 1

  local top = candidates[1]
  state.fxchains_for_artist = scan_fxchains_for_artist(top.key)
  state.selected_fxchain_ix = 1
end

------------------------------------------------------------
-- Apply-Hook: FXChain-Pfad in ExtState schreiben
------------------------------------------------------------

local function set_extstate_fxchain_path(abs_path)
  -- persist = true, damit der Pfad auch nach REAPER-Neustart noch da ist
  r.SetExtState("DF95_AI_ArtistFXBrain", "fxchain_path", abs_path, true)
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

local function draw_ui()
  r.ImGui_Text(ctx, "DF95 AI Artist FXBrain")
  r.ImGui_Separator(ctx)

  r.ImGui_TextWrapped(ctx,
    "Dieses Panel verbindet AI-Resultate (Artist-Vorschläge) mit deinen Artist-/IDM-FXChains.\n" ..
    "V1.1: JSON-Pfad eingeben, laden, Artist + FXChain auswählen.\n" ..
    "Der Apply-Button schreibt den FXChain-Pfad in ExtState,\n" ..
    "damit ein zweites Script ihn laden kann."
  )

  r.ImGui_Separator(ctx)

  -- JSON path
  local changed, new_path = r.ImGui_InputText(ctx, "AI Result JSON Pfad", state.ai_json_path or "", 1024)
  if changed then
    state.ai_json_path = new_path
  end
  if r.ImGui_Button(ctx, "AI JSON laden") then
    load_ai_json()
  end

  if state.load_error then
    r.ImGui_SameLine(ctx)
    r.ImGui_TextColored(ctx, 1, 0.3, 0.3, 1, "Fehler: " .. state.load_error)
  end

  r.ImGui_Separator(ctx)

  if not state.ai_payload then
    r.ImGui_TextWrapped(ctx, "Noch keine AI-Daten geladen. Bitte Pfad angeben und 'AI JSON laden' drücken.")
    return
  end

  -- Meta-Info
  if state.ai_payload.source then
    r.ImGui_Text(ctx, "Quelle: " .. tostring(state.ai_payload.source))
  end
  if state.ai_payload.track_name then
    r.ImGui_Text(ctx, "Track: " .. tostring(state.ai_payload.track_name))
  end
  if state.ai_payload.target_bus_type then
    r.ImGui_Text(ctx, "Ziel-Bus-Typ: " .. tostring(state.ai_payload.target_bus_type))
  end

  r.ImGui_Separator(ctx)

  -- Artist-Liste
  r.ImGui_Text(ctx, "Artist-Vorschläge:")
  if #state.artist_candidates == 0 then
    r.ImGui_TextWrapped(ctx, "Keine Artist-Candidates gefunden.")
  else
    if r.ImGui_BeginListBox(ctx, "##artist_list", 260, 160) then
      for i, cand in ipairs(state.artist_candidates) do
        local label    = string.format("%s (%.2f)", cand.key, cand.score or 0)
        local selected = (i == state.selected_artist_ix)
        local clicked  = r.ImGui_Selectable(ctx, label, selected)
        if clicked then
          state.selected_artist_ix  = i
          state.fxchains_for_artist = scan_fxchains_for_artist(cand.key)
          state.selected_fxchain_ix = 1
        end
        if selected then
          r.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      r.ImGui_EndListBox(ctx)
    end
  end

  r.ImGui_SameLine(ctx)

  -- FXChains-Liste
  r.ImGui_BeginGroup(ctx)
  r.ImGui_Text(ctx, "FXChains für Artist:")
  if #state.fxchains_for_artist == 0 then
    r.ImGui_TextWrapped(ctx, "Keine FXChains gefunden (prüfe FXChains/DF95/Coloring/Artists/<Artist>/...).")
  else
    if r.ImGui_BeginListBox(ctx, "##fxchain_list", 420, 160) then
      for i, entry in ipairs(state.fxchains_for_artist) do
        local label    = entry.label or entry.rel_path
        local selected = (i == state.selected_fxchain_ix)
        local clicked  = r.ImGui_Selectable(ctx, label, selected)
        if clicked then
          state.selected_fxchain_ix = i
        end
        if selected then
          r.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      r.ImGui_EndListBox(ctx)
    end
  end
  r.ImGui_EndGroup(ctx)

  r.ImGui_Separator(ctx)

  local selArtist = state.artist_candidates[state.selected_artist_ix]
  local selChain  = state.fxchains_for_artist[state.selected_fxchain_ix]

  if selArtist then
    r.ImGui_Text(ctx, "Gewählter Artist: " .. tostring(selArtist.key))
  end
  if selChain then
    r.ImGui_TextWrapped(ctx, "Gewählte FXChain (relativ): " .. tostring(selChain.rel_path))
    local abs = join_path(get_fxchains_root(), selChain.rel_path)
    r.ImGui_TextWrapped(ctx, "Absoluter Pfad: " .. abs)
  end

  r.ImGui_Separator(ctx)

  if r.ImGui_Button(ctx, "Apply FXChain (Pfad in ExtState schreiben)") then
    if not selChain then
      msg("Keine FXChain ausgewählt.")
    else
      local abs = join_path(get_fxchains_root(), selChain.rel_path)
      set_extstate_fxchain_path(abs)
      msg("FXChain-Pfad in ExtState gesetzt:\n\n" ..
          abs ..
          "\n\nStarte jetzt dein Apply-Script, das diesen Pfad liest und die Chain auf selektierte Tracks lädt.")
    end
  end

  -- Index-Tools
  if r.ImGui_Button(ctx, "Build FXChain Index") then
    trigger_index_builder()
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Enrich FXChain Index") then
    trigger_index_enricher()
  end

  -- Batch / FXMacros
  if r.ImGui_Button(ctx, "Build AI BatchRequest (Selection)") then
    trigger_batchrequest()
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, "Apply AI FXMacros") then
    trigger_fxmacros_apply()
  end

  -- Option 3: FullAuto-Anbindung
  if r.ImGui_Button(ctx, "FullAuto: AI FXChain Apply (ai_fxchains_result.json)") then
    trigger_fullauto_ai_fxchain()
  end

  -- Option 4: Selftest / Diagnostics
  if r.ImGui_Button(ctx, "Selftest: DF95 AI FX Pipeline") then
    run_selftest()
  end
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------

local function loop()
  r.ImGui_SetNextWindowSize(ctx, 950, 620, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 AI Artist FXBrain", true)

  if visible then
    draw_ui()
  end

  r.ImGui_End(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
