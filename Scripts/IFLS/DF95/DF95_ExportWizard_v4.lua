-- @description ExportWizard v4 (NameEngine + KitMeta aware)
-- @version 1.0
-- @author DF95
-- @about
--   Dünner Wrapper um DF95_Export_Core.run(opts), damit der Wizard
--   ggf. als eigene Action aufgerufen werden kann. Die eigentliche
--   UI- und Tag-Steuerung erfolgt über die ArtistConsole (EXPORT-Tab)
--   sowie über DF95_Export_PackWizard.lua und die AutoTag/NameEngine-
--   Pipeline. Dieses Script ist vorrangig als Einstiegs-Action gedacht.
--
--   Standardverhalten:
--     * mode      = "SELECTED_SLICES"
--     * target    = "ORIGINAL" (Format via Export-Core umschaltbar)
--     * category  = "Slices_Master"
--     * subtype   = "" (kann z.B. durch TagProfiles ergänzt werden)
--
--   Hinweis:
--     Naming-Style wird über ExtState "DF95_EXPORT_NAMESTYLE" / "Style"
--     beeinflusst und in DF95_Export_Core.build_render_basename
--     ausgewertet (DF95 / Splice / Loopmasters / ADSR).

local r = reaper

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function main()
  local dir = df95_root()
  if dir == "" then
    r.ShowMessageBox("DF95_ExportWizard_v4: Konnte Script-Ordner nicht bestimmen.", "DF95 ExportWizard v4", 0)
    return
  end

  local ok, core = pcall(dofile, dir .. "DF95_Export_Core.lua")
  if not ok or not core or type(core.run) ~= "function" then
    r.ShowMessageBox("DF95_ExportWizard_v4: Konnte DF95_Export_Core.lua nicht laden:\\n" .. tostring(core), "DF95 ExportWizard v4", 0)
    return
  end

  local opts = {
    mode     = "SELECTED_SLICES",
    target   = "ORIGINAL",
    category = "Slices_Master",
    subtype  = "",
  }
  core.run(opts)
end

main()
