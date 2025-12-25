-- DF95_Scan_InstalledFX.lua
-- Scannt REAPER-Ini-Dateien (VST/JSFX), erkennt installierte FX
-- und erzeugt eine JSON-Übersicht DF95_InstalledFX.json im DF95-Ordner.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function read_file(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

local function parse_ini_vst(path)
  local txt = read_file(path) or ""
  local vst = {}
  for line in txt:gmatch("[^\r\n]+") do
    if line:match("^VST") or line:match("^VST3") then
      table.insert(vst, line)
    end
  end
  return vst
end

local function parse_ini_jsfx(path)
  local txt = read_file(path) or ""
  local jsfx = {}
  for line in txt:gmatch("[^\r\n]+") do
    if line:match("^desc:") then
      table.insert(jsfx, line:sub(6))
    end
  end
  return jsfx
end

local function save_json(tbl, path)
  local function esc(s)
    return (s:gsub('\\', '\\\\'):gsub('"','\\"'))
  end
  local function dump_val(v, indent)
    indent = indent or ""
    if type(v) == "table" then
      local out = "["
      local first = true
      for _, vv in ipairs(v) do
        if not first then out = out .. "," end
        out = out .. "\n" .. indent .. "  " .. dump_val(vv, indent.."  ")
        first = false
      end
      if not first then out = out .. "\n"..indent end
      out = out .. "]"
      return out
    elseif type(v) == "string" then
      return '"'..esc(v)..'"'
    elseif type(v) == "number" then
      return tostring(v)
    elseif type(v) == "boolean" then
      return v and "true" or "false"
    else
      return "null"
    end
  end

  local f = io.open(path, "wb"); if not f then return end
  f:write(dump_val(tbl, ""))
  f:close()
end

local function main()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local ini_vst = res .. sep .. "reaper-vstplugins64.ini"
  local ini_js = res .. sep .. "reaper-jsfx.ini"

  local out = { vst = {}, jsfx = {} }

  local f = io.open(ini_vst, "rb")
  if f then f:close(); out.vst = parse_ini_vst(ini_vst) end

  local f2 = io.open(ini_js, "rb")
  if f2 then f2:close(); out.jsfx = parse_ini_jsfx(ini_js) end

  local out_path = df95_root() .. "DF95_InstalledFX.json"
  save_json(out, out_path)
  r.ShowMessageBox("Installed FX gescannt:\n"..out_path, "DF95 Scan Installed FX", 0)
end

main()
