-- @description DF95_V102_Fieldrec_ArtistStyleBeatEngine_MIDI_MultiArtist
-- @version 1.0
-- @author DF95
-- @about
--   Erweiterte Artist+Style BeatEngine für Fieldrec-Kits (V95/V98).
--   Artist = konkrete Künstlerpersönlichkeit (Aphex Twin, Autechre, Boards of Canada,
--             Squarepusher + zusätzliche Artists wie µ-ziq, Apparat, Arovane, Björk,
--             Bochum Welt, Bogdan Raczynski, Burial, Cylob, DMX Krew, Flying Lotus,
--             Four Tet, The Future Sound Of London, I am Robot and Proud, Isan,
--             Jan Jelinek, Jega, Legowelt, Matmos, Moderat, Photek, Plaid, Skylab,
--             Telefon Tel Aviv, Thom Yorke, Tim Hecker, Proem).
--   Style  = musikalischer Stil/Textur-Layer (IDM_Style, Glitch_Style, WarmTape_Style,
--             HarshDigital_Style, Neutral).
--
--   Artist steuert die "Persönlichkeit" des Beats (Komplexität, Breakbeat-Bias,
--   Ghost-Notes, Hat-Dichte, Swing/Jitter-Baseline).
--   Style wirkt als Layer auf dieses Profil (mehr/weniger Dichte, mehr/weniger Swing
--   oder Harshness etc.).
--
--   Typischer Workflow:
--     1. Fieldrec via V95/V95.2 splitten + klassifizieren.
--     2. V98_SliceKit_RS5k bauen (Kick=36, Snare=38, Hat=42).
--     3. Dieses Script starten:
--        - Artist auswählen (echte Künstlerliste).
--        - Style auswählen (IDM/Glitch/WarmTape/HarshDigital/Neutral).
--        - Anzahl Takte eingeben.
--        -> Track "V102_ArtistStyleBeat_MIDI" mit Artist+Style-Beat wird erzeugt.
--     4. MIDI-Track auf SliceKit oder anderes Drum-Instrument routen.
--
--   Hinweis:
--     - Die zusätzlichen Artists werden intern auf Cluster gemappt
--       (z.B. µ-ziq eher zwischen Aphex/Squarepusher, Flying Lotus zwischen
--       Jazz/IDM/Beats, Burial in Richtung 2Step/Offgrid-Groove etc.).
--     - Die Emulation ist stilisiert und nicht als exakte Kopie gedacht.
--

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowMessageBox(s, "DF95 V102 Artist+Style BeatEngine", 0)
end

local function get_project_tempo_timesig()
  local proj = 0
  local _, tempo, num, denom, _ = r.GetProjectTimeSignature2(proj)
  return tempo, num, denom
end

------------------------------------------------------------
-- Artist/Style Auswahl + Persistenz
------------------------------------------------------------

local ARTIST_KEY = "DF95_ARTIST"
local STYLE_KEY  = "DF95_STYLE"
local ARTIST_EXT_KEY = "NAME"
local STYLE_EXT_KEY  = "NAME"

local ARTIST_LIST = {
  "Aphex Twin",
  "Autechre",
  "Boards of Canada",
  "Squarepusher",
  "µ-ziq",
  "Apparat",
  "Arovane",
  "Björk",
  "Bochum Welt",
  "Bogdan Raczynski",
  "Burial",
  "Cylob",
  "DMX Krew",
  "Flying Lotus",
  "Four Tet",
  "The Future Sound Of London",
  "I am Robot and Proud",
  "Isan",
  "Jan Jelinek",
  "Jega",
  "Legowelt",
  "Matmos",
  "Moderat",
  "Photek",
  "Plaid",
  "Skylab",
  "Telefon Tel Aviv",
  "Thom Yorke",
  "Tim Hecker",
  "Proem",
}

local STYLE_LIST = {
  "Neutral",
  "IDM_Style",
  "Glitch_Style",
  "WarmTape_Style",
  "HarshDigital_Style",
}

local function normalize_artist_name(a)
  if not a or a == "" then return nil end
  local al = a:lower()

  if al:find("aphextwin") or al == "aphex twin" then return "Aphex Twin" end
  if al:find("autechre") then return "Autechre" end
  if al:find("boards") or al:find("boc") then return "Boards of Canada" end
  if al:find("square") then return "Squarepusher" end
  if al:find("u%-?ziq") or al:find("µ%-?ziq") or al:find("mu%-?ziq") then return "µ-ziq" end
  if al:find("apparat") then return "Apparat" end
  if al:find("arovane") then return "Arovane" end
  if al:find("bjork") or al:find("björk") then return "Björk" end
  if al:find("bochum") and al:find("welt") then return "Bochum Welt" end
  if al:find("bogdan") then return "Bogdan Raczynski" end
  if al:find("burial") then return "Burial" end
  if al:find("cylob") then return "Cylob" end
  if al:find("dmx") and al:find("krew") then return "DMX Krew" end
  if al:find("flying") and al:find("lotus") then return "Flying Lotus" end
  if al:find("four") and al:find("tet") then return "Four Tet" end
  if al:find("future") and al:find("sound") then return "The Future Sound Of London" end
  if al:find("i am robot") or al:find("iamrobot") then return "I am Robot and Proud" end
  if al:find("isan") then return "Isan" end
  if al:find("jan") and al:find("jelinek") then return "Jan Jelinek" end
  if al:find("jega") then return "Jega" end
  if al:find("legowelt") then return "Legowelt" end
  if al:find("matmos") then return "Matmos" end
  if al:find("moderat") then return "Moderat" end
  if al:find("photek") then return "Photek" end
  if al:find("plaid") then return "Plaid" end
  if al:find("skylab") then return "Skylab" end
  if al:find("telefon") and al:find("tel") then return "Telefon Tel Aviv" end
  if al:find("thom") and al:find("yorke") then return "Thom Yorke" end
  if al:find("tim") and al:find("hecker") then return "Tim Hecker" end
  if al:find("proem") then return "Proem" end

  return nil
end

local function get_or_choose_artist()
  local _, cur = r.GetProjExtState(0, ARTIST_KEY, ARTIST_EXT_KEY)
  local norm = normalize_artist_name(cur)
  if norm then return norm end

  -- Auswahlmenü
  local menu_str = table.concat(ARTIST_LIST, "|")
  local _,_, mx,my = r.GetMousePosition()
  gfx.init("DF95 Artist Select", 1,1,0,mx,my)
  local sel = gfx.showmenu(menu_str)
  gfx.quit()
  local artist
  if sel < 1 or sel > #ARTIST_LIST then
    artist = ARTIST_LIST[1]
  else
    artist = ARTIST_LIST[sel]
  end
  r.SetProjExtState(0, ARTIST_KEY, ARTIST_EXT_KEY, artist)
  return artist
end

local function normalize_style_name(s)
  if not s or s == "" then return nil end
  local sl = s:lower()
  if sl == "neutral" then return "Neutral" end
  if sl:find("idm") then return "IDM_Style" end
  if sl:find("glitch") then return "Glitch_Style" end
  if sl:find("warm") or sl:find("tape") then return "WarmTape_Style" end
  if sl:find("harsh") or sl:find("digital") then return "HarshDigital_Style" end
  return nil
end

local function get_or_choose_style()
  local _, cur = r.GetProjExtState(0, STYLE_KEY, STYLE_EXT_KEY)
  local norm = normalize_style_name(cur)
  if norm then return norm end

  local menu_str = table.concat(STYLE_LIST, "|")
  local _,_, mx,my = r.GetMousePosition()
  gfx.init("DF95 Style Select", 1,1,0,mx,my)
  local sel = gfx.showmenu(menu_str)
  gfx.quit()
  local style
  if sel < 1 or sel > #STYLE_LIST then
    style = STYLE_LIST[1]
  else
    style = STYLE_LIST[sel]
  end
  r.SetProjExtState(0, STYLE_KEY, STYLE_EXT_KEY, style)
  return style
end

------------------------------------------------------------
-- Artist-/Style-Profile
------------------------------------------------------------

local function get_artist_profile(artist)
  -- Basis: Aphex/Autechre/BoC/Squarepusher-Profile als archetypes.
  local p = {
    name = artist or "Unknown",
    complexity = 1.0,
    breakbeat_bias = 0.0,
    ghost_prob = 0.0,
    hat_density = 1.0,
    swing = 0.0,
    jitter = 0.0,
    vel_main = 110,
    vel_ghost = 80,
  }

  if artist == "Aphex Twin" then
    p.complexity      = 1.4
    p.breakbeat_bias  = 0.6
    p.ghost_prob      = 0.4
    p.hat_density     = 1.6
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 112
    p.vel_ghost       = 82
  elseif artist == "Autechre" then
    p.complexity      = 1.6
    p.breakbeat_bias  = 0.8
    p.ghost_prob      = 0.35
    p.hat_density     = 1.8
    p.swing           = 0.02
    p.jitter          = 0.03
    p.vel_main        = 115
    p.vel_ghost       = 85
  elseif artist == "Boards of Canada" then
    p.complexity      = 0.8
    p.breakbeat_bias  = 0.2
    p.ghost_prob      = 0.2
    p.hat_density     = 0.7
    p.swing           = 0.03
    p.jitter          = 0.02
    p.vel_main        = 100
    p.vel_ghost       = 70
  elseif artist == "Squarepusher" then
    p.complexity      = 1.9
    p.breakbeat_bias  = 0.9
    p.ghost_prob      = 0.5
    p.hat_density     = 2.2
    p.swing           = 0.0
    p.jitter          = 0.015
    p.vel_main        = 120
    p.vel_ghost       = 90

  -- µ-ziq: zwischen Aphex/Squarepusher, braindance, drill&bass
  elseif artist == "µ-ziq" then
    p.complexity      = 1.7
    p.breakbeat_bias  = 0.7
    p.ghost_prob      = 0.35
    p.hat_density     = 1.8
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 115
    p.vel_ghost       = 85

  -- Apparat: eher kontrollierte, emotive Elektronik, moderate Komplexität
  elseif artist == "Apparat" then
    p.complexity      = 1.1
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 105
    p.vel_ghost       = 78

  -- Arovane: IDM, melodisch, detaillierte Micro-Patterns aber nicht extrem
  elseif artist == "Arovane" then
    p.complexity      = 1.2
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.3
    p.hat_density     = 1.2
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 108
    p.vel_ghost       = 80

  -- Björk: Beats oft experimentell aber Song-orientiert, moderate Dichte
  elseif artist == "Björk" then
    p.complexity      = 1.1
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 105
    p.vel_ghost       = 78

  -- Bochum Welt: eher klassisch/retro-IDM, moderat
  elseif artist == "Bochum Welt" then
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.2
    p.hat_density     = 1.0
    p.swing           = 0.015
    p.jitter          = 0.015
    p.vel_main        = 104
    p.vel_ghost       = 76

  -- Bogdan Raczynski: sehr wild, chaotische Breakbeats
  elseif artist == "Bogdan Raczynski" then
    p.complexity      = 2.0
    p.breakbeat_bias  = 0.95
    p.ghost_prob      = 0.5
    p.hat_density     = 2.2
    p.swing           = 0.0
    p.jitter          = 0.03
    p.vel_main        = 122
    p.vel_ghost       = 92

  -- Burial: offgrid, 2Step/Future-Garage, viel Swing, weniger Dichte
  elseif artist == "Burial" then
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.35
    p.hat_density     = 0.8
    p.swing           = 0.04
    p.jitter          = 0.02
    p.vel_main        = 100
    p.vel_ghost       = 75

  -- Cylob: Warp-IDM, eigenartig, moderate Komplexität
  elseif artist == "Cylob" then
    p.complexity      = 1.3
    p.breakbeat_bias  = 0.5
    p.ghost_prob      = 0.3
    p.hat_density     = 1.3
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 110
    p.vel_ghost       = 82

  -- DMX Krew: Electro/Funk, klarere Grooves, weniger Chaos
  elseif artist == "DMX Krew" then
    p.complexity      = 0.9
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.15
    p.hat_density     = 1.0
    p.swing           = 0.015
    p.jitter          = 0.01
    p.vel_main        = 105
    p.vel_ghost       = 78

  -- Flying Lotus: beats+Jazz+IDM, polyrhythmisch, aber groovig
  elseif artist == "Flying Lotus" then
    p.complexity      = 1.5
    p.breakbeat_bias  = 0.5
    p.ghost_prob      = 0.35
    p.hat_density     = 1.6
    p.swing           = 0.03
    p.jitter          = 0.02
    p.vel_main        = 112
    p.vel_ghost       = 84

  -- Four Tet: organische, rhythmische Loops, moderate Komplexität
  elseif artist == "Four Tet" then
    p.complexity      = 1.2
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.3
    p.hat_density     = 1.4
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 108
    p.vel_ghost       = 80

  -- The Future Sound Of London: breakbeat/ambient hybrid
  elseif artist == "The Future Sound Of London" then
    p.complexity      = 1.1
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.02
    p.vel_main        = 106
    p.vel_ghost       = 78

  -- I am Robot and Proud: melodisch, freundlich, moderate Komplexität
  elseif artist == "I am Robot and Proud" then
    p.complexity      = 1.1
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 104
    p.vel_ghost       = 78

  -- Isan: warm, minimalistisch, weniger Dichte
  elseif artist == "Isan" then
    p.complexity      = 0.9
    p.breakbeat_bias  = 0.2
    p.ghost_prob      = 0.2
    p.hat_density     = 0.8
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 100
    p.vel_ghost       = 75

  -- Jan Jelinek: klicks/cuts, aber eher subtil, minimal
  elseif artist == "Jan Jelinek" then
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 0.9
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 102
    p.vel_ghost       = 76

  -- Jega: Warp-IDM, eher Aphex-nah
  elseif artist == "Jega" then
    p.complexity      = 1.4
    p.breakbeat_bias  = 0.6
    p.ghost_prob      = 0.35
    p.hat_density     = 1.5
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 110
    p.vel_ghost       = 82

  -- Legowelt: Electro/House/LoFi, solide Grooves
  elseif artist == "Legowelt" then
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.2
    p.hat_density     = 1.1
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 108
    p.vel_ghost       = 80

  -- Matmos: konzeptuell, viele überraschende Elemente
  elseif artist == "Matmos" then
    p.complexity      = 1.5
    p.breakbeat_bias  = 0.5
    p.ghost_prob      = 0.4
    p.hat_density     = 1.4
    p.swing           = 0.02
    p.jitter          = 0.02
    p.vel_main        = 110
    p.vel_ghost       = 82

  -- Moderat: Apparat+Modeselektor -> klarere Songstrukturen
  elseif artist == "Moderat" then
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 106
    p.vel_ghost       = 78

  -- Photek: sehr präzise Drum&Bass-Breakbeats
  elseif artist == "Photek" then
    p.complexity      = 1.7
    p.breakbeat_bias  = 0.9
    p.ghost_prob      = 0.3
    p.hat_density     = 1.6
    p.swing           = 0.0
    p.jitter          = 0.015
    p.vel_main        = 115
    p.vel_ghost       = 82

  -- Plaid: melodisch, IDM, ausgewogen
  elseif artist == "Plaid" then
    p.complexity      = 1.2
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.3
    p.hat_density     = 1.2
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 108
    p.vel_ghost       = 80

  -- Skylab: abstrakte TripHop/Elektronik, nicht zu dicht
  elseif artist == "Skylab" then
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.02
    p.vel_main        = 104
    p.vel_ghost       = 78

  -- Telefon Tel Aviv: emotive, detailreiche Beats, kontrolliert
  elseif artist == "Telefon Tel Aviv" then
    p.complexity      = 1.2
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.3
    p.hat_density     = 1.2
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 108
    p.vel_ghost       = 80

  -- Thom Yorke: experimentelle, aber strukturierte Elektronik
  elseif artist == "Thom Yorke" then
    p.complexity      = 1.1
    p.breakbeat_bias  = 0.3
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.02
    p.jitter          = 0.015
    p.vel_main        = 106
    p.vel_ghost       = 78

  -- Tim Hecker: eher ambient/Drone, sehr geringe Beat-Dichte
  elseif artist == "Tim Hecker" then
    p.complexity      = 0.5
    p.breakbeat_bias  = 0.1
    p.ghost_prob      = 0.15
    p.hat_density     = 0.4
    p.swing           = 0.01
    p.jitter          = 0.015
    p.vel_main        = 95
    p.vel_ghost       = 70

  -- Proem: IDM, detailliert, aber nicht extrem wild
  elseif artist == "Proem" then
    p.complexity      = 1.3
    p.breakbeat_bias  = 0.5
    p.ghost_prob      = 0.3
    p.hat_density     = 1.3
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 108
    p.vel_ghost       = 80

  else
    -- Fallback: moderater IDM-Style
    p.complexity      = 1.0
    p.breakbeat_bias  = 0.4
    p.ghost_prob      = 0.25
    p.hat_density     = 1.0
    p.swing           = 0.015
    p.jitter          = 0.02
    p.vel_main        = 108
    p.vel_ghost       = 80
  end

  return p
end

local function get_style_profile(style)
  local s = {
    name = style or "Neutral",
    complexity_mul  = 1.0,
    breakbeat_mul   = 1.0,
    ghost_mul       = 1.0,
    hat_density_mul = 1.0,
    swing_add       = 0.0,
    jitter_add      = 0.0,
    vel_main_mul    = 1.0,
    vel_ghost_mul   = 1.0,
  }

  if style == "Neutral" then
    -- keine Änderung
  elseif style == "IDM_Style" then
    s.complexity_mul   = 1.2
    s.breakbeat_mul    = 1.1
    s.ghost_mul        = 1.1
    s.hat_density_mul  = 1.1
    s.swing_add        = 0.005
    s.jitter_add       = 0.005
  elseif style == "Glitch_Style" then
    s.complexity_mul   = 1.4
    s.breakbeat_mul    = 1.3
    s.ghost_mul        = 1.3
    s.hat_density_mul  = 1.3
    s.swing_add        = 0.0
    s.jitter_add       = 0.01
  elseif style == "WarmTape_Style" then
    s.complexity_mul   = 0.9
    s.breakbeat_mul    = 0.9
    s.ghost_mul        = 0.9
    s.hat_density_mul  = 0.8
    s.swing_add        = 0.01
    s.jitter_add       = 0.003
    s.vel_main_mul     = 0.92
    s.vel_ghost_mul    = 0.9
  elseif style == "HarshDigital_Style" then
    s.complexity_mul   = 1.3
    s.breakbeat_mul    = 1.4
    s.ghost_mul        = 1.2
    s.hat_density_mul  = 1.2
    s.swing_add        = -0.005
    s.jitter_add       = 0.008
    s.vel_main_mul     = 1.05
    s.vel_ghost_mul    = 1.05
  end

  return s
end

local function merge_profiles(artist_p, style_p)
  local r = {}

  r.name = (artist_p.name or "?") .. " + " .. (style_p.name or "?")

  r.complexity = (artist_p.complexity or 1.0) * (style_p.complexity_mul or 1.0)
  r.breakbeat_bias = (artist_p.breakbeat_bias or 0.0) * (style_p.breakbeat_mul or 1.0)
  r.ghost_prob = (artist_p.ghost_prob or 0.0) * (style_p.ghost_mul or 1.0)
  r.hat_density = (artist_p.hat_density or 1.0) * (style_p.hat_density_mul or 1.0)

  r.swing = (artist_p.swing or 0.0) + (style_p.swing_add or 0.0)
  r.jitter = (artist_p.jitter or 0.0) + (style_p.jitter_add or 0.0)

  r.vel_main = (artist_p.vel_main or 110) * (style_p.vel_main_mul or 1.0)
  r.vel_ghost = (artist_p.vel_ghost or 80) * (style_p.vel_ghost_mul or 1.0)

  if r.hat_density < 0.1 then r.hat_density = 0.1 end
  if r.hat_density > 2.5 then r.hat_density = 2.5 end
  if r.complexity < 0.3 then r.complexity = 0.3 end
  if r.complexity > 2.5 then r.complexity = 2.5 end

  return r
end

------------------------------------------------------------
-- Pattern-Generation
------------------------------------------------------------

local function build_base_patterns(beats_per_bar)
  local K = {0.0, 2.0}
  local S = {1.0, 3.0}
  local H = {}
  local step = 0.5
  local t = 0.0
  while t < beats_per_bar do
    H[#H+1] = t
    t = t + step
  end
  return K, S, H
end

local function add_variations(K, S, H, prof, beats_per_bar)
  local function add_kick(pos)
    if pos >= 0 and pos < beats_per_bar then
      K[#K+1] = pos
    end
  end
  local function add_snare(pos)
    if pos >= 0 and pos < beats_per_bar then
      S[#S+1] = pos
    end
  end
  local function add_hat(pos)
    if pos >= 0 and pos < beats_per_bar then
      H[#H+1] = pos
    end
  end

  local complexity = prof.complexity or 1.0

  local bb = prof.breakbeat_bias or 0.0
  if bb > 0.05 then
    local offbeats = {0.75, 1.75, 2.75, 3.75}
    for _,pos in ipairs(offbeats) do
      if math.random() < bb then
        if math.random() < 0.5 then add_kick(pos) else add_snare(pos) end
      end
    end
  end

  local kv = math.max(0, complexity - 1.0)
  local sv = kv

  if kv > 0.05 then
    local candidates = {0.5, 1.5, 2.5, 3.5}
    for _,pos in ipairs(candidates) do
      if math.random() < kv then add_kick(pos) end
    end
  end

  if sv > 0.05 then
    local candidates = {0.25, 0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75}
    for _,pos in ipairs(candidates) do
      if math.random() < sv * 0.7 then add_snare(pos) end
    end
  end

  local hd = prof.hat_density or 1.0
  if hd > 1.05 then
    local step = 0.25
    local t = 0.0
    while t < beats_per_bar do
      if math.random() < (hd - 1.0) then add_hat(t) end
      t = t + step
    end
  elseif hd < 0.95 then
    local keep = {}
    for _,pos in ipairs(H) do
      if math.random() < hd then keep[#keep+1] = pos end
    end
    H = keep
  end

  return K, S, H
end

------------------------------------------------------------
-- MIDI Beat erzeugen
------------------------------------------------------------

local function create_midi_track()
  local proj = 0
  local idx = r.CountTracks(proj)
  r.InsertTrackAtIndex(idx, true)
  local tr = r.GetTrack(proj, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "V102_ArtistStyleBeat_MIDI", true)
  return tr
end

local function main()
  math.randomseed(os.time())

  local tempo, num, denom = get_project_tempo_timesig()
  local beats_per_bar = num

  local artist = get_or_choose_artist()
  local style  = get_or_choose_style()

  local artist_p = get_artist_profile(artist)
  local style_p  = get_style_profile(style)
  local prof     = merge_profiles(artist_p, style_p)

  local default_bars = "8"
  local ret, inp = r.GetUserInputs("DF95 V102 Artist+Style BeatEngine", 1,
                                   "Bars (Anzahl Takte)", default_bars)
  if not ret then return end
  local bars = tonumber(inp) or 8
  if bars < 1 then bars = 1 end

  local proj = 0
  local start_beat = 0.0
  local end_beat = bars * beats_per_bar
  local start_time = r.TimeMap2_beatsToTime(proj, start_beat, 0)
  local end_time   = r.TimeMap2_beatsToTime(proj, end_beat, 0)
  local item_len   = end_time - start_time

  local track = create_midi_track()
  local item = r.AddMediaItemToTrack(track)
  r.SetMediaItemInfo_Value(item, "D_POSITION", start_time)
  r.SetMediaItemInfo_Value(item, "D_LENGTH",  item_len)

  local take = r.AddTakeToMediaItem(item)
  r.SetMediaItemTakeInfo_Value(take, "C_LOCK", 0)
  r.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", 0)

  local PPQ = 960
  local function beat_to_ppq(beat)
    return beat * PPQ
  end

  local base_K, base_S, base_H = build_base_patterns(beats_per_bar)
  local K,S,H = add_variations(base_K, base_S, base_H, prof, beats_per_bar)

  local K_NOTE = 36
  local S_NOTE = 38
  local H_NOTE = 42

  local vel_main  = prof.vel_main or 110
  local vel_ghost = prof.vel_ghost or 80
  local note_len_beats = 0.3

  local swing = prof.swing or 0.0
  local jitter = prof.jitter or 0.0
  local ghost_prob = prof.ghost_prob or 0.0

  local function apply_swing_and_jitter(pos_beats, is_hat)
    local b = pos_beats
    if swing ~= 0 then
      local frac = (b * 4.0) % 1.0
      if frac > 0.25 and frac < 0.75 then
        b = b + swing * 0.5
      end
    end
    if jitter ~= 0 then
      local j = (math.random() * 2 - 1) * jitter
      b = b + j
    end
    return b
  end

  r.Undo_BeginBlock()

  -- Kicks
  for bar = 0, bars-1 do
    for _, beat in ipairs(K) do
      local pos_beats = bar * beats_per_bar + beat
      pos_beats = apply_swing_and_jitter(pos_beats, false)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, K_NOTE, vel_main, false)
    end
  end

  -- Snares
  for bar = 0, bars-1 do
    for _, beat in ipairs(S) do
      local pos_beats = bar * beats_per_bar + beat
      local vel = vel_main
      local is_ghost = false
      if ghost_prob > 0 and math.random() < ghost_prob * 0.3 then
        is_ghost = true
        vel = vel_ghost
      end
      pos_beats = apply_swing_and_jitter(pos_beats, false)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats)
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, S_NOTE, vel, false)

      if ghost_prob > 0 and math.random() < ghost_prob * 0.2 then
        local ghost_beat = pos_beats - 0.1
        local g_ppq = beat_to_ppq(ghost_beat)
        local g_end = beat_to_ppq(ghost_beat + 0.2)
        r.MIDI_InsertNote(take, false, false, g_ppq, g_end, 0, S_NOTE, vel_ghost, false)
      end
    end
  end

  -- Hats
  for bar = 0, bars-1 do
    for _, beat in ipairs(H) do
      local pos_beats = bar * beats_per_bar + beat
      local vel = vel_main
      local is_ghost = false
      if ghost_prob > 0 and math.random() < ghost_prob then
        is_ghost = true
        vel = vel_ghost
      end
      pos_beats = apply_swing_and_jitter(pos_beats, true)
      local start_ppq = beat_to_ppq(pos_beats)
      local end_ppq   = beat_to_ppq(pos_beats + note_len_beats * (is_ghost and 0.8 or 1.0))
      r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, H_NOTE, vel, false)
    end
  end

  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 V102 Artist+Style BeatEngine ("..(prof.name or "?")..")", -1)
end

main()
