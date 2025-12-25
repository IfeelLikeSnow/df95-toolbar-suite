-- @description META Helper GUI (add/edit // META: headers in .rfxchain)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Scans FXChains/DF95/** and lets you apply artist/style/color/lufs meta tags in-place.

local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = res..sep.."FXChains"..sep.."DF95"

local fields = {
  {key="artist", hint="autechre|aphex|boc|squarepusher|plaid|arovane|proem|muziq|bola|mouseonmars|janjelinek|fourtet"},
  {key="style",  hint="idm|glitch|granular|euclid|breakcore|ambient|dub"},
  {key="color",  hint="warm|clean|tape|console|air|dark|bright"},
  {key="lufs_target", hint="-16..-10"},
  {key="notes",  hint="free text (optional)"}
}

local function list_chains(root)
  local t = {}
  local stack = {root}
  while #stack>0 do
    local dir = table.remove(stack)
    local i=0
    while true do
      local sub = r.EnumerateSubdirectories(dir, i)
      if not sub then break end
      stack[#stack+1] = dir..sep..sub
      i=i+1
    end
    local j=0
    while true do
      local fn = r.EnumerateFiles(dir, j)
      if not fn then break end
      if fn:lower():match("%.rfxchain$") then
        t[#t+1] = dir..sep..fn
      end
      j=j+1
    end
  end
  table.sort(t)
  return t
end

local function readfile(p)
  local f = io.open(p,"rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end
local function writefile(p, s)
  local f = io.open(p,"wb"); if not f then return false end
  f:write(s); f:close(); return true
end

local chains = list_chains(base)
if #chains==0 then r.ShowMessageBox("Keine Chains unter FXChains/DF95 gefunden.","DF95 META Helper",0) return end

local W,H = 780, 420
gfx.init("DF95 META Helper", W, H)

local idx = 1
local edits = {artist="",style="",color="",lufs_target="",notes=""}

local function parse_meta(s)
  local meta = {}
  for k,v in s:gmatch("//%s*META:([%w_%-]+)%s*=%s*([^\r\n]+)") do
    meta[k] = v
  end
  return meta
end

local function inject_meta(body, m)
  local cleaned = body:gsub("//%s*META:[^\r\n]*\r?\n","")
  local header = ""
  for _,f in ipairs(fields) do
    local v = m[f.key]
    if v and v~="" then
      header = header .. ("// META:%s=%s\n"):format(f.key, v)
    end
  end
  return header .. cleaned
end

local function current_meta()
  local raw = readfile(chains[idx]) or ""
  return parse_meta(raw)
end

local function draw_label(x,y,txt) gfx.x,gfx.y=x,y; gfx.drawstr(txt) end
local function draw_edit(x,y,w,key, hint)
  gfx.rect(x-3,y-3,w+6,22,0)
  gfx.x,gfx.y=x,y
  local val = edits[key] or ""
  gfx.drawstr(val~="" and val or ("("..hint..")"))
end

local function handle_input()
  local char = gfx.getchar()
  if char == 27 then return false end
  if char == 1919379572 or char == 26161 then
    idx = math.max(1, idx-1)
  elseif char == 1919379576 or char == 26163 then
    idx = math.min(#chains, idx+1)
  elseif char == 13 then
    local m = {}
    for _,f in ipairs(fields) do m[f.key] = edits[f.key] end
    local raw = readfile(chains[idx]) or ""
    writefile(chains[idx], inject_meta(raw, m))
    r.ShowMessageBox("META gespeichert:\n"..chains[idx],"DF95 META Helper",0)
  end
  return true
end

edits = current_meta()

while true do
  if not handle_input() then break end
  gfx.set(0.1,0.1,0.12,1); gfx.rect(0,0,W,H,1)
  gfx.set(1,1,1,1)
  draw_label(16,14,("Chain %d / %d"):format(idx,#chains))
  draw_label(16,34,chains[idx]:gsub(res..sep,""))
  edits = current_meta()

  local x,y = 16,80
  for i,f in ipairs(fields) do
    draw_label(x,y, f.key..":")
    draw_edit(x+120, y-2, 580, f.key, f.hint)
    y = y + 28
  end
  draw_label(16, y+10, "ENTER = speichern  |  ←/→ = vorher/nachher  |  ESC = schließen")
  gfx.update()
  reaper.defer(function() end)
end
