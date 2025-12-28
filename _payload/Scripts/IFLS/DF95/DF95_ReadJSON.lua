return function(path)
  local f = io.open(path, "rb"); if not f then return {} end
  local s = f:read("*all"); f:close()
  -- crude JSON decode (REAPER lacks built-in); expect simple maps only
  local ok, json = pcall(function() return assert(load("return "..s:gsub("null","nil"):gsub('"(%d+)"','%1')))() end)
  if ok and type(json)=="table" then return json end
  return {}
end