
-- DF95 Common RfxChain I/O + Discovery (with category grouping)
local r = reaper
local sep = package.config:sub(1,1)

local M = {}

function M.read_file(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

function M.write_chunk_fxchain(track, rfx_text, append)
  local ok, chunk = r.GetTrackStateChunk(track, "", true)
  if not ok then return false, "Cannot read track chunk" end
  if not rfx_text:find("<FXCHAIN") then return false, ".rfxchain missing <FXCHAIN> block" end

  if append then
    local cur_fx = chunk:match("(<FXCHAIN.-</FXCHAIN>)")
    if not cur_fx then
      chunk = chunk:gsub("(<TRACK.-)>", "%1\n"..rfx_text.."\n>", 1)
    else
      local head = chunk:sub(1, chunk:find("<FXCHAIN")-1)
      local tail = chunk:sub(chunk:find("</FXCHAIN>")+10)
      local inner_new = rfx_text:gsub("^.-<FXCHAIN", "<FXCHAIN"):gsub("</FXCHAIN>.-$", "</FXCHAIN>")
      local inner_cur_body = cur_fx:gsub("^<FXCHAIN",""):gsub("</FXCHAIN>$","")
      local merged = "<FXCHAIN"..inner_cur_body..inner_new:gsub("^<FXCHAIN",""):gsub("</FXCHAIN>$","").."</FXCHAIN>"
      chunk = head .. merged .. tail
    end
  else
    if chunk:find("<FXCHAIN") then
      chunk = chunk:gsub("<FXCHAIN.-</FXCHAIN>", rfx_text, 1)
    else
      chunk = chunk:gsub("(<TRACK.-)>", "%1\n"..rfx_text.."\n>", 1)
    end
  end

  local ok2 = r.SetTrackStateChunk(track, chunk, true)
  return ok2, ok2 and "" or "SetTrackStateChunk failed"
end

function M.ensure_track_named(name)
  for i=0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0,i)
    local _, nm = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if nm == name then return tr end
  end
  r.InsertTrackAtIndex(r.CountTracks(0), true)
  local tr = r.GetTrack(0, r.CountTracks(0)-1)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

function M.resource_path()
  return r.GetResourcePath()
end

function M.chains_root(sub)
  local base = M.resource_path() .. sep .. "Chains"
  if not sub or sub == "" then return base end
  return base .. sep .. sub
end

local function nice_name(fname)
  local n = fname:gsub("%.rfxchain$", ""):gsub("_"," "):gsub("%-"," ")
  n = n:gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
  return n
end

-- Returns a structure: { ["Category/Subcategory"] = { {label, path}, ... }, ... }
function M.list_by_category(subdir)
  local root = M.chains_root(subdir)
  local out = {}
  -- enumerate files in root
  local i = 0
  while true do
    local f = r.EnumerateFiles(root, i)
    if not f then break end
    if f:lower():match("%.rfxchain$") then
      local cat = ""  -- top level
      out[cat] = out[cat] or {}
      table.insert(out[cat], {label = nice_name(f), path = root .. sep .. f})
    end
    i = i + 1
  end
  -- enumerate subfolders one level deep
  i = 0
  while true do
    local d = r.EnumerateSubdirectories(root, i)
    if not d then break end
    local sub = root .. sep .. d
    local j = 0
    while true do
      local f = r.EnumerateFiles(sub, j)
      if not f then break end
      if f:lower():match("%.rfxchain$") then
        local cat = d
        out[cat] = out[cat] or {}
        table.insert(out[cat], {label = nice_name(f), path = sub .. sep .. f})
      end
      j = j + 1
    end
    i = i + 1
  end
  -- sort each category
  for k,v in pairs(out) do
    table.sort(v, function(a,b) return a.label:lower() < b.label:lower() end)
  end
  return out
end

return M
