-- DF95_Capabilities.lua (V3)
-- Capability detection helpers for REAPER extensions / APIs.
-- Designed to be safe: detection is by probing function existence.
local r = reaper

local M = {}

function M.detect()
  return {
    sws = (type(r.CF_ShellExecute) == "function") or (type(r.BR_Win32_GetPrivateProfileString) == "function"),
    reapack = (type(r.ReaPack_BrowsePackages) == "function") or (type(r.ReaPack_About) == "function"),
    reaimgui = (type(r.ImGui_CreateContext) == "function"),
    js_reascriptapi = (type(r.JS_Window_Find) == "function") or (type(r.JS_Window_FindEx) == "function"),
  }
end

function M.missing(reqs, caps)
  caps = caps or M.detect()
  reqs = reqs or {}
  local missing = {}
  for _,k in ipairs(reqs) do
    if not caps[k] then missing[#missing+1] = k end
  end
  return missing
end

return M
