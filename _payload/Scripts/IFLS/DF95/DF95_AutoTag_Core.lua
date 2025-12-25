-- @description AutoTag Core + NameEngine Wrapper
-- @version 1.0
-- @author DF95
-- @about
--   Stellt eine kleine, stabile API rund um DF95_Export_Core bereit:
--     * GetEffectiveTags(opts)
--     * BuildRenderBasename(opts, index, bpm, tags)
--
--   Ziel:
--     * zentrale Stelle für Tag-Logik (Role/Source/FXFlavor)
--     * Wiederverwendbarkeit für:
--         - Export-Wizard
--         - PackWizard
--         - SamplerSubsystem (C2 Kit Wizard)
--         - ArtistConsole-Tools-Tab

local r = reaper
local M = {}

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_export_core()
  local dir = df95_root()
  if dir == "" then return nil end
  local ok, core = pcall(dofile, dir .. "DF95_Export_Core.lua")
  if not ok then
    r.ShowConsoleMsg("[DF95_AutoTag_Core] Fehler beim Laden von DF95_Export_Core.lua:\n" .. tostring(core) .. "\n")
    return nil
  end
  return core
end

function M.GetEffectiveTags(opts)
  local core = load_export_core()
  if not core or type(core.GetEffectiveTags) ~= "function" then
    return "Any", "Any", "Generic"
  end
  return core.GetEffectiveTags(opts)
end

function M.BuildRenderBasename(opts, index, bpm, tags)
  local core = load_export_core()
  if not core or type(core.BuildRenderBasename) ~= "function" then
    return nil
  end
  return core.BuildRenderBasename(opts, index, bpm, tags)
end

return M
