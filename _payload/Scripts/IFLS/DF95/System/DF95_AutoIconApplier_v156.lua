
-- @description Auto Icon Applier (v1.56)
-- @version 1.0
-- @about Liest DF95_IconMap_v156.json und schreibt Icon-Zeilen in alle DF95 *.ReaperMenuSet Dateien.
-- Hinweis: Danach im REAPER-Dialog "Customize menus/toolbars" die betroffenen Toolbars re-importieren.
-- Sicher: erzeugt zuerst *.backup Dateien.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()

local function readall(p)
  local f = io.open(p,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end
local function writeall(p, s)
  local f = io.open(p,"wb"); if not f then return false end
  f:write(s); f:close(); return true
end

-- Mapping laden
local map_fn = res..sep.."Data"..sep.."DF95"..sep.."DF95_IconMap_v156.json"
local raw = readall(map_fn)
if not raw then r.ShowMessageBox("IconMap nicht gefunden:\n"..map_fn, "DF95 Auto Icons", 0) return end
if not r.JSON_Decode then r.ShowMessageBox("JSON-API fehlt (REAPER 6.82+).", "DF95 Auto Icons", 0) return end
local icon_map = r.JSON_Decode(raw)

-- Menüs suchen
local menus = {
  res..sep.."Menus"..sep.."DF95_MainToolbar_FlowErgo_Pro.ReaperMenuSet",
  res..sep.."Menus"..sep.."DF95_CoToolbar_Context.ReaperMenuSet",
  res..sep.."Menus"..sep.."DF95_MicToolbar_Input.ReaperMenuSet",
  res..sep.."Menus"..sep.."DF95_EditToolbar_Arrange.ReaperMenuSet",
  res..sep.."Menus"..sep.."DF95_QA_Toolbar_Safety.ReaperMenuSet"
}

-- Einfache Parser/Writer: nach dem SCRIPT:-Block eines Items eine ICON:-Zeile ergänzen.
local function apply_icons_to_text(txt)
  local out = {}
  local changed = false
  local lines = {}
  for line in txt:gmatch("([^\r\n]*)\r?\n") do lines[#lines+1] = line end

  local i = 1
  while i <= #lines do
    local line = lines[i]
    local label = line:match("^Item%d+%s*=%s*Custom:%s*(.+)$")
    if label then
      -- nächster Eintrag sollte SCRIPT sein
      local j = i + 1
      while j <= #lines and not lines[j]:match("^%s*SCRIPT:") do
        table.insert(out, lines[j-1])
        i = i + 1
        j = j + 1
      end
      -- schreibe die Item-Zeile
      table.insert(out, line)
      if j <= #lines and lines[j]:match("^%s*SCRIPT:") then
        table.insert(out, lines[j]) -- SCRIPT behalten
        -- ggf. existierende ICON-Zeile überspringen
        if j+1 <= #lines and lines[j+1]:match("^%s*ICON:") then
          j = j + 1 -- die alte ICON-Zeile wird nicht in 'out' übernommen
        end
        local icon_rel = icon_map[label]
        if icon_rel and icon_rel ~= "" then
          table.insert(out, "\tICON: "..icon_rel)
          changed = true
        end
        i = j + 1
      else
        i = j
      end
    else
      table.insert(out, line)
      i = i + 1
    end
  end

  return table.concat(out, "\n").."\n", changed
end

local applied = {}
for _, mf in ipairs(menus) do
  local txt = readall(mf)
  if txt then
    local patched, changed = apply_icons_to_text(txt)
    if changed then
      writeall(mf..".backup", txt)
      writeall(mf, patched)
      table.insert(applied, mf)
    end
  end
end

if #applied > 0 then
  r.ShowMessageBox("Icons zugewiesen für:\n"..table.concat(applied, "\n")..
    "\n\nImportiere die Toolbars erneut über:\nOptions → Customize menus/toolbars → Import",
    "DF95 Auto Icons", 0)
else
  r.ShowMessageBox("Keine Änderungen vorgenommen (evtl. bereits zugewiesen).", "DF95 Auto Icons", 0)
end
