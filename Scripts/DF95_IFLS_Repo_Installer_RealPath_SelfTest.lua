-- DF95_IFLS_Repo_Installer_RealPath_SelfTest.lua
-- IFLS / DF95 Repo Installer mit dynamischem REAPER-Resource-Pfad (reaper.GetResourcePath) + Self-Test
--
-- Dieses Script ist speziell für das System von "ifeel":
--   REAPER Resource Path = reaper.GetResourcePath() (dynamisch ermittelt)
--
-- Funktionen:
--   • Install:  Repo-ZIP auswählen und nach REAL_RESOURCE_PATH\Scripts, \Effects, \Support kopieren
--   • Uninstall: löscht IfeelLikeSnow/IFLS/DF95-Strukturen unter REAL_RESOURCE_PATH
--   • Self-Test: scannt Skripte/JSFX/Configs im IfeelLikeSnow-Namespace und zeigt eine Zusammenfassung
--
-- WICHTIG:
--   • Dieses Script verwendet reaper.GetResourcePath() und ist damit auf beliebigen Systemen lauffähig,
--     solange die IFLS/DF95-Struktur im ResourcePath liegt.

--------------------------------------------------
-- KONFIGURATION
--------------------------------------------------

-- Fester REAPER Resource Path (von dir bestätigt)
local REAL_RESOURCE_PATH = reaper.GetResourcePath()

-- Pfade, die bei Uninstall entfernt werden (relativ zu REAL_RESOURCE_PATH)
local TARGET_REMOVE_PATHS = {
  "Scripts/IfeelLikeSnow",
  "Effects/IfeelLikeSnow",
}

local sep = package.config:sub(1,1) or "\\"

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  else
    return a .. sep .. b
  end
end

local function msg(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end

local function alert(title, text)
  reaper.ShowMessageBox(text, title, 0)
end

--------------------------------------------------
-- FS Helpers
--------------------------------------------------

local function path_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end
  if code == 13 then return true end -- permission denied but exists
  return false
end

local function ensure_dir(path)
  reaper.RecursiveCreateDirectory(path, 0)
end

local function delete_tree(path)
  if not path_exists(path) then return end

  -- Dateien löschen
  local i = 0
  while true do
    local fname = reaper.EnumerateFiles(path, i)
    if not fname then break end
    local fpath = join_path(path, fname)
    os.remove(fpath)
    i = i + 1
  end

  -- Unterordner löschen
  local j = 0
  while true do
    local dname = reaper.EnumerateSubdirectories(path, j)
    if not dname then break end
    local dpath = join_path(path, dname)
    delete_tree(dpath)
    j = j + 1
  end

  -- Root-Ordner selbst löschen
  os.remove(path)
end

local function copy_file(src, dst)
  local f_in = io.open(src, "rb")
  if not f_in then
    return false, "cannot open src: " .. tostring(src)
  end
  local data = f_in:read("*a")
  f_in:close()

  local dst_dir = dst:match("^(.*" .. sep .. ")")
  if dst_dir then ensure_dir(dst_dir) end

  local f_out, err = io.open(dst, "wb")
  if not f_out then
    return false, "cannot open dst: " .. tostring(dst) .. " (" .. tostring(err) .. ")"
  end
  f_out:write(data)
  f_out:close()
  return true
end

local function copy_tree(src_root, dst_root)
  ensure_dir(dst_root)

  -- Unterordner
  local i = 0
  while true do
    local dirname = reaper.EnumerateSubdirectories(src_root, i)
    if not dirname then break end
    local src_sub = join_path(src_root, dirname)
    local dst_sub = join_path(dst_root, dirname)
    copy_tree(src_sub, dst_sub)
    i = i + 1
  end

  -- Dateien
  local j = 0
  while true do
    local fname = reaper.EnumerateFiles(src_root, j)
    if not fname then break end
    local src_f = join_path(src_root, fname)
    local dst_f = join_path(dst_root, fname)
    local ok, err = copy_file(src_f, dst_f)
    if not ok then
      msg("[WARN] Copy failed: " .. src_f .. " -> " .. dst_f .. " (" .. tostring(err) .. ")")
    else
      msg("[OK] Copied: " .. src_f .. " -> " .. dst_f)
    end
    j = j + 1
  end
end

local function is_windows()
  local os_str = reaper.GetOS()
  return os_str:match("Win") ~= nil
end

local function run_cmd(cmd)
  msg("[CMD] " .. cmd)
  local res, _, code = os.execute(cmd)
  if res == true or res == 0 then return true end
  if type(res) == "number" and res == 0 then return true end
  if type(code) == "number" and code == 0 then return true end
  return false
end

--------------------------------------------------
-- Unzip
--------------------------------------------------

local function unzip(zip_path, dest_dir)
  ensure_dir(dest_dir)

  if is_windows() then
    -- PowerShell Expand-Archive
    local cmd = 'powershell -Command "Expand-Archive -LiteralPath \'' .. zip_path .. '\' -DestinationPath \'' .. dest_dir .. '\' -Force"'
    local ok = run_cmd(cmd)
    if not ok then
      return false, "Unzip fehlgeschlagen (PowerShell Expand-Archive)"
    end
    return true
  else
    local cmd = 'unzip -o "' .. zip_path .. '" -d "' .. dest_dir .. '"'
    local ok = run_cmd(cmd)
    if not ok then
      return false, "Unzip fehlgeschlagen (unzip Kommando)"
    end
    return true
  end
end

local function find_repo_root(tmp_dir)
  local candidate = join_path(tmp_dir, "Scripts")
  if path_exists(candidate) then
    return tmp_dir
  end

  local first_subdir = nil
  local count_subdirs = 0
  local i = 0
  while true do
    local d = reaper.EnumerateSubdirectories(tmp_dir, i)
    if not d then break end
    count_subdirs = count_subdirs + 1
    if count_subdirs == 1 then
      first_subdir = d
    end
    i = i + 1
  end

  if count_subdirs == 1 and first_subdir then
    local subroot = join_path(tmp_dir, first_subdir)
    local sub_scripts = join_path(subroot, "Scripts")
    if path_exists(sub_scripts) then
      return subroot
    end
  end

  return tmp_dir
end

--------------------------------------------------
-- Uninstall
--------------------------------------------------

local function do_uninstall()
  msg("=== IFLS Uninstall (REAL_RESOURCE_PATH) ===")
  msg("REAL_RESOURCE_PATH: " .. REAL_RESOURCE_PATH)

  for _, rel in ipairs(TARGET_REMOVE_PATHS) do
    local full = join_path(REAL_RESOURCE_PATH, rel)
    if path_exists(full) then
      msg("[UNINSTALL] remove tree: " .. full)
      delete_tree(full)
    else
      msg("[UNINSTALL] skip missing: " .. full)
    end
  end

  -- Support/DF95* / IFLS* / IfeelLikeSnow*
  local support_root = join_path(REAL_RESOURCE_PATH, "Support")
  if path_exists(support_root) then
    local i = 0
    while true do
      local d = reaper.EnumerateSubdirectories(support_root, i)
      if not d then break end
      if d:match("^DF95") or d:match("^IFLS") or d:match("^IfeelLikeSnow") then
        local dirpath = join_path(support_root, d)
        msg("[UNINSTALL] remove Support dir: " .. dirpath)
        delete_tree(dirpath)
      end
      i = i + 1
    end

    local j = 0
    while true do
      local f = reaper.EnumerateFiles(support_root, j)
      if not f then break end
      if f:match("^DF95") or f:match("^IFLS") or f:match("^IfeelLikeSnow") then
        local fpath = join_path(support_root, f)
        msg("[UNINSTALL] remove Support file: " .. fpath)
        os.remove(fpath)
      end
      j = j + 1
    end
  end

  alert("IFLS Uninstall (RealPath)",
        "IFLS/DF95 Strukturen unter:\n\n" .. REAL_RESOURCE_PATH .. "\n\n" ..
        "wurden weitgehend entfernt.")
end

--------------------------------------------------
-- Self-Test (integriert)
--------------------------------------------------

local function self_test()
  local scripts_root = join_path(REAL_RESOURCE_PATH, "Scripts" .. sep .. "IfeelLikeSnow")
  local effects_root = join_path(REAL_RESOURCE_PATH, "Effects" .. sep .. "IfeelLikeSnow")

  local counts = {
    lua = 0,
    jsfx = 0,
    json = 0,
    png = 0,
    md = 0,
    txt = 0,
    other = 0,
  }

  local function scan_root(root)
    if not path_exists(root) then return end
    local function recurse(dir)
      local i = 0
      while true do
        local sub = reaper.EnumerateSubdirectories(dir, i)
        if not sub then break end
        recurse(join_path(dir, sub))
        i = i + 1
      end
      local j = 0
      while true do
        local f = reaper.EnumerateFiles(dir, j)
        if not f then break end
        local lower = f:lower()
        local ext = lower:match("%.([^.]+)$") or ""
        if ext == "lua" then
          counts.lua = counts.lua + 1
        elseif ext == "jsfx" then
          counts.jsfx = counts.jsfx + 1
        elseif ext == "json" then
          counts.json = counts.json + 1
        elseif ext == "png" then
          counts.png = counts.png + 1
        elseif ext == "md" then
          counts.md = counts.md + 1
        elseif ext == "txt" then
          counts.txt = counts.txt + 1
        else
          counts.other = counts.other + 1
        end
        j = j + 1
      end
    end
    recurse(root)
  end

  scan_root(scripts_root)
  scan_root(effects_root)

  local summary = "IFLS / DF95 Self-Test (RealPath)\n\n" ..
                  "Resource Path:\n" .. REAL_RESOURCE_PATH .. "\n\n" ..
                  "Scanned:\n" ..
                  "  " .. scripts_root .. "\n" ..
                  "  " .. effects_root .. "\n\n" ..
                  "Gefundene Dateien:\n" ..
                  "  Lua  : " .. tostring(counts.lua) .. "\n" ..
                  "  JSFX : " .. tostring(counts.jsfx) .. "\n" ..
                  "  JSON : " .. tostring(counts.json) .. "\n" ..
                  "  PNG  : " .. tostring(counts.png) .. "\n" ..
                  "  MD   : " .. tostring(counts.md) .. "\n" ..
                  "  TXT  : " .. tostring(counts.txt) .. "\n" ..
                  "  Other: " .. tostring(counts.other) .. "\n\n" ..
                  "(Hinweis: Dies ist ein integrierter Self-Test,\n" ..
                  "Diagnostics 2.0/3.0 werden hier nicht aufgerufen.)"

  alert("IFLS / DF95 Self-Test (RealPath)", summary)

  ----------------------------------------------------
  -- Optional: DF95 Self-Test Result Viewer öffnen
  ----------------------------------------------------
  local ret = reaper.ShowMessageBox(
    "Möchtest du den DF95 Self-Test Result Viewer öffnen\n" ..
    "und die detaillierten Reports (TXT + Manifest) ansehen?",
    "DF95 Self-Test Result Viewer",
    4 -- Yes/No
  )

  if ret == 6 then -- Yes
    local viewer_path = REAL_RESOURCE_PATH..sep.."Scripts"..sep.."IFLS"..sep.."DF95"..sep.."DF95_SelfTest_ResultViewer.lua"
    local ok,err = pcall(dofile, viewer_path)
    if not ok then
      alert("DF95 Self-Test Result Viewer – Fehler",
        "Fehler beim Laden des Viewers:\n\n"..tostring(err)
          .."\n\nErwarteter Pfad:\n"..viewer_path)
    end
  end
end

--------------------------------------------------
-- Install
--------------------------------------------------

local function do_install()
  msg("=== IFLS Install (RealPath) ===")
  msg("REAL_RESOURCE_PATH: " .. REAL_RESOURCE_PATH)

  local tmp_root = join_path(REAL_RESOURCE_PATH, "IFLS_RepoInstaller_Temp")
  ensure_dir(tmp_root)

  local ok, zip_path = reaper.GetUserFileNameForRead(
    "",
    "Wähle IFLS Master Repo ZIP (z.B. IFLS_MasterRepo_AllIntegrated_UpTo_Phase115_Diagnostics2_IFLSOnly.zip)",
    ""
  )
  if not ok or not zip_path or zip_path == "" then
    msg("Install: keine ZIP gewählt, Abbruch.")
    return
  end

  if not path_exists(zip_path) then
    alert("IFLS Installer (RealPath)", "ZIP existiert nicht:\n" .. zip_path)
    return
  end

  msg("Using ZIP: " .. zip_path)

  local extracted_dir = join_path(tmp_root, "extracted")

  if is_windows() then
    run_cmd('rmdir /S /Q "' .. extracted_dir .. '"')
  else
    run_cmd('rm -rf "' .. extracted_dir .. '"')
  end
  ensure_dir(extracted_dir)

  local ok_unzip, err_unzip = unzip(zip_path, extracted_dir)
  if not ok_unzip then
    alert("IFLS Installer (RealPath)", "Unzip fehlgeschlagen:\n" .. tostring(err_unzip))
    return
  end

  msg("Unzip done, suche Repo-Root...")
  local repo_root = find_repo_root(extracted_dir)
  msg("Repo-Root erkannt als: " .. repo_root)

  local function copy_if_exists(rel)
    local src = join_path(repo_root, rel)
    if path_exists(src) then
      local dst = join_path(REAL_RESOURCE_PATH, rel)
      msg("Copy tree: " .. src .. " -> " .. dst)
      copy_tree(src, dst)
    else
      msg("[INFO] skip missing folder: " .. src)
    end
  end

  copy_if_exists("Scripts")
  copy_if_exists("Effects")
  copy_if_exists("Support")

  alert("IFLS Installer (RealPath)",
        "Installation/Aktualisierung abgeschlossen.\n\n" ..
        "Resource Path:\n" .. REAL_RESOURCE_PATH .. "\n\n" ..
        "Du kannst jetzt den integrierten Self-Test starten.")

  local choice = reaper.ShowMessageBox(
    "Möchtest du jetzt den integrierten IFLS/DF95 Self-Test ausführen?\n\n" ..
    "(Scannt IfeelLikeSnow Skripte/JSFX unter dem festen Resource Path)",
    "IFLS Self-Test (DF95/IFLS, dynamic ResourcePath)",
    4
  )
  if choice == 6 then
    self_test()
  else
    msg("Self-Test übersprungen.")
  end
end

--------------------------------------------------
-- Main
--------------------------------------------------

local function main()
  reaper.ShowConsoleMsg("")
  msg("=== DF95 IFLS Repo Installer (Dynamic ResourcePath + SelfTest) ===")
  msg("Resource Path: " .. REAL_RESOURCE_PATH)

  local mode = reaper.ShowMessageBox(
    "IFLS / DF95 Installer (DF95/IFLS, dynamischer ResourcePath)\n\n" ..
    "Aktueller REAPER Resource Path (reaper.GetResourcePath):\n" .. REAL_RESOURCE_PATH .. "\n\n" ..
    "YES   = Installieren/Aktualisieren (von ZIP)\n" ..
    "NO    = Deinstallieren (Uninstall)\n" ..
    "CANCEL= Abbrechen",
    "IFLS / DF95 – Install / Uninstall (RealPath)",
    3
  )

  if mode == 2 then
    msg("Abgebrochen.")
    return
  elseif mode == 6 then
    do_install()
  else
    local confirm = reaper.ShowMessageBox(
      "WARNUNG:\n\n" ..
      "Dies wird IFLS/DF95 Strukturen unter folgendem Pfad entfernen:\n" ..
      REAL_RESOURCE_PATH .. "\n\n" ..
      "Fortfahren?",
      "IFLS Uninstall (RealPath) – Bist du sicher?",
      1
    )
    if confirm == 1 then
      do_uninstall()
    else
      msg("Uninstall abgebrochen.")
    end
  end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("IFLS / DF95 Repo – Installer + Uninstaller + SelfTest (Dynamic ResourcePath)", -1)
