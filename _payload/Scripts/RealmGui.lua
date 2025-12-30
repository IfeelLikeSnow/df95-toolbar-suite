(
echo -- Root shim: RealmGui.lua  (adapter for ReaImGui)
echo -- Returns a table with ImGui_* functions (ReaImGui uses reaper.ImGui_* API)
echo if not reaper or not reaper.ImGui_CreateContext then
echo   return nil
echo end
echo return reaper
) > RealmGui.lua
