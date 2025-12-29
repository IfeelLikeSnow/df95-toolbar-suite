
-- DF95_Installer_Helper.lua
-- DF95 Installer / Status GUI (ImGui + Popup-Fallback)

local r = reaper

local function join(a, b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then
    return a .. b
  end
  return a .. "/" .. b
end

local function exists_dir(path)
  local f = r.EnumerateFiles(path, 0)
  return f ~= nil
end

local function exists_file(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function msgbox(txt)
  r.ShowMessageBox(txt, "DF95 Installer Helper", 0)
end

local RESOURCE = r.GetResourcePath()
local DF_ROOT  = join(RESOURCE, "Scripts/IFLS/DF95")
local MENUS    = join(RESOURCE, "Menus")
local ICONS    = join(RESOURCE, "Data/toolbar_icons/DF95")
local DOC      = join(RESOURCE, "Documentation")
local CONFIGS  = join(RESOURCE, "Configs")

local function check_all()
  local out = {}
  local function add(status, label, detail)
    out[#out+1] = { status = status, label = label, detail = detail or "" }
  end

  if exists_dir(DF_ROOT) then
    add("OK", "DF95-Root gefunden", DF_ROOT)
  else
    add("ERR", "DF95-Root NICHT gefunden", DF_ROOT .. " (Ordner fehlt)")
  end

  local script_count = 0
  local function scan_scripts(dir)
    local i = 0
    while true do
      local f = r.EnumerateFiles(dir, i)
      if not f then break end
      if f:lower():sub(-4) == ".lua" then
        script_count = script_count + 1
        local full = join(dir, f)
        r.AddRemoveReaScript(true, 0, full, true)
      end
      i = i + 1
    end
    local j = 0
    while true do
      local sub = r.EnumerateSubdirectories(dir, j)
      if not sub then break end
      scan_scripts(join(dir, sub))
      j = j + 1
    end
  end

  if exists_dir(DF_ROOT) then
    scan_scripts(DF_ROOT)
  end

  if script_count > 0 then
    add("OK", "DF95-Skripte registriert", script_count .. " Lua-Skripte")
  else
    add("WARN", "Keine DF95-Skripte gefunden", "Erwarte .lua-Dateien unter " .. DF_ROOT)
  end

  local menu_files = {
    "DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet",
    "DF95_MainToolbar_FlowErgo_Hub.ReaperMenuSet",
    "DF95_Reamp_Toolbar.ReaperMenuSet"
  }
  for _, mf in ipairs(menu_files) do
    local p = join(MENUS, mf)
    if exists_file(p) then
      add("OK", "Toolbar-MenuSet vorhanden", mf)
    else
      add("WARN", "Toolbar-MenuSet fehlt", mf .. " (erwartet unter Menus/)")
    end
  end

  local icon_found = false
  if exists_dir(ICONS) then
    local i = 0
    while true do
      local f = r.EnumerateFiles(ICONS, i)
      if not f then break end
      if f:lower():sub(-4) == ".png" then
        icon_found = true
        break
      end
      i = i + 1
    end
  end
  if icon_found then
    add("OK", "DF95-Icons gefunden", ICONS)
  else
    add("WARN", "Keine DF95-Icons gefunden", ICONS)
  end

  local docs_to_check = {
    "DF95_Manual_DE.pdf",
    "DF95_CheatSheet_Flow.pdf",
    "DF95_IconSheet_Labeled.png",
    "DF95_Toolbar_Icon_Mapping.md",
    "DF95_Toolbar_VisualSetup.md",
    "DF95_VideoScript_DE.md",
    "DF95_Installer.md"
  }
  for _, df in ipairs(docs_to_check) do
    local p = join(DOC, df)
    if exists_file(p) then
      add("OK", "Dokument: " .. df, "")
    else
      add("WARN", "Dokument fehlt: " .. df, "Erwartet unter Documentation/")
    end
  end

  if exists_dir(CONFIGS) then
    local i = 0
    local found_cfg = false
    while true do
      local f = r.EnumerateFiles(CONFIGS, i)
      if not f then break end
      if f:lower():match("%.reaperconfigzip$") then
        found_cfg = true
        add("OK", "ConfigZip gefunden", "Configs/" .. f)
      end
      i = i + 1
    end
    if not found_cfg then
      add("INFO", "Keine DF95-ConfigZip gefunden", "Optional; du kannst später eine eigene exportieren.")
    end
  else
    add("INFO", "Configs-Ordner nicht gefunden", "Optional: Configs/DF95_*.ReaperConfigZip")
  end



  -- Spezielle Checks für SuperToolbar + BEAT / RHYTHM + HealthCheck
  local super_menu = "DF95_SuperToolbar_Main.ReaperMenuSet"
  local beat_menu  = "DF95_SuperToolbar_BEAT_Sub.ReaperMenuSet"

  do
    local p_super = join(MENUS, super_menu)
    if exists_file(p_super) then
      add("OK", "SuperToolbar Main gefunden", super_menu)
    else
      add("WARN", "SuperToolbar Main fehlt", super_menu .. " (erwartet unter Menus/)")
    end

    local p_beat = join(MENUS, beat_menu)
    if exists_file(p_beat) then
      add("OK", "BEAT / RHYTHM SubToolbar gefunden", beat_menu)
    else
      add("WARN", "BEAT / RHYTHM SubToolbar fehlt", beat_menu .. " (erwartet unter Menus/)")
    end
  end

  do
    local beat_scripts = {
      "DF95_Beat_ControlCenter_ImGui.lua",
      "DF95_Sampler_SitalaKitBuilder_v1.lua",
      "DF95_Global_BeatPresetLoader_ImGui.lua",
      "DF95_Script_HealthCheck.lua",
      "DF95_Script_HealthCheck_ImGui.lua",
      "DF95_Script_HealthCheck_AutoReport.lua",
    }
    local missing = {}
    for _, bf in ipairs(beat_scripts) do
      local p = join(DF_ROOT, bf)
      if not exists_file(p) then
        missing[#missing+1] = bf
      end
    end
    if #missing == 0 then
      add("OK", "BEAT / SuperToolbar Kernskripte vorhanden", "BeatEngine / Sitala / GlobalPresets / HealthCheck")
    else
      add("WARN", "BEAT / SuperToolbar Skripte unvollständig", "Fehlt: " .. table.concat(missing, ", "))
    end
  end


  return out
end

local results = check_all()
local has_imgui = (reaper.ImGui_CreateContext ~= nil)

if not has_imgui then
  local lines = {}
  lines[#lines+1] = "DF95 Installer Helper – Zusammenfassung\\n\\n"
  lines[#lines+1] = "ResourcePath: " .. RESOURCE .. "\\n"
  lines[#lines+1] = "DF95-Root: " .. DF_ROOT .. "\\n\\n"
  for _, it in ipairs(results) do
    lines[#lines+1] = string.format("[%s] %s", it.status, it.label)
    if it.detail and it.detail ~= "" then
      lines[#lines+1] = "  " .. it.detail
    end
    lines[#lines+1] = "\\n"
  end
  lines[#lines+1] = "\\nNächste Schritte siehe: Documentation/DF95_Installer.md\\n"
  msgbox(table.concat(lines))
  return
end

local ctx = reaper.ImGui_CreateContext('DF95 Installer Helper')

local function color_for_status(status)
  if status == "OK" then
    return 0.25, 0.7, 0.25, 1.0
  elseif status == "WARN" then
    return 0.9, 0.7, 0.2, 1.0
  elseif status == "ERR" then
    return 0.9, 0.2, 0.2, 1.0
  else
    return 0.7, 0.7, 0.7, 1.0
  end
end

local function open_resource_path()
  r.ShowExplorer(RESOURCE)
end

local function open_custom_toolbars()
  r.Main_OnCommand(40533, 0)
end

local function loop()
  local visible, open = reaper.ImGui_Begin(ctx, 'DF95 Installer Helper', true,
    reaper.ImGui_WindowFlags_AlwaysAutoResize())

  if visible then
    reaper.ImGui_Text(ctx, "DF95 Installer / Status-Übersicht")
    reaper.ImGui_Separator(ctx)

    reaper.ImGui_Text(ctx, "ResourcePath:")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, RESOURCE)

    reaper.ImGui_Text(ctx, "DF95-Root:")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, DF_ROOT)

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Checks:")

    for _, item in ipairs(results) do
      local r_, g, b, a = color_for_status(item.status)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), r_, g, b, a)
      reaper.ImGui_Text(ctx, string.format("[%s] %s", item.status, item.label))
      reaper.ImGui_PopStyleColor(ctx)
      if item.detail and item.detail ~= "" then
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_Text(ctx, " - " .. item.detail)
      end
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Aktionen:")

    if reaper.ImGui_Button(ctx, "ResourcePath öffnen") then
      open_resource_path()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Customize Toolbars…") then
      open_custom_toolbars()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "DF95 Installer Doku öffnen") then
      local doc_path = join(DOC, "DF95_Installer.md")
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc_path)
      end
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Details siehe: Documentation/DF95_Installer.md")

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)
