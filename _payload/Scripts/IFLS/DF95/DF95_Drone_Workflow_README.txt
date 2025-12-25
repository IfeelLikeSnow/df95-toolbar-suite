DF95 Drone / Atmos Workflow - Kurzuebersicht
=========================================

Dieses Dokument beschreibt den typischen DF95-Workflow fuer Drone-/Atmos-Sounds
ausgehend von Fieldrecordings / SampleDB-Views bis hin zum Export und AutoIngest.

1. SampleDB-View / AutoIngest-Subset
------------------------------------

* Im SampleDB Inspector V5 eine View bauen (z.B. nur HOME_ATMOS, EMF, Bedroom, Cellar etc.).
* Ueber das Inspector-Menu: "View -> AutoIngest Subset schreiben"
  -> erstellt: REAPER/ResourcePath/Support/DF95_SampleDB/DF95_AutoIngest_Subset.json

Diese Datei dient als Quelle fuer den Drone/Atmos Builder.

2. Drone/Atmos Builder from View
--------------------------------

Script: DF95_Drone_Atmos_Builder_From_View_ImGui.lua

Start:
* Entweder direkt ueber Action-Liste
* Oder indirekt ueber das ControlCenter (SampleDB-Tab -> "Drone/Atmos Builder (from View)")

Funktionen:
* Liest DF95_AutoIngest_Subset.json und filtert alle Files nach Mindestlaenge.
* Optional zusaetzlicher Name-Filter (z.B. "amb", "room", "emf", "night").
* Layout-Mode:
  - "ein Track pro Drone" -> legt pro File einen Track DRONE_<Name> an
  - "alles auf DRONE_STACK" -> legt alle Drone-Sounds auf einen gemeinsamen Track
* Fades: einstellbare Fade-In / Fade-Out Zeiten.
* Optional: "DroneFX V1 (DF95_Drone_Granular) automatisch auf Tracks anwenden".

3. DroneFX V1 - Granular Textures
---------------------------------

JSFX: Effects/DF95/DF95_Drone_Granular.jsfx
* Granular-Texturprozessor mit Grain-Length, Density, Pitch-Random, Jitter, Stereo-Offset, Feedback und Mix.
* Gut geeignet fuer weiche, flaechenartige Drones / Atmos.

FXChain: FXChains/DF95_DroneFX_Rack_V1.RfxChain
* Minimal-Chain mit DF95_Drone_Granular als Kernbaustein.
* Kann in REAPER weiter ergaenzt werden (EQ, Coloring, MasterFX, etc.).

4. Export Presets fuer Drone/Atmos
----------------------------------

Modul: DF95_Export_Presets.lua

Es gibt drei dedizierte Drone-Presets:

* ID: DRONE_HOME_ATMOS_LOOP
  - Label: "Home Drone Atmos (Loop)"
  - mode   = LOOP_TIMESEL
  - target = ZOOM96_32F
  - category = HOME_ATMOS
  - subtype  = ROOMTONE
  - role     = Drone
  - source   = Fieldrec
  - fxflavor = DroneFXV1

* ID: DRONE_EMF_DRONE_LONG
  - Label: "EMF Drone Longform"
  - mode   = LOOP_TIMESEL
  - target = ZOOM96_32F
  - category = EMF_DRONE
  - subtype  = LONG
  - role     = Drone
  - source   = EMFRecorder
  - fxflavor = DroneFXV1

* ID: DRONE_IDM_TEXTURE_LONG
  - Label: "IDM Drone Texture (Loop)"
  - mode   = LOOP_TIMESEL
  - target = SPLICE_44_24
  - category = IDM_TEXTURE
  - subtype  = AMBIENT
  - role     = Drone
  - source   = ArtistIDM
  - fxflavor = DroneFXV1

5. Export Preset Picker (ImGui)
-------------------------------

Script: DF95_Export_PresetPicker_ImGui.lua

Start:
* Direkt als Action oder ueber ControlCenter (SampleDB-Tab -> "Export Preset Picker").

Funktionen:
* Laedt alle Presets aus DF95_Export_Presets.lua.
* Filterfunktion (Label/ID) und Checkbox "Nur Drone/Atmos Presets anzeigen".
* Klick auf einen Eintrag setzt DF95_EXPORT.current_preset_id.
* Der DF95_Export_Wizard.lua uebernimmt dieses Preset automatisch.

6. Auto-Export-Integration im Drone/Atmos Builder
-------------------------------------------------

Im Drone/Atmos Builder gibt es unterhalb des Buttons:
  "Drones/Atmos im Projekt anlegen (ab Cursor)"
den Block:

* Checkbox:
  "Export Wizard nach Preset-Auswahl automatisch starten"

* Buttons:
  - "Home Drone Atmos (Loop) Preset setzen"
  - "EMF Drone Longform Preset setzen"
  - "IDM Drone Texture (Loop) Preset setzen"

Diese Buttons rufen intern auto_export_with_preset() auf:

* Setzen DF95_EXPORT.current_preset_id auf das entsprechende Drone-Preset.
* Aktualisieren die Statusmeldung im Builder.
* Wenn die Checkbox aktiv ist, wird zudem versucht, die Action "_DF95_EXPORT_WIZARD"
  auszufuehren (d.h., der Nutzer muss DF95_Export_Wizard.lua unter dieser Command-ID
  registrieren).

Empfohlener Workflow:
---------------------

1. Drone/Atmos Tracks mit dem Builder erzeugen (mit oder ohne DroneFX).
2. Eine Time Selection ueber den gewuenschten Loop-/Exportbereich setzen.
3. Im Builder:
   * eines der Drone-Presets setzen (optional mit Auto-Launch des Export Wizard).
4. In DF95_Export_Wizard:
   * Pruefen, ob Mode/Target/Category/Role wie gewuenscht gesetzt sind.
   * Render starten.
5. Optional: DF95 AutoIngest V3 ueber den Export-Ordner laufen lassen,
   so dass die neuen Drone-Samples direkt in SampleDB / Inspector V5 auftauchen.

Hinweis:
--------

Alle IDs / Bezeichner (z.B. "_DF95_EXPORT_WIZARD") muessen in REAPER entsprechend
den individuellen DF95-Installationseinstellungen registriert werden.
