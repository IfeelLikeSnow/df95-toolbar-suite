-- @description DF95 Fieldrec AI Annotations (ImGui Browser + Best-of Mode)
-- @version 1.1
-- @author DF95
-- @about
--   Zeigt alle Items im aktuellen Projekt an, die DF95 AIWorker-Tags
--   in den Item-Notes tragen (Block "[DF95 AIWorker]").
--
--   Features:
--     * Rescan des Projekts
--     * Filter nach Drum-Rolle (Kick/Snare/HiHat/Tom/Perc/FX/Ambience)
--     * Filter nach Mindest-Confidence
--     * Best-of Mode:
--         - pro Rolle (KICK, SNARE, …) nur das Item mit höchster Confidence
--         - optional pro Rolle+Instrument
--     * Klick auf eine Zeile -> Item auswählen & Cursor dorthin setzen
--
--   Typischer Workflow:
--     1. Fieldrec-Projekt bearbeiten, AIWorker-Bridge + ApplyToItems verwenden
--     2. Dieses Script starten -> Fenster zeigt alle AI-annotierten Items
--     3. Filter + Best-of nutzen, um die besten Slices pro Rolle zu finden

local r = reaper
local ctx = r.ImGui_CreateContext('DF95 Fieldrec AI Annotations')
local FONT_SCALE = 1.0

------------------------------------------------------------
-- State
------------------------------------------------------------

local ai_items = {}
local last_scan_time = 0
local role_filter = "ANY"
local min_conf_filter = 0.0
local selected_index = -1

local roles = {
  "ANY",
  "KICK",
  "SNARE",
  "HIHAT",
  "TOM",
  "PERC",
  "FX",
  "AMBIENCE",
}

local bestof_enabled = false
local bestof_group_mode = "ROLE"
local bestof_group_modes = { "ROLE", "ROLE+INSTRUMENT" }

------------------------------------------------------------
-- Utils
------------------------------------------------------------

local function format_time(t)
  return r.format_timestr(t, "")
end

local function get_track_name(tr)
  local ok, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if not ok or name == "" then
    local idx = r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    return string.format("Track %d", idx)
  end
  return name
end

local function parse_ai_block(notes)
  if not notes or notes == "" then return nil end

  local start_pos = notes:find("%[DF95 AIWorker%]")
  if not start_pos then return nil end

  local block = notes:sub(start_pos)
  local sep = block:find("\n\n")
  if sep then
    block = block:sub(1, sep-1)
  end

  local lines = {}
  for line in block:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  if #lines == 0 or not lines[1]:match("%[DF95 AIWorker%]") then
    return nil
  end

  local info = {
    raw_block = block,
  }

  for i = 2, #lines do
    local line = lines[i]
    local k, v = line:match("^([^=]+)=(.*)$")
    if k and v then
      k = k:lower()
      v = v:match("^%s*(.-)%s*$")
      if k == "material" then
        info.material = v
      elseif k == "instrument" then
        info.instrument = v
      elseif k == "confidence" then
        info.confidence = tonumber(v)
      elseif k == "tags" then
        info.tags_raw = v
        local tags = {}
        for t in v:gmatch("([^,]+)") do
          tags[#tags+1] = t:match("^%s*(.-)%s*$")
        end
        info.tags = tags
      elseif k == "ucs" then
        local c, s, d = v:match("^(.-)|(.-)|(.*)$")
        info.ucs_category = c
        info.ucs_subcategory = s
        info.ucs_description = d
      elseif k == "role" then
        info.role = v:upper()
      end
    end
  end

  return info
end

local function build_ai_items()
  ai_items = {}
  local proj = 0
  local num_tracks = r.CountTracks(proj)
  for ti = 0, num_tracks-1 do
    local tr = r.GetTrack(proj, ti)
    local tr_name = get_track_name(tr)
    local num_items = r.CountTrackMediaItems(tr)
    for ii = 0, num_items-1 do
      local it = r.GetTrackMediaItem(tr, ii)
      local take = r.GetActiveTake(it)
      local ok, notes = r.GetSetMediaItemInfo_String(it, "P_NOTES", "", false)
      notes = notes or ""
      if notes:find("%[DF95 AIWorker%]") then
        local ai = parse_ai_block(notes)
        if ai then
          local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
          local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")

          local src_path = ""
          if take then
            local src = r.GetMediaItemTake_Source(take)
            local _, fn = r.GetMediaSourceFileName(src, "", 2048)
            src_path = fn or ""
          end

          ai_items[#ai_items+1] = {
            track = tr,
            track_name = tr_name,
            item = it,
            take = take,
            pos = pos,
            len = len,
            ai = ai,
            src_path = src_path,
          }
        end
      end
    end
  end

  table.sort(ai_items, function(a, b)
    if a.track ~= b.track then
      local ta = r.GetMediaTrackInfo_Value(a.track, "IP_TRACKNUMBER")
      local tb = r.GetMediaTrackInfo_Value(b.track, "IP_TRACKNUMBER")
      if ta == tb then
        return a.pos < b.pos
      end
      return ta < tb
    end
    return a.pos < b.pos
  end)

  last_scan_time = r.time_precise()
  selected_index = (#ai_items > 0) and 1 or -1
end

local function item_matches_filters(entry)
  local ai = entry.ai
  if role_filter ~= "ANY" then
    local rupper = (ai.role or ""):upper()
    if rupper ~= role_filter then
      return false
    end
  end
  local conf = ai.confidence or 0.0
  if min_conf_filter > 0 then
    if not conf or conf < min_conf_filter then
      return false
    end
  end
  return true
end

local function build_visible_entries()
  local list = {}
  for i, e in ipairs(ai_items) do
    if item_matches_filters(e) then
      list[#list+1] = { idx = i, entry = e }
    end
  end

  if not bestof_enabled then
    return list
  end

  local groups = {}
  for _, rec in ipairs(list) do
    local e = rec.entry
    local ai = e.ai
    local role_key = (ai.role or "?")
    local group_key
    if bestof_group_mode == "ROLE" then
      group_key = role_key
    else
      local inst = ai.instrument or ai.material or "?"
      group_key = role_key .. "|" .. inst
    end

    local conf = ai.confidence or 0.0
    local g = groups[group_key]
    if not g or (conf > (g.entry.ai.confidence or 0.0)) then
      groups[group_key] = rec
    end
  end

  local best_list = {}
  for _, rec in pairs(groups) do
    best_list[#best_list+1] = rec
  end

  table.sort(best_list, function(a, b)
    local ta = r.GetMediaTrackInfo_Value(a.entry.track, "IP_TRACKNUMBER")
    local tb = r.GetMediaTrackInfo_Value(b.entry.track, "IP_TRACKNUMBER")
    if ta == tb then
      return a.entry.pos < b.entry.pos
    end
    return ta < tb
  end)

  return best_list
end

local function select_item(entry)
  local it = entry.item
  local tr = entry.track
  local proj = 0

  r.Main_OnCommand(40297, 0)
  r.Main_OnCommand(40289, 0)

  r.SetMediaItemSelected(it, true)
  r.UpdateItemInProject(it)

  r.SetOnlyTrackSelected(tr)
  r.SetEditCurPos(entry.pos, true, true)
end

local function select_all_visible(visible_entries)
  r.Undo_BeginBlock()
  r.Main_OnCommand(40289, 0)
  for _, rec in ipairs(visible_entries) do
    r.SetMediaItemSelected(rec.entry.item, true)
  end
  r.UpdateArrange()
  r.Undo_EndBlock("DF95 Fieldrec AI: Select all visible AI items", -1)
end

------------------------------------------------------------
-- ImGui UI
------------------------------------------------------------

local function draw_toolbar()
  if r.ImGui_Button(ctx, "Rescan", 80, 0) then
    build_ai_items()
  end
  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx, string.format("Items mit AI-Tags: %d", #ai_items))

  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx, "Rolle:")
  r.ImGui_SameLine(ctx)
  if r.ImGui_BeginCombo(ctx, "##rolefilter", role_filter, r.ImGui_ComboFlags_HeightLargest()) then
    for _, role in ipairs(roles) do
      local sel = (role == role_filter)
      if r.ImGui_Selectable(ctx, role, sel) then
        role_filter = role
      end
    end
    r.ImGui_EndCombo(ctx)
  end

  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx, "Min. Confidence:")
  r.ImGui_SameLine(ctx)
  local changed, val = r.ImGui_SliderDouble(ctx, "##minconf", min_conf_filter, 0.0, 1.0, "%.2f")
  if changed then
    min_conf_filter = val
  end

  r.ImGui_Separator(ctx)
  local changed_bo, bo_val = r.ImGui_Checkbox(ctx, "Best-of Mode", bestof_enabled)
  if changed_bo then
    bestof_enabled = bo_val
  end
  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx, "(zeigt nur das beste Item je Gruppe)")

  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx, "Group by:")
  r.ImGui_SameLine(ctx)
  if r.ImGui_BeginCombo(ctx, "##bestofgroup", bestof_group_mode, r.ImGui_ComboFlags_HeightLargest()) then
    for _, gm in ipairs(bestof_group_modes) do
      local sel = (gm == bestof_group_mode)
      if r.ImGui_Selectable(ctx, gm, sel) then
        bestof_group_mode = gm
      end
    end
    r.ImGui_EndCombo(ctx)
  end
end

local function draw_item_table()
  local visible_entries = build_visible_entries()

  if r.ImGui_Button(ctx, "Alle sichtbaren Items im Arrange selektieren", 280, 0) then
    if #visible_entries > 0 then
      select_all_visible(visible_entries)
    end
  end

  local flags = r.ImGui_TableFlags_RowBg() |
                r.ImGui_TableFlags_Borders() |
                r.ImGui_TableFlags_Resizable() |
                r.ImGui_TableFlags_ScrollY() |
                r.ImGui_TableFlags_Hideable()

  local avail_x, avail_y = r.ImGui_GetContentRegionAvail(ctx)
  if r.ImGui_BeginTable(ctx, "ai_items_table", 8, flags, avail_x, avail_y) then
    r.ImGui_TableSetupScrollFreeze(ctx, 0, 1)
    r.ImGui_TableSetupColumn(ctx, "Track", r.ImGui_TableColumnFlags_WidthFixed(), 120)
    r.ImGui_TableSetupColumn(ctx, "Pos", r.ImGui_TableColumnFlags_WidthFixed(), 80)
    r.ImGui_TableSetupColumn(ctx, "Role", r.ImGui_TableColumnFlags_WidthFixed(), 70)
    r.ImGui_TableSetupColumn(ctx, "Material", 0, 80)
    r.ImGui_TableSetupColumn(ctx, "Instrument", 0, 80)
    r.ImGui_TableSetupColumn(ctx, "UCS", 0, 160)
    r.ImGui_TableSetupColumn(ctx, "Conf", r.ImGui_TableColumnFlags_WidthFixed(), 60)
    r.ImGui_TableSetupColumn(ctx, "Tags", 0, 180)
    r.ImGui_TableHeadersRow(ctx)

    for _, rec in ipairs(visible_entries) do
      local i = rec.idx
      local entry = rec.entry
      r.ImGui_TableNextRow(ctx)

      local selected = (i == selected_index)

      r.ImGui_TableSetColumnIndex(ctx, 0)
      if r.ImGui_Selectable(ctx, entry.track_name .. "##row" .. i, selected, r.ImGui_SelectableFlags_SpanAllColumns()) then
        selected_index = i
        select_item(entry)
      end

      r.ImGui_TableSetColumnIndex(ctx, 1)
      r.ImGui_Text(ctx, format_time(entry.pos))

      r.ImGui_TableSetColumnIndex(ctx, 2)
      r.ImGui_Text(ctx, entry.ai.role or "")

      r.ImGui_TableSetColumnIndex(ctx, 3)
      r.ImGui_Text(ctx, entry.ai.material or "")

      r.ImGui_TableSetColumnIndex(ctx, 4)
      r.ImGui_Text(ctx, entry.ai.instrument or "")

      r.ImGui_TableSetColumnIndex(ctx, 5)
      local ucs_str = ""
      if entry.ai.ucs_category or entry.ai.ucs_subcategory or entry.ai.ucs_description then
        ucs_str = string.format("%s | %s | %s",
          entry.ai.ucs_category or "",
          entry.ai.ucs_subcategory or "",
          entry.ai.ucs_description or "")
      end
      r.ImGui_Text(ctx, ucs_str)

      r.ImGui_TableSetColumnIndex(ctx, 6)
      if entry.ai.confidence then
        r.ImGui_Text(ctx, string.format("%.2f", entry.ai.confidence))
      else
        r.ImGui_Text(ctx, "-")
      end

      r.ImGui_TableSetColumnIndex(ctx, 7)
      r.ImGui_Text(ctx, entry.ai.tags_raw or "")
    end

    r.ImGui_EndTable(ctx)
  end
end

local function loop()
  r.ImGui_PushFont(ctx, nil)

  r.ImGui_SetNextWindowSize(ctx, 800, 500, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 Fieldrec AI Annotations", true)

  if visible then
    if #ai_items == 0 and last_scan_time == 0 then
      build_ai_items()
    end

    draw_toolbar()
    r.ImGui_Separator(ctx)
    draw_item_table()

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
