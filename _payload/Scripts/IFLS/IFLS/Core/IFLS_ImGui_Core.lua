-- IFLS_ImGui_Core.lua
local M = {}
local r = reaper
local ig = r.ImGui

function M.create_context(name)
  if not ig or not ig.CreateContext then
    r.ShowMessageBox(
      "ReaImGui API not found.\n\nPlease install the ReaImGui extension via ReaPack.",
      "IFLS ImGui Core",
      0
    )
    return nil
  end
  local ctx = ig.CreateContext(name or "IFLS_ImGui")
  ig.Attach(ctx)
  return ctx
end

function M.run_mainloop(ctx, window_title, draw_fn)
  if not ctx then return end
  window_title = window_title or "IFLS Panel"

  local function loop()
    if not ig.ValidatePtr(ctx, "ImGui_Context*") then return end
    ig.NewFrame(ctx)
    local visible, open = ig.Begin(ctx, window_title, true)
    if visible then
      local ok, err = pcall(draw_fn, ctx)
      if not ok then
        r.ShowConsoleMsg("IFLS ImGui draw error: " .. tostring(err) .. "\n")
      end
    end
    ig.End(ctx)
    ig.Render(ctx)
    r.defer(loop)
  end

  loop()
end

function M.set_default_window_size(ctx, width, height)
  width  = width  or 700
  height = height or 420
  ig.SetNextWindowSize(ctx, width, height, ig.Cond_FirstUseEver())
end

return M
