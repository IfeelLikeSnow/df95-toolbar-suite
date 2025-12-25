-- @description DF95_V113_ArtistStyleFX_Apply
-- @version 1.0
-- @author DF95
-- @about
--   Liest Artist/Style/Tempo-ExtStates aus der DF95-BeatEngine
--   und legt passende FX-Ketten auf die selektierten Tracks.
--
--   Fokus:
--     * nur installierte Standard-ReaFX + optionale 3rd-Party (wenn vorhanden)
--     * pro Track-Rolle (Kick/Snare/Hat/Perc/FX/Bus) unterschiedliche Ketten
--     * Artist-Overrides, Style-Overrides, ansonsten Default-IDM-Kette
--
--   Wichtig:
--     * Das Script schreibt keine Audiofiles, nur FX in den Track-FX-Slot
--     * Es versucht erst Artist-Profil, dann Style-Profil, dann Fallback

local r = reaper

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function dbg(msg)
  --r.ShowConsoleMsg(tostring(msg).."\n")
end

local function get_ext(proj, section, key, default)
  local ok, val = r.GetProjExtState(proj, section, key)
  if ok == 1 and val ~= "" then return val end
  return default
end

local function set_ext(proj, section, key, val)
  r.SetProjExtState(proj, section, key, val or "")
end

-- Check if an FX exists; if mode = "add", actually create it
local function ensure_fx(track, fx_name)
  if not track or not fx_name or fx_name == "" then return -1 end

  -- Query only
  local idx = r.TrackFX_AddByName(track, fx_name, false, 0x1000000)
  if idx ~= -1 then
    -- Already present somewhere, return the index
    return idx
  end

  -- Try as VST3, VST, JS variations
  local candidates = {
    fx_name,
    "VST3: "..fx_name,
    "VST: "..fx_name,
    "JS: "..fx_name,
  }

  for _, c in ipairs(candidates) do
    idx = r.TrackFX_AddByName(track, c, false, -1)
    if idx ~= -1 then
      dbg("Added FX: "..c)
      return idx
    end
  end

  dbg("FX NOT FOUND: "..fx_name)
  return -1
end

local function set_param(track, fx_idx, param_idx, value)
  if fx_idx < 0 then return end
  r.TrackFX_SetParam(track, fx_idx, param_idx, value)
end

---------------------------------------------------------------------------
-- Role detection (from ExtStates & Trackname)
---------------------------------------------------------------------------

local ROLE_SECTION = "DF95_CLASS"

local function detect_role(proj, track)
  -- 1) Try explicit DF95_CLASS/ROLE_<GUID>
  local guid = r.GetTrackGUID(track)
  local _, guid_str = r.Undo_CanUndo2(proj) -- dummy to ensure proj exists
  local guid_s = tostring(guid)

  -- Unfortunately GetProjExtState is per-project only – we store global per-track role:
  local ok, role = r.GetSetMediaTrackInfo_String(track, "P_EXT:DF95_ROLE", "", false)
  if ok and role ~= nil and role ~= "" then
    return role
  end

  -- 2) Fallback: name heuristics
  local _, name = r.GetTrackName(track, "")
  name = (name or ""):lower()

  if name:find("kick") or name:find("bd") or name:find("bassdrum") then
    return "kick"
  elseif name:find("snare") or name:find("sna") then
    return "snare"
  elseif name:find("hat") or name:find("hihat") or name:find("hh") then
    return "hat"
  elseif name:find("perc") or name:find("clap") or name:find("rim") then
    return "perc"
  elseif name:find("fx") or name:find("noise") or name:find("sfx") then
    return "fx"
  elseif name:find("bus") or name:find("drumbus") then
    return "bus"
  end

  return "generic"
end

---------------------------------------------------------------------------
-- Artist / Style Profiles
---------------------------------------------------------------------------

-- Styles: IDM, Glitch, Ambient, Dub, Minimal
local STYLE_ALIASES = {
  ["idb"] = "IDM",
  ["idm"] = "IDM",
  ["glitch"] = "Glitch",
  ["ambient"] = "Ambient",
  ["drone"] = "Ambient",
  ["dub"] = "Dub",
  ["dubtechno"] = "Dub",
  ["minimal"] = "Minimal",
  ["techno"] = "Minimal",
}

local ARTIST_MAP = {
  ["aphex twin"]        = "Aphex Twin",
  ["autechre"]          = "Autechre",
  ["boards of canada"]  = "Boards of Canada",
  ["squarepusher"]      = "Squarepusher",
  ["μ-ziq"]             = "µ-Ziq",
  ["mu-ziq"]            = "µ-Ziq",
  ["apparat"]           = "Apparat",
  ["arovane"]           = "Arovane",
  ["björk"]             = "Björk",
  ["bjork"]             = "Björk",
  ["bochum welt"]       = "Bochum Welt",
  ["bogdan raczynski"]  = "Bogdan Raczynski",
  ["burial"]            = "Burial",
  ["cylob"]             = "Cylob",
  ["dmx krew"]          = "DMX Krew",
  ["flying lotus"]      = "Flying Lotus",
  ["four tet"]          = "Four Tet",
  ["the future sound of london"] = "The Future Sound Of London",
  ["i am robot and proud"] = "I am Robot and Proud",
  ["isan"]              = "Isan",
  ["jan jelinek"]       = "Jan Jelinek",
  ["jega"]              = "Jega",
  ["legowelt"]          = "Legowelt",
  ["matmos"]            = "Matmos",
  ["moderat"]           = "Moderat",
  ["photek"]            = "Photek",
  ["plaid"]             = "Plaid",
  ["skylab"]            = "Skylab",
  ["telefon tel aviv"]  = "Telefon Tel Aviv",
  ["thom yorke"]        = "Thom Yorke",
  ["tim hecker"]        = "Tim Hecker",
  ["proem"]             = "Proem",
}

-- Tempo layers – these beeinflussen nur die Intensität einiger Effekte
local TEMPO_MULT = {
  slow   = 0.7,
  medium = 1.0,
  fast   = 1.3,
}

---------------------------------------------------------------------------
-- FX Recipes
-- (Names are *browser names*, not DLLs – we let Reaper resolve them.)
---------------------------------------------------------------------------

local function recipe_default(role)
  if role == "kick" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_kick" },
      { name = "ReaComp (Cockos)", kind = "comp_drums" },
    }
  elseif role == "snare" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_snare" },
      { name = "ReaComp (Cockos)", kind = "comp_drums" },
    }
  elseif role == "hat" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_hat" },
      { name = "ReaComp (Cockos)", kind = "comp_hat" },
    }
  elseif role == "perc" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_perc" },
      { name = "ReaComp (Cockos)", kind = "comp_perc" },
    }
  elseif role == "fx" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_fx" },
      { name = "ReaDelay (Cockos)",kind = "delay_fx" },
    }
  elseif role == "bus" then
    return {
      { name = "ReaComp (Cockos)", kind = "bus_comp" },
      { name = "ReaXcomp (Cockos)",kind = "bus_multicomp" },
    }
  else
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_generic" },
      { name = "ReaComp (Cockos)", kind = "comp_generic" },
    }
  end
end

-- Artist overrides – nur wenige, rest erbt von Style/Default

local function recipe_artist(artist, role)
  -- Pro Artist nur sanfte, sinnvolle Tendenzen – alles auf Basis von ReaFX + optionalen Extras
  if artist == "Aphex Twin" then
    if role == "kick" or role == "snare" or role == "perc" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_idm_drums" },
        { name = "ReaComp (Cockos)", kind = "comp_snappy" },
        { name = "ReaDelay (Cockos)",kind = "delay_crisp" },
      }
    elseif role == "fx" or role == "hat" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_fx_bright" },
        { name = "ReaComp (Cockos)", kind = "comp_fast" },
      }
    end

  elseif artist == "Autechre" then
    -- Autechre: mid-focused, glitchy, eher trocken, teils FIR-basierte Eingriffe
    if role == "perc" or role == "hat" or role == "fx" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_midfocus" },
        { name = "ReaComp (Cockos)", kind = "comp_fast" },
        { name = "ReaFIR (FFT EQ+Dynamics Processor) (Cockos)", kind = "weird_fir" },
      }
    end

  elseif artist == "Boards of Canada" then
    -- Warm, lofi, leicht dumpf, mit Raum
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_lofi" },
      { name = "ReaComp (Cockos)", kind = "comp_soft" },
      { name = "ReaDelay (Cockos)",kind = "delay_tapeish" },
    }

  elseif artist == "Squarepusher" then
    if role == "kick" or role == "snare" or role == "hat" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_aggressive" },
        { name = "ReaComp (Cockos)", kind = "comp_hard" },
        { name = "ReaDelay (Cockos)",kind = "delay_crisp" },
      }
    else
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_fx_bright" },
        { name = "ReaComp (Cockos)", kind = "comp_fast" },
      }
    end

  elseif artist == "µ-Ziq" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_idm_drums" },
      { name = "ReaComp (Cockos)", kind = "comp_fast" },
      { name = "ReaDelay (Cockos)",kind = "delay_tapeish" },
    }

  elseif artist == "Apparat" or artist == "Moderat" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_clean" },
      { name = "ReaComp (Cockos)", kind = "comp_clean" },
      { name = "ReaVerbate (Cockos)", kind = "verb_long_dark" },
    }

  elseif artist == "Arovane" or artist == "Jan Jelinek" or artist == "The Future Sound Of London" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_ambient" },
      { name = "ReaComp (Cockos)", kind = "comp_soft" },
      { name = "ReaVerbate (Cockos)", kind = "verb_huge" },
    }

  elseif artist == "Björk" or artist == "Thom Yorke" then
    if role == "fx" or role == "perc" or role == "hat" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_fx" },
        { name = "ReaComp (Cockos)", kind = "comp_generic" },
        { name = "ReaDelay (Cockos)",kind = "delay_tapeish" },
      }
    end

  elseif artist == "Bochum Welt" or artist == "Isan" or artist == "I am Robot and Proud" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_clean" },
      { name = "ReaComp (Cockos)", kind = "comp_soft" },
    }

  elseif artist == "Bogdan Raczynski" or artist == "DMX Krew" or artist == "Proem" then
    -- eher aggressiver, breakbeatiger IDM
    if role == "kick" or role == "snare" or role == "perc" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_aggressive" },
        { name = "ReaComp (Cockos)", kind = "comp_hard" },
      }
    end

  elseif artist == "Burial" then
    if role == "perc" or role == "fx" or role == "hat" or role == "generic" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_bandpass_mid" },
        { name = "ReaComp (Cockos)", kind = "comp_soft" },
        { name = "ReaVerbate (Cockos)", kind = "verb_long_dark" },
      }
    end

  elseif artist == "Cylob" or artist == "Plaid" or artist == "Four Tet" or artist == "Flying Lotus" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_idm_drums" },
      { name = "ReaComp (Cockos)", kind = "comp_fast" },
      { name = "ReaDelay (Cockos)",kind = "delay_fx" },
    }

  elseif artist == "Legowelt" or artist == "Photek" or artist == "Skylab" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_clean" },
      { name = "ReaComp (Cockos)", kind = "comp_bus" },
      { name = "ReaDelay (Cockos)",kind = "delay_dub" },
    }

  elseif artist == "Matmos" or artist == "Telefon Tel Aviv" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_fx" },
      { name = "ReaComp (Cockos)", kind = "comp_generic" },
      { name = "ReaDelay (Cockos)",kind = "delay_crisp" },
    }

  elseif artist == "Tim Hecker" then
    if role == "fx" or role == "bus" or role == "generic" or role == "drone" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_drone" },
        { name = "ReaComp (Cockos)", kind = "comp_slow" },
        { name = "ReaVerbate (Cockos)", kind = "verb_huge" },
      }
    end
  end

  return nil
end


local function recipe_style(style, role)
  if style == "IDM" then
    if role == "kick" or role == "snare" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_idm_drums" },
        { name = "ReaComp (Cockos)", kind = "comp_fast" },
      }
    elseif role == "hat" or role == "perc" then
      return {
        { name = "ReaEQ (Cockos)",   kind = "eq_hat_bright" },
        { name = "ReaComp (Cockos)", kind = "comp_hat" },
      }
    end
  elseif style == "Glitch" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_fx_bright" },
      { name = "ReaComp (Cockos)", kind = "comp_fast" },
      -- gRainbow optional Granular-FX, falls installiert
      { name = "gRainbow (StrangeLoops)", kind = "granular_glitch", optional = true },
    }
  elseif style == "Ambient" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_ambient" },
      { name = "ReaComp (Cockos)", kind = "comp_soft" },
      { name = "ReaVerbate (Cockos)", kind = "verb_huge" },
    }
  elseif style == "Dub" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_dub" },
      { name = "ReaComp (Cockos)", kind = "comp_bus" },
      { name = "ReaDelay (Cockos)",kind = "delay_dub" },
    }
  elseif style == "Minimal" then
    return {
      { name = "ReaEQ (Cockos)",   kind = "eq_clean" },
      { name = "ReaComp (Cockos)", kind = "comp_clean" },
    }
  end
  return nil
end

---------------------------------------------------------------------------
-- Parameter shapers
---------------------------------------------------------------------------

local function shape_eq(track, fx_idx, kind, tempo_mult)
  if fx_idx < 0 then return end
  -- Vereinfachte Annahmen: ReaEQ default: 4 Bänder, Param Layout:
  -- Band 1 Freq (0), Gain (1), Q (2), Type (3), usw.
  -- Wir arbeiten nur mit Frequenz/Gain/Q einiger Bänder.
  local function set(band, freq, gain_db, q)
    local base = (band-1)*4
    -- ReaEQ Normalisierung: Freq (log), Gain +/- 12 dB ~ 0..1, Q 0.1..10
    -- Wir setzen nur grob: 0..1 approximiert.
    if freq then
      -- Very rough mapping 20Hz..20kHz -> 0..1
      local f = math.log(freq/20, 10) / math.log(20000/20, 10)
      f = math.max(0, math.min(1, f))
      set_param(track, fx_idx, base, f)
    end
    if gain_db then
      local g = (gain_db + 12) / 24
      g = math.max(0, math.min(1, g))
      set_param(track, fx_idx, base+1, g)
    end
    if q then
      local qnorm = (math.log(q) - math.log(0.1)) / (math.log(10) - math.log(0.1))
      qnorm = math.max(0, math.min(1, qnorm))
      set_param(track, fx_idx, base+2, qnorm)
    end
  end

  if kind == "eq_kick" then
    set(1, 40,   4, 1.0)
    set(2, 90,   3, 1.0)
    set(3, 400, -4, 1.0)
    set(4, 8000, 2, 0.7)
  elseif kind == "eq_snare" then
    set(1, 120, -3, 1.0)
    set(2, 200,  3, 1.0)
    set(3, 4500, 3, 0.8)
    set(4, 9000, 2, 0.7)
  elseif kind == "eq_hat" or kind == "eq_hat_bright" then
    set(1, 200, -6, 1.0)
    set(2, 3000, 2, 0.8)
    set(3, 8000, 4, 0.7)
  elseif kind == "eq_perc" or kind == "eq_fx" or kind == "eq_fx_bright" then
    set(1, 150, -4, 1.0)
    set(2, 1000, 3, 0.9)
    set(3, 6000, 3, 0.7)
  elseif kind == "eq_idm_drums" or kind == "eq_aggressive" then
    set(1, 50,  5, 1.0)
    set(2, 200, 4, 1.0)
    set(3, 3000, 4, 0.7)
    set(4, 9000, 3, 0.7)
  elseif kind == "eq_lofi" then
    set(1, 80,  -2, 1.0)
    set(2, 400, 2, 0.8)
    set(3, 3000,-2, 0.8)
    set(4, 8000,-4, 0.7)
  elseif kind == "eq_ambient" or kind == "eq_drone" then
    set(1, 60,  -3, 1.0)
    set(2, 400, 1, 0.8)
    set(3, 3000,-3, 0.8)
    set(4, 8000,-6, 0.7)
  elseif kind == "eq_bandpass_mid" then
    set(1, 150, -6, 1.0)
    set(2, 2500, 4, 0.5)
    set(3, 9000,-6, 1.0)
  elseif kind == "eq_clean" or kind == "eq_generic" then
    set(1, 40,  -3, 1.0)
    set(2, 250, 1.5, 0.9)
    set(3, 3000,1.5, 0.9)
  elseif kind == "eq_dub" then
    set(1, 80,   4, 1.0)
    set(2, 300,  2, 0.9)
    set(3, 800, -3, 1.0)
    set(4, 4000,-2, 0.9)
  end
end

local function shape_comp(track, fx_idx, kind, tempo_mult)
  if fx_idx < 0 then return end
  -- ReaComp Standard: 0:Threshold,1:PreComp,2:Attack,3:Release,4:Knee,5:Ratio,6:AutoRelease,7:AutoMakeup...
  local function set_param_norm(p, v)
    set_param(track, fx_idx, p, v)
  end

  if kind == "comp_drums" or kind == "comp_snappy" or kind == "comp_fast" then
    local speed = tempo_mult or 1.0
    set_param_norm(0, 0.4)                     -- Threshold
    set_param_norm(2, 0.05 * speed)            -- Attack
    set_param_norm(3, 0.15 * speed)            -- Release
    set_param_norm(5, 0.7)                     -- Ratio ~ 4:1
  elseif kind == "comp_hat" then
    set_param_norm(0, 0.5)
    set_param_norm(2, 0.02)
    set_param_norm(3, 0.10)
    set_param_norm(5, 0.5)
  elseif kind == "comp_perc" or kind == "comp_generic" then
    set_param_norm(0, 0.45)
    set_param_norm(2, 0.08)
    set_param_norm(3, 0.20)
    set_param_norm(5, 0.6)
  elseif kind == "bus_comp" or kind == "bus_multicomp" or kind == "comp_bus" then
    set_param_norm(0, 0.55)
    set_param_norm(2, 0.15)
    set_param_norm(3, 0.40)
    set_param_norm(5, 0.5)
  elseif kind == "comp_soft" or kind == "comp_slow" or kind == "comp_clean" then
    set_param_norm(0, 0.65)
    set_param_norm(2, 0.20)
    set_param_norm(3, 0.60)
    set_param_norm(5, 0.4)
  elseif kind == "comp_hard" then
    set_param_norm(0, 0.35)
    set_param_norm(2, 0.05)
    set_param_norm(3, 0.20)
    set_param_norm(5, 0.8)
  end
end

local function shape_delay(track, fx_idx, kind, tempo_mult)
  if fx_idx < 0 then return end
  -- ReaDelay: 0:Length (ms),1:Feedback,2:LP,3:HP, etc. Normiert.
  local function setn(p, v) set_param(track, fx_idx, p, v) end

  local speed = tempo_mult or 1.0
  if kind == "delay_pingpong_short" then
    setn(0, 0.20 * speed) -- ~ 1/8
    setn(1, 0.35)
  elseif kind == "delay_tapeish" then
    setn(0, 0.35 * speed) -- 1/4
    setn(1, 0.45)
  elseif kind == "delay_crisp" then
    setn(0, 0.18 * speed)
    setn(1, 0.30)
  elseif kind == "delay_dub" or kind == "delay_fx" then
    setn(0, 0.50 * speed) -- 3/8 – 1/2
    setn(1, 0.55)
  end
end

local function shape_verb(track, fx_idx, kind, tempo_mult)
  if fx_idx < 0 then return end
  -- ReaVerbate: 0:RoomSize,1:Damp,2:EQ LowCut,3:EQ HighCut,4:EarlyRef,5:StereoWidth,6:Wet,7:Dry
  local function setn(p, v) set_param(track, fx_idx, p, v) end

  if kind == "verb_long_dark" then
    setn(0, 0.8)
    setn(1, 0.7)
    setn(2, 0.3)
    setn(3, 0.4)
    setn(6, 0.7)
  elseif kind == "verb_huge" then
    setn(0, 0.95)
    setn(1, 0.5)
    setn(2, 0.2)
    setn(3, 0.3)
    setn(6, 0.8)
  end
end

---------------------------------------------------------------------------
-- Main processing
---------------------------------------------------------------------------

local function normalize_key(s)
  if not s then return "" end
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  s = s:lower()
  return s
end

local function main()
  local proj = 0

  -- Read global artist/style/tempo from project ExtStates
  local artist_raw = get_ext(proj, "DF95_ARTIST", "NAME", "")
  local style_raw  = get_ext(proj, "DF95_STYLE",  "NAME", "")
  local tempo_raw  = get_ext(proj, "DF95_ARTIST", "TEMPO", "medium")

  local artist_norm = normalize_key(artist_raw)
  local style_norm  = normalize_key(style_raw)
  local tempo_norm  = normalize_key(tempo_raw)

  local artist_resolved = ARTIST_MAP[artist_norm]
  local style_resolved  = STYLE_ALIASES[style_norm] or style_raw
  local tempo_mult      = TEMPO_MULT[tempo_norm] or 1.0

  dbg("Artist raw: "..tostring(artist_raw).." -> "..tostring(artist_resolved))
  dbg("Style raw: "..tostring(style_raw).." -> "..tostring(style_resolved))
  dbg("Tempo layer: "..tostring(tempo_norm).." -> "..tostring(tempo_mult))

  r.Undo_BeginBlock()

  local num_sel = r.CountSelectedTracks(proj)
  if num_sel == 0 then
    r.ShowMessageBox("Keine Tracks ausgewählt – bitte Tracks wählen, auf die Artist/Style-FX angewendet werden sollen.","DF95 ArtistStyleFX",0)
    r.Undo_EndBlock("DF95 ArtistStyleFX – nichts getan", -1)
    return
  end

  for i = 0, num_sel-1 do
    local tr = r.GetSelectedTrack(proj, i)
    local role = detect_role(proj, tr)

    local recipe = nil

    if artist_resolved then
      recipe = recipe_artist(artist_resolved, role)
    end
    if not recipe and style_resolved and style_resolved ~= "" then
      recipe = recipe_style(style_resolved, role)
    end
    if not recipe then
      recipe = recipe_default(role)
    end

    if recipe and #recipe > 0 then
      for _, fx in ipairs(recipe) do
        local idx = ensure_fx(tr, fx.name)
        if idx >= 0 then
          -- param shaping
          if fx.kind and fx.kind:match("^eq") then
            shape_eq(tr, idx, fx.kind, tempo_mult)
          elseif fx.kind and fx.kind:match("^comp") or fx.kind == "bus_comp" or fx.kind == "bus_multicomp" then
            shape_comp(tr, idx, fx.kind, tempo_mult)
          elseif fx.kind and fx.kind:match("^delay") then
            shape_delay(tr, idx, fx.kind, tempo_mult)
          elseif fx.kind and fx.kind:match("^verb") then
            shape_verb(tr, idx, fx.kind, tempo_mult)
          end
        else
          if not fx.optional then
            dbg("Required FX missing: "..tostring(fx.name))
          end
        end
      end
    end
  end

  r.Undo_EndBlock("DF95 ArtistStyleFX – Apply", -1)
end

main()
