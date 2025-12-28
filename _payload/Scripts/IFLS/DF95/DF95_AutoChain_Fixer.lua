
-- DF95_AutoChain_Fixer.lua
-- Automatic Mic Chain Name Normalizer (V68-safe)

local r = reaper
package.path = package.path .. ";../?.lua"

local ok, tagger = pcall(dofile, "DF95_Auto_MicTagger.lua")
if not ok or type(tagger) ~= "table" then
  r.ShowMessageBox("DF95_Auto_MicTagger.lua konnte nicht geladen werden.\nAbbruch.",
                   "DF95 Auto Chain Fixer", 0)
  return
end

local APPLY   = false   -- DRY RUN by default
local VERBOSE = true

local function log(msg)
  if VERBOSE then
    r.ShowConsoleMsg(tostring(msg) .. "\n")
  end
end

local function fix_chain_name(name)
  local rec = tagger.detect_recorder(name)
  local model, pattern, ch = tagger.detect_model(name)
  return tagger.build_name(rec, model, pattern, ch)
end

local function run()
  local root = r.GetResourcePath() .. "/FXChains/DF95/Mic/"
  local i = 0
  local renames = {}

  while true do
    local f = r.EnumerateFiles(root, i)
    if not f then break end
    if f:lower():match("%.rfxchain$") then
      local new = fix_chain_name(f)
      if new ~= f then
        renames[#renames+1] = { old = f, new = new }
      end
    end
    i = i + 1
  end

  if #renames == 0 then
    r.ShowMessageBox("Keine Mic-Chains mit abweichenden Namen gefunden.\nAlles scheint konsistent.",
                     "DF95 Auto Chain Fixer", 0)
    return
  end

  log("DF95 Auto Chain Fixer – DRY RUN = " .. tostring(not APPLY))
  log("Mic Chain Root: " .. root)
  log("Gefundene Kandidaten (" .. #renames .. "):")
  for _, rn in ipairs(renames) do
    log("  OLD: " .. rn.old .. " -> NEW: " .. rn.new)
  end

  if not APPLY then
    r.ShowMessageBox("DF95 Auto Chain Fixer (DRY RUN)\n\n" ..
                     "Es wurden " .. #renames .. " Mic-Chains gefunden, die umbenannt werden könnten.\n" ..
                     "Details siehe ReaScript Console.\n\n" ..
                     "Um die Umbenennungen durchzuführen, setze APPLY = true im Script.",
                     "DF95 Auto Chain Fixer", 0)
    return
  end

  local ok_count, err_count = 0, 0
  for _, rn in ipairs(renames) do
    local old_full = root .. rn.old
    local new_full = root .. rn.new
    local ok, err = os.rename(old_full, new_full)
    if ok then ok_count = ok_count + 1
    else
      err_count = err_count + 1
      log("FEHLER: " .. tostring(err) .. " | " .. old_full .. " -> " .. new_full)
    end
  end

  r.ShowMessageBox("DF95 Auto Chain Fixer – Fertig\n\n" ..
                   "Erfolgreich umbenannt: " .. ok_count .. "\n" ..
                   "Fehler: " .. err_count .. "\n" ..
                   "Details siehe ReaScript Console.",
                   "DF95 Auto Chain Fixer", 0)
end

run()
