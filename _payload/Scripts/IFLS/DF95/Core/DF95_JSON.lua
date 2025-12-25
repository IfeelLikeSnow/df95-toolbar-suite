-- DF95_JSON.lua
-- Lightweight JSON Encode/Decode für DF95
-- Version: 1.0

local JSON = {}

local function is_array(t)
  if type(t) ~= "table" then return false end
  local maxIndex = 0
  local count = 0
  for k, _ in pairs(t) do
    if type(k) == "number" and k > 0 and math.floor(k) == k then
      if k > maxIndex then maxIndex = k end
      count = count + 1
    else
      return false
    end
  end
  return maxIndex == count
end

local function escape_str(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub("\"", "\\\"")
  s = s:gsub("\b", "\\b")
  s = s:gsub("\f", "\\f")
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\t", "\\t")
  return s
end

local function encode_value(v)
  local tv = type(v)
  if tv == "nil" then
    return "null"
  elseif tv == "boolean" then
    return v and "true" or "false"
  elseif tv == "number" then
    return tostring(v)
  elseif tv == "string" then
    return "\"" .. escape_str(v) .. "\""
  elseif tv == "table" then
    if is_array(v) then
      local parts = {}
      for i = 1, #v do
        parts[#parts+1] = encode_value(v[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      local parts = {}
      for k, val in pairs(v) do
        if type(k) ~= "string" then
          error("JSON encode: object keys must be strings")
        end
        parts[#parts+1] = "\"" .. escape_str(k) .. "\":" .. encode_value(val)
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  else
    error("JSON encode: unsupported type " .. tv)
  end
end

function JSON.encode(tbl)
  return encode_value(tbl)
end

local function create_reader(s)
  return { s = s, i = 1, len = #s }
end

local function peek(r)
  return r.s:sub(r.i, r.i)
end

local function next_char(r)
  local ch = r.s:sub(r.i, r.i)
  r.i = r.i + 1
  return ch
end

local function skip_ws(r)
  while r.i <= r.len do
    local c = r.s:sub(r.i, r.i)
    if c == " " or c == "\n" or c == "\r" or c == "\t" then
      r.i = r.i + 1
    else
      break
    end
  end
end

local function parse_value(r)
  skip_ws(r)
  local c = peek(r)

  if c == "{" then
    next_char(r)
    local obj = {}
    skip_ws(r)
    if peek(r) == "}" then
      next_char(r)
      return obj
    end
    while true do
      skip_ws(r)
      if peek(r) ~= "\"" then
        error("JSON decode error: expected string key")
      end
      local key = nil
      do
        next_char(r)
        local buf = {}
        while r.i <= r.len do
          local ch = next_char(r)
          if ch == "\"" then
            break
          elseif ch == "\\" then
            local esc = next_char(r)
            if esc == "n" then buf[#buf+1] = "\n"
            elseif esc == "r" then buf[#buf+1] = "\r"
            elseif esc == "t" then buf[#buf+1] = "\t"
            elseif esc == "b" then buf[#buf+1] = "\b"
            elseif esc == "f" then buf[#buf+1] = "\f"
            elseif esc == "\\" then buf[#buf+1] = "\\"
            elseif esc == "\"" then buf[#buf+1] = "\""
            else
              buf[#buf+1] = esc
            end
          else
            buf[#buf+1] = ch
          end
        end
        key = table.concat(buf)
      end
      skip_ws(r)
      if next_char(r) ~= ":" then
        error("JSON decode error: expected ':' after key")
      end
      local val = parse_value(r)
      obj[key] = val
      skip_ws(r)
      local sep = peek(r)
      if sep == "}" then
        next_char(r)
        break
      elseif sep == "," then
        next_char(r)
      else
        error("JSON decode error: expected ',' or '}' in object")
      end
    end
    return obj

  elseif c == "[" then
    next_char(r)
    local arr = {}
    skip_ws(r)
    if peek(r) == "]" then
      next_char(r)
      return arr
    end
    local idx = 1
    while true do
      arr[idx] = parse_value(r)
      idx = idx + 1
      skip_ws(r)
      local sep = peek(r)
      if sep == "]" then
        next_char(r)
        break
      elseif sep == "," then
        next_char(r)
      else
        error("JSON decode error: expected ',' or ']' in array")
      end
    end
    return arr

  elseif c == "\"" then
    next_char(r)
    local buf = {}
    while r.i <= r.len do
      local ch = next_char(r)
      if ch == "\"" then
        break
      elseif ch == "\\" then
        local esc = next_char(r)
        if esc == "n" then buf[#buf+1] = "\n"
        elseif esc == "r" then buf[#buf+1] = "\r"
        elseif esc == "t" then buf[#buf+1] = "\t"
        elseif esc == "b" then buf[#buf+1] = "\b"
        elseif esc == "f" then buf[#buf+1] = "\f"
        elseif esc == "\\" then buf[#buf+1] = "\\"
        elseif esc == "\"" then buf[#buf+1] = "\""
        else
          buf[#buf+1] = esc
        end
      else
        buf[#buf+1] = ch
      end
    end
    return table.concat(buf)

  elseif c == "t" then
    local sub = r.s:sub(r.i, r.i+3)
    if sub ~= "true" then error("JSON decode error: expected 'true'") end
    r.i = r.i + 4
    return true

  elseif c == "f" then
    local sub = r.s:sub(r.i, r.i+4)
    if sub ~= "false" then error("JSON decode error: expected 'false'") end
    r.i = r.i + 5
    return false

  elseif c == "n" then
    local sub = r.s:sub(r.i, r.i+3)
    if sub ~= "null" then error("JSON decode error: expected 'null'") end
    r.i = r.i + 4
    return nil

  else
    local start_i = r.i
    while r.i <= r.len do
      local ch = r.s:sub(r.i, r.i)
      if ch:match("[%d%+%-%e%E%.]") then
        r.i = r.i + 1
      else
        break
      end
    end
    local num_str = r.s:sub(start_i, r.i-1)
    local num_val = tonumber(num_str)
    if not num_val then
      error("JSON decode error: invalid number '" .. num_str .. "'")
    end
    return num_val
  end
end

function JSON.decode(str)
  if type(str) ~= "string" then
    return nil, "JSON decode: input is not a string"
  end
  local reader = create_reader(str)
  local ok, result = pcall(parse_value, reader)
  if not ok then
    return nil, result
  end
  return result
end

function JSON.save_table_to_file(path, tbl)
  local ok, encoded = pcall(JSON.encode, tbl)
  if not ok then
    return false, encoded
  end
  local f, err = io.open(path, "w")
  if not f then
    return false, err
  end
  f:write(encoded)
  f:close()
  return true
end

function JSON.load_table_from_file(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, err
  end
  local content = f:read("*a")
  f:close()
  return JSON.decode(content)
end

return JSON
