-- @description DF95_V133 AI Beat & Soundscape Generator (SampleDB + AI)
-- @version 1.0
-- @author DF95
-- @about
--   Erzeugt automatisch einen kleinen Beat oder eine Soundscape im aktuellen Projekt,
--   basierend auf der DF95 SampleDB (UCS, Text-Heuristik) und optional AI-Tags
--   (ai_primary / ai_labels aus YAMNet o.ä.).
--
--   Features:
--     * MODE=BEAT:
--         - Sucht Kicks, Snares, HiHats in der DB.
--         - Nutzt AI-Labels (z.B. "Drum", "Kick drum", "Snare", "Hi-hat")
--           und/oder Dateinamen (kick/snare/hat) + UCS Category (DRUMS).
--         - Setzt einen einfachen 1- oder 2-Takt Groove auf neue Tracks.
--     * MODE=TEXTURE:
--         - Sucht Wasser-/Ambience-/Whoosh-ähnliche Sounds (AI + UCS + Dateinamen).
--         - Legt mehrere Tracks als sich überlagernde Texturen an.
--
--   Voraussetzungen:
--     * Eine DF95 SampleDB JSON:
--         <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--       mit Einträgen im Format:
--         { path=..., ucs_category=..., ai_primary=..., ai_labels=..., quality_grade=..., ... }
--     * AI-Felder sind optional. Wenn nicht vorhanden, wird nur mit UCS/Text gearbeitet.

local r = reaper

------------------------------------------------------------
-- JSON Decoder (einfach, wie in anderen DF95 Scripts)
------------------------------------------------------------

local function decode_json(text)
  if type(text) ~= "string" then return nil, "no text" end

  local lua_text = text
  lua_text = lua_text:gsub('"(.-)"%s*:', '["%1"] =')
  lua_text = lua_text:gsub("%[", "{")
  lua_text = lua_text:gsub("%]", "}")
  lua_text = lua_text:gsub("null", "nil")

  lua_text = "return " .. lua_text

  local f, err = load(lua_text)
  if not f then return nil, err end

  local ok, res = pcall(f)
  if not ok then return nil, res end
  return res
end

------------------------------------------------------------

------------------------------------------------------------
-- Konfiguration: AI-Auswahlmodus für Drums
------------------------------------------------------------

-- Mögliche Werte:
--   "CLASSIC"    = nur klassische Heuristiken (Dateiname + UCS + ai_primary)
--   "AI_FIRST"   = AIWorker-Felder (drum_role, ai_tags, ai_labels, material/instrument)
--                  werden zuerst berücksichtigt, klassische Heuristik als Fallback.
--   "AI_WEIGHTED"= nutzt Weighted Selector + drum_confidence + Quality-Grade.
--
-- Der Modus kann im BEAT-Dialog pro Aufruf gesetzt werden oder über
-- ExtState "DF95_AI_BEAT", Key "MODE".
do
  local ext_mode = reaper.GetExtState("DF95_AI_BEAT", "MODE")
  ext_mode = (ext_mode or ""):upper()
  if ext_mode ~= "CLASSIC" and ext_mode ~= "AI_FIRST" and ext_mode ~= "AI_WEIGHTED" then
    ext_mode = "AI_FIRST"
  end
  AI_BEAT_SELECTION_MODE = ext_mode
end

-- Pfad-Helper
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\\" then
    a = a .. sep
  end
  return a .. b
end

local function get_db_path()
  local res = r.GetResourcePath()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function basename(path)
  return (path or ""):match("([^\\/]+)$") or path
end

------------------------------------------------------------
-- Helper: Grade-Ranking (optional)
------------------------------------------------------------

local function grade_to_rank(g)
  if not g then return 0 end
  g = g:upper()
  if g == "A" then return 4
  elseif g == "B" then return 3
  elseif g == "C" then return 2
  elseif g == "D" then return 1
  end
  return 0
end

------------------------------------------------------------
-- Helper: Random
------------------------------------------------------------

local function choice(list)
  if not list or #list == 0 then return nil end
  local idx = math.random(1, #list)
  return list[idx]
end

local function DF95_AIBeat_ReadWeights()
  local r = reaper
  local function read_num(key, default)
    local s = r.GetExtState("DF95_AI_BEAT", key)
    local v = tonumber(s)
    if not v then return default end
    return v
  end
  return {
    base  = read_num("W_BASE",  1.0),
    role  = read_num("W_ROLE",  2.0),
    meta  = read_num("W_META",  1.0),
    conf  = read_num("W_CONF",  2.0),
    grade = read_num("W_GRADE", 0.25),
  }
end

local function compute_candidate_score(it, target_role)
  local w = DF95_AIBeat_ReadWeights()

  -- Basisscore
  local score = w.base or 1.0

  -- Metadaten sammeln (nutzt gleiche Logik wie die Klassifizierer)
  local ok, meta = pcall(gather_drum_meta, it)
  if not ok or type(meta) ~= "table" then
    meta = { meta = "", role = "", tags = "", ai = "", name = "", cat = "", sub = "" }
  end

  local trg = (target_role or ""):lower()
  local role = meta.role or ""
  local conf = it.drum_confidence or it.ai_confidence or 0.0

  -- Rolle passend?
  if trg ~= "" and role == trg then
    score = score + (w.role or 0)
  end

  -- Text-Matches im Meta-String
  if trg ~= "" and meta.meta and meta.meta:find(" " .. trg .. " ") then
    score = score + (w.meta or 0)
  end

  -- Confidence (AI / Drum)
  if conf > 0 then
    score = score + ((w.conf or 0) * math.min(conf, 1.0))
  end

  -- Bevorzugung von hohen Quality-Grades
  local gr = grade_to_rank and grade_to_rank(it.quality_grade) or 0
  score = score + ((w.grade or 0) * gr)

  return score
end

local function weighted_choice(list, target_role)
  if not list or #list == 0 then return nil end

  -- Scores berechnen
  local total = 0.0
  local scores = {}
  for i, it in ipairs(list) do
    local s = compute_candidate_score(it, target_role)
    if s < 0.001 then s = 0.001 end
    scores[i] = s
    total = total + s
  end

  if total <= 0 then
    return choice(list)
  end

  -- Zufälliger Punkt auf der Summenachse
  local rpos = math.random() * total
  local acc = 0.0
  for i, it in ipairs(list) do
    acc = acc + scores[i]
    if rpos <= acc then
      return it
    end
  end

  return list[#list]
end

local function pick_candidate(candidates, target_role)
  if not candidates or #candidates == 0 then return nil end

  if AI_BEAT_SELECTION_MODE == "AI_WEIGHTED" then
    return weighted_choice(candidates, target_role)
  else
    -- CLASSIC oder AI_FIRST: beide nutzen dieselbe Auswahl,
    -- aber die Klassifizierer sind bereits AI-bewusst.
    return choice(candidates)
  end
end

local function filter_best_quality(list, min_rank)
  min_rank = min_rank or 0
  local out = {}
  for _, it in ipairs(list) do
    local gr = grade_to_rank(it.quality_grade)
    if gr >= min_rank then
      out[#out+1] = it
    end
  end
  if #out == 0 then
    return list
  end
  return out
end

------------------------------------------------------------
-- Klassifizierungs-Heuristiken (Drums / Texturen, AIWorker-aware)
------------------------------------------------------------

local function lower(s) return (s or ""):lower() end

-- Gemeinsamer Metadaten-Sampler für Drum-Entscheidungen
local function gather_drum_meta(it)
  local name = lower(basename(it.path or ""))
  local cat  = lower(it.ucs_category or "")
  local sub  = lower(it.ucs_subcategory or "")
  local ai   = lower(it.ai_primary or "")

  local ai_labels = ""
  if type(it.ai_labels) == "table" then
    ai_labels = lower(table.concat(it.ai_labels, " "))
  elseif type(it.ai_labels) == "string" then
    ai_labels = lower(it.ai_labels)
  end

  local tags = ""
  if type(it.ai_tags) == "table" then
    tags = lower(table.concat(it.ai_tags, " "))
  elseif type(it.ai_tags) == "string" then
    tags = lower(it.ai_tags)
  end

  local role = lower(it.drum_role or it.df95_role or it.role or "")
  local material   = lower(it.df95_material   or it.material   or "")
  local instrument = lower(it.df95_instrument or it.instrument or "")

  local meta = " " .. name .. " " .. sub .. " " .. cat .. " "
            .. ai .. " " .. ai_labels .. " " .. tags .. " "
            .. material .. " " .. instrument .. " "

  return {
    name       = name,
    cat        = cat,
    sub        = sub,
    ai         = ai,
    ai_labels  = ai_labels,
    tags       = tags,
    role       = role,
    material   = material,
    instrument = instrument,
    meta       = meta,
  }
end

------------------------------------------------------------
-- Kick / Snare / Hat
------------------------------------------------------------

local function is_kick(it)
  local m = gather_drum_meta(it)

  -- AI-first Ebene (Role / Tags / Labels), kann via MODE deaktiviert werden
  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "kick" or m.role == "bd" or m.role == "bassdrum" then
      return true
    end
    if m.meta:find(" kick ")
      or m.meta:find(" bass drum")
      or m.meta:find(" bassdrum")
      or m.meta:find(" bd ")
      or m.meta:find(" bd_")
    then
      return true
    end
  end

  -- Klassische Heuristiken (immer aktiv, fallback)
  if m.name:find("kick") or m.name:find("bd_") or m.name:find("bassdrum") then return true end
  if m.sub:find("kick") then return true end
  if m.ai:find("kick") or m.ai:find("bass drum") then return true end
  if m.cat:find("drum") and (m.name:find("kik") or m.name:find("bd")) then return true end

  return false
end

local function is_snare(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "snare" or m.role == "sd" then
      return true
    end
    if m.meta:find(" snare")
      or m.meta:find(" rimshot")
      or m.meta:find(" side stick")
      or m.meta:find(" sidestick")
    then
      return true
    end
  end

  if m.name:find("snare") or m.name:find("sd_") or m.name:find("snr") then return true end
  if m.sub:find("snare") then return true end
  if m.ai:find("snare") then return true end
  if m.cat:find("drum") and m.name:find("snr") then return true end

  return false
end

local function is_hat(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "hat" or m.role == "hh" or m.role == "hihat" then
      return true
    end
    if m.meta:find(" hi-hat")
      or m.meta:find(" hihat")
      or m.meta:find(" hat ")
      or m.meta:find(" closed hat")
      or m.meta:find(" open hat")
    then
      return true
    end
  end

  if m.name:find("hihat") or m.name:find("hi-hat") or m.name:find("hat_") or m.name:find("hh_") then return true end
  if m.sub:find("hat") then return true end
  if m.ai:find("hi-hat") or m.ai:find("hihat") or m.ai:find("cymbal") then return true end

  return false
end

------------------------------------------------------------
-- Toms / Cymbals
------------------------------------------------------------

local function is_tom_high(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "tomh" or m.role == "tom_high" then
      return true
    end
  end

  if m.sub:find("tomhigh") or m.sub:find("tom_high") then return true end
  if m.name:find("tom1") or m.name:find("high tom") or m.name:find("hightom") then return true end
  return false
end

local function is_tom_mid(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "tomm" or m.role == "tom_mid" then
      return true
    end
  end

  if m.sub:find("tommid") or m.sub:find("tom_mid") then return true end
  if m.name:find("tom2") or m.name:find("midt") or m.name:find("mid tom") then return true end
  return false
end

local function is_tom_low(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "toml" or m.role == "tom_low" or m.role == "floortom" then
      return true
    end
  end

  if m.sub:find("tomlow") or m.sub:find("tom_low") or m.sub:find("floortom") then return true end
  if m.name:find("floor") or m.name:find("floortom") or m.name:find("floor tom") then return true end
  return false
end

local function is_ride(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "ride" then
      return true
    end
    if m.meta:find(" ride cymbal") or m.meta:find(" ride ") then
      return true
    end
  end

  if m.sub:find("ride") then return true end
  if m.name:find("ride") or m.name:find("rd_") then return true end
  if m.ai:find("ride") and m.ai:find("cymbal") then return true end

  return false
end

local function is_crash(it)
  local m = gather_drum_meta(it)

  if AI_BEAT_SELECTION_MODE ~= "CLASSIC" then
    if m.role == "crash" then
      return true
    end
    if m.meta:find(" crash")
      or m.meta:find(" splash")
      or m.meta:find(" china")
    then
      return true
    end
  end

  if m.sub:find("crash") or m.sub:find("splash") or m.sub:find("china") then return true end
  if m.name:find("crash") or m.name:find("splash") or m.name:find("china") then return true end
  if m.ai:find("crash") or m.ai:find("splash") or m.ai:find("china") then return true end

  return false
end
------------------------------------------------------------
-- Audio-Objekt erzeugen
------------------------------------------------------------

local function add_item_with_source(track, path, pos)
  local src = r.PCM_Source_CreateFromFile(path)
  if not src then return nil end

  local length = r.GetMediaSourceLength(src)

  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", pos or 0)
  r.SetMediaItemInfo_Value(item, "D_LENGTH", length or 0)

  local take = r.AddTakeToMediaItem(item)
  r.SetMediaItemTake_Source(take, src)

  -- src nicht zerstören; REAPER übernimmt Referenz

  return item, take, length
end

------------------------------------------------------------
-- Beat-Generator
------------------------------------------------------------

local function generate_beat(db, items)
  local ok, vals = r.GetUserInputs(
    "DF95 AI Beat Generator",
    6,
    "BPM,Bars,Min Quality Grade (A/B/C/D, leer=keine),Extended Kit? (YES/NO),Add Toms Fills? (YES/NO),AI Selection Mode (CLASSIC/AI_FIRST/AI_WEIGHTED)",
    "90,2,,YES,YES,AI_FIRST"
  )
  if not ok then return end

  local s_bpm, s_bars, s_grade, s_ext, s_fills, s_aimode = vals:match("([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")

  local aimode = (s_aimode or ""):upper()
  if aimode ~= "CLASSIC" and aimode ~= "AI_FIRST" and aimode ~= "AI_WEIGHTED" then
    aimode = "AI_FIRST"
  end
  AI_BEAT_SELECTION_MODE = aimode
  reaper.SetExtState("DF95_AI_BEAT", "MODE", aimode, false)

  local bpm = tonumber(s_bpm or "90") or 90
  if bpm < 40 then bpm = 40 end
  if bpm > 220 then bpm = 220 end

  local bars = tonumber(s_bars or "2") or 2
  if bars < 1 then bars = 1 end
  if bars > 64 then bars = 64 end

  local min_rank = grade_to_rank(s_grade)
  local use_ext  = ((s_ext or ""):upper() ~= "NO")
  local use_fills = ((s_fills or ""):upper() == "YES")

  local kicks, snares, hats = {}, {}, {}
  local tomh, tomm, toml = {}, {}, {}
  local rides, crashes = {}, {}

  for _, it in ipairs(items) do
    if it.path then
      local rank = grade_to_rank(it.quality_grade)
      if rank >= min_rank then
        if is_kick(it) then
          kicks[#kicks+1] = it
        elseif is_snare(it) then
          snares[#snares+1] = it
        elseif is_hat(it) then
          hats[#hats+1] = it
        elseif use_ext and is_tom_high(it) then
          tomh[#tomh+1] = it
        elseif use_ext and is_tom_mid(it) then
          tomm[#tomm+1] = it
        elseif use_ext and is_tom_low(it) then
          toml[#toml+1] = it
        elseif use_ext and is_ride(it) then
          rides[#rides+1] = it
        elseif use_ext and is_crash(it) then
          crashes[#crashes+1] = it
        end
      end
    end
  end

  if #kicks == 0 and #snares == 0 and #hats == 0 then
    r.ShowMessageBox(
      "Keine Drums gefunden (Kick/Snare/Hat) mit den aktuellen Filtern.
" ..
      "Bitte AI-Classify verwenden oder Dateinamen/UCS prüfen.",
      "DF95 AI Beat Generator",
      0
    )
    return
  end

  local proj = 0
  r.Undo_BeginBlock()

  r.GetSetProjectInfo(proj, "TEMPO", bpm, true)

  local kick_it =     pick_candidate(filter_best_quality(kicks,   min_rank), "KICK")   or pick_candidate(kicks,   "KICK")
  local snare_it =    pick_candidate(filter_best_quality(snares, min_rank), "SNARE")  or pick_candidate(snares, "SNARE")
  local hat_it   =    pick_candidate(filter_best_quality(hats,   min_rank), "HIHAT")  or pick_candidate(hats,   "HIHAT")
  local th_it    =    pick_candidate(filter_best_quality(tomh,   min_rank), "TOMH")   or pick_candidate(tomh,   "TOMH")
  local tm_it    =    pick_candidate(filter_best_quality(tomm,   min_rank), "TOMM")   or pick_candidate(tomm,   "TOMM")
  local tl_it    =    pick_candidate(filter_best_quality(toml,   min_rank), "TOML")   or pick_candidate(toml,   "TOML")
  local ride_it  =    pick_candidate(filter_best_quality(rides,  min_rank), "RIDE")   or pick_candidate(rides,  "RIDE")
  local crash_it =    pick_candidate(filter_best_quality(crashes,min_rank), "CRASH")  or pick_candidate(crashes,"CRASH")

  local start_track_idx = r.CountTracks(proj)

  local function create_track(name)
    r.InsertTrackAtIndex(start_track_idx, true)
    local tr = r.GetTrack(proj, start_track_idx)
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
    start_track_idx = start_track_idx + 1
    return tr
  end

  local tr_kick, tr_snare, tr_hat, tr_tomh, tr_tomm, tr_toml, tr_ride, tr_crash
  if kick_it then tr_kick   = create_track("DF95 Beat – Kick") end
  if snare_it then tr_snare = create_track("DF95 Beat – Snare") end
  if hat_it   then tr_hat   = create_track("DF95 Beat – Hat") end

  if use_ext then
    if th_it then tr_tomh   = create_track("DF95 Beat – Tom High") end
    if tm_it then tr_tomm   = create_track("DF95 Beat – Tom Mid") end
    if tl_it then tr_toml   = create_track("DF95 Beat – Tom Low") end
    if ride_it then tr_ride = create_track("DF95 Beat – Ride") end
    if crash_it then tr_crash = create_track("DF95 Beat – Crash") end
  end

  local spb = 60.0 / bpm
  local beats_per_bar = 4
  local total_beats = bars * beats_per_bar

  for b = 0, total_beats-1 do
    local t = b * spb
    local bar_pos = (b % beats_per_bar) + 1

    -- Kick
    if tr_kick and kick_it then
      local place = false
      if bar_pos == 1 or bar_pos == 3 then
        place = true
      else
        if math.random() < 0.2 then place = true end
      end
      if place then
        add_item_with_source(tr_kick, kick_it.path, t)
      end
    end

    -- Snare
    if tr_snare and snare_it then
      if bar_pos == 2 or bar_pos == 4 then
        add_item_with_source(tr_snare, snare_it.path, t)
      end
    end

    -- Hat (8tel)
    if tr_hat and hat_it then
      local t1 = t
      local t2 = t + spb * 0.5
      add_item_with_source(tr_hat, hat_it.path, t1)
      if math.random() < 0.8 then
        add_item_with_source(tr_hat, hat_it.path, t2)
      end
    end
  end

  -- Fills mit Toms + Crash/Ride am Ende von 2er/4er Phrasen
  if use_ext and (tr_tomh or tr_tomm or tr_toml or tr_crash or tr_ride) then
    local phrase_len_bars = 2
    local phrases = math.floor(bars / phrase_len_bars)
    for p = 0, phrases-1 do
      local phrase_start_bar = p * phrase_len_bars
      local fill_bar = phrase_start_bar + phrase_len_bars
      local fill_start_beats = (fill_bar - 1) * beats_per_bar
      local fill_start_time = fill_start_beats * spb

      -- Toms Fill (16tel)
      local steps = 8
      for i = 0, steps-1 do
        local tt = fill_start_time - spb + (i * (spb / steps))
        local choice_tom = nil
        local rtom = math.random()
        if rtom < 0.33 and tr_tomh and th_it then
          choice_tom = { tr = tr_tomh, it = th_it }
        elseif rtom < 0.66 and tr_tomm and tm_it then
          choice_tom = { tr = tr_tomm, it = tm_it }
        elseif tr_toml and tl_it then
          choice_tom = { tr = tr_toml, it = tl_it }
        end
        if choice_tom then
          add_item_with_source(choice_tom.tr, choice_tom.it.path, tt)
        end
      end

      -- Crash/Ride auf Downbeat der nächsten Phrase
      local downbeat_time = fill_start_beats * spb
      if tr_crash and crash_it then
        add_item_with_source(tr_crash, crash_it.path, downbeat_time)
      elseif tr_ride and ride_it then
        add_item_with_source(tr_ride, ride_it.path, downbeat_time)
      end
    end
  end

  r.Undo_EndBlock("DF95 AI Beat Generator", -1)
end

------------------------------------------------------------
-- Soundscape-Generator
------------------------------------------------------------

local DF95_TEXTURE_PRESETS = {
  {
    name = "Bathroom – Water Drone",
    desc = "Dusch-/Badezimmer-Wasseratmosphäre (Shower/Sink, WATER).",
    zone = "BATHROOM",
    material = "WATER",
    object_class = nil,
    ai_contains = "water",
  },
  {
    name = "Kitchen – Busy Ambience",
    desc = "Küchen-Atmo mit Geschirr/Besteck/Wasser.",
    zone = "KITCHEN",
    material = nil,
    object_class = "FOLEY",
    ai_contains = "",
  },
  {
    name = "Childroom – Playroom",
    desc = "Kinderzimmer-Spielatmo (Toys, Lego, Movement).",
    zone = "CHILDROOM",
    material = nil,
    object_class = "TOY",
    ai_contains = "",
  },
  {
    name = "Basement – Machines",
    desc = "Kellermaschinen (Waschmaschine, Trockner, Geräuschkulisse).",
    zone = "BASEMENT",
    material = nil,
    object_class = "APPLIANCE",
    ai_contains = "",
  },
  {
    name = "Hallway – Distant Rooms",
    desc = "Flur mit Türen, entfernten Räumen, Roomtone.",
    zone = "HALLWAY",
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  -- EMF / ELECTRIC Presets
  {
    name = "EMF – SOMA Sweep",
    desc = "Breite SOMA Ether Scans (ELECTRIC/EMF_SOMA).",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_SOMA",
  },
  {
    name = "EMF – Telephone Lines",
    desc = "Telephone Pick-Up Coil: Leitungen, Telefone, Basisstationen.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Telephone",
  },
  {
    name = "EMF – Devices & Chargers",
    desc = "Router, Laptop, Ladegeräte, Monitore (ELECTRIC/EMF_Devices).",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – Mixed Noise Bed",
    desc = "Gemischtes EMF-Bett aus allen EMF-Kategorien.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
  },
  -- Bedroom / Kids
  {
    name = "Bedroom – Night Quiet",
    desc = "Leise Nachtgeräusche: Bett, Decke, Zimmerbewegungen.",
    zone = "BEDROOM",
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  {
    name = "Kids – Asleep",
    desc = "Schlafende Kinder, ruhiges Rascheln, Raumton.",
    zone = "CHILDROOM",
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  -- Computer / Office EMF
  {
    name = "Computer Room – EMF",
    desc = "EMF von PC, Monitor, GPU, Router.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – Smartphone Idle",
    desc = "Smartphone im Standby: subtile EMF-/Polling-/Signalgeräusche.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "phone",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – WiFi Router Burst",
    desc = "Stärkere EMF-Spitzen von Router/WiFi/LAN-Geräten.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "router",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  {
    name = "EMF – Laptop Coil Whine",
    desc = "Hohe, feine EMF-/Elektronik-Fiepgeräusche (Laptops, GPUs, Netzteile).",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "computer",
    require_cat = "ELECTRIC",
    require_sub = "EMF_Devices",
  },
  -- Themes / Whole Apartment
  {
    name = "Whole Apartment – Night",
    desc = "Gesamte Wohnung nachts: leise Ambiences aus Schlafzimmer, Kinderzimmer, Flur, Wohnzimmer.",
    zones = {"BEDROOM","CHILDROOM","HALLWAY","LIVINGROOM"},
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
  {
    name = "Basement – Heavy Machines",
    desc = "Keller mit lauten Maschinen/Appliances (Waschmaschine, Trockner, etc.).",
    zone = "BASEMENT",
    material = nil,
    object_class = "APPLIANCE",
    ai_contains = "",
  },
  {
    name = "Urban – EMF Map",
    desc = "Städtische EMF-Karte: verschiedene EMF-Quellen gemischt.",
    zone = nil,
    material = "ELECTRIC",
    object_class = nil,
    ai_contains = "",
    require_cat = "ELECTRIC",
  },
  -- Generic
  {
    name = "Generic – Soft Ambience",
    desc = "Weiche Ambiences (Roomtone, leise Bewegungen).",
    zone = nil,
    material = nil,
    object_class = "AMBIENCE",
    ai_contains = "",
  },
}




local function generate_texture(db, items)
  -- Mode: MANUAL (freie Filter) oder PRESET (DF95_TEXTURE_PRESETS)
  local ok, vals = r.GetUserInputs(
    "DF95 AI Soundscape Generator (UCS-Light)",
    8,
    "Mode (MANUAL/PRESET),Dauer in Sekunden (z.B. 60),Anzahl Layer (z.B. 4),Min Quality Grade (A/B/C/D, leer=keine)," ..
    "Home Zone Filter (z.B. ANY/KITCHEN/BATHROOM/...)," ..
    "Material Filter (ANY/WOOD/METAL/PLASTIC/WATER/...)," ..
    "Object Class Filter (ANY/FOLEY/TOY/APPLIANCE/DRUM/AMBIENCE/...)," ..
    "AI-Label enthält (oder leer)",
    "MANUAL,60,4,,ANY,ANY,ANY,"
  )
  if not ok then return end

  local s_mode, s_dur, s_layers, s_grade, s_zone, s_mat, s_obj, s_ai =
    vals:match("([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")

  local mode = (s_mode or ""):upper()
  if mode ~= "MANUAL" and mode ~= "PRESET" then
    mode = "MANUAL"
  end

  local duration = tonumber(s_dur or "60") or 60
  if duration < 10 then duration = 10 end
  if duration > 1200 then duration = 1200 end

  local layers = tonumber(s_layers or "4") or 4
  if layers < 1 then layers = 1 end
  if layers > 16 then layers = 16 end

  local min_rank = grade_to_rank(s_grade)

  local textures = {}

  if mode == "PRESET" and DF95_TEXTURE_PRESETS then
    -- Zweiter Dialog: Preset-Auswahl
    local preset_labels = {}
    for i, p in ipairs(DF95_TEXTURE_PRESETS) do
      preset_labels[#preset_labels+1] = string.format("%d:%s", i, p.name)
    end

    local ok2, vals2 = r.GetUserInputs(
      "DF95 AI Soundscape Preset Mode",
      4,
      "Preset-Nummer ("..table.concat(preset_labels, " | ").."),Dauer in Sekunden,Layer,Min Quality Grade (A/B/C/D, leer=keine)",
      string.format("1,%d,%d,%s", duration, layers, s_grade or "")
    )
    if not ok2 then return end

    local s_idx, s_dur2, s_layers2, s_grade2 =
      vals2:match("([^,]*),([^,]*),([^,]*),([^,]*)")

    local idx = tonumber(s_idx or "1") or 1
    if idx < 1 then idx = 1 end
    if idx > #DF95_TEXTURE_PRESETS then idx = #DF95_TEXTURE_PRESETS end

    local preset = DF95_TEXTURE_PRESETS[idx]

    duration = tonumber(s_dur2 or tostring(duration)) or duration
    if duration < 10 then duration = 10 end
    if duration > 1200 then duration = 1200 end

    layers = tonumber(s_layers2 or tostring(layers)) or layers
    if layers < 1 then layers = 1 end
    if layers > 16 then layers = 16 end

    min_rank = grade_to_rank(s_grade2 ~= "" and s_grade2 or s_grade)

    local required_cat = preset.require_cat and upper(preset.require_cat)
    local required_sub = preset.require_sub and upper(preset.require_sub)

    for _, it in ipairs(items) do
      if it.path then
        if is_texture(it) then
          local rank = grade_to_rank(it.quality_grade)
          if rank >= min_rank then
            local ok_zone = true
            local ok_mat  = true
            local ok_obj  = true
            local ok_ai   = true
            local ok_cat  = true
            local ok_sub  = true

            if preset.zone then
              local hz = upper(it.home_zone or "")
              ok_zone = (hz:find(upper(preset.zone), 1, true) ~= nil)
            end
            if preset.zones then
              local hz = upper(it.home_zone or "")
              ok_zone = false
              for _, z in ipairs(preset.zones) do
                if hz:find(upper(z), 1, true) then
                  ok_zone = true
                  break
                end
              end
            end
            if preset.material then
              local mt = upper(it.material or "")
              ok_mat = (mt:find(upper(preset.material), 1, true) ~= nil)
            end
            if preset.object_class then
              local oc = upper(it.object_class or "")
              ok_obj = (oc:find(upper(preset.object_class), 1, true) ~= nil)
            end
            if preset.ai_contains and preset.ai_contains ~= "" then
              local ai = lower(it.ai_primary or "")
              ok_ai = (ai:find(lower(preset.ai_contains), 1, true) ~= nil)
            end
            if required_cat then
              local cat = upper(it.ucs_category or "")
              ok_cat = (cat:find(required_cat, 1, true) ~= nil)
            end
            if required_sub then
              local sub = upper(it.ucs_subcategory or "")
              ok_sub = (sub:find(required_sub, 1, true) ~= nil)
            end

            if ok_zone and ok_mat and ok_obj and ok_ai and ok_cat and ok_sub then
              textures[#textures+1] = it
            end
          end
        end
      end
    end
  else
    -- MANUAL Mode: alte Filterlogik
    local zone_filter = (s_zone or ""):upper()
    local mat_filter  = (s_mat  or ""):upper()
    local obj_filter  = (s_obj  or ""):upper()
    local ai_filter   = (s_ai   or ""):lower()

    if zone_filter == "" or zone_filter == "ANY" then zone_filter = nil end
    if mat_filter  == "" or mat_filter  == "ANY" then mat_filter  = nil end
    if obj_filter  == "" or obj_filter  == "ANY" then obj_filter  = nil end
    if ai_filter   == "" then ai_filter = nil end

    for _, it in ipairs(items) do
      if it.path then
        local rank = grade_to_rank(it.quality_grade)
        if rank >= min_rank then
          if is_texture(it) then
            local ok_zone = true
            local ok_mat  = true
            local ok_obj  = true
            local ok_ai   = true

            if zone_filter then
              local hz = (it.home_zone or ""):upper()
              ok_zone = (hz:find(zone_filter, 1, true) ~= nil)
            end
            if mat_filter then
              local mt = (it.material or ""):upper()
              ok_mat = (mt:find(mat_filter, 1, true) ~= nil)
            end
            if obj_filter then
              local oc = (it.object_class or ""):upper()
              ok_obj = (oc:find(obj_filter, 1, true) ~= nil)
            end
            if ai_filter then
              local ai = lower(it.ai_primary or "")
              ok_ai = (ai:find(ai_filter, 1, true) ~= nil)
            end

            if ok_zone and ok_mat and ok_obj and ok_ai then
              textures[#textures+1] = it
            end
          end
        end
      end
    end
  end

  if #textures == 0 then
    r.ShowMessageBox(
      "Keine Textur-Samples gefunden, die zu den Filtern passen.\n" ..
      "Bitte Scanner/Inspector/AI prüfen oder Filter lockern.",
      "DF95 AI Soundscape Generator (UCS-Light)",
      0
    )
    return
  end

  local proj = 0
  r.Undo_BeginBlock()

  local start_track_idx = r.CountTracks(proj)

  local function create_track(name)
    r.InsertTrackAtIndex(start_track_idx, true)
    local tr = r.GetTrack(proj, start_track_idx)
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
    start_track_idx = start_track_idx + 1
    return tr
  end

  for i = 1, layers do
    local it = choice(filter_best_quality(textures, min_rank)) or choice(textures)
    if it then
      local label = basename(it.path or "")
      if it.home_zone and it.home_zone ~= "" then
        label = "["..it.home_zone.."] "..label
      end
      local tr = create_track("DF95 Texture "..i.." – "..label)
      local pos = 0.0
      while pos < duration do
        local item, take, len = add_item_with_source(tr, it.path, pos)
        if not len or len <= 0 then
          break
        end
        local overlap = math.random() * 0.5
        local step = len * (1.0 - overlap)
        if step <= 0.01 then step = len end
        pos = pos + step
        if pos > duration then break end
      end
    end
  end

  r.Undo_EndBlock("DF95 AI Soundscape Generator (UCS-Light)", -1)
end
end


------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  math.randomseed(os.time())

  local db_path = get_db_path()
  local f = io.open(db_path, "r")
  if not f then
    r.ShowMessageBox(
      "JSON-Datenbank nicht gefunden:\n"..db_path..
      "\n\nBitte zuerst den DF95 SampleDB Scanner ausführen.",
      "DF95 AI Beat & Soundscape Generator",
      0
    )
    return
  end

  local text = f:read("*all")
  f:close()

  local db, err = decode_json(text)
  if not db then
    r.ShowMessageBox(
      "Fehler beim Lesen der JSON-Datenbank:\n"..tostring(err),
      "DF95 AI Beat & Soundscape Generator",
      0
    )
    return
  end

  local items = db.items or {}
  if #items == 0 then
    r.ShowMessageBox(
      "Die JSON-Datenbank enthält keine Items.\n"..db_path,
      "DF95 AI Beat & Soundscape Generator",
      0
    )
    return
  end

  local ok, mode = r.GetUserInputs(
    "DF95 AI Beat & Soundscape Generator",
    1,
    "Mode (BEAT oder TEXTURE)",
    "BEAT"
  )
  if not ok then return end

  mode = (mode or ""):upper()
  if mode == "BEAT" then
    generate_beat(db, items)
  elseif mode == "TEXTURE" then
    generate_texture(db, items)
  else
    r.ShowMessageBox(
      "Ungültiger Mode: "..tostring(mode).."\nBitte BEAT oder TEXTURE eingeben.",
      "DF95 AI Beat & Soundscape Generator",
      0
    )
  end
end

main()
