
-- DF95_StartupCheck.lua
-- Optional startup health-check for DF95.
--
-- Intended usage:
--   - Either call this from your global __startup.lua
--   - Or rename this file to __startup.lua if you want
--     DF95 to manage your startup script (only recommended
--     if you don't already use __startup.lua).
--
-- Behavior:
--   - Runs a lightweight DF95 health-check using
--     DF95_Diagnostics_Lib_SelfTest.lua
--   - If everything looks fine: exits silently.
--   - If core files are missing: shows a dialog offering to
--     run the full-repo self-test, ignore warnings for 24h, or cancel.

local SECTION = "DF95_StartupCheck"

-- Helper: get DF95 lib paths
local function get_df95_paths()
  local resource = reaper.GetResourcePath()
  local root = resource .. "/Scripts/DF95"
  return {
    resource_root = resource,
    df95_root = root,
    lib_root = root .. "/Lib",
    tools_root = root .. "/Tools",
    diagnostics_root = root .. "/Diagnostics",
  }
end

-- Try to load diagnostics library
local function load_selftest_lib()
  local paths = get_df95_paths()
  local lib_path = paths.lib_root .. "/DF95_Diagnostics_Lib_SelfTest.lua"
  local ok, mod = pcall(dofile, lib_path)
  if not ok then
    return nil, "Failed to load DF95_Diagnostics_Lib_SelfTest.lua: " .. tostring(mod)
  end
  return mod, nil
end

-- Check whether we should skip (user chose "ignore for 24h")
local function should_skip_now()
  local val = reaper.GetExtState(SECTION, "ignore_until")
  if val == nil or val == "" then return false end
  local ts = tonumber(val) or 0
  local now = os.time()
  if now < ts then return true end
  return false
end

local function set_ignore_for_24h()
  local now = os.time()
  local future = now + 24 * 60 * 60
  reaper.SetExtState(SECTION, "ignore_until", tostring(future), true)
end

local function clear_ignore()
  reaper.SetExtState(SECTION, "ignore_until", "", true)
end

local function set_last_status(ok, msg)
  reaper.SetExtState(SECTION, "last_status_ok", ok and "1" or "0", true)
  reaper.SetExtState(SECTION, "last_status_msg", msg or "", true)
end

-- Run lightweight check and act on result
local function main()
  if should_skip_now() then
    return
  end

  local selftest, err = load_selftest_lib()
  if not selftest then
    -- If we can't even load the library, we log extstate and stop to avoid user spam.
    set_last_status(false, err or "Unknown error loading selftest lib")
    return
  end

  local ok, res = selftest.run_light_healthcheck()
  if ok then
    set_last_status(true, "DF95 startup check: OK")
    clear_ignore()
    return
  end

  -- Something is wrong: build a message
  local details = ""
  if res and res.core_file_errors and #res.core_file_errors > 0 then
    details = table.concat(res.core_file_errors, "\n")
  else
    details = "Unknown problem in DF95 health check."
  end

  local msg = "DF95 Startup Check hat mögliche Probleme erkannt.\n\n"
    .. "Details:\n" .. details .. "\n\n"
    .. "Möchtest du jetzt den vollständigen DF95 Self-Test ausführen?\n\n"
    .. "Hinweis: Du kannst Warnungen für 24 Stunden ignorieren."

  -- 3 = MB_YESNOCANCEL
  local ret = reaper.ShowMessageBox(msg, "DF95 Startup Check", 3)
  -- ret: 6 = Yes, 7 = No, 2 = Cancel
  if ret == 6 then
    -- Yes: run full self-test
    set_last_status(false, "Full self-test requested from startup check")
    clear_ignore()

    -- Adjust this path to match the actual location of your full-repo self-test script
    local paths = get_df95_paths()
    local full_selftest_path = paths.diagnostics_root .. "/DF95_Diagnostics_SelfTest_FullRepo_RealPath.lua"

    local ok2, err2 = pcall(dofile, full_selftest_path)
    if not ok2 then
      reaper.ShowMessageBox(
        "Fehler beim Ausführen des vollständigen DF95 Self-Tests:\n\n"
          .. tostring(err2)
          .. "\n\nBitte prüfe, ob der Pfad korrekt ist:\n"
          .. full_selftest_path,
        "DF95 Startup Check – Fehler",
        0
      )
    end
  elseif ret == 7 then
    -- No: ignore for 24h
    set_ignore_for_24h()
    set_last_status(false, "User chose to ignore DF95 startup warnings for 24h")
  else
    -- Cancel: do nothing special
    set_last_status(false, "User cancelled DF95 startup warning dialog")
  end
end

main()
