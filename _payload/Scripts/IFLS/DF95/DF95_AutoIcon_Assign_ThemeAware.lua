-- @description Auto-Icon Assign (Theme-Aware, light/dark sets)
-- @version 1.1
-- @author IfeelLikeSnow
-- Chooses icon set (dark/light) based on current theme background luminance and writes ICON lines.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local menu_path = res..sep.."Menus"..sep.."DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet"
local icons_dark = "Data/toolbar_icons/DF95/dark/"
local icons_light = "Data/toolbar_icons/DF95/light/"

-- Rough luminance from colortable if available
local function get_luminance_from_theme()
  if not r.GetLastColorThemeFile then return 0.2 end
  local theme = r.GetLastColorThemeFile()
  -- Try to open colortable inside themezip not trivial; fallback to guess by theme name
  local lower = theme:lower()
  if lower:find("dark") or lower:find("balanced") or lower:find("hydra") or lower:find("imperial") then
    return 0.2 -- darkish
  end
  if lower:find("light") or lower:find("white") then
    return 0.8
  end
  return 0.35 -- default a bit dark
end

local function pick_set()
  local L = get_luminance_from_theme() -- 0..1
  if L >= 0.6 then return icons_light else return icons_dark end
end

local set_prefix = pick_set()

local map = {
  ["DF95 – Explode AutoBus"]       = "df95_explode.png",
  ["DF95 – Mic FX"]                = "df95_micfx.png",
  ["DF95 – FX Bus"]                = "df95_fxbus.png",
  ["DF95 – FX Seed"]               = "df95_seed.png",
  ["DF95 – Coloring Bus"]          = "df95_coloring.png",
  ["DF95 – Coloring A/B (GainMatch)"] = "df95_ab.png",
  ["DF95 – Master Bus"]            = "df95_master.png",
  ["DF95 – Slicing"]               = "df95_slicing.png",
  ["DF95 – Rearrange / Align"]     = "df95_rearrange.png",
  ["DF95 – Loop / Rhythm Builder"] = "df95_loop.png",
  ["DF95 – LiveCheck"]             = "df95_livecheck.png",
  ["DF95 – Safety / Loudness"]     = "df95_safety.png",
  ["DF95 – Console Mode Switch"]   = "df95_console.png",
  ["DF95 – Post-Install Validator"]= "df95_validator.png"
,["DF95_Beat_ControlCenter_ImGui"]       = "df95_beat_console.png"
,["DF95_Global_BeatPresetLoader_ImGui"]  = "df95_beat_preset.png"
,["DF95_Sampler_SitalaKitBuilder_v1"]    = "df95_sitala.png"
,["DF95_Script_HealthCheck"]             = "df95_health_console.png"
,["DF95_Script_HealthCheck_ImGui"]       = "df95_health_gui.png"
,["DF95_Script_HealthCheck_AutoReport"]  = "df95_health_report.png"
,["DF95 SuperToolbar Toggle BEAT"]       = "df95_beat_hub.png"
}

local function file_exists(p) local f=io.open(p,"rb"); if f then f:close(); return true end return false end

-- Read MenuSet
local f=io.open(menu_path,"rb"); if not f then r.ShowMessageBox("MenuSet nicht gefunden:\n"..menu_path,"DF95 Icon Assign",0) return end
local txt=f:read("*all"); f:close()

-- Transform: after each matching Item label block, insert/update ICON line
local out = {}
local last_label = ""
for line in txt:gmatch("[^\r\n]*\r?\n?") do
  if line:match("^Item%d+=Custom:%s*(.+)$") then
    last_label = line:match("^Item%d+=Custom:%s*(.+)$") or ""
  end
  -- Skip previous ICON lines for our DF95 icons (we'll rewrite)
  if line:match("^%s*ICON:%s*Data/toolbar_icons/DF95/") then
    -- drop
  else
    table.insert(out, line)
  end
  if line:match("^%s*SCRIPT:%s*") and last_label ~= "" then
    local icon = map[last_label]
    if icon then
      local full = res..sep..set_prefix..icon
      if file_exists(full) then
        table.insert(out, ("ICON: %s%s\n"):format(set_prefix, icon))
      end
    end
    last_label = ""
  end
end

local bak = menu_path..".bak"
os.remove(bak)
os.rename(menu_path, bak)

local g=io.open(menu_path,"wb"); g:write(table.concat(out)); g:close()

r.ShowMessageBox("DF95 Icon Assign (Theme-Aware):\nSet verwendet: "..set_prefix.."\nBackup: "..bak.."\nToolbar jetzt re-importieren und Apply.", "DF95 Icon Assign", 0)
