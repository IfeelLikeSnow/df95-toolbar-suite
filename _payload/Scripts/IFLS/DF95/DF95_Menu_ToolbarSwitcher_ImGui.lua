-- @description Toolbar Switcher (ImGui Dropdown, Kategorien, Status)
-- @version 1.2
-- @author DF95
-- @changelog
--   + Alle DF95-Toolbars einzeln anwählbar
--   + Kategorien (zweite Ebene) im Dropdown
--   + Status-Anzeige (on/off) pro Toolbar via GetToggleCommandStateEx
--   + Optionaler Name-Import aus .ReaperMenuSet (auto-detect Display-Namen)

local r = reaper

-- ############################################################
-- ImGui Context
-- ############################################################

local ctx = r.ImGui_CreateContext("DF95 Toolbar Switcher", 0)

-- ############################################################
-- CONFIG: DF95-Toolbars und ihr Mapping auf Reaper-Slots
-- ############################################################
--
-- WICHTIG:
--  Die cmd-Werte sind Reaper-Builtin-Actions:
--    41651 = Toolbar: Open/close main toolbar
--    41679 = Toolbar: Open/close toolbar 1
--    41680 = Toolbar: Open/close toolbar 2
--    ...
--    41686 = Toolbar: Open/close toolbar 8
--
--  Du musst in Reaper unter:
--    Options -> Customize menus/toolbars...
--  die jeweiligen DF95_*.ReaperMenuSet-Files in diese Toolbar-Slots importieren.

local sep = package.config:sub(1,1)
local resource_path = r.GetResourcePath()

local toolbars = {
  {
    name      = "DF95 Hub (Main Toolbar)",
    category  = "Core / Hub",
    cmd       = 41651,
    menuset   = "Menus" .. sep .. "DF95_MainToolbar_FlowErgo_Hub.ReaperMenuSet",
  },

  {
    name      = "DF95 Export Desk (Toolbar 1)",
    category  = "Export",
    cmd       = 41679,
    menuset   = "Menus" .. sep .. "DF95_ExportDesk_MainToolbar.ReaperMenuSet",
  },
  {
    name      = "DF95 Main FlowErgo (Toolbar 2)",
    category  = "Main",
    cmd       = 41680,
    menuset   = "Menus" .. sep .. "DF95_MainToolbar_FlowErgo.ReaperMenuSet",
  },
  {
    name      = "DF95 Main FlowErgo Pro (Toolbar 3)",
    category  = "Main",
    cmd       = 41681,
    menuset   = "Menus" .. sep .. "DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet",
  },

  {
    name      = "DF95 Edit / Arrange (Toolbar 4)",
    category  = "Edit",
    cmd       = 41682,
    menuset   = "Menus" .. sep .. "DF95_EditToolbar_Arrange.ReaperMenuSet",
  },
  {
    name      = "DF95 Mic / Input (Toolbar 5)",
    category  = "Input",
    cmd       = 41683,
    menuset   = "Menus" .. sep .. "DF95_MicToolbar_Input.ReaperMenuSet",
  },
  {
    name      = "DF95 QA & Safety (Toolbar 6)",
    category  = "QA / Safety",
    cmd       = 41684,
    menuset   = "Menus" .. sep .. "DF95_QA_Toolbar_Safety.ReaperMenuSet",
  },
  {
    name      = "DF95 Bias & Tools (Toolbar 7)",
    category  = "Bias / Tools",
    cmd       = 41685,
    menuset   = "Menus" .. sep .. "DF95_Toolbar_BiasTools.ReaperMenuSet",
  },
  {
    name      = "DF95 FXBus & Audition (Toolbar 8)",
    category  = "FX / Audition",
    cmd       = 41686,
    menuset   = "Menus" .. sep .. "DF95_Toolbar_ColorMaster_Audition_SWS.ReaperMenuSet",
  },
  {
    name      = "DF95 SuperPipeline (Toolbar 9)",
    category  = "Core / Hub",
    cmd       = 41687,
    menuset   = "Menus" .. sep .. "DF95_SuperPipeline_Toolbar.ReaperMenuSet",
  },
  {
    name      = "DF95 ReampSuite (Toolbar 10)",
    category  = "Reamp / HW",
    cmd       = 41688,
    menuset   = "Menus" .. sep .. "DF95_ReampSuite_Toolbar.ReaperMenuSet",
  },

}

-- ############################################################
-- Hilfsfunktionen: Menuset-Namen auto-detecten, Toggle-Status, etc.
-- ############################################################

local function read_first_custom_label_from_menuset(relpath)
  if not relpath or relpath == "" then return nil end
  local full = resource_path .. sep .. relpath
  local f = io.open(full, "r")
  if not f then return nil end

  local label
  for line in f:lines() do
    local l = line:match("^Item%d+=Custom:%s*(.+)$")
    if l and l ~= "" then
      label = l
      break
    end
  end
  f:close()
  return label
end

local function enrich_toolbar_metadata()
  for _, tb in ipairs(toolbars) do
    tb.display_name = tb.name or "?"
    if tb.menuset and tb.menuset ~= "" then
      local label = read_first_custom_label_from_menuset(tb.menuset)
      if label and label ~= "" then
        tb.display_name = string.format("%s [%s]", tb.name, label)
      end
    end
  end
end

local function resolve_command_id(cmd)
  if type(cmd) == "number" then
    return cmd
  elseif type(cmd) == "string" and cmd ~= "" then
    local id = r.NamedCommandLookup(cmd)
    if id ~= 0 then return id end
  end
  return nil
end

local function call_command(cmd)
  local id = resolve_command_id(cmd)
  if not id or id <= 0 then return end
  r.Main_OnCommand(id, 0)
end

local function get_toolbar_state(tb)
  local id = resolve_command_id(tb.cmd)
  if not id then return nil end
  local st = r.GetToggleCommandStateEx(0, id)
  if st < 0 then return nil end
  return st
end

-- ############################################################
-- Kategorien aus den Toolbars generieren
-- ############################################################

local categories = { "Alle" }
local category_index_by_name = { Alle = 1 }

local function build_categories()
  for _, tb in ipairs(toolbars) do
    local cat = tb.category or "Sonstiges"
    if not category_index_by_name[cat] then
      table.insert(categories, cat)
      category_index_by_name[cat] = #categories
    end
  end
end

enrich_toolbar_metadata()
build_categories()

local current_cat_idx = 1
local current_tb_idx  = 1

-- ############################################################
-- GUI Loop
-- ############################################################

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 Toolbar Switcher", true)

  if visible then
    local current_cat_name = categories[current_cat_idx] or "Alle"
    if r.ImGui_BeginCombo(ctx, "Kategorie", current_cat_name) then
      for i, cat in ipairs(categories) do
        local selected = (i == current_cat_idx)
        if r.ImGui_Selectable(ctx, cat, selected) then
          current_cat_idx = i
        end
        if selected then
          r.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      r.ImGui_EndCombo(ctx)
    end

    local filtered_indices = {}
    for i, tb in ipairs(toolbars) do
      if current_cat_idx == 1 or (tb.category == categories[current_cat_idx]) then
        table.insert(filtered_indices, i)
      end
    end

    if #filtered_indices == 0 then
      r.ImGui_Text(ctx, "Keine Toolbars für diese Kategorie gefunden.")
    else
      local effective_idx = 1
      local found = false
      for j, real_idx in ipairs(filtered_indices) do
        if real_idx == current_tb_idx then
          effective_idx = j
          found = true
          break
        end
      end
      if not found then
        current_tb_idx = filtered_indices[1]
        effective_idx = 1
      end

      local current_tb = toolbars[current_tb_idx]
      local current_name = current_tb.display_name or current_tb.name or "?"

      if r.ImGui_BeginCombo(ctx, "Toolbar auswählen", current_name) then
        for _, real_idx in ipairs(filtered_indices) do
          local tb = toolbars[real_idx]
          local selected = (real_idx == current_tb_idx)
          if r.ImGui_Selectable(ctx, tb.display_name or tb.name or "?", selected) then
            current_tb_idx = real_idx
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end
    end

    r.ImGui_Separator(ctx)

    if r.ImGui_Button(ctx, "Toggle ausgewählte Toolbar", -1, 0) then
      local tb = toolbars[current_tb_idx]
      if tb then
        call_command(tb.cmd)
      end
    end

    if r.ImGui_Button(ctx, "Alle DF95-Toolbars togglen", -1, 0) then
      for _, tb in ipairs(toolbars) do
        call_command(tb.cmd)
      end
    end

    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Status aller DF95-Toolbars:")
    for _, tb in ipairs(toolbars) do
      local st = get_toolbar_state(tb)
      local status_str
      if st == nil then
        status_str = "(kein Toggle-Status)"
      elseif st > 0 then
        status_str = "[ON]"
      else
        status_str = "[OFF]"
      end
      r.ImGui_Bullet(ctx)
      r.ImGui_SameLine(ctx)
      r.ImGui_Text(ctx, string.format("%s  %s", tb.display_name or tb.name or "?", status_str))
    end

    r.ImGui_Separator(ctx)

    if r.ImGui_Button(ctx, "Switcher-Fenster schließen", -1, 0) then
      open = false
    end

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
