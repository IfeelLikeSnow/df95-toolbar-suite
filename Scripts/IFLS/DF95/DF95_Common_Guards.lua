-- @description Common Guards (pcall dofile, safe io)
-- @version 1.0
-- @author IfeelLikeSnow
-- @about Hilfsfunktionen: guard_dofile(path) mit pcall; safe_open(path,mode) mit Fehlerfallback.
local function guard_dofile(path)
  local ok, mod = pcall(dofile, path)
  if not ok then
    reaper.ShowConsoleMsg("[DF95 GUARD] dofile failed: "..tostring(path).." :: "..tostring(mod).."\n")
    return nil, mod
  end
  return mod, nil
end

local function safe_open(path, mode)
  local f, err = io.open(path, mode or "rb")
  if not f then
    reaper.ShowConsoleMsg("[DF95 GUARD] io.open failed: "..tostring(path).." :: "..tostring(err).."\n")
    return nil, err
  end
  return f, nil
end

return { guard_dofile = guard_dofile, safe_open = safe_open }