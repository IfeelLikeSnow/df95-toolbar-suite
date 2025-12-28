-- IFLS_ReverbEQDomain.lua
-- Reverb & EQ catalog + artist/style mapping
-- Auto-generated from DF95_AllFX_ParamDump_FULL-1

local r = reaper
local M = {}

----------------------------------------------------------------
-- Catalog: Reverbs and EQs (flattened list from FX dump)
----------------------------------------------------------------

M.reverbs = {
  { id = "vst3_latticereverb_uhhyou", name = "VST3: LatticeReverb (Uhhyou)", flavor = "ambient" },
  { id = "vst3_spaced_out_baby_audio", name = "VST3: Spaced Out (BABY Audio)", flavor = "ambient" },
  { id = "vst3_tal_reverb_4_plugin_tal_togu_audio_line", name = "VST3: TAL Reverb 4 Plugin (TAL-Togu Audio Line)", flavor = "general" },
  { id = "vst3_valhallafreqecho_valhalla_dsp_llc", name = "VST3: ValhallaFreqEcho (Valhalla DSP, LLC)", flavor = "hall" },
  { id = "vst3_valhallaspacemodulator_valhalla_dsp_llc", name = "VST3: ValhallaSpaceModulator (Valhalla DSP, LLC)", flavor = "hall" },
  { id = "vst3_valhallasupermassive_valhalla_dsp_llc", name = "VST3: ValhallaSupermassive (Valhalla DSP, LLC)", flavor = "hall" },
  { id = "vst3_bx_rooms_plugin_alliance", name = "VST3: bx_rooMS (Plugin Alliance)", flavor = "room" },
  { id = "vst3_epicplatemkii_variety_of_sound", name = "VST3: epicPLATEmkII (Variety Of Sound)", flavor = "plate" },
  { id = "vst3_khs_reverb_kilohearts", name = "VST3: kHs Reverb (Kilohearts)", flavor = "general" },
  { id = "vst_brightambience_airwindows", name = "VST: BrightAmbience (airwindows)", flavor = "ambient" },
  { id = "vst_brightambience2_airwindows", name = "VST: BrightAmbience2 (airwindows)", flavor = "ambient" },
  { id = "vst_brightambience3_airwindows", name = "VST: BrightAmbience3 (airwindows)", flavor = "ambient" },
  { id = "vst_dubplate_airwindows", name = "VST: DubPlate (airwindows)", flavor = "plate" },
  { id = "vst_dubplate2_airwindows", name = "VST: DubPlate2 (airwindows)", flavor = "plate" },
  { id = "vst_nonlinearspace_airwindows", name = "VST: NonlinearSpace (airwindows)", flavor = "ambient" },
  { id = "vst_reverb_airwindows", name = "VST: Reverb (airwindows)", flavor = "general" },
  { id = "vst_valhallafreqecho_valhalla_dsp_llc", name = "VST: ValhallaFreqEcho (Valhalla DSP, LLC)", flavor = "hall" },
  { id = "vst_kcathedral_airwindows", name = "VST: kCathedral (airwindows)", flavor = "hall" },
  { id = "vst_kcathedral2_airwindows", name = "VST: kCathedral2 (airwindows)", flavor = "hall" },
  { id = "vst_kcathedral3_airwindows", name = "VST: kCathedral3 (airwindows)", flavor = "hall" },
  { id = "vst_kguitarhall_airwindows", name = "VST: kGuitarHall (airwindows)", flavor = "hall" },
  { id = "vst_kplate140_airwindows", name = "VST: kPlate140 (airwindows)", flavor = "plate" },
  { id = "vst_kplate240_airwindows", name = "VST: kPlate240 (airwindows)", flavor = "plate" },
  { id = "vst_kplatea_airwindows", name = "VST: kPlateA (airwindows)", flavor = "plate" },
  { id = "vst_kplateb_airwindows", name = "VST: kPlateB (airwindows)", flavor = "plate" },
  { id = "vst_kplatec_airwindows", name = "VST: kPlateC (airwindows)", flavor = "plate" },
  { id = "vst_kplated_airwindows", name = "VST: kPlateD (airwindows)", flavor = "plate" },
}


M.eqs = {
  { id = "js_3_band_eq", name = "JS: 3-Band EQ", flavor = "surgical" },
  { id = "js_3x3_eq", name = "JS: 3x3 EQ", flavor = "surgical" },
  { id = "js_3x3_eq_1_pole_crossover", name = "JS: 3x3 EQ (1-Pole Crossover)", flavor = "surgical" },
  { id = "js_4_band_eq", name = "JS: 4-Band EQ", flavor = "surgical" },
  { id = "js_4x4_eq", name = "JS: 4x4 EQ", flavor = "surgical" },
  { id = "js_midi_eq_ducker", name = "JS: MIDI EQ Ducker", flavor = "surgical" },
  { id = "js_presence_eq", name = "JS: Presence EQ", flavor = "surgical" },
  { id = "js_rbj_1073_eq", name = "JS: RBJ 1073 EQ", flavor = "surgical" },
  { id = "js_rbj_12_band_eq_w_hpf", name = "JS: RBJ 12-Band EQ w/HPF", flavor = "surgical" },
  { id = "js_rbj_4_band_semi_parametric_eq", name = "JS: RBJ 4-Band Semi-Parametric EQ", flavor = "parametric" },
  { id = "js_rbj_4_band_semi_parametric_eq_v2", name = "JS: RBJ 4-Band Semi-Parametric EQ v2", flavor = "parametric" },
  { id = "js_rbj_7_band_graphic_eq", name = "JS: RBJ 7-Band Graphic EQ", flavor = "surgical" },
  { id = "js_tilt_equalizer", name = "JS: Tilt Equalizer", flavor = "surgical" },
  { id = "vst3_baxtereq_variety_of_sound", name = "VST3: BaxterEQ (Variety Of Sound)", flavor = "surgical" },
  { id = "vst3_blindfold_eq_audiothing", name = "VST3: Blindfold EQ (AudioThing)", flavor = "surgical" },
  { id = "vst3_blue_cat_s_triple_eq_4_dual_blue_cat_audio", name = "VST3: Blue Cat's Triple EQ 4 (Dual) (Blue Cat Audio)", flavor = "surgical" },
  { id = "vst3_blue_cat_s_triple_eq_4_mono_blue_cat_audio", name = "VST3: Blue Cat's Triple EQ 4 (Mono) (Blue Cat Audio)", flavor = "surgical" },
  { id = "vst3_blue_cat_s_triple_eq_4_stereo_blue_cat_audio", name = "VST3: Blue Cat's Triple EQ 4 (Stereo) (Blue Cat Audio)", flavor = "surgical" },
  { id = "vst3_free_eq_venn_audio", name = "VST3: Free EQ (Venn Audio)", flavor = "surgical" },
  { id = "vst3_ozone_12_equalizer_izotope", name = "VST3: Ozone 12 Equalizer (iZotope)", flavor = "surgical" },
  { id = "vst3_rezzoeq_evilturtleproductions", name = "VST3: RezzoEQ (EvilTurtleProductions)", flavor = "surgical" },
  { id = "vst3_tdr_vos_slickeq_tokyo_dawn_labs", name = "VST3: TDR VOS SlickEQ (Tokyo Dawn Labs)", flavor = "surgical" },
  { id = "vst3_zl_equalizer_zl", name = "VST3: ZL Equalizer (ZL)", flavor = "surgical" },
  { id = "vst3_bx_2098_eq_plugin_alliance", name = "VST3: bx_2098 EQ (Plugin Alliance)", flavor = "surgical" },
  { id = "vst3_bx_dyneq_v2_plugin_alliance", name = "VST3: bx_dynEQ V2 (Plugin Alliance)", flavor = "surgical" },
  { id = "vst3_bx_dyneq_v2_mono_plugin_alliance", name = "VST3: bx_dynEQ V2 Mono (Plugin Alliance)", flavor = "surgical" },
  { id = "vst3_bx_paneq_plugin_alliance", name = "VST3: bx_panEQ (Plugin Alliance)", flavor = "surgical" },
  { id = "vst3_khs_3_band_eq_kilohearts", name = "VST3: kHs 3-Band EQ (Kilohearts)", flavor = "surgical" },
  { id = "vst_angleeq_airwindows", name = "VST: AngleEQ (airwindows)", flavor = "surgical" },
  { id = "vst_bezeq_airwindows", name = "VST: BezEQ (airwindows)", flavor = "surgical" },
  { id = "vst_eq_airwindows", name = "VST: EQ (airwindows)", flavor = "surgical" },
  { id = "vst_mackeq_airwindows", name = "VST: MackEQ (airwindows)", flavor = "surgical" },
  { id = "vst_reaeq_cockos", name = "VST: ReaEQ (Cockos)", flavor = "parametric" },
  { id = "vst_reaeq_reaplugs_edition_cockos", name = "VST: ReaEQ (ReaPlugs Edition) (Cockos)", flavor = "parametric" },
  { id = "vst_reafir_fft_eq_dynamics_processor_cockos", name = "VST: ReaFir (FFT EQ+Dynamics Processor) (Cockos)", flavor = "dynamic" },
  { id = "vst_reseq_airwindows", name = "VST: ResEQ (airwindows)", flavor = "surgical" },
  { id = "vst_rezzoeq_evilturtleproductions", name = "VST: RezzoEQ (EvilTurtleProductions)", flavor = "surgical" },
  { id = "vst_smootheq_airwindows", name = "VST: SmoothEQ (airwindows)", flavor = "surgical" },
  { id = "vst_splineeq_photosounder", name = "VST: SplineEQ (Photosounder)", flavor = "surgical" },
}


----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function normalize_tag(t)
  if not t then return "" end
  t = tostring(t):lower()
  return t
end

function M.get_all_reverbs()
  return M.reverbs or {}
end

function M.get_all_eqs()
  return M.eqs or {}
end

function M.filter_reverbs_by_flavor(flav)
  flav = normalize_tag(flav)
  local out = {}
  for _, rv in ipairs(M.reverbs or {}) do
    if normalize_tag(rv.flavor) == flav or flav == "" then
      out[#out+1] = rv
    end
  end
  return out
end

function M.filter_eqs_by_flavor(flav)
  flav = normalize_tag(flav)
  local out = {}
  for _, eq in ipairs(M.eqs or {}) do
    if normalize_tag(eq.flavor) == flav or flav == "" then
      out[#out+1] = eq
    end
  end
  return out
end

----------------------------------------------------------------
-- Artist / Style Mapping
----------------------------------------------------------------

-- einfache Zuordnung von Artist-Tags zu Reverb/EQ-Flavours

local STYLE_MAP = {
  IDM = { reverb_flavor = "general",   eq_flavor = "surgical"   },
  Glitch = { reverb_flavor = "general",   eq_flavor = "surgical"   },
  ClicksPops = { reverb_flavor = "room",     eq_flavor = "surgical"   },
  Microbeat = { reverb_flavor = "room",     eq_flavor = "parametric" },
  LoFi = { reverb_flavor = "plate",    eq_flavor = "character" },
  Ambient = { reverb_flavor = "ambient",  eq_flavor = "linear"     },
  Drone = { reverb_flavor = "ambient",  eq_flavor = "linear"     },
  Cinematic = { reverb_flavor = "hall",     eq_flavor = "surgical"   },
  Experimental = { reverb_flavor = "resonant", eq_flavor = "parametric" },
}

local function pick_from_list(list)
  if not list or #list == 0 then return nil end
  return list[1]
end

-- artist_id: string
-- artist_domain: optional handle auf IFLS_ArtistDomain (für Tags/META)
function M.build_chain_for_artist(artist_id, artist_domain)
  artist_id = tostring(artist_id or "")

  local tags = {}
  local meta = nil

  if artist_domain and type(artist_domain) == "table" then
    if artist_domain.get_tags_for_artist then
      tags = artist_domain.get_tags_for_artist(artist_id) or {}
    end
    if artist_domain.ARTIST_META and artist_domain.ARTIST_META[artist_id] then
      meta = artist_domain.ARTIST_META[artist_id]
    end
  end

  -- fallback tags aus META, falls get_tags_for_artist nicht existiert
  if (not tags or #tags == 0) and meta and type(meta.tags) == "table" then
    tags = meta.tags
  end

  local chosen_style = nil

  for _, t in ipairs(tags or {}) do
    local key = t
    if type(key) == "string" then
      key = key:gsub("%s+", "")
    end
    if STYLE_MAP[key] then
      chosen_style = STYLE_MAP[key]
      break
    end
  end

  if not chosen_style then
    -- generischer Fallback: neutrales Setup
    chosen_style = { reverb_flavor = "general", eq_flavor = "surgical" }
  end

  local reverb_list = M.filter_reverbs_by_flavor(chosen_style.reverb_flavor or "general")
  local eq_list     = M.filter_eqs_by_flavor(chosen_style.eq_flavor or "surgical")

  local reverb_fx = pick_from_list(reverb_list)
  local eq_fx     = pick_from_list(eq_list)

  return {
    reverb = reverb_fx,
    eq     = eq_fx,
    style  = chosen_style,
  }
end

return M
