-- IFLS_ScenePresets.lua
-- Phase 92: Scene Presets for IFLS
--
-- A "Scene" captures a snapshot of high-level IFLS state that defines
-- a particular IDM configuration:
--
--   * artist_id / artist_name
--   * active flavor
--   * groove profile
--   * rhythm style
--   * macro control values
--   * optional extra metadata (notes, tags, bpm range)
--
-- Scenes are stored in project ExtState (JSON-like serialization)
-- so they can be recalled per project. If your repo already has a
-- JSON helper module, you can swap the simple encoder/decoder here.

local ScenePresets = {}

----------------------------------------------------------------
-- SIMPLE JSON-LIKE ENCODER/DECODER (Lua tables only)
----------------------------------------------------------------
-- To keep this self-contained, we implement a minimal encoder for
-- basic tables (no cyclic refs, no metatables). You can replace
-- this with your own JSON lib (dkjson, lunajson, etc.) if preferred.

local function escape_str(s)
  s = tostring(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub("\"", "\\\"")
  s = s:gsub("\n", "\\n")
  return s
end

local function encode_value(v)
  local t = type(v)
  if t == "string" then
    return "\"" .. escape_str(v) .. "\""
  elseif t == "number" then
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    -- treat as object with string keys (simple)
    local parts = {}
    for k, vv in pairs(v) do
      local key = "\"" .. escape_str(k) .. "\""
      local val = encode_value(vv)
      table.insert(parts, key .. ":" .. val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  else
    return "null"
  end
end

local function encode_scene(scene)
  return encode_value(scene)
end

-- Very minimal decoder: expects a single level of {key:value,...}
-- where values are strings, numbers, booleans or nested tables.
-- For complex scenes it's usually enough; you can replace this with
-- a robust JSON library in your repo.
local function decode_scene(str)
  if not str or str == "" then return nil end
  local ok, res = pcall(load("return " .. str:gsub("null", "nil")))
  if not ok then return nil end
  if type(res) ~= "table" then return nil end
  return res
end

----------------------------------------------------------------
-- EXTSTATE BACKEND
----------------------------------------------------------------

local NS = "IFLS_SCENES"
local LIST_KEY = "__scene_list" -- stores comma-separated list of ids

local function get_proj()
  return 0
end

local function read_ext(key)
  local proj = get_proj()
  local rv, val = reaper.GetProjExtState(proj, NS, key)
  if rv == 0 or val == "" then return nil end
  return val
end

local function write_ext(key, val)
  local proj = get_proj()
  reaper.SetProjExtState(proj, NS, key, val or "")
end

local function list_ids()
  local s = read_ext(LIST_KEY)
  if not s then return {} end
  local ids = {}
  for id in string.gmatch(s, "([^,]+)") do
    table.insert(ids, id)
  end
  return ids
end

local function save_ids(ids)
  write_ext(LIST_KEY, table.concat(ids, ","))
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

--- Save a scene with given id.
-- scene = {
--   id           = "scene1",
--   name         = "Glitch Intro",
--   artist_id    = "artist_foo",
--   artist_name  = "Foo",
--   flavor       = "GlitchCore",
--   groove_profile = "IDM_MicroSwing",
--   rhythm_style   = "IDM_Chaos",
--   macros = {
--     glitch_intensity = 0.8,
--     rhythm_chaos     = 0.7,
--     texture_depth    = 0.6,
--     human_vs_robot   = 0.3,
--   },
--   meta = {
--     bpm_min = 140,
--     bpm_max = 180,
--     tags    = {"intro","glitch"},
--     notes   = "High-energy glitch opener",
--   },
-- }
function ScenePresets.save(scene)
  if not scene or not scene.id then return end
  local ids = list_ids()
  local exists = false
  for i, id in ipairs(ids) do
    if id == scene.id then
      exists = true
      break
    end
  end
  if not exists then
    table.insert(ids, scene.id)
    save_ids(ids)
  end

  write_ext(scene.id, encode_scene(scene))
end

--- Load scene by id.
function ScenePresets.load(id)
  if not id then return nil end
  local s = read_ext(id)
  if not s then return nil end
  return decode_scene(s)
end

--- Delete scene by id.
function ScenePresets.delete(id)
  if not id then return end
  -- remove id from list
  local ids = list_ids()
  local out = {}
  for _, sid in ipairs(ids) do
    if sid ~= id then table.insert(out, sid) end
  end
  save_ids(out)
  write_ext(id, "")
end

--- List all scenes (ids + raw scenes).
function ScenePresets.list()
  local ids = list_ids()
  local scenes = {}
  for _, id in ipairs(ids) do
    local sc = ScenePresets.load(id)
    if sc then
      table.insert(scenes, sc)
    end
  end
  return scenes
end

----------------------------------------------------------------
-- HELPER: BUILD SCENE FROM CURRENT IFLS STATE
----------------------------------------------------------------

-- This helper expects there to be modules like:
--   IFLS_MacroControls
--   IFLS_FlavorState
--   IFLS_GroovePool (for current groove profile name)
-- etc.
-- You can adapt this to your actual IFLS modules.

function ScenePresets.capture_current(args)
  args = args or {}

  local scene = {
    id            = args.id or ("scene_" .. tostring(os.time())),
    name          = args.name or "Unnamed Scene",
    artist_id     = args.artist_id,
    artist_name   = args.artist_name,
    flavor        = args.flavor,
    groove_profile= args.groove_profile,
    rhythm_style  = args.rhythm_style,
    macros        = args.macros or {},
    meta          = args.meta or {},
  }

  return scene
end

return ScenePresets
