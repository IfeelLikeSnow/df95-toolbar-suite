\
-- @description Add Co-Toolbar (safe import helper)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Kopiert DF95_CoToolbar_FlowErgo_Pro.ReaperMenuSet nach Menus und öffnet den Customize-Dialog.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local function read_text(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function write_text(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end

local src = res..sep.."Menus"..sep.."DF95_CoToolbar_FlowErgo_Pro.ReaperMenuSet"
if not read_text(src) then
  -- try to locate within script dir (portable unpack)
  local here = (debug.getinfo(1,"S").source:match("(.+[\\/])") or "")..".."..sep..".."..sep.."Menus"..sep.."DF95_CoToolbar_FlowErgo_Pro.ReaperMenuSet"
  local data = read_text(here)
  if data then write_text(src, data) end
end

r.Main_OnCommand(40016,0) -- Customize menus/toolbars
r.ShowMessageBox("Co-Toolbar bereit.\nIm Dialog: Toolbar auswählen (z.B. Toolbar 2) → Import → DF95_CoToolbar_FlowErgo_Pro.ReaperMenuSet → Apply.", "DF95 Co-Toolbar", 0)
