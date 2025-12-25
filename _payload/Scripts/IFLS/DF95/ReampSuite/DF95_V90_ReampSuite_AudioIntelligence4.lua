\
-- @description DF95_V90_ReampSuite_AudioIntelligence4
-- @version 1.0
-- @author DF95
-- @about
--   Audio Intelligence 4.0 (Meta-Meter-Release):
--   - verwendet AI3-Struktur (DF95_V84_ReampSuite_AudioIntelligence3.lua)
--   - nutzt, sofern vorhanden, spektrale Informationen (z. B. aus JSFX-Analysern)
--   - wählt eine PedalChain, indem eine erweiterte Heuristik auf die
--     Metriken angewendet wird.
--
--   WICHTIG:
--   - Dieses Script macht KEINE eigene Spektralanalyse.
--   - Es geht davon aus, dass externe Tools (z. B. JSFX Analyzer) die
--     AI3-Datenstruktur in Zukunft mit echten Werten füllen können.
--   - Fällt Werte auf nil zurück -> nutzt nur Namen/Typ-Informationen.

local r = reaper

local EXT_NS       = "DF95_REAMP"
local KEY_PC_KEY   = "PEDAL_CHAIN_KEY"
local KEY_PC_NAME  = "PEDAL_CHAIN_NAME"
local KEY_PC_DESC  = "PEDAL_CHAIN_DESC"

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end

local chains_mod, chains_err = safe_require(df95_root() .. "ReampSuite/DF95_ReampSuite_PedalChains.lua")
local ai3_mod, ai3_err       = safe_require(df95_root() .. "ReampSuite/DF95_V84_ReampSuite_AudioIntelligence3.lua")

if not chains_mod or type(chains_mod) ~= "table" or type(chains_mod.chains) ~= "table" then
  r.ShowMessageBox("PedalChains-Modul nicht verfügbar (DF95_ReampSuite_PedalChains.lua).", "DF95 AI4", 0)
  return
end

local M = {}

local function get_chain_info_list()
  local infos = {}
  for key, ch in pairs(chains_mod.chains) do
    local txt = (key .. " " .. (ch.name or "") .. " " .. (ch.use_case or "")):lower()
    infos[#infos+1] = { key = key, chain = ch, text = txt }
  end
  return infos
end

local chains_info = get_chain_info_list()

local function score_chain(info, track_info)
  -- track_info: aus AI3 summary (peak_db, dyn_db, spectral_*, name)
  local s = 0
  local t = info.text

  local name = (track_info.name or ""):lower()
  if name:find("kick") or name:find("drum") or name:find("perc") then
    if t:find("perc") or t:find("drum") then s = s + 5 end
  end
  if name:find("lead") then
    if t:find("lead") then s = s + 5 end
  end
  if name:find("pad") then
    if t:find("pad") or t:find("ambient") then s = s + 5 end
  end
  if name:find("bass") or name:find("sub") then
    if t:find("bass") or t:find("sub") then s = s + 5 end
  end
  if name:find("idm") or name:find("glitch") then
    if t:find("idm") or t:find("glitch") then s = s + 4 end
  end

  -- Dynamik
  local dyn = track_info.dyn_db or nil
  if dyn then
    if dyn >= 10 then
      if t:find("perc") or t:find("transient") then s = s + 3 end
    elseif dyn <= 6 then
      if t:find("pad") or t:find("sustain") then s = s + 3 end
    end
  end

  -- Spektral-Platzhalter: wenn später befüllt, kann man hier logisch verfeinern
  local bright = track_info.spectral_brightness
  local noisy  = track_info.spectral_noisiness

  if bright and bright > 0.6 then
    if t:find("bright") or t:find("shimmer") or t:find("chip") then s = s + 2 end
  end
  if noisy and noisy > 0.6 then
    if t:find("noise") or t:find("fuzz") or t:find("dist") then s = s + 2 end
  end

  return s
end

local function set_ext_state_for_chain(key, chain)
  r.SetExtState(EXT_NS, KEY_PC_KEY,  key or "",       false)
  r.SetExtState(EXT_NS, KEY_PC_NAME, (chain and chain.name) or "",     false)
  r.SetExtState(EXT_NS, KEY_PC_DESC, (chain and chain.use_case) or "", false)
end

function M.auto_assign_from_ai3_summary(summary)
  if not summary or not summary.tracks or #summary.tracks == 0 then
    return nil, "Keine Tracks in AI3-Summary."
  end

  local best_key, best_chain, best_score = nil, nil, -1

  for _, track_info in ipairs(summary.tracks) do
    for _, info in ipairs(chains_info) do
      local s = score_chain(info, track_info)
      if s > best_score then
        best_score = s
        best_key   = info.key
        best_chain = info.chain
      end
    end
  end

  if best_key then
    set_ext_state_for_chain(best_key, best_chain)
  end

  return best_key, best_chain, best_score
end

-- Wenn direkt als Action gestartet: nutzt AI3, liest selektierte Reamp-Tracks ein und wählt Chain.
local function collect_selected_tracks()
  local t = {}
  local cnt = r.CountSelectedTracks(0)
  for i = 0, cnt - 1 do
    t[#t+1] = r.GetSelectedTrack(0, i)
  end
  return t
end

local function is_reamp_candidate_name(name)
  if not name or name == "" then return false end
  local u = name:upper()
  if u:match("REAMP") then return true end
  if u:match("RE%-AMP") then return true end
  if u:match(" DI ") then return true end
  if u:match("_DI") then return true end
  if u:match("DI_") then return true end
  if u:match("PEDAL") then return true end
  return false
end

local function collect_reamp_candidates(tracks)
  local out = {}
  for _, tr in ipairs(tracks) do
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if is_reamp_candidate_name(name) then
      out[#out+1] = tr
    end
  end
  return out
end

local function main_action()
  if not ai3_mod or type(ai3_mod.analyze_tracks) ~= "function" then
    r.ShowMessageBox("AudioInt3-Modul nicht verfügbar (DF95_V84_ReampSuite_AudioIntelligence3.lua).", "DF95 AI4", 0)
    return
  end

  local sel = collect_selected_tracks()
  if #sel == 0 then
    r.ShowMessageBox("Bitte Reamp/DI/PEDAL-Tracks selektieren.", "DF95 AI4", 0)
    return
  end

  local reamp = collect_reamp_candidates(sel)
  if #reamp == 0 then
    r.ShowMessageBox("Keine Reamp-Kandidaten in der Auswahl.", "DF95 AI4", 0)
    return
  end

  local summary = ai3_mod.analyze_tracks(reamp)
  local key, chain, score = M.auto_assign_from_ai3_summary(summary)
  if key then
    r.ShowMessageBox(string.format("AI4 hat PedalChain '%s' (Key: %s, Score: %.1f) gewählt.",
      chain and (chain.name or key) or key, key, score or 0), "DF95 AI4", 0)
  else
    r.ShowMessageBox("AI4 konnte keine PedalChain bestimmen.", "DF95 AI4", 0)
  end
end

if not ... then
  main_action()
end

return M
