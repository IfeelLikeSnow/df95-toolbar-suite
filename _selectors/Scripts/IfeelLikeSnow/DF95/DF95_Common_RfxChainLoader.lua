
-- DF95 Common: apply .rfxchain to a track by chunk replace/append
local r = reaper

local function read_file(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

local function write_chunk_fxchain(track, rfx_text, append)
  -- Get current track chunk
  local _, chunk = r.GetTrackStateChunk(track, "", true)
  if not _ then return false, "Cannot read track chunk" end

  -- Ensure RFX text contains <FXCHAIN ...> ... block
  if not rfx_text:find("<FXCHAIN") then
    return false, ".rfxchain missing <FXCHAIN> block"
  end

  if append then
    -- Append by merging: extract inner of <FXCHAIN> from rfx_text and append into existing FXCHAIN
    local cur_fx = chunk:match("(<FXCHAIN.-</FXCHAIN>)")
    if not cur_fx then
      -- no current FXCHAIN: just insert whole rfx_text replacing empty slot
      chunk = chunk:gsub("(<TRACK.-)>", "%1\n"..rfx_text.."\n>", 1)
    else
      local head = chunk:sub(1, chunk:find("<FXCHAIN")-1)
      local tail = chunk:sub(chunk:find("</FXCHAIN>")+10)
      local inner_new = rfx_text:gsub("^.-<FXCHAIN", "<FXCHAIN"):gsub("</FXCHAIN>.-$", "</FXCHAIN>")
      -- naive append: concatenate inner bodies (keeps settings order)
      local inner_cur_body = cur_fx:gsub("^<FXCHAIN", ""):gsub("</FXCHAIN>$","")
      local merged = "<FXCHAIN"..inner_cur_body..inner_new:gsub("^<FXCHAIN",""):gsub("</FXCHAIN>$","").."</FXCHAIN>"
      chunk = head .. merged .. tail
    end
  else
    -- Replace entire FXCHAIN block (or insert if missing)
    if chunk:find("<FXCHAIN") then
      chunk = chunk:gsub("<FXCHAIN.-</FXCHAIN>", rfx_text, 1)
    else
      chunk = chunk:gsub("(<TRACK.-)>", "%1\n"..rfx_text.."\n>", 1)
    end
  end

  local ok = r.SetTrackStateChunk(track, chunk, true)
  return ok, ok and "" or "SetTrackStateChunk failed"
end

local function ensure_track_named(name)
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

local function resource_path()
  return r.GetResourcePath()
end

local function chains_root(sub)
  return resource_path() .. package.config:sub(1,1) .. "Chains" .. package.config:sub(1,1) .. (sub or "")
end

return {
  read_file = read_file,
  write_chunk_fxchain = write_chunk_fxchain,
  ensure_track_named = ensure_track_named,
  chains_root = chains_root,
  resource_path = resource_path
}
