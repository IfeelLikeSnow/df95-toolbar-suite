-- DF95 SelfTest Result Viewer (Patched V2)
-- Liest: DF95_SelfTest_Report.txt aus Support/DF95_SelfTest

local r = reaper
local base = r.GetResourcePath()
local report_path = base .. "/Support/DF95_SelfTest/DF95_SelfTest_Report.txt"

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

if not file_exists(report_path) then
  r.ShowMessageBox("Report-Datei nicht gefunden unter:\n" .. report_path, "DF95 Result Viewer", 0)
  return
end

local content = ""
for line in io.lines(report_path) do
  content = content .. line .. "\n"
end

-- Anzeige
local w, h = 720, 480
gfx.init("DF95 SelfTest Result Viewer", w, h)
gfx.x, gfx.y = 10, 10
gfx.setfont(1, "Courier New", 16)

local lines = {}
for l in content:gmatch("([^
]*)\n?") do table.insert(lines, l) end

local line_offset = 0
local function loop()
  gfx.set(1, 1, 1)
  gfx.rect(0, 0, w, h, true)

  gfx.set(0, 0, 0)
  for i = 1, math.min(#lines - line_offset, 30) do
    gfx.x = 10
    gfx.y = 10 + (i - 1) * 16
    gfx.drawstr(lines[i + line_offset])
  end

  local char = gfx.getchar()
  if char == 65364 or char == 31 then
    line_offset = math.min(line_offset + 1, #lines - 30)
  elseif char == 65362 or char == 30 then
    line_offset = math.max(line_offset - 1, 0)
  elseif char < 0 then
    return
  end

  r.defer(loop)
end

loop()
