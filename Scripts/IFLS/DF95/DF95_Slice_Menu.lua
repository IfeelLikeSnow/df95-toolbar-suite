-- @description Slice Menu (Loader with Fallback)
-- @version 2.0
-- @about
--   Primärer Loader für das optionale DF95_Slicing-AddOn.
--   Fallback:
--     1) Wenn kein externes AddOn vorhanden ist, wird automatisch das
--        Weighted-Slicing-Menü geladen (DF95_Slice_Menu_Weighted.lua).
--     2) Wenn dieses nicht gefunden wird, wird das Slicing-Dropdown verwendet
--        (DF95_Menu_Slicing_Dropdown.lua), das direkt auf FXChains/DF95/Slicing zugreift.

local r = reaper

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = (res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep):gsub("\\","/")

local function try_run(path, label)
  local f = io.open(path, "rb")
  if not f then return false end
  f:close()
  local ok, err = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("DF95 Slice: Fehler in "..(label or path)..":\n"..tostring(err), "DF95 Slice", 0)
  end
  return ok
end

local function main()
  -- 1) Versuch: Externes AddOn (DF95_Slicing)
  local alt = (res..sep.."Scripts"..sep.."IFLS"..sep.."DF95_Slicing"..sep.."DF95_Slicing_Master_Menu.lua"):gsub("\\","/")
  if try_run(alt, "DF95_Slicing_Master_Menu.lua") then
    return
  end

  -- 2) Fallback: Weighted Slice Menu (Bias/Artist-basiert)
  local weighted = base.."Core"..sep.."DF95_Slice_Menu_Weighted.lua"
  if try_run(weighted, "DF95_Slice_Menu_Weighted.lua") then
    return
  end

  -- 3) Fallback: Slicing Dropdown (FXChains/DF95/Slicing)
  local dropdown = base.."DF95_Menu_Slicing_Dropdown.lua"
  if try_run(dropdown, "DF95_Menu_Slicing_Dropdown.lua") then
    return
  end

  -- 4) gar nichts gefunden
  r.ShowMessageBox(
    "DF95 Slice: Kein Slicing-Menü gefunden.\n\n" ..
    "- Optionales AddOn: Scripts/IFLS/DF95_Slicing/DF95_Slicing_Master_Menu.lua\n" ..
    "- Interne Fallbacks:\n" ..
    "   • Core/DF95_Slice_Menu_Weighted.lua\n" ..
    "   • DF95_Menu_Slicing_Dropdown.lua\n\n" ..
    "Bitte sicherstellen, dass mindestens einer dieser Pfade existiert.",
    "DF95 Slice",
    0
  )
end

main()
