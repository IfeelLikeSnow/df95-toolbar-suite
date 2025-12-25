-- @description DF95 AIWorker Material Status (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Kleines Status-Widget für den DF95-AIWorker-Material-Flow.
--   Liest die neueste *_material_conflicts_summary.json aus
--   Support/DF95_AIWorker/Results und zeigt:
--     - Overall-Stats (Results/Matched/Conflicts/ProposedNew)
--     - verwendeten min_conf
--     - optional Filter (from_material, to_material)
--     - Top-Konfliktpaare (old -> new)
--
--   Idee:
--     - Schneller Überblick im Workflow Brain / Library-Tab
--     - Du siehst sofort, ob dein letztes AIWorker-Material-Run
--       "ruhig" ist oder viele Konflikte erzeugt.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox(
    "DF95 AIWorker Material Status benötigt REAPER mit ReaImGui-Unterstützung (REAPER v6.80+).",
    "DF95 AIWorker Material Status",
    0
  )
  return
end

local ctx = r.ImGui_CreateContext("DF95 AIWorker Material Status")
local ig = r.ImGui

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function join_path(a, b)
  local sep = package.config:sub(1,1)
  if a:sub(-1) ~= "/" and a:sub(-1) ~= "\" then
    a = a .. sep
  end
  return a .. b
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_results_dir()
  local root = join_path(get_resource_path(), "Support")
  root = join_path(root, "DF95_AIWorker")
  return join_path(root, "Results")
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function load_json(path)
  local respath = get_resource_path()
  local reader_path = join_path(join_path(respath, "Scripts"), "IfeelLikeSnow")
  reader_path = join_path(reader_path, "DF95")
  reader_path = join_path(reader_path, "DF95_ReadJSON.lua")
  local ok, reader = pcall(dofile, reader_path)
  if not ok or type(reader) ~= "function" then
    return nil, "DF95_ReadJSON.lua konnte nicht geladen werden."
  end
  local ok2, data = pcall(reader, path)
  if not ok2 then
    return nil, "Fehler beim Lesen von JSON: " .. tostring(data)
  end
  return data, nil
end

local function find_latest_summary(results_dir)
  local latest_name = nil

  local i = 0
  while true do
    local fname = r.EnumerateFiles(results_dir, i)
    if not fname then break end
    local lf = fname:lower()
    if lf:match("_material_conflicts_summary%.json$") then
      if not latest_name or fname > latest_name then
        latest_name = fname
      end
    end
    i = i + 1
  end

  if not latest_name then return nil end
  return join_path(results_dir, latest_name)
end

------------------------------------------------------------
-- State
------------------------------------------------------------

local state = {
  results_dir = get_results_dir(),
  summary_path = nil,
  summary = nil,
  last_error = nil,
}

local function refresh_summary()
  state.last_error = nil
  state.summary = nil
  state.summary_path = nil

  local dir = state.results_dir
  if not file_exists(dir) then
    state.last_error = "Results-Ordner nicht gefunden: " .. tostring(dir)
    return
  end

  local spath = find_latest_summary(dir)
  if not spath or not file_exists(spath) then
    state.last_error = "Keine *_material_conflicts_summary.json im Results-Ordner gefunden."
    return
  end

  local data, err = load_json(spath)
  if not data then
    state.last_error = err or ("Fehler beim Laden der Summary: " .. tostring(spath))
    return
  end

  state.summary_path = spath
  state.summary = data
end

refresh_summary()

------------------------------------------------------------
-- GUI Loop
------------------------------------------------------------

local function loop()
  ig.ImGui_SetNextWindowSize(ctx, 500, 320, ig.Cond_FirstUseEver())
  local visible, open = ig.ImGui_Begin(ctx, "DF95 AIWorker Material Status", true)
  if visible then
    ig.ImGui_Text(ctx, "DF95 AIWorker – Material Status")
    ig.ImGui_Separator(ctx)

    ig.ImGui_Text(ctx, "Results-Ordner:")
    ig.ImGui_SameLine(ctx)
    ig.ImGui_Text(ctx, state.results_dir or "?")

    if ig.ImGui_Button(ctx, "Refresh", 80, 0) then
      refresh_summary()
    end

    ig.ImGui_Separator(ctx)

    if state.last_error then
      ig.ImGui_Text(ctx, "Fehler:")
      ig.ImGui_SameLine(ctx)
      ig.ImGui_TextColored(ctx, 1, 0.3, 0.3, 1, state.last_error)
    elseif not state.summary then
      ig.ImGui_Text(ctx, "Noch keine Summary geladen.")
    else
      local s = state.summary
      local overall = s.overall or {}
      local filters = s.filters or {}
      local pairs = s.pairs or {}

      ig.ImGui_Text(ctx, "Summary-Datei:")
      ig.ImGui_SameLine(ctx)
      ig.ImGui_Text(ctx, state.summary_path or "?")

      ig.ImGui_Separator(ctx)
      ig.ImGui_Text(ctx, string.format(
        "Results: %d   Matched: %d   Unmatched: %d",
        overall.total_results or 0,
        overall.matched or 0,
        overall.unmatched or 0
      ))
      ig.ImGui_Text(ctx, string.format(
        "Conflicts: %d   ProposedNew: %d",
        overall.num_conflicts or 0,
        overall.num_proposed_new or 0
      ))
      ig.ImGui_Text(ctx, string.format(
        "Min. Confidence: %.2f",
        overall.min_conf or 0.0
      ))

      local from_m = filters.from_material or ""
      local to_m   = filters.to_material or ""
      if (from_m ~= "") or (to_m ~= "") then
        ig.ImGui_Text(ctx, "Filter:")
        ig.ImGui_SameLine(ctx)
        ig.ImGui_Text(ctx, string.format("from: %s  ->  to: %s", from_m, to_m))
      end

      ig.ImGui_Separator(ctx)
      ig.ImGui_Text(ctx, "Top Konflikt-Paare (old -> new):")
      if #pairs == 0 then
        ig.ImGui_Text(ctx, "(keine Konfliktpaare in Summary)")
      else
        local max_show = math.min(#pairs, 10)
        for i = 1, max_show do
          local p = pairs[i]
          ig.ImGui_Text(ctx, string.format("  %s -> %s : %d",
            p.old or "?",
            p.new or "?",
            p.count or 0
          ))
        end
      end
    end

    ig.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    ig.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)
