-- @description Sampler Kit Wizard (multi-slot builder with presets)
-- @version 1.1
-- @author DF95
-- @about
--   Wizard zum Bauen mehrerer RS5k-Kits (Slots) hintereinander.
--   Features:
--     - Vordefinierte Presets (3,4,5,6,7,8 Slots) für typische DF95-Setups
--     - Globale Auswahl "Layers per Sound" (1 = Single, 2 = Layered-Kit)
--     - Manueller Modus für freie Konfiguration:
--         Name, Mode(folder/items/roundrobin), Build(plain/roundrobin/layered), Annotate(y/n)[,Layers(1/2)]
--
--   Die eigentliche Kit-Erzeugung passiert über DF95_Sampler_Core.build_multi_slots,
--   welches intern die bestehenden Builder-Scripts aufruft. Ordner/Items werden
--   dabei wie gewohnt über die jeweiligen Scripts abgefragt.

local r = reaper
local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local DF95_AutoTag = nil
do
  local dir = df95_root()
  if dir ~= "" then
    local ok, mod = pcall(dofile, dir .. "DF95_AutoTag_Core.lua")
    if ok and mod then
      DF95_AutoTag = mod
    end
  end
end


local function msg(s)
  r.ShowMessageBox(tostring(s), "DF95 Sampler Kit Wizard", 0)
end

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_sampler_core()
  local path = df95_root() .. "DF95_Sampler_Core.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    msg("Fehler beim Laden von DF95_Sampler_Core.lua:\n"..tostring(mod))
    return nil
  end
  return mod
end

----------------------------------------------------------------------
-- Preset-Definitionen
----------------------------------------------------------------------

local function build_preset_slots(preset_n, layers_per_sound)
local function DF95_MapTrackNameToRole(track_name)
  track_name = tostring(track_name or ""):lower()
  if track_name:find("kick") then
    return "Kick"
  elseif track_name:find("snare") then
    return "Snare"
  elseif track_name:find("hat") then
    return "Hats"
  elseif track_name:find("click") or track_name:find("pop") then
    return "ClicksPops"
  elseif track_name:find("microperc") or track_name:find("micro") then
    return "MicroPerc"
  elseif track_name:find("randomidmp") or track_name:find("idmp") then
    return "RandomIDMPerc"
  elseif track_name:find("fxstab") or track_name:find("stab") then
    return "FXStabs"
  elseif track_name:find("vocal") then
    return "VocalFX"
  elseif track_name:find("fulldrums") or track_name:find("fulldrum") then
    return "FullDrums"
  else
    return "Any"
  end
end

local function DF95_AnnotateSlotsWithRoles(slots)
  if not slots then return end
  for _, slot in ipairs(slots) do
    if slot.annotate_roles and slot.track_name then
      slot.role = DF95_MapTrackNameToRole(slot.track_name)
    end
  end
end

  layers_per_sound = tonumber(layers_per_sound or 1) or 1
  if layers_per_sound < 1 then layers_per_sound = 1 end
  if layers_per_sound > 2 then layers_per_sound = 2 end

  local slots = {}

  -- Minimal 3-Kit Setup
  if preset_n == 3 then
    slots = {
      { track_name="MicroPerc",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="Clicks&Pops", mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="FullDrums",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
    }
  elseif preset_n == 4 then
    slots = {
      { track_name="MicroPerc",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="Clicks&Pops", mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="FullDrums",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="RandomIDMPerc",mode="folder",build="roundrobin", annotate_roles=true, layers=layers_per_sound },
    }
  elseif preset_n == 5 then
    slots = {
      { track_name="MicroPerc",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="Clicks&Pops",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="KickClicks",    mode="folder", build="layered",    annotate_roles=true, layers=layers_per_sound },
      { track_name="FullDrums",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="RandomIDMPerc", mode="folder", build="roundrobin", annotate_roles=true, layers=layers_per_sound },
    }
  elseif preset_n == 6 then
    slots = {
      { track_name="MicroPerc",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="Clicks&Pops",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="KickClicks",    mode="folder", build="layered",    annotate_roles=true, layers=layers_per_sound },
      { track_name="HatsSpecial",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="FullDrums",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="RandomIDMPerc", mode="folder", build="roundrobin", annotate_roles=true, layers=layers_per_sound },
    }
  elseif preset_n == 7 then
    slots = {
      { track_name="MicroPerc",       mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="Clicks&Pops",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="KickClicks",      mode="folder", build="layered",    annotate_roles=true, layers=layers_per_sound },
      { track_name="HatsSpecial",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="FullDrums",       mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="RandomIDMPerc",   mode="folder", build="roundrobin", annotate_roles=true, layers=layers_per_sound },
      { track_name="FXStabs",         mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
    }
  elseif preset_n == 8 then
    slots = {
      { track_name="MicroPerc",       mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="Clicks&Pops",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="KickClicks",      mode="folder", build="layered",    annotate_roles=true, layers=layers_per_sound },
      { track_name="HatsSpecial",     mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="FullDrums",       mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="RandomIDMPerc",   mode="folder", build="roundrobin", annotate_roles=true, layers=layers_per_sound },
      { track_name="FXStabs",         mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
      { track_name="VocalGlitchFX",   mode="folder", build="plain",      annotate_roles=true, layers=layers_per_sound },
    }
  end

  return slots
end

----------------------------------------------------------------------
-- Abfragen
----------------------------------------------------------------------

local function ask_preset_and_layers()
  local last = r.GetExtState("DF95_SAMPLER_WIZ", "preset_layers")
  if last == "" then
    -- Default: kein Preset, 3 Slots, 1 Layer pro Sound, FolderMode=0 (per Slot)
    -- Format: Preset,Slots,LayersPerSound,FolderMode(0=per-slot,1=global)
    last = "0,3,1,0"
  end
  local caption = "Preset(0=none,3,4,5,6,7,8),Slots(1..8),Layers(1/2),FolderMode(0=per-slot,1=global)"
  local ok, ret = r.GetUserInputs("DF95 Sampler Kit Wizard", 1, caption..":", last)
  if not ok or not ret or ret == "" then return nil end
  r.SetExtState("DF95_SAMPLER_WIZ", "preset_layers", ret, true)

  local p,s,l,fm = ret:match("^(.-),(.-),(.-),(.-)$")
  if not p or not s or not l or not fm then
    msg("Eingabeformat nicht erkannt.\nErwartet: Preset,Slots,Layers,FolderMode (z.B. 3,3,1,0)")
    return nil
  end
  local preset_n   = tonumber(p or "0") or 0
  local slots_n    = tonumber(s or "0") or 0
  local layers     = tonumber(l or "1") or 1
  local foldermode = tonumber(fm or "0") or 0

  preset_n   = math.floor(preset_n)
  slots_n    = math.floor(slots_n)
  layers     = math.floor(layers)
  foldermode = math.floor(foldermode)

  if slots_n < 1 then slots_n = 1 end
  if slots_n > 8 then slots_n = 8 end
  if layers < 1 then layers = 1 end
  if layers > 2 then layers = 2 end
  if foldermode < 0 then foldermode = 0 end
  if foldermode > 1 then foldermode = 1 end

  -- Falls globaler Ordner-Modus: Root-Pfad abfragen und speichern
  if foldermode == 1 then
    local last_root = r.GetExtState("DF95_SAMPLER_WIZ", "global_root")
    if last_root == "" then last_root = "" end
    local ok2, root = r.GetUserInputs("DF95 Sampler Global Root", 1, "Globaler Root-Ordner (inkl. Unterordner):", last_root)
    if not ok2 or not root or root == "" then
      msg("Globaler Root-Ordner wurde nicht angegeben. Abbruch.")
      return nil
    end
    -- sanitize path minimal
    root = root:gsub('[\\"<>|]', ""):gsub("[/\\]+$", "")
    r.SetExtState("DF95_SAMPLER_WIZ", "global_root", root, true)
    r.SetExtState("DF95_SAMPLER_WIZ", "global_mode", "1", true)
  else
    -- Per-Slot-Ordner: Global-Modus zurücksetzen
    r.SetExtState("DF95_SAMPLER_WIZ", "global_mode", "0", true)
  end

  return preset_n, slots_n, layers, foldermode
end
end

local function ask_slot_params(i, default_layers)
  local key = "slot"..tostring(i)
  local last = r.GetExtState("DF95_SAMPLER_WIZ", key)
  if last == "" then
    -- Default: Name_i,folder,plain,y,Layers
    last = string.format("Kit%d,folder,plain,y,%d", i, default_layers or 1)
  end
  local caption = string.format("Slot %d – Name,Mode(folder/items/roundrobin),Build(plain/roundrobin/layered),Annotate(y/n),Layers(1/2)", i)
  local ok, ret = r.GetUserInputs("DF95 Sampler Kit Wizard", 1, caption..":", last)
  if not ok or not ret or ret == "" then return nil end
  r.SetExtState("DF95_SAMPLER_WIZ", key, ret, true)

  -- Versuche 5 Felder (inkl. Layers), fallback auf 4 Felder
  local name, mode, build, ann, layers = ret:match("^(.-),(.-),(.-),(.-),(.-)$")
  if not name then
    name, mode, build, ann = ret:match("^(.-),(.-),(.-),(.-)$")
  end
  if not name or not mode or not build or not ann then
    msg("Eingabeformat für Slot "..tostring(i).." nicht erkannt.\nErwartet: Name,Mode,Build,Annotate[,Layers] (z.B. MicroPerc,folder,plain,y,1)")
    return nil
  end
  name  = name:gsub("^%s+",""):gsub("%s+$","")
  mode  = mode:lower():gsub("%s+","")
  build = build:lower():gsub("%s+","")
  ann   = ann:lower():gsub("%s+","")
  layers = layers and layers:gsub("%s+","") or tostring(default_layers or 1)

  if mode ~= "folder" and mode ~= "items" and mode ~= "roundrobin" then
    msg("Ungültiger Mode für Slot "..tostring(i)..": "..mode.."\nErlaubt: folder, items, roundrobin")
    return nil
  end
  if build ~= "plain" and build ~= "roundrobin" and build ~= "layered" then
    msg("Ungültiger Build-Typ für Slot "..tostring(i)..": "..build.."\nErlaubt: plain, roundrobin, layered")
    return nil
  end
  local annotate = (ann == "y" or ann == "yes" or ann == "1" or ann == "true")
  local layers_n = tonumber(layers or "1") or 1
  if layers_n < 1 then layers_n = 1 end
  if layers_n > 2 then layers_n = 2 end

  return {
    track_name     = name,
    mode           = mode ~= "layered" and mode or "folder",
    build          = build,
    annotate_roles = annotate,
    layers         = layers_n,
  }
end

----------------------------------------------------------------------
-- Main
----------------------------------------------------------------------

local function main()
  local sampler = load_sampler_core()
  if not sampler or not sampler.build_multi_slots then return end

  local preset_n, slots_n, layers_per_sound, foldermode = ask_preset_and_layers()
  if not preset_n then return end

  -- Wenn ein Preset gewählt ist (3/4/5/6/7/8), bauen wir direkt
  if preset_n == 3 or preset_n == 4 or preset_n == 5
     or preset_n == 6 or preset_n == 7 or preset_n == 8 then
    local slots = build_preset_slots(preset_n, layers_per_sound)
    if not slots or #slots == 0 then
      msg("Preset "..tostring(preset_n).." ist nicht definiert.")
      return
    end
    DF95_AnnotateSlotsWithRoles(slots)
    sampler.build_multi_slots(slots)
    return
  end

  -- Manueller Modus
  local slots = {}
  for i = 1, slots_n do
    local slot = ask_slot_params(i, layers_per_sound)
    if not slot then return end
    table.insert(slots, slot)
  end

  DF95_AnnotateSlotsWithRoles(slots)
  sampler.build_multi_slots(slots)
end

main()
