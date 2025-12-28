-- IFLS_SampleLibraryHub_ImGui.lua
-- Phase 29: Sample Library Hub (UCS / SampleDB)

local r = reaper
local ig = r.ImGui

local ctx = ig.CreateContext('IFLS_SampleLibraryHub')

local function run_df95_script(relpath)
  local base = r.GetResourcePath() .. '/Scripts/IFLS/DF95/'
  local full = base .. relpath
  local chunk, err = loadfile(full)
  if not chunk then
    r.ShowMessageBox('Konnte DF95-Script nicht laden: ' .. tostring(full) .. '\nFehler: ' .. tostring(err), 'IFLS SampleLibraryHub', 0)
    return
  end
  local ok, perr = pcall(chunk)
  if not ok then
    r.ShowMessageBox('Fehler beim Ausführen von: ' .. tostring(full) .. '\n' .. tostring(perr), 'IFLS SampleLibraryHub', 0)
  end
end

local SCRIPTS = {
  scan_folder_ucslight = 'DF95_V137_SampleDB_ScanFolder_UCSLight_HomeField.lua',
  library_analyzer      = 'DF95_V138_SampleDB_LibraryAnalyzer.lua',
  inspector_ai_mapping  = 'DF95_V132_SampleDB_Inspector_V4_AI_Mapping.lua',
  ai_tag_browser        = 'DF95_V161_SampleDB_AI_TagBrowser.lua',
  ucs_renamer           = 'DF95_V134_UCS_Renamer.lua',
  ucs_ai_rename_glue    = 'DF95_V138_UCS_AI_Rename_Glue.lua',
  pack_exporter         = 'DF95_V142_SampleDB_PackExporter.lua',
}

local last_info = ""

local function set_info(msg)
  last_info = msg or ""
end

local function loop()
  ig.SetNextWindowSize(ctx, 640, 360, ig.Cond_FirstUseEver())
  local visible, open = ig.Begin(ctx, 'IFLS Sample Library Hub (UCS)', true)
  if visible then
    ig.Text(ctx, 'IFLS Sample Library Hub – UCS / SampleDB')
    ig.Separator(ctx)

    ig.TextWrapped(ctx, 'Dieser Hub bündelt die DF95-Sample-Library-Tools (UCS, AI-Mapping, Library-Scan) '
      .. 'unter einem IFLS-Dach. Die eigentliche Logik bleibt in den DF95-Scripten.')

    ig.Separator(ctx)
    ig.Text(ctx, 'Schritt 1: Library scannen / analysieren')
    if ig.Button(ctx, 'Scan Folder (UCS Light – HomeField)') then
      set_info('Starte DF95_V137_SampleDB_ScanFolder_UCSLight_HomeField.lua ...')
      run_df95_script(SCRIPTS.scan_folder_ucslight)
    end
    ig.SameLine(ctx)
    if ig.Button(ctx, 'Library Analyzer') then
      set_info('Starte DF95_V138_SampleDB_LibraryAnalyzer.lua ...')
      run_df95_script(SCRIPTS.library_analyzer)
    end

    ig.Separator(ctx)
    ig.Text(ctx, 'Schritt 2: AI-Mapping / Tags')
    if ig.Button(ctx, 'AI Inspector / Mapping') then
      set_info('Starte DF95_V132_SampleDB_Inspector_V4_AI_Mapping.lua ...')
      run_df95_script(SCRIPTS.inspector_ai_mapping)
    end
    ig.SameLine(ctx)
    if ig.Button(ctx, 'AI Tag Browser') then
      set_info('Starte DF95_V161_SampleDB_AI_TagBrowser.lua ...')
      run_df95_script(SCRIPTS.ai_tag_browser)
    end

    ig.Separator(ctx)
    ig.Text(ctx, 'Schritt 3: UCS Rename / Export')
    if ig.Button(ctx, 'UCS Renamer') then
      set_info('Starte DF95_V134_UCS_Renamer.lua ...')
      run_df95_script(SCRIPTS.ucs_renamer)
    end
    ig.SameLine(ctx)
    if ig.Button(ctx, 'UCS AI Rename Glue') then
      set_info('Starte DF95_V138_UCS_AI_Rename_Glue.lua ...')
      run_df95_script(SCRIPTS.ucs_ai_rename_glue)
    end
    ig.SameLine(ctx)
    if ig.Button(ctx, 'Pack Exporter') then
      set_info('Starte DF95_V142_SampleDB_PackExporter.lua ...')
      run_df95_script(SCRIPTS.pack_exporter)
    end

    ig.Separator(ctx)
    if last_info ~= "" then
      ig.Text(ctx, 'Info:')
      ig.TextWrapped(ctx, last_info)
    else
      ig.Text(ctx, 'Info: bereit.')
    end

    ig.Spacing(ctx)
    ig.TextWrapped(ctx, 'Workflow-Tipp:\n'
      .. '1) Mit "Scan Folder (UCS Light)" eine oder mehrere Library-Ordner scannen.\n'
      .. '2) Mit Library Analyzer & AI Inspector die Ergebnisse prüfen / verfeinern.\n'
      .. '3) Über UCS Renamer (und ggf. AI Rename Glue) die finalen Namen nach UCS-Standard schreiben.\n'
      .. '4) Optional: Mit Pack Exporter UCSpacks / Kits erstellen.')

    ig.End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    ig.DestroyContext(ctx)
  end
end

loop()
