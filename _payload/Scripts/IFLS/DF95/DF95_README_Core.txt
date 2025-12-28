DF95 Toolchain – Core Overview (V260 / Phase 20+)

Kernskripte (ImGui / Control):

  * Tools/DF95_ControlCenter_ImGui.lua
      - Zentrales UI (Tabs: Fieldrec, SampleDB, Analytics, Artist, Safety)
      - Einstiegspunkt fuer alle wichtigen Workflows

  * DF95_SampleDB_Inspector_V5_AI_Review_ImGui.lua
      - SampleDB Inspector mit AI-/Review-/Confidence-Feldern
      - Filter: Text, Zone, Review-Flag, ai_status, Confidence
      - Quick-Actions + AutoIngest-Subset-Export

  * DF95_AI_QA_Center_ImGui.lua
      - Uebersicht ueber Clean-/Problem-Rate und Schema-Health

AutoIngest / Review / QA:

  * DF95_AutoIngest_Master_V3.lua
      - Haupt-AutoIngest:
          Modes: ANALYZE / SAFE / AGGR
          Subset-Mode: nur Items aus DF95_AutoIngest_Subset.json
      - schreibt ChangeLog nach:
          Support/DF95_SampleDB/DF95_AutoIngest_ChangeLog.jsonl

  * DF95_AutoIngest_Undo_LastRun.lua
      - Macht den letzten SAFE/AGGR-Lauf anhand des ChangeLogs rueckgaenig
      - Button im ControlCenter / SampleDB-Tab vorhanden

  * DF95_AutoIngest_ReviewInspector_V1.lua
  * DF95_AutoIngest_ReviewReport_V1.lua
      - Review-UI und Text-Report fuer AutoIngest-Flags

  * DF95_SampleDB_Validator_V3.lua
      - Validiert die Multi-UCS SampleDB auf Pflichtfelder / AI-Felder

  * DF95_SampleDB_Migrate_V2_to_V3.lua
      - Migration aelterer DB-Versionen in das neue Schema

Analytics / Device / Zonen:

  * Tools/DF95_ControlCenter_ImGui.lua
      - Tab "Analytics": Hotspots pro HomeZone/SubZone, ai_status-Stats
      - Hotspot -> Inspector V5-Integration (Zone/Flag-Filter uebernimmt)

  * DF95_DeviceProfiles.lua
      - Definition der Fieldrec-/Home-/Device-Profile

Unterstuetzende Dateien (werden im REAPER Resource Path erwartet):

  Support/DF95_SampleDB/DF95_SampleDB_Multi_UCS.json
      - Haupt-JSON-Datenbank

  Support/DF95_SampleDB/DF95_InspectorV5_HotspotFilter.json
      - Hotspot-Config vom ControlCenter für Inspector V5

  Support/DF95_SampleDB/DF95_AutoIngest_Subset.json
      - Subset-Liste fuer AutoIngest V3 (nur ausgewertete Items)

  Support/DF95_SampleDB/DF95_AutoIngest_ChangeLog.jsonl
      - ChangeLog (eine JSON-Zeile pro AutoIngest-SAFE/AGGR-Lauf)

Empfohlene Erst-Konfiguration:

  1. DF95_ControlCenter_ImGui.lua als Action registrieren.
  2. DF95_Installer_SanityCheck.lua als Action registrieren und ausfuehren.
  3. Sicherstellen, dass der Support/DF95_SampleDB-Ordner existiert und beschreibbar ist.
  4. Migration V2->V3 nur bei bestehenden DB-Bestaenden ausfuehren.
  5. Validator V3 ueber die DB laufen lassen.
  6. Inspector V5, QA Center und Analytics zum laufenden Arbeiten verwenden.

