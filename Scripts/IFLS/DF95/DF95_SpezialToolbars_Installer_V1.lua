-- @description Spezial-Toolbars Installer (FX / Sampler / Loop-Warp / Arrangement)
-- @version 1.0
-- @author DF95

local r = reaper

local function ensure_menu_sets_dir()
  local res = r.GetResourcePath()
  local menu_dir = res .. "/MenuSets"
  local ok = r.RecursiveCreateDirectory(menu_dir, 0)
  return menu_dir
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function register_reascript_and_get_cmd_id(script_rel_path)
  local res = r.GetResourcePath()
  local full_path = res .. "/" .. script_rel_path
  if not file_exists(full_path) then
    return nil
  end
  local cmd_id = reaper.AddRemoveReaScript(true, 0, full_path, true)
  return cmd_id
end

local function write_toolbar(menu_path, entries)
  local f = io.open(menu_path, "w")
  if not f then return false end
  f:write("[toolbar]\n")
  for _, e in ipairs(entries) do
    f:write("NAME " .. (e.label or "DF95") .. "\n")
    if e.icon and e.icon ~= "" then
      f:write("ICON " .. e.icon .. "\n")
    end
    f:write("COMMAND " .. (e.cmd_id or "") .. "\n")
  end
  f:close()
  return true
end

local function build_toolbar(menu_dir, filename, scripts)
  local entries = {}
  for _, s in ipairs(scripts) do
    local cmd = register_reascript_and_get_cmd_id(s.rel)
    if cmd then
      table.insert(entries, {
        label = s.label,
        icon  = "",
        cmd_id = cmd
      })
    end
  end
  if #entries == 0 then return false end
  local menu_path = menu_dir .. "/" .. filename
  if not write_toolbar(menu_path, entries) then
    return false
  end
  return true, menu_path
end

local function main()
  local menu_dir = ensure_menu_sets_dir()
  local msgs = {}

  -- FX Toolbar (nur Artist Core + ggf. vorhandene FX-Engines aus Repo)
  local fx_scripts = {
    { rel = "Scripts/IFLS/DF95/DF95_ArtistCore_Manager_V1.lua",           label = "DF95 Artist Core" },
    { rel = "Scripts/IFLS/DF95/DF95_Apply_IDM_Bus_Recommended.lua",       label = "DF95 IDM Bus Setup" }
  }
  local fx_ok, fx_path = build_toolbar(menu_dir, "DF95_FX_Toolbar.ReaperMenu", fx_scripts)
  if fx_ok then
    table.insert(msgs, "FX Toolbar: " .. fx_path)
  else
    table.insert(msgs, "FX Toolbar: keine passenden Scripts gefunden.")
  end

  -- Sampler Toolbar
  local sampler_scripts = {
    { rel = "Scripts/IFLS/DF95/DF95_Sampler_Menu_V2.lua",                 label = "DF95 Sampler Menü V2" },
    { rel = "Scripts/IFLS/DF95/DF95_DrumNoteMapper_V1.lua",               label = "DF95 Drum Note Mapper" }
  }
  local sam_ok, sam_path = build_toolbar(menu_dir, "DF95_Sampler_Toolbar.ReaperMenu", sampler_scripts)
  if sam_ok then
    table.insert(msgs, "Sampler Toolbar: " .. sam_path)
  else
    table.insert(msgs, "Sampler Toolbar: keine passenden Scripts gefunden.")
  end

  -- Loop/Warp Toolbar
  local loop_scripts = {
    { rel = "Scripts/IFLS/DF95/DF95_CreateLoop_Menu_V2.lua",              label = "DF95 Loop Menü V2" },
    { rel = "Scripts/IFLS/DF95/DF95_ZeroCross_FadeOptimizer.lua",         label = "DF95 ZeroCross FadeOpt" }
  }
  local loop_ok, loop_path = build_toolbar(menu_dir, "DF95_LoopWarp_Toolbar.ReaperMenu", loop_scripts)
  if loop_ok then
    table.insert(msgs, "Loop/Warp Toolbar: " .. loop_path)
  else
    table.insert(msgs, "Loop/Warp Toolbar: keine passenden Scripts gefunden.")
  end

  -- Arrangement Toolbar
  local arr_scripts = {
    { rel = "Scripts/IFLS/DF95/DF95_Rearrange_Menu_V2.lua",               label = "DF95 Rearrange Menü V2" },
    { rel = "Scripts/IFLS/DF95/DF95_Humanize_Menu_V2.lua",                label = "DF95 Humanize Menü V2" }
  }
  local arr_ok, arr_path = build_toolbar(menu_dir, "DF95_Arrangement_Toolbar.ReaperMenu", arr_scripts)
  if arr_ok then
    table.insert(msgs, "Arrangement Toolbar: " .. arr_path)
  else
    table.insert(msgs, "Arrangement Toolbar: keine passenden Scripts gefunden.")
  end

  local msg = "DF95 Spezial-Toolbars Installer:\n\n" .. table.concat(msgs, "\n") ..
              "\n\nImportiere die gewünschten Toolbars in REAPER über:\n" ..
              "  Toolbar Rechtsklick -> Customize... -> Import"

  reaper.ShowMessageBox(msg, "DF95 Spezial-Toolbars Installer", 0)
end

main()
