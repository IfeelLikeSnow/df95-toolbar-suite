-- @description SmartFlow Installer v1.56a (Hybrid + Backup + Validator 2.5 hook + Seed + SmartCeiling)
-- @version 1.56a
-- @author IfeelLikeSnow
-- @about Erkennt DF95-Status und wählt automatisch Auto-Register (non-invasive) ODER Force-Import (mit Backup).
--        Post-Install: Data/DF95 anlegen, CSV optional kopieren, UX-Profile schreiben, SmartCeiling.json schreiben,
--        Seed-Persistenz initialisieren, Validator 2.5 starten.
-- @changelog +Seed-Persistenz (per Project ExtState); +SmartCeiling Profile JSON; +Validator 2.5 Hook

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

-- ============== Helpers ==============
local function read_text(p) local f=io.open(p,"rb"); if not f then return nil end local d=f:read("*all"); f:close(); return d end
local function write_text(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end
local function list_files(dir) local t,i={},0; while true do local fn=r.EnumerateFiles(dir,i); if not fn then break end t[#t+1]=fn; i=i+1 end; return t end
local function ensure_dir(p) return r.RecursiveCreateDirectory(p,0)~=0 end
local function file_exists(p) local f=io.open(p,"rb"); if f then f:close(); return true end return false end
local function copy(src,dst) local d=read_text(src); if not d then return false end return write_text(dst,d) end
local function now_stamp() return os.date("!%Y%m%d_%H%M%S") end
local function msg(title, body) r.ShowMessageBox(body, title, 0) end

-- ============== Detection ==============
local function detect_df95_toolbar()
  local ini = res..sep.."reaper-menu.ini"
  local ini_t = read_text(ini) or ""
  local has_signature = ini_t:match("Custom:%s*DF95%s*[%-%–]%s*Explode") ~= nil
  local menus = res..sep.."Menus"..sep
  local pick = nil
  for _,fn in ipairs(list_files(menus)) do
    if fn:match("^DF95_SuperToolbar_Main%.ReaperMenuSet$") then pick = fn break end
  end
  if not pick then
    for _,fn in ipairs(list_files(menus)) do
      if fn:match("^DF95_MainToolbar") and fn:match("%.ReaperMenuSet$") then pick = fn break end
    end
  end
  return has_signature, pick and (menus..pick) or nil
end

-- ============== Auto-Register Scripts ==============
local function auto_register_scripts()
  local base = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep
  local want = {
    "DF95_Explode_AutoBus.lua","DF95_MicFX_Manager.lua",
    "DF95_FXBus_Selector.lua","DF95_FXBus_Seed.lua",
    "DF95_Menu_FXBus_Dropdown.lua","DF95_Menu_Coloring_Dropdown.lua","DF95_Menu_Master_Dropdown.lua",
    "DF95_Menu_Artist_Dropdown.lua","DF95_Menu_Generative_Dropdown.lua","DF95_Menu_Parallel_Dropdown.lua","DF95_Menu_SafetyQA_Dropdown.lua",
    "DF95_GainMatch_AB.lua",
    "DF95_Slice_Menu.lua","DF95_Rearrange_Align.lua","DF95_LoopBuilder.lua",
    "DF95_FirstRun_LiveCheck.lua","DF95_Safety_Loudness_Menu.lua","DF95_Console7_Toggle.lua",
    "DF95_Validator_2_5.lua" -- upgraded
  }
  local ok,miss=0,{}
  for _,fname in ipairs(want) do
    local p = base..fname
    if file_exists(p) then r.AddRemoveReaScript(true, 0, p, true); ok=ok+1 else miss[#miss+1]=fname end
  end
  return ok, miss
end

-- ============== Force-Import Toolbar (with Backup) ==============
local function force_import_toolbar(toolbar_path)
  local ini = res..sep.."reaper-menu.ini"
  local ini_t = read_text(ini)
  if not ini_t then return false, "reaper-menu.ini nicht gefunden" end
  local tb_t = read_text(toolbar_path)
  if not tb_t then return false, "Toolbar-Datei unlesbar: "..toolbar_path end

  local bak = ini..".DF95_backup_"..now_stamp()
  write_text(bak, ini_t)

  local function norm(s) return (s:gsub("\r\n","\n")) end
  ini_t = norm(ini_t); tb_t = norm(tb_t)

  local payload = {}
  for line in tb_t:gmatch("([^\n]+)") do
    if line:match("^Item%d+%s*=") or line:match("^%s*SCRIPT:") or line:match("^%s*$") then payload[#payload+1]=line end
  end
  if #payload==0 then for line in tb_t:gmatch("([^\n]+)") do payload[#payload+1]=line end end

  local out, in_section = {}, false
  for line in ini_t:gmatch("([^\n]*)\n?") do
    local sec = line:match("^%[(.-)%]")
    if sec then if in_section then in_section=false end table.insert(out,line) else if not in_section then table.insert(out,line) end end
    if line:match("^%[Main toolbar%]") then in_section=true; table.insert(out, table.concat(payload, "\n")) end
  end

  local ok = write_text(ini, table.concat(out,"\n"))
  return ok, ok and bak or "Schreiben fehlgeschlagen"
end

-- ============== Post-Install (Folders + CSV + Validator + UX + Seed + SmartCeiling) ==============
local function post_install_and_validate()
  local d_data = res..sep.."Data"..sep.."DF95"
  local d_chains = d_data..sep.."Chains"
  ensure_dir(d_data); ensure_dir(d_chains)

  -- optional CSVs from Scripts/IFLS/DF95/Data
  local base = res..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep
  local cand = {
    base.."Data"..sep.."DF95_FXChains_Catalog_Reclassified_SoftPass.csv",
    base.."Data"..sep.."DF95_FXChains_Catalog_Reclassified_Strict.csv",
    base.."Data"..sep.."DF95_FXChains_Catalog.csv"
  }
  for _,p in ipairs(cand) do if file_exists(p) then copy(p, d_data..sep..(p:match("([^"..sep.."]+)$") or "catalog.csv")) end end

  -- UX profile (theme-aware)
  local theme = (r.GetLastColorThemeFile and r.GetLastColorThemeFile() or ""):lower()
  local profile = { spacer="auto", icon_variant="mono", density="normal" }
  if theme:find("hydra") then profile.spacer="wide"; profile.icon_variant="light" end
  if theme:find("commala") then profile.spacer="narrow" end
  if theme:find("imperial") or theme:find("lcs") then profile.spacer="wide" end
  local ux_json = string.format('{"theme":"%s","spacer":"%s","icon_variant":"%s","density":"%s"}',
    theme, profile.spacer, profile.icon_variant, profile.density)
  write_text(base.."DF95_UX_Profile.json", ux_json)

  -- SmartCeiling profile JSON
  local ceiling_json = [[{
    "Default": -0.1,
    "Neutral": -0.1,
    "Artist": -0.5,
    "Coloring": -0.3,
    "FX Bus": -1.0,
    "Generative": -1.0,
    "Parallel": -1.0,
    "Safety/QA": -0.1,
    "Master": -0.1
  }]]
  write_text(d_data..sep.."SmartCeiling.json", ceiling_json)

  -- Seed Persistenz: initialisiere, wenn leer
  local proj = 0
  local retval, seed = r.GetProjExtState(proj, "DF95", "SEED")
  if retval == 0 or seed == "" then
    local new_seed = tostring(math.floor(os.clock()*1000000)%1000000)
    r.SetProjExtState(proj, "DF95", "SEED", new_seed)
  end

  -- run validator 2.5 if present, else 2.3
  local v25 = base.."DF95_Validator_2_5.lua"
  local v23 = base.."DF95_Validator_2_3.lua"
  r.Main_OnCommand(40297,0) -- show console
  if file_exists(v25) then dofile(v25) elseif file_exists(v23) then dofile(v23) end
end

-- ============== Main Flow ==============
r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local has_df95, toolbar_path = detect_df95_toolbar()
local reg_ok, reg_miss = auto_register_scripts()

if has_df95 then
  post_install_and_validate()
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 SmartFlow Installer v1.56a (Auto-Register)", -1)
  msg("DF95 SmartFlow",
    ("Modus: Auto-Register\nRegistriert: %d (Fehlend: %s)\nToolbar erkannt → kein Force-Import.\nPost-Install + Validator ausgeführt.\n\nOptions → Customize menus/toolbars → Apply, falls Toolbar noch nicht sichtbar.")
    :format(reg_ok, table.concat(reg_miss, ", ")))
else
  if not toolbar_path then
    local menus = res..sep.."Menus"..sep
    for _,fn in ipairs(list_files(menus)) do
      if fn:match("^DF95_SuperToolbar_Main%.ReaperMenuSet$") then toolbar_path = menus..fn; break end
    end
    if not toolbar_path then
      for _,fn in ipairs(list_files(menus)) do
        if fn:match("^DF95_MainToolbar") and fn:match("%.ReaperMenuSet$") then toolbar_path = menus..fn; break end
      end
    end
  end
  if not toolbar_path then
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock("DF95 SmartFlow Installer v1.56a (Fallback)", -1)
    r.Main_OnCommand(40016,0)
    msg("DF95 SmartFlow","Keine DF95-Toolbar-Datei unter Menus gefunden.\nBitte im Toolbar-Dialog manuell importieren.")
    return
  end
  local ok, bak_or_err = force_import_toolbar(toolbar_path)
  post_install_and_validate()
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("DF95 SmartFlow Installer v1.56a (Force-Import)", -1)
  if ok then
    msg("DF95 SmartFlow",
      ("Modus: Force-Import\nRegistriert: %d (Fehlend: %s)\nMain Toolbar ersetzt durch:\n%s\nBackup:\n%s\n\nBitte Toolbars neu laden (Options → Customize menus/toolbars → OK) oder REAPER neu starten.")
      :format(reg_ok, table.concat(reg_miss,", "), toolbar_path, bak_or_err))
  else
    r.Main_OnCommand(40016,0)
    msg("DF95 SmartFlow", "Force-Import fehlgeschlagen: "..tostring(bak_or_err).."\nBitte manuell importieren.")
  end
end
