-- @description Validator – Write Fallback Chains (_fallback)
-- @version 2.2
-- @author DF95
-- @about Scans .rfxchain files, replaces missing FX via mapping, writes *_fallback.rfxchain.
local r = reaper
local sep = package.config:sub(1,1)
local res = r.GetResourcePath()
local base = (debug.getinfo(1,'S').source:sub(2)):match("^(.*"..sep..")") or ""
local CH = base:gsub("Scripts"..sep.."IFLS"..sep.."DF95"..sep, "Chains"..sep)

local mapping = {
  -- Analog Obsession → Airwindows / Stock
  ["VST3: AO"] = "VST3: ToTape8 (Airwindows)",
  ["VST: AO"]  = "VST3: ToTape8 (Airwindows)",
  -- BABY Audio
  ["VST3: Magic Dice (BABY Audio)"] = "JS: Delay/pingpong_pan",
  ["VST3: Warp (BABY Audio)"]       = "JS: chorus",
  ["VST3: Spaced Out (BABY Audio)"] = "JS: Delay/varying_delay",
  -- PaulXStretch
  ["VST3: PaulXStretch (PaulXStretch)"] = "JS: LOSER/time_frequency_stretch",
}

local function exists_fx(name)
  local fx = r.TrackFX_AddByName(r.GetMasterTrack(0), name, false, 1)
  return fx >= 0
end

local function map_line(line)
  for k,v in pairs(mapping) do
    if line:find(k,1,true) then
      if exists_fx(v) then return line:gsub(k, v, 1), (k.." → "..v) end
    end
  end
  return line, nil
end

local function process_chain(path)
  local f = io.open(path, "rb"); if not f then return false,"open" end
  local data = f:read("*all"); f:close()
  local out = {}; local changes = {}
  for line in (data.."\n"):gmatch("(.-)\n") do
    local nl, info = map_line(line)
    table.insert(out, nl)
    if info then table.insert(changes, info) end
  end
  local dst = path:gsub("%.rfxchain$", "_fallback.rfxchain")
  local g = io.open(dst, "wb"); if not g then return false,"write" end
  g:write(table.concat(out, "\n")); g:close()
  return true, changes
end

local function scan_dir(dir)
  local cnt, changed = 0, 0
  for filename in io.popen('dir "'..dir..'" /b'):lines() do
    if filename:lower():match("%.rfxchain$") then
      local ok, info = process_chain(dir..sep..filename)
      cnt = cnt + 1
      if ok and #info>0 then changed = changed + 1 end
    end
  end
  return cnt, changed
end

local dir = CH
local cnt, chg = scan_dir(dir)
r.ShowMessageBox(string.format("Fallback writer done.\nChains scanned: %d\nWith replacements: %d\n(Output: *_fallback.rfxchain)", cnt, chg), "DF95", 0)