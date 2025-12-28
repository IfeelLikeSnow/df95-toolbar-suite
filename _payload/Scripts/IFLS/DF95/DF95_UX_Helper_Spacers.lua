-- @description UX Helper – Spacer & Icon profile
-- @version 1.0
local r = reaper
local sep = package.config:sub(1,1)
local prof = r.GetResourcePath()..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_UX_Profile.json"
local function readfile(p) local f=io.open(p,"rb"); if not f then return "" end local d=f:read("*all"); f:close(); return d end
local s = readfile(prof)
local function jget(k) return s:match('"'..k..'":"(.-)"') end
local spacer = jget("spacer") or "auto"
local density = jget("density") or "normal"
local theme = jget("theme") or "unknown"
local msg = ("DF95 UX Profile\nTheme: %s\nSpacer: %s\nDensity: %s\n\nEmpfehlung:\n- Spacer: %s leere Items\n"):format(
  theme, spacer, density, (spacer=="wide" and "3" or spacer=="narrow" and "1" or "2"))
r.ShowMessageBox(msg,"DF95 UX Helper",0)
