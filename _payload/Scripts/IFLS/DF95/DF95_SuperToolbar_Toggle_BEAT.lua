\
-- @description DF95 SuperToolbar Toggle BEAT
-- @version 1.0
-- @author DF95
-- @about
--   Schaltet die zugehörige DF95 SuperToolbar-Subtoolbar ein/aus
--   und ordnet alle aktiven Subtoolbars in definierter Reihenfolge von oben nach unten.
--
--   HINWEIS:
--   Du musst im MODE_TOOLBAR_CMD-Table unten einmalig die Command-IDs
--   für "Toolbar: Show toolbar X at top of main window" eintragen.
--
--   Vorgehen:
--     * In REAPER: Actions -> Show action list...
--     * Nach "Toolbar: Show toolbar" suchen
--     * Die passende Toolbar-Nummer für den Modus auswählen (z.B. Toolbar 20 für SESSION)
--     * Die Command ID (z.B. 41110) kopieren und unten eintragen.

local r = reaper

local MODE_NAME = "BEAT"

-- HIER Toolbar-Command-IDs eintragen:
-- Beispiel: SESSION benutzt Toolbar 20, deren Show-Command hat ID 41110
local MODE_TOOLBAR_CMD = {
  SESSION   = 0, -- TODO: Command ID für "Show toolbar X (SESSION)" eintragen
  FIELDREC  = 0, -- TODO
  BEAT      = 0, -- TODO
  SOUND     = 0, -- TODO
  DRONES    = 0, -- TODO
  LIBEXPORT = 0, -- TODO
  AISEARCH  = 0, -- TODO
  SETUPQA   = 0, -- TODO
}

-- Reihenfolge von oben nach unten
local PRIORITY = {
  "SESSION",
  "FIELDREC",
  "BEAT",
  "SOUND",
  "DRONES",
  "LIBEXPORT",
  "AISEARCH",
  "SETUPQA",
}

local EXT_SECTION = "DF95_SUPERTOOLBAR"
local EXT_KEY     = "ACTIVE_MODES"

local function split_csv(str)
  local t = {}
  for part in string.gmatch(str or "", "([^,]+)") do
    t[#t+1] = part
  end
  return t
end

local function join_csv(t)
  return table.concat(t, ",")
end

local function load_active_modes()
  local s = r.GetExtState(EXT_SECTION, EXT_KEY)
  if not s or s == "" then return {} end
  return split_csv(s)
end

local function save_active_modes(list)
  r.SetExtState(EXT_SECTION, EXT_KEY, join_csv(list), true)
end

local function contains(list, value)
  for i,v in ipairs(list) do
    if v == value then return true, i end
  end
  return false, nil
end

local function ensure_toolbar_off(cmd)
  if cmd == 0 then return end
  -- Wenn Toolbar aktuell sichtbar ist, schalten wir sie aus.
  local state = r.GetToggleCommandState(cmd)
  if state == 1 then
    r.Main_OnCommand(cmd, 0)
  end
end

local function ensure_toolbar_on(cmd)
  if cmd == 0 then return end
  local state = r.GetToggleCommandState(cmd)
  if state == 0 then
    r.Main_OnCommand(cmd, 0)
  end
end

local function apply_layout(active)
  local active_set = {}
  for _,m in ipairs(active) do
    active_set[m] = true
  end

  -- Zuerst alle relevanten Toolbars ausschalten
  for mode, cmd in pairs(MODE_TOOLBAR_CMD) do
    ensure_toolbar_off(cmd)
  end

  -- Dann in PRIORITY-Reihenfolge alle aktiven einschalten
  for _,mode in ipairs(PRIORITY) do
    if active_set[mode] then
      local cmd = MODE_TOOLBAR_CMD[mode]
      ensure_toolbar_on(cmd)
    end
  end
end

local function main()
  local active = load_active_modes()
  local has, idx = contains(active, MODE_NAME)
  if has then
    table.remove(active, idx)
  else
    active[#active+1] = MODE_NAME
  end
  save_active_modes(active)
  apply_layout(active)
end

main()
