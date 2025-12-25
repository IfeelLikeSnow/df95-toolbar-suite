
-- @description Slicing Menu (ZeroCross, Fade Shapes, Categories)
-- @version 1.1
local r = reaper
local function menu(str) local _,_,x,y=r.GetMousePosition(); gfx.init("DF95_Slicing",1,1,0,x,y); local s=gfx.showmenu(str); gfx.quit(); return s end
local parts = {
  ">Presets","IDM – Tight","IDM – Classic","Generative – Loose","Glitch – Micro","<|",
  ">ZeroCross","Respect Zero-Cross (On)","Respect Zero-Cross (Off)","<|",
  ">Fade Shapes","Linear","Slow","Fast","<|Apply Now"
}
local choice = menu(table.concat(parts,"|")); if choice<=0 then return end
local label_idx, idx = nil, 0; for token in (table.concat(parts,"|").. "|"):gmatch("([^|]+)|") do
  if not (token:sub(1,1)==">" or token:sub(-1)=="<") then idx=idx+1; if idx==choice then label_idx=token; break end end
end
if not label_idx then return end
if label_idx=="Respect Zero-Cross (On)" then reaper.SetProjExtState(0,"DF95_SLICE","ZEROX","1")
elseif label_idx=="Respect Zero-Cross (Off)" then reaper.SetProjExtState(0,"DF95_SLICE","ZEROX","0")
elseif label_idx=="Linear" or label_idx=="Slow" or label_idx=="Fast" then reaper.SetProjExtState(0,"DF95_SLICE","FADE",label_idx)
elseif label_idx=="Apply Now" then
  reaper.ShowConsoleMsg("[DF95] Slicing: Apply with ZEROX="..(select(2,reaper.GetProjExtState(0,"DF95_SLICE","ZEROX")) or "?")..", FADE="..(select(2,reaper.GetProjExtState(0,"DF95_SLICE","FADE")) or "?").."\n")
else
  reaper.SetProjExtState(0,"DF95_SLICE","PRESET",label_idx)
  reaper.ShowConsoleMsg("[DF95] Slicing preset set: "..label_idx.."\n")
end
