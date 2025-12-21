-- @description FXChain Repair Auto (fix alias names, optional replacements)
-- @version 1.0
-- @author DF95
-- @about
--   Scans FXChains/DF95 for .RfxChain files, compares FX display names
--   against installed plugins (reaper-vstplugins64.ini, reaper-jsfx.ini),
--   and:
--     - auto-fixes alias / mismatched names if a unique match is found
--     - optionally applies fallback replacements for certain missing plugins
--   Creates backups (.bak) and a detailed log in DF95/Reports.

local r = reaper

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function msg(m) r.ShowConsoleMsg(tostring(m) .. "\n") end

local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local DF95_root    = res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep
local chains_root  = res .. sep .. "FXChains" .. sep .. "DF95" .. sep
local report_dir   = DF95_root .. "Reports" .. sep

-- ensure report dir
local ok = r.RecursiveCreateDirectory(report_dir, 0)

local log_path = report_dir .. "DF95_FXChain_RepairAuto_Log.txt"
local log = {}
local function logln(line) log[#log+1] = line end

------------------------------------------------------------
-- Load VST DB from reaper-vstplugins64.ini
------------------------------------------------------------
local function load_vst_db()
  local path = res .. sep .. "reaper-vstplugins64.ini"
  local f = io.open(path, "r")
  if not f then
    msg("Could not open reaper-vstplugins64.ini")
    return {}, {}
  end
  local db = {}
  local list = {}
  for line in f:lines() do
    -- format: dll=hex,hex,Display Name
    local name = line:match(",([^,]+)%s*$")
    if name then
      db[name] = true
      list[#list+1] = name
    end
  end
  f:close()
  return db, list
end

------------------------------------------------------------
-- Load JSFX DB
------------------------------------------------------------
local function load_js_db()
  local path = res .. sep .. "reaper-jsfx.ini"
  local f = io.open(path, "r")
  if not f then
    msg("Could not open reaper-jsfx.ini")
    return {}, {}
  end
  local db = {}
  local list = {}
  for line in f:lines() do
    local name = line:match('NAME.-"(.-)"')
    if name then
      db[name] = true
      list[#list+1] = name
    end
  end
  f:close()
  return db, list
end

local vst_db, vst_list = load_vst_db()
local js_db,  js_list  = load_js_db()

------------------------------------------------------------
-- Replacement / Fallback map for truly missing plugins
------------------------------------------------------------
-- Keys are *short* names (after the colon), e.g. "ShaperBox 3"
-- Values are full display names as they should appear in the chain,
-- and must be present in vst_db to be applied.
local replacements = {
  ["ShaperBox 3"] = "kHs Shaper (Kilohearts)",
  ["Decimort"]    = "Krush (Tritik)",
  ["SSQ"]         = "BritChannel (AnalogObsession)",
  ["BUSTERse"]    = "LALA (AnalogObsession)",
  ["N492ME"]      = "Rare (AnalogObsession)",
  -- For Argotlunar: prefer any vst_db name containing "Argotlunar"
  ["Argotlunar"]  = "<AUTO_VST2_ARGOTLUNAR>"
}

------------------------------------------------------------
-- Helpers: matching and alias resolution
------------------------------------------------------------

local function find_vst_exact(name)
  return vst_db[name] or false
end

local function find_vst_partial(short)
  local short_l = short:lower()
  local best = nil
  local count = 0
  for _,name in ipairs(vst_list) do
    if name:lower():find(short_l, 1, true) then
      best = name
      count = count + 1
      if count > 1 then
        return nil, 0  -- ambiguous
      end
    end
  end
  if count == 1 then
    return best, 1
  end
  return nil, 0
end

local function find_js_exact(name)
  return js_db[name] or false
end

------------------------------------------------------------
-- Parse / rewrite FX lines
------------------------------------------------------------

local function parse_label(line)
  -- VST-like: <VST "VST3: Smooth Operator (BABY Audio)" ...
  local prefix, label = line:match('^<%s*(VST3?)%s+"([^"]+)"')
  if prefix and label then
    -- label might be "VST3: Smooth Operator", or already "VST3: Smooth Operator (BABY Audio)"
    -- we treat label as-is for comparison; we also derive a short name for matching
    local short = label:match(":%s*(.+)$") or label
    return "VST", prefix, label, short
  end

  -- JSFX: <JS "JS: Volume Adjustment"
  local js_label = line:match('^<%s*JS%s+"([^"]+)"')
  if js_label then
    local short = js_label:match(":%s*(.+)$") or js_label
    return "JS", "JS", js_label, short
  end

  return nil
end

local function build_vst_label(prefix, display)
  -- prefix = "VST" or "VST3"
  -- display = something like "Smooth Operator (BABY Audio)"
  return prefix .. ": " .. display
end

local function build_js_label(display)
  -- display = "JS: Volume Adjustment" or just "Volume Adjustment"
  if display:match("^JS:") then return display end
  return "JS: " .. display
end

------------------------------------------------------------
-- Process single FX label
------------------------------------------------------------
local function repair_label(fxtype, prefix, label, short)
  -- fxtype: "VST" or "JS"
  -- prefix: for VST = "VST" or "VST3"; for JS = "JS"
  -- label: full current label inside quotes
  -- short: text after colon (if any), stripped

  -- First: if exact installed, keep
  if fxtype == "VST" then
    if find_vst_exact(label) then
      return label, "ok"
    end
  elseif fxtype == "JS" then
    if find_js_exact(label) then
      return label, "ok"
    end
  end

  -- Try alias via partial match in VST DB (for VST only)
  if fxtype == "VST" then
    local best, count = find_vst_partial(short)
    if best and count == 1 then
      local new_label = build_vst_label(prefix, best)
      if new_label ~= label then
        return new_label, "alias:" .. best
      end
    end
  end

  -- Fallback replacements (only if we *know* this short name is suspect)
  local repl = replacements[short]
  if repl then
    if repl == "<AUTO_VST2_ARGOTLUNAR>" then
      -- look for any VST that has "argotlunar" in name
      local best, count = find_vst_partial("argotlunar")
      if best and count == 1 then
        local new_label = build_vst_label("VST", best)
        if new_label ~= label then
          return new_label, "repl:" .. best
        end
      else
        return label, "missing:Argotlunar"
      end
    else
      -- check if replacement exists in vst_db
      if find_vst_exact(repl) then
        local new_label = build_vst_label(prefix, repl)
        if new_label ~= label then
          return new_label, "repl:" .. repl
        end
      else
        return label, "missing_repl:" .. repl
      end
    end
  end

  -- No change
  return label, "unresolved"
end

------------------------------------------------------------
-- Scan a single .RfxChain file and rewrite if needed
------------------------------------------------------------
local function process_chain_file(path)
  local f = io.open(path, "r")
  if not f then return false end

  local lines = {}
  for line in f:lines() do lines[#lines+1] = line end
  f:close()

  local changed = false
  local file_changes = {}

  for i,line in ipairs(lines) do
    local fxtype, prefix, label, short = parse_label(line)
    if fxtype then
      local new_label, status = repair_label(fxtype, prefix, label, short)
      if new_label ~= label then
        -- Replace only the label part inside quotes
        local escaped_label = label:gsub("([^%w])", "%%%1")
        local repl = new_label:gsub("%%","%%%%")
        local new_line = line:gsub(escaped_label, repl, 1)
        if new_line ~= line then
          lines[i] = new_line
          changed = true
          file_changes[#file_changes+1] = string.format("  FX '%s' -> '%s' (%s)", label, new_label, status)
        end
      else
        if status ~= "ok" and status ~= "unresolved" then
          file_changes[#file_changes+1] = string.format("  FX '%s' status: %s (no label change)", label, status)
        end
      end
    end
  end

  if changed then
    -- backup
    local bak_path = path .. ".bak"
    -- only create backup once
    local bk = io.open(bak_path, "r")
    if not bk then
      local orig = io.open(path, "r")
      if orig then
        local bak = io.open(bak_path, "w")
        if bak then
          bak:write(orig:read("*a"))
          bak:close()
        end
        orig:close()
      end
    else
      bk:close()
    end

    -- write new file
    local out = io.open(path, "w")
    out:write(table.concat(lines, "\n"))
    out:close()

    logln("FILE: " .. path)
    for _,c in ipairs(file_changes) do logln(c) end
    logln("")
  end

  return changed
end

------------------------------------------------------------
-- Recursively scan FXChains/DF95
------------------------------------------------------------
local function scan_dir(root)
  local changed_files = 0

  local function recurse(path)
    -- files
    local i = 0
    while true do
      local fn = r.EnumerateFiles(path, i)
      if not fn then break end
      i = i + 1
      if fn:lower():match("%.rfxchain$") then
        local full = path .. sep .. fn
        local ok = process_chain_file(full)
        if ok then changed_files = changed_files + 1 end
      end
    end

    -- subdirs
    local j = 0
    while true do
      local dn = r.EnumerateSubdirectories(path, j)
      if not dn then break end
      j = j + 1
      recurse(path .. sep .. dn)
    end
  end

  recurse(root)
  return changed_files
end

------------------------------------------------------------
-- Main
------------------------------------------------------------
local function main()
  if not vst_list or #vst_list == 0 then
    r.ShowMessageBox("No VST entries loaded from reaper-vstplugins64.ini.\nAborting.", "DF95 FXChain Repair Auto", 0)
    return
  end

  logln("DF95 FXChain Repair Auto Log")
  logln("Generated: " .. os.date())
  logln("FXChains root: " .. chains_root)
  logln("")

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  local changed = scan_dir(chains_root)

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock(string.format("[DF95] FXChain Auto Repair (%d files modified)", changed), -1)

  logln(string.format("Total modified files: %d", changed))

  local f = io.open(log_path, "w")
  f:write(table.concat(log, "\n"))
  f:close()

  r.ShowMessageBox(
    string.format("DF95 FXChain Auto Repair completed.\nModified files: %d\n\nLog written to:\n%s", changed, log_path),
    "DF95 FXChain Repair Auto", 0
  )
end

main()
