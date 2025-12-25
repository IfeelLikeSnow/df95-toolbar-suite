# Diff: unresolved toolbar script targets vs local snapshots

This repo was generated from `df95-ifls-full.zip` (local snapshot). Toolbars reference some script paths under `Scripts/IfeelLikeSnow/...` that do not exist in the snapshot.

- Unresolved targets (from `Reports/unresolved_script_targets.md`): **36**
- Present in local `df95-ifls-full.zip`: **0** (expected 0; unresolved implies missing/ambiguous)
- Present in local `df95-ifls.zip`: **0**

## Unresolved list

- `Scripts/IfeelLikeSnow/DF95/DF95_Menu_Humanize_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Menu_Coloring_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/Design/DF95_Slice_Menu.lua`
- `Scripts/IfeelLikeSnow/DF95/Design/DF95_Menu_Humanize_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/Design/DF95_FXBus_Seed.lua`
- `Scripts/IfeelLikeSnow/DF95/Design/DF95_LoopBuilder.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Slice_Menu.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_FXBus_Seed.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_LoopBuilder.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Rearrange_Align.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Explode_AutoBus.lua`
- `Scripts/IfeelLikeSnow/DF95/Tools/DF95_MicFX_Profile_GUI.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_FXBus_Selector.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_GainMatch_AB.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Menu_Master_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_FirstRun_LiveCheck.lua`
- `Scripts/IfeelLikeSnow/DF95/Edit/DF95_Rearrange_Align.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_MicFX_Manager.lua`
- `Scripts/IfeelLikeSnow/DF95/Tools/DF95_Menu_FXBus_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/Tools/DF95_Menu_Coloring_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/Tools/DF95_Menu_Master_Dropdown.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_ColoringBus_Selector.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_MasterBus_Selector.lua`
- `Scripts/IfeelLikeSnow/DF95/Input/DF95_MicFX_Manager.lua`
- `Scripts/IfeelLikeSnow/DF95/Input/DF95_GainMatch_AB.lua`
- `Scripts/IfeelLikeSnow/DF95/QA/DF95_Safety_Loudness_Menu.lua`
- `Scripts/IfeelLikeSnow/DF95/QA/DF95_FirstRun_LiveCheck.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Fieldrec_Slicing_Hub_ImGui.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Fieldrec_Fusion_GUI.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_InputFX_Metering.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_InputFX_TapeColor.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_DroneFXV1_Repo_AutoInstaller.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Safety_Inspector_ImGui.lua`
- `Scripts/IfeelLikeSnow/DF95/Tools/DF95_Toolbar_BiasTools_Show.lua`
- `Scripts/IfeelLikeSnow/DF95/Tools/DF95_Toolbar_ColorMaster_Audition_SWS_Show.lua`
- `Scripts/IfeelLikeSnow/DF95/DF95_Safety_Loudness_Menu.lua`

## Next step

Run `tools/resolve_missing_from_github.sh` in a real environment to attempt fetching these paths from upstream GitHub repos (df95-ifls-full / df95-ifls). If files still don't exist upstream, fix mapping by pointing toolbar targets to the real scripts (often under `Scripts/IFLS/...`).
