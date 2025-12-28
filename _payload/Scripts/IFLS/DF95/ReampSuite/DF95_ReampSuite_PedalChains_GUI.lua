
-- @description DF95_ReampSuite_PedalChains_GUI
-- @version 1.0
-- @author DF95
-- @about
--   GUI zur Auswahl von Pedal-Ketten-Presets:
--   - zeigt alle Presets mit Name, Use-Case, Pedal-Liste
--   - setzt aktives Preset in DF95_REAMP/* ExtStates
--   - optional: Tag für selektierte Tracks ([PC:<Key>] im Namen)

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui nicht installiert – bitte nachrüsten.",
                   "DF95 ReampSuite Pedal Chains", 0)
  return
end

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
end

local function safe_require(path)
  local ok, mod = pcall(dofile, path)
  if not ok then return nil, mod end
  return mod, nil
end

local chains_mod, err = safe_require(df95_root() .. "ReampSuite/DF95_ReampSuite_PedalChains.lua")
if not chains_mod then
  r.ShowMessageBox("DF95_ReampSuite_PedalChains.lua konnte nicht geladen werden:\\n" .. tostring(err or "?"),
                   "DF95 ReampSuite Pedal Chains", 0)
  return
end

local ctx = r.ImGui_CreateContext("DF95 ReampSuite – Pedal Chains")

local keys = {}
for k, _ in pairs(chains_mod.chains) do keys[#keys+1] = k end
table.sort(keys)

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "DF95 ReampSuite – Pedal Chains", true,
    r.ImGui_WindowFlags_AlwaysAutoResize())

  if visible then
    r.ImGui_Text(ctx, "Pedal-Ketten Presets")
    r.ImGui_Separator(ctx)

    local active_key = chains_mod.get_active_key()

    for _, key in ipairs(keys) do
      local ch = chains_mod.chains[key]
      local sel = (key == active_key)

      if sel then
        r.ImGui_Text(ctx, "● " .. (ch.name or key))
      else
        r.ImGui_Text(ctx, "○ " .. (ch.name or key))
      end

      if ch.use_case and ch.use_case ~= "" then
        r.ImGui_Text(ctx, "   Use-Case: " .. ch.use_case)
      end

      if ch.pedals and #ch.pedals > 0 then
        r.ImGui_Text(ctx, "   Pedals:")
        for _, p in ipairs(ch.pedals) do
          r.ImGui_Text(ctx, "     - " .. p)
        end
      end

      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, "Aktivieren##" .. key) then
        chains_mod.set_active_key(key)
        active_key = key
      end

      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, "Tag auf selektierte Tracks##" .. key) then
        chains_mod.set_active_key(key)
        chains_mod.apply_to_selected_tracks()
        active_key = key
      end

      r.ImGui_Separator(ctx)
    end

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)
