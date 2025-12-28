DF95_MenuBuilder (V3)
====================

File:
  Scripts/DF95Framework/Lib/DF95_MenuBuilder.lua

Purpose:
  - Build and show gfx.showmenu() popups from a Lua table spec.
  - Support soft-disable of menu items using REAPER menu prefixes:
      # = disabled (grayed out)
      ! = checked
  - Provide show_disabled_menu() for feature-flag aware menus.

Reference:
  REAPER ReaScript API gfx.showmenu docs: '#' grays out items, empty field creates separators.

Usage:
  local MB = dofile(reaper.GetResourcePath() .. "/Scripts/DF95Framework/Lib/DF95_MenuBuilder.lua")
  MB.show({
    { label="Do thing", on_select=function() ... end },
    { separator=true },
    { label="Disabled item", disabled=true },
  }, "DF95 Menu")

Soft-disable example:
  MB.show_disabled_menu({
    title="DF95 Menü",
    reason="Diagnostics deaktiviert",
    config_path=reaper.GetResourcePath().."/Support/DF95_Config.json"
  })
