-- @description RoleFX Static Chains v2 (Variants + Preset-Aware, MetaCore FX)
-- @author You
-- @version 2.0
-- @about
--   Erweiterte Version der RoleFX-Engine:
--     • Pro Rolle (Drum/Synth) drei FX-Varianten: Soft / Medium / Extreme
--     • Nutzt DF95_ROLE-Tags (domain/role/preset/variant)
--     • Kann anhand des Preset-Namens + Zahlen-Variante automatisch Soft/Med/Extreme wählen
--     • Getrennte Ketten für FXBus, Color und Master
--     • Option: existierende FX ersetzen oder anhängen
--
--   Integration:
--     • Funktioniert direkt mit:
--         - DF95_SuperRandom_RoleChain
--         - DF95_DrumRole_Layer_Builder / Randomizer
--         - DF95_SynthGlobal_PresetBrowser
--         - DF95_Tag_SelectedTracks_Role
--
--   Hinweis:
--     FX werden über Namens-Substrings gesucht (z.B. "Filterstep", "Nova", "SPAN").
--     Wenn ein Plugin nicht installiert oder anders benannt ist, wird es einfach ignoriert.

local r = reaper

------------------------------------------------------------
-- DF95_ROLE Tag lesen
------------------------------------------------------------

local function get_role_tag_for_track(tr)
  if not tr then return nil end
  local guid = r.GetTrackGUID(tr)
  local ok, val = r.GetProjExtState(0, "DF95_ROLE", guid)
  if ok ~= 1 or not val or val == "" then
    return nil
  end

  local domain = val:match("domain=([^;]+)")
  local role   = val:match("role=([^;]+)")
  local preset = val:match("preset=([^;]+)")
  local var    = val:match("variant=([^;]+)")
  return {
    domain = domain or "",
    role   = role or "",
    preset = preset or "",
    variant= var or "",
    raw    = val,
  }
end

------------------------------------------------------------
-- FX-Ketten pro Rolle / Domain / Variante
--   Soft: subtil / utility
--   Medium: charaktervoll / IDM-freundlich
--   Extreme: glitch / heavy processing
------------------------------------------------------------

local RoleFXVariants = {
  drum = {
    kick = {
      soft = {
        fxbus  = { "Filterstep" },
        color  = { "Nova", "IVGI" },
        master = { "Kotelnikov", "SPAN" },
      },
      medium = {
        fxbus  = { "Filterstep", "Gatelab" },
        color  = { "Nova", "IVGI", "KClip" },
        master = { "Kotelnikov", "Limiter No6", "SPAN" },
      },
      extreme = {
        fxbus  = { "Filterstep", "Gatelab", "Fracture" },
        color  = { "Decimort", "Bitcrush", "KClip" },
        master = { "Limiter No6", "SPAN", "Youlean Loudness" },
      },
    },
    snare = {
      soft = {
        fxbus  = { "Fracture" },
        color  = { "Nova" },
        master = { "Kotelnikov", "SPAN" },
      },
      medium = {
        fxbus  = { "Fracture", "Gatelab" },
        color  = { "Nova", "Decimort" },
        master = { "Kotelnikov", "Limiter No6", "SPAN" },
      },
      extreme = {
        fxbus  = { "Fracture XT", "Cryogen", "Gatelab" },
        color  = { "Decimort", "Bitcrush", "Transient" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    clap = {
      soft = {
        fxbus  = { "Fracture" },
        color  = { "Nova" },
        master = { "Kotelnikov" },
      },
      medium = {
        fxbus  = { "Fracture", "Gatelab" },
        color  = { "Nova", "Bitcrush" },
        master = { "Kotelnikov", "Limiter", "SPAN" },
      },
      extreme = {
        fxbus  = { "Fracture XT", "Cryogen" },
        color  = { "Bitcrush", "RC-20" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    hat = {
      soft = {
        fxbus  = { "Filterstep" },
        color  = { "DeEsser", "Nova" },
        master = { "SPAN" },
      },
      medium = {
        fxbus  = { "Filterstep", "Gatelab" },
        color  = { "DeEsser", "Nova", "Bitcrush" },
        master = { "Limiter No6", "SPAN" },
      },
      extreme = {
        fxbus  = { "Filterstep", "Gatelab", "Hysteresis" },
        color  = { "Bitcrush", "Saturation" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    perc = {
      soft = {
        fxbus  = { "Filterstep" },
        color  = { "Nova" },
        master = { "Kotelnikov", "SPAN" },
      },
      medium = {
        fxbus  = { "Filterstep", "Tactic", "Fracture" },
        color  = { "Nova", "Decimort", "Saturation" },
        master = { "Kotelnikov", "Limiter No6", "SPAN" },
      },
      extreme = {
        fxbus  = { "Filterstep", "Tactic", "Fracture XT" },
        color  = { "Decimort", "Bitcrush", "RC-20" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    toms = {
      soft = {
        fxbus  = { "Filterstep" },
        color  = { "Nova" },
        master = { "Kotelnikov", "SPAN" },
      },
      medium = {
        fxbus  = { "Filterstep", "Gate", "Fracture" },
        color  = { "Nova", "IVGI" },
        master = { "Kotelnikov", "Limiter", "SPAN" },
      },
      extreme = {
        fxbus  = { "Filterstep", "Fracture XT" },
        color  = { "IVGI", "Bitcrush" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    clicks = {
      soft = {
        fxbus  = { "Fracture" },
        color  = { "Nova" },
        master = { "SPAN" },
      },
      medium = {
        fxbus  = { "Fracture", "Hysteresis" },
        color  = { "Bitcrush", "Saturation" },
        master = { "Limiter No6", "SPAN" },
      },
      extreme = {
        fxbus  = { "Fracture XT", "Hysteresis", "Tactic" },
        color  = { "Bitcrush", "RC-20" },
        master = { "Limiter No6", "SPAN" },
      },
    },
  },

  synth = {
    bass = {
      soft = {
        fxbus  = { "Filterstep" },
        color  = { "Nova", "IVGI" },
        master = { "Kotelnikov", "SPAN" },
      },
      medium = {
        fxbus  = { "Filterstep", "Gatelab" },
        color  = { "Nova", "kHs Distortion", "IVGI" },
        master = { "Kotelnikov", "SPAN", "Youlean Loudness" },
      },
      extreme = {
        fxbus  = { "Filterstep", "Gatelab", "Fracture" },
        color  = { "kHs Distortion", "KClip" },
        master = { "Limiter No6", "SPAN", "Youlean Loudness" },
      },
    },
    lead = {
      soft = {
        fxbus  = { "Fracture" },
        color  = { "Chorus", "Reverb" },
        master = { "Nova", "Kotelnikov" },
      },
      medium = {
        fxbus  = { "Fracture", "Cryogen", "Filterstep" },
        color  = { "Chorus", "Delay", "Reverb" },
        master = { "Nova", "Kotelnikov", "Limiter No6" },
      },
      extreme = {
        fxbus  = { "Fracture XT", "Cryogen", "Filterstep" },
        color  = { "Chorus", "Delay", "Supermassive" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    pad = {
      soft = {
        fxbus  = { "Emergence" },
        color  = { "Chorus", "Reverb" },
        master = { "Nova", "Kotelnikov" },
      },
      medium = {
        fxbus  = { "Emergence", "Fracture", "Shimmer" },
        color  = { "Chorus", "Supermassive", "Reverb" },
        master = { "Nova", "Kotelnikov", "SPAN" },
      },
      extreme = {
        fxbus  = { "Emergence", "Fracture XT", "Shimmer" },
        color  = { "Supermassive", "Crystalline" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    keys = {
      soft = {
        fxbus  = { "Filterstep" },
        color  = { "Chorus", "Reverb" },
        master = { "Nova" },
      },
      medium = {
        fxbus  = { "Filterstep", "Gatelab" },
        color  = { "Chorus", "Delay", "Reverb" },
        master = { "Nova", "Kotelnikov", "Limiter No6" },
      },
      extreme = {
        fxbus  = { "Filterstep", "Fracture" },
        color  = { "Chorus", "Delay", "Supermassive" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    pluck = {
      soft = {
        fxbus  = { "Fracture" },
        color  = { "Delay", "Reverb" },
        master = { "Nova" },
      },
      medium = {
        fxbus  = { "Fracture", "Filterstep", "Gatelab" },
        color  = { "Delay", "Reverb" },
        master = { "Nova", "Limiter No6" },
      },
      extreme = {
        fxbus  = { "Fracture XT", "Filterstep", "Gatelab" },
        color  = { "Delay", "Supermassive" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    fx = {
      soft = {
        fxbus  = { "Fracture", "Filterstep" },
        color  = { "Bitcrush" },
        master = { "Nova", "SPAN" },
      },
      medium = {
        fxbus  = { "Fracture", "Cryogen", "Emergence", "Filterstep" },
        color  = { "Bitcrush", "RC-20", "Saturation" },
        master = { "Nova", "Limiter No6", "SPAN" },
      },
      extreme = {
        fxbus  = { "Fracture XT", "Cryogen", "Emergence", "Filterstep" },
        color  = { "Bitcrush", "RC-20", "Saturation" },
        master = { "Limiter No6", "SPAN" },
      },
    },
    drone = {
      soft = {
        fxbus  = { "Emergence" },
        color  = { "Chorus", "Reverb" },
        master = { "Nova", "SPAN" },
      },
      medium = {
        fxbus  = { "Emergence", "Grain", "Shimmer", "Crystalline" },
        color  = { "Chorus", "Reverb", "Supermassive" },
        master = { "Nova", "Kotelnikov", "SPAN" },
      },
      extreme = {
        fxbus  = { "Emergence", "Grain", "Shimmer", "Crystalline" },
        color  = { "Supermassive", "Resonator" },
        master = { "Limiter No6", "SPAN" },
      },
    },
  }
}

------------------------------------------------------------
-- Preset-Name -> Variant Mapping (für bekannte Presets aus deinen Browsern)
------------------------------------------------------------

local PresetVariantHints = {
  -- Drum-Layer-Beispiele
  ["Kick – ChowKick + Vital Low"]        = "medium",
  ["Kick – Drumatic3 + ThumpBass"]       = "medium",
  ["Snare – Drumatic3 + Grainbow"]       = "extreme",
  ["Snare – Drum_Boxx + Vital"]          = "medium",
  ["Clap – ADC_Clap + Vital"]            = "medium",
  ["Clap – Drum_Boxx + Grainbow"]        = "extreme",
  ["Hat – Drum_Boxx + Grainbow"]         = "medium",
  ["Hat – BucketPops + Vital"]           = "medium",
  ["Clicks – BucketPops + Grainbow"]     = "extreme",

  -- Synth-Layer-Beispiele
  ["Bass – Vital + Tyrell"]              = "medium",
  ["Bass – ThumpOne + ThumpBass"]        = "medium",
  ["Lead – Vital + ZebraHZ"]             = "medium",
  ["Lead – Pendulate + Tyrell"]          = "extreme",
  ["Pad – Grainbow + MNDALA2"]           = "extreme",
  ["Pad – ZebraHZ + Tyrell"]             = "medium",
  ["FX – Vital + Grainbow"]              = "extreme",
  ["Drone – ZebraHZ + Tyrell"]           = "medium",
  ["Drone – VoltageModular + Tyrell"]    = "extreme",
}

------------------------------------------------------------
-- Variant-Auswahl: Auto anhand Preset/Var + User-Override
------------------------------------------------------------

local function infer_variant_from_preset_and_number(preset_name, var_num)
  local name = (preset_name or ""):lower()

  -- 1) explizite Text-Hints
  if name:find("extreme") or name:find("xtreme") or name:find("hard") or name:find("aggress") then
    return "extreme"
  end
  if name:find("soft") or name:find("gentle") then
    return "soft"
  end
  if name:find("medium") or name:find("med ") then
    return "medium"
  end

  -- 2) Mapping-Tabelle
  if PresetVariantHints[preset_name or ""] then
    return PresetVariantHints[preset_name]
  end

  -- 3) numerische Variante: 1 = soft, 2-3 = medium, >=4 = extreme
  local n = tonumber(var_num or 0) or 0
  if n == 1 then return "soft" end
  if n == 2 or n == 3 then return "medium" end
  if n >= 4 then return "extreme" end

  -- Fallback
  return "medium"
end

local function ask_mode_and_section_and_variant()
  local ok, ret = r.GetUserInputs(
    "DF95 RoleFX Static Chains v2",
    3,
    "Mode (1=Replace,2=Append):,Sektion (1=FXBus,2=Color,3=Master,4=Alle):,Variante (0=Auto,1=Soft,2=Med,3=Extreme):",
    "1,4,0"
  )
  if not ok then return end
  local m_str, s_str, v_str = ret:match("([^,]+),([^,]+),([^,]+)")
  local m = tonumber(m_str) or 1
  if m < 1 or m > 2 then m = 1 end
  local s = tonumber(s_str) or 4
  if s < 1 or s > 4 then s = 4 end
  local v = tonumber(v_str) or 0
  if v < 0 or v > 3 then v = 0 end
  return m, s, v
end

local function add_chain_to_track(tr, chain_list)
  if not tr or not chain_list then return end
  for _, name in ipairs(chain_list) do
    if name ~= "" then
      r.TrackFX_AddByName(tr, name, false, -1)
    end
  end
end

local function clear_all_fx(tr)
  if not tr then return end
  local cnt = r.TrackFX_GetCount(tr)
  for i = cnt-1, 0, -1 do
    r.TrackFX_Delete(tr, i)
  end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

local function main()
  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("Bitte einen oder mehrere Bus-Tracks mit DF95_ROLE-Tag selektieren.", "DF95 RoleFX Static Chains v2", 0)
    return
  end

  local mode, section, variant_mode = ask_mode_and_section_and_variant()
  if not mode or not section then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local processed = 0

  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    local tag = get_role_tag_for_track(tr)
    if tag and tag.domain ~= "" and tag.role ~= "" then
      local domain_tbl = RoleFXVariants[tag.domain]
      local role_tbl   = domain_tbl and domain_tbl[tag.role]
      if role_tbl then
        -- Variante bestimmen
        local chosen_variant
        if variant_mode == 1 then
          chosen_variant = "soft"
        elseif variant_mode == 2 then
          chosen_variant = "medium"
        elseif variant_mode == 3 then
          chosen_variant = "extreme"
        else
          chosen_variant = infer_variant_from_preset_and_number(tag.preset, tag.variant)
        end

        local variant_tbl = role_tbl[chosen_variant] or role_tbl["medium"]
        if variant_tbl then
          if mode == 1 then
            clear_all_fx(tr)
          end

          if section == 1 or section == 4 then
            add_chain_to_track(tr, variant_tbl.fxbus)
          end
          if section == 2 or section == 4 then
            add_chain_to_track(tr, variant_tbl.color)
          end
          if section == 3 or section == 4 then
            add_chain_to_track(tr, variant_tbl.master)
          end

          processed = processed + 1
        end
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 RoleFX Static Chains v2 ("..processed.." Tracks)", -1)

  if processed == 0 then
    r.ShowMessageBox("Keine passenden DF95_ROLE-Tags / Rollen gefunden.", "DF95 RoleFX Static Chains v2", 0)
  end
end

main()
