-- DF95_PluginMeta_QC_AutoOverride.lua
-- 
-- Auto-QC für DF95 PluginMeta:
-- * Lädt DF95_PluginMetaDomain.lua
-- * Führt eine Heuristik über alle Einträge aus
-- * Schreibt Vorschläge als Overrides in DF95_PluginMetaOverrides.lua
--
-- Achtung:
-- * Dieses Script überschreibt DF95_PluginMetaOverrides.lua komplett.
-- * Manuelle Overrides solltest du vorher sichern oder später wieder einpflegen.

local r = reaper

local function msg(s) r.ShowConsoleMsg(tostring(s) .. "\n") end

local function load_meta()
  local res = r.GetResourcePath()
  local path = res .. "/Scripts/IFLS/DF95/DF95_PluginMetaDomain.lua"
  local ok, mod = pcall(dofile, path)
  if not ok or type(mod) ~= "table" then
    r.ShowMessageBox("Konnte DF95_PluginMetaDomain.lua nicht laden:\n" .. tostring(mod), "DF95 AutoOverride QC", 0)
    return nil
  end
  if mod.get_all then
    return mod.get_all()
  elseif mod.PLUGIN_META then
    return mod.PLUGIN_META
  end
  return nil
end

local function suggest_cat(name)
  local ln = name:lower()
  if ln:find("vst3i:") or ln:find("vsti:") then return "instrument" end
  if (ln:find("reverb") or ln:find("plate") or ln:find("hall") or ln:find("cathedral") or ln:find("room") or ln:find("chamber"))
     and not ln:find("scope") then
    return "reverb"
  end
  if (ln:find("delay") or ln:find("echo") or ln:find("echoes"))
     and not ln:find("chorus") then
    return "delay"
  end
  if ln:find("chorus") or ln:find("phaser") or ln:find("flanger") or ln:find("tremolo") or ln:find("vibrato") or ln:find("rotator") or ln:find("leslie") then
    return "modulation"
  end
  if ln:find(" eq") or ln:find("eq ") or ln:find("filter") or ln:find("equalizer")
     or ln:find("baxter") or ln:find("pultec") or ln:find("highpass")
     or ln:find("lowpass") or ln:find("bandpass") or ln:find("tilt") then
    return "filter_eq"
  end
  if ln:find("comp") or ln:find("compressor") or ln:find("limiter")
     or ln:find("gate") or ln:find("expander") or ln:find("de-esser") or ln:find("deesser") then
    return "dynamics"
  end
  if ln:find("distort") or ln:find("distortion") or ln:find("drive") or ln:find("saturat")
     or ln:find("fuzz") or ln:find("crush") or ln:find("bitcrush") or ln:find("lofi")
     or ln:find("tape") or ln:find("overdrive") or ln:find("preamp") or ln:find("tube") then
    return "saturation"
  end
  if ln:find("glitch") or ln:find("granular") or ln:find("shuffler") or ln:find("spectral")
     or ln:find("freeze") or ln:find("stutter") or ln:find("tantra")
     or ln:find("hysteresis") or ln:find("shaperbox") or ln:find("convex")
     or ln:find("cryogen") or ln:find("fracture") or ln:find("subvert")
     or ln:find("dispersion") or ln:find("dissolve") then
    return "texture_experimental"
  end
  if ln:find("midi ") and not ln:find("vsti") then
    return "midi"
  end
  return nil
end

local function expected_group(cat)
  if cat == "reverb"                then return "IDM_SPACE"   end
  if cat == "dynamics"              then return "IDM_BUSS"    end
  if cat == "saturation"            then return "IDM_GLITCH"  end
  if cat == "delay"                 then return "IDM_ECHO"    end
  if cat == "modulation"            then return "IDM_STEREO"  end
  if cat == "filter_eq"             then return "IDM_TONE"    end
  if cat == "console_tape"          then return "IDM_BUSS"    end
  if cat == "meter_utility"         then return "IDM_UTILITY" end
  if cat == "instrument"            then return "IDM_INSTR"   end
  if cat == "texture_experimental"  then return "IDM_TEXTURE" end
  if cat == "midi"                  then return "IDM_MIDI"    end
  return nil
end

local meta = load_meta()
if not meta then return end

r.ClearConsole()
msg("DF95 AutoOverride QC – starte Heuristik...")

local overrides = {}
local changed = 0

for name, m in pairs(meta) do
  local cat = m.category or "other"
  local grp = m.idm_group or "IDM_MISC"

  local sugg_cat = suggest_cat(name)
  local new_cat  = cat
  local new_grp  = grp

  -- Kategorie nur überschreiben, wenn bisher 'other' und wir eine klare Suggestion haben
  if cat == "other" and sugg_cat then
    new_cat = sugg_cat
  end

  -- IDM-Gruppe ggf. nachziehen, wenn noch IDM_MISC
  local exp_grp_for_cat = expected_group(new_cat)
  if grp == "IDM_MISC" and exp_grp_for_cat then
    new_grp = exp_grp_for_cat
  end

  if new_cat ~= cat or new_grp ~= grp then
    overrides[name] = {
      category  = new_cat,
      idm_group = new_grp,
    }
    changed = changed + 1
    msg(string.format("Override: %s | cat %s -> %s | idm %s -> %s",
      name, cat, new_cat, grp, new_grp))
  end
end

msg("")
msg(string.format("Heuristik fertig, %d Plugins mit Overrides.", changed))

local res = r.GetResourcePath()
local outpath = res .. "/Scripts/IFLS/DF95/DF95_PluginMetaOverrides.lua"

local f, err = io.open(outpath, "w")
if not f then
  r.ShowMessageBox("Konnte Overrides-Datei nicht schreiben:\n" .. tostring(err), "DF95 AutoOverride QC", 0)
  return
end

f:write("local M = {}\n")
f:write("M.OVERRIDES = {\n")
for name, ov in pairs(overrides) do
  local name_esc = name:gsub("\\", "\\\\"):gsub('"','\\"')
  local cat_esc  = (ov.category or ""):gsub("\\","\\\\"):gsub('"','\\"')
  local grp_esc  = (ov.idm_group or ""):gsub("\\","\\\\"):gsub('"','\\"')
  f:write(string.format('  [\"%s\"] = { category = \"%s\", idm_group = \"%s\" },\n',
    name_esc, cat_esc, grp_esc))
end
f:write("}\n")
f:write("return M\n")
f:close()

msg("Overrides wurden geschrieben nach:")
msg(outpath)
msg("")
msg("Hinweis: DF95_PluginMetaDomain.apply_overrides() wird diese automatisch anwenden,\n" ..
    "sobald du IFLS / Threepo / IFLS_PluginMetaBridgeDomain nutzt.")
