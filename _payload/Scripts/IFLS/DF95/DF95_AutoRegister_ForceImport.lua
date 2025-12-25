-- @description Auto-Register + Force-Import Main Toolbar (with Backup)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Registriert alle DF95-Skripte und ersetzt die Main Toolbar mit der DF95-Toolbar (.ReaperMenuSet).
--         Sichert vorher reaper-menu.ini als Backup. Fällt bei Fehlern auf den normalen Dialog zurück.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

-- ---------- helpers ----------
local function read_text(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end
local function write_text(p, s)
  local f = io.open(p, "wb"); if not f then return false end
  f:write(s or ""); f:close(); return true
end
local function list_dir(dir)
  local t = {}
  local i = 0
  while true do
    local fn = reaper.EnumerateFiles(dir, i)
    if not fn then break end
    t[#t+1] = fn
    i = i + 1
  end
  return t
end

-- ---------- 1) Auto-register DF95 scripts ----------
local base = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep
local register_list = {
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

local ok, miss = 0, {}
for _,fname in ipairs(register_list) do
  local p = base .. fname
  if reaper.file_exists(p) then
    reaper.AddRemoveReaScript(true, 0, p, true) -- main section
    ok = ok + 1
  else
    miss[#miss+1] = fname
  end
end

-- ---------- 2) Pick DF95 toolbar file from Menus ----------
local menus_dir = res .. sep .. "Menus" .. sep
local files = list_dir(menus_dir)
local pick = nil
for _,fn in ipairs(files) do
  if fn:match("^DF95_MainToolbar") and fn:match("%.ReaperMenuSet$") then
    pick = fn -- last match wins; we prefer any DF95_ file present
  end
end

if not pick then
  reaper.Main_OnCommand(40016,0) -- open Customize menus/toolbars
  reaper.ShowMessageBox(
    ("DF95 Auto-ForceImport: Keine Toolbar-Datei unter Menus gefunden.\n" ..
     "Registriert: %d, Fehlend: %s\nBitte im Dialog manuell importieren." )
      :format(ok, table.concat(miss, ", ")),
    "DF95 Auto-ForceImport", 0)
  return
end

local toolbar_path = menus_dir .. pick
local toolbar_text = read_text(toolbar_path)
if not toolbar_text then
  reaper.Main_OnCommand(40016,0)
  reaper.ShowMessageBox("DF95 Auto-ForceImport: Toolbar-Datei konnte nicht gelesen werden:\n"..toolbar_path,
    "DF95 Auto-ForceImport", 0)
  return
end

-- ---------- 3) Backup + reaper-menu.ini rewrite for [Main toolbar] ----------
local ini = res .. sep .. "reaper-menu.ini"
local ini_text = read_text(ini)
if not ini_text then
  reaper.Main_OnCommand(40016,0)
  reaper.ShowMessageBox("DF95 Auto-ForceImport: reaper-menu.ini nicht gefunden.\nFalle zurück auf manuellen Import.",
    "DF95 Auto-ForceImport", 0)
  return
end

-- backup
local ts = os.date("!%Y%m%d_%H%M%S")
local bak = ini .. ".DF95_backup_"..ts
write_text(bak, ini_text)

-- normalize line endings
local function norm(s) return (s:gsub("\r\n", "\n")) end
ini_text = norm(ini_text); toolbar_text = norm(toolbar_text)

-- extract payload lines from .ReaperMenuSet (strip possible header)
local payload = {}
for line in toolbar_text:gmatch("([^\n]+)") do
  if line:match("^Item%d+%s*=") or line:match("^%s*SCRIPT:") or line:match("^%s*$") then
    payload[#payload+1] = line
  end
end
if #payload == 0 then
  for line in toolbar_text:gmatch("([^\n]+)") do payload[#payload+1] = line end
end

-- rewrite [Main toolbar] section
local out = {}
local in_section = false
for line in ini_text:gmatch("([^\n]*)\n?") do
  local sec = line:match("^%[(.-)%]")
  if sec then
    if in_section then
      in_section = false
    end
    table.insert(out, line)
  else
    if not in_section then
      table.insert(out, line)
    end
  end
  if line:match("^%[Main toolbar%]") then
    in_section = true
    table.insert(out, table.concat(payload, "\n"))
  end
end

local new_ini = table.concat(out, "\n")
local ok_write = write_text(ini, new_ini)

-- ---------- 4) Prompt user to reload toolbars ----------
if ok_write then
  reaper.ShowMessageBox(
    ("DF95 Auto-ForceImport: Erfolgreich.\n" ..
     "• %d Scripts registriert (Fehlend: %s)\n" ..
     "• Main Toolbar ersetzt mit '%s'\n" ..
     "• Backup: %s\n\n" ..
     "Bitte Menü/Toolbars neu laden:\nOptions → Customize menus/toolbars (OK klicken) oder REAPER neu starten.")
      :format(ok, table.concat(miss, ", "), pick, bak),
    "DF95 Auto-ForceImport", 0)
else
  reaper.Main_OnCommand(40016,0)
  reaper.ShowMessageBox("DF95 Auto-ForceImport: Schreiben von reaper-menu.ini fehlgeschlagen.\nFalle zurück auf manuellen Import.",
    "DF95 Auto-ForceImport", 0)
end
