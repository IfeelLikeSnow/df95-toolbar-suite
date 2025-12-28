-- @description DF95_Script_HealthCheck_ImGui
-- @version 1.1
-- @author DF95
-- @about
--   ImGui-Oberfläche für den DF95 Script Health Check.
--   Lädt alle DF95-Lua-Skripte (Scripts/IFLS/DF95) und testet sie
--   per loadfile() auf Syntaxfehler. Ergebnisse werden in einer
--   filterbaren Tabelle angezeigt.
--
--   Extras in v1.1:
--     - Button "AutoReport erzeugen": schreibt einen vollständigen Report
--       nach Data/DF95/DF95_ScriptHealthReport_TIMESTAMP.txt
--     - Pro Zeile ein "Edit"-Button, um ein Skript direkt im Editor
--       (oder per Standardprogramm des OS) zu öffnen.

local r = reaper
local ImGui = r.ImGui or reaper.ImGui

if not (ImGui and (r.ImGui_CreateContext or ImGui.CreateContext)) then
  r.ShowMessageBox("ReaImGui ist nicht installiert. Bitte über ReaPack nachinstallieren.", "DF95 Script HealthCheck ImGui", 0)
  return
end

local function get_sep()
  return package.config:sub(1,1)
end

local function normalize_path(path)
  local sep = get_sep()
  if sep == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function get_resource_path()
  return r.GetResourcePath()
end

local function get_df95_root()
  local sep = get_sep()
  local base = get_resource_path()
  local dir = base .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
  return normalize_path(dir)
end

local function list_lua_files(root)
  local sep = get_sep()
  local files = {}

  local function scan_dir(path)
    path = normalize_path(path)
    local cmd
    if sep == "\\" then
      cmd = 'dir "' .. path .. '" /b'
    else
      cmd = 'ls "' .. path .. '"'
    end
    local p = io.popen(cmd)
    if not p then return end
    for name in p:lines() do
      local full = path .. sep .. name
      full = normalize_path(full)
      if name:lower():match("%.lua$") then
        files[#files+1] = full
      elseif not name:match("%.") then
        -- einfache Heuristik: Eintrag ohne Punkt -> Unterordner
        scan_dir(full)
      end
    end
    p:close()
  end

  scan_dir(root)
  table.sort(files)
  return files
end

local function run_health_check()
  local root = get_df95_root()
  local files = list_lua_files(root)

  local results = {}
  local ok_count, fail_count = 0, 0

  for _, full in ipairs(files) do
    local rel = full:gsub("^" .. root, "DF95")
    rel = normalize_path(rel)
    local f, err = loadfile(full)
    local entry = {
      full = full,
      rel  = rel,
      ok   = (f ~= nil),
      err  = f and "" or tostring(err)
    }
    if entry.ok then ok_count = ok_count + 1 else fail_count = fail_count + 1 end
    results[#results+1] = entry
  end

  return results, ok_count, fail_count, root
end

local function ensure_data_dir()
  local sep = get_sep()
  local base = get_resource_path()
  local data_dir = base .. sep .. "Data" .. sep .. "DF95"
  data_dir = normalize_path(data_dir)
  r.RecursiveCreateDirectory(data_dir, 0)
  return data_dir
end

local function write_report(results, ok_count, fail_count, root)
  local sep = get_sep()
  local data_dir = ensure_data_dir()

  local ts = os.date("%Y%m%d_%H%M%S")
  local fname = data_dir .. sep .. "DF95_ScriptHealthReport_" .. ts .. ".txt"

  local f, err = io.open(fname, "w")
  if not f then
    r.ShowMessageBox("Konnte Report-Datei nicht schreiben:\n" .. tostring(err), "DF95 Script HealthCheck AutoReport", 0)
    return nil
  end

  f:write("DF95 Script HealthCheck AutoReport\n")
  f:write("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
  f:write("Root: " .. (root or "") .. "\n")
  f:write(string.rep("-", 60) .. "\n")
  f:write(string.format("Anzahl Skripte: %d\n", #results))
  f:write(string.format("OK: %d\n", ok_count or 0))
  f:write(string.format("FAIL: %d\n", fail_count or 0))
  f:write(string.rep("-", 60) .. "\n\n")

  f:write("DETAILS:\n\n")
  for _, e in ipairs(results) do
    local status = e.ok and "OK" or "FAIL"
    f:write(string.format("[%s] %s\n", status, e.rel or ""))
    if not e.ok and e.err and e.err ~= "" then
      f:write("  -> " .. e.err .. "\n")
    end
  end

  f:close()
  return fname
end

local function open_file_external(path)
  path = normalize_path(path)
  -- Bevorzugt SWS-Funktion, falls vorhanden
  if r.CF_ShellExecute then
    r.CF_ShellExecute(path)
    return
  end

  local sep = get_sep()
  local cmd
  if sep == "\\" then
    -- Windows
    cmd = 'start "" "' .. path .. '"'
  else
    -- macOS / Linux
    local uname = io.popen("uname"):read("*l") or ""
    if uname:match("Darwin") then
      cmd = 'open "' .. path .. '"'
    else
      cmd = 'xdg-open "' .. path .. '"'
    end
  end
  os.execute(cmd)
end

------------------------------------------------------------
-- ImGui State
------------------------------------------------------------

local ctx = nil
local results = {}
local ok_count, fail_count = 0, 0
local last_root = ""
local filter_text = ""
local show_only_fail = false

local function refresh_results()
  results, ok_count, fail_count, last_root = run_health_check()
end

local function main_loop()
  if not ctx then
    ctx = ImGui.CreateContext("DF95 Script HealthCheck", ImGui.ConfigFlags_None)
    local io = ImGui.GetIO(ctx)
    io.FontGlobalScale = 1.0
    refresh_results()
  end

  ImGui.SetNextWindowSize(ctx, 780, 560, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, "DF95 Script HealthCheck", true)
  if visible then
    ImGui.Text(ctx, "DF95 Script HealthCheck (ImGui)")
    ImGui.Spacing(ctx)
    ImGui.TextWrapped(ctx,
      "Prüft alle DF95-Lua-Skripte unter Scripts/IFLS/DF95 auf Syntaxfehler.\n" ..
      "Die Skripte werden NICHT ausgeführt, sondern nur mit loadfile() geladen.\n" ..
      "Nützlich nach Updates oder manuellen Änderungen im DF95-Repo.")

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Root: " .. (last_root or ""))
    ImGui.Text(ctx, string.format("Ergebnis: OK = %d, FAIL = %d", ok_count or 0, fail_count or 0))

    if ImGui.Button(ctx, "HealthCheck erneut ausführen", 240, 0) then
      refresh_results()
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "AutoReport erzeugen", 180, 0) then
      local fname = write_report(results or {}, ok_count or 0, fail_count or 0, last_root or "")
      if fname then
        r.ShowMessageBox(
          string.format("DF95 Script HealthCheck AutoReport erstellt.\nOK: %d, FAIL: %d\n\nDatei:\n%s",
            ok_count or 0, fail_count or 0, fname),
          "DF95 Script HealthCheck AutoReport",
          0
        )
      end
    end

    ImGui.Separator(ctx)
    ImGui.Text(ctx, "Filter")
    local changed
    changed, filter_text = ImGui.InputText(ctx, "Suchen (Dateiname / Pfad / Fehler)", filter_text or "", 256)
    changed, show_only_fail = ImGui.Checkbox(ctx, "Nur FAIL-Einträge anzeigen", show_only_fail)

    ImGui.Separator(ctx)
    ImGui.BeginChild(ctx, "results_child", 0, 360, true)

    ImGui.Columns(ctx, 4, "result_cols", true)
    ImGui.Text(ctx, "Status"); ImGui.NextColumn()
    ImGui.Text(ctx, "Script"); ImGui.NextColumn()
    ImGui.Text(ctx, "Fehler"); ImGui.NextColumn()
    ImGui.Text(ctx, "Aktion"); ImGui.NextColumn()
    ImGui.Separator(ctx)

    local needle = (filter_text or ""):lower()
    for idx, e in ipairs(results or {}) do
      local status = e.ok and "OK" or "FAIL"
      local color = e.ok and 0xFF88FF88 or 0xFF8888FF -- ABGR
      local hay = (e.rel or ""):lower() .. " " .. (e.err or ""):lower()

      if (not show_only_fail or not e.ok) and (needle == "" or hay:match(needle)) then
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, color)
        ImGui.Text(ctx, status)
        ImGui.PopStyleColor(ctx)
        ImGui.NextColumn()

        ImGui.Text(ctx, e.rel or "")
        ImGui.NextColumn()

        ImGui.TextWrapped(ctx, e.err or "")
        ImGui.NextColumn()

        local label = e.ok and ("Edit##" .. tostring(idx)) or ("Edit (FAIL)##" .. tostring(idx))
        if ImGui.SmallButton(ctx, label) then
          if e.full and e.full ~= "" then
            open_file_external(e.full)
          end
        end
        ImGui.NextColumn()
      end
    end

    ImGui.Columns(ctx, 1)
    ImGui.EndChild(ctx)

    ImGui.Spacing(ctx)
    if ImGui.Button(ctx, "Konsole öffnen (Log)", 180, 0) then
      r.ShowConsoleMsg("DF95 Script HealthCheck (ImGui) – Details siehe hier.\n")
    end

    ImGui.Spacing(ctx)
    if ImGui.Button(ctx, "Schließen", 100, 0) then
      open = false
    end
  end

  ImGui.End(ctx)

  if open then
    r.defer(main_loop)
  else
    ImGui.DestroyContext(ctx)
    ctx = nil
  end
end

main_loop()
