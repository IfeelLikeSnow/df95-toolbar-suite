
-- @description Diagnostics – Collect & Open HTML
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local base = reaper.GetResourcePath():gsub("\\","/")

-- Feature flag gate (V3): diagnostics can be disabled via Support/DF95_Config.json
do
  local okc, Core = pcall(dofile, base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
  if okc and type(Core) == "table" and type(Core.get_config) == "function" then
    local cfg = Core.get_config()
    if cfg and cfg.features and cfg.features.enable_diagnostics == false then
      if Core.log_info then Core.log_info("Diagnostics disabled by config: " .. (debug.getinfo(1,'S').source or '?')) end
      return
    end
  end
end
local root = r.GetResourcePath()
local data = root..sep.."Data"..sep.."DF95"..sep

local files = {
  {"Menu Lint", data.."MenuLintReport.txt"},
  {"Slicing Smoke", data.."SlicingSmokeReport.txt"},
  {"Loudness Hook", data.."LoudnessHook.log"}
}

local html = {"<html><head><meta charset='utf-8'><title>DF95 Diagnostics</title>",
"<style>body{font:13px system-ui,Segoe UI,Roboto,Arial} pre{background:#111;color:#eee;padding:12px;border-radius:6px} h2{margin-top:24px}</style>",
"</head><body><h1>DF95 Diagnostics</h1>"}

for _,pair in ipairs(files) do
  local title, path = pair[1], pair[2]
  local f = io.open(path,"rb")
  local content = ""
  if f then content = f:read("*all") f:close() else content = "(no report yet)" end
  content = content:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
  table.insert(html, "<h2>"..title.."</h2><pre>"..content.."</pre>")
end

table.insert(html, "</body></html>")
local out = data.."Diagnostics.html"
local hf = io.open(out,"wb"); if hf then hf:write(table.concat(html)); hf:close() end
r.CF_ShellExecute(out)
r.ShowConsoleMsg("[DF95] Diagnostics.html erzeugt und geöffnet.\n")
