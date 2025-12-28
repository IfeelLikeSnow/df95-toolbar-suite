-- DF95_Config.lua (V3)
-- Config loader with JSON overrides at: <ResourcePath>/Support/DF95_Config.json
-- - Pure Lua JSON decoder (minimal, sufficient for config)
-- - Deep-merge override table into defaults
-- - No external dependencies

local r = reaper
local M = {}

local function norm(s)
  local out = (s or ""):gsub("\\","/")
  return out
end

local function join(a,b,c,d,e)
  local parts = {a,b,c,d,e}
  local out = {}
  for _,p in ipairs(parts) do if p and p ~= "" then out[#out+1] = tostring(p) end end
  local s = table.concat(out, "/"):gsub("//+","/")
  return s
end

-- ---------- Minimal JSON decoder ----------
local function json_decode(str)
  local i, n = 1, #str

  local function skip_ws()
    while i <= n do
      local c = str:sub(i,i)
      if c == ' ' or c == '\t' or c == '\r' or c == '\n' then i = i + 1 else break end
    end
  end

  local function parse_error(msg)
    error("JSON parse error at " .. tostring(i) .. ": " .. tostring(msg))
  end

  local function parse_literal(lit, val)
    if str:sub(i, i + #lit - 1) == lit then
      i = i + #lit
      return val
    end
    parse_error("expected " .. lit)
  end

  local function parse_number()
    local s = i
    local c = str:sub(i,i)
    if c == '-' then i = i + 1 end
    while i <= n and str:sub(i,i):match("%d") do i = i + 1 end
    if i <= n and str:sub(i,i) == '.' then
      i = i + 1
      while i <= n and str:sub(i,i):match("%d") do i = i + 1 end
    end
    if i <= n and (str:sub(i,i) == 'e' or str:sub(i,i) == 'E') then
      i = i + 1
      local c2 = str:sub(i,i)
      if c2 == '+' or c2 == '-' then i = i + 1 end
      while i <= n and str:sub(i,i):match("%d") do i = i + 1 end
    end
    local num = tonumber(str:sub(s, i-1))
    if num == nil then parse_error("invalid number") end
    return num
  end

  local function parse_string()
    if str:sub(i,i) ~= '"' then parse_error("expected string") end
    i = i + 1
    local out = {}
    while i <= n do
      local c = str:sub(i,i)
      if c == '"' then
        i = i + 1
        return table.concat(out)
      elseif c == '\\' then
        local esc = str:sub(i+1,i+1)
        if esc == '"' or esc == '\\' or esc == '/' then out[#out+1] = esc
        elseif esc == 'b' then out[#out+1] = '\b'
        elseif esc == 'f' then out[#out+1] = '\f'
        elseif esc == 'n' then out[#out+1] = '\n'
        elseif esc == 'r' then out[#out+1] = '\r'
        elseif esc == 't' then out[#out+1] = '\t'
        elseif esc == 'u' then
          local hex = str:sub(i+2, i+5)
          if not hex:match("^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
            parse_error("invalid unicode escape")
          end
          local code = tonumber(hex, 16)
          -- Minimal UTF-8 encode
          if code <= 0x7F then out[#out+1] = string.char(code)
          elseif code <= 0x7FF then
            out[#out+1] = string.char(0xC0 + math.floor(code/64))
            out[#out+1] = string.char(0x80 + (code % 64))
          else
            out[#out+1] = string.char(0xE0 + math.floor(code/4096))
            out[#out+1] = string.char(0x80 + (math.floor(code/64) % 64))
            out[#out+1] = string.char(0x80 + (code % 64))
          end
        else
          parse_error("invalid escape")
        end
        i = i + 2
      else
        out[#out+1] = c
        i = i + 1
      end
    end
    parse_error("unterminated string")
  end

  local parse_value
  local function parse_array()
    if str:sub(i,i) ~= '[' then parse_error("expected [") end
    i = i + 1
    skip_ws()
    local arr = {}
    if str:sub(i,i) == ']' then i = i + 1; return arr end
    while true do
      skip_ws()
      arr[#arr+1] = parse_value()
      skip_ws()
      local c = str:sub(i,i)
      if c == ',' then i = i + 1
      elseif c == ']' then i = i + 1; return arr
      else parse_error("expected , or ]") end
    end
  end

  local function parse_object()
    if str:sub(i,i) ~= '{' then parse_error("expected {") end
    i = i + 1
    skip_ws()
    local obj = {}
    if str:sub(i,i) == '}' then i = i + 1; return obj end
    while true do
      skip_ws()
      local key = parse_string()
      skip_ws()
      if str:sub(i,i) ~= ':' then parse_error("expected :") end
      i = i + 1
      skip_ws()
      obj[key] = parse_value()
      skip_ws()
      local c = str:sub(i,i)
      if c == ',' then i = i + 1
      elseif c == '}' then i = i + 1; return obj
      else parse_error("expected , or }") end
    end
  end

  function parse_value()
    skip_ws()
    local c = str:sub(i,i)
    if c == '"' then return parse_string()
    elseif c == '{' then return parse_object()
    elseif c == '[' then return parse_array()
    elseif c == 't' then return parse_literal("true", true)
    elseif c == 'f' then return parse_literal("false", false)
    elseif c == 'n' then return parse_literal("null", nil)
    else
      if c:match("[%d%-]") then return parse_number() end
      parse_error("unexpected character: " .. tostring(c))
    end
  end

  local v = parse_value()
  skip_ws()
  return v
end

local function deep_merge(dst, src)
  if type(dst) ~= "table" or type(src) ~= "table" then return dst end
  for k,v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

local function read_all(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

function M.config_path()
  local base = norm(r.GetResourcePath())
  return join(base, "Support", "DF95_Config.json")
end

function M.load(defaults)
  local cfg = defaults or {}
  local path = M.config_path()
  local raw = read_all(path)
  if not raw or raw == "" then
    return cfg, { loaded=false, path=path, error="" }
  end
  local ok, parsed = pcall(json_decode, raw)
  if not ok then
    return cfg, { loaded=false, path=path, error=tostring(parsed) }
  end
  if type(parsed) ~= "table" then
    return cfg, { loaded=false, path=path, error="JSON root must be an object" }
  end
  deep_merge(cfg, parsed)
  return cfg, { loaded=true, path=path, error="" }
end

return M
