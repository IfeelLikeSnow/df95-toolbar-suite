-- @description Export – UCS README (Help Window)
-- @version 1.0
-- @author DF95

-- Zeigt eine kleine Hilfe zur UCS-Integration im DF95 Export-System.
-- Nutzt ImGui (ReaImGui) für ein scrollbares Info-Fenster.

local r = reaper

local ctx = r.ImGui_CreateContext("DF95 Export UCS – README", 0)

local help_text = [[
DF95 Export – UCS Integration (Kurzüberblick)
============================================

Was ist UCS?
------------
UCS = "Universal Category System".
Es definiert ein gemeinsames Vokabular und eine Naming-Struktur
für Sound Libraries, z.B.:

  CatID_FXName_CreatorID_SourceID.wav

Beispiele:
  DRMElct_GlitchLoop01_DF95_DF95_IDM01.wav
  SFXGlit_BitcrushRise_DF95_IDM_FXPack01.wav

Im DF95-System werden diese Teile über Tags + UCS-Felder gebaut:

  - CatID      -> ucs_catid      (z.B. DRMElct, SFXGlit, SYNPad...)
  - FXName     -> ucs_fxname     (z.B. GlitchLoop01, PadDroneA)
  - CreatorID  -> ucs_creatorid  (z.B. DF95 oder Artist-Name)
  - SourceID   -> ucs_sourceid   (z.B. Projekt- oder Library-Name)

Wann wird UCS benutzt?
----------------------
UCS greift nur dann, wenn eine CatID gesetzt ist.
D.h. sobald ucs_catid NICHT leer ist, wird der Dateiname im
Export-Core wie folgt gebaut:

  CatID_FXName_CreatorID_SourceID.wav

Wenn ucs_catid leer bleibt, nutzt DF95 die bisherigen
Naming-Styles (Splice / Loopmasters / ADSR usw.).

Wichtige Dateien
----------------
  Scripts/IFLS/DF95/DF95_Export_Core.lua
    - Kern-Exportlogik, baut Dateinamen & Render-Settings
    - UCS-Override im build_base_path()

  Scripts/IFLS/DF95/DF95_Export_Wizard.lua
    - Textbasierter Export-Wizard
    - Unterstützt 7-Felder (Legacy) und 11-Felder (mit UCS-Feldern)

  Scripts/IFLS/DF95/DF95_Export_UCS_Helper.lua
    - Hilfsscript, um UCS-CatID / FXName / CreatorID / SourceID
      vorzubelegen und in DF95_EXPORT/wizard_tags zu speichern.

  Scripts/IFLS/DF95/DF95_Export_UCS_ImGui.lua
    - ImGui-Frontend für Export + UCS:
      Mode, Target, Category, Role, Source, FXFlavor, DestRoot,
      UCS-Felder + Live-Dateinamen-Vorschau + "Run Export"-Button

  Scripts/IFLS/DF95/DF95_Export_UCS_Browser_ImGui.lua
    - UCS-Browser mit Filter:
      Zeigt CatID / Category / Subcategory / Description aus JSON
      Klick auf eine Zeile setzt die UCS_CatID im Wizard/Export.

  Data/DF95/DF95_Export_UCSDefaults_v1.json
    - Enthält:
        * defaults:
            creator_id, source_mode, default_source_id,
            use_artist_as_creator
        * examples:
            Liste von CatID-Beispielen (DRMElct, SYNPad, SFXGlit ...)

  Data/DF95/DF95_Export_UCSArtistProfiles_v1.json
    - Artist-basierte Defaults:
      pro Artist:
        ucs_catid, role, source, fxflavor

Typischer Workflow
------------------
1) Artist wählen (in DF95 / ArtistConsole / Autopilot)
2) Autopilot & FXBus / Motion ausführen, Slices/Loops erzeugen
3) Export starten (Master-Export-Button):
   a) Ziel-Format wählen (ORIGINAL, SPLICE_44_24, CIRCUIT_RHYTHM_48_16, ...)
   b) UCS-Einstellungen prüfen/feintunen:
      - CatID aus Presets wählen oder eingeben
      - FXName setzen (kurze, aussagekräftige Bezeichnung)
      - CreatorID (oft Artist oder "DF95")
      - SourceID (Projekt/Pack-Name)
   c) "Run Export" drücken

4) Ergebnis:
   - Dateien liegen im gewählten Export-Ordner
   - Dateinamen sind UCS-konform, z.B.:

       DRMElct_AutechreBeat01_Autechre_DF95_IDM01.wav
       SYNPad_BoCPad01_BoC_DF95_IDM01.wav

Hinweis zu Circuit Rhythm
-------------------------
Für das Export-Target CIRCUIT_RHYTHM_48_16 stellt DF95:
  - Samplerate: 48 kHz
  - Bit-Tiefe:  16-bit
  - Kanäle:    Mono

Das entspricht den Anforderungen für Circuit Rhythm Packs.
UCS-Namen können dabei trotzdem verwendet werden, z.B.:

  DRMElct_CircBeat01_DF95_CircuitPack01.wav

Tipps
-----
- FXName eher kurz halten (< 25 Zeichen), klare Nummerierung hilft:
    GlitchLoop01, GlitchLoop02, PadTextureA, PadTextureB...
- CreatorID:
    - gut geeignet: Artist-Name, Producer-Name, "DF95"
- SourceID:
    - Projektname, Librarytitel oder Pack-ID

- Nutze den UCS Browser (DF95_Export_UCS_Browser_ImGui.lua),
  um passende CatIDs zu finden und auf den Export zu übernehmen.

]]

local function loop()
  if not r.ImGui_ValidatePtr(ctx, "ImGui_Context*") then return end

  r.ImGui_SetNextWindowSize(ctx, 720, 520, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "DF95 Export – UCS README", true, 0)

  if visible then
    r.ImGui_Text(ctx, "DF95 Export – UCS README")
    r.ImGui_Separator(ctx)

    if r.ImGui_BeginChild(ctx, "scrollregion", 0, -40, true) then
      r.ImGui_TextWrapped(ctx, help_text)
      r.ImGui_EndChild(ctx)
    end

    if r.ImGui_Button(ctx, "Close", 80, 24) then
      open = false
    end

    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

loop()
