-- IFLS_PerfProbe.lua
-- Phase 93: Simple Performance Probes
--
-- This module provides a very small performance-probe facility:
--   * mark sections of code with start/stop
--   * aggregate total time & call count per label
--   * dump a flat report to console
--
-- This follows the "annotated probe" approach used in many game/audio
-- engines, where strategically placed timers give quick feedback
-- without heavy external tooling. citeturn6search1turn6search3turn6search9turn6search13

local PerfProbe = {}

local probes = {}

local function now()
  if reaper and reaper.time_precise then
    return reaper.time_precise()
  else
    return os.clock()
  end
end

--- Begin timing a section.
function PerfProbe.begin(label)
  if not label then return end
  local p = probes[label]
  if not p then
    p = { label = label, total = 0.0, calls = 0, _stack = {} }
    probes[label] = p
  end
  table.insert(p._stack, now())
end

--- End timing a section.
function PerfProbe.finish(label)
  if not label then return end
  local p = probes[label]
  if not p or not p._stack or #p._stack == 0 then return end
  local t0 = table.remove(p._stack)
  local dt = now() - t0
  p.total = p.total + dt
  p.calls = p.calls + 1
end

--- Clear all probe data.
function PerfProbe.clear()
  probes = {}
end

--- Return raw probe data.
function PerfProbe.get_all()
  return probes
end

--- Dump a simple report to REAPER console.
function PerfProbe.dump_to_console()
  reaper.ShowConsoleMsg("=== IFLS PerfProbe report ===\n")
  local list = {}
  for label, p in pairs(probes) do
    table.insert(list, p)
  end
  table.sort(list, function(a,b) return a.total > b.total end)
  for _, p in ipairs(list) do
    local ms = p.total * 1000.0
    local avg = (p.calls > 0) and (ms / p.calls) or 0.0
    reaper.ShowConsoleMsg(string.format(
      "%-40s total=%8.3f ms  calls=%5d  avg=%6.3f ms\n",
      p.label, ms, p.calls, avg
    ))
  end
  reaper.ShowConsoleMsg("=== end perf report ===\n")
end

return PerfProbe
