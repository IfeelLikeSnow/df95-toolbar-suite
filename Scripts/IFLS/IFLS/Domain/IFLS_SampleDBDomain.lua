-- IFLS_SampleDBDomain.lua
-- Phase 5: Extended SampleDB Domain (Loops / Speech / Artist-Beat linkage)
-- -----------------------------------------------------------------------

local r = reaper
local resource_path = r.GetResourcePath()
local core_path   = resource_path .. "/Scripts/IFLS/IFLS/Core/"
local config_path = resource_path .. "/Scripts/IFLS/IFLS/Config/"

local ok_contracts, contracts = pcall(dofile, core_path .. "IFLS_Contracts.lua")
local ok_ext,       ext       = pcall(dofile, core_path .. "IFLS_ExtState.lua")

if not ok_contracts or type(contracts) ~= "table" then
  r.ShowConsoleMsg("IFLS_SampleDBDomain: Failed to load IFLS_Contracts.lua\n")
  contracts = {
    NS_SAMPLEDB   = "DF95_SAMPLEDB",
    SAMPLEDB_KEYS = {},
  }
end

if not ok_ext or type(ext) ~= "table" then
  r.ShowConsoleMsg("IFLS_SampleDBDomain: Failed to load IFLS_ExtState.lua\n")
  ext = {
    get     = function(_,_,default) return default end,
    set     = function() end,
    get_proj= function(_,_,default) return default end,
    set_proj= function() end,
  }
end

local action_map = {}
do
  local ok_map, map = pcall(dofile, config_path .. "IFLS_ActionMap.lua")
  if ok_map and type(map) == "table" then
    action_map = map
  else
    action_map = {}
  end
end

local M = {}

local ns   = contracts.NS_SAMPLEDB   or "DF95_SAMPLEDB"
local SK   = contracts.SAMPLEDB_KEYS or {}

function M.get_state()
  local s = {}
  s.active_library   = ext.get(ns, SK.ACTIVE_LIBRARY   or "ACTIVE_LIBRARY",   "")
  s.tag_filter       = ext.get(ns, SK.TAG_FILTER       or "TAG_FILTER",       "")
  s.loop_tag         = ext.get(ns, SK.LOOP_TAG         or "LOOP_TAG",         "loop")
  s.speech_tag       = ext.get(ns, SK.SPEECH_TAG       or "SPEECH_TAG",       "speech")
  s.last_selection   = ext.get(ns, SK.LAST_SELECTION   or "LAST_SELECTION",   "")
  s.category_hint    = ext.get(ns, SK.CATEGORY_HINT    or "CATEGORY_HINT",    "")
  s.filter_hint      = ext.get(ns, SK.FILTER_HINT      or "FILTER_HINT",      "")
  return s
end

function M.set_state(st)
  if not st then return end
  if st.active_library ~= nil then
    ext.set(ns, SK.ACTIVE_LIBRARY or "ACTIVE_LIBRARY", st.active_library, true)
  end
  if st.tag_filter ~= nil then
    ext.set(ns, SK.TAG_FILTER or "TAG_FILTER", st.tag_filter, true)
  end
  if st.loop_tag ~= nil then
    ext.set(ns, SK.LOOP_TAG or "LOOP_TAG", st.loop_tag, true)
  end
  if st.speech_tag ~= nil then
    ext.set(ns, SK.SPEECH_TAG or "SPEECH_TAG", st.speech_tag, true)
  end
  if st.last_selection ~= nil then
    ext.set(ns, SK.LAST_SELECTION or "LAST_SELECTION", st.last_selection, true)
  end
  if st.category_hint ~= nil then
    ext.set(ns, SK.CATEGORY_HINT or "CATEGORY_HINT", st.category_hint, true)
  end
  if st.filter_hint ~= nil then
    ext.set(ns, SK.FILTER_HINT or "FILTER_HINT", st.filter_hint, true)
  end
end

local SampleDBActions = {
  BROWSER_OPEN    = (action_map.SampleDB and action_map.SampleDB.BROWSER_OPEN)    or "_RS_DF95_SAMPLEDB_Browser_ImGui",
  INDEX_REBUILD   = (action_map.SampleDB and action_map.SampleDB.INDEX_REBUILD)   or "_RS_DF95_SAMPLEDB_RebuildIndex",
  ANALYZE_LIBRARY = (action_map.SampleDB and action_map.SampleDB.ANALYZE_LIBRARY) or "_RS_DF95_SAMPLEDB_Analyzer",
}

local LayersActions = {
  V198_LOOP_LAYERS   = (action_map.Layers and action_map.Layers.V198_LOOP_LAYERS)   or "_RS_DF95_V198_LoopLayers",
  V198_SPEECH_LAYERS = (action_map.Layers and action_map.Layers.V198_SPEECH_LAYERS) or "_RS_DF95_V198_SpeechLoopLayers",
}

local function run_action_by_named_cmd(named_cmd)
  if not named_cmd or named_cmd == "" then return end
  local cmd_id = r.NamedCommandLookup(named_cmd)
  if cmd_id == 0 then
    r.ShowConsoleMsg("IFLS_SampleDBDomain: NamedCommandLookup failed for " .. tostring(named_cmd) .. "\n")
    return
  end
  r.Main_OnCommand(cmd_id, 0)
end

function M.open_browser()
  local id = SampleDBActions.BROWSER_OPEN
  if id then run_action_by_named_cmd(id) end
end

function M.rebuild_index()
  local id = SampleDBActions.INDEX_REBUILD
  if id then run_action_by_named_cmd(id) end
end

function M.analyze_library()
  local id = SampleDBActions.ANALYZE_LIBRARY
  if id then run_action_by_named_cmd(id) end
end

function M.build_loop_layers()
  local id = LayersActions.V198_LOOP_LAYERS
  if id then run_action_by_named_cmd(id) end
end

function M.build_speech_layers()
  local id = LayersActions.V198_SPEECH_LAYERS or LayersActions.V198_LOOP_LAYERS
  if id then run_action_by_named_cmd(id) end
end

function M.apply_artist_hints_to_sampledb(artist_state)
  if not artist_state then return end
  local st = M.get_state()
  if artist_state.sampledb_category and artist_state.sampledb_category ~= "" then
    st.category_hint = artist_state.sampledb_category
  end
  if artist_state.sampledb_filter and artist_state.sampledb_filter ~= "" then
    st.filter_hint = artist_state.sampledb_filter
  end
  M.set_state(st)
end

return M
