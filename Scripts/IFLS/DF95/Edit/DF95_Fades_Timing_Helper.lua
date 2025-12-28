-- @description Fades & Timing Helper
-- @version 1.1
-- @about Setzt Fade-Längen für ausgewählte Items über ein kleines Popup-Menü.

local r = reaper

local function set_fades(len)
  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then return end

  r.Undo_BeginBlock()
  for i = 0, cnt-1 do
    local it = r.GetSelectedMediaItem(0, i)
    r.SetMediaItemInfo_Value(it, "D_FADEINLEN", len)
    r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", len)
  end
  r.Undo_EndBlock("DF95: Fades & Timing Helper", -1)
  r.UpdateArrange()
end

local function main()
  if not (gfx and gfx.getchar) then gfx = gfx or {} end
  if not gfx.init then gfx.init("DF95", 10, 10) end

  local menu = "|DF95 Fade Presets||Short (2 ms)|Medium (10 ms)|Long (30 ms)|Remove (0 ms)|"
  local mx, my = r.GetMousePosition()
  gfx.init("DF95 Fades", 0, 0, 0, mx, my)
  local idx = gfx.showmenu(menu)
  gfx.quit()

  if idx == 0 then return end

  if idx == 2 then
    set_fades(0.002)
  elseif idx == 3 then
    set_fades(0.010)
  elseif idx == 4 then
    set_fades(0.030)
  elseif idx == 5 then
    set_fades(0.0)
  end
end

main()
