-- @description DF95 AIWorker Material Conflict Inspector (ImGui)
-- @version 1.0
-- @author DF95
-- @about
--   Zeigt Konflikte zwischen existierenden df95_material/df95_instrument Feldern
--   in der DF95 Multi-UCS SampleDB und neuen Vorschlägen aus einem AIWorker-
--   Result (Material-Mode) an. Nutzt die gleiche Logik wie der Python-
--   Conflict-Helper, aber mit ImGui-Frontend direkt in REAPER.

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox(
    "DF95 AIWorker Material Conflict Inspector benötigt REAPER mit ReaImGui-Unterstützung (REAPER v6.80+).",
    "DF95 AIWorker Material Conflict Inspector",
    0
  )
  return
end

local ctx = r.ImGui_CreateContext("DF95 AIWorker Material Conflicts")
local ig = r.ImGui

local sep = package.config:sub(1,1)

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_sampledb_path()
  local res = get_resource_path()
  local dir = join_path(res, "Support")
  dir = join_path(dir, "DF95_SampleDB")
  return join_path(dir, "DF95_SampleDB_Multi_UCS.json")
end

local function get_aiworker_root()
  local root = join_path(get_resource_path(), "Support")
  root = join_path(root, "DF95_AIWorker")
  return root
end

local function get_results_dir()
  return join_path(get_aiworker_root(), "Results")
end

local function norm_path(p)
  if not p or p == "" then return "" end
  p = p:gsub("\\", "/"):gsub("\\", "/"):gsub("\\", "/")
  return p:lower()
end

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

------------------------------------------------------------
-- JSON Loader (nutzt DF95_ReadJSON.lua)
------------------------------------------------------------

local function load_json(path)
  local respath = get_resource_path()
  local reader_path = join_path(join_path(respath, "Scripts"), "IfeelLikeSnow")
  reader_path = join_path(reader_path, "DF95")
  reader_path = join_path(reader_path, "DF95_ReadJSON.lua")
  local ok, reader = pcall(dofile, reader_path)
  if not ok or type(reader) ~= "function" then
    return {}
  end
  return reader(path)
end

------------------------------------------------------------
-- Conflict-Analyse (Lua-Port des Python-Conflict-Helpers)
------------------------------------------------------------

local function build_sampledb_map(db_path)
  local data = load_json(db_path)
  local items = {}
  if type(data) == "table" then
    if data.items and type(data.items) == "table" then
      items = data.items
    else
      items = data
    end
  end

  local map = {}
  for _, it in ipairs(items) do
    local cand = it.full_path or it.path or it.file or ""
    if cand ~= "" then
      map[norm_path(cand)] = it
    end
  end
  return map
end

local function load_results(result_path)
  local data = load_json(result_path)
  if type(data) ~= "table" then return {} end
  if type(data.results) == "table" then
    return data.results
  end
  return {}
end

local function analyze_conflicts_lua(db_path, result_path, min_conf)
  min_conf = min_conf or 0.5
  local db_map = build_sampledb_map(db_path)
  local results = load_results(result_path)

  local total_results = #results
  local matched, unmatched = 0, 0
  local conflicts = {}
  local proposed_new = {}
  local conflict_pairs = {}

  for _, res in ipairs(results) do
    local full = res.full_path or ""
    if full ~= "" then
      local key = norm_path(full)
      local item = db_map[key]
      if not item then
        unmatched = unmatched + 1
      else
        matched = matched + 1

        local function up(v)
          if not v then return "" end
          return (tostring(v):gsub("^%s+", ""):gsub("%s+$", "")):upper()
        end

        local old_mat = up(item.df95_material)
        local old_ins = up(item.df95_instrument)
        local new_mat = up(res.df95_material)
        local new_ins = up(res.df95_instrument)
        local ai_conf = tonumber(res.ai_confidence or 0.0) or 0.0
        local ai_model = tostring(res.ai_model or "")

        if (new_mat ~= "" or new_ins ~= "") and ai_conf >= min_conf then
          if old_mat == "" and old_ins == "" then
            proposed_new[#proposed_new+1] = {
              full_path = full,
              old_material = old_mat,
              new_material = new_mat,
              old_instrument = old_ins,
              new_instrument = new_ins,
              ai_confidence = ai_conf,
              ai_model = ai_model,
            }
          else
            local mat_conflict = (old_mat ~= "" and new_mat ~= "" and old_mat ~= new_mat)
            local ins_conflict = (old_ins ~= "" and new_ins ~= "" and old_ins ~= new_ins)
            if mat_conflict or ins_conflict then
              conflicts[#conflicts+1] = {
                full_path = full,
                old_material = old_mat,
                new_material = new_mat,
                old_instrument = old_ins,
                new_instrument = new_ins,
                ai_confidence = ai_conf,
                ai_model = ai_model,
              }
              local key_pair = (old_mat ~= "" and old_mat or "<EMPTY>") .. "||" .. (new_mat ~= "" and new_mat or "<EMPTY>")
              conflict_pairs[key_pair] = (conflict_pairs[key_pair] or 0) + 1
            end
          end
        end
      end
    end
  end

  return {
    total_results = total_results,
    matched = matched,
    unmatched = unmatched,
    conflicts = conflicts,
    proposed_new = proposed_new,
    conflict_pairs = conflict_pairs,
  }
end

------------------------------------------------------------
-- State
------------------------------------------------------------

local state = {
  db_path = get_sampledb_path(),
  results_dir = get_results_dir(),
  result_files = {},
  selected_result_idx = -1,
  min_conf = 0.6,
  stats = nil,
  last_error = nil,
}

local function refresh_result_files()
  state.result_files = {}
  local dir = state.results_dir
  local i = 0
  while true do
    local fname = r.EnumerateFiles(dir, i)
    if not fname then break end
    if fname:lower():match("%.json$") and fname:find("DF95_AIWorker_UCSResult_", 1, true) then
      state.result_files[#state.result_files+1] = fname
    end
    i = i + 1
  end
  table.sort(state.result_files)
  if #state.result_files == 0 then
    state.selected_result_idx = -1
  else
    if state.selected_result_idx < 0 or state.selected_result_idx > #state.result_files then
      state.selected_result_idx = #state.result_files
    end
  end
end

local function run_analysis()
  state.last_error = nil
  state.stats = nil

  if not file_exists(state.db_path) then
    state.last_error = "SampleDB nicht gefunden: " .. tostring(state.db_path)
    return
  end

  if state.selected_result_idx < 1 or state.selected_result_idx > #state.result_files then
    state.last_error = "Bitte ein Result-JSON auswählen."
    return
  end

  local result_name = state.result_files[state.selected_result_idx]
  local result_path = join_path(state.results_dir, result_name)

  if not file_exists(result_path) then
    state.last_error = "Result-JSON existiert nicht: " .. tostring(result_path)
    return
  end

  local ok, stats_or_err = pcall(analyze_conflicts_lua, state.db_path, result_path, state.min_conf)
  if not ok then
    state.last_error = "Analyse fehlgeschlagen: " .. tostring(stats_or_err)
    return
  end

  state.stats = stats_or_err
end

refresh_result_files()

------------------------------------------------------------
-- GUI
------------------------------------------------------------

local function loop()
  ig.ImGui_SetNextWindowSize(ctx, 800, 600, ig.Cond_FirstUseEver())
  local visible, open = ig.ImGui_Begin(ctx, "DF95 AIWorker Material Conflicts", true)
  if visible then
    ig.ImGui_Text(ctx, "DF95 AIWorker Material Conflict Inspector")
    ig.ImGui_Separator(ctx)

    -- SampleDB Path
    ig.ImGui_Text(ctx, "SampleDB:")
    ig.ImGui_SameLine(ctx)
    ig.ImGui_Text(ctx, state.db_path)

    ig.ImGui_Text(ctx, "Results-Ordner:")
    ig.ImGui_SameLine(ctx)
    ig.ImGui_Text(ctx, state.results_dir or "?")

    ig.ImGui_Separator(ctx)

    -- Result-Auswahl & Min-Confidence
    ig.ImGui_Text(ctx, "Result-JSON:")
    ig.ImGui_SameLine(ctx)
    if ig.ImGui_Button(ctx, "Refresh", 0, 0) then
      refresh_result_files()
    end

    if #state.result_files == 0 then
      ig.ImGui_Text(ctx, "(keine DF95_AIWorker_UCSResult_*.json im Results-Ordner gefunden)")
    else
      ig.ImGui_Separator(ctx)
      -- Combo für Result-Auswahl
      local current_label = state.result_files[state.selected_result_idx] or "(bitte wählen)"
      if ig.ImGui_BeginCombo(ctx, "Result", current_label, 0) then
        for i, name in ipairs(state.result_files) do
          local is_selected = (i == state.selected_result_idx)
          if ig.ImGui_Selectable(ctx, name, is_selected, 0, 0, 0) then
            state.selected_result_idx = i
          end
          if is_selected then
            ig.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        ig.ImGui_EndCombo(ctx)
      end

      -- Min-Confidence Slider
      local changed, new_min = ig.ImGui_SliderDouble(ctx, "Min. AI-Confidence", state.min_conf, 0.0, 1.0, "%.2f")
      if changed then
        state.min_conf = new_min
      end

      if ig.ImGui_Button(ctx, "Analyse starten", 150, 0) then
        run_analysis()
      end
    end

    ig.ImGui_Separator(ctx)

    if state.last_error then
      ig.ImGui_Text(ctx, "Fehler:")
      ig.ImGui_SameLine(ctx)
      ig.ImGui_TextColored(ctx, 1, 0.3, 0.3, 1, state.last_error)
    end

    if state.stats then
      local st = state.stats
      ig.ImGui_Text(ctx, string.format("Total Results: %d   Matched: %d   Unmatched: %d",
        st.total_results or 0, st.matched or 0, st.unmatched or 0))
      ig.ImGui_Text(ctx, string.format("Conflicts: %d   Proposed new: %d",
        #(st.conflicts or {}), #(st.proposed_new or {})))

      ig.ImGui_Separator(ctx)
      ig.ImGui_Text(ctx, "Top Konflikt-Paare (old -> new):")
      local pairs = st.conflict_pairs or {}
      local pair_list = {}
      for key, count in pairs pairs do
        pair_list[#pair_list+1] = { key = key, count = count }
      end
      table.sort(pair_list, function(a,b) return a.count > b.count end)
      local max_show = math.min(#pair_list, 20)
      if max_show == 0 then
        ig.ImGui_Text(ctx, "(keine Konflikt-Paare mit aktuellem Confidence-Filter)")
      else
        for i = 1, max_show do
          local entry = pair_list[i]
          local old_mat, new_mat = entry.key:match("^(.-)||(.+)$")
          ig.ImGui_Text(ctx, string.format("  %s -> %s : %d", old_mat or "?", new_mat or "?", entry.count))
        end
      end

      ig.ImGui_Separator(ctx)
      ig.ImGui_Text(ctx, "Konflikte (Material/Instrument):")
      if #(st.conflicts or {}) == 0 then
        ig.ImGui_Text(ctx, "(keine Konflikte)")
      else
        r.ImGui_Columns(ctx, 6, "df95_ai_conflict_cols", true)
        r.ImGui_Text(ctx, "old_mat"); r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "new_mat"); r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "old_ins"); r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "new_ins"); r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "conf");    r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "model");   r.ImGui_NextColumn(ctx)

        for _, c in ipairs(st.conflicts) do
          r.ImGui_Text(ctx, c.old_material or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.new_material or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.old_instrument or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.new_instrument or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, string.format("%.3f", c.ai_confidence or 0)); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.ai_model or ""); r.ImGui_NextColumn(ctx)
        end

        r.ImGui_Columns(ctx, 1)
      end

      ig.ImGui_Separator(ctx)
      ig.ImGui_Text(ctx, "Proposed new (bisher leere Material/Instrument-Felder):")
      if #(st.proposed_new or {}) == 0 then
        ig.ImGui_Text(ctx, "(keine neuen Vorschläge mit aktuellem Confidence-Filter)")
      else
        r.ImGui_Columns(ctx, 6, "df95_ai_proposed_cols", true)
        r.ImGui_Text(ctx, "mat");   r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "ins");   r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "conf");  r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "model"); r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "path");  r.ImGui_NextColumn(ctx)
        r.ImGui_Text(ctx, "");      r.ImGui_NextColumn(ctx)

        for _, c in ipairs(st.proposed_new) do
          r.ImGui_Text(ctx, c.new_material or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.new_instrument or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, string.format("%.3f", c.ai_confidence or 0)); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.ai_model or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, c.full_path or ""); r.ImGui_NextColumn(ctx)
          r.ImGui_Text(ctx, ""); r.ImGui_NextColumn(ctx)
        end

        r.ImGui_Columns(ctx, 1)
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
