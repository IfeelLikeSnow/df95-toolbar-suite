-- @description Metadata Core (Plugin DB & Classifier) v2.3
-- @version 2.3
-- @author DF95
-- @about
--   Liest reaper-vstplugins64.ini und reaper-fxtags.ini ein
--   und baut eine Plugin-Datenbank mit:
--     • Name, Format, Instrument/Effekt
--     • Developer, Kategorie
--     • abgeleitetem "role" (EQ, Comp, Limiter, Tape, etc.)
--     • reichhaltigen Tags für IDM/Tape/Granular/Experimental

local r = reaper
local DF95Meta = {}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local sep = package.config:sub(1,1)
local function join(...)
  local t = {...}
  return table.concat(t, sep)
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$",""))
end

------------------------------------------------------------
-- VSTCACHE PARSER (reaper-vstplugins64.ini)
------------------------------------------------------------

local function parse_vstplugins64(path)
  local plugins = {}
  if not file_exists(path) then return plugins end
  local in_cache = false
  for line in io.lines(path) do
    line = trim(line)
    if line == "" or line:sub(1,1) == ";" then
      -- ignore
    elseif line:match("^%[vstcache%]") then
      in_cache = true
    elseif in_cache then
      if line:sub(1,1) == "[" then
        break
      end
      local file, hex, intid, name = line:match("^([^=]+)=([^,]*),([^,]*),(.+)$")
      if file and name then
        local is_instr = false
        if name:find("!!!VSTi") then
          is_instr = true
          name = trim(name:gsub("!!!VSTi",""))
        end
        plugins[file] = {
          file = file,
          hex_id = hex,
          int_id = tonumber(intid) or intid,
          name = name,
          is_instrument = is_instr,
        }
      end
    end
  end
  return plugins
end

------------------------------------------------------------
-- FXTAGS PARSER (reaper-fxtags.ini)
------------------------------------------------------------

local function parse_fxtags(path)
  local dev, cat = {}, {}
  if not file_exists(path) then return dev, cat end
  local section = nil
  for line in io.lines(path) do
    line = trim(line)
    if line == "" or line:sub(1,1) == ";" then
    elseif line:match("^%[developer%]") then
      section = "developer"
    elseif line:match("^%[category%]") then
      section = "category"
    elseif line:sub(1,1) == "[" then
      section = nil
    elseif section == "developer" then
      local file, d = line:match("^([^=]+)=(.*)$")
      if file and d and d ~= "" then dev[file] = d end
    elseif section == "category" then
      local file, c = line:match("^([^=]+)=(.*)$")
      if file and c and c ~= "" then cat[file] = c end
    end
  end
  return dev, cat
end

------------------------------------------------------------
-- ROLE HEURISTIK
------------------------------------------------------------

local function derive_role(name, category, developer, file)
  local n = (name or ""):lower()
  local c = (category or ""):lower()
  local d = (developer or ""):lower()
  local f = (file or ""):lower()

  if c:find("eq") or n:find(" eq") or n:find("equal") or n:find("parametric") then
    return "EQ"
  end
  if c:find("dynamics") or c:find("compress") or n:find("compressor") then
    if n:find("limit") or n:find("maxim") or n:find("brickwall") then
      return "Limiter"
    else
      return "Compressor"
    end
  end
  if c:find("gate") or n:find("gate") then
    return "Gate/Expander"
  end
  if c:find("reverb") or n:find("reverb") or n:find("hall") or n:find("plate") then
    return "Reverb"
  end
  if c:find("delay") or n:find("delay") or n:find("echo") then
    return "Delay"
  end
  if c:find("analy") or c:find("meter") or n:find("analy") or n:find("meter") or n:find("scope") then
    return "Analyzer/Meter"
  end
  if c:find("saturat") or c:find("distort") or c:find("clip") or n:find("drive") or n:find("dist") or n:find("saturat") then
    return "Saturation/Distortion"
  end
  if c:find("generator") or c:find("synth") or n:find("synth") or n:find("drum machine") then
    return "Synth/Instrument"
  end
  if c:find("filter") and not c:find("eq") then
    return "Filter"
  end
  if c:find("master") then
    return "Mastering"
  end
  if n:find("tape") or n:find("cassette") or n:find("vinyl") or n:find("lo[%s%-]?fi") then
    return "Tape/LoFi"
  end
  if n:find("transient") then
    return "Transient"
  end
  if n:find("chorus") or n:find("flanger") or n:find("phaser") then
    return "Modulation"
  end
  if n:find("pan") or n:find("stereo") or n:find("imager") or n:find("binaural") then
    return "Stereo/Spatial"
  end
  if n:find("channel") or n:find("console") then
    return "ChannelStrip"
  end
  return "Other"
end

------------------------------------------------------------
-- TAG HEURISTIK v2.3 (IDM, Tape, Granular, usw.)
------------------------------------------------------------

local function derive_tags(name, category, developer, file)
  local tags = {}
  local function add(tag)
    for _,t in ipairs(tags) do if t == tag then return end end
    table.insert(tags, tag)
  end

  local n = (name or ""):lower()
  local c = (category or ""):lower()
  local d = (developer or ""):lower()
  local f = (file or ""):lower()

  ------------------------------------------------
  -- MASTERING / METERING / UTILITY
  ------------------------------------------------
  if c:find("master") or n:find("masterdesk") or n:find("true peak")
     or n:find("limiter") then
    add("MASTERING")
  end

  if c:find("analy") or n:find("spectrum") or n:find("span")
     or n:find("vision 4x") or n:find("loudness") or n:find("imager")
     or n:find("vectorscope") or n:find("scope") then
    add("METERING")
  end

  if c:find("tools") or c:find("utility") or n:find("tool") or n:find("gain") or n:find("mono") then
    add("UTILITY")
  end

  if n:find("basslane") or n:find("lowend") then
    add("LOWEND_CONTROL")
  end

  ------------------------------------------------
  -- TAPE / LOFI / BoC
  ------------------------------------------------
  if n:find("tape") or n:find("cassette") or n:find("warble")
     or n:find("wow") or n:find("flutter") or n:find("vinyl")
     or n:find("lo[%s%-]?fi") or n:find("vhs") then
    add("TAPE_LOFI")
  end

  if d:find("caelum") or n:find("cassette") then
    add("TAPE_LOFI"); add("BOC_TAPE")
  end

  if d:find("chow") and n:find("tape") then
    add("TAPE_LOFI"); add("IDM_GRIT")
  end

  if d:find("neold") and n:find("warble") then
    add("TAPE_LOFI"); add("BOC_TAPE"); add("IDM_MOVEMENT")
  end

  if d:find("evil") and (n:find("okair2r") or n:find("oldcomms")) then
    add("TAPE_LOFI")
    if n:find("oldcomms") then add("LOFI_BANDLIMIT") end
  end

  if d:find("klevgrand") and (n:find("cassette") or n:find("sketch")) then
    add("TAPE_LOFI"); add("BOC_TAPE")
    if n:find("sketch") then add("LOFI_BANDLIMIT") end
  end

  ------------------------------------------------
  -- IDM / GLITCH / BUFFER / CHAOS / MOVEMENT
  ------------------------------------------------
  if d:find("glitchmachines") then
    add("IDM_GLITCH"); add("IDM_BUFFER"); add("IDM_CHAOS")
  end

  if d:find("audiomodern") then
    add("IDM_MOVEMENT")
    if n:find("filterstep") then add("IDM_GLITCH"); add("MULTI_FX_RHYTHMIC") end
    if n:find("panflow") then add("IDM_GLITCH") end
  end

  if d:find("noise engineering") or n:find("ruina") then
    add("IDM_CHAOS"); add("DISTORTION")
  end

  if d:find("kilohearts") then
    add("IDM_GLITCH")
    if n:find("tape stop") then add("TAPE_LOFI"); add("IDM_BUFFER") end
    if n:find("resonator") then add("IDM_RESONATOR") end
    if n:find("trance gate") or n:find("gate") then add("IDM_MOVEMENT") end
  end

  if n:find("fracture") or n:find("cryogen") or n:find("subvert")
     or n:find("quadrant") or n:find("hysteresis") then
    add("IDM_GLITCH"); add("IDM_BUFFER")
    if n:find("subvert") then add("DISTORTION"); add("IDM_CHAOS"); add("MULTIBAND_DISTORTION") end
    if n:find("hysteresis") then add("DELAY_CREATIVE"); add("IDM_MOVEMENT") end
  end

  if n:find("glitch") or n:find("stutter") or n:find("crusher")
     or n:find("bitcrush") then
    add("IDM_GLITCH")
  end

  if n:find("tantra") then
    add("IDM_MOVEMENT"); add("IDM_GLITCH"); add("MULTI_FX_RHYTHMIC")
  end

  if n:find("ott") then
    add("IDM_CHAOS"); add("MULTIBAND_COMP")
  end

  if n:find("trash") then
    add("IDM_CHAOS"); add("IDM_GLITCH"); add("DISTORTION")
  end

  if n:find("panflow") then
    add("IDM_MOVEMENT"); add("IDM_GLITCH")
  end

  if n:find("filterstep") then
    add("IDM_MOVEMENT"); add("IDM_GLITCH"); add("FILTER_RHYTHMIC")
  end

  -- Krush, Cramit, GSat+
  if n:find("krush") then
    add("IDM_GLITCH"); add("IDM_GRIT"); add("DISTORTION")
  end

  if n:find("cramit") then
    add("IDM_CHAOS"); add("MULTIBAND_COMP"); add("IDM_GLITCH")
  end

  if n:find("gsat%+") or n:find("gsat") then
    add("DISTORTION"); add("IDM_GRIT"); add("SATURATION")
  end

  -- Valhalla Supermassive / Freq Echo / Space Modulator
  if n:find("supermassive") then
    add("IDM_GRANULAR"); add("REVERB_SPECIAL"); add("TEXTURE")
  end

  if n:find("freq echo") or n:find("frequecho") then
    add("IDM_CHAOS"); add("IDM_GLITCH"); add("MODULATION")
  end

  if n:find("space modulator") or n:find("spacemodulator") then
    add("MODULATION"); add("FLANGER"); add("CHORUS"); add("IDM_MOVEMENT"); add("TEXTURE"); add("REVERB_SPECIAL")
  end

  -- FeenstaubHDR
  if n:find("feenstaub") then
    add("MASTERING"); add("DISTORTION"); add("IDM_GRIT")
  end

  -- Unfiltered Audio Fault / Zip / BYOME / TRIAD
  if d:find("unfiltered audio") or n:find("fault") or n:find("zip") or n:find("byome") or n:find("triad") then
    add("IDM_CHAOS")
  end

  if n:find("fault") then
    add("IDM_GLITCH"); add("MODULATION")
  end

  if n:find("zip") then
    add("MULTIBAND_COMP"); add("IDM_MOVEMENT")
  end

  if n:find("byome") then
    add("MODULAR_FX"); add("IDM_MOVEMENT"); add("TEXTURE")
  end

  if n:find("triad") then
    add("MULTIBAND_MOD"); add("IDM_MOVEMENT"); add("TEXTURE")
  end

  -- Replika / Deelay
  if n:find("replika") then
    add("DELAY_CREATIVE"); add("IDM_MOVEMENT")
  end

  if n:find("deelay") then
    add("REVERB_SPECIAL"); add("IDM_MOVEMENT"); add("IDM_CHAOS")
  end

  -- Freakshow Backmask
  if d:find("freakshow") or n:find("backmask") then
    add("IDM_GLITCH"); add("IDM_CHAOS"); add("IDM_BUFFER")
  end

  -- RoughRider3 (Audio Damage) – Character Drum Compressor
  if n:find("roughrider") or n:find("rough rider") then
    add("DRUM_FX"); add("IDM_GRIT"); add("IDM_MOVEMENT"); add("CHARACTER_COMP")
  end

  ------------------------------------------------
  -- GRANULAR / SPECTRAL / TEXTURE / MORPH
  ------------------------------------------------
  if n:find("emergence") then
    add("IDM_GRANULAR"); add("TEXTURE")
  end

  if n:find("paulxstretch") or n:find("paul x stretch") then
    add("IDM_GRANULAR"); add("TEXTURE")
  end

  if n:find("grain") or n:find("granular") then
    add("IDM_GRANULAR")
  end

  if n:find("fogpad") then
    add("IDM_GRANULAR"); add("REVERB_SPECIAL")
  end

  if d:find("strangeloops") or n:find("grainbow") or (n:find("gra") and n:find("rainbow")) then
    add("IDM_GRANULAR"); add("TEXTURE"); add("IDM_MOVEMENT")
  end

  if n:find("portal") then
    add("IDM_GRANULAR"); add("TEXTURE"); add("IDM_MOVEMENT")
  end

  if d:find("zynaptiq") or n:find("morph") then
    add("IDM_CHAOS"); add("IDM_GRANULAR"); add("TEXTURE"); add("FORMANT_MORPH")
  end

  if d:find("chow") and n:find("matrix") then
    add("DELAY_CREATIVE"); add("IDM_GRANULAR"); add("IDM_MOVEMENT"); add("TEXTURE")
  end

  if n:find("pancz") then
    add("SPECTRAL_PROCESSING"); add("TRANSIENT"); add("IDM_CHAOS"); add("IDM_GRIT")
  end

  ------------------------------------------------
  -- ANARCHY EFFECTS
  ------------------------------------------------
  if d:find("anarchy") or n:find("anarchy") then
    if n:find("rhythm") then
      add("IDM_GLITCH"); add("IDM_CHAOS"); add("IDM_MOVEMENT"); add("TEXTURE")
    elseif n:find("convoluter") then
      add("TEXTURE"); add("REVERB_SPECIAL"); add("IDM_GRANULAR")
    elseif n:find("corkscrew") then
      add("PITCH_FX"); add("IDM_MOVEMENT"); add("TEXTURE"); add("IDM_CHAOS")
    elseif n:find("harmonic") then
      add("DISTORTION"); add("IDM_GRIT"); add("HARMONIC_ENHANCE")
    elseif n:find("length") then
      add("TRANSIENT"); add("IDM_MOVEMENT"); add("UTILITY")
    elseif n:find("spectralautopan") or n:find("spectral autopan") then
      add("IDM_MOVEMENT"); add("STEREO_SPECIAL"); add("TEXTURE")
    end
  end

  ------------------------------------------------
  -- AUDec (adc-Plugins)
  ------------------------------------------------
  if n:find("adc ") or d:find("audec") then
    if n:find("clap") then
      add("DRUM_SYNTH"); add("PERCUSSION")
    elseif n:find("crush") then
      add("IDM_GLITCH"); add("DISTORTION"); add("IDM_GRIT")
    elseif n:find("extra pan") then
      add("IDM_MOVEMENT"); add("STEREO_SPECIAL")
    elseif n:find("haas") then
      add("STEREO_SPECIAL"); add("UTILITY")
    elseif n:find("mono") then
      add("UTILITY"); add("LOWEND_CONTROL")
    elseif n:find("ring") then
      add("IDM_GLITCH"); add("RINGMOD"); add("TEXTURE")
    elseif n:find("shape") then
      add("DISTORTION"); add("IDM_GRIT"); add("WAVEFOLDER")
    elseif n:find("spread delay") then
      add("DELAY_CREATIVE"); add("IDM_MOVEMENT"); add("TEXTURE")
    elseif n:find("transient") then
      add("TRANSIENT"); add("DRUM_FX"); add("IDM_MOVEMENT")
    elseif n:find("vectorscope") then
      add("METERING"); add("STEREO_ANALYSIS"); add("UTILITY")
    end
  end

  ------------------------------------------------
  -- Auburn Sounds
  ------------------------------------------------
  if d:find("auburn") then
    if n:find("couture") then
      add("TRANSIENT"); add("DISTORTION"); add("IDM_GRIT")
    elseif n:find("lens") then
      add("SPECTRAL_PROCESSING"); add("MASTERING"); add("TEXTURE")
    elseif n:find("panagement") then
      add("STEREO_SPECIAL"); add("IDM_MOVEMENT")
    elseif n:find("renegate") then
      add("GATE/EXPANDER"); add("IDM_MOVEMENT"); add("DRUM_FX")
    end
  end

  ------------------------------------------------
  -- Blue Cat Audio
  ------------------------------------------------
  if d:find("blue cat") then
    if n:find("chorus") then
      add("MODULATION"); add("CHORUS")
    elseif n:find("flanger") then
      add("MODULATION"); add("FLANGER")
    elseif n:find("free amp") then
      add("AMP_SIM"); add("DISTORTION"); add("IDM_GRIT")
    elseif n:find("freqanalyst") then
      add("METERING"); add("SPECTRAL_ANALYSIS"); add("UTILITY")
    elseif n:find("gain") then
      add("UTILITY"); add("GAIN_CONTROL")
    elseif n:find("phaser") then
      add("MODULATION"); add("PHASER")
    elseif n:find("triple eq") then
      add("EQ"); add("UTILITY")
    end
  end

  ------------------------------------------------
  -- Sonstige spezialisierte Tools
  ------------------------------------------------
  if n:find("blindfold") and n:find("eq") then
    add("EQ"); add("EXPERIMENTAL_UI"); add("UTILITY")
  end

  if n:find("bt%-clipper") or n:find("bt clipper") or n:find("bt clip") then
    add("CLIPPER"); add("DISTORTION"); add("IDM_GRIT"); add("MASTERING")
  end

  if d:find("full bucket") and n:find("bucketpops") then
    add("DRUM_MACHINE"); add("VINTAGE"); add("IDM_SOURCE")
  end

  if d:find("tone projects") and n:find("basslane") then
    add("LOWEND_CONTROL"); add("UTILITY"); add("MASTERING")
  end

  if n:find("bx_2098") or (n:find("2098") and n:find("eq")) then
    add("EQ"); add("MASTERING"); add("M/S_PROCESSING")
  end

  if n:find("bx_aura") or n:find("aura reverb") then
    add("REVERB_SPECIAL"); add("IDM_MOVEMENT"); add("TEXTURE")
  end

  if n:find("bx_bassdude") then
    add("AMP_SIM"); add("DISTORTION"); add("IDM_GRIT")
  end

  if n:find("bx_boom") then
    add("DRUM_FX"); add("LOWEND_CONTROL"); add("MASTERING")
  end

  if n:find("bx_cleansweep") then
    add("FILTER"); add("UTILITY"); add("IDM_MOVEMENT")
  end

  if n:find("bx_clipper") then
    add("CLIPPER"); add("DISTORTION"); add("MASTERING"); add("IDM_GRIT")
  end

  if n:find("bx_console") or n:find("bx%-console") then
    add("CHANNEL_STRIP"); add("MASTERING"); add("BUS_PROCESSING")
  end

  ------------------------------------------------
  -- allgemeine Resonator-Erkennung
  ------------------------------------------------
  if n:find("resonator") then
    add("IDM_RESONATOR")
  end

  return tags
end

------------------------------------------------------------
-- DB-BUILDER & QUERIES
------------------------------------------------------------

function DF95Meta.load(custom_paths)
  local respath = r.GetResourcePath()
  local vstcache_path = custom_paths and custom_paths.vstcache or join(respath,"reaper-vstplugins64.ini")
  local fxtags_path   = custom_paths and custom_paths.fxtags   or join(respath,"reaper-fxtags.ini")
  local vstcache = parse_vstplugins64(vstcache_path)
  local dev, cat = parse_fxtags(fxtags_path)
  local db = { plugins = {}, by_name = {}, by_file = {} }
  for file,info in pairs(vstcache) do
    local name = info.name or file
    local developer = dev[file]
    local category  = cat[file]
    local format = file:lower():match("%.vst3$") and "VST3" or "VST2"
    local role = derive_role(name, category, developer, file)
    local tags = derive_tags(name, category, developer, file)
    local entry = {
      file=file, name=name, format=format,
      is_instrument = info.is_instrument and true or false,
      developer=developer, category=category,
      role=role, tags=tags,
      hex_id=info.hex_id, int_id=info.int_id,
    }
    table.insert(db.plugins, entry)
    db.by_file[file] = entry
    db.by_name[name:lower()] = entry
  end
  DF95Meta.db = db
  return db
end

function DF95Meta.find_by_name(pattern)
  if not DF95Meta.db then DF95Meta.load() end
  local res = {}
  local p = pattern:lower()
  for _,pl in ipairs(DF95Meta.db.plugins) do
    if pl.name:lower():find(p,1,true) then table.insert(res,pl) end
  end
  return res
end

function DF95Meta.filter(filter)
  if not DF95Meta.db then DF95Meta.load() end
  local res = {}
  for _,pl in ipairs(DF95Meta.db.plugins) do
    local ok = true
    if filter.role and pl.role ~= filter.role then ok = false end
    if filter.developer and (pl.developer or "") ~= filter.developer then ok = false end
    if filter.category and (pl.category or "") ~= filter.category then ok = false end
    if filter.tag then
      local has_tag=false
      for _,t in ipairs(pl.tags or {}) do if t==filter.tag then has_tag=true break end end
      if not has_tag then ok=false end
    end
    if ok then table.insert(res,pl) end
  end
  return res
end

function DF95Meta.dump_to_file(path)
  if not DF95Meta.db then DF95Meta.load() end
  local f, err = io.open(path,"w")
  if not f then return false, err end
  f:write("DF95 Metadata Core – Plugin Report\n\n")
  for _,pl in ipairs(DF95Meta.db.plugins) do
    f:write(string.format(
      "%s | %s | %s | dev=%s | cat=%s | role=%s | tags=%s\n",
      pl.file or "?", pl.name or "?", pl.format or "?",
      pl.developer or "-", pl.category or "-",
      pl.role or "-",
      table.concat(pl.tags or {}, ",")
    ))
  end
  f:close()
  return true
end

return DF95Meta
