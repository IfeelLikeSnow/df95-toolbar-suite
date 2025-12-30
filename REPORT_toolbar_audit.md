# DF95 IFLS Main Toolbar — Audit Report
This report is generated from static analysis of the repository payload.
## Buttons → target scripts (from DF95_Build_IFLS_Main_Toolbar_MenuSet.lua)
- **0: Beat Control Center** → `Scripts/IFLS/IFLS/Hubs/IFLS_BeatControlCenter_ImGui.lua` — OK
- **1: Artist Hub** → `Scripts/IFLS/IFLS/Hubs/IFLS_ArtistHub_ImGui.lua` — OK
- **2: SampleGalaxy** → `Scripts/IFLS/IFLS/Hubs/IFLS_SampleLibraryHub_ImGui.lua` — OK
- **3: Groove & Rhythm** → `Scripts/IFLS/IFLS/Hubs/IFLS_PolyRhythmHub_ImGui.lua` — OK
- **4: Macros & Scenes** → `Scripts/IFLS/IFLS/Hubs/IFLS_SceneHub_ImGui.lua` — OK
- **5: FX Brain** → `Scripts/IFLS/IFLS/Hubs/IFLS_MasterHub_ImGui.lua` — OK
- **6: Diagnostics / Inspector** → `Scripts/IFLS/DF95/DF95_Diagnostics_Insight_Run.lua` — OK
- **7: Dev / Debug** → `Scripts/IFLS/IFLS/Domain/IFLS_Diagnostics_DebugDemo.lua` — OK

## Dependency checks (static)
- Verified: each target script exists at the exact path expected by the builder.
- Verified: each target script’s `core_path` / `domain_path` references exist.
- Verified: no git-merge conflict markers (`<<<<<<<` / `>>>>>>>`) in the payload.

## ReaPack full-install fix
- Added a metapackage at `_payload/Packages/DF95_IFLS_CoreAssets.lua` (v1.0.4) that **provides the entire `_payload/` tree** into the REAPER resource path.
- Updated `.reapack-index.conf` to scan `_payload/Packages` so the index contains the metapackage.
