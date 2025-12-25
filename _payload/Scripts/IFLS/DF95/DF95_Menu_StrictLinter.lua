-- DF95_Menu_StrictLinter.lua (V3 Hub Entrypoint)
-- This entry script is kept for backward compatibility (Action stays the same).
-- It delegates to the central hub definitions in Scripts/DF95Framework/Menus/DF95_Hubs.lua

local r = reaper
local base = r.GetResourcePath():gsub("\\","/")

local Hubs = dofile(base .. "/Scripts/DF95Framework/Menus/DF95_Hubs.lua")
Hubs.run_hub("diagnostics_strictlinter")


--[[
LEGACY CONTENT (preserved for reference):

-- @description Strict Menu Linter (SCRIPT path validator + auto-fix suggester)
-- @version 1.0
-- @about Prüft alle Menüs (*.ReaperMenuSet) im Menus/-Ordner. Log: Data/DF95/MenuLintReport.txt
local r = reaper

-- V3 Feature Flags (menu flag-aware)
local __df95_base = reaper.GetResourcePath():gsub("\\","/")
local __df95_Core = dofile(__df95_base .. "/Scripts/DF95Framework/Lib/DF95_Core.lua")
local __df95_cfg = (__df95_Core and __df95_Core.get_config) and __df95_Core.get_config() or {}

if __df95_cfg.features and __df95_cfg.features.enable_diagnostics == false then
  local MB = dofile(__df95_base .. "/Scripts/DF95Framework/Lib/DF95_MenuBuilder.lua")
  MB.show_disabled_menu({
    title = "DF95 Menü",
    reason = "Diagnostics deaktiviert",
    config_path = __df95_base .. "/Support/DF95_Config.json"
  })
  return
end

local sep = package.config:sub(1,1)
local root = r.GetResourcePath()
local menus_dir = root..sep.."Menus"..sep
local out = root..sep.."Data"..sep.."DF95"..sep.."MenuLintReport.txt"
local function log(s) local f=io.open(out,"a"); if f then f:write(s.."\n"); f:close() end
local function exists(path)
  local f=io.open(path,"rb"); if f then f:close(); return true end; return false
end
local function normalize(p)
  p = p:gsub("\\\\","/"); p = p:gsub("/", sep)
  if p:sub(1,1) ~= sep then
    p = root .. sep .. p
  end
  return p
end
-- reset file
local f=io.open(out,"wb"); if f then f:write(""); f:close() end
log("[DF95 Linter] Start "..os.date())
-- enumerate menu files
local i=0; local m = r.EnumerateFiles(menus_dir, i)
while m do
  if m:lower():match("%.reapermenuSet$"):lower() then
    local path = menus_dir..m
    local t = {}
    for line in io.lines(path) do table.insert(t, line) end
    local errors = 0
    for idx,line in ipairs(t) do
      local script = line:match("^%s*SCRIPT:%s*(.+)$")
      if script then
        local np = normalize(script)
        if not exists(np) then
          errors = errors + 1
          -- heuristics
          local try_slash = normalize(script:gsub("\\\\","/"))
          local try_back  = normalize(script:gsub("/","\\\\"))
          log(string.format("[MENU:%s] Missing: %s", m, script))
          log("  → Try (slash):   "..try_slash)
          log("  → Try (backslash): "..try_back)
          -- common DF95 roots
          if not script:find("Scripts/IFLS/") and script:lower():find("scripts/") then
            local sug = script:gsub("Scripts/", "Scripts/IFLS/DF95/")
            log("  → Try (DF95-root): "..normalize(sug))
          end
        end
      end
    end
    if errors==0 then
      log(string.format("[MENU:%s] OK (no missing SCRIPT refs)", m))
    end
  end
  i = i + 1; m = r.EnumerateFiles(menus_dir, i)
end
log("[DF95 Linter] End")
r.ShowConsoleMsg("[DF95] Menu Lint abgeschlossen. Report: Data/DF95/MenuLintReport.txt\n")

]]
