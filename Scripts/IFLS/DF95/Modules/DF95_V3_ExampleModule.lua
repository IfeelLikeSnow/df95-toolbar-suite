-- DF95_V3_ExampleModule.lua
-- Example V3 module: demonstrates Core usage, logging, and a small utility.
-- Loaded via dofile() from an entry script.

local M = {}

function M.run(Core, opts)
  opts = opts or {}
  if not Core then return false, "Core missing" end

  Core.log_info("ExampleModule: run() started")

  -- Example: do something harmless in REAPER: show selected track count
  local sel = reaper.CountSelectedTracks(0)
  Core.log_info("ExampleModule: selected tracks = " .. tostring(sel))

  -- Example return payload
  return true, { selected_tracks = sel, timestamp = os.date("%Y-%m-%d %H:%M:%S") }
end

return M
