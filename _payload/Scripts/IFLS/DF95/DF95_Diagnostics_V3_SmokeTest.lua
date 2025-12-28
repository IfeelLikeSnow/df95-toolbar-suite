-- DF95_Diagnostics_V3_SmokeTest.lua (ReaPack-aware sanity checks, gentle)
local function has_fn(name) return type(reaper[name]) == "function" end

local function read_repo_url()
  local sep = package.config:sub(1,1)
  local res = reaper.GetResourcePath()
  local cfg = res .. sep .. "Support" .. sep .. "DF95_Config.json"
  local file = io.open(cfg, "r")
  if not file then return nil, cfg end
  local txt = file:read("*a"); file:close()
  local url = txt:match([["df95_repo_index_url"%s*:%s*"([^"]*)"]])
  if url and url:match("%S") then
    url = url:gsub("^%s+",""):gsub("%s+$","")
    if url == "" then url = nil end
  else
    url = nil
  end
  return url, cfg
end

local has_reapack = has_fn("ReaPack_BrowsePackages") or has_fn("ReaPack_AddSetRepository") or has_fn("ReaPack_ProcessQueue")
local url, cfg_path = read_repo_url()

local function ok(label, msg) return ("[OK]   %-18s %s"):format(label, msg or "") end
local function warn(label, msg) return ("[WARN] %-18s %s"):format(label, msg or "") end

local out = {}
out[#out+1] = "DF95 • V3 Smoke Test"
out[#out+1] = "----------------------------------------"

-- ReaPack-aware checks
if not has_reapack then
  out[#out+1] = warn("ReaPack", "not installed (fine if you don't use ReaPack)")
else
  out[#out+1] = ok("ReaPack", "installed")
  if url then
    out[#out+1] = ok("DF95 Repo URL", "set")
    -- Gentle “load” check: we can't reliably fetch network here; instead sanity-check format.
    if url:match("^https?://") and url:match("index%.xml$") then
      out[#out+1] = ok("URL format", "looks like a raw index.xml URL")
    else
      out[#out+1] = warn("URL format", "doesn't look like a raw index.xml (expected http(s) + …/index.xml)")
    end
  else
    out[#out+1] = warn("DF95 Repo URL", "not set (Support/DF95_Config.json)")
    out[#out+1] = warn("Config path", tostring(cfg_path))
  end
end

-- Keep existing dependency probes light
out[#out+1] = ok("SWS", has_fn("CF_ShellExecute") and "installed" or "missing")
out[#out+1] = ok("ReaImGui", has_fn("ImGui_CreateContext") and "installed" or "missing")
out[#out+1] = ok("js_ReaScriptAPI", has_fn("JS_Window_Find") and "installed" or "missing")

reaper.ShowConsoleMsg(table.concat(out, "\n") .. "\n")
reaper.ShowMessageBox("Smoke Test completed.\n\nDetails in ReaScript console (View → ReaScript console).", "DF95 Smoke Test", 0)