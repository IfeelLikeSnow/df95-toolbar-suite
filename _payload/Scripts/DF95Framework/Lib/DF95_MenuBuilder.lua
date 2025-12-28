-- DF95_MenuBuilder.lua (V3)
-- Helpers for gfx.showmenu-based menus.
--
-- gfx.showmenu format (summary):
--  - items separated by '|'
--  - '#' prefix disables an item (grayed out)
--  - empty item between pipes acts as separator
--
-- This helper renders a table-based menu and calls item callbacks.

local r = reaper
local M = {}

local function ensure_gfx()
  if not gfx.wnd then
    gfx.init("DF95 Menu", 0, 0, 0, 0, 0)
    gfx.quit()
  end
end

local function build_menu_string(items)
  local parts = {}
  for _, it in ipairs(items) do
    if it.separator then
      table.insert(parts, "")
    else
      local label = tostring(it.label or "")
      if it.disabled then
        label = "#" .. label
      end
      table.insert(parts, label)
    end
  end
  return table.concat(parts, "|")
end

function M.show_menu(title, items)
  ensure_gfx()
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local menu = build_menu_string(items)
  local idx = gfx.showmenu(menu)
  if idx and idx > 0 then
    local it = items[idx]
    if it and not it.disabled and type(it.on_select) == "function" then
      it.on_select()
    elseif it and it.disabled then
      -- soft disabled: no action
    end
  end
end

function M.show_disabled_menu(title, flag_name, reopen_fn, reopen_arg)
  ensure_gfx()
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local msg = "#(disabled by config: " .. tostring(flag_name) .. ")"
  local menu = msg .. "|Open DF95_Config.json hint|Cancel"
  local idx = gfx.showmenu(menu)
  if idx == 2 then
    r.ShowMessageBox(
      "Config liegt hier:\n\n" .. r.GetResourcePath():gsub("\\","/") .. "/Support/DF95_Config.json\n\n" ..
      "Setze dort " .. tostring(flag_name) .. " auf true und starte das Menü erneut.",
      "DF95 Config", 0)
  elseif idx == 1 then
    -- disabled item
  end
end

return M
