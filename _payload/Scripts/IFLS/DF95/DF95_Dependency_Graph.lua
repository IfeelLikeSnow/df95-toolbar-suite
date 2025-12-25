-- DF95_Dependency_Graph.lua
-- Scannt das DF95-Verzeichnis und erzeugt eine einfache Dependency-Liste
-- (dofile/require/NamedCommandLookup/ExtStates) als JSON.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  local base = (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\\","/")
  return base
end

local function scan_files(root)
  local results = {}
  local function walk(dir)
    local i = 0
    while true do
      local fn = r.EnumerateFiles(dir, i)
      if not fn then break end
      if fn:match("%.lua$") then
        table.insert(results, dir.."/"..fn)
      end
      i = i + 1
    end
    i = 0
    while true do
      local sub = r.EnumerateSubdirectories(dir, i)
      if not sub then break end
      walk(dir.."/"..sub)
      i = i + 1
    end
  end
  walk(root)
  return results
end

local function read_file(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read("*all"); f:close(); return d
end

local function build_graph()
  local root = df95_root()
  local files = scan_files(root)
  local graph = {}

  for _, path in ipairs(files) do
    local rel = path:gsub("^"..root, "")
    local txt = read_file(path) or ""
    local node = { requires = {}, dofiles = {}, uses_named = {}, uses_extstate = {} }

    for mod in txt:gmatch("require%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
      table.insert(node.requires, mod)
    end
    for fp in txt:gmatch("dofile%s*%(%s*df95_root%(%s*%)%s*%..['\"]([^'\"]+)['\"]%s*%)") do
      table.insert(node.dofiles, fp)
    end
    for cmd in txt:gmatch("NamedCommandLookup%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
      table.insert(node.uses_named, cmd)
    end
    for k in txt:gmatch("SetProjExtState%([^,]+,%s*['\"]([^'\"]+)['\"]%s*,%s*['\"]([^'\"]+)['\"]") do
      table.insert(node.uses_extstate, k)
    end

    graph[rel] = node
  end

  return graph
end

local function save_json(tbl, path)
  local function esc(s)
    return (s:gsub('\\', '\\\\'):gsub('"','\\"'))
  end
  local function dump_val(v, indent)
    indent = indent or ""
    if type(v) == "table" then
      local out = "{"
      local first = true
      for k, vv in pairs(v) do
        if not first then out = out .. "," end
        out = out .. '\n' .. indent .. '  "'..esc(k)..'": '..dump_val(vv, indent.."  ")
        first = false
      end
      if not first then out = out .. '\n'..indent end
      out = out .. "}"
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
  local root = df95_root()
  local graph = build_graph()
  local out_path = root .. "DF95_DependencyGraph.json"
  save_json(graph, out_path)
  r.ShowMessageBox("Dependency Graph gespeichert:\n"..out_path, "DF95 Dependency Graph", 0)
end

main()
