-- @description Auto-Register Core & Dropdown Scripts (opens Toolbar dialog)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Registriert alle DF95-Skripte in der Action List und öffnet das Toolbar-Fenster zum Import.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep

local list = {
  "DF95_Explode_AutoBus.lua",
  "DF95_MicFX_Manager.lua",
  "DF95_FXBus_Selector.lua",
  "DF95_FXBus_Seed.lua",
  "DF95_Menu_FXBus_Dropdown.lua",
  "DF95_Menu_Coloring_Dropdown.lua",
  "DF95_Menu_Master_Dropdown.lua",
  "DF95_Menu_Artist_Dropdown.lua",
  "DF95_Menu_Generative_Dropdown.lua",
  "DF95_Menu_Parallel_Dropdown.lua",
  "DF95_Menu_SafetyQA_Dropdown.lua",
  "DF95_GainMatch_AB.lua",
  "DF95_Slice_Menu.lua",
  "DF95_Rearrange_Align.lua",
  "DF95_LoopBuilder.lua",
  "DF95_FirstRun_LiveCheck.lua",
  "DF95_Safety_Loudness_Menu.lua",
  "DF95_Console7_Toggle.lua",
  "DF95_Validator_2_3.lua"
}

local function register(path)
  if not reaper.file_exists(path) then return false end
  reaper.AddRemoveReaScript(true, 0, path, true) -- section 0 = Main
  return true
end

local ok, miss = 0, {}
for _,fname in ipairs(list) do
  local p = base .. fname
  if register(p) then ok = ok + 1 else miss[#miss+1] = fname end
end

reaper.Main_OnCommand(40016,0) -- Options: Customize menus/toolbars
reaper.ShowMessageBox(
  ("DF95 Auto-Register: %d Scripts registriert.\nFehlend: %s\n\nBitte jetzt im Toolbar-Dialog importieren:\nMenus/DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet")
  :format(ok, table.concat(miss, ", ")),
  "DF95 Auto-Register", 0)