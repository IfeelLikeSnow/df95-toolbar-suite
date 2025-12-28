-- @description DF95/IFLS: Open REAPER resource path (for troubleshooting)
-- @version 1.0.0
-- @author DF95 / IFLS
-- @about
--   Opens the REAPER resource path in your file browser.

local rp = reaper.GetResourcePath()
-- 40025: Show REAPER resource path in explorer/finder
reaper.Main_OnCommand(40025, 0)
reaper.ShowMessageBox(rp, "REAPER resource path", 0)
