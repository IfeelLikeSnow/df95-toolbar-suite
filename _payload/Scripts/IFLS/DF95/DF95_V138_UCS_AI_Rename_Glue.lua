-- @description DF95_V138 UCS AI + Renamer Glue Hub
-- @version 1.0
-- @author DF95
-- @about
--   Orchestriert die UCS-bezogenen AIWorker- und Rename-Schritte:
--
--     1) AIWorker-Job für Ordner erzeugen (DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua)
--     2) Result-JSON des Python-AIWorkers in die DF95 SampleDB Multi-UCS ingestieren
--     3) Den UCS Batch Renamer (DF95_V134_UCS_Renamer.lua) starten
--
--   Dieses Script führt SELBST KEIN Python aus, sondern bündelt nur die DF95-Tools
--   zu einer klaren „UCS AI Pipeline“:
--
--     Folder  ->  AI Job JSON  ->  Python Worker  ->  Result JSON
--           ->  SampleDB AI-Felder (UCS + df95_material/Instrument) aktualisieren
--           ->  UCS Batch Renamer (DF95_V134) nutzt diese Felder für die Namen.

local r = reaper

local function df95_root()
  local sep = package.config:sub(1,1)
  local res = r.GetResourcePath()
  return (res .. sep .. "Scripts" .. sep .. "IfeelLikeSnow" .. sep .. "DF95" .. sep):gsub("\","/")
end

local function run_script(rel)
  local path = df95_root() .. rel
  local f, err = loadfile(path)
  if not f then
    r.ShowMessageBox("Kann Script nicht laden:\n" .. path .. "\n\n" .. tostring(err),
      "DF95 UCS AI Glue", 0)
    return false
  end
  f()
  return true
end

local function main()
  local title = "DF95 UCS AI + Renamer – Glue Hub"
  local ok, ret = r.GetUserInputs(
    title,
    3,
    "Schritt (1=Job,2=Ingest,3=Renamer,4=1+2+3),AIWorker Job/Result-Path (leer=Dialog),WorkerMode (generic/drone/material, leer=generic)",
    "1,,generic"
  )
  if not ok then return end

  local s_step, s_path, s_mode = ret:match("([^,]*),([^,]*),?(.*)")
  s_step = (s_step or ""):gsub("%s+","")
  s_path = (s_path or "")
  s_mode = (s_mode or "")

  if s_step == "" then
    r.ShowMessageBox("Kein Schritt gewählt. Bitte 1,2,3 oder 4 eingeben.",
      "DF95 UCS AI Glue", 0)
    return
  end

  local step = tonumber(s_step) or 0
  if step < 1 or step > 4 then
    r.ShowMessageBox("Ungültiger Schritt: " .. tostring(s_step) ..
      "\nErlaubt sind: 1, 2, 3 oder 4.", "DF95 UCS AI Glue", 0)
    return
  end

  -- 1/2 nutzen das AIWorker-UCS-Script (mit eigener UI, wenn Pfad leer)
  -- 3 ruft nur den UCS Batch Renamer auf.

  -- Schritt 1: Job erstellen
  local do_job    = (step == 1 or step == 4)
  -- Schritt 2: Result ingest
  local do_ingest = (step == 2 or step == 4)
  -- Schritt 3: Renamer starten
  local do_rename = (step == 3 or step == 4)

  ------------------------------------------------------------
  -- 1) Job erstellen (Folder -> Job-JSON)
  ------------------------------------------------------------
  if do_job then
    -- Das AIWorker-UCS-Script hat seine eigene UI:
    -- Modus = job/create, Folder (oder Browser), WorkerMode.
    -- Wenn der Benutzer im Glue-Hub bereits s_path/s_mode gesetzt hat,
    -- geben wir sie via ExtState an das Script weiter (optional).
    r.SetExtState("DF95_AI_UCS_GLUE", "MODE",      "job/create", false)
    r.SetExtState("DF95_AI_UCS_GLUE", "PATH_HINT", s_path or "",  false)
    r.SetExtState("DF95_AI_UCS_GLUE", "WORKER",    s_mode or "",  false)

    run_script("DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua")
  end

  ------------------------------------------------------------
  -- 2) Result-JSON ingestieren
  ------------------------------------------------------------
  if do_ingest then
    r.SetExtState("DF95_AI_UCS_GLUE", "MODE",      "result/ingest", false)
    r.SetExtState("DF95_AI_UCS_GLUE", "PATH_HINT", s_path or "",     false)
    r.SetExtState("DF95_AI_UCS_GLUE", "WORKER",    s_mode or "",     false)

    run_script("DF95_SampleDB_AIWorker_UCS_Python_Skeleton.lua")
  end

  ------------------------------------------------------------
  -- 3) UCS Batch Renamer starten
  ------------------------------------------------------------
  if do_rename then
    run_script("DF95_V134_UCS_Renamer.lua")
  end
end

main()
