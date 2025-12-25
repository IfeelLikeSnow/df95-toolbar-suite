-- @description DF95_Script_HealthCheck
-- @version 1.0
-- @author DF95
-- @about
--   Prüft alle DF95-Lua-Skripte im REAPER-ResourcePath (Standard: Scripts/IFLS/DF95)
--   auf Syntaxfehler, indem sie mit loadfile/pcall geladen werden.
--   Ergebnis wird im REAPER-Console-Log ausgegeben.
--
--   Hinweis:
--     - Dies ist ein statischer Health-Check (keine Ausführung der Skripte).
--     - Er findet Syntaxfehler (z.B. fehlende 'end', kaputte Strings),
--       aber keine logischen Fehler.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function get_df95_script_dir()
  local sep = package.config:sub(1,1)
  local base = r.GetResourcePath()
  local dir = base .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95"
  return dir
end

local function list_lua_files(root)
  local sep = package.config:sub(1,1)
  local files = {}

  local function scan_dir(path)
    local ok, iter, dir_obj = pcall(function() return os.listdir(path) end)
    if not ok or not iter then
      -- Fallback über io.popen (plattformabhängig)
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
        -- Wir haben keine direkte Möglichkeit, File vs. Directory zu unterscheiden ohne lfs,
        -- deshalb filtern wir nur .lua-Dateien plus einfache Unterordner-Heuristik.
        if name:lower():match("%.lua$") then
          files[#files+1] = full
        elseif not name:match("%.") then
          -- naive Heuristik: Eintrag ohne Punkt könnte ein Ordner sein -> rekursiv
          scan_dir(full)
        end
      end
      p:close()
      return
    end
  end

  -- In den meisten REAPER-Setups existiert os.listdir nicht; wir nutzen daher nur die Fallback-Variante oben.
  -- Wir rufen scan_dir einfach auf und lassen die Fallback-Logik arbeiten.
  scan_dir(root)

  return files
end

local function normalize_path(path)
  local sep = package.config:sub(1,1)
  if sep == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function run_health_check()
  r.ShowConsoleMsg("") -- Clear console on some systems
  msg("=== DF95 Script Health Check ===")
  local root = get_df95_script_dir()
  msg("Root: " .. root)

  local files = list_lua_files(root)
  table.sort(files)

  if #files == 0 then
    msg("Keine DF95-Lua-Skripte unter " .. root .. " gefunden.")
    return
  end

  msg(string.format("Gefundene Skripte: %d", #files))
  msg("----------------------------------------")

  local ok_count = 0
  local fail_count = 0

  for _, full in ipairs(files) do
    local rel = normalize_path(full:gsub("^" .. normalize_path(root), "DF95"))
    local f, err = loadfile(full)
    if f then
      ok_count = ok_count + 1
      msg("[OK]    " .. rel)
    else
      fail_count = fail_count + 1
      msg("[FAIL] " .. rel)
      msg("       -> " .. tostring(err))
    end
  end

  msg("----------------------------------------")
  msg(string.format("Fertig. OK: %d, FAIL: %d", ok_count, fail_count))
  if fail_count > 0 then
    msg("Bitte die [FAIL]-Einträge prüfen – meist sind dies Syntaxfehler (z.B. kaputte Strings oder fehlende 'end').")
  else
    msg("Alle DF95-Skripte konnten syntaktisch geladen werden.")
  end
end

run_health_check()
