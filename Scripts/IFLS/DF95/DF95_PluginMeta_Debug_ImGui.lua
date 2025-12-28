-- DF95_PluginMeta_Debug_ImGui.lua
-- Small ImGui browser for DF95_PluginMetaDomain

local r = reaper
local ok, meta = pcall(dofile, r.GetResourcePath() .. "/Scripts/IFLS/DF95/DF95_PluginMetaDomain.lua")
if not ok or not meta then
  r.ShowMessageBox("DF95_PluginMetaDomain.lua not found or failed to load","DF95 PluginMeta Debug",0)
  return
end

local fx_by_group = {}

for name, m in meta.iter() do
  local g = m.idm_group or "IDM_MISC"
  fx_by_group[g] = fx_by_group[g] or {}
  table.insert(fx_by_group[g], name)
end

for g, list in pairs(fx_by_group) do
  table.sort(list)
end

local ctx = r.ImGui_CreateContext("DF95 PluginMeta Browser")
local size_x, size_y = 640, 480

local function loop()
  if not r.ImGui_Begin(ctx, "DF95 PluginMeta Browser", true) then
    r.ImGui_End(ctx)
    return
  end

  r.ImGui_Text(ctx, "DF95 Plugin Meta (100 random FX, categorized)")
  r.ImGui_Separator(ctx)

  for g, list in pairs(fx_by_group) do
    if r.ImGui_TreeNode(ctx, g) then
      for _, name in ipairs(list) do
        r.ImGui_BulletText(ctx, name)
      end
      r.ImGui_TreePop(ctx)
    end
  end

  r.ImGui_End(ctx)
  if r.ImGui_IsWindowAppearing(ctx) then end
  if r.ImGui_IsWindowCollapsed(ctx) then end

  if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
    return
  end
  r.defer(loop)
end

r.ImGui_SetNextWindowSize(ctx, size_x, size_y, r.ImGui_Cond_FirstUseEver())
loop()
