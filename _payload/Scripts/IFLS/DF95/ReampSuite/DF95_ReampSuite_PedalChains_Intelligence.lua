
-- @description DF95_ReampSuite_PedalChains_Intelligence
-- @version 1.0
-- @author DF95
-- @about
--   Intelligenz-Layer für DF95_ReampSuite_PedalChains:
--   - analysiert Tracknamen (Kick/Snare/Lead/FX/etc.)
--   - versucht, eine passende PedalChain aus M.chains zu wählen
--   - schreibt optional ExtStates in DF95_REAMP/*
--   - kann optional Tracknamen mit [PC:<Key>] taggen
--
--   Wird von DF95_V76_SuperPipeline.lua genutzt, kann aber auch
--   als eigenständige Action eingesetzt werden (über ein kleines
--   Wrapper-Script).
--
--   Wichtig:
--     - Erwartet DF95_ReampSuite_PedalChains.lua im selben Ordner.
--     - Greift NICHT direkt in Routing oder FX-Chain ein – nur
--       in ExtStates / Tracknamen.

local r = reaper

local M = {}

---------------------------------------------------------
-- DF95 Root / Require
---------------------------------------------------------

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

local chains_mod, err = safe_require(df95_root() .. "ReampSuite/DF95_ReampSuite_PedalChains.lua")
if not chains_mod or type(chains_mod) ~= "table" or type(chains_mod.chains) ~= "table" then
  r.ShowMessageBox(
    "DF95_ReampSuite_PedalChains_Intelligence:\n" ..
    "Konnte DF95_ReampSuite_PedalChains.lua nicht laden.\n\n" ..
    "Fehler: " .. tostring(err or "?"),
    "DF95 ReampSuite PedalChains Intelligence",
    0
  )
  return M
end

---------------------------------------------------------
-- Konstanten (kompatibel mit PedalChains.lua)
---------------------------------------------------------

local EXT_NS       = "DF95_REAMP"
local KEY_PC_KEY   = "PEDAL_CHAIN_KEY"
local KEY_PC_NAME  = "PEDAL_CHAIN_NAME"
local KEY_PC_DESC  = "PEDAL_CHAIN_DESC"

---------------------------------------------------------
-- Util
---------------------------------------------------------

local function get_track_name(tr)
  local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  return name or ""
end

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize(str)
  return (str or ""):lower()
end

local function extract_pc_tag(name)
  -- Sucht nach [PC:<KEY>] im Namen
  local tag = name:match("%[PC:([%w_%-]+)%]")
  return tag
end

---------------------------------------------------------
-- Chain-Metadaten vorbereiten
---------------------------------------------------------

local chain_info = {}

do
  for key, chain in pairs(chains_mod.chains) do
    local name = chain.name or ""
    local use_case = chain.use_case or ""
    local text = (key .. " " .. name .. " " .. use_case):lower()
    chain_info[#chain_info+1] = {
      key      = key,
      chain    = chain,
      text     = text,
      name     = name,
      use_case = use_case,
    }
  end
end

---------------------------------------------------------
-- Scoring-Logik
---------------------------------------------------------

local function collect_keywords_from_trackname(name)
  local n = normalize(name)
  local kws = {}

  local function add_kw(kw)
    kws[#kws+1] = kw
  end

  if n:find("kick") then add_kw("kick") end
  if n:find("snare") or n:find("clap") or n:find("rim") then add_kw("snare") end
  if n:find("hat") or n:find("hh") or n:find("hihat") then add_kw("hat") end
  if n:find("perc") or n:find("perk") or n:find("drum") or n:find("tom") then add_kw("perc") end

  if n:find("lead") or n:find("ld") then add_kw("lead") end
  if n:find("pad") then add_kw("pad") end
  if n:find("bass") or n:find("sub") then add_kw("bass") end
  if n:find("vox") or n:find("vocal") or n:find("voice") then add_kw("vocal") end

  if n:find("fx") or n:find("sfx") or n:find("impact") or n:find("hit") or n:find("whoosh")
     or n:find("sweep") or n:find("rise") or n:find("risr") or n:find("noise") then
    add_kw("fx")
  end

  if n:find("idm") then add_kw("idm") end
  if n:find("glitch") then add_kw("glitch") end
  if n:find("chip") or n:find("8bit") or n:find("8-bit") then add_kw("chip") end
  if n:find("warp") or n:find("pitch") then add_kw("pitch") end

  return kws
end

local function score_chain_for_keywords(info, kws)
  local score = 0
  local text = info.text

  for _, kw in ipairs(kws) do
    if kw == "kick" then
      if text:find("kick") then score = score + 4 end
      if text:find("drum") or text:find("perk") or text:find("perc") then score = score + 2 end
    elseif kw == "snare" or kw == "hat" or kw == "perc" then
      if text:find("perc") or text:find("perk") or text:find("drum") then score = score + 3 end
      if text:find("glitch") then score = score + 2 end
    elseif kw == "lead" then
      if text:find("lead") then score = score + 4 end
      if text:find("pitch") or text:find("formant") then score = score + 2 end
    elseif kw == "pad" then
      if text:find("pad") or text:find("ambient") or text:find("raum") then score = score + 3 end
    elseif kw == "bass" then
      if text:find("bass") or text:find("low") then score = score + 3 end
    elseif kw == "vocal" then
      if text:find("vocal") or text:find("voice") then score = score + 3 end
      if text:find("formant") or text:find("pitch") then score = score + 2 end
    elseif kw == "fx" then
      if text:find("fx") or text:find("noise") or text:find("chip") then score = score + 4 end
      if text:find("space") or text:find("raum") or text:find("reverb") then score = score + 1 end
    elseif kw == "idm" then
      if text:find("idm") then score = score + 3 end
      if text:find("glitch") then score = score + 2 end
    elseif kw == "glitch" then
      if text:find("glitch") then score = score + 4 end
    elseif kw == "chip" then
      if text:find("chip") or text:find("8%-bit") or text:find("8bit") then score = score + 4 end
      if text:find("noise") then score = score + 1 end
    elseif kw == "pitch" then
      if text:find("pitch") or text:find("warp") then score = score + 4 end
      if text:find("lead") then score = score + 1 end
    end

    -- generischer Treffer: Keyword als Substring
    if text:find(kw) then
      score = score + 1
    end
  end

  return score
end

local function decide_best_chain_for_track_name(name)
  local tag = extract_pc_tag(name or "")
  if tag and chains_mod.chains[tag] then
    return tag, chains_mod.chains[tag], true
  end

  local kws = collect_keywords_from_trackname(name or "")
  if #kws == 0 then
    return nil, nil, false
  end

  local best_key, best_chain, best_score = nil, nil, 0
  for _, info in ipairs(chain_info) do
    local s = score_chain_for_keywords(info, kws)
    if s > best_score then
      best_score = s
      best_key = info.key
      best_chain = info.chain
    end
  end

  if best_score <= 0 then
    return nil, nil, false
  end

  return best_key, best_chain, false
end

M.decide_best_chain_for_track_name = decide_best_chain_for_track_name

---------------------------------------------------------
-- ExtState / Tag-Anwendung
---------------------------------------------------------

local function set_ext_state_for_chain(key, chain)
  if not key or not chain then return end
  r.SetExtState(EXT_NS, KEY_PC_KEY,  key,        false)
  r.SetExtState(EXT_NS, KEY_PC_NAME, chain.name or "",      false)
  r.SetExtState(EXT_NS, KEY_PC_DESC, chain.use_case or "",  false)
end

local function apply_tag_to_track_name(tr, key)
  if not tr or not key then return end
  local name = get_track_name(tr)
  if name == "" then
    name = "[PC:" .. key .. "]"
  else
    -- vorhandenes [PC:...] entfernen
    name = name:gsub("%[PC:[^%]]+%]%s*", "")
    name = name .. " [PC:" .. key .. "]"
  end
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
end

---------------------------------------------------------
-- Hauptfunktion: mehreren Tracks eine Chain zuweisen
---------------------------------------------------------

-- opts:
--   tag_tracks   (bool)  -> Tracknamen mit [PC:<key>] markieren
--   set_extstate (bool)  -> DF95_REAMP/* ExtStates setzen
--   verbose      (bool)  -> Console-Debug
function M.auto_assign_for_tracks(tracks, opts)
  opts = opts or {}
  local tag_tracks   = opts.tag_tracks ~= false and opts.tag_tracks or false
  local set_extstate = opts.set_extstate ~= false and opts.set_extstate or true
  local verbose      = opts.verbose or false

  local best_key, best_chain, best_score = nil, nil, 0

  for _, tr in ipairs(tracks) do
    local name = get_track_name(tr)
    local key, chain, from_tag = decide_best_chain_for_track_name(name)

    if key and chain then
      -- wir werten Scores neu, um global die "beste" Chain zu wählen
      local kws = collect_keywords_from_trackname(name or "")
      local info = nil
      for _, ci in ipairs(chain_info) do
        if ci.key == key then info = ci break end
      end
      local score = info and score_chain_for_keywords(info, kws) or 0

      if verbose then
        r.ShowConsoleMsg(string.format("[DF95 PC-Intel] Track '%s' -> %s (Score %d%s)\n",
          name, key, score, from_tag and ", via [PC:..]" or ""))
      end

      if score > best_score then
        best_score = score
        best_key = key
        best_chain = chain
      end

      if tag_tracks and key then
        apply_tag_to_track_name(tr, key)
      end
    elseif verbose then
      r.ShowConsoleMsg(string.format("[DF95 PC-Intel] Track '%s' -> keine passende Chain gefunden\n", name))
    end
  end

  if best_key and best_chain and set_extstate then
    set_ext_state_for_chain(best_key, best_chain)
  end

  return best_key
end

return M
