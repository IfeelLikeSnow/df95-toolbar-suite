-- IFLS_SceneArrangerDomain.lua
-- Phase 26: Scene Arranger Domain
-- Verwalten eines Arrangements aus Szenen + SceneEvolution-Makros

local r = reaper
local M = {}

local NS = "IFLS_SCENEARRANGER"

----------------------------------------------------------------
-- ExtState helpers
----------------------------------------------------------------

local function get_ext(key, default)
  local ok, val = r.GetProjExtState(0, NS, key)
  if ok ~= 1 or val == "" then return default end
  return val
end

local function set_ext(key, val)
  r.SetProjExtState(0, NS, key or "", tostring(val or ""))
end

local function decode_json(s)
  if not s or s == "" then return nil end
  local ok, res = pcall(function() return load("return " .. s)() end)
  if ok then return res end
  return nil
end

local function encode_lua_table(t)
  -- einfache Lua-Table-Serialisierung via tostring und etwas Formatierung
  local ok, res = pcall(function() return string.format("%q", tostring("")) end)
  -- wir nutzen eine einfache Dump-Funktion
  local function dump(o, indent)
    indent = indent or ""
    if type(o) == "number" then
      return tostring(o)
    elseif type(o) == "boolean" then
      return o and "true" or "false"
    elseif type(o) == "string" then
      return string.format("%q", o)
    elseif type(o) == "table" then
      local parts = {"{"}
      local first = true
      for k, v in pairs(o) do
        local key
        if type(k) == "number" then
          key = string.format("[%d]", k)
        else
          key = k
        end
        local value = dump(v, indent .. "  ")
        table.insert(parts, string.format("%s  %s = %s,", indent, key, value))
        first = false
      end
      table.insert(parts, indent .. "}")
      return table.concat(parts, "\n")
    else
      return "nil"
    end
  end
  return dump(t, "")
end

----------------------------------------------------------------
-- SceneEvolution integration
----------------------------------------------------------------

local function load_sceneevo_domain()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_SceneEvolutionDomain.lua")
  if ok and type(mod) == "table" then return mod end
  return nil
end

local function apply_macros_to_sceneevo(macros)
  if not macros then return end
  local evo = load_sceneevo_domain()
  if not evo or not evo.read_cfg or not evo.write_cfg or not evo.apply_to_domains then return end
  local cfg = evo.read_cfg()
  cfg.macro_variation = macros.variation or cfg.macro_variation or 0.5
  cfg.macro_melody    = macros.melody    or cfg.macro_melody    or 0.5
  cfg.macro_groove    = macros.groove    or cfg.macro_groove    or 0.5
  cfg.macro_chaos     = macros.chaos     or cfg.macro_chaos     or 0.0
  evo.write_cfg(cfg)
  evo.apply_to_domains(cfg)
end

----------------------------------------------------------------
-- SceneDomain integration
----------------------------------------------------------------

local function load_scene_domain()
  local ok, mod = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/IFLS/Domain/IFLS_SceneDomain.lua")
  if ok and type(mod) == "table" then return mod end
  return nil
end

----------------------------------------------------------------
-- Arrangement lesen/schreiben
----------------------------------------------------------------

function M.default_arrangement()
  return {
    version = 1,
    scenes = {
      -- leer, wird im Hub erzeugt
    }
  }
end

function M.read_arrangement()
  local s = get_ext("ARRANGEMENT", "")
  local t = decode_json(s)
  if not t or type(t) ~= "table" then
    t = M.default_arrangement()
  end
  if not t.scenes then t.scenes = {} end
  return t
end

function M.write_arrangement(arr)
  if not arr then return end
  local s = encode_lua_table(arr)
  set_ext("ARRANGEMENT", s)
end

----------------------------------------------------------------
-- Highlevel Operations
----------------------------------------------------------------

--- apply_scene_index:
-- 1) Scene-Slot in IFLS_SceneDomain laden (falls vorhanden)
-- 2) SceneEvolution-Makros aus Arrangement-Step übernehmen
function M.apply_scene_index(idx)
  local arr = M.read_arrangement()
  local step = arr.scenes[idx]
  if not step then return end

  -- SceneSlot anwenden, falls gesetzt
  if step.scene_slot then
    local scene_dom = load_scene_domain()
    if scene_dom and scene_dom.load_scene then
      scene_dom.load_scene(step.scene_slot)
    end
  end

  -- Makros auf SceneEvolution anwenden
  if step.macros then
    apply_macros_to_sceneevo(step.macros)
  end
end

--- convenience: next/prev step index bei zyklischem Durchlauf
function M.get_next_index(current_idx)
  local arr = M.read_arrangement()
  local count = #arr.scenes
  if count == 0 then return nil end
  if not current_idx or current_idx < 1 then
    return 1
  end
  local nxt = current_idx + 1
  if nxt > count then nxt = 1 end
  return nxt
end

function M.get_prev_index(current_idx)
  local arr = M.read_arrangement()
  local count = #arr.scenes
  if count == 0 then return nil end
  if not current_idx or current_idx < 1 then
    return count
  end
  local prv = current_idx - 1
  if prv < 1 then prv = count end
  return prv
end

----------------------------------------------------------------
-- Arrangement Presets (IDM Arc, Glitch Peaks, Ambient Drift)
----------------------------------------------------------------

local function make_macros(variation, melody, groove, chaos)
  return {
    variation = variation,
    melody    = melody,
    groove    = groove,
    chaos     = chaos,
  }
end

function M.generate_preset(preset_name)
  local arr = { version = 1, scenes = {} }

  if preset_name == "IDM_ARC" then
    arr.scenes = {
      { name = "Intro",      scene_slot = 1, energy = 0.2, length_bars = 8,  macros = make_macros(0.2, 0.2, 0.3, 0.0) },
      { name = "Build",      scene_slot = 2, energy = 0.5, length_bars = 16, macros = make_macros(0.5, 0.4, 0.4, 0.2) },
      { name = "Peak IDM",   scene_slot = 3, energy = 0.9, length_bars = 16, macros = make_macros(0.9, 0.8, 0.6, 0.8) },
      { name = "Breakdown",  scene_slot = 4, energy = 0.4, length_bars = 8,  macros = make_macros(0.3, 0.5, 0.3, 0.2) },
      { name = "Outro",      scene_slot = 5, energy = 0.2, length_bars = 8,  macros = make_macros(0.1, 0.2, 0.3, 0.0) },
    }
  elseif preset_name == "GLITCH_SPIKES" then
    arr.scenes = {
      { name = "Sparse Intro",   scene_slot = 1, energy = 0.2, length_bars = 8,  macros = make_macros(0.3, 0.3, 0.3, 0.1) },
      { name = "First Spike",    scene_slot = 2, energy = 0.8, length_bars = 8,  macros = make_macros(0.9, 0.7, 0.5, 0.9) },
      { name = "Valley",         scene_slot = 3, energy = 0.4, length_bars = 8,  macros = make_macros(0.4, 0.4, 0.3, 0.2) },
      { name = "Second Spike",   scene_slot = 4, energy = 0.95,length_bars = 8,  macros = make_macros(1.0, 0.9, 0.6, 1.0) },
      { name = "Deconstruction", scene_slot = 5, energy = 0.3, length_bars = 8,  macros = make_macros(0.5, 0.6, 0.2, 0.3) },
    }
  elseif preset_name == "AMBIENT_DRIFT" then
    arr.scenes = {
      { name = "Soft Intro",     scene_slot = 1, energy = 0.1, length_bars = 16, macros = make_macros(0.1, 0.2, 0.3, 0.0) },
      { name = "Slow Motion",    scene_slot = 2, energy = 0.3, length_bars = 16, macros = make_macros(0.2, 0.3, 0.4, 0.1) },
      { name = "Evolving Center",scene_slot = 3, energy = 0.4, length_bars = 16, macros = make_macros(0.3, 0.4, 0.5, 0.2) },
      { name = "Dissolve",       scene_slot = 4, energy = 0.2, length_bars = 16, macros = make_macros(0.1, 0.3, 0.3, 0.1) },
    }
  else
    -- fallback: leeres Arrangement
    arr = M.default_arrangement()
  end

  M.write_arrangement(arr)
  return arr
end

return M
