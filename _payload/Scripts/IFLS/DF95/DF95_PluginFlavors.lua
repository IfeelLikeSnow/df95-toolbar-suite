-- DF95_PluginFlavors.lua
--
-- Lightweight "flavor" / tag system on top of DF95_PluginMetaDomain.
-- Ziel: Für jede FX-Instanz einfache semantische Labels wie
--   "glitch", "granular", "filter", "stutter", "vocoder", "spectral",
--   "bitcrush", "tape", "stereo", "space", ...
-- bereitzustellen, ohne das Category-/IDM-Gruppen-Schema aufzublasen.

local r = reaper
local M = {}

----------------------------------------------------------------
-- Manuelle Flavor-Overrides für wichtige IDM/Glitch Tools
----------------------------------------------------------------

M.FLAVORS = {
  -- Baby Audio / IDM Allstars
  ["VST3: Magic Dice (BABY Audio)"]             = {
    primary = "granular",
    tags    = { "granular", "texture", "space", "random" },
  },
  ["VST: Magic Dice (x86) (BABY Audio) (64ch)"] = {
    primary = "granular",
    tags    = { "granular", "texture", "space", "random" },
  },
  ["VST3: Magic Switch (BABY Audio)"]           = {
    primary = "chorus",
    tags    = { "stereo", "chorus", "juno", "idn_melody" },
  },
  ["VST: Magic Switch (x86) (BABY Audio) (64ch)"] = {
    primary = "chorus",
    tags    = { "stereo", "chorus", "juno", "idn_melody" },
  },

  -- A1StereoControl
  ["VST3: A1StereoControl (A1AUDIO.de)"] = {
    primary = "stereo",
    tags    = { "stereo", "widener", "utility" },
  },

  -- Danaides (Inear Display): Sequenced Glitch-Mangler
  ["VST: Danaides (x86) (Inear_Display)"] = {
    primary = "glitch",
    tags    = { "glitch", "sequence", "filter", "stutter" },
  },

  -- Glitchmachines (Beispiele)
  ["VST: Fracture (Glitchmachines)"] = {
    primary = "glitch",
    tags    = { "glitch", "granular", "stutter" },
  },
  ["VST: Fracture XT (Glitchmachines)"] = {
    primary = "glitch",
    tags    = { "glitch", "granular", "stutter", "texture" },
  },
  ["VST: Subvert (Glitchmachines)"] = {
    primary = "distortion",
    tags    = { "glitch", "distortion", "bitcrush" },
  },
  ["VST: Hysteresis (Glitchmachines)"] = {
    primary = "delay",
    tags    = { "glitch", "delay", "stutter" },
  },

  -- JS / Spektral-FX (Name ggf. anpassen)
  ["JS: Spectral Hold"] = {
    primary = "spectral",
    tags    = { "spectral", "freeze", "texture" },
  },
}

----------------------------------------------------------------
-- interne Helper
----------------------------------------------------------------

local function dedupe_append(dst, src)
  if not src then return dst end
  local seen = {}
  for _, t in ipairs(dst) do seen[t] = true end
  for _, t in ipairs(src) do
    if t and t ~= "" and not seen[t] then
      dst[#dst+1] = t
      seen[t] = true
    end
  end
  return dst
end

----------------------------------------------------------------
-- Heuristik basierend auf Name, Category, IDM-Gruppe
----------------------------------------------------------------

local function infer_from_name_and_meta(name, meta)
  local tags = {}
  local ln   = (name or ""):lower()
  local cat  = meta and (meta.category or "") or ""
  local grp  = meta and (meta.idm_group or "") or ""

  -- Basierend auf IDM-Gruppe
  if grp == "IDM_GLITCH"   then tags[#tags+1] = "glitch"      end
  if grp == "IDM_TEXTURE"  then tags[#tags+1] = "texture"     end
  if grp == "IDM_SPACE"    then tags[#tags+1] = "space"       end
  if grp == "IDM_ECHO"     then tags[#tags+1] = "delay"       end
  if grp == "IDM_STEREO"   then tags[#tags+1] = "stereo"      end
  if grp == "IDM_TONE"     then tags[#tags+1] = "filter"      end
  if grp == "IDM_BUSS"     then tags[#tags+1] = "buss"        end
  if grp == "IDM_INSTR"    then tags[#tags+1] = "instrument"  end
  if grp == "IDM_MIDI"     then tags[#tags+1] = "midi"        end
  if grp == "IDM_UTILITY"  then tags[#tags+1] = "utility"     end

  -- Basierend auf Category
  if cat == "filter_eq"            then tags[#tags+1] = "filter"      end
  if cat == "reverb"               then tags[#tags+1] = "reverb"      end
  if cat == "delay"                then tags[#tags+1] = "delay"       end
  if cat == "modulation"           then tags[#tags+1] = "modulation"  end
  if cat == "saturation"
     or cat == "console_tape"      then tags[#tags+1] = "saturation"  end
  if cat == "dynamics"             then tags[#tags+1] = "dynamics"    end
  if cat == "texture_experimental" then tags[#tags+1] = "texture"     end

  -- Keywort-Heuristiken
  if ln:find("granular") or ln:find("grain") or ln:find("particle") or ln:find("cloud") then
    tags[#tags+1] = "granular"
  end

  if ln:find("stutter") or ln:find("repeat") or ln:find("chopper") then
    tags[#tags+1] = "stutter"
  end

  if ln:find("vocoder") or ln:find("vocal synth") or ln:find("robot") then
    tags[#tags+1] = "vocoder"
  end

  if ln:find("spectral") or ln:find("fft") or ln:find("partial") then
    tags[#tags+1] = "spectral"
  end

  if ln:find("bitcrush") or ln:find("bit-crush") or ln:find("bit crush")
     or ln:find("bitglitter") or ln:find("bit decimator") then
    tags[#tags+1] = "bitcrush"
  end

  if ln:find("tape") or ln:find("cassette") or ln:find("vhs") then
    tags[#tags+1] = "tape"
  end

  if ln:find("lofi") or ln:find("lo-fi") then
    tags[#tags+1] = "lofi"
  end

  if ln:find("stereo") or ln:find("pan") or ln:find("width") or ln:find("widener") or ln:find("imager") then
    tags[#tags+1] = "stereo"
  end

  if ln:find("formant") then
    tags[#tags+1] = "formant"
  end

  if ln:find("pitch") or ln:find("transpose") or ln:find("harmonizer") then
    tags[#tags+1] = "pitch"
  end

  if ln:find("sidechain") or ln:find("duck") then
    tags[#tags+1] = "sidechain"
  end

  if ln:find("transient") then
    tags[#tags+1] = "transient"
  end

  if ln:find("freeze") or ln:find("hold") then
    tags[#tags+1] = "freeze"
  end

  if ln:find("drone") or ln:find("pad") then
    tags[#tags+1] = "drone"
  end

  if ln:find("click") then
    tags[#tags+1] = "click"
  end

  return tags
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function M.get_flavors(name, meta)
  local res = {}
  local ov = M.FLAVORS[name]
  if ov and ov.tags then
    res = dedupe_append(res, ov.tags)
  end
  res = dedupe_append(res, infer_from_name_and_meta(name, meta))
  return res
end

function M.has_flavor(name, meta, flavor)
  if not flavor or flavor == "" then return false end
  local tags = M.get_flavors(name, meta)
  for _, t in ipairs(tags) do
    if t == flavor then return true end
  end
  return false
end

function M.filter_meta_by_flavor(meta_table, flavor)
  local out = {}
  if not meta_table or not flavor or flavor == "" then return out end
  for name, m in pairs(meta_table) do
    if M.has_flavor(name, m, flavor) then
      out[#out+1] = m
    end
  end
  return out
end

return M
