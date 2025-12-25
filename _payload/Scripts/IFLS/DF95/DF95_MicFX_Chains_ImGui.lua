
-- @description MicFX Chain Browser
-- @version 1.3
-- @author DF95
-- @about
--   Öffnet ein ImGui-Fenster mit einer Dropdown-Auswahl von FX-Chains
--   aus dem FXChains-Ordner. Die Chains werden rekursiv in allen
--   Unterordnern gesucht, nach Kategorien gruppiert und können auf
--   selektierte Tracks angewendet werden.
--
--   Zusatz (v1.3):
--   - Favoriten mit Priorität (0–3 Sterne)
--   - Filtermodus: Alle / nur Favoriten / nur Nicht-Favoriten
--   - Favoriten werden persistent in ExtState gespeichert
--     (Sektion: DF95_CHAIN_BROWSER, Key: favorites)
--
--   Hinweis:
--   - Die tatsächliche Kategorisierung erfolgt anhand der Dateinamen
--     (Präfixe wie MIC_, FX_GLITCH_, FX_PERC_, FX_FILTER_, COLOR_, MASTER_).

local r = reaper

local ctx = r.ImGui_CreateContext("MicFX Chain Browser", 0)

local function load_favorites()
  local s = r.GetExtState("DF95_CHAIN_BROWSER", "favorites") or ""
  local fav = {}
  if s ~= "" then
    for token in string.gmatch(s, "([^;]+)") do
      local name, lvl = token:match("^(.*):(%d+)$")
      if name and lvl then
        fav[name] = tonumber(lvl) or 1
      else
        -- Legacy-Format: nur Name, ohne Level -> als 1 Stern interpretieren
        fav[token] = 1
      end
    end
  end
  return fav
end

local function save_favorites(fav)
  local t = {}
  for name, lvl in pairs(fav) do
    if lvl and lvl > 0 then
      table.insert(t, name .. ":" .. tostring(math.floor(lvl)))
    end
  end
  table.sort(t)
  local s = table.concat(t, ";")
  r.SetExtState("DF95_CHAIN_BROWSER", "favorites", s, true)
end

local function scan_fxchains()
  local categories = {
    ["Glitch / IDM"]        = { },
    ["Perc / DrumGhost"]    = { },
    ["Filter / Motion"]     = { },
    ["Coloring / Tone"]     = { },
    ["Master / Safety"]     = { },
    ["MicFX"]               = { },
    ["Other"]               = { },
  }

  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local root = res .. sep .. "FXChains"

  local function classify(name)
    local lname = name:lower()
    if lname:find("mic_") or lname:find("mcm") or lname:find("ntg") or lname:find("md400") or lname:find("geofon") or lname:find("lav") or lname:find("telecoil") then
      return "MicFX"
    elseif lname:find("fx_glitch_") or lname:find("glitch") or lname:find("idm") or lname:find("stutter") or lname:find("slice") or lname:find("gran") then
      return "Glitch / IDM"
    elseif lname:find("fx_perc_") or lname:find("perc") or lname:find("drum") or lname:find("ghost") then
      return "Perc / DrumGhost"
    elseif lname:find("fx_filter_") or lname:find("filter") or lname:find("motion") or lname:find("sweep") then
      return "Filter / Motion"
    elseif lname:find("color_") or lname:find("color") or lname:find("tape") or lname:find("sat") or lname:find("warm") or lname:find("tone") then
      return "Coloring / Tone"
    elseif lname:find("master_") or lname:find("master") or lname:find("limit") or lname:find("lufs") or lname:find("safety") then
      return "Master / Safety"
    end
    return "Other"
  end

  local function scan_dir(dir)
    local i = 0
    while true do
      local file = r.EnumerateFiles(dir, i)
      if not file then break end
      if file:lower():match("%.rfxchain$") then
        local name = file:gsub("%.RfxChain",""):gsub("%.rfxchain","")
        local cat = classify(name)
        table.insert(categories[cat], name)
      end
      i = i + 1
    end
    local j = 0
    while true do
      local sub = r.EnumerateSubdirectories(dir, j)
      if not sub then break end
      scan_dir(dir .. sep .. sub)
      j = j + 1
    end
  end

  scan_dir(root)

  for _, list in pairs(categories) do
    table.sort(list)
  end

  local cat_list = {}
  for k, _ in pairs(categories) do
    table.insert(cat_list, k)
  end
  table.sort(cat_list)

  return categories, cat_list
end

local favorites = load_favorites()
local categories, cat_list = scan_fxchains()
local current_cat_idx = 1
local current_chain_name = nil
local filter_mode = 1 -- 1=alle, 2=nur Favoriten, 3=nur Nicht-Favoriten

local filter_labels = {
  [1] = "Alle Chains",
  [2] = "Nur Favoriten",
  [3] = "Nur nicht-Favoriten",
}

local function star_prefix(level)
  if not level or level <= 0 then return "" end
  if level == 1 then return "★ "
  elseif level == 2 then return "★★ "
  else return "★★★ " end
end

local function apply_chain_to_selected(chain_name)
  if not chain_name or chain_name == "" then return end
  local sel_count = r.CountSelectedTracks(0)
  if sel_count == 0 then
    r.ShowMessageBox("Keine selektierten Tracks. Bitte wähle einen oder mehrere Tracks aus.", "MicFX Chain Browser", 0)
    return
  end
  r.Undo_BeginBlock()
  for i = 0, sel_count-1 do
    local tr = r.GetSelectedTrack(0, i)
    r.TrackFX_AddByName(tr, "FXCHAIN:" .. chain_name, false, -1)
  end
  r.Undo_EndBlock("MicFX Chain Browser: Apply " .. chain_name, -1)
end

local function get_filtered_chains(cat)
  local src = categories[cat] or {}
  local out = {}
  for _, ch in ipairs(src) do
    local lvl = favorites[ch] or 0
    if filter_mode == 1
      or (filter_mode == 2 and lvl > 0)
      or (filter_mode == 3 and lvl == 0)
    then
      table.insert(out, ch)
    end
  end
  return out
end

local function loop()
  local visible, open = r.ImGui_Begin(ctx, "MicFX Chain Browser", true)
  if visible then
    if #cat_list == 0 then
      r.ImGui_Text(ctx, "Keine FX-Chains im FXChains-Ordner gefunden.")
    else
      local current_cat = cat_list[current_cat_idx] or ""
      if r.ImGui_BeginCombo(ctx, "Kategorie", current_cat) then
        for i, cat in ipairs(cat_list) do
          local selected = (i == current_cat_idx)
          if r.ImGui_Selectable(ctx, cat, selected) then
            current_cat_idx = i
            current_chain_name = nil
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end

      -- Filtermodus
      local filter_label = filter_labels[filter_mode] or "Alle Chains"
      if r.ImGui_BeginCombo(ctx, "Filter", filter_label) then
        for i = 1, 3 do
          local selected = (i == filter_mode)
          if r.ImGui_Selectable(ctx, filter_labels[i], selected) then
            filter_mode = i
            current_chain_name = nil
          end
          if selected then
            r.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        r.ImGui_EndCombo(ctx)
      end

      local current_cat = cat_list[current_cat_idx] or ""
      local chains = get_filtered_chains(current_cat)
      if #chains == 0 then
        r.ImGui_Text(ctx, "Keine Chains für diesen Filter in dieser Kategorie.")
      else
        -- sicherstellen, dass current_chain_name gültig ist
        local found = false
        for _, ch in ipairs(chains) do
          if ch == current_chain_name then
            found = true
            break
          end
        end
        if not found then
          current_chain_name = chains[1]
        end

        local lvl = favorites[current_chain_name] or 0
        local display_chain = (star_prefix(lvl) .. current_chain_name)

        if r.ImGui_BeginCombo(ctx, "Chain", display_chain) then
          for _, ch in ipairs(chains) do
            local clvl = favorites[ch] or 0
            local label = star_prefix(clvl) .. ch
            local selected = (ch == current_chain_name)
            if r.ImGui_Selectable(ctx, label, selected) then
              current_chain_name = ch
            end
            if selected then
              r.ImGui_SetItemDefaultFocus(ctx)
            end
          end
          r.ImGui_EndCombo(ctx)
        end

        if r.ImGui_Button(ctx, "Apply to selected Tracks") then
          apply_chain_to_selected(current_chain_name)
        end

        r.ImGui_SameLine(ctx)
        local lvl_btn_label
        local lvl_cur = favorites[current_chain_name] or 0
        if lvl_cur <= 0 then
          lvl_btn_label = "☆ Add (1–3 Sterne)"
        elseif lvl_cur == 1 then
          lvl_btn_label = "★ Stufe 1 → 2"
        elseif lvl_cur == 2 then
          lvl_btn_label = "★★ Stufe 2 → 3"
        else
          lvl_btn_label = "★★★ Stufe 3 → 0"
        end

        if r.ImGui_Button(ctx, lvl_btn_label) then
          local new_lvl = (lvl_cur + 1) % 4 -- 0,1,2,3
          if new_lvl <= 0 then
            favorites[current_chain_name] = nil
          else
            favorites[current_chain_name] = new_lvl
          end
          save_favorites(favorites)
        end
      end
    end

    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx, "Hinweis: Dieses Fenster durchsucht rekursiv den FXChains-Ordner und sortiert Chains anhand der Dateinamen in Kategorien (MicFX, FX_GLITCH, FX_PERC, FX_FILTER, COLOR, MASTER, Other).")
    r.ImGui_TextWrapped(ctx, "Favoriten: Du kannst für jede Chain 0–3 Sterne vergeben. Der Filter erlaubt dir, nur Favoriten oder nur Nicht-Favoriten anzuzeigen.")

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
