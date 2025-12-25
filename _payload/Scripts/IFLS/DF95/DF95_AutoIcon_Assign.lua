-- @description Auto-Icon Assign (FlowErgo Creative)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Fügt Icon-Zuordnungen in DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet ein (pfadbasiert).
-- Nach dem Lauf: in REAPER Toolbar-Menü erneut "Import" und "Apply".

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local menu_path = res..sep.."Menus"..sep.."DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet"
local icon_root = res..sep.."Data"..sep.."toolbar_icons"..sep.."DF95"..sep

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
}

local function file_exists(p) local f=io.open(p,"rb"); if f then f:close(); return true end return false end

-- Read MenuSet
local f=io.open(menu_path,"rb"); if not f then r.ShowMessageBox("MenuSet nicht gefunden:\n"..menu_path,"DF95 Icon Assign",0) return end
local txt=f:read("*all"); f:close()

-- Transform: after each matching Item label block, insert ICON line if not present
local out = {}
local last_label = ""
for line in txt:gmatch("[^\r\n]*\r?\n?") do
  if line:match("^Item%d+=Custom:%s*(.+)$") then
    last_label = line:match("^Item%d+=Custom:%s*(.+)$") or ""
  end
  table.insert(out, line)
  if line:match("^%s*SCRIPT:%s*") and last_label ~= "" then
    local icon = map[last_label]
    if icon then
      local full = icon_root .. icon
      if file_exists(full) then
        table.insert(out, ("ICON: Data/toolbar_icons/DF95/%s\n"):format(icon))
      end
    end
    last_label = ""
  end
end

local bak = menu_path..".bak"
os.remove(bak)
os.rename(menu_path, bak)

local g=io.open(menu_path,"wb"); g:write(table.concat(out)); g:close()

r.ShowMessageBox("Icon-Zuordnung geschrieben.\nRe-Importiere die Toolbar und klicke Apply.\nBackup: "..bak, "DF95 Icon Assign", 0)
