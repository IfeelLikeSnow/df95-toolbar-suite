-- @description ThemeAdaptive Loader (Icon profile + spacer auto-select)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Setzt ICON_PROFILE & SPACER_MODE abhängig vom REAPER-Theme.
local r = reaper
local theme = (r.GetLastColorThemeFile() or ""):lower()
local profile = "mono_standard"
local spacer  = "auto"

if theme:find("df95_balancedstudio") then profile="mono_standard"; spacer="wide"
elseif theme:find("hydra") then profile="dark_flat"; spacer="wide"
elseif theme:find("commala") then profile="warm_flat"; spacer="narrow"
elseif theme:find("imperial") or theme:find("lcs") then profile="light_outline"; spacer="compact" end

r.SetExtState("DF95_UI", "ICON_PROFILE", profile, true)
r.SetExtState("DF95_UI", "SPACER_MODE", spacer, true)
r.ShowConsoleMsg(("[DF95] ThemeAdaptive → ICON_PROFILE=%s, SPACER_MODE=%s\n"):format(profile, spacer))
