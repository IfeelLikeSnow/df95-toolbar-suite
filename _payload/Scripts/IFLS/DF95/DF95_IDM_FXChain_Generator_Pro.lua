-- @description IDM FXChain Generator PRO (Metadata-Core aware, v2)
-- @version 2.0
-- @author DF95
-- @about
--   Erzeugt typische IDM FX-Ketten auf dem ausgewählten Track
--   und nutzt DF95_Metadata_Core v2 (erweiterte Tags/Rollen).

local r = reaper

local function msg(s) r.ShowConsoleMsg(tostring(s) .. "\n") end

local function ensure_track()
  local tr = r.GetSelectedTrack(0,0)
  if not tr then
    r.ShowMessageBox("Bitte zuerst einen Track auswählen.","DF95 IDM FXChain Generator PRO",0)
    return nil
  end
  return tr
end

local function join(...)
  local sep = package.config:sub(1,1)
  local t = {...}
  return table.concat(t, sep)
end

------------------------------------------------------------
-- Metadata-Core laden
------------------------------------------------------------

local Meta = nil

local function load_metadata_core()
  if Meta ~= nil then return Meta end
  local respath = r.GetResourcePath()
  local meta_path = join(respath,"Scripts","IfeelLikeSnow","DF95","DF95_Metadata_Core.lua")
  local f, err = loadfile(meta_path)
  if not f then
    msg("DF95 Metadata-Core nicht gefunden:\n"..tostring(err))
    msg("Erwartet: "..meta_path)
    msg("Weiter im Lite-Modus (nur ReaFX / Fallback-Namen).")
    Meta = false
    return Meta
  end
  local ok, mod = pcall(f)
  if not ok then
    msg("Fehler beim Ausführen von Metadata-Core:\n"..tostring(mod))
    Meta = false
    return Meta
  end
  Meta = mod
  Meta.load()
  msg("DF95 Metadata-Core v2 geladen.")
  return Meta
end

------------------------------------------------------------
-- FX-Add Helpers
------------------------------------------------------------

local function add_fx_by_name(tr,name)
  local idx = r.TrackFX_AddByName(tr,name,false,-1)
  if idx < 0 then
    msg("WARN – Plugin nicht gefunden: "..name)
  else
    msg("OK   – Plugin hinzugefügt: "..name)
  end
  return idx
end

local function add_fx_meta_choice(tr,candidates,desc,fallback_names)
  if Meta and candidates and #candidates>0 then
    local pl = candidates[1]
    msg(("Wähle %s: %s (%s)"):format(desc,pl.name,pl.developer or "?"))
    return add_fx_by_name(tr, pl.name)
  end
  if fallback_names then
    for _,n in ipairs(fallback_names) do
      local idx = add_fx_by_name(tr,n)
      if idx >= 0 then
        msg(("Fallback für %s: %s"):format(desc,n))
        return idx
      end
    end
  end
  msg("Keine passende FX für "..desc.." gefunden.")
  return -1
end

------------------------------------------------------------
-- Selector-Helper
------------------------------------------------------------

local function select_by_role(role)
  if not Meta or not Meta.db then return {} end
  return Meta.filter({role=role})
end

local function select_by_tag(tag)
  if not Meta or not Meta.db then return {} end
  return Meta.filter({tag=tag})
end

local function select_by_tags_any(tags_list)
  if not Meta or not Meta.db then return {} end
  local res = {}
  for _,pl in ipairs(Meta.db.plugins) do
    local hit = false
    for _,tag in ipairs(tags_list) do
      for _,t in ipairs(pl.tags or {}) do
        if t == tag then hit = true break end
      end
      if hit then break end
    end
    if hit then table.insert(res, pl) end
  end
  return res
end

------------------------------------------------------------
-- Ketten
------------------------------------------------------------

local function chain_idm_drum_elastic(tr)
  msg("=== IDM Drum: Elastic Resonator (Autechre-ish) ===")
  load_metadata_core()

  add_fx_by_name(tr,"ReaEQ (Cockos)")
  add_fx_by_name(tr,"ReaComp (Cockos)")
  add_fx_by_name(tr,"ReaDelay (Cockos)")

  local glitch = select_by_tags_any({"IDM_BUFFER","IDM_RESONATOR","IDM_GLITCH"})
  add_fx_meta_choice(
    tr,
    glitch,
    "IDM-Resonator/Buffer",
    {"FractureXT","Fracture","Cryogen","kHs Resonator","dblue Glitch"}
  )

  r.ShowMessageBox(
    "IDM Elastic-Resonator-Kette erzeugt.\n\n"..
    "Nutze short delays, Resonanz und ggf. Glitch/Buffer FX für tonale 'Rings'.",
    "DF95 IDM – Elastic Resonator",0)
end

local function chain_idm_drum_breakcrunch(tr)
  msg("=== IDM Drum: BreakCrunch (Aphex/Squarepusher-ish) ===")
  load_metadata_core()

  add_fx_by_name(tr,"ReaEQ (Cockos)")
  add_fx_by_name(tr,"ReaComp (Cockos)")

  local chaos = select_by_tags_any({"IDM_CHAOS","DISTORTION","IDM_GLITCH"})
  add_fx_meta_choice(tr, chaos, "Chaos/Distortion 1",
    {"Ruina","Trash","OTT","Cramit","Distox"})
  add_fx_meta_choice(tr, chaos, "Chaos/Distortion 2",
    {"FractureXT","Cryogen","Krush","GSatPlus"})

  local rev = select_by_role("Reverb")
  add_fx_meta_choice(tr, rev, "Dunkler Raum/Reverb",
    {"FogPad","ValhallaSupermassive","ReaVerbate (Cockos)"})
end

local function chain_idm_pad_tapegranular(tr)
  msg("=== IDM Pad: Tape + Granular Atmos (BoC/Arovane-ish) ===")
  load_metadata_core()

  add_fx_by_name(tr,"ReaEQ (Cockos)")

  local mod = select_by_role("Modulation")
  add_fx_meta_choice(tr,mod,"Chorus/Modulation",
    {"ValhallaSpaceModulator","Multiply","TAL-Chorus-LX"})

  local tape = select_by_tags_any({"BOC_TAPE","TAPE_LOFI"})
  add_fx_meta_choice(tr,tape,"Tape/LoFi",
    {"NEOLD WARBLE","Tape Cassette 2","CHOWTapeModel","OkaiR2R"})

  local gran = select_by_tags_any({"IDM_GRANULAR","TEXTURE"})
  add_fx_meta_choice(tr,gran,"Granular/Textur",
    {"Emergence","gRainbow","fogpad","PaulXStretch"})

  local rev = select_by_role("Reverb")
  add_fx_meta_choice(tr,rev,"Deep Reverb",
    {"FogPad","ValhallaSupermassive","Raum","ReaVerbate (Cockos)"})
end

local function chain_idm_send_glitch(tr)
  msg("=== IDM Send: Glitch Comb/Delay ===")
  load_metadata_core()

  add_fx_by_name(tr,"ReaEQ (Cockos)")

  local glitch = select_by_tags_any({"IDM_BUFFER","IDM_GLITCH"})
  add_fx_meta_choice(tr,glitch,"Glitch/Buffer",
    {"FractureXT","Fracture","Cryogen","Hysteresis","dblue Glitch"})

  local move = select_by_tags_any({"IDM_MOVEMENT"})
  add_fx_meta_choice(tr,move,"Movement (Pan/Filter)",
    {"Panflow","Filterstep_64","DS Tantra 2","kHs Trance Gate"})

  local delays = select_by_role("Delay")
  add_fx_meta_choice(tr,delays,"Delay",
    {"ReaDelay (Cockos)","Replika","Deelay"})

  local rev = select_by_role("Reverb")
  add_fx_meta_choice(tr,rev,"Reverb (optional)",
    {"FogPad","ValhallaSupermassive","Raum","ReaVerbate (Cockos)"})
end

local function main()
  local tr = ensure_track()
  if not tr then return end
  local menu =
    "DF95 IDM FXChain Generator PRO v2||" ..
    "1. IDM Drum – Elastic Resonator (Autechre-ish)|" ..
    "2. IDM Drum – BreakCrunch (Aphex/Squarepusher-ish)|" ..
    "3. IDM Pad – Tape + Granular Atmos (BoC/Arovane-ish)|" ..
    "4. IDM Send – Glitch Comb/Delay|"
  local mx,my = r.GetMousePosition()
  gfx.init("DF95 IDM FXChain Generator PRO v2",0,0,0,mx,my)
  local idx = gfx.showmenu(menu)
  gfx.quit()
  if idx==2 then
    chain_idm_drum_elastic(tr)
  elseif idx==3 then
    chain_idm_drum_breakcrunch(tr)
  elseif idx==4 then
    chain_idm_pad_tapegranular(tr)
  elseif idx==5 then
    chain_idm_send_glitch(tr)
  end
end

main()
