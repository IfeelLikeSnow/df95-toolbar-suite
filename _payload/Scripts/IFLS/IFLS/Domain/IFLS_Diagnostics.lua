-- IFLS_Diagnostics.lua
-- Phase 93: Diagnostics & Event Logging
--
-- Lightweight diagnostics / logging hub for IFLS.
-- Responsibilities:
--   * Collect high-level "what happened?" events (pattern morphed, FX chain chosen, scene loaded, etc.)
--   * Store short in-memory history per session (ring buffer).
--   * Allow subsystems to record timing info (duration in ms).
--   * Provide a simple console dump for debugging.
--
-- This is intentionally minimal and text-based, following common logging
-- best practices (include timestamp, event type, and key fields; avoid
-- sensitive payloads; keep format machine- and human-readable). citeturn6search10turn6search12

local Diagnostics = {}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

-- Max number of events kept in memory
local MAX_EVENTS = 500

-- Whether to also mirror events to REAPER console (for hardcore debug)
local MIRROR_TO_CONSOLE = false

----------------------------------------------------------------
-- INTERNAL STATE
----------------------------------------------------------------

local events = {}
local next_id = 1

local function now_time_precise()
  if reaper and reaper.time_precise then
    return reaper.time_precise()
  else
    return os.clock()
  end
end

local function now_timestamp()
  if reaper and reaper.format_timestr_pos then
    -- project time 0 with "datetime" format
    local t = os.time()
    return os.date("%Y-%m-%d %H:%M:%S", t)
  else
    return string.format("%.3f", os.clock())
  end
end

local function push_event(ev)
  ev.id        = next_id
  ev.ts_raw    = now_time_precise()
  ev.timestamp = now_timestamp()
  next_id      = next_id + 1

  table.insert(events, ev)
  if #events > MAX_EVENTS then
    table.remove(events, 1)
  end

  if MIRROR_TO_CONSOLE then
    reaper.ShowConsoleMsg(string.format(
      "[IFLS] %s | %s | %s\n",
      ev.timestamp or "?", ev.type or "event", ev.message or ""
    ))
  end
end

----------------------------------------------------------------
-- PUBLIC API: LOGGING
----------------------------------------------------------------

--- Log a generic IFLS event.
-- type  : string, e.g. "scene_load", "rhythm_morph", "fx_chain_build"
-- message: short description
-- data  : optional table with extra info (pattern_id, chain_name, etc.)
function Diagnostics.log(type_, message, data)
  local ev = {
    type    = type_ or "event",
    message = message or "",
    data    = data or {},
  }
  push_event(ev)
end

--- Log timing info for an operation.
-- name   : string identifier ("BeatEngine.export", "RhythmMorpher.morph")
-- ms     : duration in milliseconds
-- data   : optional extra context
function Diagnostics.log_timing(name, ms, data)
  local ev = {
    type    = "timing",
    message = name or "timing",
    data    = data or {},
    ms      = ms,
  }
  push_event(ev)
end

--- Measure duration of a function call and log it.
-- name : label
-- fn   : function to call
-- data : optional table merged into log entry
function Diagnostics.profile_block(name, fn, data)
  if type(fn) ~= "function" then return nil end
  local t0 = now_time_precise()
  local ok, res1, res2, res3 = pcall(fn)
  local t1 = now_time_precise()
  local ms = (t1 - t0) * 1000.0
  Diagnostics.log_timing(name, ms, data)
  if not ok then
    Diagnostics.log("error", "profile_block error: "..tostring(res1), {block=name})
    return nil
  end
  return res1, res2, res3
end

----------------------------------------------------------------
-- PUBLIC API: QUERY
----------------------------------------------------------------

function Diagnostics.get_events()
  return events
end

function Diagnostics.get_last(n)
  n = n or 20
  local out = {}
  local start = math.max(1, #events - n + 1)
  for i = start, #events do
    table.insert(out, events[i])
  end
  return out
end

function Diagnostics.filter(predicate)
  local out = {}
  for _, ev in ipairs(events) do
    if predicate(ev) then
      table.insert(out, ev)
    end
  end
  return out
end

----------------------------------------------------------------
-- PUBLIC API: CONSOLE DUMP
----------------------------------------------------------------

local function format_data_table(t)
  if not t then return "" end
  local parts = {}
  for k, v in pairs(t) do
    table.insert(parts, tostring(k).."="..tostring(v))
  end
  return table.concat(parts, " ")
end

function Diagnostics.dump_to_console(limit)
  limit = limit or 80
  local list = Diagnostics.get_last(limit)
  reaper.ShowConsoleMsg("=== IFLS Diagnostics (last "..tostring(#list).." events) ===\n")
  for _, ev in ipairs(list) do
    local line = string.format(
      "#%d %s | %s | %s",
      ev.id or 0,
      ev.timestamp or "?",
      ev.type or "event",
      ev.message or ""
    )
    local extra = {}

    if ev.ms then
      table.insert(extra, string.format("dur=%.2fms", ev.ms))
    end
    if ev.data then
      table.insert(extra, format_data_table(ev.data))
    end

    if #extra > 0 then
      line = line .. " | " .. table.concat(extra, " ")
    end

    reaper.ShowConsoleMsg(line.."\n")
  end
  reaper.ShowConsoleMsg("=== end ===\n")
end

return Diagnostics
