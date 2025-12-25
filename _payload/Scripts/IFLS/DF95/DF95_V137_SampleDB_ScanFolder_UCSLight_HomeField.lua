-- @description DF95_V137 SampleDB – Scan Folder (UCS-Light Home Field) and build Multi-UCS DB
-- @version 1.0
-- @author DF95
-- @about
--   Scannt einen oder mehrere Basis-Ordner mit WAV/AIFF-Dateien (Home Field Recording:
--   Küche, Wohnzimmer, Bad, Kinderzimmer, Keller, Drums, etc.) und erstellt eine
--   Multi-UCS-Datenbank im DF95-Format:
--
--       <REAPER>/Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
--
--   Es nutzt eine "UCS-Light"-Taxonomie, optimiert für Home/Foley/Drums:
--     * ucs_category       (z.B. KITCHEN, BATHROOM, DRUMS, TOYS, ...)
--     * ucs_subcategory    (z.B. Dishes_Handling, Shower, Kick, Snare, ...)
--     * df95_catid         (sanitisierter CatID z.B. KITCHEN_Dishes_Handling)
--     * home_zone          (KITCHEN, LIVINGROOM, BEDROOM, CHILDROOM, HALLWAY, BASEMENT, WORKROOM)
--     * material           (WOOD, METAL, PLASTIC, GLASS, WATER, FABRIC, PAPER, STONE, ELECTRIC, MIXED)
--     * object_class       (FOLEY, APPLIANCE, TOY, VEHICLE, DRUM, INSTRUMENT, AMBIENCE, MECHANICAL, IMPACT)
--     * action             (OPEN, CLOSE, STEP, MOVE, DROP, TURN, SWITCH, HIT, SCRAPE, RATTLE, FLOW, POUR, ...)
--
--   Diese Felder sind heuristisch und können später durch AI/Mappings (YAMNet,
--   Inspector V4, etc.) verfeinert werden. Ziel ist ein strukturierter Startpunkt
--   für deine gesamte Haus-/Field-Recording-Library.
--
--   Hinweis:
--     * Dieser Scanner ersetzt NICHT deine AI-Tools – er ergänzt sie mit
--       Domain-Wissen über Räume, Materialien und typische Home-/Drum-Situationen.
--     * Die JSON kann jederzeit von den anderen DF95 Tools (Inspector V4,
--       UCS Renamer, VEED Engine, Beat/Soundscape Generator) genutzt werden.

local r = reaper

------------------------------------------------------------
-- Basic helpers
------------------------------------------------------------

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_db_path()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return dir, join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function ensure_dir(path)
  local attr = r.GetFileAttributes and r.GetFileAttributes(path)
  if attr then return true end
  if sep == "\\" then
    os.execute(string.format('mkdir "%s"', path))
  else
    os.execute(string.format('mkdir -p "%s"', path))
  end
end

local function basename(path)
  return (path or ""):match("([^"..sep.."]+)$") or path
end

local function dirname(path)
  if not path then return "" end
  local dir = path:match("^(.*"..sep..")")
  if dir then
    if dir:sub(-1) == sep then
      dir = dir:sub(1,-2)
    end
    return dir
  end
  return ""
end

local function split_ext(name)
  local base, ext = name:match("^(.*)(%.[^%.]+)$")
  if not base then
    return name, ""
  end
  return base, ext
end

local function lower(s) return (s or ""):lower() end
local function upper(s) return (s or ""):upper() end

local function contains_any(str, list)
  str = lower(str or "")
  for _, token in ipairs(list) do
    if str:find(lower(token), 1, true) then
      return true
    end
  end
  return false
end

local function sanitize_token(s, max_len)
  s = s or ""
  s = s:gsub("[^%w]+", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_", ""):gsub("_$", "")
  max_len = max_len or 24
  if #s > max_len then
    s = s:sub(1, max_len)
  end
  if s == "" then s = "GEN" end
  return s
end

------------------------------------------------------------
-- JSON encoder (simple, array/object detection)
------------------------------------------------------------

local function json_escape(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  return str
end

local function json_encode_value(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then
    return "\"" .. json_escape(v) .. "\""
  elseif t == "number" then
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    return json_encode_table(v, indent)
  else
    return "null"
  end
end

function json_encode_table(t, indent)
  indent = indent or ""
  local next_indent = indent .. "  "
  local is_array = (#t > 0)
  local parts = {}

  if is_array then
    table.insert(parts, "[\n")
    for i = 1, #t do
      table.insert(parts, next_indent .. json_encode_value(t[i], next_indent))
      if i < #t then
        table.insert(parts, ",\n")
      else
        table.insert(parts, "\n")
      end
    end
    table.insert(parts, indent .. "]")
  else
    table.insert(parts, "{\n")
    local first = true
    for k, v in pairs(t) do
      if not first then
        table.insert(parts, ",\n")
      end
      first = false
      table.insert(parts, next_indent .. "\"" .. json_escape(k) .. "\": " .. json_encode_value(v, next_indent))
    end
    table.insert(parts, "\n" .. indent .. "}")
  end

  return table.concat(parts)
end

------------------------------------------------------------
-- Audio info
------------------------------------------------------------

local function get_wav_info(path)
  local src = r.PCM_Source_CreateFromFile(path)
  if not src then return nil end

  local len = r.GetMediaSourceLength(src)
  local takepcm = r.GetMediaSourceSampleRate(src)
  local ch = r.GetMediaSourceNumChannels(src)

  r.PCM_Source_Destroy(src)

  return {
    length = len or 0,
    samplerate = takepcm or 0,
    channels = ch or 0,
  }
end

------------------------------------------------------------
-- Folder enumeration
------------------------------------------------------------

local function enum_files_recursive(base_dir, out_list)
  out_list = out_list or {}
  local idx = 0
  while true do
    local fname = r.EnumerateFiles(base_dir, idx)
    if not fname then break end
    local full = join_path(base_dir, fname)
    table.insert(out_list, full)
    idx = idx + 1
  end
  local didx = 0
  while true do
    local sub = r.EnumerateSubdirectories(base_dir, didx)
    if not sub then break end
    local fullsub = join_path(base_dir, sub)
    enum_files_recursive(fullsub, out_list)
    didx = didx + 1
  end
  return out_list
end

------------------------------------------------------------
-- Stufe 9: UCS-Light Home Field Classification
------------------------------------------------------------

local function classify_home_zone(path_components)
  local joined = " " .. table.concat(path_components, " ") .. " "
  joined = lower(joined)

  if joined:find("küche") or joined:find("kueche") or joined:find("kitchen") then
    return "KITCHEN"
  end
  if joined:find("bad") or joined:find("bath") or joined:find("bathroom") or joined:find("dusche") then
    return "BATHROOM"
  end
  if joined:find("wohnzimmer") or joined:find("living") or joined:find("livingroom") then
    return "LIVINGROOM"
  end
  if joined:find("schlafzimmer") or joined:find("bedroom") then
    return "BEDROOM"
  end
  if joined:find("kinderzimmer") or joined:find("child") or joined:find("kids") then
    return "CHILDROOM"
  end
  if joined:find("flur") or joined:find("hallway") or joined:find("gang") then
    return "HALLWAY"
  end
  if joined:find("keller") or joined:find("basement") then
    return "BASEMENT"
  end
  if joined:find("arbeitszimmer") or joined:find("workroom") or joined:find("office") then
    return "WORKROOM"
  end

  return nil
end

local function classify_material(name, components)
  local s = lower(name .. " " .. table.concat(components, " "))

  if contains_any(s, {"metal", "metall", "stahl", "eisen"}) then return "METAL" end
  if contains_any(s, {"wood", "holz", "parkett"}) then return "WOOD" end
  if contains_any(s, {"plastik", "plastic", "kunststoff"}) then return "PLASTIC" end
  if contains_any(s, {"glas", "glass"}) then return "GLASS" end
  if contains_any(s, {"stein", "stone", "beton", "concrete"}) then return "STONE" end
  if contains_any(s, {"paper", "papier", "pappe", "cardboard"}) then return "PAPER" end
  if contains_any(s, {"cloth", "kleidung", "shirt", "pants", "stoff", "fabric", "towel"}) then return "FABRIC" end
  if contains_any(s, {"wasser", "water", "rain", "regen", "shower", "sink", "tap"}) then return "WATER" end
  if contains_any(s, {"electric", "fan", "motor", "engine", "elektro", "soma", "ether", "emf"}) then return "ELECTRIC" end

  return "MIXED"
end


local function classify_emf(name, components)
  local s = lower(name .. " " .. table.concat(components or {}, " "))
  -- SOMA Ether, EMF, Radio Noise, Telephone Coil etc.
  if contains_any(s, {"soma", "ether", "emf", "electrosmog", "rf_", "radio_noise", "radio-noise", "induction", "pickup", "pickup_coil"}) then
    if contains_any(s, {"phone", "telefon", "handset", "line"}) then
      return "ELECTRIC", "EMF_Telephone"
    elseif contains_any(s, {"router", "laptop", "monitor", "screen", "netzteil", "adapter", "charger"}) then
      return "ELECTRIC", "EMF_Devices"
    else
      return "ELECTRIC", "EMF_SOMA"
    end
  end
  if contains_any(s, {"telephone_coil", "pickup_coil", "pick-up_coil", "induction"}) then
    return "ELECTRIC", "EMF_Telephone"
  end
  return nil, nil
end

local function classify_object_class(name, components)
  local s = lower(name .. " " .. table.concat(components, " "))

  if contains_any(s, {"kick", "snare", "hihat", "tom", "ride", "crash", "cymbal", "drum"}) then
    return "DRUM"
  end
  if contains_any(s, {"guitar", "piano", "violin", "synth", "instrument"}) then
    return "INSTRUMENT"
  end
  if contains_any(s, {"bike", "bicycle", "fahrrad", "roller", "scooter", "laufrad"}) then
    return "VEHICLE"
  end
  if contains_any(s, {"toy", "spielzeug", "lego", "duplo", "rattle"}) then
    return "TOY"
  end
  if contains_any(s, {"washing", "washer", "waschmaschine", "dryer", "trockner", "dishwasher", "spülmaschine", "spuelmaschine"}) then
    return "APPLIANCE"
  end
  if contains_any(s, {"roomtone", "ambience", "atmo", "atmosphere"}) then
    return "AMBIENCE"
  end
  if contains_any(s, {"whoosh", "swoosh", "air", "wind"}) then
    return "MECHANICAL"
  end
  if contains_any(s, {"switch", "button", "click"}) then
    return "FOLEY"
  end

  return "FOLEY"
end

local function classify_action(name)
  local s = lower(name)

  if contains_any(s, {"open", "auf", "öffnen", "oeffnen"}) then return "OPEN" end
  if contains_any(s, {"close", "zu", "schließen", "schliessen"}) then return "CLOSE" end
  if contains_any(s, {"step", "tritt", "footstep", "laufen", "gehen"}) then return "STEP" end
  if contains_any(s, {"drop", "fallen", "fall", "werfen"}) then return "DROP" end
  if contains_any(s, {"hit", "schlag", "impact", "kick"}) then return "HIT" end
  if contains_any(s, {"scrape", "kratzen", "schaben"}) then return "SCRAPE" end
  if contains_any(s, {"rattle", "klapper", "rassel"}) then return "RATTLE" end
  if contains_any(s, {"switch", "button", "click"}) then return "SWITCH" end
  if contains_any(s, {"pour", "gießen", "giessen"}) then return "POUR" end
  if contains_any(s, {"flow", "strömen", "laufen"}) then return "FLOW" end
  if contains_any(s, {"move", "move", "schieben"}) then return "MOVE" end

  return nil
end

local function classify_drums_sub(name)
  local s = lower(name)

  if contains_any(s, {"kick", "bd", "bassdrum"}) then return "Kick" end
  if contains_any(s, {"snare", "sd", "snr"}) then return "Snare" end
  if contains_any(s, {"hihat", "hi_hat", "hh"}) then return "HiHat" end
  if contains_any(s, {"tom1", "tom_high", "hightom"}) then return "TomHigh" end
  if contains_any(s, {"tom2", "tom_mid", "midtomo"}) then return "TomMid" end
  if contains_any(s, {"floor", "floortom", "tom_low"}) then return "TomLow" end
  if contains_any(s, {"ride"}) then return "Ride" end
  if contains_any(s, {"crash"}) then return "Crash" end
  if contains_any(s, {"china"}) then return "China" end
  if contains_any(s, {"splash"}) then return "Splash" end
  if contains_any(s, {"rim", "sidestick"}) then return "Rimshot" end

  return nil
end

local function classify_kitchen_sub(name)
  local s = lower(name)
  if contains_any(s, {"plate", "teller", "geschirr", "dishes"}) then return "Dishes_Handling" end
  if contains_any(s, {"cutlery", "besteck", "fork", "knife", "spoon"}) then return "Cutlery" end
  if contains_any(s, {"pot", "topf"}) then return "Pots" end
  if contains_any(s, {"pan", "pfanne"}) then return "Pans" end
  if contains_any(s, {"drawer", "schublade"}) then return "Drawer" end
  if contains_any(s, {"fridge", "kühlschrank", "kuehlschrank"}) then return "Fridge" end
  if contains_any(s, {"microwave", "mikrowelle"}) then return "Microwave" end
  if contains_any(s, {"sink", "spüle", "spuele"}) then return "Sink" end
  if contains_any(s, {"tap", "wasserhahn"}) then return "Tap" end
  if contains_any(s, {"kettle", "wasserkocher"}) then return "Kettle" end
  if contains_any(s, {"coffee", "kaffee"}) then return "CoffeeMachine" end
  return nil
end

local function classify_bathroom_sub(name)
  local s = lower(name)
  if contains_any(s, {"shower", "dusche"}) then return "Shower" end
  if contains_any(s, {"sink", "waschbecken"}) then return "Sink" end
  if contains_any(s, {"toilet", "klo", "wc"}) then return "Toilet" end
  if contains_any(s, {"towel", "handtuch"}) then return "Towel" end
  if contains_any(s, {"toothbrush", "zahnbürste", "zahnbuerste"}) then return "Toothbrush" end
  if contains_any(s, {"cabinet", "schrank"}) then return "Cabinet" end
  if contains_any(s, {"hairdryer", "foehn", "föhn"}) then return "Hairdryer" end
  return nil
end

local function classify_childroom_sub(name)
  local s = lower(name)
  if contains_any(s, {"toy", "spielzeug"}) then return "Toys" end
  if contains_any(s, {"lego", "duplo"}) then return "Lego" end
  if contains_any(s, {"ball"}) then return "Ball" end
  if contains_any(s, {"rattle", "rassel"}) then return "Rattle" end
  if contains_any(s, {"soft", "pluesch", "plüsch", "stuffed"}) then return "SoftToys" end
  if contains_any(s, {"baby", "crib", "gitterbett"}) then return "BabyBed" end
  return nil
end

local function classify_basement_sub(name)
  local s = lower(name)
  if contains_any(s, {"bike", "bicycle", "fahrrad"}) then return "Bicycle" end
  if contains_any(s, {"laufrad", "balance"}) then return "BalanceBike" end
  if contains_any(s, {"scooter", "roller"}) then return "Scooter" end
  if contains_any(s, {"washing", "waschmaschine"}) then return "WashingMachine" end
  if contains_any(s, {"dryer", "trockner"}) then return "Dryer" end
  if contains_any(s, {"tool", "werkzeug"}) then return "Tools" end
  return nil
end


local function derive_ucs(path)
  local base = basename(path)
  local base_noext = split_ext(base)
  local dir = dirname(path)

  -- Path-Komponenten (Ordnernamen) sammeln
  local comps = {}
  for part in dir:gmatch("[^"..sep.."]+") do
    comps[#comps+1] = part
  end

  local zone = classify_home_zone(comps)
  local name = base_noext

  local mat  = classify_material(name, comps)
  local ocls = classify_object_class(name, comps)

  local ucs_cat = nil
  local ucs_sub = nil

  -- EMF / ELECTRIC zuerst (SOMA, Telephone Coil, EMF)
  local emf_cat, emf_sub = classify_emf(name, comps)
  if emf_cat then
    ucs_cat = emf_cat
    ucs_sub = emf_sub or "EMF_Generic"
  end

  -- Drums (nur, wenn nicht schon EMF)
  if not ucs_cat then
    local drum_sub = classify_drums_sub(name)
    if drum_sub then
      ucs_cat = "DRUMS"
      ucs_sub = drum_sub
    end
  end

  -- Home-Zonen-spezifische Kategorien
  if not ucs_cat and zone == "KITCHEN" then
    ucs_cat = "KITCHEN"
    ucs_sub = classify_kitchen_sub(name) or "General"
  elseif not ucs_cat and zone == "BATHROOM" then
    ucs_cat = "BATHROOM"
    ucs_sub = classify_bathroom_sub(name) or "General"
  elseif not ucs_cat and zone == "CHILDROOM" then
    ucs_cat = "CHILDROOM"
    ucs_sub = classify_childroom_sub(name) or "General"
  elseif not ucs_cat and zone == "BASEMENT" then
    ucs_cat = "BASEMENT"
    ucs_sub = classify_basement_sub(name) or "General"
  elseif not ucs_cat and zone ~= nil then
    ucs_cat = zone
    ucs_sub = "General"
  end

  -- Fallback auf Object-Class
  if not ucs_cat then
    if ocls == "DRUM" then
      ucs_cat = "DRUMS"
      ucs_sub = ucs_sub or "General"
    elseif ocls == "APPLIANCE" then
      ucs_cat = "APPLIANCES"
      ucs_sub = "General"
    elseif ocls == "TOY" then
      ucs_cat = "TOYS"
      ucs_sub = "General"
    elseif ocls == "VEHICLE" then
      ucs_cat = "VEHICLES"
      ucs_sub = "General"
    elseif ocls == "INSTRUMENT" then
      ucs_cat = "MUSIC_INSTRUMENTS"
      ucs_sub = "General"
    elseif ocls == "AMBIENCE" then
      ucs_cat = "AMBIENCE"
      ucs_sub = "General"
    elseif ocls == "MECHANICAL" then
      ucs_cat = "MECHANICAL"
      ucs_sub = "General"
    else
      ucs_cat = "FOLEY"
      ucs_sub = "General"
    end
  end

  local catid = sanitize_token((ucs_cat or "MISC") .. "_" .. (ucs_sub or "General"), 32)

  return {
    ucs_category    = ucs_cat,
    ucs_subcategory = ucs_sub,
    df95_catid      = catid,
    home_zone       = zone,
    material        = mat,
    object_class    = ocls,
    action          = classify_action(name),
  }
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local ok, vals = r.GetUserInputs(
    "DF95 SampleDB – Scan (UCS-Light Home Field)",
    2,
    "Basis-Ordner (oder mehrere, mit ; getrennt),Nur WAV/AIFF? (YES/NO)",
    "C:\\FieldRec_Home;D:\\ZoomF6_Home,YES"
  )
  if not ok then return end

  local s_dirs, s_wav = vals:match("([^,]*),([^,]*)")
  s_dirs = (s_dirs or ""):gsub("^%s+",""):gsub("%s+$","")
  s_wav  = (s_wav  or ""):upper()

  if s_dirs == "" then
    r.ShowMessageBox("Bitte mindestens einen Basis-Ordner angeben.", "DF95 SampleDB – Scan (UCS-Light)", 0)
    return
  end

  local only_wav = (s_wav ~= "NO")

  local dirs = {}
  for part in s_dirs:gmatch("[^;]+") do
    part = part:gsub("^%s+",""):gsub("%s+$","")
    if part ~= "" then
      dirs[#dirs+1] = part
    end
  end

  if #dirs == 0 then
    r.ShowMessageBox("Keine gültigen Ordner gefunden (Trennung mit ;).", "DF95 SampleDB – Scan (UCS-Light)", 0)
    return
  end

  local all_files = {}
  for _, d in ipairs(dirs) do
    local attr = r.GetFileAttributes and r.GetFileAttributes(d)
    if attr then
      enum_files_recursive(d, all_files)
    end
  end

  if #all_files == 0 then
    r.ShowMessageBox("Keine Dateien in den angegebenen Ordnern gefunden.", "DF95 SampleDB – Scan (UCS-Light)", 0)
    return
  end

  local items = {}
  for _, p in ipairs(all_files) do
    local base = basename(p)
    local name_noext, ext = split_ext(base)
    local ext_lower = lower(ext)
    if (not only_wav) or ext_lower == ".wav" or ext_lower == ".aif" or ext_lower == ".aiff" or ext_lower == ".flac" then
      local info = get_wav_info(p)
      if info then
        local ucs = derive_ucs(p)
        items[#items+1] = {
          path          = p,
          ucs_category  = ucs.ucs_category,
          ucs_subcategory = ucs.ucs_subcategory,
          df95_catid    = ucs.df95_catid,
          home_zone     = ucs.home_zone,
          material      = ucs.material,
          object_class  = ucs.object_class,
          action        = ucs.action,
          length_sec    = info.length,
          samplerate    = info.samplerate,
          channels      = info.channels,
        }
      end
    end
  end

  local db_dir, db_path = get_db_path()
  ensure_dir(db_dir)

  local db = {
    version = "DF95_MultiUCS_Stufe9",
    created = os.date("%Y-%m-%d %H:%M:%S"),
    items   = items,
  }

  local f = io.open(db_path, "w")
  if not f then
    r.ShowMessageBox("Kann DB-Datei nicht schreiben:\n"..db_path, "DF95 SampleDB – Scan (UCS-Light)", 0)
    return
  end
  f:write(json_encode_table(db, ""))
  f:close()

  r.ShowMessageBox(
    string.format("Scan abgeschlossen.\nErkannte Items: %d\nDB: %s", #items, db_path),
    "DF95 SampleDB – Scan (UCS-Light)",
    0
  )
end

main()
