-- DF95_Diagnostics_InstallDoctor.lua (ReaPack-aware + prominent URL + Copy URL)
-- Drop-in replacement / patch overlay.

local function has_fn(name) return type(reaper[name]) == "function" end

local has_sws = has_fn("CF_ShellExecute")
local has_clip = has_fn("CF_SetClipboard") -- SWS provides CF_SetClipboard
local has_reapack = false
for _,fn in ipairs({
  "ReaPack_BrowsePackages",
  "ReaPack_AddSetRepository",
  "ReaPack_ImportRepository",
  "ReaPack_ProcessQueue"
}) do
  if has_fn(fn) then has_reapack = true break end
end

local function read_df95_repo_url()
  -- Best effort: try to load DF95_Config.json near script path
  -- If your DF95 framework has a config loader, you can replace this block.
  local sep = package.config:sub(1,1)
  local res = reaper.GetResourcePath()
  local cfg = res .. sep .. "Support" .. sep .. "DF95_Config.json"
  local file = io.open(cfg, "r")
  if not file then return nil, cfg end
  local txt = file:read("*a"); file:close()
  local ok, data = pcall(function() return reaper.JSON_Parse and reaper.JSON_Parse(txt) end)
  -- If no JSON_Parse, do ultra-light parse for df95_repo_index_url
  local url = txt:match([["df95_repo_index_url"%s*:%s*"([^"]*)"]])
  if url and url:match("%S") then return url, cfg end
  return nil, cfg
end

local function normalize_url(url)
  if not url then return nil end
  url = url:gsub("%s+$",""):gsub("^%s+","")
  if url == "" then return nil end
  return url
end

local df95_url, cfg_path = read_df95_repo_url()
df95_url = normalize_url(df95_url)

local lines = {}
local function add(s) lines[#lines+1] = s end

add("DF95 • Install Doctor")
add("----------------------------------------")

if not has_reapack then
  add("ReaPack: MISSING")
  add("")
  add("Next step (only one): Install ReaPack")
  add("  - https://reapack.com/")
  add("")
  add("After installing: restart REAPER, then run Install Doctor again.")
else
  add("ReaPack: OK")
  add("")
  add("ReaPack workflow (inside REAPER):")
  add("  1) Extensions → ReaPack → Import repositories…")
  add("  2) Extensions → ReaPack → Synchronize packages")
  add("")
  if df95_url then
    add("Your DF95 repo index URL (import this):")
    add("  " .. df95_url)
    add("")
    if has_clip then
      local ret = reaper.ShowMessageBox(
        "DF95 ReaPack index URL:\n\n" .. df95_url .. "\n\nCopy to clipboard?",
        "DF95 Install Doctor",
        4 -- Yes/No
      )
      if ret == 6 then
        reaper.CF_SetClipboard(df95_url)
        add("[Copied URL to clipboard via SWS]")
      else
        add("[URL not copied]")
      end
    else
      add("Tip: install SWS to enable one-click clipboard copy (CF_SetClipboard).")
    end
  else
    add("DF95 repo index URL: NOT SET")
    add("Config file expected at:")
    add("  " .. tostring(cfg_path))
    add("")
    add("Set Support/DF95_Config.json → reapack.df95_repo_index_url to your raw index.xml URL.")
  end
end

-- Show other deps succinctly (since user asked: avoid spam)
add("")
add("Other dependencies (quick probe):")
add("  SWS: " .. (has_sws and "OK" or "MISSING"))
add("  ReaImGui: " .. (has_fn("ImGui_CreateContext") and "OK" or "MISSING"))
add("  js_ReaScriptAPI: " .. (has_fn("JS_Window_Find") and "OK" or "MISSING"))

reaper.ShowConsoleMsg(table.concat(lines, "\n") .. "\n")
reaper.ShowMessageBox("Install Doctor report written to ReaScript console.\n\nOpen: View → ReaScript console", "DF95 Install Doctor", 0)