-- DF95_Autopilot_Pipeline_Visualizer_ImGui.lua
-- Visualisiert die aktuelle/letzte Autopilot-Pipeline:
--   Artist -> Dynamic Preset -> Slice Length -> Rearrange -> Humanize -> DrumSetup
-- Liest:
--   * ProjExtStates (DF95_SLICING, DF95_DYN, DF95_AUTOPILOT)
--   * Logfiles: Data/DF95/Logs/DF95_Autopilot.log, DF95_DynamicSlicing.log

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui-Extension nicht gefunden.\nBitte ReaImGui installieren.", "DF95 Autopilot Pipeline Visualizer", 0)
  return
end

local ctx = r.ImGui_CreateContext('DF95 Autopilot Pipeline Visualizer')
local FONT = r.ImGui_CreateFont('sans-serif', 17)
r.ImGui_AttachFont(ctx, FONT)

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function logs_dir()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Data" .. sep .. "DF95" .. sep .. "Logs" .. sep):gsub("\\","/")
end

local function read_tail(path, max_lines)
  local f = io.open(path, "rb")
  if not f then return {} end
  local data = f:read("*all")
  f:close()
  if not data then return {} end
  local lines = {}
  for line in data:gmatch("[^\r\n]+") do
    lines[#lines+1] = line
  end
  local n = #lines
  if n <= max_lines then return lines end
  local out = {}
  for i = n-max_lines+1, n do
    out[#out+1] = lines[i]
  end
  return out
end

local function get_proj_state_snapshot()
  local snap = {}
  local ret, art = r.GetProjExtState(0, "DF95_SLICING", "ARTIST")
  snap.artist = art or ""
  ret, art = r.GetProjExtState(0, "DF95_SLICING", "INTENSITY")
  snap.intensity = art or ""
  ret, art = r.GetProjExtState(0, "DF95_DYN", "PRESET")
  snap.dynamic_preset = art or ""
  ret, art = r.GetProjExtState(0, "DF95_DYN", "LENGTH_MODE")
  snap.length_mode = art or ""
  ret, art = r.GetProjExtState(0, "DF95_AUTOPILOT", "REARR")
  snap.rearr = art or ""
  ret, art = r.GetProjExtState(0, "DF95_AUTOPILOT", "HUM")
  snap.hum = art or ""
  return snap
end

local function bool_from_yes(s)
  s = (s or ""):lower()
  return (s == "yes" or s == "y" or s == "1" or s == "true")
end

local function loop()
  r.ImGui_PushFont(ctx, FONT)

  r.ImGui_SetNextWindowSize(ctx, 780, 620, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, 'DF95 Autopilot Pipeline Visualizer', true)

  if visible then
    local snap = get_proj_state_snapshot()

    r.ImGui_Text(ctx, "Autopilot Pipeline Snapshot (ProjExtState):")
    r.ImGui_BulletText(ctx, "Artist: " .. (snap.artist ~= "" and snap.artist or "<none>"))
    r.ImGui_BulletText(ctx, "Intensity: " .. (snap.intensity ~= "" and snap.intensity or "<auto/default>"))
    r.ImGui_BulletText(ctx, "Dynamic Preset: " .. (snap.dynamic_preset ~= "" and snap.dynamic_preset or "<auto>"))
    r.ImGui_BulletText(ctx, "Slice Length Mode: " .. (snap.length_mode ~= "" and snap.length_mode or "<medium>"))
    r.ImGui_BulletText(ctx, "Rearrange after slicing: " .. tostring(bool_from_yes(snap.rearr)))
    r.ImGui_BulletText(ctx, "Apply Humanize: " .. tostring(bool_from_yes(snap.hum)))

    r.ImGui_Separator(ctx)

    --------------------------------------------------------
    -- Pipeline visualization as steps
    --------------------------------------------------------
    r.ImGui_Text(ctx, "Pipeline Diagram:")

    local function step(label, active)
      if active then
        r.ImGui_BulletText(ctx, "[ON]  " .. label)
      else
        r.ImGui_BulletText(ctx, "[OFF] " .. label)
      end
    end

    local has_artist = (snap.artist or "") ~= ""
    local has_preset = (snap.dynamic_preset or "") ~= ""
    local length_mode = snap.length_mode ~= "" and snap.length_mode or "medium"
    local do_rearr = bool_from_yes(snap.rearr)
    local do_hum = bool_from_yes(snap.hum)

    step("Artist selected", has_artist)
    step("Dynamic Preset selected", has_preset)
    r.ImGui_BulletText(ctx, "Slice Length Mode: " .. length_mode)

    step("Dynamic Slice (DF95_Dynamic_Slicer.lua)", true)
    step("Rearrange (DF95_Rearrange_Align.lua)", do_rearr)
    step("Humanize (DF95_Humanize_Preset_Apply.lua)", do_hum)
    step("DrumSetup (DF95_IDM_DrumSetup.lua)", true)

    r.ImGui_Separator(ctx)

    --------------------------------------------------------
    -- Last log entries (Autopilot + DynamicSlicing)
    --------------------------------------------------------
    r.ImGui_Text(ctx, "Log-Auszüge (letzte Durchläufe):")

    local logdir = logs_dir()
    local auto_log = logdir .. "DF95_Autopilot.log"
    local dyn_log  = logdir .. "DF95_DynamicSlicing.log"

    r.ImGui_Text(ctx, "Autopilot Log (letzte Zeilen):")
    local auto_lines = read_tail(auto_log, 10)
    if #auto_lines == 0 then
      r.ImGui_Text(ctx, "(Keine Einträge gefunden.)")
    else
      r.ImGui_BeginChild(ctx, "auto_log", 740, 150, true)
      for _, line in ipairs(auto_lines) do
        r.ImGui_Text(ctx, line)
      end
      r.ImGui_EndChild(ctx)
    end

    r.ImGui_Separator(ctx)

    r.ImGui_Text(ctx, "Dynamic Slicing Log (letzte Zeilen):")
    local dyn_lines = read_tail(dyn_log, 10)
    if #dyn_lines == 0 then
      r.ImGui_Text(ctx, "(Keine Einträge gefunden.)")
    else
      r.ImGui_BeginChild(ctx, "dyn_log", 740, 150, true)
      for _, line in ipairs(dyn_lines) do
        r.ImGui_Text(ctx, line)
      end
      r.ImGui_EndChild(ctx)
    end

    r.ImGui_End(ctx)
  end

  r.ImGui_PopFont(ctx)

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
