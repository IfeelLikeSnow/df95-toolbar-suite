
-- @description IDM SynthChain Builder (MetaUnified Core, refined)
-- @author You + Reaper DAW Ultimate Assistant
-- @version 1.1
-- @changelog
--   v1.1: Verfeinerte Chains pro Source-Typ (Bass/Lead/Pad/Keys/Pluck/FX/Drone)
--         unter Berücksichtigung typischer Eigenschaften moderner Synths
--         (Wavetable/FM/VA/Granular/Drum-Synth) aus DF95 MetaCore.
-- @about
--   Voraussetzungen:
--     - DF95_MetaCore_VST_All_Modular_v15_WITH_ALL
--     - DF95_SynthMetaCore_v2_7.lua
--     - DF95_MetaUnified_Core.lua
--     im Ordner:
--       <REAPER Resource Path>/Scripts/IFLS/DF95/
--
--   Workflow:
--     1. Synth-Spur auswählen (Instrument- oder Audio-Quelle)
--     2. Script ausführen
--     3. Typ wählen: Bass / Lead / Pad / Keys / Pluck / FX / Drone
--     4. Flavor wählen: Clean / Color / Aggressive / Weird
--     5. Script erzeugt:
--          • [SYNTH FX BUS]
--          • [SYNTH COLOR BUS]
--          • [SYNTH MASTER BUS]
--        + Routing: Synth → FX → Color → SynthMaster → Master
--        + verfeinerte FX-Ketten auf den Bussen (IDM-tauglich)

local r = reaper

local has_vital_engine, VitalEngine = pcall(require, "DF95_Vital_PresetEngine")

local has_surge_engine, SurgeEngine = pcall(require, "DF95_SurgeXT_PresetEngine")


----------------------------------------------------------------------
-- MetaUnified Core laden
----------------------------------------------------------------------
local function load_meta_unified_core()
  local resource = r.GetResourcePath()
  local path = resource .. "/Scripts/IFLS/DF95/DF95_MetaUnified_Core.lua"

  local ok, Core = pcall(dofile, path)
  if not ok or type(Core) ~= "table" or type(Core.Meta) ~= "table" then
    r.ShowMessageBox(
      "Konnte DF95_MetaUnified_Core.lua nicht laden:\\n" ..
      path ..
      "\\n\\nStelle sicher, dass:\\n" ..
      " - DF95_MetaCore_VST_All_Modular_v15_WITH_ALL\\n" ..
      " - DF95_SynthMetaCore_v2_7.lua\\n" ..
      "korrekt entpackt sind.",
      "MetaUnified Core Fehler",
      0
    )
    return nil, nil
  end

  local MetaCore = Core.Meta
  if MetaCore._build_indices then
    MetaCore._build_indices()
  end

  return MetaCore, Core.Synth
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

local function apply_chain_to_track(MC, track, chain_defs)
  for _, def in ipairs(chain_defs or {}) do
    local name = def.display or def.name or def.id
    if name and name ~= "" then
      r.TrackFX_AddByName(track, name, false, -1)
    end
  end
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
-- Versuch, Synth-Klasse grob aus FX-Namen abzuleiten (optional)
-- (z.B. Vital = harscher Wavetable, TyrellN6 = VA, ZebraHZ = modular, etc.)
----------------------------------------------------------------------

local function detect_synth_flavor_hint(track)
  -- Versucht, grob zwischen Synth-Klassen zu unterscheiden,
  -- basierend auf den tatsächlichen Plugins in DF95 MetaCore / SynthCore.
  -- Die Zuordnung ist absichtlich simpel und liefert nur Hinweise wie:
  --   "wavetable_bright", "va_analog", "modular_complex",
  --   "cinematic_texture" oder "ne_digital".
  -- Diese werden weiter unten in build_synth_chain() genutzt, um z.B.
  -- Harsh-Taming, zusätzliche Sättigung oder LoFi zu aktivieren.

  local fx_count = r.TrackFX_GetCount(track)
  for i = 0, fx_count-1 do
    local ok, name = r.TrackFX_GetFXName(track, i, "")
    if ok then
      local n = name:lower()

      ------------------------------------------------------------------
      -- Wavetable / digital bright
      ------------------------------------------------------------------
      if n:find("vital") then
        -- Vital: moderner Wavetable-Synth, eher bright/aggressiv
        return "wavetable_bright"
      elseif n:find("thump one") or n:find("thump_one") then
        -- Thump One: Toybox / granular-wavetable Hybrid, oft knackig/bright
        return "wavetable_bright"
      elseif n:find("sqkone") or n:find("skq-01") or n:find("skq01") then
        -- SQKOne / SKQ-01: FM / digitale Synthese mit eher scharfen Obertönen
        return "wavetable_bright"
      end

      ------------------------------------------------------------------
      -- VA / klassische Analogsounds
      ------------------------------------------------------------------
      if n:find("tyrell") or n:find("tyrelln6") then
        -- TyrellN6: virtuell-analog (Juno-ähnlich)
        return "va_analog"
      elseif n:find("podolski") then
        -- Podolski: simpler VA mit Arp/Sequencer
        return "va_analog"
      elseif n:find("triple cheese") then
        -- Triple Cheese: Comb-Filter-Synth, aber klanglich eher VA-artig im Mix
        return "va_analog"
      elseif n:find("oberhausen") or n:find("bx_oberhausen") then
        -- bx_oberhausen: OB-X inspiriert, klassischer polyphoner VA
        return "va_analog"
      end

      ------------------------------------------------------------------
      -- Modular / komplexe Engines
      ------------------------------------------------------------------
      if n:find("zebra") or n:find("zebralette") then
        -- Zebra / ZebraHZ: semi-modular, sehr flexibel
        return "modular_complex"
      elseif n:find("pendulate") then
        -- Pendulate: chaotischer Monosynth, gut für aggressive Leads/Bässe
        return "modular_complex"
      elseif n:find("voltage modular") then
        -- Voltage Modular: komplettes Modularsystem
        return "modular_complex"
      elseif n:find("battalion") then
        -- Unfiltered Audio Battalion: Drum-Machine mit vielen Synth-Engines
        -- Für unsere Zwecke wie ein komplexer, digitaler Drum-/Synth-Hybrid.
        return "modular_complex"
      end

      ------------------------------------------------------------------
      -- Textur / Granular / Tape- und LoFi-Instrumente
      ------------------------------------------------------------------
      if n:find("mndala") then
        -- MNDALA 2-Engine: Multi-Sample / Hybrid-Textur-Instrument
        return "cinematic_texture"
      elseif n:find("grainbow") or n:find("grainbow") then
        -- gRainbow: pitch-detecting granular synth
        return "cinematic_texture"
      elseif n:find("expanse") then
        -- Expanse: Texture/Noise/Drone-Generator
        return "cinematic_texture"
      elseif n:find("leems") then
        -- Leems: supernatural lo-fi / chiptune-artige Texturen
        return "cinematic_texture"
      elseif n:find("verv") then
        -- Verv: sunbaked tape loop string synth
        return "cinematic_texture"
      elseif n:find("adsr sample manager") or n:find("sample manager") then
        -- ADSR Sample Manager: Sample-Instrument, oft für Drums/One-Shots/Textures
        return "cinematic_texture"
      end

      ------------------------------------------------------------------
      -- Speziell: Sinc Vereor / eher digital / bright
      ------------------------------------------------------------------
      if n:find("sinc vereor") or n:find("sinc_vereor") then
        return "ne_digital"
      end
    end
  end

  return nil
end

----------------------------------------------------------------------
-- UI: Auswahl Synth-Typ + Flavor
----------------------------------------------------------------------
local function choose_synth_context()
  local title = "IDM SynthChain Builder"
  local prompts = "Source-Typ (1=Bass,2=Lead,3=Pad,4=Keys,5=Pluck,6=FX/Texture,7=Drone):," ..
                  "Flavor (1=Clean,2=Color,3=Aggressive,4=Weird):"
  local defaults = "1,2"

  local ok, ret = r.GetUserInputs(title, 2, prompts, defaults)
  if not ok then return nil end

  local src_idx, flav_idx = ret:match("^%s*(%d+)%s*,%s*(%d+)%s*$")
  src_idx  = tonumber(src_idx)
  flav_idx = tonumber(flav_idx)
  if not src_idx or src_idx < 1 or src_idx > 7 then
    r.ShowMessageBox("Ungültiger Source-Index.", "SynthChain Builder", 0)
    return nil
  end
  if not flav_idx or flav_idx < 1 or flav_idx > 4 then
    r.ShowMessageBox("Ungültiger Flavor-Index.", "SynthChain Builder", 0)
    return nil
  end

  local sources = {
    [1] = "bass",
    [2] = "lead",
    [3] = "pad",
    [4] = "keys",
    [5] = "pluck",
    [6] = "fx",
    [7] = "drone",
  }

  local flavors = {
    [1] = "clean",
    [2] = "color",
    [3] = "aggressive",
    [4] = "weird",
  }

  return {
    source = sources[src_idx],
    flavor = flavors[flav_idx],
  }
end

----------------------------------------------------------------------
-- Verfeinerte Chain-Builder pro Typ
----------------------------------------------------------------------
local function build_synth_chain(MC, ctx, synth_hint)
  local src    = ctx.source
  local flavor = ctx.flavor or "color"

  local chain_fx     = {}
  local chain_color  = {}
  local chain_master = {}

  local function add(t, def)
    if def then t[#t+1] = def end
  end

  local is_bright_wavetable = (synth_hint == "wavetable_bright")
  local is_va_analog        = (synth_hint == "va_analog")
  local is_modular_complex  = (synth_hint == "modular_complex")
  local is_texture_synth    = (synth_hint == "cinematic_texture")

  --------------------------------------------------------------------
  -- Bass
  -- Ziel:
  --   • Tight Low-End (HP & Low-Shelf)
  --   • Punch (Bus-Comp / Dynamics)
  --   • ggf. Distortion/Multiband-Sat (Aggro)
  --   • Sub-Enhancement (falls sinnvoll)
  --------------------------------------------------------------------
  if src == "bass" then
    -- FX Bus: Charakterbearbeitung
    if flavor ~= "clean" then
      add(chain_fx, mc_pick_by_role(MC, {"Distortion","Drive","Bass"}))
      add(chain_fx, mc_pick(MC, { query = "multiband", roles = {"Bass","Drive"} }))
    end
    -- Harte Wavetable-Bässe: zusätzlich etwas dynamische Kontrolle obenrum
    if is_bright_wavetable then
      add(chain_fx, mc_pick(MC, { query = "dynamic", roles = {"DynamicEQ","Tamer"} }))
    end
    -- Filter / EQ, um den Low-End-Bereich zu formen
    add(chain_fx, mc_pick_by_role(MC, {"Filter","EQ","Tone"}))

    -- Color Bus: Sättigung & Sub
    add(chain_color, mc_pick_by_role(MC, {"Saturation","Color","Console"}))
    add(chain_color, mc_pick(MC, { query = "tape", roles = {"Bass","LowEnd"} }))
    add(chain_color, mc_pick_by_role(MC, {"Bass","LowEnd","Enhancer"}))

    -- Master Bus: Kompressor + Limiter + Meter
    add(chain_master, mc_pick_by_role(MC, {"Bus","Glue","MasterComp"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter","TruePeak","Safety"}))
    add(chain_master, mc_pick_by_role(MC, {"Meter","Loudness"}))

  --------------------------------------------------------------------
  -- Lead
  -- Ziel:
  --   • Räumlichkeit (Delay/Verb)
  --   • Leichte Modulation für Breite
  --   • De-Harsh (bei Wavetable/FM)
  --------------------------------------------------------------------
  elseif src == "lead" then
    -- FX Bus: Delay und Reverb als Hauptcharakter
    add(chain_fx, mc_pick(MC, { query = "delay", roles = {"Lead","Rhythmic"} }))
    add(chain_fx, mc_pick_by_role(MC, {"Reverb","Space"}))
    if flavor ~= "clean" then
      add(chain_fx, mc_pick_by_role(MC, {"Chorus","Ensemble","Doubler","Modulation"}))
    end
    -- Wavetable/FM Leads: Harsh-Taming
    if is_bright_wavetable or is_modular_complex then
      add(chain_fx, mc_pick(MC, { query = "dynamic", roles = {"DynamicEQ","DeHarsh","DeEss"} }))
    end

    -- Color Bus: Sättigung + Tonformung
    add(chain_color, mc_pick_by_role(MC, {"Saturation","Color"}))
    if is_va_analog then
      -- leichte Tape-Färbung für VA-Leads
      add(chain_color, mc_pick(MC, { query = "tape" }))
    end
    add(chain_color, mc_pick_by_role(MC, {"Tone","CleanEQ"}))

    -- Master Bus: Bus-Comp / Limiter / Meter
    add(chain_master, mc_pick_by_role(MC, {"Bus","Glue"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter","TruePeak"}))
    add(chain_master, mc_pick_by_role(MC, {"Meter","Loudness"}))

  --------------------------------------------------------------------
  -- Pad
  -- Ziel:
  --   • Breite (Chorus/Ensemble)
  --   • Tiefe Räume (Hall/Mod-Verb)
  --   • Weiche Sättigung, kein übertriebener Punch
  --------------------------------------------------------------------
  elseif src == "pad" then
    -- FX Bus: Modulation & Reverb
    add(chain_fx, mc_pick_by_role(MC, {"Chorus","Ensemble","Modulation"}))
    add(chain_fx, mc_pick(MC, { query = "reverb", roles = {"Space","Pad"} }))
    if flavor ~= "clean" then
      add(chain_fx, mc_pick(MC, { query = "shimmer", roles = {"Reverb"} }))
      add(chain_fx, mc_pick(MC, { query = "delay", roles = {"Pad"} }))
    end

    -- Color Bus: Tape / Console / leichte LoFi bei weird
    add(chain_color, mc_pick_by_role(MC, {"Tape","Saturation","Console"}))
    add(chain_color, mc_pick_by_role(MC, {"Tone","CleanEQ"}))
    if flavor == "weird" or is_texture_synth then
      add(chain_color, mc_pick_by_role(MC, {"LoFi","Noise"}))
    end

    -- Master Bus: Glue / Limiter / Meter
    add(chain_master, mc_pick_by_role(MC, {"Bus","Glue","MasterComp"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter","TruePeak"}))
    add(chain_master, mc_pick_by_role(MC, {"Meter","Loudness"}))

  --------------------------------------------------------------------
  -- Keys
  -- Ziel:
  --   • moderate Räume
  --   • leichte Modulation
  --   • klare Transienten (für E-Piano/Keys)
  --------------------------------------------------------------------
  elseif src == "keys" then
    -- FX Bus: kurzer Reverb, Delay, leichte Modulation
    add(chain_fx, mc_pick(MC, { query = "reverb", roles = {"Room","Plate"} }))
    add(chain_fx, mc_pick(MC, { query = "delay", roles = {"Keys"} }))
    if flavor ~= "clean" then
      add(chain_fx, mc_pick_by_role(MC, {"Chorus","Modulation"}))
    end

    -- Color Bus: leichte Saturation, EQ
    add(chain_color, mc_pick_by_role(MC, {"Saturation","Color"}))
    add(chain_color, mc_pick_by_role(MC, {"Tone","CleanEQ"}))
    if flavor == "weird" then
      add(chain_color, mc_pick_by_role(MC, {"LoFi","Noise"}))
    end

    -- Master Bus: Bus-Comp / Limiter / Meter
    add(chain_master, mc_pick_by_role(MC, {"Bus","Glue"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter"}))
    add(chain_master, mc_pick_by_role(MC, {"Meter"}))

  --------------------------------------------------------------------
  -- Pluck
  -- Ziel:
  --   • rhythmische Delays
  --   • Transient-Kontrolle
  --   • klares Timing
  --------------------------------------------------------------------
  elseif src == "pluck" then
    -- FX Bus: Delay, subtile Reverb, Transient optional
    add(chain_fx, mc_pick(MC, { query = "delay", roles = {"Rhythmic","Pluck"} }))
    add(chain_fx, mc_pick(MC, { query = "reverb", roles = {"Plate","Room"} }))
    if flavor == "aggressive" then
      add(chain_fx, mc_pick_by_role(MC, {"Transient","Shaper"}))
    end

    -- Color Bus: Saturation / EQ
    add(chain_color, mc_pick_by_role(MC, {"Saturation","Color"}))
    add(chain_color, mc_pick_by_role(MC, {"Tone","CleanEQ"}))

    -- Master Bus: Comp + Limiter
    add(chain_master, mc_pick_by_role(MC, {"Bus","Glue"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter"}))

  --------------------------------------------------------------------
  -- FX / Texture
  -- Ziel:
  --   • Spectral/Granular/Pitch-FX
  --   • komplexe Modulation
  --   • kreative Degradation
  --------------------------------------------------------------------
  elseif src == "fx" then
    -- FX Bus: Spectral / Granular / Delay / Modulation / Reverb
    add(chain_fx, mc_pick(MC, { query = "spectral", roles = {"Spectral","FX"} }))
    add(chain_fx, mc_pick(MC, { query = "granular", roles = {"Granular"} }))
    add(chain_fx, mc_pick(MC, { query = "pitch", roles = {"Pitchshift","FX"} }))
    add(chain_fx, mc_pick(MC, { query = "delay", roles = {"FX","Rhythmic"} }))
    add(chain_fx, mc_pick_by_role(MC, {"Chorus","Flanger","Phaser","Modulation"}))
    add(chain_fx, mc_pick(MC, { query = "reverb", roles = {"Space","FX"} }))

    -- Color Bus: LoFi / Tape / Noise / Filter
    add(chain_color, mc_pick_by_role(MC, {"LoFi","Noise","Tape","Saturation"}))
    add(chain_color, mc_pick_by_role(MC, {"Filter","EQ"}))

    -- Master Bus: eher Utility – leichter Glue + Limiter
    add(chain_master, mc_pick_by_role(MC, {"Bus","Glue"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter"}))

  --------------------------------------------------------------------
  -- Drone
  -- Ziel:
  --   • sehr lange Reverbs / Shimmer
  --   • Modulation / Bewegung
  --   • subtile Sättigung, evtl. Noise-Layer
  --------------------------------------------------------------------
  elseif src == "drone" then
    -- FX Bus: große Reverbs, Spectral, Modulation
    add(chain_fx, mc_pick(MC, { query = "reverb", roles = {"Space","Drone"} }))
    add(chain_fx, mc_pick(MC, { query = "shimmer", roles = {"Reverb","Drone"} }))
    add(chain_fx, mc_pick(MC, { query = "spectral", roles = {"Spectral"} }))
    add(chain_fx, mc_pick_by_role(MC, {"Chorus","Ensemble","Modulation"}))

    -- Color Bus: Tape, Saturation, Tilt, LoFi möglich
    add(chain_color, mc_pick_by_role(MC, {"Tape","Saturation","Console"}))
    add(chain_color, mc_pick_by_role(MC, {"Tone","CleanEQ"}))
    if flavor == "weird" or flavor == "aggressive" or is_texture_synth then
      add(chain_color, mc_pick_by_role(MC, {"LoFi","Noise"}))
    end

    -- Master Bus: Comp + Meter + Limiter als Schutz
    add(chain_master, mc_pick_by_role(MC, {"Bus","MasterComp"}))
    add(chain_master, mc_pick_by_role(MC, {"Limiter","Safety"}))
    add(chain_master, mc_pick_by_role(MC, {"Meter","Loudness"}))
  end

  return chain_fx, chain_color, chain_master
end

----------------------------------------------------------------------
-- MAIN
----------------------------------------------------------------------
local function main()
  local tr = r.GetSelectedTrack(0, 0)
  if not tr then
    r.ShowMessageBox("Bitte zuerst eine Synth-Spur auswählen.", "IDM SynthChain Builder", 0)
    return
  end

  local MC, SynthCore = load_meta_unified_core()
  if not MC then return end

  local ctx = choose_synth_context()
  if not ctx then return end

  
-- Optional: Vital/Surge Preset-Engine pro Rolle/Flavor
if ctx and ctx.source then
  local inst_idx = r.TrackFX_GetInstrument(tr)
  if inst_idx and inst_idx >= 0 then
    local ok_fx, fxname = r.TrackFX_GetFXName(tr, inst_idx, "")
    if ok_fx and fxname and fxname ~= "" then
      -- Vital
      if has_vital_engine and VitalEngine and VitalEngine.IsVitalFXName(fxname) then
        VitalEngine.ApplyPresetForType(tr, inst_idx, ctx.source, ctx.flavor or "color")
      end
      -- Surge XT
      if has_surge_engine and SurgeEngine and SurgeEngine.IsSurgeFXName(fxname) then
        SurgeEngine.ApplyPresetForType(tr, inst_idx, ctx.source, ctx.flavor or "color")
      end
    end
  end
end


r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  -- Synth-Hint aus FX-Namen ableiten (optional)
  local synth_hint = detect_synth_flavor_hint(tr)

  -- Spur ggf. benennen
  local _, old_name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  local tag = "[SYNTH " .. (ctx.source or "CHAIN") .. "]"
  if not old_name or old_name == "" then
    r.GetSetMediaTrackInfo_String(tr, "P_NAME", tag, true)
  else
    if not old_name:find(tag, 1, true) then
      r.GetSetMediaTrackInfo_String(tr, "P_NAME", old_name .. " " .. tag, true)
    end
  end

  -- Busse erzeugen
  local bus_fx     = create_bus_after(tr, "[SYNTH FX BUS]")
  local bus_color  = create_bus_after(bus_fx, "[SYNTH COLOR BUS]")
  local bus_master = create_bus_after(bus_color, "[SYNTH MASTER BUS]")

  -- Routing
  clear_master_send(tr)
  clear_master_send(bus_fx)
  clear_master_send(bus_color)
  set_master_send_on(bus_master, true)

  create_send(tr,       bus_fx)
  create_send(bus_fx,   bus_color)
  create_send(bus_color,bus_master)

  -- Chains bauen & anwenden
  local chain_fx, chain_color, chain_master = build_synth_chain(MC, ctx, synth_hint)

  apply_chain_to_track(MC, bus_fx,     chain_fx)
  apply_chain_to_track(MC, bus_color,  chain_color)
  apply_chain_to_track(MC, bus_master, chain_master)

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
  r.Undo_EndBlock("IDM SynthChain Builder (" .. (ctx.source or "?") .. " / " .. (ctx.flavor or "?") .. ")", -1)
end

main()
