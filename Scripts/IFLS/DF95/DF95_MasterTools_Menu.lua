if not (gfx and gfx.getchar) then gfx = gfx or {} end; if not gfx.init then gfx.init("DF95", 10, 10) end -- DF95_GFX_GUARD
-- @description Master Menu – Tools (XL)
-- @version 1.2
-- @author DF95
local r = reaper
local sep = package.config:sub(1,1)
local base = (debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")") or ""
local items = {
  "# DF95 Master Tools",
  "SmartCeiling…",
  "SmartCeiling – Toggle TP Hard Safety…",
  "Color Bias…",
  "Customize Bias Profiles…",
  "-",
  "GainMatch (LUFS) – Auto-Learn…",
  "GainMatch (LUFS) – Autopilot…",
  "GainMatch (LUFS) – Manual…",
  "-",
  "Parallel FX – Presets…",
  "Parallel FX – Dry/Wet Macro…",
  "Parallel FX – Auto Route",
  "-",
  "Validator 2.1 (GUI)…",
  "Run Validator 2.0"
}
local menu = table.concat(items, "|")
gfx.init("DF95 Master Tools",0,0,0,0,0)
local x,y = r.GetMousePosition(); gfx.x,gfx.y=x,y
local idx = gfx.showmenu(menu); gfx.quit()
if     idx == 2  then dofile(base.."DF95_SmartCeiling.lua")
elseif idx == 3  then dofile(base.."DF95_ColorBias_Manager.lua")
elseif idx == 4  then dofile(base.."DF95_ColorBias_Customizer.lua")
elseif idx == 6  then dofile(base.."DF95_GainMatch_LUFS_AutoLearn.lua")
elseif idx == 7  then dofile(base.."DF95_GainMatch_LUFS_Autopilot.lua")
elseif idx == 8  then dofile(base.."DF95_GainMatch_LUFS_Manual.lua")
elseif idx == 10 then dofile(base.."DF95_ParallelFX_Presets_Menu.lua")
elseif idx == 11 then dofile(base.."DF95_ParallelFX_AutoRoute.lua")
elseif idx == 11+1 then dofile(base.."DF95_ParallelFX_DryWet_Macro.lua")
elseif idx == 13 then dofile(base.."DF95_Validator_GUI.lua")
elseif idx == 14 then dofile(base.."DF95_PostInstall_Validator2.lua")
end