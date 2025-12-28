-- IFLS_QuickStart_SelfCheck.lua
-- Phase 94: Quick Start & Self-Check for IFLS
--
-- Dieses Script prüft:
--   * ob das IFLS-Repo (Domain-Module) unter Scripts/IFLS/IFLS liegt
--   * ob die IFLS-Toolbars im Repo/MenuSets vorhanden sind
--   * ob die IFLS-Toolbars bereits im REAPER-MenuSets-Ordner installiert sind
--   * gibt eine kompakte Zusammenfassung in der REAPER-Konsole + MessageBox aus
--
-- Es nimmt KEINE Änderungen vor, sondern dient nur als "Was ist installiert?"
-- Überblick direkt in REAPER.

local r = reaper

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function dirname(path)
  local sep = package.config:sub(1,1)
  return path:match("^(.*" .. sep .. ")") or path
end

local function strip_trailing_sep(path)
  local sep = package.config:sub(1,1)
  if path:sub(-1) == sep then
    return path:sub(1, -2)
  end
  return path
end

local function join(a, b)
  local sep = package.config:sub(1,1)
  a = strip_trailing_sep(a)
  if a == "" then return b end
  return a .. sep .. b
end

local function file_exists(path)
  if r.file_exists then
    return r.file_exists(path)
  end
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

------------------------------------------------------------
-- Detect repo root, domain and menusets
------------------------------------------------------------

local _, script_path = r.get_action_context()
script_path = strip_trailing_sep(script_path)
local script_dir = dirname(script_path)                  -- .../IFLS/Setup/
script_dir = strip_trailing_sep(script_dir)
local ifls_dir   = dirname(script_dir)                   -- .../IFLS/
ifls_dir = strip_trailing_sep(ifls_dir)
local ifls_parent= dirname(ifls_dir)                     -- .../IfeelLikeSnow/
ifls_parent = strip_trailing_sep(ifls_parent)
local scripts_dir= dirname(ifls_parent)                  -- .../Scripts/
scripts_dir = strip_trailing_sep(scripts_dir)
local repo_root  = dirname(scripts_dir)                  -- repo root
repo_root = strip_trailing_sep(repo_root)

-- Fallback: go three parents up
if not repo_root or repo_root == "" then
  local p = script_dir
  for i = 1,3 do
    p = strip_trailing_sep(p)
    p = dirname(p)
  end
  repo_root = strip_trailing_sep(p)
end

local repo_menusets   = join(repo_root, "MenuSets")
local repo_ifls_dir   = ifls_dir
local repo_ifls_domain= join(repo_ifls_dir, "Domain")
local repo_ifls_setup = join(repo_ifls_dir, "Setup")

local resource_path   = r.GetResourcePath()
local resource_menusets = join(resource_path, "MenuSets")

------------------------------------------------------------
-- Checks
------------------------------------------------------------

local result = {
  repo_root          = repo_root,
  repo_menusets      = repo_menusets,
  repo_ifls_dir      = repo_ifls_dir,
  repo_ifls_domain   = repo_ifls_domain,
  repo_ifls_setup    = repo_ifls_setup,
  resource_menusets  = resource_menusets,
  checks             = {},
}

local function add_check(category, name, ok, info)
  table.insert(result.checks, {
    category = category,
    name     = name,
    ok       = ok and true or false,
    info     = info or "",
  })
end

-- 1) Struktur: IFLS Domain/Setup vorhanden?
add_check("Repo Struktur", "IFLS Domain Ordner",
  file_exists(repo_ifls_domain),
  repo_ifls_domain
)

add_check("Repo Struktur", "IFLS Setup Ordner",
  file_exists(repo_ifls_setup),
  repo_ifls_setup
)

-- 2) Kernmodule der Phasen 86–93
local core_modules = {
  { "IFLS_FXChainRecommender.lua", "FXChain Recommender (Phase 89)" },
  { "IFLS_SampleEmbeddings.lua",   "Sample Embeddings (Phase 90)" },
  { "IFLS_SimilaritySearch.lua",   "Similarity Search (Phase 90)" },
  { "IFLS_RhythmStyles.lua",       "Rhythm Styles (Phase 91)" },
  { "IFLS_RhythmMorpher.lua",      "Rhythm Morpher (Phase 91)" },
  { "IFLS_MacroControls.lua",      "Macro Controls (Phase 92)" },
  { "IFLS_ScenePresets.lua",       "Scene Presets (Phase 92)" },
  { "IFLS_Diagnostics.lua",        "Diagnostics (Phase 93)" },
  { "IFLS_PerfProbe.lua",          "PerfProbe (Phase 93)" },
}

for _, entry in ipairs(core_modules) do
  local fname, desc = entry[1], entry[2]
  local p = join(repo_ifls_domain, fname)
  add_check("IFLS Domain-Module", desc, file_exists(p), p)
end

-- 3) Toolbars im Repo vorhanden?
local toolbar_files = {
  "IFLS_Main.Toolbar.ReaperMenu",
  "IFLS_Beat.Toolbar.ReaperMenu",
  "IFLS_Sample.Toolbar.ReaperMenu",
  "IFLS_Debug.Toolbar.ReaperMenu",
}

for _, fname in ipairs(toolbar_files) do
  local p = join(repo_menusets, fname)
  add_check("Toolbars im Repo", fname, file_exists(p), p)
end

-- 4) Toolbars im REAPER ResourcePath installiert?
for _, fname in ipairs(toolbar_files) do
  local p = join(resource_menusets, fname)
  add_check("Toolbars in REAPER", fname, file_exists(p), p)
end

------------------------------------------------------------
-- Output
------------------------------------------------------------

r.ShowConsoleMsg("=== IFLS QuickStart SelfCheck ===\n\n")
r.ShowConsoleMsg("Repo Root:        " .. repo_root .. "\n")
r.ShowConsoleMsg("Repo MenuSets:    " .. repo_menusets .. "\n")
r.ShowConsoleMsg("Repo IFLS Domain: " .. repo_ifls_domain .. "\n")
r.ShowConsoleMsg("Repo IFLS Setup:  " .. repo_ifls_setup .. "\n")
r.ShowConsoleMsg("REAPER MenuSets:  " .. resource_menusets .. "\n\n")

local ok_count, fail_count = 0, 0

for _, c in ipairs(result.checks) do
  local status = c.ok and "[OK]     " or "[FEHLT] "
  if c.ok then ok_count = ok_count + 1 else fail_count = fail_count + 1 end
  local line = string.format("%s %-24s : %s", status, c.category, c.name)
  r.ShowConsoleMsg(line .. "\n")
  if c.info and c.info ~= "" then
    r.ShowConsoleMsg("           Pfad: " .. c.info .. "\n")
  end
end

r.ShowConsoleMsg("\nZusammenfassung: OK="..ok_count.."  Fehlend="..fail_count.."\n")
r.ShowConsoleMsg("=== Ende IFLS QuickStart SelfCheck ===\n")

local msg_lines = {}
table.insert(msg_lines, "IFLS QuickStart SelfCheck:")
table.insert(msg_lines, "  OK: " .. tostring(ok_count))
table.insert(msg_lines, "  Fehlend: " .. tostring(fail_count))
table.insert(msg_lines, "")
table.insert(msg_lines, "Details siehe REAPER-Konsole (View > Show console).")

r.ShowMessageBox(table.concat(msg_lines, "\n"), "IFLS QuickStart SelfCheck", 0)
