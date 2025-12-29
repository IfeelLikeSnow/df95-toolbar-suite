Fix for IFLS Toolbar Builder missing InstallDoctor script

Your builder expects:
  REAPER/Scripts/IFLS/DF95/Installers/DF95_IFLS_InstallDoctor_CreateShims.lua

But your current install placed it under:
  REAPER/Scripts/DF95 Toolbar Suite/Scripts/IFLS/DF95/Installers/...

This patch adds the script at the expected location (without deleting the original).

Apply:
- Copy the 'Scripts' folder from this patch into your REAPER resource path OR into your Git repo root.
- Re-run: DF95_IFLS_Rebuild_Toolbar_MenuSet.lua
- Re-import: MenuSets/IFLS_Main.Toolbar.ReaperMenuSet into Floating toolbar 1.
