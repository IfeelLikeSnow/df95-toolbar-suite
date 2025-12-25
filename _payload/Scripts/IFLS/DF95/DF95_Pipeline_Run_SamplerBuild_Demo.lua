-- @description Pipeline Demo: Run SAMPLER_BUILD (RS5k Kit from Folder + Roles)
-- @version 1.0
-- @author DF95
-- @about
--   Einfaches Demo-Script, das DF95_Pipeline_Core benutzt, um
--   die SAMPLER_BUILD-Stage auszuführen:
--     - baut ein RS5k-Kit aus einem Ordner
--     - annotiert Kick/Snare/Hat/Tom/Perc basierend auf Noten

local r = reaper

local function df95_root()
  local info = debug.getinfo(1, "S")
  local script_path = info and info.source:match("^@(.+)$")
  if not script_path then return "" end
  local dir = script_path:match("^(.*[\\/])")
  return dir or ""
end

local function load_pipeline_core()
  local path = df95_root() .. "DF95_Pipeline_Core.lua"
  local ok, mod = pcall(dofile, path)
  if not ok then
    r.ShowMessageBox("Fehler beim Laden von DF95_Pipeline_Core.lua:\n"..tostring(mod), "DF95 Pipeline Demo", 0)
    return nil
  end
  return mod
end

local function main()
  local pipeline = load_pipeline_core()
  if not pipeline or not pipeline.run then return end

  local stages = { "SAMPLER_BUILD" }
  local options = {
    sampler = {
      mode = "folder",       -- "folder" | "items" | "roundrobin"
      annotate_roles = true, -- Kick/Snare/Hat/Tom/Perc beschriften
    }
  }

  pipeline.run(stages, options)
end

main()
