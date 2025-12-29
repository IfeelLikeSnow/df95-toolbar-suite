-- @description DF95/IFLS: Sanity check (install paths + dependencies)
-- @version 1.0.0
-- @author DF95 / IFLS
-- @about
--   Checks whether the DF95/IFLS repository files are present in the REAPER resource path,
--   and whether common dependencies (SWS) appear installed.
--   Safe to run anytime.

local function ok_exists(path)
  local f = io.open(path, 'rb')
  if f then f:close() return true end
  return false
end

local rp = reaper.GetResourcePath()
local function pjoin(a,b)
  if a:sub(-1) == '/' or a:sub(-1) == '\\' then return a .. b end
  return a .. '/' .. b
end

local checks = {
  { "Scripts folder", pjoin(rp, "Scripts") },
  { "DF95 scripts (common)", pjoin(rp, "Scripts/DF95") },
  { "IFLS scripts (common)", pjoin(rp, "Scripts/IFLS") },
  { "Toolbars folder", pjoin(rp, "Toolbars") },
  { "Menus folder", pjoin(rp, "Menus") },
  { "MenuSets folder", pjoin(rp, "MenuSets") },
  { "Chains folder", pjoin(rp, "Chains") },
}

local report = {}
report[#report+1] = "REAPER resource path:"
report[#report+1] = rp
report[#report+1] = ""
report[#report+1] = "Repository presence:"
for _,c in ipairs(checks) do
  report[#report+1] = ("- %s: %s"):format(c[1], ok_exists(c[2]) and "OK" or "MISSING")
end

report[#report+1] = ""
report[#report+1] = "Dependencies:"
local has_sws = reaper.NamedCommandLookup("_SWS_ABOUT") ~= 0
report[#report+1] = ("- SWS extension: %s"):format(has_sws and "DETECTED" or "NOT DETECTED")

report[#report+1] = ""
report[#report+1] = "Next steps:"
report[#report+1] = "1) If scripts are installed but Actions are missing, run:"
report[#report+1] = "   DF95/IFLS: Register all DF95/IFLS actions (first run)"
report[#report+1] = "2) For toolbars/menus: import the MenuSet in Options -> Customize menus/toolbars -> Import..."

reaper.ShowMessageBox(table.concat(report, "\n"), "DF95/IFLS Sanity Check", 0)
